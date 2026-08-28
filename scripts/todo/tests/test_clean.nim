## Regression tests for the AWK-equivalence of the cleaner.
##
## Every expectation here was captured from the original Bash/AWK
## implementation before it was removed. If one of these fails, the port has
## drifted from the behaviour the TODO files were written against.

import std/[strutils, unittest]
import ../src/todopkg/clean

proc lines(s: varargs[string]): string =
  s.join("\n") & "\n"

suite "clean -- preserved AWK behaviour":

  test "first two lines are printed unconditionally":
    # NR<=2 { print; next } -- a completed item on line 1 or 2 survives.
    # details/scripts/asdf.md is exactly this shape.
    let input = lines("- [x] create a script:", "    - [-] list the shims")
    let r = clean(input)
    check r.kept == input
    check r.harvested.len == 0

  test "completed items and their children are removed":
    let r = clean(lines("# T", "", "- [ ] keep", "- [x] drop", "  - [ ] child of drop"))
    check r.kept == lines("# T", "", "- [ ] keep")
    check r.harvested == @["- [x] drop", "  - [ ] child of drop"]

  test "[-] is treated as completed":
    let r = clean(lines("# T", "", "- [-] cancelled", "- [ ] keep"))
    check r.kept == lines("# T", "", "- [ ] keep")
    check r.harvested == @["- [-] cancelled"]

  test "uppercase [X] is treated as completed":
    let r = clean(lines("# T", "", "- [X] done", "- [ ] keep"))
    check r.harvested == @["- [X] done"]

  test "sections with no open items are pruned":
    let input = lines("# T", "", "## Gone", "- [x] done", "## Kept", "- [ ] open")
    check clean(input).kept == lines("# T", "", "## Kept", "- [ ] open")

  test "a section is pruned even when it holds prose":
    # keep is only ever set by an open item, so prose alone cannot save a
    # section.
    let input = lines("# T", "", "## Gone", "just prose", "## Kept", "- [ ] open")
    check clean(input).kept == lines("# T", "", "## Kept", "- [ ] open")

  test "uninitialised skip_indent drops indented content before any heading":
    # AWK's uninitialised scalar compares as 0, so the program starts in the
    # "skipping at indent 0" state.
    check clean(lines("# Title", "", "  - [ ] indented open")).kept ==
          lines("# Title")
    check clean(lines("# Title", "", "    indented prose")).kept ==
          lines("# Title")

  test "'- []' is kept as text but does not keep its section alive":
    # No space between the brackets: matches neither branch, falls through.
    check clean(lines("# T", "", "- [] no space")).kept == lines("# T")
    let both = clean(lines("# T", "", "- [ ] open", "- [] no space"))
    check both.kept == lines("# T", "", "- [ ] open", "- [] no space")

  test "bullets without a checkbox are kept as continuation text":
    # details/android.md relies on this.
    let input = lines("# T", "", "- [ ] Create an app to:", "  - Monitor things")
    check clean(input).kept == input

  test "trailing blank lines are trimmed, whitespace-only lines are not":
    # The old `sed ':a;/^\n*$/{$d;N;ba}'` matched only truly empty lines.
    check clean(lines("# T", "", "- [ ] open", "", "")).kept ==
          lines("# T", "", "- [ ] open")
    check clean(lines("# T", "", "- [ ] open", "   ")).kept ==
          lines("# T", "", "- [ ] open", "   ")

  test "empty input yields empty output":
    check clean("").kept == ""
    check clean("\n").kept == ""

  test "input without a trailing newline is still a full record":
    check clean("# T\n\n- [ ] open").kept == lines("# T", "", "- [ ] open")

  test "tab-indented children of a completed item are removed":
    let r = clean(lines("# T", "", "- [x] done", "\t- [ ] tabbed child", "- [ ] keep"))
    check r.kept == lines("# T", "", "- [ ] keep")
    check r.harvested == @["- [x] done", "\t- [ ] tabbed child"]

  test "a blank line inside a skipped run is kept, not harvested":
    # The blank line goes into `section` rather than being dropped, so the
    # completed item leaves its blank line behind. Confirmed against the
    # original AWK; do not "tidy" this away.
    let r = clean(lines("# T", "", "- [x] done", "", "- [ ] keep"))
    check r.kept == lines("# T", "", "", "- [ ] keep")
    check r.harvested == @["- [x] done"]

suite "hasOpenItems":
  test "detects open items at any indent":
    check hasOpenItems(lines("- [ ] open"))
    check hasOpenItems(lines("  - [ ] nested open"))
    check not hasOpenItems(lines("- [x] done", "- [-] cancelled"))
    check not hasOpenItems(lines("- [] no space"))
    check not hasOpenItems("")
