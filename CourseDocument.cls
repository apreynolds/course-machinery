\ProvidesClass{CourseDocument}[2026/07/10]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newif\ifLegalPaper
\DeclareOption{legalpaper}{\LegalPapertrue}

% [lining] -- opt OUT of the old-style body figures below. osf is right for
% continuous prose but clunky in a document that is mostly *data* read at a
% glance: dates, room numbers, section codes, percentages. A syllabus is both,
% and which one dominates is a per-document judgement, so it is a class option
% rather than a fixed property of the class.
%
% This has to live here because a DOCUMENT cannot reach it: Typefaces is loaded
% during \documentclass, so by the time a preamble could say
% \PassOptionsToPackage{lining}{Typefaces} the package is already in. Nor is
% there a global undo -- Libertinus defines \useosf and no \uselining twin
% (libertinus-type1.sty:204), which is why the only alternative was
% \liningnums{...} at every single call site.
\newif\ifLiningFigures
\DeclareOption{lining}{\LiningFigurestrue}

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

% Options must reach xcolor before any other package loads it.
\PassOptionsToPackage{dvipsnames}{xcolor}
\ProcessOptions\relax

\LoadClass{article}

\RequirePackage{import}
\RequirePackage{graphicx}

% [osf] -- prose-heavy documents get old-style figures in body text; [lining]
% above flips this document back to lining. Exactly one of the two options is
% passed, deliberately: passing both would work (Typefaces processes its options
% in DECLARED order, so `lining' would win as the later declaration), but only by
% accident of that file's line order, which is not a thing to depend on.
%
% Typefaces loads amsmath (and amsthm) itself, in the order newtxmath needs,
% and defines \alphabet (measured in the real body font -- so it must come
% after \LoadClass, and the geometry below must come after it).
\ifLiningFigures
  \RequirePackage[lining]{Typefaces}
\else
  \RequirePackage[osf]{Typefaces}
\fi
\RequirePackage{Titling}
\RequirePackage{Hyperlinks}

% \textbookref -- links into the course text (a syllabus cites the book as much
% as a lecture does). Mechanism only; the manifest is course data, in
% .textbook/textbook.tex.
\RequirePackage{TextRef}

% Instructor-only notes layer, shared with LectureNotes. AFTER Typefaces: this is
% where tcolorbox now legitimately enters this class (below the font block, per the
% "Fonts" load order). The instructor-copy signal is its page-edge frame -- no
% \TitleMarker override needed (see the Titling hooks below).
\RequirePackage{InstructorNotes}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The measure rule is the DEFAULT here -- there is no option to opt out.
% Without it you get article's stock 1in margins, i.e. ~90 characters a line,
% well past readable.
%
% legalpaper first: \paperwidth must be settled before the marginparwidth
% \dimexpr below reads it.
\RequirePackage{geometry}
\ifLegalPaper
  \geometry{legalpaper}
\fi

\geometry{textwidth=2.6\alphabet}
\geometry{head=15pt}
\if@twoside
  \geometry{hmarginratio={2:3}}
\else
  \geometry{hmarginratio={1:1}}
\fi
\geometry{marginparwidth=0.7\dimexpr\paperwidth-1.0in-\hoffset-\oddsidemargin-\textwidth\relax}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COLOURS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The identity colour is named ONCE here and derived everywhere it appears
% (title, headings, hyperref linkcolor), so it can be changed in one place.
% NOT green: green means "solutions / not for students" (SolutionColor in
% Exercises.sty), so a student-facing course document must not read as green.
% Mahogany is the rich brownish-red choice.
\RequirePackage{xcolor}
\colorlet{CourseIdentity}{Mahogany}
\colorlet{HeadingColor}{Black!20!CourseIdentity}
\colorlet{TitleColour}{Black!40!CourseIdentity}

% Titling hooks: this is the class that colours, and the one that stamps a time.
\renewcommand{\TitleColor}{\color{TitleColour}}
\renewcommand{\TitleStamp}{\space at \DTMcurrenttime}
% No \TitleMarker override: the instructor-copy signal is the page-edge frame
% (InstructorNotes.sty), not a title stamp.

% Hyperlinks hooks: internal links pick up the identity colour.
\renewcommand{\LinkColor}{HeadingColor}
\renewcommand{\UrlColor}{Black!20!RoyalBlue}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAGRAPHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Blank line between paragraphs instead of an indent -- one paragraph-boundary
% signal, not two. Default skip (.5\baselineskip plus 2pt).
%
% Loaded BEFORE titlesec. parskip patches LaTeX's \@startsection at load time
% and titlesec's own machinery at \AtBeginDocument, so it compensates for the
% \parskip that would otherwise double up after every heading. Those patches
% fail SILENTLY (a \typeout, not a warning): after any titlesec or amsthm
% upgrade, grep the log for "Couldn't patch" -- see the gotchas in
% manual/ch-architecture.tex.
\RequirePackage{parskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% usage: \titleformat{command}[shape]{format}{label}{sep}{before-code}[after-code]
% usage: \titlespacing*{command}{left}{before-sep}{after-sep}[right-sep]
\RequirePackage{titlesec}
\setcounter{secnumdepth}{3}

\titleformat{\section}[block]
  {\LARGE\sffamily\bfseries\color{HeadingColor}}{\thesection.}{0.3em}{}
\titlespacing*{\section}
  {0pt}{6ex plus 1ex minus .2ex}{3ex plus .2ex}

\titleformat{\subsection}[block]
  {\Large\sffamily\bfseries\color{HeadingColor}}{\thesubsection}{0.5em}{}
\titlespacing*{\subsection}
  {0pt}{4.5ex plus 1ex minus .2ex}{2ex plus .2ex}

\titleformat{\subsubsection}[block]
  {\sffamily\bfseries\itshape\color{HeadingColor}}{\thesubsubsection}{0.5em}{}
\titlespacing*{\subsubsection}
  {0pt}{4.5ex plus 1ex minus .2ex}{2ex plus .2ex}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HEADERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Two named styles, neither activated -- deliberate. \maketitle runs
% before the document picks a style, so the title page stays on `plain';
% defaulting to `myfancy' here would put a running head on it. Documents do:
%   \maketitle  \pagestyle{toc}  \tableofcontents  \newpage  \pagestyle{myfancy}
\RequirePackage{fancyhdr}

\fancypagestyle{myfancy}{%
  \renewcommand{\headrulewidth}{0.4pt}%
  \fancyhf{}%
  \fancyhead[R]{{\scshape\nouppercase{\leftmark}}}%
  \fancyfoot[C]{\thepage}%
}

\fancypagestyle{toc}{%
  \renewcommand{\headrulewidth}{0pt}%
  \fancyhf{}%
  \fancyfoot[C]{\thepage}%
}

