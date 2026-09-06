#!/usr/bin/env python3
#
# build-d2l-import.py — build a D2L question import from pool .tex files
# Usage: build-d2l-import.py [-o DIR] [--note TEXT] POOL.tex ...
#
# Reads the pool files that already define a quiz — their \importproblem lines
# say which problems are in which pool, and their points= says what each is
# worth — and emits:
#
#   <quiz>_questions.csv     bulk import for D2L's question library
#   <quiz>_paste-sheet.md    the same questions as LaTeX, for typing them into
#                            D2L's editor by hand instead
#
# The pool .tex is the single source of truth. Nothing about a quiz is repeated
# here, so the PDF you inspect and the questions you upload cannot drift apart.
#
# ---------------------------------------------------------------------------
# WHAT D2L'S CSV IMPORT ACTUALLY DOES — tested 2026-09-06, not guessed
# ---------------------------------------------------------------------------
# QuestionText is PLAIN TEXT. The importer HTML-escapes it, so markup arrives
# intact and is then DISPLAYED rather than rendered — a MathML attempt
# previewed as a wall of visible `<math display="block" xmlns=...>'. An <img>
# tag fails the same way. So the CSV cannot carry mathematics as text at all,
# and QuestionText is only ever a short note.
#
# It also renders BELOW the image, so it can never be a lead-in. Whatever the
# question says has to be inside the picture. That is why `build-images'
# renders the whole self-contained problem rather than splitting prose out.
#
# The Image field works, with one prerequisite that fails silently:
#
#     THE IMAGE MUST ALREADY EXIST at /content/<course path>/images/ BEFORE
#     the import runs. It is a reference, not an embed. Import first and every
#     question arrives with nothing where the picture should be — and no
#     broken-image marker to say why.
#
# Neither route creates a POOL. The CSV fills the question library; the random
# section is built by hand in the quiz editor. That is why Title and ID carry
# the pool name — they are what tells you which question belongs where.
# ---------------------------------------------------------------------------

import argparse
import csv
import pathlib
import re
import sys

# The note shown under every question image. Not an instruction to answer in
# D2L: the handwritten work is submitted separately and the D2L text box is
# left empty, so there is no answer key here for anyone to read either.
DEFAULT_NOTE = ("(NOTE: you do not need to enter your answer here; "
                "submit your handwritten work separately.)")

# `%! key: value' magic comments, the same idiom build-pdfs uses for `%! views:'.
MAGIC = re.compile(r"^%!\s*([a-z0-9-]+)\s*:\s*(.*?)\s*$", re.M)

# \importproblem[OPTS]{DIR}{FILE} -- OPTS optional.
IMPORT = re.compile(r"\\importproblem\s*(?:\[([^\]]*)\])?\s*\{([^}]*)\}\s*\{([^}]*)\}")

# A braced value in a ProblemMeta block, one key per line by convention.
META_NAME = re.compile(r"^\s*name\s*=\s*\{(.*?)\}\s*,?\s*$", re.M)


def parse_pool(path):
    """A pool .tex -> its magic-comment settings and its member problems."""
    text = path.read_text(encoding="utf-8")
    magic = {k: v for k, v in MAGIC.findall(text)}

    members = []
    for opts, dirpart, filepart in IMPORT.findall(text):
        # The import directory is relative to the pool file, exactly as LaTeX
        # resolves it, so the same string works for us and for the compiler.
        problem = (path.parent / dirpart / filepart).resolve()
        if not problem.is_file():
            sys.exit(f"build-d2l-import: {path.name} imports a file that does "
                     f"not exist:\n  {problem}")
        points = None
        m = re.search(r"points\s*=\s*([0-9]+)", opts or "")
        if m:
            points = m.group(1)
        members.append({"path": problem, "points": points})

    if not members:
        sys.exit(f"build-d2l-import: {path.name} has no \\importproblem lines")
    return magic, members


def problem_label(problem):
    """The ProblemMeta `name' -- the short human label for this problem."""
    m = META_NAME.search(problem.read_text(encoding="utf-8"))
    return m.group(1) if m else problem.stem.replace("-", " ")


def strip_solutions(body):
    """Remove solution environments, including nested [notitle] ones in qparts.

    Done by scanning rather than regex: a `qparts' problem has one solution per
    part, and a non-greedy regex would stop at the first \\end{solution} while a
    greedy one would swallow everything between the first and last.
    """
    out, i = [], 0
    while True:
        start = body.find(r"\begin{solution}", i)
        if start == -1:
            out.append(body[i:])
            return "".join(out)
        out.append(body[i:start])
        depth, j = 0, start
        while j < len(body):
            if body.startswith(r"\begin{solution}", j):
                depth += 1
                j += len(r"\begin{solution}")
            elif body.startswith(r"\end{solution}", j):
                depth -= 1
                j += len(r"\end{solution}")
                if depth == 0:
                    break
            else:
                j += 1
        i = j


def tidy_math(s):
    """Normalise whitespace, and drop trailing sentence punctuation.

    LaTeX convention puts the full stop INSIDE the display -- `\\[ y = 0 . \\]'
    -- but that period is prose, not mathematics. Pasted into D2L's equation
    editor it would set a stray dot after the equation.
    """
    return re.sub(r"[\s.,;]+$", "", " ".join(s.split()))


def question_blocks(problem):
    """The statement as ("text"|"math"|"display"|"break", content) blocks.

    Only the paste sheet uses this. The CSV carries the mathematics as an
    image, so an imperfect parse here can never affect what gets uploaded.
    """
    text = problem.read_text(encoding="utf-8")
    m = re.search(r"\\begin\{problem\}(.*)\\end\{problem\}", text, re.S)
    if not m:
        return []
    body = strip_solutions(m.group(1))

    # Structural markup that carries no words. \qpart becomes a break so the
    # parts of a multi-part question stay on separate lines.
    body = re.sub(r"\\begin\{qparts\}|\\end\{qparts\}", "", body)
    body = re.sub(r"\\qpart\s*", "@@BREAK@@", body)

    # re.split with one capturing group alternates: outside, inside, outside...
    # so an odd index is the captured math and an even one the text around it.
    out = []
    for i, chunk in enumerate(re.split(r"\\\[(.*?)\\\]", body, flags=re.S)):
        if i % 2:
            out.append(("display", tidy_math(chunk)))
            continue
        for j, piece in enumerate(re.split(r"\$([^$]*)\$", chunk)):
            if j % 2:
                out.append(("math", tidy_math(piece)))
                continue
            # A break belongs BETWEEN segments, not on an empty one -- two
            # \qpart bodies that both end and begin with words would otherwise
            # be run together into a single line.
            for k, seg in enumerate(piece.split("@@BREAK@@")):
                if k:
                    out.append(("break", ""))
                seg = " ".join(seg.split())
                if seg:
                    out.append(("text", seg))
    # Collapse runs of breaks and drop leading/trailing ones.
    tidy = []
    for kind, content in out:
        if kind == "break" and (not tidy or tidy[-1][0] == "break"):
            continue
        tidy.append((kind, content))
    while tidy and tidy[-1][0] == "break":
        tidy.pop()
    return tidy


def build(pools, outdir, note):
    quiz = course = None
    questions = []

    for pool_path in pools:
        magic, members = parse_pool(pool_path)
        course = magic.get("d2l-course", course)
        quiz = magic.get("d2l-quiz", quiz)
        pool = magic.get("d2l-pool") or pool_path.stem
        pool_name = magic.get("d2l-pool-name", "")

        for n, member in enumerate(members, start=1):
            slug = member["path"].stem
            label = problem_label(member["path"])
            pretty = f"{pool} pool ({pool_name})" if pool_name else f"{pool} pool"
            questions.append({
                "id": f"{course}-{quiz}-{pool}-{n}",
                "title": f"{quiz} Quiz - {pretty} - {label}",
                "points": member["points"] or "1",
                "image": f"images/{slug}.png",
                "blocks": question_blocks(member["path"]),
                "label": label,
                "pretty": pretty,
            })

    if course is None or quiz is None:
        sys.exit("build-d2l-import: the pool files must carry `%! d2l-course:' "
                 "and `%! d2l-quiz:' magic comments")

    outdir.mkdir(parents=True, exist_ok=True)
    return (write_csv(outdir / f"{quiz}_questions.csv", questions, note),
            write_paste_sheet(outdir / f"{quiz}_paste-sheet.md", questions, note))


CSV_HEADER = [
    "// D2L question import, generated by build-d2l-import.py from the pool",
    "// .tex files. Edit those, not this.",
    "//",
    "// UPLOAD THE IMAGES FIRST. The Image lines are REFERENCES, not embeds:",
    "// each file must already exist at /content/<course path>/images/ when",
    "// the import runs. Import before they are there and every question",
    "// arrives with nothing where the picture should be, and NO broken-image",
    "// marker to tell you why.",
    "//",
    "// QuestionText is plain text -- D2L HTML-escapes this field, so markup",
    "// and MathML are displayed rather than rendered. It also renders BELOW",
    "// the image, so it can only ever be a trailing note.",
    "//",
    "// This creates the questions; it does NOT create the pool. Build the",
    "// random section in the quiz editor -- the Title of each question says",
    "// which pool it belongs to.",
]


def write_csv(dest, questions, note):
    # Plain utf-8, NO BOM. The instructions say "CSV UTF-8", which in Excel
    # means a BOM -- but D2L's own sample file has none, and a BOM makes the
    # first field read as an unrecognised key rather than a comment.
    with dest.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, quoting=csv.QUOTE_MINIMAL)
        for line in CSV_HEADER:
            w.writerow([line, "", "", "", ""])
        for q in questions:
            w.writerow(["//", "", "", "", ""])
            w.writerow([f"// {q['title']}", "", "", "", ""])
            w.writerow(["NewQuestion", "WR", "", "", ""])
            w.writerow(["ID", q["id"], "", "", ""])
            w.writerow(["Title", q["title"], "", "", ""])
            w.writerow(["QuestionText", note, "", "", ""])
            w.writerow(["Points", q["points"], "", "", ""])
            w.writerow(["Image", q["image"], "", "", ""])
    return dest


PASTE_HEADER = """# {quiz} quiz — paste sheet

For typing these into D2L's question editor by hand rather than importing the
CSV. Both routes work; this one is slower, but the mathematics ends up
selectable, reflowing and readable by a screen reader, which an image is not.

Each equation is LaTeX. Put the cursor where it belongs, open
**Equation → LaTeX**, and paste. `⟦…⟧` marks where an insert goes.

Set each question to **Written Response**. Nothing is auto-graded and no answer
is expected in D2L — the note below each question says so, and the worked
solution arrives through the upload instead.

Neither route creates a pool, so build the random sections in the quiz editor.

Generated by `build-d2l-import.py` from the pool .tex files — edit those.

---
"""


def join_line(parts):
    """Join blocks into a line, without a space before closing punctuation.

    The prose full stop after an inline equation arrives as its own block, so a
    plain " ".join would set "y'(0) = 0 ." with a floating period.
    """
    line = ""
    for part in parts:
        if line and not re.match(r"^[.,;:)?!]", part):
            line += " "
        line += part
    return line


def write_paste_sheet(dest, questions, note):
    out = [PASTE_HEADER.format(quiz=questions[0]["title"].split()[0])]
    for q in questions:
        out.append(f"\n## {q['title']}\n\n")
        out.append(f"`{q['id']}` · Written Response · {q['points']} points\n\n")
        line = []
        for kind, content in q["blocks"]:
            if kind == "text":
                line.append(content)
            elif kind == "math":
                line.append(f"⟦{content}⟧")
            else:
                if line:
                    out.append("> " + join_line(line) + "\n>\n")
                    line = []
                if kind == "display":
                    out.append(f"> ⟦{content}⟧   ← display equation\n>\n")
        if line:
            out.append("> " + join_line(line) + "\n>\n")
        out.append(f"\n> _{note}_\n")
        out.append("\nEquations to paste, in order:\n\n```\n")
        out.extend(c + "\n" for k, c in q["blocks"] if k in ("math", "display"))
        out.append("```\n")
    dest.write_text("".join(out), encoding="utf-8")
    return dest


def main():
    ap = argparse.ArgumentParser(
        description="Build a D2L question import from pool .tex files. The "
                    "pool files are the source of truth: their \\importproblem "
                    "lines say what is in each pool and their points= says "
                    "what each question is worth.",
        epilog="Pure stdlib; nothing external is needed.")
    ap.add_argument("pools", nargs="+", type=pathlib.Path,
                    help="the pool .tex files, in question order")
    ap.add_argument("-o", "--out", type=pathlib.Path, default=None,
                    help="where to write (default: beside the first pool file)")
    ap.add_argument("--note", default=DEFAULT_NOTE,
                    help="the text shown under every question image")
    args = ap.parse_args()

    for p in args.pools:
        if not p.is_file():
            sys.exit(f"build-d2l-import: no such file: {p}")

    outdir = args.out or args.pools[0].parent
    for dest in build(args.pools, outdir, args.note):
        print(f"wrote {dest}")

    # The CSV's Image lines are only as good as the pictures beside them, and
    # the two are produced by different tools. Print the exact command that
    # makes the matching set, derived from the same pool files, so the list
    # never has to be retyped and cannot drift from what the CSV expects.
    members = []
    for pool in args.pools:
        _, ms = parse_pool(pool)
        members.extend(str(m["path"]) for m in ms)
    print("\nTo (re)build the images these reference:\n")
    print(f"  build-images --no-solutions -o {outdir / 'images'} \\")
    print("      " + " \\\n      ".join(members))
    return 0


if __name__ == "__main__":
    sys.exit(main())
