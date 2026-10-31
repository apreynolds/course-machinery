# gradebook.py — the grading scheme and the D2L export, and a student's mark so far
# Usage: imported by student-record; not run directly.
#
# WHY THIS EXISTS. D2L's gradebook cannot calculate a mark under this kind of
# scheme: it does not know who writes on which day, who chose which homework
# system, or that a test's weight depends on how it ranks among that student's
# tests. So this is the only place the real scheme is calculated, and every step
# is kept visible to the caller so a printed mark can be checked by hand.
#
# TWO FILES IN THE COURSE'S course-info/ DESCRIBE THE COURSE:
#
#   grading-scheme.csv   category,weight,rule -- one row per category
#   assessments.csv      title,due-date,category,track,d2l-items -- one per assessment
#
# d2l-items names the gradebook items an assessment is recorded in, separated by
# `|', and may be left empty when the only item has the assessment's own title.
# A test written on two days is one assessment with two items. A gradebook item
# named in neither file (a practice set, say) is simply ignored.
#
# THE RULES a category can name:
#
#   ranked-1-2-3  each student's scores are sorted, and the worst counts once, the
#                 best three times and the rest twice. With one score it counts
#                 alone, and two are weighted 1:3.
#   best-track    each row names a track, the scores in a track are averaged, and
#                 the student gets whichever track is higher.
#   single        a plain average, which for one assessment is just its score.
#
# WHEN A SCORE COUNTS. A due date has passed only on the day AFTER it, since work
# can be due at the end of that day.
#
#   not due yet, or no due date    left out, even if a score exists, since an open
#                                  quiz can still be retried
#   exempt                         left out, so the rule applies to the rest
#   blank, past due, hand-marked   0 if that item has been marked; otherwise left
#                                  out, because marks are simply not posted yet
#   blank, past due, otherwise     0
#
# An item counts as marked once MARKED_SHARE of the students expected to write it
# have something recorded. Without that, everyone would get a 0 between writing a
# test and its marks being posted.

import csv
import difflib
import re
import statistics
from collections import OrderedDict
from datetime import datetime

from courseadmin import ASSESSMENTS_CSV, GRADING_SCHEME_CSV, die, warn

EXEMPT = "exempt"

RULES = ("ranked-1-2-3", "best-track", "single")

# Rules whose scores are entered by someone after the fact, rather than arriving
# as the work is done. Only these can be blank because marking is unfinished.
HAND_MARKED_RULES = ("ranked-1-2-3", "single")
MARKED_SHARE = 0.5

# "Test 1 (Tue) Points Grade <Numeric MaxPoints:30 Category:Tests>", where the
# category is optional. Only points columns are matched, so the subtotals, the
# calculated grades and the rest of the export are never read as assessments.
D2L_POINTS_COLUMN_RE = re.compile(
    r"^(?P<title>.+) Points Grade <Numeric MaxPoints:(?P<max>[\d.]+)"
    r"(?: Category:(?P<category>[^>]+))?>$"
)

# (2026 FA) MATH 1003 Calculus I (all sections)_GradesExport_2026-10-30-23-45.csv
D2L_FILENAME_RE = re.compile(r"_GradesExport_(\d{4}-\d{2}-\d{2}-\d{2}-\d{2})")
D2L_GLOB = "*_GradesExport_*.csv"
D2L_TIME_FORMAT = "%Y-%m-%d-%H-%M"


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% THE COURSE'S TWO FILES
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def read_grading_scheme(path=GRADING_SCHEME_CSV):
    """grading-scheme.csv -> {category: {"weight": number, "rule": name}}, in order."""
    scheme = OrderedDict()
    with path.open(encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            category = (row.get("category") or "").strip()
            if not category:
                continue
            rule = (row.get("rule") or "").strip()
            if rule not in RULES:
                die(f"{path.name}: {category} has rule {rule!r}; it must be one of "
                    f"{', '.join(RULES)}.")
            try:
                weight = float(row.get("weight") or "")
            except ValueError:
                die(f"{path.name}: {category} has weight {row.get('weight')!r}, "
                    f"which is not a number.")
            scheme[category] = {"weight": weight, "rule": rule}

    total = sum(entry["weight"] for entry in scheme.values())
    if abs(total - 100) > 1e-9:
        warn(f"{path.name}: the weights add up to {total:g}, not 100.")
    return scheme


def read_assessments(scheme, path=ASSESSMENTS_CSV):
    """assessments.csv -> a list of dicts: title, due, category, track, items.

    A BAD ROW STOPS THE RUN, because a mistyped date or category would otherwise
    change marks with no sign that anything was wrong. An EMPTY due date is
    allowed, since it means "not set yet", and is reported all together.
    """
    assessments, undated = [], []
    with path.open(encoding="utf-8-sig", newline="") as handle:
        for number, row in enumerate(csv.DictReader(handle), start=2):
            title = (row.get("title") or "").strip()
            if not title:
                continue

            category = (row.get("category") or "").strip()
            if category not in scheme:
                die(f"{path.name} line {number}: category {category!r} is not in "
                    f"grading-scheme.csv ({', '.join(scheme)}).")

            track = (row.get("track") or "").strip()
            if scheme[category]["rule"] == "best-track" and not track:
                die(f"{path.name} line {number}: {title} needs a track, because "
                    f"{category} uses the best-track rule.")

            text = (row.get("due-date") or "").strip()
            due = None
            if text:
                try:
                    due = datetime.strptime(text, "%Y-%m-%d").date()
                except ValueError:
                    die(f"{path.name} line {number}: due date {text!r} is not "
                        f"YYYY-MM-DD.")
            else:
                undated.append(title)

            items = [
                item.strip()
                for item in (row.get("d2l-items") or "").split("|")
                if item.strip()
            ] or [title]
            assessments.append({
                "title": title,
                "due": due,
                "category": category,
                "track": track,
                "items": items,
            })

    if undated:
        warn(f"{path.name}: no due date yet, so left out of marks: "
             f"{', '.join(undated)}.")
    return assessments


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% THE D2L EXPORT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def newest_export(grades_dir):
    """The newest grades export in a folder -> (path, its timestamp), or (None, None).

    The timestamp is the one in the filename, which is why the choice survives a
    re-sync that changes a file's modification time. It may not be local time.
    """
    newest, newest_stamp = None, None
    for path in grades_dir.glob(D2L_GLOB):
        match = D2L_FILENAME_RE.search(path.name)
        if not match:
            continue
        try:
            stamp = datetime.strptime(match.group(1), D2L_TIME_FORMAT)
        except ValueError:
            continue
        if newest is None or stamp > newest_stamp:
            newest, newest_stamp = path, stamp
    return newest, newest_stamp


def clean_org_id(text):
    """OrgDefinedId as the class lists write it: D2L can prefix it with `#'."""
    return (text or "").strip().lstrip("#").strip()


def read_grade(text, symbol, title, oddities):
    """One grade cell -> a number, EXEMPT or None.

    Anything else is counted in `oddities' and treated as blank, so that a value
    nobody anticipated is reported rather than taken for a score.
    """
    text = (text or "").strip()
    if text.casefold() == EXEMPT or (symbol or "").strip().casefold() == EXEMPT:
        return EXEMPT
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        oddities.setdefault(title, set()).add(text)
        return None


def read_d2l_export(path):
    """A grades export -> {"items": {title: {...}}, "students": {id: {...}}}.

    By column name and never by position, since an export's columns depend on what
    was ticked when it was made and on the order of the gradebook.
    """
    items, students, oddities = OrderedDict(), {}, {}
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for column in reader.fieldnames or []:
            match = D2L_POINTS_COLUMN_RE.match(column)
            if match:
                items[match.group("title")] = {
                    "max": float(match.group("max")),
                    "category": match.group("category") or "",
                    "column": column,
                    "symbol": f"{match.group('title')} Scheme Symbol",
                }

        for row in reader:
            student_id = clean_org_id(row.get("OrgDefinedId"))
            if not student_id:
                continue
            students[student_id] = {
                "last": (row.get("Last Name") or "").strip(),
                "first": (row.get("First Name") or "").strip(),
                "email": (row.get("Email") or "").strip(),
                "grades": {
                    title: read_grade(row.get(item["column"]), row.get(item["symbol"]),
                                      title, oddities)
                    for title, item in items.items()
                },
            }

    for title, values in oddities.items():
        warn(f"{path.name}: {title} has values that are neither numbers nor Exempt "
             f"({', '.join(sorted(values))}); treated as blank.")
    return {"items": items, "students": students}


def check_items(assessments, items):
    """Warn about an item assessments.csv names that the export does not have.

    A typo here would otherwise read as a whole class of blank grades.
    """
    for assessment in assessments:
        for item in assessment["items"]:
            if item not in items:
                close = difflib.get_close_matches(item, list(items), n=1, cutoff=0.6)
                hint = f" Did you mean {close[0]!r}?" if close else ""
                warn(f"{assessment['title']}: {item!r} is not in the D2L export.{hint}")


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% WHICH ITEM IS WHOSE
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def item_applies(item, day):
    """Is this item written on this day? "Test 1 (Tue)" against "Tues", say.

    An item with no day in brackets applies to everyone, and so does every item
    when the student's day is not known. Compared on three letters, because the
    gradebook writes Tue and course-sections.csv writes Tues.
    """
    match = re.search(r"\(([^)]*)\)\s*$", item)
    if not match or not day:
        return True
    return match.group(1).strip().casefold()[:3] == day.strip().casefold()[:3]


def find_marked_items(assessments, scheme, export, enrolled):
    """Which hand-marked items have been marked -> {item: (recorded, expected)}.

    `enrolled' is (student id, day) for each student still in the course, so the
    count is not diluted by students who have left. Only ever consulted for a
    student's blank, and an item absent from the result counts as not marked.
    """
    progress = {}
    for assessment in assessments:
        if scheme[assessment["category"]]["rule"] not in HAND_MARKED_RULES:
            continue
        for item in assessment["items"]:
            if item not in export["items"]:
                continue
            expected = recorded = 0
            for student_id, day in enrolled:
                if not item_applies(item, day):
                    continue
                expected += 1
                student = export["students"].get(student_id)
                if student and student["grades"].get(item) is not None:
                    recorded += 1
            progress[item] = (recorded, expected)
    return progress


def is_marked(item, progress):
    recorded, expected = progress.get(item, (0, 0))
    return expected > 0 and recorded / expected >= MARKED_SHARE


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% ONE STUDENT
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def evaluate(assessment, rule, grades, day, as_of, export_items, progress):
    """One student on one assessment -> a dict saying what happened and why.

        status   counted, missing, exempt, pending, not-due, not-in-export
        item     the gradebook item this refers to, for showing
        score    the points, or None        max  what it was out of
        percent  the score as a percentage; 0 for missing; None if there is none
        note     something odd worth showing, or ""

    A score on work that is not due yet keeps its percent, for showing, but its
    status keeps it out of every calculation.
    """
    result = {"assessment": assessment, "item": assessment["items"][0], "score": None,
              "max": None, "percent": None, "note": "", "status": None}

    present = [item for item in assessment["items"] if item in export_items]
    if not present:
        result["status"] = "not-in-export"
        return result

    # Which item to describe when the student has nothing recorded.
    theirs = [item for item in present if item_applies(item, day)] or present
    result["item"] = theirs[0]
    result["max"] = export_items[theirs[0]]["max"]

    values = {item: grades.get(item) for item in present}
    if EXEMPT in values.values():
        result["item"] = next(item for item in present if values[item] == EXEMPT)
        result["status"] = "exempt"
        return result

    scored = [item for item in present if values[item] is not None]
    if scored:
        # Their own day's version wins if they somehow have both.
        own = [item for item in scored if item_applies(item, day)]
        chosen = (own or scored)[0]
        if len(scored) > 1:
            result["note"] = f"also graded on {', '.join(i for i in scored if i != chosen)}"
        elif not own:
            result["note"] = f"section writes on {day}"
        result["item"] = chosen
        result["score"] = values[chosen]
        result["max"] = export_items[chosen]["max"]
        result["percent"] = 100 * result["score"] / result["max"] if result["max"] else 0.0

    due = assessment["due"]
    if due is None or as_of <= due:
        result["status"] = "not-due"
    elif scored:
        result["status"] = "counted"
    elif rule in HAND_MARKED_RULES and not all(is_marked(item, progress) for item in theirs):
        result["status"] = "pending"
    else:
        result["status"] = "missing"
        result["percent"] = 0.0
    return result


def ranked_weights(count):
    """How many times each of `count' scores counts, worst first."""
    if count == 1:
        return [1]
    if count == 2:
        return [1, 3]
    return [1] + [2] * (count - 2) + [3]


def mean(values):
    return sum(values) / len(values) if values else None


def counting(evaluations):
    return [e for e in evaluations if e["status"] in ("counted", "missing")]


def apply_ranked(result):
    """The ranked-1-2-3 rule. Records each evaluation's multiplier as `times'."""
    # sorted() keeps equal scores in their listed order, so a tie is stable.
    ordered = sorted(counting(result["evaluations"]), key=lambda e: e["percent"])
    if not ordered:
        return
    weights = ranked_weights(len(ordered))
    for evaluation, times in zip(ordered, weights):
        evaluation["times"] = times
    result["value"] = sum(e["percent"] * t for e, t in zip(ordered, weights)) / sum(weights)
    result["average"] = mean([e["percent"] for e in ordered])


def apply_best_track(result):
    """The best-track rule.

    A TRACK WITH NOTHING DUE CANNOT BE COMPARED. If a student's work is all in a
    track with no due dates passed, its average so far beating the other track
    means the better track is unknown, so the category is left out of the mark and
    says so. Otherwise that student would be given the other track's 0.
    """
    tracks = OrderedDict()
    for evaluation in result["evaluations"]:
        tracks.setdefault(evaluation["assessment"]["track"], []).append(evaluation)

    result["tracks"] = OrderedDict()
    for track, evaluations in tracks.items():
        due = counting(evaluations)
        open_scores = [e["percent"] for e in evaluations
                       if e["status"] == "not-due" and e["percent"] is not None]
        result["tracks"][track] = {
            "evaluations": evaluations,
            "due": len(due),
            "value": mean([e["percent"] for e in due]),
            "open_average": mean(open_scores),
            "has_work": any(e["percent"] for e in evaluations),
        }

    decided = [(info["value"], track) for track, info in result["tracks"].items()
               if info["value"] is not None]
    # max() on (value, track) would break a tie by name; this keeps the listed order.
    best = None
    for value, track in decided:
        if best is None or value > best[0]:
            best = (value, track)

    if sum(info["has_work"] for info in result["tracks"].values()) > 1:
        result["both_tracks"] = True

    best_value = best[0] if best else None
    for info in result["tracks"].values():
        if (info["due"] == 0 and info["open_average"] is not None
                and (best_value is None or info["open_average"] > best_value)):
            result["undetermined"] = True
            return

    if best:
        result["value"], result["best_track"] = best


def apply_single(result):
    result["value"] = mean([e["percent"] for e in counting(result["evaluations"])])


APPLY_RULE = {
    "ranked-1-2-3": apply_ranked,
    "best-track": apply_best_track,
    "single": apply_single,
}


def standing(grades, day, assessments, scheme, export_items, progress, as_of):
    """A student's whole position -> {"categories": {...}, "mark": ..., "due_weight": ...}.

    The mark is over only the categories with something counted so far, rescaled so
    they make up 100: (40 x Tests + 10 x Homework) / 50 before the final exam.
    """
    categories = OrderedDict()
    for category, entry in scheme.items():
        categories[category] = {
            "weight": entry["weight"], "rule": entry["rule"], "evaluations": [],
            "value": None, "average": None, "tracks": None, "best_track": None,
            "undetermined": False, "both_tracks": False,
        }

    for assessment in assessments:
        result = categories[assessment["category"]]
        result["evaluations"].append(
            evaluate(assessment, result["rule"], grades, day, as_of, export_items, progress)
        )

    for result in categories.values():
        APPLY_RULE[result["rule"]](result)

    settled = [r for r in categories.values() if r["value"] is not None]
    due_weight = sum(r["weight"] for r in settled)
    mark = sum(r["value"] * r["weight"] for r in settled) / due_weight if due_weight else None
    return {"categories": categories, "mark": mark, "due_weight": due_weight}


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#% A WHOLE CLASS
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

def item_statistics(item, max_points, student_ids, students):
    """How a group did on one item -> {n, mean, median, exempt}, in percent.

    BLANKS ARE LEFT OUT, not counted as 0: a blank may only mean "not marked yet"
    or "chose the other homework system". Real zeros stay in, which is why the
    median is reported too, and n always says how many this rests on.
    """
    scores, exempt = [], 0
    for student_id in student_ids:
        student = students.get(student_id)
        value = student["grades"].get(item) if student else None
        if value == EXEMPT:
            exempt += 1
        elif value is not None and max_points:
            scores.append(100 * value / max_points)
    return {
        "n": len(scores),
        "mean": mean(scores),
        "median": statistics.median(scores) if scores else None,
        "exempt": exempt,
    }
