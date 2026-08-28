## Tree-aware extraction of completed work from a TODO document.
##
## This is the engine of the daily rollover: the previous day's file is parsed
## into a tree, completed work is removed, and what remains becomes today's
## file. It exists because the line-oriented `clean.nim` structurally cannot
## express the rules -- it has no nesting, so "remove a parent section that
## became empty" is not computable there, and it recognises only `## `.
##
## Rules:
##   * `- [x]`, `- [X]` and `- [-]` are removed together with their entire
##     subtree;
##   * `- [ ]` is never removed, but is still recursed into so a completed
##     child is extracted from an open parent;
##   * a note is never removed on its own;
##   * a section survives only if something remains inside it -- a task, a
##     note, or a surviving child section -- evaluated bottom-up, so a parent
##     whose children all collapsed collapses too.
##
## Everything that survives keeps its original text, indentation and order.
## Nothing is reformatted.

import std/strutils
import ./clean

type
  NodeKind* = enum
    nkDocument
    nkSection
    nkTask
    nkNote

  Node* = ref object
    kind*: NodeKind
    line*: string ## raw source line, never reformatted
    trailing*: seq[string] ## blank lines that FOLLOW this node
    blankBefore*: bool ## had >=1 blank line before it in the source
    indent*: int ## visual column of the first non-space character
    depth*: int ## header depth for sections, arbitrary
    marker*: char ## ' ' | 'x' | 'X' | '-' for tasks
    children*: seq[Node]
    removed*: bool

  ExtractResult* = object
    remaining*: string ## the document with completed work taken out
    extracted*: string ## the removed content, in original order
    count*: int ## how many completed tasks were extracted

const
  DoneMarkers = {'x', 'X', '-'}
  TabStop = 4

# --- lexing ---------------------------------------------------------------

func firstNonSpace(line: string): int =
  while result < line.len and line[result] in {' ', '\t'}:
    inc result

func visualIndent(line: string): int =
  ## Tab advances to the next multiple of four, so a tab-indented child and a
  ## four-space-indented child nest the same way. `clean.nim` counted raw
  ## characters instead, which orphaned tab-indented children of a completed
  ## task.
  for ch in line:
    case ch
    of ' ': inc result
    of '\t': result = (result div TabStop + 1) * TabStop
    else: return

func headerDepth(line: string): int =
  ## `^#+ ` at column zero. Any depth; markdown's limit of six is not enforced
  ## because the documents are ours, not a renderer's.
  var i = 0
  while i < line.len and line[i] == '#':
    inc i
  if i == 0 or i >= line.len or line[i] != ' ':
    return 0
  i

func taskMarker(line: string, offset: int): char =
  ## The character between the brackets of `- [?]`, or '\0' when this is not a
  ## checkbox. `- []` (no space) yields '\0' and is therefore a note, which is
  ## how the existing files use it.
  if offset + 4 < line.len and
     line[offset] == '-' and line[offset + 1] == ' ' and
     line[offset + 2] == '[' and line[offset + 4] == ']' and
     line[offset + 3] in DoneMarkers + {' '}:
    line[offset + 3]
  else:
    '\0'

func isBlank(line: string): bool =
  line.strip(chars = {' ', '\t'}).len == 0

# --- parsing --------------------------------------------------------------

proc parse*(content: string): Node =
  ## Single pass. Sections nest by header depth, tasks by visual indent, and a
  ## note indented past the open task belongs to that task's subtree -- which
  ## is what keeps continuation lines like `  - Monitor notifications` with
  ## the item they describe.
  result = Node(kind: nkDocument)
  var
    sections = @[result] ## innermost section last; the document is the root
    tasks: seq[Node] = @[]
    last = result ## node that trailing blank lines attach to
    blankRun = false

  for line in splitRecords(content):
    if isBlank(line):
      last.trailing.add(line)
      blankRun = true
      continue

    let depth = headerDepth(line)
    if depth > 0:
      while sections.len > 1 and sections[^1].depth >= depth:
        discard sections.pop()
      let node = Node(kind: nkSection, line: line, depth: depth,
                      blankBefore: blankRun)
      sections[^1].children.add(node)
      sections.add(node)
      tasks.setLen(0)
      last = node
      blankRun = false
      continue

    let
      offset = firstNonSpace(line)
      indent = visualIndent(line)
      marker = taskMarker(line, offset)

    while tasks.len > 0 and tasks[^1].indent >= indent:
      discard tasks.pop()

    let node = Node(
      kind: if marker == '\0': nkNote else: nkTask,
      line: line, indent: indent, marker: marker, blankBefore: blankRun,
    )
    if tasks.len > 0:
      tasks[^1].children.add(node)
    else:
      sections[^1].children.add(node)
    if node.kind == nkTask:
      tasks.add(node)
    last = node
    blankRun = false

# --- extraction -----------------------------------------------------------

proc markRemoved(node: Node) =
  node.removed = true
  for child in node.children:
    markRemoved(child)

proc countCompleted(node: Node): int =
  if node.kind == nkTask and node.marker in DoneMarkers:
    inc result
  for child in node.children:
    result += countCompleted(child)

proc prune(node: Node): bool =
  ## Returns true when `node` survives. Marks removed subtrees on the way.
  case node.kind
  of nkNote:
    true
  of nkTask:
    if node.marker in DoneMarkers:
      markRemoved(node)
      false
    else:
      for child in node.children:
        discard prune(child)
      true
  of nkSection, nkDocument:
    var survivor = false
    for child in node.children:
      if prune(child):
        survivor = true
    if node.kind == nkDocument:
      return true
    if not survivor:
      node.removed = true
    survivor

# --- rendering ------------------------------------------------------------

proc render(node: Node, buf: var string, full: bool) =
  if node.kind != nkDocument:
    # A removed node takes its trailing blank lines with it, which can leave a
    # surviving section glued to the line above. Restore the single separator
    # the source had, and nothing more.
    if node.kind == nkSection and node.blankBefore and
       buf.len > 0 and not buf.endsWith("\n\n"):
      buf.add("\n")
    buf.add(node.line & "\n")
    # Trailing blanks belong immediately after this node's own line, before
    # its children: the blank line following `## Shop` sits between the header
    # and its first task. A node can never own blanks that follow its
    # children, because whatever preceded such a blank was itself the last
    # node parsed, however deep.
    for blank in node.trailing:
      buf.add(blank & "\n")
  for child in node.children:
    if full or not child.removed:
      render(child, buf, full)

proc renderRemoved(node: Node, buf: var string) =
  ## Emits removed subtrees in document order. A removed section is emitted
  ## whole -- header included -- and not descended into, since everything
  ## inside it is removed by definition.
  for child in node.children:
    if child.removed:
      render(child, buf, full = true)
    else:
      renderRemoved(child, buf)

func stripLeadingBlankLines(s: string): string =
  var lines = splitRecords(s)
  var start = 0
  while start < lines.len and lines[start].len == 0:
    inc start
  if start >= lines.len:
    return ""
  lines[start .. ^1].join("\n") & "\n"

proc tallyRemoved(node: Node): int =
  for child in node.children:
    if child.removed:
      result += countCompleted(child)
    else:
      result += tallyRemoved(child)

proc extract*(content: string): ExtractResult =
  ## Removes every completed task and every section left empty by that
  ## removal, returning both halves of the split.
  let doc = parse(content)
  discard prune(doc)

  var remaining = ""
  render(doc, remaining, full = false)
  result.remaining = trimTrailingBlankLines(remaining)

  var extracted = ""
  renderRemoved(doc, extracted)
  result.extracted = trimTrailingBlankLines(stripLeadingBlankLines(extracted))

  result.count = tallyRemoved(doc)
