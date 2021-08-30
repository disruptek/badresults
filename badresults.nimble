version = "2.0.0"
author = "disruptek"
description = "a simpler and less fascist fork of nim-result"
license = "MIT"

task test, "run tests for ci":
  when defined(windows):
    # https://github.com/nim-lang/Nim/issues/16661
    # see if this works... maybe
    block found:
      for n in ["balls.cmd", "balls.exe", "balls"]:
        if n.findExe != "":
          exec n.findExe
          break found
      echo "looked for balls.cmd, balls.exe, balls.  found nothing."
      quit 1
  else:
    exec findExe"balls"
