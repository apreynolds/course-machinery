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

**`pdflatex` here does not pass `-file-line-error`, and log readers cannot tell.**
Both invocation sites — the view override at `build-pdfs:368` and the plain build
at `build-pdfs:412` — leave it off, so errors print in the traditional two-line
form: `! Undefined control sequence.` then `l.4 \undefinedcontrolsequence`. The
line number is there; the **filename is not**. With the flag the same error reads
`./sub.tex:4: Undefined control sequence.`, carrying both.

Without it a parser can only recover the filename by tracking the log's `(`/`)`
file pushes. That is fragile in principle and dangerous in practice: vim's
`errorformat` does it with `%*[^()]` rules that backtrack exponentially, and one
2000-column line carrying a few hundred parens — a `qrcodetikz` QR path,
unwrapped because of `max_print_line` (`build-pdfs:106`) — hangs the editor
outright rather than slowly. Those rules were deleted from the vim side on
2026-09-06 rather than fixed, since they never produced a correct filename
anyway.

So today every error is attributed to the master document. That is not vague but
*wrong*, and it matters here because documents are not single files: 49 of 55
built documents read more than one first-party source, and the lecture masters
read 28–38 each. An error inside an imported passage or a shared `.sty` sends
the reader to that line number in the wrong file.

*Settled, so it need not be re-derived:*

- **This cannot land alone.** With the flag on, the leading `! ` disappears
  entirely. Any parser matching `%E! %m` stops matching errors and reports a
  clean build — loud failures become silent ones. The consumer must understand
  `%E%f:%l: %m` first; that half is independent, backward-compatible, and worth
  doing on its own.
- **An editor that also compiles these documents writes to the same aux dir**
  (the scheme in the contract above), so its log and this script's log are the
  same file, and the last build wins. If the two producers disagree about
  `-file-line-error`, a reader that understands only one format reports "no
  errors" for a document that has them. Making both producers agree is the real
  argument for the flag; nicer attribution is the smaller half.
- **It does not touch warnings.** `Overfull \hbox … detected at line 1` is
  byte-identical either way, and warnings are almost all of what a quickfix list
  ever holds in practice. The gain is confined to genuine errors.
- **Reference implementation:** vimtex passes the flag and parses the result with
  no paren rules at all — `autoload/vimtex/compiler/latexmk.vim` for the
  invocation, `autoload/vimtex/qf/latexlog.vim` for the format.
- `pr-latexmk` is a third producer writing into the same scheme and would need
  the same treatment for the formats to agree everywhere.

**Ghostscript is invoked as `gs`, which is not its name on Windows.**
`build-images` (its tool check, the bbox probe and the page count) and
`build-pdfs`' `%! coverpage:` extract all call the binary `gs`. That is right on
macOS and Linux and wrong on Windows, where Ghostscript installs as
`gswin64c.exe` — so both would report it missing on a machine that has it.
`pdfcrop`, which `build-images` also runs, already solves this: `pdfcrop.pl:181`
keeps a per-platform candidate list (`win => gswin32c, gswin64c, gs`; `miktex =>
mgs, …`) and probes. Nothing to do while this is a macOS/Linux toolkit, and it is
recorded here rather than fixed speculatively — but if Windows ever matters, the
fix is ONE resolver shared by both scripts, not a second copy of the probe in
each. Note Ghostscript is a separate install on every platform: TeX Live ships
`gsftopk`, never `gs`.

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

**`yourturn` on a `problemgroup` stem** → *when a whole set is handed over at once.*
The per-import key marks a single top-level problem; a group member never reaches `\ProblemHeadingFormat` (it renders through the lettered `(a)` branch), so the key warns there rather than working.
The natural home is the group's own key set, `exgroup` in `Exercises.sty`, which today carries only `name` — the mark would land on the stem via `\ProblemGroupHeadingFormat`, reading "Your turn: Example. Differentiate each of the following."
Deferred only because the immediate use is single problems; nothing about the current design blocks it.

**A contents-list legend for the pen glyph** → *if the bare glyph proves unclear in use.*
The contents entry for a `yourturn` example carries the glyph alone, and `\lecturetoc` sits on page 1 — before the reader has met "Your turn:" on a page that explains it.
A legend line would fix that, but is noise in the great majority of lectures that contain no such example.
The conditional form removes that objection: set a flag when a your-turn renders, write it to the `.aux`, and emit the legend on the next run only if it is set — the same two-pass trick `\label`/`\ref` and `\printtotalpoints` already depend on, so latexmk's reruns cost nothing extra.
Wait for evidence the glyph actually confuses someone; the bookmark pane already spells it out in words.

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

**A cross-reference key for passages (`companions`)** → *when a SECOND passage
pair develops a cross-reference.*
`how-we-mark` refers out to `sec:impression` and `sec:otherpointvalues`, so those
three travel together, and today that is a `% REFERS OUT` comment in the one file
that needs it. One file out of eleven does not earn a key, and the failure is
already loud — drop one and LaTeX reports an undefined reference at build time,
which is the failure wanted. If it ever earns one, the key is
`companions = {mostly-right-impression, other-point-values}` (basenames, no
`.tex`), and it does *not* belong in `tsv_cols`.

Note as of 2026-09-04 that this now costs more than it did: the passage bank has
**no metadata block at all**, so a `companions` key means reintroducing one, for
one relation, in one file. That raises the bar rather than lowering it — the
`% REFERS OUT` comment stays until a second pair appears, and even then a comment
may still be the right answer.

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

- **Heading levels.** ~~Does a body start at `\section`? Standalone that competes
  with the title; in the guide it must nest under something. Probably the
  wrapper's job, but unexamined.~~

  > **Answered for prose, 2026-09-04 — and the answer is that it is not the
  > wrapper's job.** It was, briefly: `\importpassage` shifted levels with three
  > `\let`s in a group so a body written at its natural depth could land where
  > the importing document said, and `\PassageTitle` took the title from a
  > `\PassageMeta` block. That machinery was retired after a fortnight. The
  > passage now carries **no title at all** and starts at `\subsection`; the
  > importing document writes the `\section` itself, one line above the
  > `\import`.
  >
  > What that bought is worth recording, because the question will recur for the
  > collected guide. A title, a label, a depth and an editor's note are all facts
  > about the **importer**, not the passage — `how-work-is-marked.tex` is
  > "How Student Work is Marked" in the student handout and "Guidelines for
  > Marking" in the TA instructions. Every one of them was a key invented to
  > carry across a file boundary something the far side already knew. Writing the
  > heading at the call site puts them where they are known, and the machinery
  > goes to zero.
  >
  > So the guide's wrapper wants a body that supplies no title — which is what a
  > passage now is, unconditionally, with no option needed.
- **The guide's class.** `CourseDocument`, or a book-ish option on
  `LectureNotes`? Untouched.

**A per-offering setup file** (instructor and TA names, office hours, and the
handful of per-term facts that are not per-text). Sequenced deliberately after
the text layer shrank to almost nothing, since the objection to merging per-text
and per-offering data was that they change on different cadences. The open
question was mechanical: it would be read by every master at three different
depths, so finding it on `TEXINPUTS` — the way `.latexmkrc` already resolves
this directory and the text layer — was the obvious next question.

> **Answered, 2026-08-23, by the tier rule** (see the architecture chapter,
> *Where course-specific things live*). A file goes on `TEXINPUTS` exactly when
> its readers sit at depths it cannot predict; otherwise it lives beside the
> documents that load it. So the setup file needs no new mechanism — it is
> tier two if genuinely course-wide, tier three if not, and moving between
> them is a `git mv` because nothing names it by path.
>
> **Worked example, math1003.** `courseinfo.sty` is exactly this file:
> `\coursenum`, `\courseterm`, the withdrawal date. It landed in **tier
> three**, beside the syllabus/schedule/roster documents, because those turned
> out to be its only readers — the guess that every master would want it was
> wrong. It carries a documented promotion path for the day a lecture title
> page or a test header wants course identity. It is a `.sty` rather than data
> only because `\DTMsavedate` needs `\usepackage` timing.
>
> The cadence objection that sequenced this item also resolved, and not as
> expected: per-term facts and per-text facts were never the axis that
> mattered. The axis is *how many directories read the file*.
