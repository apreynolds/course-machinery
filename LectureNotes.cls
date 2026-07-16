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

% Same shape as Test.cls's \ShowSolutions: build-pdfs' view loop can inject
% \def\ProjectorView{} before \documentclass is read, so the view needs no class
% option at the call site. (Build arms still unwired -- see NOTE.md.)
\ifdefined\ProjectorView \Projectortrue \fi

\ifProjector
  \LoadClass[17pt]{extarticle}
\else
  \LoadClass[14pt]{extarticle}
\fi

\RequirePackage{import}
\RequirePackage{graphicx}

% The exercise system. Two independent packages, essential first:
%   Exercises  -- \begin{problem}/\begin{solution} + the solutions toggle. A
%                 lecture imports problem files too, and they may carry solutions.
%   ProblemMeta -- greppable topic/tag metadata. Nice-to-have; removable on its
%                 own (Exercises no longer depends on it) without breaking builds.
\RequirePackage{Exercises}
\RequirePackage{ProblemMeta}

% No [osf] -- figures here are information; keep them lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs,
% and defines \alphabet (measured in the real body font -- so it must come
% after \LoadClass, and the geometry below must come after it).
\RequirePackage{Typefaces}
\RequirePackage{Titling}
\RequirePackage{Hyperlinks}

% No \TitleColor override: lecture headings stay black. Colour is for course
% documents only -- lectures sit with assessments on the "clear, not fancy" side.
% \LinkColor/\UrlColor likewise keep Hyperlinks' plain defaults (black/RoyalBlue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% textwidth follows the measure rule rather than a frozen length; see Typefaces.
% At 14pt this gives ~6.31in (the inherited hardcode was 6.382in, derived for a
% font we no longer use); at 17pt it re-derives on its own.
\RequirePackage{geometry}
\geometry{letterpaper}
\ifProjector
  % Room copy: no marginpar, top margin tightened to buy vertical space.
  \geometry{top=0.25in, bottom=0.75in, textwidth=2.6\alphabet}
\else
  % Handout: left margin fixed, remainder falls to the right and carries the
  % marginpar column.
  \geometry{top=0.5in, bottom=0.75in, left=0.5in,
            textwidth=2.6\alphabet, marginparwidth=1.3in}
\fi

% No \TitleColor override: lecture headings stay black. Colour is for course
% documents only -- lectures sit with assessments on the "clear, not fancy" side.
% \TitleMarker stays empty until \InstructorNote exists; that is where the
% -INSTRUCTOR view's "Instructor Copy" flag will hang.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAGRAPHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% skip=1em, deliberately airier than parskip's default (.5\baselineskip plus 2pt)
% -- 10x3 chose this for lectures alone. Reads as a pedagogical call (room to
% annotate, legible at a distance), not a typographic one; it is also the trade
% against the display-math argument, since parskip weakens the
% continuation-vs-new-paragraph cue after a display. Keep knowingly.
%
% Loaded BEFORE titlesec, as 10x3 did. See CourseDocument.cls / NOTE.md
% "Paragraphs" on the silent-patch hazard.
\RequirePackage[skip=1em]{parskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% usage: \titleformat{command}[shape]{format}{label}{sep}{before-code}[after-code]
% usage: \titlespacing*{command}{left}{before-sep}{after-sep}[right-sep]
\RequirePackage{titlesec}
\RequirePackage{titletoc}
\setcounter{secnumdepth}{1}
\setcounter{tocdepth}{3}

% titlesec calls \<name>break before each such title (titlesec.sty:435-437), so
% this really does \clearpage before every subsection. Deliberate in 10x3.
\newcommand{\subsectionbreak}{\clearpage}

\titleformat{\section}[block]
  {\sffamily\bfseries\Large}{\thesection}{0.7em}{}[]

\titleformat{\subsection}[block]
  {\sffamily\bfseries\large}{\thesubsection}{0.7em}{}[]
% 10x3 had `{\thesection-\thesubsection asdd}' here -- a stray typo, dormant only
% because secnumdepth=1 leaves subsections unnumbered, so titlesec never
% typesets the label. Dropped.

\titleformat{\subsubsection}[block]
  {\sffamily\bfseries\itshape}{\thesubsubsection}{1em}{}[]
% 10x3 had `{\thesection}' here -- the wrong counter, dormant for the same reason.

%USAGE: \titlespacing*{command}{left}{before-sep}{after-sep}[right-sep]
\titlespacing*{\section}{0em}{2em}{1em}[0em]
\titlespacing*{\subsection}{0pt}{1.0em}{1.0em}
\titlespacing*{\subsubsection}{0pt}{1em}{0.3em}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\titlecontents{section}[1em]
  {}
  {\bfseries\thecontentslabel. \normalfont \enspace }
  {\normalfont\enspace}
  {\titlerule*[0.8pc]{.} \bfseries \thecontentspage}[]

\titlecontents{subsection}[2.5em]
  {\small}
  {\thecontentslabel. \enspace }
  {\enspace}
  {\hfill \thecontentspage}[]

\titlecontents{subsubsection}[3.5em]
  {\small}
  {\thecontentslabel. \enspace }
  {\enspace}
  {\hfill \thecontentspage}[]

\contentsmargin{1em}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lectures want no running head at all -- just a page number, and not even that
% on the projector copy: it is scrolled on screen and never collated, so a page
% number is noise. \fancyhf{} clears every field; each view puts back only what
% it wants.
\RequirePackage{fancyhdr}
\renewcommand{\headrulewidth}{0pt}
\fancyhf{}

\ifProjector
  % Back-to-top arrow, bottom right of every page. The projector copy is scrolled
  % rather than paged, so a way back to the top earns its keep -- and grey keeps
  % it from competing with the content when projected.
  %
  % The FOOTER is the whole trick. songsheets' equivalent (MyLeadsheets.sty's
  % \MyLStochint) emits into the text body, so it needs \pagegoal/\pagetotal
  % arithmetic and a fit test to avoid forcing an extra page -- and a full page
  % silently gets no link. A footer is reserved space: every page, no arithmetic,
  % cannot overflow.
  \definecolor{TopLinkGray}{gray}{0.5}
  \fancyfoot[R]{\BackToTopLink{\textcolor{TopLinkGray}{\large$\uparrow$}}}
\else
  \fancyfoot[C]{\small\thepage}
\fi
\pagestyle{fancy}

% TEMPORARY, testing purposes only
\usepackage[english]{babel}
\usepackage[math]{blindtext}
