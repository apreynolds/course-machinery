\ProvidesClass{Test}[2026/07/17]

% Forward \documentclass[...] options to article, as the sibling classes do; a
% stray option (12pt, twoside, ...) would otherwise be collected and then SILENTLY
% dropped -- \LoadClass{article} does not forward what the class never processed.
%
% [legalpaper] is our own (same name CourseDocument uses): tests and finals
% sometimes run on legal stock for the extra vertical room. It only sets a flag,
% read by the GEOMETRY block below where the paper size is chosen before the
% margins.
%
% [noid] is for documents that collect no student identity -- homework, in-class
% worksheets, MC practice: it drops the NAME/ID box (in \AssessmentTitle) and the
% deep Crowdmark top margin (in GEOMETRY). The default keeps the full identified-
% exam furniture on purpose: forgetting [noid] only over-furnishes homework with an
% unused ID box (harmless), whereas a plain default could ship a real exam with no
% ID box at all (a silent, high-stakes failure) -- so the safe mistake is the easy
% one to make. xcolor's dvipsnames names are already secured by Exercises.sty below.
\newif\ifLegalPaper
\DeclareOption{legalpaper}{\LegalPapertrue}
\newif\ifNoID
\DeclareOption{noid}{\NoIDtrue}
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
% assessments: Exercises already supplies \ShowSolutions/\ShowHints, so adding
% InstructorNotes (\ShowInstructorNotes / \ShowPrivateNotes) means build-pdfs'
% `instructor' view yields a full -INSTRUCTOR exam copy -- answer key + hints +
% staff notes, inside the slate "Instructor copy" page frame. The plain -SOLUTIONS
% answer-key twin already worked without it (Exercises owns \ifsolutions); this
% adds the notes layer on top.
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
% `top' is a deliberately deep 3.7cm (the default). Crowdmark stamps a QR code and
% matching information into the top band of EVERY page when the paper is uploaded,
% so that band must stay clear of content on the interior pages. On the cover,
% \AssessmentTitle lifts its NAME/ID box up into this same band (a negative
% \vspace, as the reference class did) so the box sits beside the QR near the top
% edge rather than below it. [noid] drops this band -- no QR to clear, no box to
% lift -- for a normal 2cm top.
% [legalpaper] swaps only the sheet; the cm margins are absolute, so legal's extra
% 3in of height simply becomes more writing room (same 8.5in width, same margins).
\RequirePackage{geometry}
\ifLegalPaper\geometry{legalpaper}\else\geometry{letterpaper}\fi
\geometry{bottom=1.5cm, left=2.0cm, right=2.0cm, head=15pt}
\ifNoID\geometry{top=2.0cm}\else\geometry{top=3.7cm}\fi

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
%   1. an empty NAME / ID box in the upper LEFT (labels only, as the reference had)
%      -- SUPPRESSED under [noid], where there is no identity to collect and no deep
%      top band to lift it into; the title then simply starts at the normal top;
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
  % fixes the height so the two labels sit centred with room between them. Under
  % [noid] the whole box (and its lift) is dropped.
  \ifNoID\else
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
  \fi
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROBLEM LABELS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% On a test a problem is a numbered QUESTION. The LEFT margin is a pure NUMBER rail
% -- "Q N" hung there for a standalone question, "Q N." for a group stem -- and the
% RIGHT margin is the MARKS rail: every scored item drops its point value there via
% \ProblemPointsFormat. Splitting numbers (left) from marks (right) is what keeps a
% standalone question and a grouped question's PARTS consistent: a part is lettered
% "(a)" inline, not numbered in the margin, yet its marks still land in the same
% right rail as every other item's. (The reference class stacked marks under the
% number on the LEFT -- which read well for a lone question but had no answer for
% the grouped parts; this is the fix.)
%
% \llap hangs the number block in the left margin; \smash keeps it off the line's
% height so the body's first line is not pushed down; the \hspace opens a gap to
% the text. \marginnote (from InstructorNotes' marginnote) drops the marks in the
% outer = right margin, aligned with the heading line and without floating. Point
% BOOKKEEPING is already done by the problem environment, so these hooks DISPLAY only.
%
% The \smash means the number block reserves NO vertical room, so two short
% back-to-back questions would let one hang onto the next. The leading \addvspace
% restores the inter-question gap (and reads as deliberate breathing room). It is
% \addvspace, not \vspace, so it merges with any skip a question already left.
\renewcommand{\ProblemLabelWord}{Q}
\renewcommand{\ProblemNumberText}{\ProblemLabelWord\theproblem}% tight: "Q3", no space
% Marks in the right margin -- the SHARED points hook, so a standalone question and
% a grouped part render identically. \ifnum needs the integer (guaranteed by
% \importproblem).
\renewcommand{\ProblemPointsFormat}[1]{%
  \marginnote{\small\bfseries (#1\ \ifnum#1=1 pt\else pts\fi)}%
}
\renewcommand{\ProblemHeadingFormat}{%
  \par\addvspace{2\baselineskip}%
  \noindent
  \llap{\smash{\textbf{\ProblemNumberText.}}\hspace{1em}}%
  \ifdefempty{\CurrentProblemPoints}{}{\ProblemPointsFormat{\CurrentProblemPoints}}%
}
% The group's numbered stem gets the SAME margin placement (number hung left, no
% points box -- the parts carry the points), so a grouped question lines up with
% the standalone ones. The stem then sets flush against the text edge.
\renewcommand{\ProblemGroupHeadingFormat}[1]{%
  \par\addvspace{2\baselineskip}%
  \noindent
  \llap{\smash{\textbf{\ProblemNumberText.}}\hspace{1em}}%
  \ignorespaces#1\par
}
