## Archiving of old TODO files and harvesting of completed detail-file work.
##
## Rules implemented here (see README.md for the rationale):
##
##   TODO files -- `TODO.YYYYMMDD.md` directly in the todos root. The two
##   newest by *date* are retained: today's file and the most recent file
##   older than today. Everything else moves verbatim into `archives/`,
##   flat, because root files have no relative subpath. Retaining the newest
##   older file rather than literally yesterday keeps the "fall back to the
##   most recent TODO" path working after a skipped day.
##
##   Detail files -- every `*.md` under `details/`, at any depth. These are
##   never moved and never deleted. Completed work is extracted out of the
##   live file by the tree extractor and appended to
##   `archives/details/<path>/<name>.<YYYYMMDD>.md`, so the live file keeps
##   only open work and the archive records what was finished, dated. A file
##   with nothing completed is not touched at all.
##
## `archives/` is never itself a source: TODO scanning is non-recursive and
## detail scanning is rooted at `details/`, so the directory cannot recurse
## into its own output.

import std/[algorithm, os, strutils, times]
import ./tree
import ./log

const
  ArchivesDir* = "archives"
  DetailsDir* = "details"
  TodoPrefix = "TODO."
  TodoSuffix = ".md"
  RetainedTodoFiles = 2 ## today's file plus the newest one older than today

type
  Plan* = object
    dryRun*: bool

  DatedTodo = object
    name: string
    date: DateTime

proc parseTodoDate(name: string): (bool, DateTime) =
  ## Accepts exactly `TODO.YYYYMMDD.md`; anything else is not a dated TODO
  ## file and is left alone (this is what protects TODO.cleared.md and
  ## friends).
  if not (name.startsWith(TodoPrefix) and name.endsWith(TodoSuffix)):
    return (false, DateTime())
  let stamp = name[TodoPrefix.len ..< name.len - TodoSuffix.len]
  if stamp.len != 8 or not stamp.allCharsInSet({'0' .. '9'}):
    return (false, DateTime())
  try:
    (true, parse(stamp, "yyyyMMdd", utc()))
  except TimeParseError:
    (false, DateTime())

proc uniqueDestination(path: string): string =
  ## Never clobber an existing archive. Falls back to `name.1.md`, `name.2.md`
  ## and so on; in practice this only fires if a file was archived, restored
  ## and archived again.
  if not fileExists(path):
    return path
  let (dir, name, ext) = splitFile(path)
  for n in 1 .. 999:
    let candidate = dir / (name & "." & $n & ext)
    if not fileExists(candidate):
      return candidate
  raise newException(IOError, "cannot find a free archive name for " & path)

proc archiveTodoFiles*(root: string, today: DateTime, plan: Plan) =
  ## Moves every dated TODO file except the two newest into `archives/`.
  var dated: seq[DatedTodo]
  for kind, path in walkDir(root, relative = true):
    if kind != pcFile:
      continue
    let (ok, date) = parseTodoDate(path)
    if ok:
      dated.add(DatedTodo(name: path, date: date))

  # Newest first, with the name as a tiebreaker so the order is total and
  # the run is reproducible.
  dated.sort(proc(a, b: DatedTodo): int =
    result = cmp(b.date, a.date)
    if result == 0:
      result = cmp(a.name, b.name)
  )

  if dated.len <= RetainedTodoFiles:
    return

  let archives = root / ArchivesDir
  let todayName = TodoPrefix & today.format("yyyyMMdd") & TodoSuffix
  for entry in dated[RetainedTodoFiles .. ^1]:
    # Belt and braces: today's file is always among the retained prefix, but
    # state the invariant rather than relying on it. Compared by name, not by
    # instant, because `today` is local while the names parse as UTC.
    if entry.name == todayName:
      continue
    let src = root / entry.name
    let dest = uniqueDestination(archives / entry.name)
    if plan.dryRun:
      info("would archive " & entry.name & " -> " & relativePath(dest, root))
      continue
    createDir(archives)
    moveFile(src, dest)
    info("archived " & entry.name & " -> " & relativePath(dest, root))

func datedName(relative, stamp: string): string =
  ## `shop/customer.md` + `20260826` -> `shop/customer.20260826.md`. The date
  ## lives in the filename rather than in a heading inside the file, so an
  ## archived detail is identifiable without opening it.
  let (dir, name, ext) = splitFile(relative)
  dir / (name & "." & stamp & ext)

proc harvestDetailFile(root, relative: string, stamp: string, plan: Plan) =
  let live = root / DetailsDir / relative
  let harvest = extract(readFile(live))
  if harvest.extracted.len == 0:
    return

  let dest = root / ArchivesDir / DetailsDir / datedName(relative, stamp)

  if plan.dryRun:
    info("would harvest " & $harvest.count & " item(s) from " &
         DetailsDir / relative & " -> " &
         ArchivesDir / DetailsDir / datedName(relative, stamp))
    return

  createDir(dest.parentDir)
  # Append rather than replace: a second run the same day must not destroy
  # what the first one archived.
  let existing = if fileExists(dest): readFile(dest) else: ""
  let separator = if existing.len > 0 and not existing.endsWith("\n\n"):
                    (if existing.endsWith("\n"): "\n" else: "\n\n")
                  else: ""
  writeFile(dest, existing & separator & harvest.extracted)
  writeFile(live, harvest.remaining)
  success("harvested " & $harvest.count & " item(s) from " &
          DetailsDir / relative)

proc harvestDetailFiles*(root: string, today: DateTime, plan: Plan) =
  ## Walks `details/` and moves completed work into `archives/details/`.
  let details = root / DetailsDir
  if not dirExists(details):
    return
  let stamp = today.format("yyyyMMdd")
  var relatives: seq[string]
  for path in walkDirRec(details, relative = true):
    if path.toLowerAscii.endsWith(".md") and fileExists(details / path):
      relatives.add(path)
  # Deterministic order so a run's output is reproducible.
  relatives.sort()
  for relative in relatives:
    harvestDetailFile(root, relative, stamp, plan)

proc runArchive*(root: string, today: DateTime, plan: Plan) =
  archiveTodoFiles(root, today, plan)
  harvestDetailFiles(root, today, plan)
