\ProvidesClass{LectureNotes}[2026/07/10]

\LoadClass{article} % TODO: extarticle + 14/17pt -- the parked layout conversation

\RequirePackage{import}
\RequirePackage{graphicx}

% No [osf] -- figures here are information; keep them lining.
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs.
\RequirePackage{Typefaces}
\RequirePackage{Titling}

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
% Lectures want no running head at all -- just a page number.
\RequirePackage{fancyhdr}
\renewcommand{\headrulewidth}{0pt}
\fancyhf{}
\fancyfoot[C]{\small\thepage}
\pagestyle{fancy}

% TEMPORARY, testing purposes only
\usepackage[english]{babel}
\usepackage[math]{blindtext}
