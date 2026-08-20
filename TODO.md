# Outstanding work

What the toolkit does not do yet. The [manual](manual/) documents what exists
and is the authority on current behaviour; this file is the list of intended
changes, so the two never have to disagree.

Most entries are **trigger-gated** on purpose: they are designed but not built,
because building them before a real document needs them would be guessing. Each
one names its trigger and carries whatever was already settled about it, so
picking one up does not mean re-deciding it.

Three caveats live as comments beside the code they concern rather than being
restated here — `CourseBoxes.sty:60` (the colour palette is provisional),
`MathStuff.sty:16` (Calc I/II notation only), and `Exercises.sty:1484`
(matching-column spacing). They are cross-referenced below where relevant.

---

## Portability and handoff

**If you set `XDG_CACHE_HOME`, other tools have to follow.**
`build-pdfs` puts auxiliary files under `${XDG_CACHE_HOME:-$HOME/.cache}/latexmk/`,
keyed by each source's repo-relative path. Nothing here needs changing — but the
cache root is a *shared* assumption, and anything else that reads a build log or
prunes that directory derives the same path independently rather than asking this
script. If the variable is ever set in an environment where those other tools
run, they must derive it the same way or they will silently look in the wrong
place. Editor integrations that parse the `.log` are the ones to check: an
unreadable log usually means "no errors", not "wrong path", so the failure is
quiet.

**There is no `LICENSE`.**
The repository is public and carries no licence terms, which leaves anyone who
wants to adapt it with no permission to. Pick something and add it.

---

## Features — designed, waiting on a trigger

**`systeme` class option** → *when a linear-algebra course is taught.*
Gate `\RequirePackage{systeme}` behind a `systeme` class option and add
`nicematrix` for matrices and augmented matrices. Both are **package loads**, so
they must be gated rather than folded into the always-loaded `MathStuff.sty`:
macros are free, packages cost. `MathStuff.sty:16` records the same boundary
from the notation side.

**`CourseDocument` loading `Exercises`/`ProblemMeta`** → *when a prose document
first imports a problem.*
It does not load them today because it imports nothing. The house rule is to
extract or load when a second document type actually needs it, not in advance.

**A literal `number=` on `problemgroup`** → *if a text ever numbers a grouped
exercise set.*
Nearly free while the group is already parsing keys, but not free overall: the
unnumbered stem is a deliberate choice in lecture context, and a literal number
would need `problem`'s `\@currentlabel` handling mirrored onto the group.

**A per-import `label=` override for the notes noun** → *if one document must
mix nouns.*
Deliberately out of scope now — judged overkill against the per-course
`\NotesProblemLabelWord`, which already lets a course call them Examples or
Exercises. Note `Assessment.cls` never reads that hook (it sets "Q" literally),
so retuning the notes noun cannot leak into an exam.

**A per-instance `text=` on `\ProblemChoiceInstruction`** → *if a one-off lead-in
is ever needed.*
The wording is deliberately a class-level hook, not per-block prose, so a course
phrases "choose N of M" one consistent way for students. A per-instance override
is additive if that ever proves too rigid.

**`\leftitem[C,D]` accepting a list** → *when a matching problem needs a
non-bijective map.*
The two-column interface already supports unequal column counts and distractors;
what it cannot yet express is one left item answering to several right ones. The
layout work below does not depend on this.

**Whole-multipart `nocount`** → *decide, then implement.*
`nocount` on a multipart problem is currently a silent no-op. Whether it should
mean "every part off the books" is undecided; the risk is the silence, not the
semantics.

**Wrapper macros over `\import`** → *when raw call sites start feeling
repetitive.*
Thin sugar such as `\useproblem{topic}{name}` expanding to the full `\import`,
for call sites that read as intent rather than paths. Worth knowing before
building it: **correctness comes from `import`, not from the wrapper** — this is
cosmetic, and a wrong wrapper can only make a working mechanism less legible.

---

## Polish

**Matching columns: balance the heights (Tier 1).**
A tall graph column beside a short phrase column used to hang from a common top,
leaving a lopsided wedge of space. **Tier 0 is built** — the two minipages are
`[c]` rather than `[t]`, so a short column floats to the vertical middle of a
tall one — and is likely sufficient. Tier 1, if it is not: buffer each column,
measure both, set both to the taller height, and separate items with rubber glue
so they spread to co-terminal columns. See `Exercises.sty:1484`.

*Settled, do not re-derive:* a row-major `tabular` was **rejected**. It bakes in
a 1:1 left-row-to-right-row correspondence, which forbids unequal column counts
and non-bijective answer maps — both of which the current column-major interface
supports for free. The goal is *balance*, not row alignment; once counts differ,
row alignment is meaningless.

**Four cosmetic `Underfull \hbox` warnings** on annotated graph rows in a
matching block's solutions build. Pre-existing and confirmed present in a
pristine baseline — they are not caused by the column or label work.

**The colour palette is provisional.** See `CourseBoxes.sty:60`, which carries
the contrast figures and the reasoning. Every box is label-redundant, so colour
never carries meaning alone.

---

## Scripts

**A link-checker** → *when the corpus is large enough to be worth it.*
Harvest every outbound URL and `curl` it, so link rot surfaces on your schedule
rather than in front of a class. Nag louder about textbook links, which someone
else owns, than about your own interactive demos.

Nothing verifies these today, and this is precisely the failure LaTeX cannot
catch: an unresolved *key* warns loudly, but a merely-wrong slug renders a
perfectly good-looking link to a 404.

Implementation notes, so they need not be re-derived:

- A **bash** script beside `find-meta` — every script here is bash, and the job
  is grep plus curl. House style: `-h` reprints the header comment, and
  `set -uo pipefail`.
- **Three shapes to grep:** `link=` inside `\booksection` (anchor on
  `^\s*\\booksection` so commentary is skipped, and note a lecture may
  legitimately have no `link=`), `\DeclareSection` in the text layer, and
  `\demo{URL}`.
- **The awkward part.** Resolving a `\booksection` link means reading the
  lecture's `\usetext` — or its absence, meaning the default layer — and then
  that layer's `\DeclareTextBase`. That makes the checker a **third parser of
  the text-layer format**. This toolkit has been bitten by exactly that twice
  (the mirror-file format grew three parsers; the metadata format has two, with
  a standing note to change one and check the other). Design around it rather
  than discovering it.

---

## Larger, not scheduled

**Splitting a body from its wrapper, for a collected guide.**
Today one document is one file. The reason to split a section into a
preamble-less body plus a thin wrapper is **reuse across masters**: the same body
appearing both as its own PDF and inside a single collected guide that walks the
whole text. A build-time view toggle cannot express that — same flag, same
build, two different enclosing documents — which is why it is a different kind
of need from the student/solutions/instructor split the view system already
handles.

What the split buys precisely: the two masters need *different* wrappers but the
*same* body. Standalone, the wrapper supplies the title and frontmatter; inside
the guide, the enclosing document supplies its own structure and the body drops
in. Frontmatter is exactly the thing that cannot be shared. Views need no
change either, since the `%! views:` comment is per-file, so each master already
declares its own.

Genuinely open, if this is ever built:

- **Heading levels.** Does a body start at `\section`? Standalone that competes
  with the title; in the guide it must nest under something. Probably the
  wrapper's job, but unexamined.
- **The guide's class.** `CourseDocument`, or a book-ish option on
  `LectureNotes`? Untouched.

**A per-offering setup file** (instructor and TA names, office hours, and the
handful of per-term facts that are not per-text). Sequenced deliberately after
the text layer shrank to almost nothing, since the objection to merging per-text
and per-offering data was that they change on different cadences. The open
question is mechanical: it would be read by every master at three different
depths, so finding it on `TEXINPUTS` — the way `.latexmkrc` already resolves
this directory and the text layer — is the obvious next question.
