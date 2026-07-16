\ProvidesClass{Test}[2026/07/10]

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

% Blank line between paragraphs instead of an indent. Default skip; assessments
% are structured questions rather than continuous prose, so the indent signal
% has little to do here. No Titling -- an assessment opens with a NAME/ID box.
\RequirePackage{parskip}

% The solutions toggle and \begin{solution} used to be defined here as
% scaffolding; they now live in Exercises.sty (loaded above) so lectures can
% import solution-bearing problems too. build-pdfs still drives it the same way:
% \def\ShowSolutions{} injected for the -SOLUTIONS twin (`%! views: solutions').
