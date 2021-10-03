import badresults

import balls

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

  check rOk.isOk
  check rOk2.isOk
  check rOk.get() == 42
  check (not rOk.isErr)
  check rErr.isErr
  check rErr2.isErr

  ## Exception on access
  let va = try: discard rOk.error; false except: true
  check va, "not an error, should raise"

  ## Exception on access
  let vb = try: discard rErr.value; false except: true
  check vb, "not an value, should raise"

  var x = rOk

  ## Mutate
  x.err("failed now")

  check x.isErr

  check rOk.valueOr(50) == rOk.value
  check rErr.valueOr(50) == 50

  ## Comparisons
  check (works() == works2())
  check (fails() == fails2())
  check (works() != fails())

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

  ## ResultError
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
