# course-machinery

A LaTeX toolkit for producing course materials — lecture notes, assessments, and
prose documents like a syllabus — from a shared bank of single-problem files.

The design goal is that **one source produces every copy you need**. A problem is
written once, in its own file, with its solution and hint alongside; the same
file is imported into a lecture as a worked example and into a test as a graded
question. A build then emits the student copy, the solutions copy, the hints
copy and the instructor copy from that one source, with no forked files to keep
in sync.

This repository is meant to be mounted inside a course repository as
`.course-machinery/`. A complete worked example — a small course that exercises
the features — lives at
[`apreynolds/course-demo`](https://github.com/apreynolds/course-demo).

## Start with the manual

**`manual/`** is the reference and the place to begin. It documents every class,
package, option, knob and script, and it is compiled *with* the toolkit it
describes — the class is the shipped `CourseDocument`, and every rendered
example is typeset by the real machinery at build time. If the manual builds,
the toolkit works.

```sh
cd manual
latexmk -pdf manual.tex
```

Its opening chapter explains how to read it; the one after that ("Quickstart:
anatomy of a course repo") is the fastest way to see the shape of the whole
system.

Everything below is orientation only. The manual is the authority — where the
two disagree, the manual is right. What the toolkit does *not* do yet is listed
separately, in [`TODO.md`](TODO.md).

## What's here

**Three document classes** — when you sit down to write, the only decision is
which one:

| Class | For |
|---|---|
| `Assessment.cls` | Anything graded or handed in: tests, quizzes, homework, worksheets |
| `LectureNotes.cls` | Lecture handouts, with a projector view for the room |
| `CourseDocument.cls` | Prose documents: syllabus, policies, TA information |

**Shared packages**, supplying the content machinery the classes sit on:

| Package | Provides |
|---|---|
| `Exercises.sty` | Problems, solutions, hints, multiple choice, matching, parts, points |
| `ProblemMeta.sty` | Greppable metadata blocks on problem files |
| `FactMeta.sty` | The same, for the reusable-fact bank |
| `CourseBoxes.sty` | Theorem/definition boxes and pedagogical asides |
| `InstructorNotes.sty` | Staff-only annotations, shown in the instructor copy |
| `Workspace.sty` | Reserved answer space, and the zero-height overlay contract |
| `TextRef.sty` | Ties a document to *its* textbook — section links, named results |
| `MathStuff.sty` | Shared mathematical notation |
| `Typefaces.sty`, `TitleBlock.sty`, `Hyperlinks.sty` | Fonts, titles and headings, links |

**Scripts:**

- `build-pdfs` — compile a directory of sources, including the extra views each
  one requests through a `%! views:` magic comment, and optionally mirror the
  PDFs to a destination named in a `.MIRRORDIR` file (`SAMPLE-MIRRORDIR` is the
  annotated template).
- `build-images` — render single problem files to cropped PDFs and PNGs, one
  picture per problem, for a learning-management system whose question pools
  take an image rather than text. Question-only and question-with-solution
  versions of each, at the same measure a printed build uses.
- `pg-to-latex` — scaffold a `.tex` problem file from a WeBWorK `.pg` at a
  frozen seed. A scaffold, not a converter: it does the mechanical part and
  marks its own gaps `% TODO`.
- `webwork-check` / `webwork-deploy` — verify a course's WeBWorK set
  definitions and problem trees, and build one uploadable tarball per topic.
  Only useful to a course that assigns WeBWorK, but many do.
- `build-d2l-import.py` — read a quiz's pool `.tex` files and emit a D2L
  question-import CSV, plus a paste sheet for entering the questions by hand.
- `find-problems` / `find-facts` — search a bank by its metadata blocks,
  without running LaTeX; `--import` emits paste-ready import lines.
- `find-passages` — the odd one out, because a passage bank has **no metadata
  block**: the directory is the bank, and a passage's title and label are
  derived from its file name. So there is nothing to search and nothing to
  inject — no filters, no `--with`, no `--untagged`, no `--vocab` — and a PATH
  is required, since a bare run could not tell a passage from any other `.tex`.
  `--import` emits a `\section` and `\label` line, a blank, then a plain
  `\import`.
- `pick-problems` / `pick-facts` / `pick-passages` — the same through an `fzf`
  picker.

`find-meta` and `pick-meta` are the shared engines behind those six; the
per-bank commands are thin shims over them.

## Requirements

- A **full TeX distribution** (TeX Live or MacTeX). Everything compiles with
  `pdflatex` through `latexmk`; there is no LuaTeX or XeTeX requirement.
- The fonts are **Libertinus** with **newtx** math, so those packages must be
  installed — they are part of a full TeX Live, but not of a minimal one.
  `fontawesome5` and `tcolorbox` likewise.
- The scripts need **bash 4.0 or newer** (they use associative arrays and
  `mapfile`), and the pickers additionally need
  [`fzf`](https://github.com/junegunn/fzf). **On macOS this is the one thing
  likely to trip you up:** the system `/bin/bash` is 3.2 and will always stay
  there, so install a newer bash (`brew install bash`, or MacPorts) and make sure
  it precedes `/bin/bash` on your `PATH`. The scripts check, and say so, rather
  than failing obscurely. Linux distributions and Git Bash on Windows already
  ship bash 5.

## Using it in a course

Add this repository as a submodule at the top of the course repo:

```sh
git submodule add https://github.com/apreynolds/course-machinery.git .course-machinery
```

Every directory you build in needs a `.latexmkrc`, because latexmk reads only
the one in its startup directory and never walks up. **`build-pdfs` installs it
for you** — it copies `latexmkrc-shared` from this repo into each source's own
directory before compiling, so a new topic folder needs no manual step. Copy it
in by hand only if you intend to build a directory without ever running the
script there.

The file walks *up* from the build directory to the nearest
`.course-machinery/` and puts it on `TEXINPUTS`, which is what lets one
identical copy work at any depth — a master never refers to the machinery by
relative path, so nothing about the tree's shape is baked into a document.
Nothing needs to be installed into your TeX tree.

The copies are verbatim and refreshed whenever the master changes, so an edit to
`latexmkrc-shared` propagates on the next build. A copy carries a `managed by
build-pdfs` marker line; delete that line and the script will never touch that
copy again, which is how a directory keeps a hand-tuned rc.

*Upgrading an existing course:* copies predating this scheme have no marker line,
so `build-pdfs` treats them as hand-tuned and leaves them alone. Delete them once
and the next build installs the current file.

The same file puts `.course-machinery-local/` on the path beside it. That is
where a course keeps machinery of its *own* that more than one directory has to
find — the text layer above all. Anything only one directory's documents load
goes beside those documents instead and needs no path entry at all. The manual's
architecture chapter states the rule; it is the one question that decides where
a new file goes.

To build, run `build-pdfs` inside the directory you want to compile:

```sh
cd _assessment
../.course-machinery/build-pdfs            # every source here, all its views
../.course-machinery/build-pdfs test.tex   # just this one
```

A source declaring `%! views: solutions, hints` yields the student PDF plus a
`-SOLUTIONS` and a `-HINTS` copy. The manual's build chapter covers the view
system, the mirror file and the label routing in full.
