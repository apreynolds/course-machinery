# test-exemptions.py — check --exemptions on invented students and an invented form
# Usage: uv run --with openpyxl python3 test-exemptions.py
# FR01A writes on Thu and FR05A on Tue. IDs are in the invented class list in sr/.
import csv
import os
import shutil
import tempfile
import subprocess
from pathlib import Path

import openpyxl

HERE = Path(__file__).parent
SR = str(Path(__file__).resolve().parent.parent) + "/student-record"
work = Path(tempfile.mkdtemp(prefix="student-record-")) / "sr-exemptions"
shutil.rmtree(work, ignore_errors=True)
shutil.copytree(HERE / "fixtures", work)

# Rosters for the other instructors, so that none is absent.
for name, section, sid in (
    ("section-rosters_MATH_1003_FR07A_2026-10-25_9_06 PM.csv", "FR07A", "8000001"),
    ("section-rosters_MATH_1003_FR13A_2026-10-25_9_06 PM.csv", "FR13A", "8000002"),
    ("section-rosters_MATH_1003_FR19A_2026-10-25_9_06 PM.csv", "FR19A", "8000003"),
):
    with (work / "rosters" / name).open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["Student Name", "Student ID", "Email Address"])
        writer.writerow([f"Listonly{section}, Lee", sid, f"{sid}@example.invalid"])

# Blank Test 3 for everyone, then set the cases below, so each case is known exactly.
export = sorted((work / "grades").glob("*_GradesExport_*.csv"))[-1]
with export.open(encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.reader(handle))
header = rows[0]


def column(item):
    return next(at for at, name in enumerate(header) if name.startswith(f"{item} Points Grade"))


def set_grade(sid, item, value):
    for row in rows[1:]:
        if row[0].lstrip("#") == sid:
            row[column(item)] = value
            return
    raise SystemExit(f"{sid} is not in the invented export")


for row in rows[1:]:
    for item in ("Test 3 (Tue)", "Test 3 (Thu)"):
        row[column(item)] = ""
    # So that nothing already in the fixture shows up as unexplained.
    row[:] = ["" if cell.casefold() == "exempt" else cell for cell in row]

set_grade("1000002", "Test 3 (Thu)", "Exempt")   # Beta: done, RECORDED blank
set_grade("1000003", "Test 3 (Thu)", "22")       # Gamma: has a mark
set_grade("1000006", "Test 3 (Tue)", "25")       # Zeta: Thu section, wrote the Tue version
set_grade("1000007", "Test 3 (Thu)", "Exempt")   # Eta: done and RECORDED, no complaint
set_grade("1000012", "Test 3 (Thu)", "Exempt")   # Mu: Exempt, no form response
set_grade("1000011", "Test 2 (Tue)", "")         # Lambda: nothing yet, so the file gets them
set_grade("1000001", "Test 1 (Thu)", "Exempt")   # Alpha: Exempt, but the form's answer was NO
set_grade("1000013", "Test 2 (Thu)", "Exempt")   # Nu: Exempt, and the row is closed
set_grade("1000006", "Test 2 (Thu)", "")         # Zeta: would upload, but the row is closed
set_grade("1000006", "Test 2 (Tue)", "")
set_grade("1000012", "Test 2 (Thu)", "")         # Mu: says yes, D2L disagrees
set_grade("1000012", "Test 2 (Tue)", "")

with export.open("w", encoding="utf-8-sig", newline="") as handle:
    csv.writer(handle).writerows(rows)

REASON = "PRIVATE-REASON-surgery"
HEADINGS = ["Id", "Start time", "Completion time", "Email", "Name", "Student ID", "First name", "Last name",
            "Please select the Test you are requesting an exemption from:",
            "Please give a brief explanation of why you are requesting an exemption;.",
            "By being exempt", "This form is all you need", "APPROVED", "RECORDED"]


def response(number, email, sid, first, last, test, approved="YES", recorded=None):
    return [number, "2026-10-01 10:00:00", "2026-10-01 10:01:00", email, f"{first} {last}", sid,
            first, last, test, REASON, "Understood.", "Understood.", approved, recorded]


FORM = [
    response(1, "1000001@example.invalid", 1000001, "Ann", "Alpha", "Test 3"),                       # upload, Thu
    response(2, "1000002@example.invalid", "1000002", "Bo", "Beta", "Test 3"),                       # fill in RECORDED
    response(3, "1000003@example.invalid", 1000003, "Gil", "Gamma", "Test 3"),                       # has a mark
    response(4, "1000004@example.invalid", 1000004, "Dee", "Delta", "Test 3"),                       # dropped
    response(5, "1000005@example.invalid", 1000005, "Eve", "Epsilon", "Test 3", "YES with follow up"),  # upload, Tue
    response(6, "1000006@example.invalid", 1000006, "Zed", "Zeta", "Test 3"),                        # other version
    response(7, "1000007@example.invalid", 1000007, "Élodie", "Eta", "Test 3", "YES", "yes"),        # all done
    response(8, "1000009@example.invalid", 1000010, "Ian", "Iota", "Test 3"),                        # typed Kappa's ID
    response(9, "1000011@example.invalid", 1234567, "Lee", "Lambda", "Test 2"),                      # typo, by email
    response(10, "someone@else.invalid", 1000013, "Nia", "Nu", "Test 3"),                            # other sign-in, name agrees
    response(11, "1000001@example.invalid", 1000001, "Ann", "Alpha", "Test 3"),                      # duplicate of row 2
    response(12, "1000010@example.invalid", 1000010, "Kim", "Kappa", "Test 3", "YES", "yes"),        # RECORDED, not in D2L
    response(13, "1000001@example.invalid", 1000001, "Ann", "Alpha", "Test 9"),                      # no such test
    response(14, "stranger@else.invalid", 7777777, "Sam", "Stranger", "Test 3"),                     # nobody
    response(15, "1000001@example.invalid", 1000001, "Ann", "Alpha", "Test 2", None),                # undecided
    response(16, "1000001@example.invalid", 1000001, "Ann", "Alpha", "Test 1", "NO"),                # declined
    response(17, "1000004@example.invalid", 1000004, "Dee", "Delta", "Test 2", "YES", "No need; DROPPED"),  # closed, dropped
    response(18, "stranger@else.invalid", 7777777, "Sam", "Stranger", "Test 2", "YES", "Not ours"),  # closed, unknown
    response(19, "1000013@example.invalid", 1000013, "Nia", "Nu", "Test 2", "YES", "Sorted by phone"),  # closed, Exempt
    response(20, "1000006@example.invalid", 1000006, "Zed", "Zeta", "Test 2", "YES", "No need"),     # closed, would upload
    response(21, "1000012@example.invalid", 1000012, "Max", "Mu", "Test 2", "YES", "Yes, Nov 1"),    # a claim, unmet
]
workbook = work / "form.xlsx"
book = openpyxl.Workbook()
sheet = book.active
sheet.append(HEADINGS)
for row in FORM:
    sheet.append(row)
book.save(workbook)
before = workbook.read_bytes()


def run(*flags, form=workbook):
    command = [SR, "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
               "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
               "--scheme", str(work / "scheme.csv"), "--staff", str(work / "none.csv"),
               "--as-of", "2026-11-01", "--exemption-workbook", str(form), *flags]
    done = subprocess.run(command, capture_output=True, text=True, env={**os.environ, "NO_COLOR": "1"})
    return done.returncode, done.stdout + done.stderr


failures = 0


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


def line_with(text, *words):
    return any(all(word in line for word in words) for line in text.splitlines())


def rows_of(name):
    path = work / "grades" / name
    return list(csv.reader(path.read_text().splitlines())) if path.exists() else []


code, text = run("--exemptions")
print(text)
expect("succeeds", code == 0)
thu = rows_of("exemption-import-Test-3-Thu-2026-11-01.csv")
tue = rows_of("exemption-import-Test-3-Tue-2026-11-01.csv")
print(thu, tue)
expect("Thu header is D2L's", thu and thu[0] == ["OrgDefinedId", "Test 3 (Thu) Points Grade", "End-of-Line Indicator"])
thu_ids = {row[0] for row in thu[1:]}
tue_ids = {row[0] for row in tue[1:]}
expect("Thu section's student in the Thu file, once", [r[0] for r in thu[1:]].count("1000001") == 1)
expect("every row says Exempt and ends with #", all(r[1:] == ["Exempt", "#"] for r in thu[1:] + tue[1:]))
expect("Tue section's follow-up student in the Tue file", "1000005" in tue_ids and "1000005" not in thu_ids)
expect("other sign-in with agreeing name is in", "1000013" in thu_ids)
wrong = {"1000002", "1000003", "1000004", "1000006", "1000007", "1000009", "1000010", "1000012", "7777777"}
expect("nobody else in any file", not (wrong & (thu_ids | tue_ids)))
test2 = rows_of("exemption-import-Test-2-Tue-2026-11-01.csv")
expect("typo'd ID matched by email goes in by the real ID", any(r[0] == "1000011" for r in test2[1:]))
expect("typo'd ID itself never written", not any(r[0] == "1234567" for r in test2))

expect("follow-up no longer listed", "Follow up" not in text and not line_with(text, "Epsilon, Eve", "@example.invalid"))
closed_part = text.split("Closed off in RECORDED")[1].split("Not decided yet")[0] if "Closed off in RECORDED" in text else ""
look_part = text.split("Look at these")[1].split("Closed off in RECORDED")[0]
expect("closed note echoed verbatim", "Delta, Dee, Test 2, row 18: No need; DROPPED" in closed_part)
expect("closed row with nobody matching still echoed", "Sam Stranger, Test 2, row 19: Not ours" in closed_part)
expect("closed rows not in Look at these", "row 18" not in look_part and "row 19" not in look_part and "row 21" not in look_part)
thu2 = rows_of("exemption-import-Test-2-Thu-2026-11-01.csv")
expect("closed row in no file", not any(r[0] == "1000006" for r in thu2))
expect("Exempt on a closed row isn't unexplained", not line_with(text, "Nu, Nia, FR01A, Test 2 (Thu)"))
expect("a yes with extra words is still checked", line_with(look_part, "Mu, Max", "row 22", "RECORDED is filled in"))
expect("a closed column in the table", "closed" in text.splitlines()[1])
expect("fill in RECORDED names row 3", line_with(text, "Beta, Bo", "row 3"))
expect("all-done student not in the fill-in list", not line_with(text, "Eta, ", "row 8"))
expect("mark reported", line_with(text, "Gamma, Gil", "has a mark on Test 3 (Thu)"))
expect("other version's mark reported", line_with(text, "Zeta, Zed", "has a mark on Test 3 (Tue)"))
expect("dropped reported", line_with(text, "Delta, Dee dropped"))
expect("wrong ID refused, naming both", line_with(text, "ID 1000010 is Kappa, Kim's", "Iota, Ian's"))
expect("match by email said", line_with(text, "Lambda, Lee", "matched by email", "1234567"))
expect("duplicate said", line_with(text, "Alpha, Ann already has row 2"))
expect("RECORDED but not in D2L said", line_with(text, "Kappa, Kim", "RECORDED is filled in"))
expect("unknown test said", line_with(text, "'Test 9' is not in assessments.csv"))
expect("stranger said", line_with(text, "nobody has ID 7777777"))
expect("undecided said", line_with(text, "Alpha", "Test 2", "row 16"))
expect("declined said", line_with(text, "APPROVED says 'NO'"))
expect("Exempt with no form said", line_with(text, "Mu, Max", "Test 3 (Thu)"))
expect("Exempt whose response was declined is listed as unexplained", line_with(text, "Alpha, Ann, FR01A, Test 1 (Thu)"))
expect("explanation never printed", REASON not in text)
expect("explanation never written", not any(REASON in p.read_text(errors="ignore")
                                            for p in (work / "grades").glob("exemption-import-*")))
expect("workbook untouched", workbook.read_bytes() == before)
expect("exports still chosen correctly", "exemption-import" not in text.split("from the export")[0])

# Mark the uploaded ones Exempt in a new export: a rerun then has nothing for them.
for sid in thu_ids:
    set_grade(sid, "Test 3 (Thu)", "Exempt")
for sid in tue_ids:
    set_grade(sid, "Test 3 (Tue)", "Exempt")
set_grade("1000011", "Test 2 (Tue)", "Exempt")
with export.open("w", encoding="utf-8-sig", newline="") as handle:
    csv.writer(handle).writerows(rows)
for path in (work / "grades").glob("exemption-import-*"):
    path.unlink()
code, text = run("--exemptions")
expect("rerun after upload writes nothing", code == 0 and "Nothing to upload." in text
       and not list((work / "grades").glob("exemption-import-*")))
expect("rerun says to fill in RECORDED", line_with(text, "Alpha, Ann", "row 2") and "fill in RECORDED" in text)

# A slip in the workbook's layout stops it, naming the column.
bad = work / "bad.xlsx"
book = openpyxl.load_workbook(workbook)
book.active["M1"] = "Approval"
book.save(bad)
code, text = run("--exemptions", form=bad)
expect("missing column refused", code != 0 and "approved" in text)

# A half-synced file is not a zip file, and should say so without a traceback.
partial = work / "partial.xlsx"
partial.write_bytes(b"not finished arriving")
code, text = run("--exemptions", form=partial)
print(text)
expect("half-synced workbook gives a plain message", code != 0 and "OneDrive" in text and "Traceback" not in text)

code, text = run("--exemptions", form=work / "absent.xlsx")
expect("missing workbook refused", code != 0 and "not found" in text)

(work / "rosters" / "section-rosters_MATH_1003_FR19A_2026-10-25_9_06 PM.csv").unlink()
code, text = run("--exemptions")
expect("refused when a class list is absent", code != 0 and "no class list from HM" in text)
print(f"FAILURES: {failures}")
