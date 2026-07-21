# .latexmkrc -- the manual lives INSIDE the machinery, so the course-repo copy of
# this file (which walks UP to a directory *containing* .course-machinery) cannot
# serve here: in a standalone clone of the machinery there is no such ancestor.
# Instead point TEXINPUTS straight at the machinery root, the parent directory.
# The trailing // is recursive, matching the course-repo convention.
use Cwd qw(abs_path);
ensure_path('TEXINPUTS', abs_path('..').'//');
