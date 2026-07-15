\ProvidesClass{Test}[2026/07/10]

\LoadClass{article}

\RequirePackage{import}
\RequirePackage{graphicx}

% No [osf] -- assessments must read clearly and standardly; figures stay lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs.
\RequirePackage{Typefaces}

% --- solutions view toggle --------------------------------------------------
% Off by default (the student build). build-pdfs turns it on for the -SOLUTIONS
% twin by injecting  \def\ShowSolutions{}  on the command line before the
% document is read (see build-pdfs and the `%! views: solutions' magic comment).
\newif\ifsolutions
\ifdefined\ShowSolutions \solutionstrue \fi

% \solution{...} prints its argument only in the solutions build. For a longer,
% multi-paragraph answer, guard a block with  \ifsolutions ... \fi  instead.
\newcommand{\solution}[1]{\ifsolutions #1\fi}
