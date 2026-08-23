# .latexmkrc — put the course's two SHARED machinery directories on TEXINPUTS.
#
# managed by build-pdfs -- edit .course-machinery/latexmkrc-shared instead
#
# latexmk reads only the rc in its startup directory and never walks up, so a
# copy must sit in every directory a build runs from. build-pdfs plants it
# before compiling. Copies are verbatim; delete the marker line above and the
# copy is yours, and the script leaves it alone from then on.
#
# THE THREE TIERS. Everything a document loads sits in exactly one of three
# places, and one question decides which: is this shared across files?
#
#   .course-machinery/        machinery shared across COURSES (a submodule)
#   .course-machinery-local/  machinery specific to THIS course but still shared
#                             across files, so it must be findable from any depth
#   beside the document       everything used only by the documents in one
#                             directory -- found in the cwd, never on a search path
#
# Only the first two are search paths, and that is the whole content of this
# file. Tier three needs no help: TeX looks in the cwd, and we are already there.
#
# .course-machinery/ goes on FIRST so its vendored .sty/.cls/.tex win over any
# same-named copies elsewhere; trailing // is recursive. .course-machinery-local/
# is the FOLDER, not the repo root, so only what is deposited there is exposed;
# no trailing //, it is flat. Its usual tenant is the text layer, found BY NAME --
# which is what frees a lecture to sit at any depth, no ../.. baked into a master.
#
# TWO TESTS find the machinery: in a course repo it is an ancestor's
# .course-machinery/; inside the machinery (its manual/) it IS an ancestor. Each
# level asks both, .course-machinery/ first, so a course resolves to its own
# submodule. build-pdfs is the machinery's marker.
#
# THE COST is that a bare pdflatex run finds none of this -- but a bare run was
# already unsafe: kpsewhich may resolve a class name to a stale copy in your own
# TeX tree. Build through latexmk or build-pdfs. Both paths are guarded, so a
# course with no local machinery adds nothing.
use Cwd qw(abs_path);
my ($d, $m) = (abs_path('.'), undef);
while ($d) {
    if (-d "$d/.course-machinery") { $m = "$d/.course-machinery"; last }
    if (-f "$d/build-pdfs")        { $m = $d;                     last }
    last if $d eq '/';
    $d = abs_path("$d/..");
}
ensure_path('TEXINPUTS', "$m//")                       if $m;
ensure_path('TEXINPUTS', "$d/.course-machinery-local") if $m && -d "$d/.course-machinery-local";
