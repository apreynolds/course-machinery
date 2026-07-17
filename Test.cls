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
% margins) and the reclaimed room goes to the student, not the typographer. `top'
% is opened to reserve a band at the head of page 1 for the NAME/ID header; the
% \AssessmentTitle machinery that will fill it is a later pass (see NOTE.md, "Test
% geometry"), but the space it needs is claimed here so the layout does not shift
% when it lands.
\RequirePackage{geometry}
\geometry{letterpaper}
\geometry{top=3.6cm, bottom=2.5cm, left=2.5cm, right=2.5cm, head=15pt}

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
