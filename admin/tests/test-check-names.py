# test-check-names.py — check what --check names, on invented students and helpers
# Usage: uv run --with openpyxl python3 test-check-names.py
# Copies the invented data in sr/ and adds D2L-only people. The staff matched are the
# real TA and instructor names from course-info, which is what the matching reads.
import csv
import os
import shutil
import tempfile
import subprocess
from pathlib import Path

HERE = Path(__file__).parent
SR = str(Path(__file__).resolve().parent.parent) + "/student-record"
work = Path(tempfile.mkdtemp(prefix="student-record-")) / "sr-check"
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(HERE / "fixtures", work)

export = sorted((work / "grades").glob("*_GradesExport_*.csv"))[-1]
with export.open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.reader(handle))
header = rows[0]


def d2l_row(student_id, last, first, email=None, **grades):
    row = [""] * len(header)
    row[0:4] = [f"#{student_id}", last, first, email or f"{student_id}@d2l.invalid"]
    for column, value in grades.items():
        row[header.index(column)] = value
    return row


quiz = next(c for c in header if c.startswith("Gateway_Quiz_3 Points"))
test_1 = next(c for c in header if c.startswith("Test 1 (Thu) Points"))
rows += [
    # The instructor who tried a quiz: "C. Allen" in instructors.csv.
    d2l_row("9000001", "Allen", "Courtney", **{quiz: "80"}),
    # An instructor whose D2L first name has a different initial: found by email.
    d2l_row("9000002", "Mehmood", "Zed", "HASSAN.MEHMOOD@unb.ca"),
    # A TA in course-sections.csv, twice under two emails, one with a quiz mark.
    d2l_row("9000003", "Blackmore", "Tim", **{quiz: "50"}),
    d2l_row("9000004", "Blackmore", "Tim"),
    # Same last name and initial as nobody; a helper with no marks and no listing yet.
    d2l_row("9000005", "Helperlast", "Hana"),
    # A stranger with a mark: the case this exists to catch.
    d2l_row("9000006", "Strangerlast", "Sam", **{test_1: "20"}),
    # Shares a last name with an instructor, different initial and email: not staff.
    d2l_row("9000007", "Allen", "Zoe"),
    # Rick in the staff file and Richard in D2L, with quiz marks: found by ID alone.
    d2l_row("9000008", "Nickname", "Richard", **{quiz: "70"}),
    # Goes by something else too, and the file has only their email.
    d2l_row("9000009", "Otherly", "Robert", "bob@d2l.invalid"),
]
with export.open("w", encoding="utf-8-sig", newline="") as handle:
    csv.writer(handle).writerows(rows)

for name, section, sid in (
    ("section-rosters_MATH_1003_FR07A_2026-10-25_9_06 PM.csv", "FR07A", "8000001"),
    ("section-rosters_MATH_1003_FR13A_2026-10-25_9_06 PM.csv", "FR13A", "8000002"),
    ("section-rosters_MATH-1003-FR22A_2026-10-25_9_06 PM.csv", "FR22A", "8000003"),
):
    with (work / "rosters" / name).open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["Student Name", "Student ID", "Email Address"])
        writer.writerow([f"Listonly{section}, Lee", sid, f"{sid}@example.invalid"])

staff_file = work / "staff.csv"


def check():
    command = [SR, "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
               "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
               "--scheme", str(work / "scheme.csv"), "--staff", str(staff_file),
               "--as-of", "2026-10-30", "--check"]
    done = subprocess.run(command, capture_output=True, text=True, env={**os.environ, "NO_COLOR": "1"})
    return done.stdout + done.stderr


failures = 0


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


text = check()
print("\n".join(text.splitlines()[6:24]))
print("...")
expect("no staff file is fine", "NO CLASS LIST" not in text and "Traceback" not in text)
expect("no staff file says so", "not found, so staff are recognised by name only" in text)
expect("Richard named when the file is absent", "Nickname, Richard, 9000008" in text)
expect("instructor with a quiz mark hidden", "Allen, Courtney" not in text)
expect("instructor found by email hidden", "Mehmood" not in text)
expect("TA hidden under both emails", "Blackmore" not in text)
expect("helper with no marks named", "Helperlast, Hana, 9000005" in text and "9000005, marks" not in text)
expect("stranger named with marks", "Strangerlast, Sam, 9000006, marks on 1 listed item(s)" in text)
expect("same surname, other initial still named", "Allen, Zoe, 9000007" in text)
expect("class-list-only still named", "ListonlyFR22A, Lee, FR22A, 8000003" in text)
expect("known staff counted", "known staff:                  4" in text)

staff_file.write_text(
    "Name,note,Email,ID\n"
    "Hana Helperlast,marks the labs,,\n"
    "Rick Nickname,,,#9000008\n"
    "Bob Otherly,,BOB@d2l.invalid,\n"
)
text = check()
expect("helper hidden once listed", "Helperlast" not in text)
expect("Rick hidden by ID though D2L says Richard", "Nickname" not in text)
expect("Bob hidden by email though D2L says Robert", "Otherly" not in text)
expect("no warning when the file is there", "not found, so staff" not in text)
expect("stranger still named", "Strangerlast, Sam" in text)
expect("known staff count rises", "known staff:                  7" in text)

(work / "rosters" / "section-rosters_MATH-1003-FR22A_2026-10-25_9_06 PM.csv").unlink()
text = check()
expect("absent instructor reported", "NO CLASS LIST from HM" in text)
expect("names held back when a list is absent", "Strangerlast" not in text)
expect("counts still given", "not known:" in text)
print(f"FAILURES: {failures}")
