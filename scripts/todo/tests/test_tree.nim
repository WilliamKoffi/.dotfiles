## Tests for the tree extractor that drives the daily rollover.
##
## The two worked examples are checked byte-for-byte; they are the contract.
## Everything else covers a rule the line-oriented clean.nim could not express.

import std/[strutils, unittest]
import ../src/todopkg/tree

proc md(s: varargs[string]): string =
  s.join("\n") & "\n"

suite "worked examples":

  test "example 1 -- section that becomes empty is removed":
    let input = md(
      "# Goal: create a beutilfy web site",
      "",
      "## dev",
      "- [ ] web:",
      "  - [ ] list les elements",
      "",
      "## brainstorming",
      "- [ ] locate the issue on the register page",
      "- [x] second task:",
      "    - [ ] do something",
      "",
      "## third section",
      "- [-] do another things",
    )
    let r = extract(input)
    check r.remaining == md(
      "# Goal: create a beutilfy web site",
      "",
      "## dev",
      "- [ ] web:",
      "  - [ ] list les elements",
      "",
      "## brainstorming",
      "- [ ] locate the issue on the register page",
    )
    # The collapsed section header is part of what was extracted.
    check r.extracted == md(
      "- [x] second task:",
      "    - [ ] do something",
      "",
      "## third section",
      "- [-] do another things",
    )
    check r.count == 2

  test "example 2 -- blank line after a header is preserved":
    let input = md(
      "# Todo",
      "",
      "## Shop",
      "",
      "- [x] Product",
      "- [ ] Customer",
      "  - [ ] Add customer",
      "  - [x] Delete customer",
      "",
      "## Website",
      "",
      "- [x] Homepage",
    )
    check extract(input).remaining == md(
      "# Todo",
      "",
      "## Shop",
      "",
      "- [ ] Customer",
      "  - [ ] Add customer",
    )

suite "task extraction":

  test "[x] is extracted":
    check extract(md("## s", "- [x] done", "- [ ] keep")).remaining ==
          md("## s", "- [ ] keep")

  test "[X] is extracted":
    check extract(md("## s", "- [X] done", "- [ ] keep")).remaining ==
          md("## s", "- [ ] keep")

  test "[-] is extracted":
    check extract(md("## s", "- [-] partial", "- [ ] keep")).remaining ==
          md("## s", "- [ ] keep")

  test "[ ] is never extracted":
    let input = md("## s", "- [ ] a", "- [ ] b")
    let r = extract(input)
    check r.remaining == input
    check r.extracted == ""
    check r.count == 0

  test "extracting a task takes its entire subtree":
    let r = extract(md(
      "## s",
      "- [x] parent",
      "    - [ ] child",
      "        - [ ] grandchild",
      "- [ ] keep",
    ))
    check r.remaining == md("## s", "- [ ] keep")
    check r.extracted == md(
      "- [x] parent", "    - [ ] child", "        - [ ] grandchild")

  test "a completed child is extracted from an open parent":
    check extract(md("## s", "- [ ] parent", "  - [x] done", "  - [ ] keep")).
          remaining == md("## s", "- [ ] parent", "  - [ ] keep")

  test "an open parent survives even when every child was completed":
    # Spec rule 2 read literally: `[ ]` is never extracted.
    check extract(md("## s", "- [ ] Customer", "  - [x] a", "  - [x] b")).
          remaining == md("## s", "- [ ] Customer")

  test "mixed extracted and kept tasks preserve order":
    check extract(md(
      "## s", "- [ ] a", "- [x] b", "- [ ] c", "- [-] d", "- [ ] e",
    )).remaining == md("## s", "- [ ] a", "- [ ] c", "- [ ] e")

suite "section collapsing":

  test "a section left empty is removed":
    check extract(md("## gone", "- [x] done", "## kept", "- [ ] keep")).
          remaining == md("## kept", "- [ ] keep")

  test "an empty parent section is removed recursively":
    check extract(md(
      "# top",
      "## middle",
      "### leaf",
      "- [x] done",
      "# other",
      "- [ ] keep",
    )).remaining == md("# other", "- [ ] keep")

  test "a parent survives when a nested child survives":
    check extract(md(
      "# top",
      "## a",
      "- [x] done",
      "## b",
      "### deep",
      "- [ ] keep",
    )).remaining == md("# top", "## b", "### deep", "- [ ] keep")

  test "arbitrary header depth is handled":
    let input = md("#### four", "- [ ] keep", "##### five", "- [x] done")
    check extract(input).remaining == md("#### four", "- [ ] keep")

  test "a section holding only a note survives":
    # clean.nim deletes this; the tree keeps it, per rule 4.
    let input = md("## notes", "just prose", "## other", "- [ ] keep")
    check extract(input).remaining == input

  test "a note keeps its section alive after its tasks are extracted":
    check extract(md("## s", "a note", "- [x] done")).remaining ==
          md("## s", "a note")

suite "notes and nesting":

  test "notes are preserved":
    let input = md("## s", "- [ ] task", "a standalone note")
    check extract(input).remaining == input

  test "a note indented under an extracted task goes with it":
    check extract(md(
      "## s",
      "- [x] Create an app to:",
      "  - Monitor notifications",
      "  - Send them to an API",
      "- [ ] keep",
    )).remaining == md("## s", "- [ ] keep")

  test "a bullet without a checkbox is a note, kept under an open task":
    let input = md("## s", "- [ ] Create an app to:", "  - Monitor things")
    check extract(input).remaining == input

  test "'- []' with no space is a note, not a task":
    let input = md("## s", "- [] no space", "- [ ] keep")
    check extract(input).remaining == input

  test "a tab-indented child nests like a four-space one":
    # clean.nim counted a tab as one character and orphaned this child.
    check extract(md("## s", "- [ ] a", "    - [x] b", "\t\t- [ ] c")).
          remaining == md("## s", "- [ ] a")

  test "two-space and four-space nesting both work":
    check extract(md("## s", "- [x] a", "  - [ ] two", "- [x] b",
                     "    - [ ] four", "- [ ] keep")).remaining ==
          md("## s", "- [ ] keep")

suite "formatting":

  test "indentation and text are preserved verbatim":
    let input = md(
      "## s",
      "-   [ ] odd    spacing   kept",
      "\t- [ ] tab indented",
      "      - [ ] six spaces",
    )
    check extract(input).remaining == input

  test "a blank separator before a surviving section is restored":
    # The extracted task takes its trailing blank line with it; the separator
    # the source had before `## b` must not be lost with it.
    check extract(md("## a", "- [ ] keep", "- [x] done", "", "## b",
                     "- [ ] keep2")).remaining ==
          md("## a", "- [ ] keep", "", "## b", "- [ ] keep2")

  test "trailing blank lines are trimmed":
    check extract(md("## s", "- [ ] keep", "", "")).remaining ==
          md("## s", "- [ ] keep")

  test "empty input yields empty output":
    check extract("").remaining == ""
    check extract("\n").remaining == ""

  test "input without a trailing newline is handled":
    check extract("## s\n- [ ] keep").remaining == md("## s", "- [ ] keep")

  test "a document with no sections still extracts":
    check extract(md("- [x] done", "- [ ] keep")).remaining == md("- [ ] keep")

  test "a completed task on the first line is extracted":
    # clean.nim printed the first two lines unconditionally and could never
    # extract this one.
    check extract(md("- [x] done on line 1", "- [ ] keep")).remaining ==
          md("- [ ] keep")

  test "extraction is idempotent":
    let once = extract(md("## s", "- [ ] keep", "- [x] done")).remaining
    let twice = extract(once)
    check twice.remaining == once
    check twice.extracted == ""

  test "everything extracted leaves an empty document":
    let r = extract(md("# t", "## s", "- [x] a", "- [-] b"))
    check r.remaining == ""
    check r.count == 2
