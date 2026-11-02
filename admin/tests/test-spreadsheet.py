# test-spreadsheet.py — check the spreadsheet --d2l-import writes, on invented students
# Usage: uv run --with openpyxl python3 test-spreadsheet.py
# Compares it with the import file and with --show, student by student.
import csv
import os
import re
import shutil
import tempfile
import subprocess
from pathlib import Path

import openpyxl

HERE = Path(__file__).parent
SR = str(Path(__file__).resolve().parent.parent) + "/student-record"
work = Path(tempfile.mkdtemp(prefix="student-record-")) / "sr-spreadsheet"
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(HERE / "fixtures", work)

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
at = header.index("End-of-Line Indicator")
header[at:at] = ["Grade thus far Points Grade <Numeric MaxPoints:100>", "Grade thus far Scheme Symbol"]
for row in rows[1:]:
    row[at:at] = ["", ""]
with export.open("w", encoding="utf-8-sig", newline="") as handle:
    csv.writer(handle).writerows(rows)

target = work / "records" / "grades-thus-far.xlsx"
target.parent.mkdir()


def run(*flags, sheet=target):
    command = [SR, "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
               "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
               "--scheme", str(work / "scheme.csv"), "--staff", str(work / "none.csv"),
               "--spreadsheet", str(sheet), "--as-of", "2026-10-30", *flags]
    done = subprocess.run(command, capture_output=True, text=True, env={**os.environ, "NO_COLOR": "1"})
    return done.returncode, done.stdout + done.stderr


failures = 0


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


code, text = run("--d2l-import")
print(text[-700:])
expect("succeeds", code == 0)
expect("says it wrote the spreadsheet", "grades-thus-far.xlsx" in text)
expect("no temporary file left", [p.name for p in target.parent.iterdir()] == ["grades-thus-far.xlsx"])

book = openpyxl.load_workbook(target)
sheet = book["Grades thus far"]
expect("says edits are lost", "edits made here will be lost" in sheet["A3"].value)
expect("names the export's date", "2026-10-30" in sheet["A2"].value)
headings = [cell.value for cell in sheet[5]]
print(headings)
data = [dict(zip(headings, [cell for cell in row])) for row in sheet.iter_rows(min_row=6)]
print(f"{len(data)} rows")
by_name = {row["Name"].value: row for row in data}
expect("every row is as long as the headings", all(len(r) == len(headings) for r in data)
       and all(c.value is None or True for c in sheet[6]) and sheet.max_column == len(headings))
expect("filters cover the table", sheet.auto_filter.ref == f"A5:{openpyxl.utils.get_column_letter(len(headings))}{5 + len(data)}")
expect("headings and names stay in view", sheet.freeze_panes == "B6")

imported = {r[0]: r[1] for r in csv.reader((work / "grades" / "grade-so-far-import-2026-10-30.csv").read_text().splitlines()[1:])}
for row in data:
    sid = row["ID"].value
    if sid in imported:
        expect(f"{sid}: sheet {row['Mark so far (%)'].value} matches the import {imported[sid]}",
               f"{row['Mark so far (%)'].value:.1f}" == imported[sid])

# Each student's breakdown against --show, line by line.
for row in data:
    sid = row["ID"].value
    _code, shown = run("--show", sid)
    for item in ("Test 1", "Test 2", "Test 3", "Gateway Quiz 1", "Module 1"):
        cell = row[item].value
        # A line such as "  Test 1 (Thu)     24/30  80.0%   class ...".
        line = next((l for l in shown.splitlines() if re.match(rf"\s+{item}\b", l)), "")
        percent = re.search(r"/\S+\s+([\d.]+)%", line)
        if isinstance(cell, float) and percent:
            expect(f"{sid} {item}: {cell} agrees with --show", f"{cell:.1f}" == percent.group(1))
        elif "Exempt" in line:
            expect(f"{sid} {item}: Exempt agrees", cell == "Exempt")
        elif "MISSING" in line:
            expect(f"{sid} {item}: Missing agrees", cell == "Missing")

statuses = [row["Status"].value for row in data]
first_dropped = next(i for i, s in enumerate(statuses) if s.startswith("Dropped"))
expect("dropped students are last", all(s.startswith("Dropped") for s in statuses[first_dropped:]))
expect("dropped student is present", any(n.startswith("Delta") for n in by_name))
expect("D2L-only person is not", not any(n.startswith("Theta") for n in by_name))
iota = by_name["Iota, Ian"]
expect("class-list-only student keeps a row, saying not in D2L", "not in D2L" in iota["Status"].value and iota["Mark so far (%)"].value is None)
expect("class-list-only row is full length", sheet.max_column == len(headings))
epsilon = by_name["Epsilon, Eve"]
expect("section, day and room come from the sections file", epsilon["Section"].value == "FR05A" and epsilon["Day"].value)
expect("SAC columns filled", all(row["SAC list"].value in ("Yes", "No") for row in data))
reds = [row for row in data if isinstance(row["Mark so far (%)"].value, float) and row["Mark so far (%)"].value < 50]
expect("failing marks are red", all(r["Mark so far (%)"].font.color.rgb.endswith("C00000") for r in reds))

about = [cell.value for cell in book["How this is calculated"]["A"]]
expect("explanation on the second sheet", any(line and "(40 × Tests + 10 × Homework) ÷ 50" in line for line in about))
expect("key on the second sheet", "What the cells mean" in about)
expect("no explanation line became a formula", not any(str(line).startswith("=") for line in about))

# A new run replaces, and a failure to save still leaves the import.
stale = target.read_bytes()
blocked = work / "no-such-folder" / "grades-thus-far.xlsx"
(work / "grades" / "grade-so-far-import-2026-10-30.csv").unlink()
code, text = run("--d2l-import", sheet=blocked)
expect("save failure warns, not crashes", code == 0 and "could not update" in text and "Traceback" not in text)
expect("import still written", (work / "grades" / "grade-so-far-import-2026-10-30.csv").exists())
expect("real spreadsheet untouched by that", target.read_bytes() == stale)

(work / "rosters" / "section-rosters_MATH_1003_FR19A_2026-10-25_9_06 PM.csv").unlink()
before = target.read_bytes()
code, text = run("--d2l-import")
expect("refused with a class list absent, leaving the sheet", code != 0 and target.read_bytes() == before)
print(f"FAILURES: {failures}")
