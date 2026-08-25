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
% as a lecture does). Mechanism only; the manifest is course data, in the
% course's own text layer (.course-machinery-local/textbook.tex).
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
% PASSAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A PASSAGE is a piece of prose that belongs to the AUTHOR rather than to the
% course: why learning mathematics is worth the effort, how marking works, what
% makes a solution readable. It is shared across COURSES, so it lives in its own
% content repository (a `teaching/' submodule beside the topic submodules) and
% is pulled in here by relative path.
%
% WHY THIS IS NOT A TIER. A passage bank is content, and content in this toolkit
% has never been on a search path: \importproblem hands a literal relative
% directory to \import, and the architecture chapter's rule is that a file goes
% on TEXINPUTS only when its readers sit at depths it cannot predict. A passage's
% readers are the prose documents of one course, in one directory. So nothing
% here touches .latexmkrc, TEXINPUTS, or the three tiers -- see the architecture
% chapter, "A passage bank is content, not a tier".
%
% THE LEVEL PROBLEM, which is the whole reason this is a command and not \input.
% The same passage is a \section of one document and a \subsection of another,
% and a passage that carries its own \subsection headings has to move WITH its
% title. So the file is written at its NATURAL depth -- \PassageTitle for the
% title, plain \subsection for anything inside it -- and the importing document
% says where that natural depth lands:
%
%   \importpassage{../teaching/passages/}{why-learn-math.tex}                 % \section
%   \importpassage[level=subsection]{../teaching/passages/}{why-learn-math.tex}
%
% The shift is three \let's in a group, done TOP-DOWN so each one captures the
% still-original meaning of the level below it. \PassageTitle then needs no
% special case at all: it is \section, which the \let has already pointed at the
% right target. \label, \ref, starred forms and TOC entries all keep working
% because these are the real sectioning commands, not imitations of them.
%
% ONE LEVEL OF HEADROOM, deliberately. The SECTIONS block above styles exactly
% three levels and \paragraph is not among them -- it would fall back to
% article's run-in bold, which is not a heading in this design. So a shift of
% one is supported and anything deeper is an ERROR rather than a silent
% degradation. That is enough for every passage that exists: the deepest is a
% title plus one rank of subsections.
%
% Load-order note: the \let's run at USE time, long after titlesec and parskip
% have patched the sectioning commands (parskip at \AtBeginDocument), so what
% they copy is the fully-patched meaning. keyval arrives with graphicx above.
%
% WHERE THIS LIVES. In the class, because prose documents are its only client --
% the house rule is to extract when a SECOND document type actually needs it,
% not in advance. The day a lecture wants a passage, this block moves to a
% Passages.sty and all three classes load it; nothing above depends on it, so
% that move is a cut and paste. (Compare Exercises.sty's note on lifting the
% fact block into a standalone Facts.sty.)
\newif\ifPassage@shifted

\define@key{passage}{level}{%
  \Passage@shiftedfalse
  \def\Passage@given{#1}%
  \def\Passage@atsection{section}%
  \def\Passage@atsubsection{subsection}%
  \ifx\Passage@given\Passage@atsubsection
    \Passage@shiftedtrue
  \else
    \ifx\Passage@given\Passage@atsection
    \else
      \ClassError{CourseDocument}{%
        Unknown passage level `#1'%
      }{%
        \string\importpassage\space accepts level=section (the default) or
        level=subsection.\MessageBreak
        Deeper is refused on purpose: this class styles three heading levels,
        and\MessageBreak a further shift would land on \string\paragraph,
        which is not one of them.%
      }%
    \fi
  \fi
}

% What \subsubsection becomes under a shift: a loud stop, not a \paragraph. The
% argument signature matches a real sectioning command so the error fires
% instead of the title leaking into the text as stray prose.
\NewDocumentCommand{\Passage@toodeep}{s o m}{%
  \ClassError{CourseDocument}{%
    Passage heading pushed past \string\subsubsection
  }{%
    An imported passage used \string\subsubsection\space while being imported
    at level=subsection,\MessageBreak
    which would push it onto \string\paragraph. Either import this passage at
    level=section,\MessageBreak or flatten a heading rank inside the passage
    file.%
  }%
}

% The title of a passage, written by the passage itself. The optional argument
% is the \label, which belongs to the passage (it names the passage's own idea)
% rather than to whichever document happens to be importing it.
\NewDocumentCommand{\PassageTitle}{o m}{%
  \section{#2}%
  \IfValueT{#1}{\label{#1}}%
}

\NewDocumentCommand{\importpassage}{O{} m m}{%
  \begingroup
    \setkeys{passage}{level=section,#1}%
    \ifPassage@shifted
      \let\section\subsection
      \let\subsection\subsubsection
      \let\subsubsection\Passage@toodeep
    \fi
    \import{#2}{#3}%
  \endgroup
}

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

