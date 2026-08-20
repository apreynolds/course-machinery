\ProvidesClass{LectureNotes}[2026/07/10]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [projector] -- the copy shown in the room: bigger type, tighter top margin.
% Default is the handout (students, pre-class). The option is named for the
% -PROJECTOR view so the class option and the built file agree.
\newif\ifProjector
\DeclareOption{projector}{\Projectortrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{extarticle}}

% Options must reach xcolor before any other package loads it (Hyperlinks needs
% the dvipsnames names for link colours).
\PassOptionsToPackage{dvipsnames}{xcolor}
\ProcessOptions\relax

% Same shape as Assessment.cls's \ShowSolutions: build-pdfs' view loop injects
% \def\ProjectorView{} before \documentclass is read (its `projector' view), so
% the view needs no class option at the call site.
\ifdefined\ProjectorView \Projectortrue \fi

\ifProjector
  \LoadClass[17pt]{extarticle}
\else
  \LoadClass[14pt]{extarticle}
\fi

\RequirePackage{import}
\RequirePackage{graphicx}

% Tunable lists: `[label=(\alph*)]' for lettered parts, `[nosep]' for tight
% lists. Both are enumitem options, not stock list features.
%
% This is here for PARITY WITH Assessment.cls, which has always loaded it, and
% the asymmetry was a real bug rather than a stylistic gap: Exercises.sty is
% loaded by both classes, so a problems/ file is supposed to compile unchanged
% as a lecture Example and as a test Question. One written with
% \begin{enumerate}[label=(\alph*)] used to do neither -- it typeset on an
% assessment and failed on a lecture. A shared bank cannot be context-neutral
% while the two classes disagree about what a list can do.
%
% Prefer \begin{qparts}/\qpart inside a problem file where it fits; it letters
% the parts itself and carries per-part points and workspace. This is for the
% lists that are not question parts.
\RequirePackage{enumitem}

% The exercise system. Two independent packages, essential first:
%   Exercises  -- \begin{problem}/\begin{solution} + the solutions toggle. A
%                 lecture imports problem files too, and they may carry solutions.
%   ProblemMeta -- greppable topic/tag metadata. Nice-to-have; removable on its
%                 own (Exercises no longer depends on it) without breaking builds.
%   FactMeta   -- the same, for imported fact snippets. Also nice-to-have; the
%                 \FactMeta stub in Exercises keeps facts compiling without it.
\RequirePackage{Exercises}
\RequirePackage{ProblemMeta}
\RequirePackage{FactMeta}

% Explicit handwriting whitespace: \workspace[lines|halfpage|fullpage] / \workspace*.
% Shared with Assessment -- both need copious writing room (student answers, board work).
\RequirePackage{Workspace}

% No [osf] -- figures here are information; keep them lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs,
% and defines \alphabet (measured in the real body font -- so it must come
% after \LoadClass, and the geometry below must come after it).
\RequirePackage{Typefaces}

% Shared math notation (\lz, \norm, \deriv, ...). AFTER Typefaces per its
% contract: amsmath/newtxmath must already be loaded; MathStuff adds mathtools.
\RequirePackage{MathStuff}

\RequirePackage{Titling}
\RequirePackage{Hyperlinks}

% \textbookref -- links into the course text. Mechanism only: the base URL and
% the section manifest are course data, declared in .textbook/textbook.tex.
% Inert until that file is \input; unresolved references print as plain text.
\RequirePackage{TextRef}

% Theorem/definition boxes + pedagogical asides. AFTER Typefaces: it pulls in
% tcolorbox (which would drag amsmath in) but amsthm/amsmath are already loaded by
% newtxmath, so the load-order fixed in "Fonts" holds. Requires hyperref (for
% \phantomsection) only at box-use time, which Hyperlinks' \AtEndPreamble supplies.
\RequirePackage{CourseBoxes}

% Instructor-only notes layer (\InstructorInline / InstructorBox / \InstructorMargin)
% + the \ifinstructornotes flag the "Instructor Copy" marker below rides on. AFTER
% Typefaces (it pulls in tcolorbox); self-loads tcolorbox, so it does not depend on
% CourseBoxes' copy.
\RequirePackage{InstructorNotes}

% No \TitleColor override: lecture headings stay black. Colour is for course
% documents only -- lectures sit with assessments on the "clear, not fancy" side.
% \LinkColor/\UrlColor likewise keep Hyperlinks' plain defaults (black/RoyalBlue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTED PROBLEMS AS EXAMPLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The same problem file that is a graded "Q" on a test reads as an "Example" in
% lecture notes. Exercises.sty leaves the presentation to the class (see its
% "class-overridable PRESENTATION" hooks); here we set the notes look.
%
% The noun is a per-TEXT choice -- texts variously say Example / Exercise /
% Problem, and the notes should echo whichever the students are reading. A course
% overrides it by redefining \NotesProblemLabelWord (its home is the text layer,
% .textbook/textbook.tex). We route \ProblemLabelWord through that macro rather
% than setting the word directly, so a text layer shared with an ASSESSMENT
% document can retune the notes noun without disturbing Assessment.cls's fixed "Q"
% (Assessment sets \ProblemLabelWord literally and never reads \NotesProblemLabelWord).
\providecommand{\NotesProblemLabelWord}{Example}
\renewcommand{\ProblemLabelWord}{\NotesProblemLabelWord}

% Run-in heading: the label word, then -- only if given at import -- a literal
% number (\importproblem[number=2.1.8], typically the textbook's) and a
% parenthetical name (\importproblem[name={domain from an expression}]). No points
% (notes are ungraded) and no auto counter (an unnumbered example is the default;
% the `problem' counter still steps unseen). Renders as, e.g.:
%   Example.            Example 2.1.8.
%   Example (domain from an expression).      Example 2.1.8 (tangent lines).
% The exact bold span / period are presentation; tune here freely.
%
% It also lodges the contents entry (see TOC below), through the SAME renderer the
% CourseBoxes results use -- so an imported "Example 2.1.8" and a written
% "Definition 2.1.1" cannot end up formatted differently in the list. This hook is
% the right place because Exercises only calls it for a TOP-LEVEL problem: a
% \problemgroup part renders as "(a)" through another branch, and a check-in
% suppresses the heading entirely (Exercises.sty:647-657), so parts and check-ins
% stay out of the contents for free.
%
% The NAME goes into the entry. It could not while the key was `desc', because
% that had drifted into provenance and could hold a \textbookref -- a link nested
% inside the contents entry's own link. As a content label it is exactly what a
% contents line wants, and carries no links.
\renewcommand{\ProblemHeadingFormat}{%
  \CourseBoxTocEntry{\ProblemLabelWord}{\CurrentProblemNumber}{\CurrentProblemName}%
  \par\addvspace{\medskipamount}%
  \noindent
  \textbf{\ProblemLabelWord
    \ifdefempty{\CurrentProblemNumber}{}{\space\CurrentProblemNumber}}%
  \ifdefempty{\CurrentProblemName}{}{ \textnormal{(\CurrentProblemName)}}%
  \textbf{.}\quad\ignorespaces
}

% The GROUP stem follows the same unnumbered rule: a bare bold label word, then
% the stem (the parts letter themselves (a),(b),... as usual). Without this
% override, Exercises' default stem would print the invisibly-stepped counter
% -- "Example 3." -- beside standalone examples that show no number at all.
% (number= is a per-member import key, so the stem has none to show.)
%
% CONTENTS ENTRY ONLY IF THE GROUP IS NAMED. The stem itself is deliberately not
% used for it: it is a sentence ("Differentiate each of the following."), which
% reads badly in a list and may carry maths or a link. And a group with no name
% would otherwise contribute a bare "Example" -- indistinguishable from every
% other one, so several groups would give several identical lines. Naming a group
% is therefore how you opt it into the list, which suits something used rarely.
% The group has already run \refstepcounter, so the entry links to it.
\renewcommand{\ProblemGroupHeadingFormat}[1]{%
  \ifdefempty{\CurrentProblemName}{}{%
    \CourseBoxTocEntry{\ProblemLabelWord}{}{\CurrentProblemName}}%
  \par\addvspace{\medskipamount}%
  \noindent\textbf{\ProblemLabelWord.}\quad\ignorespaces#1%
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% textwidth follows the measure rule rather than a frozen length; see Typefaces.
% At 14pt this gives ~6.31in (the inherited hardcode was 6.382in, derived for a
% font we no longer use); at 17pt it re-derives on its own.
% includehead, because the running head (see HEADERS) is real reserved space and
% has to be budgeted rather than borrowed from the top margin: the projector
% copy's 0.25in top is smaller than the head itself, so without this the head
% would run off the top of the page. With it, `top' is measured to the top of the
% head and the body begins below it.
\RequirePackage{geometry}
\geometry{letterpaper}
\ifProjector
  % Room copy: no marginpar, top margin tightened to buy vertical space, and the
  % body pushed LEFT of centre.
  %
  % hmarginratio is the whole of that last part. With textwidth given and neither
  % `left' nor `right', geometry splits the leftover width by this ratio -- 3:7
  % hands the left margin 30% of it where the default 1:1 hands it 50%, i.e. 60%
  % of the margin it used to have, with the difference falling to the right. The
  % MEASURE IS UNTOUCHED: only where the block sits moves, never how wide it is.
  % (Same knob CourseDocument uses to switch between its 2:3 and 1:1 splits.)
  %
  % The reason is the room, not the page: presenting from an iPad puts the app's
  % tool bar down the RIGHT edge of the screen, over the projected text.
  \geometry{top=0.25in, bottom=0.75in, textwidth=2.6\alphabet,
            hmarginratio={3:7},
            includehead, headheight=22pt, headsep=8pt}
\else
  % Handout: left margin fixed, remainder falls to the right and carries the
  % marginpar column.
  \geometry{top=0.5in, bottom=0.75in, left=0.5in,
            textwidth=2.6\alphabet, marginparwidth=1.3in,
            includehead, headheight=17pt, headsep=10pt}
\fi

% No \TitleMarker override: the instructor-copy signal is now the page-edge frame
% (InstructorNotes.sty, gated on \ifinstructornotes) -- an ever-present marker on
% every page rather than a one-time title stamp.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAGRAPHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% skip=1em, deliberately airier than parskip's default (.5\baselineskip plus
% 2pt), and font-size-relative -- the air scales with the type (14pt handout,
% 17pt projector). A pedagogical call (room to annotate, legible at a
% distance), not a typographic one; it is also the trade against the
% display-math argument, since parskip weakens the continuation-vs-new-paragraph
% cue after a display. Keep knowingly.
%
% Loaded BEFORE titlesec. See CourseDocument.cls on parskip's silent-patch
% hazard (grep the log for "Couldn't patch"; gotchas in
% manual/ch-architecture.tex).
\RequirePackage[skip=1em]{parskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% usage: \titleformat{command}[shape]{format}{label}{sep}{before-code}[after-code]
% usage: \titlespacing*{command}{left}{before-sep}{after-sep}[right-sep]
\RequirePackage{titlesec}
\RequirePackage{titletoc}
\setcounter{secnumdepth}{1}
% tocdepth is set with the rest of the contents machinery, in TOC below.

% titlesec calls \<name>break before each such title (titlesec.sty:435-437), so
% this really does \clearpage before every subsection. It looks inert because
% titlesec never mentions the name -- the hook is built dynamically via
% \csname#6break\endcsname. Deliberate, not dead code.
\newcommand{\subsectionbreak}{\clearpage}

\titleformat{\section}[block]
  {\sffamily\bfseries\Large}{\thesection}{0.7em}{}[]

\titleformat{\subsection}[block]
  {\sffamily\bfseries\large}{\thesubsection}{0.7em}{}[]

\titleformat{\subsubsection}[block]
  {\sffamily\bfseries\itshape}{\thesubsubsection}{1em}{}[]

%USAGE: \titlespacing*{command}{left}{before-sep}{after-sep}[right-sep]
\titlespacing*{\section}{0em}{2em}{1em}[0em]
\titlespacing*{\subsection}{0pt}{1.0em}{1.0em}
\titlespacing*{\subsubsection}{0pt}{1em}{0.3em}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A lecture's contents list is NOT mostly sections -- most lectures have none. It
% is mostly the things that actually structure the hour: definitions, theorems,
% facts, examples. Those arrive as `cbresult' entries via \CourseBoxTocEntry
% (CourseBoxes' hook, rendered just below); \section/\subsection appear too, when
% a lecture happens to use them.
%
% HENCE FLAT, AND HENCE TYPEFACE RATHER THAN INDENT. Indentation implies hierarchy;
% in the common no-section lecture there is none to imply, and indenting every
% result would push the whole list right for nothing. So every level sits at one
% margin and the DISTINCTION IS THE FACE -- sans for headings (echoing
% \titleformat's \sffamily\bfseries on the page), serif roman for results. A
% sectionless lecture then reads as a plain flat list, and a sectioned one still
% separates at a glance. No conditional layout, nothing measured across runs.
\setcounter{tocdepth}{3}

% The pseudo-level the box hook writes. \titlecontents defines \l@cbresult, but a
% custom entry type needs its LEVEL declared too -- and there are TWO registries
% for that, which is a genuine trap:
%
%   \toclevel@cbresult  LaTeX/hyperref. Read by \addcontentsline's tocdepth test
%                       and by hyperref for bookmark nesting; without it every
%                       entry bookmarks at level 0.
%   \ttll@cbresult      titletoc's own (titletoc.sty:283-292). Without it titletoc
%                       warns "Unknown TOC type cbresult" while READING the .toc
%                       and assigns level -1000, which also skews its
%                       level-change logic and its own tocdepth test (:538).
%
% Same number in both, or the two disagree about what this entry is.
\newcommand*{\toclevel@cbresult}{2}
\def\ttll@cbresult{2}

% Leaders and the page column, in ONE place because the two views differ: the
% handout is paged and gets both; the projector prints NO page numbers anywhere
% (see HEADERS), so a page column there would point at numbers the reader cannot
% see. Its entries are still hyperlinks -- and with \LinkColor black they look like
% plain text and behave as taps, which is the whole navigation story on the room
% copy now that the back-to-top arrow is gone.
\ifProjector
  \newcommand{\CourseTocFill}{}
\else
  \newcommand{\CourseTocFill}{\titlerule*[0.8pc]{.}\normalfont\thecontentspage}
\fi

\titlecontents{section}[0em]
  {\sffamily\bfseries}
  {\thecontentslabel.\enspace}
  {}
  {\CourseTocFill}[]

\titlecontents{subsection}[0em]
  {\sffamily\bfseries\small}
  {\thecontentslabel.\enspace}
  {}
  {\CourseTocFill}[]

\titlecontents{subsubsection}[0em]
  {\sffamily\small}
  {\thecontentslabel.\enspace}
  {}
  {\CourseTocFill}[]

\titlecontents{cbresult}[0em]
  {}
  {}
  {}
  {\CourseTocFill}[]

% The projector list needs no reserved right margin, having nothing to put there.
\ifProjector\contentsmargin{0pt}\else\contentsmargin{1em}\fi

% CourseBoxes' hook, rendered. Composes "Definition 2.1.1 (Derivative)", dropping
% whichever pieces are absent -- an unnumbered result (\begin{example*}) gives
% "Example (Cubic)" or bare "Example", and a named-but-unnumbered fact likewise.
% Built up by \protected@edef rather than assembled inside \addcontentsline's
% argument, so the conditionals run here as conditionals and only finished text
% reaches the .toc write.
\renewcommand{\CourseBoxTocEntry}[3]{%
  \def\CB@tocline{#1}%
  \ifblank{#2}{}{\protected@edef\CB@tocline{\CB@tocline\space#2}}%
  \ifblank{#3}{}{\protected@edef\CB@tocline{\CB@tocline\space(#3)}}%
  \addcontentsline{toc}{cbresult}{\CB@tocline}%
}

% \lecturetoc -- what a lecture actually writes. The class owns the presentation
% (page break, and whatever heading \tableofcontents' \section* renders as) so a
% lecture spends one token and the look stays tunable in one place. DOCUMENT-called
% rather than class-emitted, deliberately: a one-topic lecture wants no list at all,
% and only the author knows which those are.
%
% The trailing \clearpage does not risk a blank page when the first \subsection
% also breaks: \clearpage on a page with no contributed material does nothing.
\newcommand{\lecturetoc}{%
  \tableofcontents
  \clearpage
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The head carries the lecture's \booksection coordinate -- "2.5: The Chain
% Rule", linked to that section of the book (TextRef.sty). It is the document's
% title as well as its running head, which is why it repeats on every page
% instead of sitting once at the top: a lecture is read a page at a time, and on
% the projector copy -- scrolled rather than paged -- persistent orientation is
% worth more than anywhere else. (Page NUMBERS are a different matter and are
% still dropped there: the copy is never collated, so a number is noise. That is
% the distinction an earlier version of this comment missed when it concluded
% lectures want no running head at all.)
%
% \fancyhf{} clears every field; each view puts back only what it wants.
\RequirePackage{fancyhdr}
\fancyhf{}
\fancyhead[R]{\CourseRunningHead}

% Rule under the head, but only when there IS a head -- a lecture that declares
% no coordinate (neither \booksection nor \lecturetitle) should not get a rule
% sitting over nothing. Redefining \headrule rather than \headrulewidth is what
% makes that testable: \headrulewidth has to expand to a dimension, whereas
% \headrule is executed at shipout, by which point the declaration has run.
\renewcommand{\headrule}{%
  \ifdefempty{\BookSectionHead}{}{%
    \hrule\@height\CourseHeadRule\@width\headwidth
    \vskip-\CourseHeadRule}%
}

% The projector foot stays empty: a grey back-to-top arrow lived here (the copy is
% scrolled, so a jump to the top looked worth its space) but went unused in the
% room and was retired 2026-08-13 along with the anchor behind it.
\ifProjector\else
  \fancyfoot[C]{\small\thepage}
\fi
\pagestyle{fancy}

