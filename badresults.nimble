version = "1.0.0"
author = "disruptek"
description = "like results but worse"
license = "MIT"
requires "nim >= 1.0.6"

proc execCmd(cmd: string) =
  echo "execCmd:" & cmd
  exec cmd

proc execTest(test: string) =
  execCmd "nim c -f              -r " & test
  execCmd "nim c      -d:release -r " & test
  execCmd "nim c       -d:danger -r " & test
  execCmd "nim cpp -f            -r " & test
  execCmd "nim cpp     -d:danger -r " & test
  when NimMajor >= 1 and NimMinor >= 1:
    execCmd "nim c   -f --gc:arc -r " & test
    execCmd "nim cpp -f --gc:arc -r " & test

task test, "run tests for travis":
  execTest("badresults.nim")
