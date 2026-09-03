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
\RequirePackage{TitleBlock}
\RequirePackage{Hyperlinks}

% \textbookref -- links into the course text (a syllabus cites the book as much
% as a lecture does). Mechanism only; the manifest is course data, in the
% course's own text layer (.course-machinery-local/textbook.tex).
\RequirePackage{TextRef}

% Instructor-only notes layer, shared with LectureNotes. AFTER Typefaces: this is
% where tcolorbox now legitimately enters this class (below the font block, per the
% "Fonts" load order). The instructor-copy signal is its page-edge frame -- no
% \TitleMarker override needed (see the TitleBlock hooks below).
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
% titlesec expands \color{HeadingColor} at each heading, TitleBlock expands
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

% TitleBlock hooks: this is the class that colours, and the one that stamps a time.
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
% WHICH WAY A PASSAGE CAN BE SHIFTED is not guesswork: its \PassageMeta block
% records `depth', either {title} (flat prose, imports at either level) or
% {subsections} (carries a rank of its own, so level=section only). Read it before
% shifting -- `find-passages --tsv' prints it as a column, and the picker shows it.
% Deliberately NOT spelled with level's own two words: depth is a property of the
% passage and level of the document importing it, and one vocabulary for two axes
% is how two things end up under one name.
%
% METADATA. Since 2026-08-25 a passage carries a \PassageMeta{} block, read off
% disk by find-passages and, uniquely among the three Meta packages, read at build
% time too: \PassageTitle takes its title and label from it. See PassageMeta.sty
% for why this one stores when its siblings discard.
%
% THE EDITOR'S NOTE is the second call-site key, and the only other one:
%
%   \importpassage[note={Note: this section is in the student syllabus; we can
%                        discuss and refine as needed.}]%
%     {../teaching/passages/}{how-work-is-marked.tex}
%
% It prints an italic parenthetical under the passage's heading, in the document
% doing the importing and nowhere else. See the block beside \Passage@note below
% for why it cannot be metadata.
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
% Loaded HERE rather than beside \RequirePackage{import} at the top, so that it
% travels with this block on the day a lecture wants a passage and the whole thing
% moves to a Passages.sty (see the note above). PassageMeta owns \PassageMeta@title
% and \PassageMeta@label; this class is their only reader. \providecommand so that
% a document which somehow lacks the package hits the ClassError in \PassageTitle
% below -- a sentence naming the problem -- rather than an undefined control
% sequence pointing at a macro nobody has heard of.
\RequirePackage{PassageMeta}
% etoolbox for \ifdefempty, the test \PassageTitle needs. Loaded explicitly rather
% than leaned on transitively (titlesec and tabularray both pull it in), the way
% enumitem and tabularray are -- and it travels with this block if it ever moves.
\RequirePackage{etoolbox}
\providecommand{\PassageMeta@title}{}
\providecommand{\PassageMeta@label}{}

\newif\ifPassage@shifted

% THE EDITOR'S NOTE, and why it is a CALL-SITE key rather than a PassageMeta one.
% A passage is written in one voice and imported by several documents:
% how-work-is-marked.tex is student-facing prose in advice-for-students and a thing
% the instructors want glossed in notes-for-instructors. The gloss -- "this section
% is in the student syllabus; we can discuss and refine it" -- is true from the
% second document's side and meaningless from the first's. So it is a property of
% the IMPORTING DOCUMENT, exactly as `level' is, and PassageMeta.sty's argument for
% keeping `level' out of the block applies to this word for word. Put it in the
% block instead and every document importing that passage prints the same note.
%
% (PassageMeta.sty's aside that "every passage is imported by exactly one document"
% stopped being true some time ago -- eleven of fourteen are imported two or three
% times -- and that is exactly what makes a per-import note necessary.)
%
% NOTHING HERE BECOMES INJECTABLE, which is worth saying because it is the
% invariant a reader will worry about. find-passages still emits bare
% \importpassage lines and still takes no --with; `note' is hand-written at the
% call site the way `level' is. The passage bank is untouched by this feature.
%
% Plain \def, not \gdef, for PassageMeta.sty's reason: the value must die with the
% \importpassage group that set it, or the next passage in the document inherits a
% note nobody wrote for it.
\newcommand{\Passage@note}{}

% Did the passage just imported actually call \PassageTitle? A note is SET at the
% call site and PRINTED inside the passage, so a file lacking \PassageTitle
% swallows it in silence -- and nothing else here notices a missing title. This
% flag turns that into a warning naming the file.
%
% A plain (local) \newif suffices, and that is not luck: import.sty closes its own
% \begingroup inside a \protected@edef BEFORE \@import runs, so the \input happens
% at \importpassage's group level and a flag set inside the passage file is still
% standing when the guard below reads it.
\newif\ifPassage@titled

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

% The note's text. No fixed `Note:' prefix and no vocabulary behind it: the author
% writes the whole sentence and this supplies only the italics and the parentheses,
% because a note that does not want to open with the word `Note' is as likely as
% one that does. Unvalidated for the same reason -- it is prose, not a key with a
% closed set of legal values, so there is nothing here to be wrong about.
\define@key{passage}{note}{\def\Passage@note{#1}}

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

% The title of a passage, written by the passage itself. It TAKES NO ARGUMENTS:
% both the title and the label come from the \PassageMeta block at the top of the
% same file, which is also what find-passages reads off disk. They used to be
% arguments here, and moving them into the block on 2026-08-25 was the point of
% adding PassageMeta -- otherwise the title would be written twice in one file,
% four lines apart, which is how `desc' and `name' drifted apart.
%
% ORDERING RULE: \PassageMeta must come before \PassageTitle in the file. It does
% naturally -- the block heads the file the way \ProblemMeta heads a problem --
% and getting it wrong is caught, not silently mistitled, by the error below.
%
% The label is optional (a passage nothing refers to needs none); the title is
% not. A missing title means the block is absent, malformed, or below this call,
% and in every one of those cases a silent empty \section{} is the wrong answer:
% this is the one metadata package the toolkit cannot build without, so it says so
% in the voice \Passage@toodeep uses just above.
\NewDocumentCommand{\PassageTitle}{}{%
  % Recorded before anything can go wrong, so that a passage which reaches this
  % line at all counts as titled -- the guard in \importpassage is asking "was the
  % note ever offered a place to print?", and the error branch below is a place.
  \Passage@titledtrue
  \ifdefempty{\PassageMeta@title}{%
    \ClassError{CourseDocument}{%
      \string\PassageTitle\space with no title in \string\PassageMeta
    }{%
      Every passage needs \string\PassageMeta{title={...}} ABOVE its
      \string\PassageTitle.\MessageBreak
      Either this file has no \string\PassageMeta\space block, or the block
      sets no title,\MessageBreak or it appears below this line. Unlike
      ProblemMeta and FactMeta, the passage\MessageBreak block is not optional:
      it is where the title and label live.%
    }%
  }{%
    % \expandafter so \section receives the TITLE TEXT, not the macro holding it.
    % Without it hyperref records \@currentlabelname as the unexpanded
    % \PassageMeta@title, writes that into the .aux, and every \secref to a passage
    % resolves against whatever the LAST imported passage happened to leave in it
    % -- so all of them come out with the same wrong name. The number and page
    % fields are unaffected, which is what makes the bug quiet: only \nameref-style
    % references show it, and only after a second run.
    \expandafter\section\expandafter{\PassageMeta@title}%
  }%
  \ifdefempty{\PassageMeta@label}{}{\label{\PassageMeta@label}}%
  % The editor's note from the call site, if the importing document gave one.
  % AFTER the \label, so nothing comes between \section and the label it binds;
  % BEFORE the body, so it reads as a gloss on the heading rather than an aside in
  % the prose.
  %
  % No \expandafter here, unlike the title above, and the asymmetry is the point:
  % this text goes to the page and nowhere else -- no .aux, no .toc, no \nameref --
  % so there is no deferred write for an unexpanded macro to poison.
  %
  % Braces around \itshape keep the italics off the passage body. \par closes the
  % paragraph so parskip separates it from what follows; \parindent is 0pt in this
  % class, so it needs no \noindent.
  \ifdefempty{\Passage@note}{}{{\itshape(\Passage@note)}\par}%
}

\NewDocumentCommand{\importpassage}{O{} m m}{%
  \begingroup
    % Cleared explicitly although \begingroup already isolates them, exactly as
    % \PassageMeta clears its own values rather than trusting the caller's group:
    % belt and braces, so a later refactor that drops the group cannot quietly
    % resurrect the leak.
    \def\Passage@note{}%
    \Passage@titledfalse
    \setkeys{passage}{level=section,#1}%
    \ifPassage@shifted
      \let\section\subsection
      \let\subsection\subsubsection
      \let\subsubsection\Passage@toodeep
    \fi
    \import{#2}{#3}%
    % A note given but never printed is a silent loss -- the one failure mode this
    % feature introduces, since the key is set here and consumed a file away. A
    % warning rather than an error: the document is still correct, just missing a
    % sentence its author asked for.
    \ifdefempty{\Passage@note}{}{%
      \ifPassage@titled\else
        \ClassWarning{CourseDocument}{%
          note= was given for `#3' but that passage never calls
          \string\PassageTitle,\MessageBreak so the note was dropped%
        }%
      \fi
    }%
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

