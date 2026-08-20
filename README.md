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
two disagree, the manual is right.

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
| `Typefaces.sty`, `Titling.sty`, `Hyperlinks.sty` | Fonts, titles and headings, links |

**Scripts:**

- `build-pdfs` — compile a directory of sources, including the extra views each
  one requests through a `%! views:` magic comment, and optionally mirror the
  PDFs to a destination named in a `.MIRRORDIR` file (`SAMPLE-MIRRORDIR` is the
  annotated template).
- `find-problems` / `find-facts` — search a bank by its metadata blocks, without
  running LaTeX; `--import` emits paste-ready import lines.
- `pick-problems` / `pick-facts` — the same search through an `fzf` picker.

`find-meta` and `pick-meta` are the shared engines behind those four; the
per-bank commands are thin shims over them.

## Requirements

- A **full TeX distribution** (TeX Live or MacTeX). Everything compiles with
  `pdflatex` through `latexmk`; there is no LuaTeX or XeTeX requirement.
- The fonts are **Libertinus** with **newtx** math, so those packages must be
  installed — they are part of a full TeX Live, but not of a minimal one.
  `fontawesome5` and `tcolorbox` likewise.
- The scripts are **bash**, and the pickers additionally need
  [`fzf`](https://github.com/junegunn/fzf).

## Using it in a course

Add this repository as a submodule at the top of the course repo:

```sh
git submodule add https://github.com/apreynolds/course-machinery.git .course-machinery
```

Then copy the demo's `.latexmkrc` into every directory that holds `.tex` files.
It walks *up* from the build directory to the nearest `.course-machinery/` and
puts it on `TEXINPUTS`, which is what lets the same file work at any depth — a
master never refers to the machinery by relative path, so nothing about the
tree's shape is baked into a document. Nothing needs to be installed into your
TeX tree.

To build, run `build-pdfs` inside the directory you want to compile:

```sh
cd _assessment
../.course-machinery/build-pdfs            # every source here, all its views
../.course-machinery/build-pdfs test.tex   # just this one
```

A source declaring `%! views: solutions, hints` yields the student PDF plus a
`-SOLUTIONS` and a `-HINTS` copy. The manual's build chapter covers the view
system, the mirror file and the label routing in full.
