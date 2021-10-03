import pkg/balls

import badresults

suite "badresults":
  type R = Result[int, string]

  ## Basic usage, producer
  func works(): R = R.ok(42)
  func works2(): R = result.ok(42)
  func fails(): R = R.err("dummy")
  func fails2(): R = result.err("dummy")

  ## Basic usage, consumer
  let
    rOk = works()
    rOk2 = works2()
    rErr = fails()
    rErr2 = fails2()

  block:
    ## Basic operations
    check "basically broken":
      rOk.isOk
      rOk2.isOk
      rOk.get() == 42
      (not rOk.isErr)
      rErr.isErr
      rErr2.isErr

  block:
    ## Exception on access (1)
    let va = try: discard rOk.error; false except: true
    check va, "not an error, should raise"

  block:
    ## Exception on access (2)
    let vb = try: discard rErr.value; false except: true
    check vb, "not an value, should raise"

  block:
    ## Mutate
    var x = rOk

    x.err("failed now")

    check x.isErr

    check rOk.valueOr(50) == rOk.value
    check rErr.valueOr(50) == 50

  block:
    ## Comparisons
    check (works() == works2())
    check (fails() == fails2())
    check (works() != fails())

  block:
    ## Custom exceptions
    type
      AnEnum = enum
        anEnumA
        anEnumB
      AnException = ref object of ValueError
        v: AnEnum

    func toException(v: AnEnum): AnException = AnException(v: v)

    func testToException(): int =
      try:
        var r = Result[int, AnEnum].err(anEnumA)
        get r
      except AnException:
        42

    check testToException() == 42

  block:
    ## Adhoc string rendering of exception
    type
      AnEnum2 = enum
        anEnum2A
        anEnum2B

    func testToString(): int =
      try:
        var r = Result[int, AnEnum2].err(anEnum2A)
        get r
      except ResultError[AnEnum2]:
        42

    check testToString() == 42

  block:
    ## Dollar-based string rendering of an error
    type
      AnEnum3 = enum
        anEnum3A
        anEnum3B

    func `$`(e: AnEnum3): string =
      case e
      of anEnum3A: "first"
      of anEnum3B: "second"

    proc testToString2(): int =
      try:
        var r = Result[int, AnEnum3].err(anEnum3B)
        get r
      except ResultError[AnEnum3] as e:
        check e.msg == "Result isErr: second"
        42

    check testToString2() == 42

  block:
    ## Void Results
    type VoidRes = Result[void, int]

    func worksVoid(): VoidRes = VoidRes.ok()
    func worksVoid2(): VoidRes = result.ok()
    func failsVoid(): VoidRes = VoidRes.err(42)
    func failsVoid2(): VoidRes = result.err(42)

    let
      vOk = worksVoid()
      vOk2 = worksVoid2()
      vErr = failsVoid()
      vErr2 = failsVoid2()

    check vOk.isOk
    check vOk2.isOk
    check vErr.isErr
    check vErr2.isErr

    vOk.get()
