version = "1.0.0"
author = "disruptek"
description = "a less fascist version of nim-result"
license = "MIT"
requires "nim >= 1.0.6"

proc execCmd(cmd: string) =
  echo "exec:" & cmd
  try:
    exec cmd
  except OSError:
    echo "test `", cmd, "` failed."
    quit 1

proc execTest(test: string) =
  execCmd "nim c                 -r " & test
  execCmd "nim c      -d:release -r " & test
  execCmd "nim c       -d:danger -r " & test
  execCmd "nim cpp     -d:danger -r " & test
  when (NimMajor, NimMinor) >= (1, 2):
    execCmd "nim c   --gc:arc -r " & test
    execCmd "nim cpp --gc:arc -r " & test

task test, "run tests for travis":
  execTest("badresults.nim")
