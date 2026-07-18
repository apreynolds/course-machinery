\ProvidesClass{Test}[2026/07/17]

% Forward \documentclass[...] options to article, as the sibling classes do.
% Without this, a stray option (12pt, twoside, ...) is collected and then SILENTLY
% dropped -- \LoadClass{article} does not forward what the class never processed.
% No named options of our own yet; xcolor's dvipsnames names are already secured by
% Exercises.sty, which loads xcolor before anything else here touches it.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

\LoadClass{article}

\RequirePackage{import}
\RequirePackage{graphicx}

% Tunable lists, for the cover's instructions block and any in-question lists.
% `[nosep]' (tight instructions) and `[label=(\alph*)]' (question parts) are the
% common needs; both are enumitem options, not stock list features.
\RequirePackage{enumitem}

% The exercise system. Two independent packages, essential first:
%   Exercises  -- \begin{problem}/\begin{solution} + the solutions toggle. The
%                 part the course can't be taught without.
%   ProblemMeta -- greppable topic/tag metadata. Nice-to-have; removable on its
%                 own (Exercises no longer depends on it) without breaking builds.
\RequirePackage{Exercises}
\RequirePackage{ProblemMeta}

% No [osf] -- assessments must read clearly and standardly; figures stay lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs.
\RequirePackage{Typefaces}

% Instructor-only notes layer, shared with LectureNotes and CourseDocument. Loaded
% AFTER Typefaces per its contract (amsthm/amsmath must already be in place; it
% pulls in tcolorbox itself). This completes the `instructor' view bundle for
% assessments: Exercises already supplies \ShowSolutions/\ShowHints and ProblemMeta
% supplies \ShowProblemMeta, so adding InstructorNotes (\ShowInstructorNotes /
% \ShowPrivateNotes) means build-pdfs' `instructor' view yields a full -INSTRUCTOR
% exam copy -- answer key + hints + metadata + staff notes, inside the slate
% "Instructor copy" page frame. The plain -SOLUTIONS answer-key twin already worked
% without it (Exercises owns \ifsolutions); this adds the notes layer on top.
\RequirePackage{InstructorNotes}

% Blank line between paragraphs instead of an indent. Default skip; assessments
% are structured questions rather than continuous prose, so the indent signal
% has little to do here. No Titling -- an assessment opens with a NAME/ID box.
\RequirePackage{parskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exam FURNITURE, not a measure decision. CourseDocument/LectureNotes size the text
% block to 2.6\alphabet for a readable prose measure; an exam is the opposite case
% -- it is not continuous prose, and a narrow measure would only shrink the space
% students write in. So the text block stays wide (near article's stock ~1in
% margins) and the reclaimed room goes to the student, not the typographer.
%
% `top' is a deliberately deep 3.7cm. Crowdmark stamps a QR code and matching
% information into the top band of EVERY page when the paper is uploaded, so that
% band must stay clear of content on the interior pages. On the cover,
% \AssessmentTitle lifts its NAME/ID box up into this same band (a negative
% \vspace, as the reference class did) so the box sits beside the QR near the top
% edge rather than below it.
\RequirePackage{geometry}
\geometry{letterpaper}
\geometry{top=3.7cm, bottom=1.5cm, left=2.0cm, right=1.5cm, head=15pt}

% The instructor/metadata view (build-pdfs injects \ShowProblemMeta as part of the
% `instructor' bundle) hangs ProblemMeta's topics/tags/difficulty/source blocks in
% the RIGHT margin via \marginpar. The exam default reserves no margin column -- a
% student copy wants the full width to write in -- so those blocks would run off
% the paper edge. Widen the right margin and reserve a marginpar column ONLY in
% that view, leaving the student copy's writing width untouched. (A pre-echo of the
% per-page-type \newgeometry furniture NOTE.md defers; kept to this one need.)
\ifdefined\ShowProblemMeta
  \geometry{right=5cm, marginparwidth=3cm, marginparsep=4mm}
\fi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADERS / FOOTERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% One job, and the single most load-bearing piece of exam chrome: a "Page N of M"
% footer, so a student can tell at a glance that no page is missing from the
% stapled packet. `lastpage' supplies \pageref{LastPage}, the two-pass page total
% (first compile shows "??" and the .aux change triggers latexmk's rerun, same as
% \printtotalpoints). No running head -- an exam wants no editorial chrome -- so
% the header rule is off. Activated in the class, unlike CourseDocument (whose
% title page must stay on `plain'): an exam has no title page to protect.
\RequirePackage{lastpage}
\RequirePackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\fancyfoot[C]{\small Page \thepage\ of \pageref{LastPage}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASSESSMENT COVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The reference class scattered the cover across a dozen \def\CourseNumber{}-style
% globals plus a \Short toggle and a hacky Tue/Thu day-box branch. Replaced by ONE
% keyval setter in the same idiom as Exercises' \importproblem / ProblemMeta's
% \ProblemMeta, holding a deliberately minimal field set -- everything else (a
% time/format/coverage line, a formula-sheet note, ...) is just prose the author
% puts in `instructions', so it needs no dedicated key.
%
%   \assessmentsetup{
%     course = {MATH 101}, term = {Fall 2026},
%     name   = {Midterm 1}, date = {17 Oct},
%     instructions = {\begin{itemize}[nosep] \item ... \end{itemize}},
%   }
%
% Every field is optional; an unset one prints nothing (and its surrounding parens
% vanish with it). The point total is NOT a field -- it comes from the problems
% themselves via \printtotalpoints, so it can never disagree with the paper.
\RequirePackage{keyval}
\newcommand{\assess@course}{}
\newcommand{\assess@term}{}
\newcommand{\assess@name}{}
\newcommand{\assess@date}{}
\newcommand{\assess@instructions}{}
\define@key{assessment}{course}{\renewcommand{\assess@course}{#1}}
\define@key{assessment}{term}{\renewcommand{\assess@term}{#1}}
\define@key{assessment}{name}{\renewcommand{\assess@name}{#1}}
\define@key{assessment}{date}{\renewcommand{\assess@date}{#1}}
\define@key{assessment}{instructions}{\renewcommand{\assess@instructions}{#1}}
\newcommand{\assessmentsetup}[1]{\setkeys{assessment}{#1}}

% \AssessmentTitle -- the cover, in three stacked pieces:
%   1. an empty NAME / ID box in the upper LEFT (labels only, as the reference had);
%   2. a CENTRED, sans-serif title: course (term) over name (date);
%   3. the instructions verbatim, no heading (whole block omitted if unset).
% The point total is NOT printed here -- drop \printtotalpoints into `instructions'
% (or anywhere) if you want it on a given paper.
% SolutionColor comes from Exercises; the SOLUTIONS flag rides the same \ifsolutions
% toggle as \begin{solution}. The instructor copy is already marked by the page-edge
% frame, so no separate instructor flag is needed here.
\newcommand{\AssessmentTitle}{%
  % 1. NAME / ID box, lifted into the top margin band (kept clear for Crowdmark's
  % QR on interior pages) so it sits near the top edge, beside where the QR lands.
  % Empty box, labels only -- the student writes to the right of each; the parbox
  % fixes the height so the two labels sit centred with room between them.
  \vspace*{-3.3cm}%
  \noindent
  \framebox[8.5cm][c]{%
    \parbox[c][2.5cm][c]{8cm}{%
      \sffamily\bfseries
      NAME: \\[4ex]
      ID:
    }%
  }%
  \par\bigskip
  % 2. Centred title.
  \begin{center}
    {\sffamily\bfseries\LARGE
       \assess@course\ifdefempty{\assess@term}{}{ (\assess@term)}}\par
    \smallskip
    {\sffamily\bfseries\Large
       \assess@name\ifdefempty{\assess@date}{}{ (\assess@date)}}\par
    \ifsolutions
      \smallskip{\sffamily\bfseries\color{SolutionColor}SOLUTIONS}\par
    \fi
  \end{center}
  % 3. Instructions (optional) -- no heading; the content stands on its own.
  \ifdefempty{\assess@instructions}{}{%
    \bigskip
    \assess@instructions\par
  }%
}
