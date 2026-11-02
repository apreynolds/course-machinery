# test-colour.py — run --class and friends with colour forced on, on invented data
# Usage: uv run --with openpyxl python3 test-colour.py
# Loads student-record as a module so that colour can be switched on without a terminal.
import contextlib
import importlib.machinery
import importlib.util
import io
import re
import sys
from pathlib import Path

ADMIN = str(Path(__file__).resolve().parent.parent)
sys.path.insert(0, ADMIN)
loader = importlib.machinery.SourceFileLoader("student_record", f"{ADMIN}/student-record")
spec = importlib.util.spec_from_loader("student_record", loader)
sr = importlib.util.module_from_spec(spec)
loader.exec_module(sr)
sr.courseadmin.USE_COLOUR = True

work = Path(__file__).parent / "fixtures"
BASE = ["student-record", "--roster-dir", str(work / "rosters"), "--sac-workbook", str(work / "sac.xlsx"),
        "--grades-dir", str(work / "grades"), "--assessments", str(work / "assessments.csv"),
        "--scheme", str(work / "scheme.csv"), "--staff", str(work / "none.csv"), "--as-of", "2026-10-30"]


def run(*flags):
    sys.argv = BASE + list(flags)
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        try:
            sr.main()
        except SystemExit:
            pass
    return out.getvalue()


def plain(text):
    return re.sub(r"\033\[[0-9;]*m", "", text)


failures = 0


def expect(label, condition):
    global failures
    failures += not condition
    print(f"{'ok  ' if condition else 'FAIL'} {label}")


section = run("--class", "fr01a")
print(section.replace("\033", "ESC")[:900])
text = plain(section)
print(text[:1000])
expect("lower case section accepted", "MATH 1003 FR01A" in text)
expect("Thu section keeps Thu items", "Test 1 (Thu)   " in text)
expect("Tue item's row hidden", "Test 2 (Tue)" not in text)
expect("someone who wrote the other version is mentioned", "Test 1 (Tue): 2 of this section wrote this version" in text)
expect("colour present", "\033[1;36m" in section and "\033[32m" in section or "\033[31m" in section)

everything = plain(run("--class"))
expect("whole class keeps both versions", "Test 2 (Tue)" in everything and "Test 2 (Thu)" in everything)
# Columns stay aligned: each stats row's median starts at the same place.
rows = [line for line in text.splitlines() if " median " in line and " mean " not in line]
expect("columns aligned with colour on", len({line.index(" median ") for line in rows}) == 1)
tue = plain(run("--class", "FR05A"))
expect("Tue section has no Thu items", "(Thu)" not in tue)
expect("--show still works", "MARK SO FAR" in plain(run("--show", "alpha")))
expect("--check still works", "not known:" in plain(run("--check")))
print(f"FAILURES: {failures}")
