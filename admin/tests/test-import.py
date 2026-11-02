# test-import.py — check --d2l-import on invented students, comparing with --show
# Usage: uv run --with openpyxl python3 test-import.py
# Assumes admin-settings.csv already names grade_so_far_item as "Grade thus far".
import csv
import os
import re
import shutil
import tempfile
import subprocess
from pathlib import Path

HERE = Path(__file__).parent
SR = str(Path(__file__).resolve().parent.parent) + "/student-record"
work = Path(tempfile.mkdtemp(prefix="student-record-")) / "sr-import"
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(HERE / "fixtures", work)

# Rosters for the other instructors, one student each, so that none is absent.
for name, section, sid in (
    ("section-rosters_MATH_1003_FR07A_2026-10-25_9_06 PM.csv", "FR07A", "8000001"),
    ("section-rosters_MATH_1003_FR13A_2026-10-25_9_06 PM.csv", "FR13A", "8000002"),
    ("section-rosters_MATH_1003_FR19A_2026-10-25_9_06 PM.csv", "FR19A", "8000003"),
):
    with (work / "rosters" / name).open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["Student Name", "Student ID", "Email Address"])
        writer.writerow([f"Listonly{section}, Lee", sid, f"{sid}@example.invalid"])

export = sorted((work / "grades").glob("*_GradesExport_*.csv"))[-1]
with export.open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.reader(handle))
header = rows[0]


def add_item(rows, maximum, last_value):
    """Add the grade item to the export, with last week's value for everyone."""
    at = header.index("End-of-Line Indicator")
    header[at:at] = [f"Grade thus far Points Grade <Numeric MaxPoints:{maximum}>", "Grade thus far Scheme Symbol"]
    for row in rows[1:]:
        row[at:at] = [last_value, ""]


def write_export(rows):
    with export.open("w", encoding="utf-8-sig", newline="") as handle:
        csv.writer(handle).writerows(rows)


def run(*flags):
    command = [SR, "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
               "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
               "--scheme", str(work / "scheme.csv"), "--staff", str(work / "none.csv"),
               "--spreadsheet", str(work / "grades-thus-far.xlsx"),
               "--as-of", "2026-10-30", *flags]
    done = subprocess.run(command, capture_output=True, text=True, env={**os.environ, "NO_COLOR": "1"})
    return done.returncode, done.stdout + done.stderr


failures = 0


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


code, text = run("--d2l-import")
expect("refused when the item isn't in the export", code != 0 and "'Grade thus far' is not in the D2L export" in text)
output = work / "grades" / "grade-so-far-import-2026-10-30.csv"
expect("nothing written when refused", not output.exists())

add_item(rows, 100, "12.3")
write_export(rows)
code, text = run("--d2l-import")
print(text)
expect("succeeds", code == 0)
raw = output.read_text()
print(raw)
lines = raw.splitlines()
expect("header is D2L's", lines[0] == "OrgDefinedId,Grade thus far Points Grade,End-of-Line Indicator")
written = {row[0]: row for row in csv.reader(lines[1:])}
expect("every row ends with #", all(row[2] == "#" for row in written.values()))
expect("IDs have no #", not any(key.startswith("#") for key in written))
expect("export not mistaken for the output", "_GradesExport_" not in output.name)

# Agrees with --show, student by student.
for sid, row in written.items():
    _code, shown = run("--show", sid)
    match = re.search(r"MARK SO FAR\s+([\d.]+)%", shown)
    expect(f"{sid}: file {row[1]} agrees with --show {match.group(1)}", match and match.group(1) == row[1])

expect("dropped left out", "1000004" not in written or "DROPPED" not in run("--show", "1000004")[1])
expect("D2L-only (Theta) left out", "1000008" not in written)
expect("class-list-only named", "left out, not in D2L: Iota, Ian" in text)
expect("partly recorded test flagged", "Before you upload" in text and "recorded" in text)

# A second run after a re-export ignores last week's value.
first = raw
rows_again = [list(row) for row in rows]
at = header.index("Grade thus far Points Grade <Numeric MaxPoints:100>")
for row in rows_again[1:]:
    row[at] = "99"
write_export(rows_again)
run("--d2l-import")
expect("last week's value plays no part", output.read_text() == first)

# An item out of 50 gets half.
header[at] = "Grade thus far Points Grade <Numeric MaxPoints:50>"
write_export(rows)
run("--d2l-import")
halved = {r[0]: float(r[1]) for r in csv.reader(output.read_text().splitlines()[1:])}
expect("scaled to the item's maximum",
       all(abs(halved[k] - float(written[k][1]) / 2) < 0.051 for k in written))
header[at] = "Grade thus far Points Grade <Numeric MaxPoints:100>"
write_export(rows)

output.unlink()
(work / "rosters" / "section-rosters_MATH_1003_FR19A_2026-10-25_9_06 PM.csv").unlink()
code, text = run("--d2l-import")
expect("refused when a class list is absent", code != 0 and "no class list from HM" in text and not output.exists())
print(f"FAILURES: {failures}")
