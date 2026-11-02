# test-student-record.py — check student-record's marks against ones worked out by hand, on invented students
# Usage: uv run --with openpyxl python3 test-student-record.py [WORKDIR]
import argparse
import csv
import importlib.machinery
import importlib.util
import sys
import tempfile
from datetime import date
from pathlib import Path

from openpyxl import Workbook

sys.dont_write_bytecode = True
ADMIN = Path(str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(ADMIN))
loader = importlib.machinery.SourceFileLoader("student_record", str(ADMIN / "student-record"))
spec = importlib.util.spec_from_loader("student_record", loader)
sr = importlib.util.module_from_spec(spec)
loader.exec_module(sr)

work = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(tempfile.mkdtemp(prefix="student-record-"))
(work / "rosters").mkdir(parents=True, exist_ok=True)
(work / "grades").mkdir(exist_ok=True)

sections = sr.read_sections()
thu = next(s for s, i in sections.items() if i["day"] == "Thurs")
tue = next(s for s, i in sections.items() if i["day"] == "Tues")
nominal = thu

(work / "assessments.csv").write_text("""title,due-date,category,track,d2l-items
Test 1,2026-09-24,Tests,,Test 1 (Tue)|Test 1 (Thu)
Test 2,2026-10-08,Tests,,Test 2 (Tue)|Test 2 (Thu)
Test 3,2026-10-22,Tests,,Test 3 (Tue)|Test 3 (Thu)
Test 4,2026-11-05,Tests,,Test 4 (Tue)|Test 4 (Thu)
Gateway Quiz 1,2026-09-25,Online homework,WeBWorK,
Gateway Quiz 2,2026-10-15,Online homework,WeBWorK,
Gateway Quiz 3,2026-11-20,Online homework,WeBWorK,Gateway_Quiz_3
Module 1,2026-10-01,Online homework,ALEKS,Module 1 - Functions
Module 2,2026-10-20,Online homework,ALEKS,Module 2 - Limits
Module 3,,Online homework,ALEKS,Module 3 - Derivatives
Final Exam,2026-12-15,Final Exam,,
""")
(work / "scheme.csv").write_text("category,weight,rule\nTests,40,ranked-1-2-3\nOnline homework,10,best-track\nFinal Exam,50,single\n")

COLUMNS = {
    "T1U": ("Test 1 (Tue)", 30, "Tests"), "T1H": ("Test 1 (Thu)", 30, "Tests"),
    "T2U": ("Test 2 (Tue)", 30, "Tests"), "T2H": ("Test 2 (Thu)", 30, "Tests"),
    "T3U": ("Test 3 (Tue)", 30, "Tests"), "T3H": ("Test 3 (Thu)", 30, "Tests"),
    "T4U": ("Test 4 (Tue)", 30, "Tests"), "T4H": ("Test 4 (Thu)", 30, "Tests"),
    "G1": ("Gateway Quiz 1", 100, "WeBWorK"), "G2": ("Gateway Quiz 2", 100, "WeBWorK"),
    "G3": ("Gateway_Quiz_3", 100, "WeBWorK"),
    "M1": ("Module 1 - Functions", 100, "ALEKS"), "M2": ("Module 2 - Limits", 100, "ALEKS"),
    "M3": ("Module 3 - Derivatives", 100, "ALEKS"),
    "P": ("OS1.1_Practice", 100, "WeBWorK practice"), "F": ("Final Exam", 100, None),
}

# id: (class-list name, last, first, grades). None as a name means no class-list row.
S = {
    # Plain case, Thu. Tests 60,70,80 ->(60+140+240)/6=73.33; WW (90+74)/2=82.
    "1000001": (f"Alpha, Ann cross-listed as MATH*1003*{thu}", "Alpha", "Ann",
                dict(T1H=21, T2H=18, T3H=24, G1=90, G2=74, G3=100, P=5)),
    # Exempt T2. Tests 60,90 at 1:3 = 82.5; ALEKS (50+70)/2=60, WW 0.
    "1000002": (f"Beta, Bo cross-listed as MATH*1003*{thu}", "Beta", "Bo",
                dict(T1H=18, T2H="Exempt", T3H=27, M1=50, M2=70, M3=40)),
    # Missed T3 (0). Tests 0,50,100 -> (0+100+300)/6=66.67. WW (50+0)/2=25, ALEKS (10+0)/2=5.
    "1000003": (f"Gamma, Gil cross-listed as MATH*1003*{thu}", "Gamma", "Gil",
                dict(T1H=30, T2H=15, G1=50, M1=10)),
    # Dropped: must not reach any class average. A wild score makes a leak obvious.
    "1000004": (f"Delta, Dee (Dropped 2026-10-20) cross-listed as MATH*1003*{thu}", "Delta", "Dee",
                dict(T1H=0, T2H=0, T3H=0)),
    # Moved Thu -> Tue, so two class-list rows. Tue day, T1 80 only + T4 Tue.
    "1000005": (f"Epsilon, Eve cross-listed as MATH*1003*{tue}", "Epsilon", "Eve",
                dict(T1U=24, T2U=24, T3U=24, T4U=24)),
    # Graded on both versions: own day (Thu) wins.
    "1000006": (f"Zeta, Zed cross-listed as MATH*1003*{thu}", "Zeta", "Zed",
                dict(T1U=30, T1H=15, T2H=15, T3H=15)),
    # Thu section, graded on Tue only: flagged, still counted.
    "1000007": (f"Eta, Élodie cross-listed as MATH*1003*{thu}", "Eta", "Élodie",
                dict(T1U=15, T2H=15, T3H=15)),
    # In D2L, on no class list.
    "1000008": (None, "Theta", "Tim", dict(T1H=15)),
    # On a class list, not in D2L.
    "1000009": (f"Iota, Ian cross-listed as MATH*1003*{thu}", None, None, None),
    # Tue, blank on a marked Test 4: missing. Tests 3 of 80 then a 0.
    "1000010": (f"Kappa, Kim cross-listed as MATH*1003*{tue}", "Kappa", "Kim",
                dict(T1U=24, T2U=24, T3U=24)),
    "1000011": (f"Lambda, Lee cross-listed as MATH*1003*{tue}", "Lambda", "Lee",
                dict(T1U=24, T2U=24, T3U=24, T4U=24)),
    # Enough Thu students with grades that Thu Tests 1-3 count as marked; T4 Thu not.
    "1000012": (f"Mu, Max cross-listed as MATH*1003*{thu}", "Mu", "Max",
                dict(T1H=15, T2H=15, T3H=15)),
    "1000013": (f"Nu, Nia cross-listed as MATH*1003*{thu}", "Nu", "Nia",
                dict(T1H=15, T2H=15, T3H=15, T4H=15)),
}

roster_name = f"section-rosters_MATH_1003_{nominal}_2026-10-25_9_06 PM.csv"
with (work / "rosters" / roster_name).open("w", encoding="utf-8-sig", newline="") as handle:
    writer = csv.writer(handle)
    writer.writerow(["Student Name", "Student ID", "Email Address"])
    for sid, (name, *_rest) in S.items():
        if name:
            writer.writerow([name, sid, f"{sid}@example.invalid"])
    # The mover's old row.
    writer.writerow([f"Epsilon, Eve (Dropped 2026-10-01) cross-listed as MATH*1003*{thu}", "1000005", "1000005@example.invalid"])

header = ["OrgDefinedId", "Last Name", "First Name", "Email"]
for title, maximum, category in COLUMNS.values():
    tail = f" Category:{category}" if category else ""
    header += [f"{title} Points Grade <Numeric MaxPoints:{maximum}{tail}>", f"{title} Scheme Symbol"]
header += ["Tests Subtotal Numerator", "End-of-Line Indicator"]

for stamp, marker in (("2026-10-30-18-40", "OLD"), ("2026-10-30-23-45", "NEW")):
    path = work / "grades" / f"(2026 FA) MATH 1003 Calculus I (all sections)_GradesExport_{stamp}.csv"
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        for sid, (_name, last, first, grades) in S.items():
            if grades is None:
                continue
            row = [f"#{sid}", last, first, f"{sid}@d2l.invalid"]
            for key in COLUMNS:
                value = grades.get(key, "")
                if marker == "OLD":
                    value = 1  # the older export must never be used
                row += [value, ""]
            writer.writerow(row + ["", "#"])
(work / "grades" / "headers.csv").write_text("not an export\n")

book = Workbook()
sheet = book.active
sheet.append(["last", "first", "section", "ID", "writes-at-sac"])
sheet.append(["Alpha", "Ann", thu, "1000001", "yes"])
sheet.append(["Beta", "Bo", thu, None, "unknown"])       # no ID: by name
sheet.append(["Gamma", "Gil", tue, 1000003, "no"])       # ID as a number, stale section
sheet.append(["Nobody", "Here", thu, None, "no"])        # matches nobody
book.save(work / "sac.xlsx")


def course(as_of):
    args = argparse.Namespace(
        as_of=as_of, roster_dir=work / "rosters", sac_workbook=work / "sac.xlsx",
        staff=work / "no-staff-file.csv",
        grades_dir=work / "grades", assessments=work / "assessments.csv", scheme=work / "scheme.csv",
    )
    return sr.Course(args)


failures = 0


def check(label, got, want):
    global failures
    ok = abs(got - want) < 1e-6 if isinstance(want, float) and got is not None else got == want
    print(f"{'ok  ' if ok else 'FAIL'} {label}: {got!r}" + ("" if ok else f" (wanted {want!r})"))
    failures += not ok


c = course(date(2026, 10, 30))
rec = c.records
st = {k: c.standing_of(rec[k]) for k in rec}
tests = lambda k: st[k]["categories"]["Tests"]
home = lambda k: st[k]["categories"]["Online homework"]

check("newest export used", c.export_path.name.endswith("23-45.csv"), True)
check("hash stripped from D2L ID, joined", rec["1000001"]["d2l"] is not None, True)
check("class-list email preferred", rec["1000001"]["email"], "1000001@example.invalid")
check("D2L email as fallback", rec["1000008"]["email"], "1000008@d2l.invalid")

check("plain: tests ranked", tests("1000001")["value"], (60 + 140 + 240) / 6)
check("plain: tests average", tests("1000001")["average"], 70.0)
check("plain: homework", home("1000001")["value"], 82.0)
check("plain: best track", home("1000001")["best_track"], "WeBWorK")
check("plain: mark", st["1000001"]["mark"], (40 * (440 / 6) + 10 * 82) / 50)
check("plain: due weight", st["1000001"]["due_weight"], 50.0)

check("exempt: 1:3 over two", tests("1000002")["value"], 82.5)
check("exempt: ALEKS wins", home("1000002")["best_track"], "ALEKS")
check("exempt: ALEKS value ignores undated module", home("1000002")["value"], 60.0)
check("exempt: mark", st["1000002"]["mark"], (40 * 82.5 + 10 * 60) / 50)
check("exempt: no both-tracks flag", home("1000002")["both_tracks"], False)

check("missed: 0 is the worst", tests("1000003")["value"], 400 / 6)
check("missed: both tracks flagged", home("1000003")["both_tracks"], True)
check("missed: better track", home("1000003")["value"], 25.0)
check("missed: mark", st["1000003"]["mark"], (40 * (400 / 6) + 250) / 50)

check("dropped: status", rec["1000004"]["dropped"], "2026-10-20")
check("dropped: not enrolled", rec["1000004"]["live"], False)
# Test 1 (Thu) among registered Thu: 21,18,15(Zeta),15(Mu),15(Nu),30(Gamma),15? Eta is on Tue.
scores = [21, 18, 30, 15, 15, 15]
check("class mean excludes dropped", c.class_stats["Test 1 (Thu)"]["mean"], sum(s / 30 * 100 for s in scores) / 6)
check("class n excludes dropped", c.class_stats["Test 1 (Thu)"]["n"], 6)
check("exempt counted separately", c.class_stats["Test 2 (Thu)"]["exempt"], 1)

check("moved: live in new section", rec["1000005"]["section"], tue)
check("moved: recorded", rec["1000005"]["moved"], [(thu, "2026-10-01")])
check("moved: day follows", rec["1000005"]["day"], "Tues")

e = {x["assessment"]["title"]: x for x in tests("1000006")["evaluations"]}
check("both versions: own day used", e["Test 1"]["percent"], 50.0)
check("both versions: noted", "also graded" in e["Test 1"]["note"], True)
e = {x["assessment"]["title"]: x for x in tests("1000007")["evaluations"]}
check("other day: counted", e["Test 1"]["status"], "counted")
check("other day: noted", "writes on" in e["Test 1"]["note"], True)

check("D2L only: not live", rec["1000008"]["live"], False)
check("class list only: no D2L", rec["1000009"]["d2l"], None)

check("SAC by ID", (rec["1000001"]["sac"]["where"], rec["1000001"]["sac_by_name"]), ("yes", False))
check("SAC by name", (rec["1000002"]["sac"]["where"], rec["1000002"]["sac_by_name"]), ("unknown", True))
check("SAC numeric ID", rec["1000003"]["sac"]["where"], "no")
check("SAC unmatched warned", any("row 5" in w for w in sr.courseadmin.report_warnings), True)

# Test 4 is not due on 30 Oct, even for those with a score.
e = {x["assessment"]["title"]: x for x in tests("1000011")["evaluations"]}
check("not due: excluded", e["Test 4"]["status"], "not-due")
check("not due: not ranked", tests("1000011")["value"], 80.0)

# After Test 4: Tue is marked (3 of 4... see below), Thu is not.
later = course(date(2026, 11, 10))
s = lambda k: later.standing_of(later.records[k])["categories"]["Tests"]
e = {x["assessment"]["title"]: x for x in s("1000010")["evaluations"]}
check("Tue blank on marked: missing", e["Test 4"]["status"], "missing")
check("missing lowers ranked", s("1000010")["value"], (0 + 160 + 160 + 240) / 7 * 7 / 8 if False else (0 * 1 + 80 * 2 + 80 * 2 + 80 * 3) / 8)
e = {x["assessment"]["title"]: x for x in s("1000001")["evaluations"]}
check("Thu blank on unmarked: pending", e["Test 4"]["status"], "pending")
check("pending not counted", s("1000001")["value"], 440 / 6)

# Before any ALEKS date: its student's work cannot yet be compared.
early = course(date(2026, 9, 28))
h = early.standing_of(early.records["1000002"])
check("undetermined: left out", h["categories"]["Online homework"]["undetermined"], True)
check("undetermined: mark from tests alone", h["mark"], 60.0)
check("undetermined: due weight", h["due_weight"], 40.0)

print("\nFAILURES:", failures)
sys.exit(1 if failures else 0)
