## todo -- daily TODO file manager.
##
## Replaces the Bash todo() function that used to live in
## bash/.config/bash/functions.sh. Behaviour of that function is preserved:
##
##   * work in ~/lab/temp/todos, creating it if needed
##   * today's file is TODO.YYYYMMDD.md
##   * if it exists, open it and stop
##   * otherwise seed it from yesterday's file, else the most recent
##     TODO.*.md, else create it empty
##   * open the result in nvim
##
## New: old TODO files are archived and completed detail-file work is
## harvested into archives/ before the editor opens. See README.md.

import std/[os, osproc, parseopt, strutils, times]
import todopkg/[archive, log, tree]

const
  Version = "1.0.0"
  DefaultRoot = "lab/temp/todos"
  Editor = "nvim"
  Usage = """
todo -- daily TODO file manager

Usage:
  todo [options]

Options:
  --dir <path>       todos directory (default: ~/""" & DefaultRoot & """)
  --today <YYYYMMDD> override today's date
  --no-archive       skip archiving and harvesting
  --no-edit          do not launch the editor
  --dry-run          report what would happen; writes nothing, opens nothing
  -h, --help         show this help
  -v, --version      show the version
"""

type Options = object
  root: string
  today: DateTime
  archive: bool
  edit: bool
  dryRun: bool

proc todoName(date: DateTime): string =
  "TODO." & date.format("yyyyMMdd") & ".md"

proc parseOptions(): Options =
  result = Options(
    root: getHomeDir() / DefaultRoot,
    today: now(),
    archive: true,
    edit: true,
    dryRun: false,
  )
  # parseopt only binds `--opt=value` unless it is told which options take a
  # value; everything listed in longNoVal/shortNoVal is a flag, the rest
  # consume the following token. Without this `--dir path` parses as a
  # valueless --dir plus a stray argument.
  var parser = initOptParser(
    commandLineParams(),
    shortNoVal = {'h', 'v'},
    longNoVal = @["help", "version", "no-archive", "no-edit", "dry-run"],
  )
  while true:
    parser.next()
    case parser.kind
    of cmdEnd:
      break
    of cmdArgument:
      raise newException(ValueError, "unexpected argument: " & parser.key)
    of cmdShortOption, cmdLongOption:
      case parser.key
      of "h", "help":
        echo Usage
        quit(0)
      of "v", "version":
        echo "todo " & Version
        quit(0)
      of "dir":
        if parser.val.len == 0:
          raise newException(ValueError, "--dir requires a path")
        # Absolute, because run() chdir's into this directory: a relative
        # --dir would invalidate every path built from it.
        result.root = absolutePath(expandTilde(parser.val))
      of "today":
        try:
          result.today = parse(parser.val, "yyyyMMdd", local())
        except TimeParseError:
          raise newException(ValueError, "--today expects YYYYMMDD, got: " &
                             parser.val)
      of "no-archive":
        result.archive = false
      of "no-edit":
        result.edit = false
      of "dry-run":
        result.dryRun = true
      else:
        raise newException(ValueError, "unknown option: " & parser.key)

proc latestTodoBefore(root: string, today: DateTime): string =
  ## The most recent TODO.YYYYMMDD.md strictly older than today, by date
  ## rather than by mtime. The Bash version used `ls -t`, which sorts by
  ## mtime and so reshuffles whenever an old file is merely touched; sorting
  ## on the filename date is the same answer in the normal case and a
  ## deterministic one in every case.
  var best = ""
  var bestStamp = ""
  let todayStamp = today.format("yyyyMMdd")
  for kind, path in walkDir(root, relative = true):
    if kind != pcFile or not (path.startsWith("TODO.") and path.endsWith(".md")):
      continue
    let stamp = path[5 ..< path.len - 3]
    if stamp.len != 8 or not stamp.allCharsInSet({'0' .. '9'}):
      continue
    if stamp >= todayStamp:
      continue
    if stamp > bestStamp:
      bestStamp = stamp
      best = path
  best

proc seedToday(root: string, today: DateTime, todayPath: string,
               dryRun: bool) =
  ## Creates today's file from the best available source.
  let yesterday = todoName(today - 1.days)
  var source = ""
  if fileExists(root / yesterday):
    source = yesterday
  else:
    source = latestTodoBefore(root, today)

  if source.len == 0:
    if dryRun:
      info("would create an empty " & todayPath.extractFilename &
           " (no TODO files found)")
      return
    info("No TODO files found. Creating an empty TODO file.")
    writeFile(todayPath, "")
    return

  info("found " & source)
  # The tree extractor, not clean(): today's file is the previous day with
  # every completed task, its subtree, and every section left empty by that
  # removal taken out.
  let original = readFile(root / source)
  let seeded = extract(original)

  # Nothing was completed, so today's file would be a byte-for-byte copy of the
  # source: this is the same list continuing, not a new day. Rename it instead,
  # or a quiet week leaves seven identical files behind.
  if seeded.count == 0:
    if dryRun:
      info("would carry " & source & " forward as " &
           todayPath.extractFilename & " (nothing completed)")
      return
    info("nothing completed; carrying " & source & " forward")
    moveFile(root / source, todayPath)
    # extract() also trims trailing blank lines, so the render can differ from
    # the source even when it removed no task.
    if seeded.remaining != original:
      writeFile(todayPath, seeded.remaining)
    return

  if dryRun:
    info("would create " & todayPath.extractFilename & " from " & source &
         ", dropping " & $seeded.count & " completed item(s)")
    return
  writeFile(todayPath, seeded.remaining)

proc run(opts: Options): int =
  # --dry-run must not write anything at all, the todos directory included.
  if opts.dryRun and not dirExists(opts.root):
    info("would create " & opts.root)
    return 0
  if not opts.dryRun:
    createDir(opts.root)
  # The old Bash implementation cd'd here first, so the editor opened with the
  # todos directory as its working directory -- which is what makes `:e
  # details/...` and fuzzy-finding inside nvim work. Do it before anything
  # else; every path below is absolute, so nothing depends on the old cwd.
  setCurrentDir(opts.root)
  let todayPath = opts.root / todoName(opts.today)
  let existed = fileExists(todayPath)

  if existed:
    info("Today's TODO file already exists.")
  else:
    seedToday(opts.root, opts.today, todayPath, opts.dryRun)

  if opts.archive:
    runArchive(opts.root, opts.today, Plan(dryRun: opts.dryRun))

  if not opts.edit or opts.dryRun:
    return 0
  if findExe(Editor).len == 0:
    error(Editor & " not found on PATH")
    return 1
  execCmd(Editor & " " & quoteShell(todayPath))

when isMainModule:
  var opts: Options
  try:
    opts = parseOptions()
  except ValueError as e:
    error(e.msg)
    echo Usage
    quit(2)
  try:
    quit(run(opts))
  except OSError, IOError:
    error(getCurrentExceptionMsg())
    quit(1)
