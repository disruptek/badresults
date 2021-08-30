version = "1.0.1"
author = "disruptek"
description = "a simpler and less fascist fork of nim-result"
license = "MIT"

when not defined(release):
  requires "https://github.com/disruptek/balls >= 2.0.0 & < 4.0.0"

task test, "run tests for ci":
  when defined(windows):
    exec "balls.cmd"
  else:
    exec "balls"
