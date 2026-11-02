# test-roster-names.py — check that class-list file names are recognised in both forms
# Usage: uv run --with openpyxl python3 test-roster-names.py
# Uses empty files with invented names, never the real class-list folder.
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from courseadmin import read_sections, select_current_exports

sections = read_sections()
folder = Path(tempfile.mkdtemp())
names = [
    "section-rosters_MATH_1003_FR01A_2026-10-30_8_22 AM.csv",
    "section-rosters_MATH_1003_FR19A_2026-09-17_4_53 PM.csv",   # HM, older
    "section-rosters_MATH-1003-FR22A_2026-10-29_11_46 AM.csv",  # HM, newer: must win
    "section-rosters_MATH-1003-FR13A_2026-10-26_1_48 PM (1).csv",  # second download
    "section-rosters_MATH.1003.FR07A_2026-10-09_1_01 PM.csv",   # must warn by name
    "section-rosters_MATH_1013_FR07A_2026-10-09_1_01 PM.csv",   # other course: must warn
]
for name in names:
    (folder / name).touch()

current, total, superseded = select_current_exports(folder, sections)
failures = 0


def check(label, got, want):
    global failures
    good = got == want
    failures += not good
    print(f"{'ok  ' if good else 'FAIL'} {label}: {got!r}")


check("files looked at", total, 6)
check("instructors found", sorted(current), ["HM", "PL", "PR"])
check("HM's section is the hyphenated, newer file", current["HM"][1], "FR22A")
check("PL's second download parses", current["PL"][1], "FR13A")
check("older HM file superseded", [p.name for p, _ in superseded], [names[1]])
print(f"FAILURES: {failures}")
