## Faithful port of the clean_todo() AWK program that lived inside the Bash
## todo() function (bash/.config/bash/functions.sh).
##
## The port is behavioural, not textual: same output for the same input,
## byte for byte, including the quirks below. Three of them are easy to
## "fix" by accident and must not be:
##
##   1. `NR<=2 { print; next }` prints the first two lines unconditionally.
##      A completed item on line 1 or 2 therefore survives cleaning and is
##      never harvested (details/scripts/asdf.md is exactly this shape).
##
##   2. `skip_indent` is never initialised, and in AWK an uninitialised
##      scalar compares numerically as 0. So the program starts in the
##      "skipping at indent 0" state: indented content appearing before the
##      first `## ` heading is dropped. Verified against the original.
##
##   3. A `- []` bullet (no space between the brackets) matches neither the
##      done branch nor the open branch. It falls through to the trailing
##      block, so its text is kept but it does NOT mark the section as worth
##      keeping. details/projects/p7.md relies on this.
##
## The trailing `sed ':a;/^\n*$/{$d;N;ba}'` trimmed blank lines at EOF; note
## it matched only *empty* lines, never whitespace-only ones.

import std/strutils

type CleanResult* = object
  kept*: string ## the cleaned document, ready to write back
  harvested*: seq[string] ## completed lines removed, in original order

func splitRecords*(content: string): seq[string] =
  ## Splits like AWK splits records on ORS: a trailing newline terminates the
  ## final record rather than introducing an empty one.
  result = content.split('\n')
  if result.len > 0 and result[^1].len == 0:
    result.setLen(result.len - 1)

func leadingWhitespace(line: string): int =
  ## RLENGTH of AWK's `match($0, /^[ \t]*/)`.
  while result < line.len and line[result] in {' ', '\t'}:
    inc result

func isBullet(line: string, indent: int): bool =
  ## `/^[ \t]*- /` -- note the mandatory space after the dash.
  indent + 1 < line.len and line[indent] == '-' and line[indent + 1] == ' '

func marker(line: string, indent: int): char =
  ## Returns the character between the brackets of `- [?]`, or '\0' when the
  ## line is not a bracketed checkbox at all.
  if indent + 4 < line.len and line[indent + 2] == '[' and line[indent + 4] == ']':
    line[indent + 3]
  else:
    '\0'

func trimTrailingBlankLines*(s: string): string =
  var lines = splitRecords(s)
  var n = lines.len
  while n > 0 and lines[n - 1].len == 0:
    dec n
  if n == 0:
    return ""
  lines.setLen(n)
  lines.join("\n") & "\n"

proc clean*(content: string): CleanResult =
  ## Mirrors the AWK program block for block. `outBuf` is AWK's stdout,
  ## `section` its buffered current section.
  var
    outBuf = ""
    section = ""
    keep = false
    skipIndent = 0 # AWK's uninitialised scalar; see quirk 2 above

  for i, line in splitRecords(content):
    # NR<=2 { print; next }
    if i < 2:
      outBuf.add(line & "\n")
      continue

    # /^## /
    if line.startsWith("## "):
      if keep:
        outBuf.add(section)
      section = line & "\n"
      keep = false
      skipIndent = -1
      continue

    # /^[ \t]*- /
    let indent = leadingWhitespace(line)
    if isBullet(line, indent):
      if skipIndent >= 0 and indent > skipIndent:
        result.harvested.add(line) # child of a completed item
        continue
      skipIndent = -1
      case marker(line, indent)
      of 'x', 'X', '-':
        skipIndent = indent
        result.harvested.add(line)
        continue
      of ' ':
        section.add(line & "\n")
        keep = true
        continue
      else:
        # the `- []` case: no branch matched, so AWK carries on into the
        # trailing block with skipIndent already reset to -1. See quirk 3.
        discard

    # the trailing unconditional block
    if skipIndent >= 0:
      if line.len > 0 and line[0] in {' ', '\t'}:
        result.harvested.add(line) # indented continuation of a completed item
        continue
      if line.len == 0:
        section.add(line & "\n")
        continue
      skipIndent = -1
    section.add(line & "\n")

  if keep:
    outBuf.add(section)
  result.kept = trimTrailingBlankLines(outBuf)

func hasOpenItems*(content: string): bool =
  ## True when cleaning would leave at least one `- [ ]` behind. Used to
  ## classify a TODO file as still-live rather than exhausted.
  for line in splitRecords(content):
    let indent = leadingWhitespace(line)
    if isBullet(line, indent) and marker(line, indent) == ' ':
      return true
  false
