# .latexmkrc — put the machinery and the course's own course-info on TEXINPUTS.
#
# managed by build-pdfs -- edit .course-machinery/latexmkrc-shared instead
#
# latexmk reads only the rc in its startup directory and never walks up, so a
# copy must sit in every directory a build runs from. build-pdfs plants it
# before compiling. Copies are verbatim; delete the marker line above and the
# copy is yours, and the script leaves it alone from then on.
#
# WHAT GOES WHERE. One question decides it: is this a fact about ONE OFFERING of
# the course -- its rooms, its dates, who teaches it this term?
#
#   .course-machinery/   NO. Code, and facts about the outside world (a book's
#                        title and URL). A submodule, shared across courses, so
#                        nothing tied to one term belongs in it.
#   course-info/         YES. The offering's data files and the packages that
#                        read them, plus anything else that is this course's
#                        alone. Visible on purpose: a colleague correcting their
#                        office hours is an audience.
#   beside the document  everything used only by the documents in one directory
#                        -- found in the cwd, never on a search path
#
# Only the first two are search paths, and that is the whole content of this
# file. The last needs no help: TeX looks in the cwd, and we are already there.
#
# .course-machinery/ is added first and gets a trailing // so every file under it
# is findable. course-info/ is the FOLDER, not the repo root, so only what is
# deposited there is exposed; no trailing //, it is flat. Everything in both is
# found BY NAME -- which is what frees a document to sit at any depth, no ../..
# baked into a master, and why a \DTLread takes a bare filename.
#
# THE COURSE'S OWN FILES ARE SEARCHED FIRST, which is the opposite of the order
# these two lines are written in. latexmk's ensure_path PREPENDS (latexmk.pl,
# `Ensure the values are in it, prepending them if not'), so the SECOND call ends
# up in front.
# A course can therefore shadow a vendored machinery file with a same-named copy
# of its own. That is deliberate and occasionally useful -- it is how a course
# overrides one package without forking the submodule -- but it is the reason a
# basename must never collide here by accident: nothing warns, and the course's
# copy simply wins, for that course only. Verified by putting the same .sty in
# both directories and seeing which one a document got.
# build-images builds the same path in the same order; keep the two in step.
#
# THERE USED TO BE A THIRD: a hidden .course-machinery-local/ beside the
# machinery, for a course's own shared files. It hid the very files colleagues
# needed to edit, and mixed them with code, so its contents were divided
# between the two directories above. A course that still has one gets nothing
# from it -- move what it holds to course-info/.
#
# TWO TESTS find the machinery: in a course repo it is an ancestor's
# .course-machinery/; inside the machinery (its manual/) it IS an ancestor. Each
# level asks both, .course-machinery/ first, so a course resolves to its own
# submodule. build-pdfs is the machinery's marker.
#
# THE COST is that a bare pdflatex run finds none of this -- but a bare run was
# already unsafe: kpsewhich may resolve a class name to a stale copy in your own
# TeX tree. Build through latexmk or build-pdfs. Both paths are guarded, so a
# course with no course-info/ adds nothing for it.
use Cwd qw(abs_path);
my ($d, $m) = (abs_path('.'), undef);
while ($d) {
    if (-d "$d/.course-machinery") { $m = "$d/.course-machinery"; last }
    if (-f "$d/build-pdfs")        { $m = $d;                     last }
    last if $d eq '/';
    $d = abs_path("$d/..");
}
ensure_path('TEXINPUTS', "$m//")           if $m;
ensure_path('TEXINPUTS', "$d/course-info") if $m && -d "$d/course-info";
