\ProvidesClass{Test}[2026/07/10]

\LoadClass{article}

\RequirePackage{import}
\RequirePackage{graphicx}

% Problem files carry a \ProblemMeta{...} block, so every class that imports one
% has to define it. Prints nothing unless \ShowProblemMeta is defined.
\RequirePackage{ProblemMeta}

% No [osf] -- assessments must read clearly and standardly; figures stay lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs.
\RequirePackage{Typefaces}

% Blank line between paragraphs instead of an indent. Default skip; assessments
% are structured questions rather than continuous prose, so the indent signal
% has little to do here. No Titling -- an assessment opens with a NAME/ID box.
\RequirePackage{parskip}

% --- solutions view toggle --------------------------------------------------
% Off by default (the student build). build-pdfs turns it on for the -SOLUTIONS
% twin by injecting  \def\ShowSolutions{}  on the command line before the
% document is read (see build-pdfs and the `%! views: solutions' magic comment).
\newif\ifsolutions
\ifdefined\ShowSolutions \solutionstrue \fi

% \solution{...} prints its argument only in the solutions build. For a longer,
% multi-paragraph answer, guard a block with  \ifsolutions ... \fi  instead.
\newcommand{\solution}[1]{\ifsolutions #1\fi}
