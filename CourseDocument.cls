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

% Tunable lists: `[nosep]' for tight lists, `[parsep=,itemsep=]' for the
% loosely-spaced ones a policy document wants. Both are enumitem options, not
% stock list features.
%
% This class was the last of the three without it, and that was the wrong way
% round: a syllabus is more list than prose -- marking schemes, test policies,
% plagiarism definitions, FAQ -- so the class whose documents lean hardest on
% tunable lists was the one making every document \usepackage it by hand. Loaded
% here, before parskip, matching where LectureNotes and Assessment put it.
\RequirePackage{enumitem}

% Tables, on the same reasoning: a syllabus is more list AND TABLE than prose --
% a grade scale, an instructor/section roster, a TA/room roster, a term schedule
% -- so the class carries the table package rather than each document loading it.
% Not in LectureNotes or Assessment: neither is table-shaped, and tabularray is a
% heavy load (expl3) to hand a class that would not use it.
%
% The tabular-vs-tblr figure gap is real but does not bite here: Typefaces pins
% lining figures with \AtBeginEnvironment{tabular}, and tblr is not built on
% tabular, so a tblr full of dates stays osf under [osf]. Documents that are
% substantially data pass [lining] anyway, which is the actual fix.
%
% Load position is free: Hyperlinks defers hyperref to \AtEndPreamble
% (Hyperlinks.sty:33), so this is in well before hyperref either way.
\RequirePackage{tabularray}

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
% The identity colour is named ONCE here, and it is the colour that actually
% PRINTS -- change this line and every coloured mark in the document follows.
% NOT green: green means "solutions / not for students" (SolutionColor in
% Exercises.sty), so a student-facing course document must not read as green.
% Mahogany is a dark, part-desaturated red -- hue 1 degree, #A61916 -- which is
% what gives it its brownish cast; it is not a brown.
%
% HeadingColor and TitleColour are plain ALIASES, not shades. They exist because
% the machinery reaches for a colour by NAME, not because anything is derived:
% titlesec expands \color{HeadingColor} at each heading, Titling expands
% \color{TitleColour} at \maketitle, and \LinkColor below hands the name
% `HeadingColor' to \hypersetup. Nothing transforms them.
%
% RETIRED 2026-08-21: HeadingColor and TitleColour used to be Black!20! and
% Black!40! blends of CourseIdentity. Those were the ONLY two uses of
% CourseIdentity in the toolkit and both darkened it, so the declared identity
% colour was a value that never appeared in any PDF while the two shades that did
% appear went unnamed -- a derivation with a population of two, three lines
% away. The title's extra darkness was also a distinction used exactly once, and
% \maketitle already signals rank by size and weight.
%
% (If a future restyle does want a darker heading, mix with LOWERCASE `black' --
% xcolor's grey, which darkens in RGB and holds the hue. Capital `Black' is
% dvipsnames cmyk (0,0,0,1): it mixes in CMYK and raises K, so it greys the red
% as it darkens, which is how the old Black!20! blend lost 17 points of
% saturation. Undarkened Mahogany is 7.6:1 on white, so there is no legibility
% pressure to darken at all.)
\RequirePackage{xcolor}
\colorlet{CourseIdentity}{Mahogany}
\colorlet{HeadingColor}{CourseIdentity}
\colorlet{TitleColour}{HeadingColor}

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

