## Console messages in the same shape as scripts/.local/bin/log-message.sh
## so the Nim binary is visually indistinguishable from the rest of the
## dotfiles tooling.
##
## That script pads the uppercased "TYPE:" label to 8 columns and follows it
## with three spaces: printf "%-8s   %s\n". The width 8 is what its
## get_max_type_width() computes (longest label WARNING/SUCCESS = 7, +1).

import std/[strutils, terminal]

type Level* = enum
  lvlInfo = "INFO"
  lvlWarning = "WARNING"
  lvlError = "ERROR"
  lvlSuccess = "SUCCESS"

const
  LabelWidth = 8
  Reset = "\e[0m"

func color(level: Level): string =
  case level
  of lvlInfo: "\e[0;34m"
  of lvlWarning: "\e[0;33m"
  of lvlError: "\e[0;31m"
  of lvlSuccess: "\e[0;32m"

proc emit(f: File, level: Level, message: string) =
  let label = alignLeft($level & ":", LabelWidth)
  if isatty(f):
    f.writeLine(level.color & label & Reset & "   " & message)
  else:
    f.writeLine(label & "   " & message)
  f.flushFile()

proc info*(message: string) = emit(stdout, lvlInfo, message)
proc warn*(message: string) = emit(stdout, lvlWarning, message)
proc success*(message: string) = emit(stdout, lvlSuccess, message)
proc error*(message: string) = emit(stderr, lvlError, message)
