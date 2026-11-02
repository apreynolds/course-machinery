# test-emails.py — check --emails on invented students, with a stand-in for pbcopy
# Usage: uv run --with openpyxl python3 test-emails.py
import csv
import os
import shutil
import tempfile
import subprocess
from pathlib import Path

HERE = Path(__file__).parent
SR = str(Path(__file__).resolve().parent.parent) + "/student-record"
work = Path(tempfile.mkdtemp(prefix="student-record-")) / "sr-emails"
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(HERE / "fixtures", work)
for old in (work / "rosters").iterdir():
    old.unlink()


def roster(name, rows):
    with (work / "rosters" / name).open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["Student Name", "Student ID", "Email Address"])
        writer.writerows(rows)


roster("section-rosters_MATH_1003_FR01A_2026-10-25_9_06 PM.csv", [
    ["Alpha, Ann", "7000001", "ann@x.invalid"],
    ["Beta, Bo cross-listed as MATH*1003*FR02A", "7000002", "bo@x.invalid"],
    ["Gone, Cy (Dropped 2026-10-01)", "7000003", "cy@x.invalid"],
    ["Blank, Dee", "7000004", ""],
    ["Twice, Eve", "7000005", "eve@x.invalid"],
    ["Twice, Eve cross-listed as MATH*1003*FR02A", "7000005", "eve@x.invalid"],
    ["Mover, Mo (Dropped 2026-10-01)", "7000006", "mo@x.invalid"],
    ["Mover, Mo cross-listed as MATH*1003*FR02A", "7000006", "mo@x.invalid"],
])
roster("section-rosters_MATH_1003_FR07A_2026-10-25_9_06 PM.csv", [["Cee, Al", "7100001", "al@x.invalid"]])
roster("section-rosters_MATH_1003_FR13A_2026-10-25_9_06 PM.csv", [["Pee, Al", "7200001", "pl@x.invalid"]])

# A stand-in for pbcopy that saves what it was given.
fakebin = work / "fakebin"
fakebin.mkdir()
clipboard = work / "clipboard.txt"
fake = fakebin / "pbcopy"
fake.write_text(f'#!/bin/bash\ncat > "{clipboard}"\n')
fake.chmod(0o755)


def emails(section):
    clipboard.unlink(missing_ok=True)
    command = [SR, "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
               "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
               "--scheme", str(work / "scheme.csv"), "--staff", str(work / "staff.csv"),
               "--as-of", "2026-10-30", "--emails", section]
    env = {**os.environ, "PATH": f"{fakebin}:{os.environ['PATH']}", "NO_COLOR": "1"}
    done = subprocess.run(command, capture_output=True, text=True, env=env)
    copied = clipboard.read_text() if clipboard.exists() else None
    return done.returncode, done.stdout + done.stderr, copied


failures = 0
# FR01A's TA, Tim Blackmore, has two emails; FR02A's, Kieran Leblanc, has no row.
(work / "staff.csv").write_text(
    "name,email,ID\ntim blackmore,tim1@x.invalid,1\nTim Blackmore,Tim2@x.invalid,2\n"
)


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


code, text, copied = emails("FR01A")
print(text)
expect("FR01A has Ann and Eve only", copied == "ann@x.invalid; eve@x.invalid")
expect("day and room shown", "Tutorial: Thurs, Tilley 205" in text)
expect("TA and both emails shown", "TA: Tim Blackmore, tim1@x.invalid, Tim2@x.invalid" in text)
expect("TA's email not copied", "tim1" not in copied)
expect("dropped left out", "cy@x.invalid" not in text)
expect("a student with no email is named", "No email on record for Blank, Dee" in text)
expect("count and class list age given", "4 registered" not in text and "3 registered" in text and "5 days old" in text)

code, text, copied = emails("fr02a")
print(text)
expect("lower case accepted", code == 0)
expect("TA with no row says so", "TA: Kieran Leblanc, no email in the staff file" in text)
expect("FR02A has Bo, a mover and the double-registered Eve",
       sorted(copied.split("; ")) == ["bo@x.invalid", "eve@x.invalid", "mo@x.invalid"])

code, text, copied = emails("FR99A")
expect("unknown section refused", code != 0 and "not in course-sections.csv" in text and copied is None)
code, text, copied = emails("FR22A")
expect("no class list refused", code != 0 and "no class list from HM" in text and copied is None)
code, text, copied = emails("FR03A")
expect("empty section refused", code != 0 and "nobody is registered in FR03A" in text and copied is None)
print(f"FAILURES: {failures}")
