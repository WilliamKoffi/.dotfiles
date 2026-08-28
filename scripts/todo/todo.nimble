version       = "1.0.0"
author        = "llyam"
description   = "Daily TODO file manager with archiving and harvesting"
license       = "MIT"
srcDir        = "src"
bin           = @["todo"]

requires "nim >= 2.0.0"

task test, "Run the test suite":
  exec "nim c -r --hints:off --outdir:" & getEnv("TMPDIR", "/tmp") &
       "/todo-tests tests/test_clean.nim"
