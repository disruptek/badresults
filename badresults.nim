# Copyright (c) 2019 Jacek Sieka
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

type
  ResultError*[E] = ref object of ValueError
    error: E

  Result*[T, E] = object
    ## For documentation, refer to the original nim-results package,
    ## or this source code.  I'm deleting the original documentation
    ## from here as it's either annoying or incorrect.

    case o: bool
    of false:
      e: E
    of true:
      v: T

func raiseResultError[T, E](self: Result[T, E]) {.noreturn.} =
  when E is ref Exception:
    if self.e.isNil: # for example Result.default()!
      raise ResultError[void](msg: "Trying to access value with err (nil)")
    raise self.e
  elif compiles(self.e.toException()):
    raise self.e.toException()
  elif compiles($self.e):
    raise ResultError[E](
      error: self.e, msg: "Trying to access value with err: " & $self.e)
  else:
    raise ResultError[E](error: self.e)

proc ok*[E](R: typedesc[Result[void, E]]): Result[void, E] =
  ## Return a result as success.
  R(o: true)

proc ok*[E](self: var Result[void, E]) =
  ## Set a result to success.
  ## Example: `result.ok(42)`
  self = ok[E](typeOf(self))

proc ok*[T, E](R: typedesc[Result[T, E]]; v: T): Result[T, E] =
  ## Return a result with a success and value.
  ## Example: `Result[int, string].ok(42)`
  R(o: true, v: v)

proc ok*[T, E](self: var Result[T, E]; v: T) =
  ## Set the result to success and update value.
  ## Example: `result.ok(42)`
  self = ok[T, E](typeOf(self), v)

proc err*[T, E](R: typedesc[Result[T, E]]; e: E): Result[T, E] =
  ## Return a result with an error.
  ## Example: `Result[int, string].err("uh-oh")`
  R(o: false, e: e)

proc err*[T, E](self: var Result[T, E]; e: E) =
  ## Set the result as an error.
  ## Example: `result.err("uh-oh")`
  self = err[T, E](typeOf(self), e)

proc isOk*(self: Result): bool = self.o
proc isErr*(self: Result): bool = not self.o

func `==`*(a, b: Result): bool {.inline.} =
  if a.isOk == b.isOk:
    if a.isOk: a.v == b.v
    else:      a.e == b.e
  else:
    false

func get*[T: not void, E](self: Result[T, E]): T {.inline.} =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    self.raiseResultError()
  else:
    self.v

func get*[T, E](self: Result[T, E], otherwise: T): T {.inline.} =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    otherwise
  else:
    self.v

func get*[T, E](self: var Result[T, E]): var T {.inline.} =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    self.raiseResultError()
  else:
    result = self.v

func get*[E](self: Result[void, E]) {.inline.} =
  ## Raise error as an Exception if `self.isErr`.
  ## See also: Option.get
  if self.isErr:
    self.raiseResultError()

func error*[T, E](self: Result[T, E]): E =
  if self.isOk:
    raise ResultError[void](msg: "Result does not contain an error")
  else:
    result = self.e

template valueOr*[T, E](self: Result[T, E], def: T): T =
  ## Fetch value of result if set, or supplied default
  ## default will not be evaluated iff value is set
  self.get(def)

template unsafeGet*[T, E](self: Result[T, E]): T =
  ## Fetch value of result if set, undefined behavior if unset
  ## See also: Option.unsafeGet
  assert not isErr(self)
  self.v

template unsafeGet*[E](self: Result[void, E]) =
  ## Fetch value of result if set, undefined behavior if unset
  ## See also: Option.unsafeGet
  assert not self.isErr

proc `$`*[T, E](self: Result[T, E]): string =
  ## Returns string representation of `self`
  if self.isOk: "Ok(" & $self.v & ")"
  else: "Err(" & $self.e & ")"

func `$`*[E](self: Result[void, E]): string =
  ## Returns string representation of `self`
  if self.isOk: "Ok()"
  else: "Err(" & $self.e & ")"

template value*[T, E](self: Result[T, E]): T = self.get()
template value*[T, E](self: var Result[T, E]): T = self.get()

template value*[E](self: Result[void, E]) = self.get()
template value*[E](self: var Result[void, E]) = self.get()

when isMainModule:
  type R = Result[int, string]

  # Basic usage, producer
  func works(): R = R.ok(42)
  func works2(): R = result.ok(42)
  func fails(): R = R.err("dummy")
  func fails2(): R = result.err("dummy")

  # Basic usage, consumer
  let
    rOk = works()
    rOk2 = works2()
    rErr = fails()
    rErr2 = fails2()

  doAssert rOk.isOk
  doAssert rOk2.isOk
  doAssert rOk.get() == 42
  doAssert (not rOk.isErr)
  doAssert rErr.isErr
  doAssert rErr2.isErr

  # Exception on access
  let va = try: discard rOk.error; false except: true
  doAssert va, "not an error, should raise"

  # Exception on access
  let vb = try: discard rErr.value; false except: true
  doAssert vb, "not an value, should raise"

  var x = rOk

  # Mutate
  x.err("failed now")

  doAssert x.isErr

  doAssert rOk.valueOr(50) == rOk.value
  doAssert rErr.valueOr(50) == 50

  # Comparisons
  doAssert (works() == works2())
  doAssert (fails() == fails2())
  doAssert (works() != fails())

  # It's also possible to use the same trick for stack capture:
  template capture*(): untyped =
    type R = type(result)

    var ret: R
    try:
      # TODO is this needed? I think so, in order to grab a call stack, but
      #      haven't actually tested...
      if true:
        # I'm sure there's a nicer way - this just works :)
        raise newException(Exception, "")
    except:
      ret = R.err(getCurrentException())
    ret

  proc testCapture(): Result[int, ref Exception] =
    return capture()

  doAssert testCapture().isErr

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

  doAssert testToException() == 42

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

  doAssert testToString() == 42

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

  doAssert vOk.isOk
  doAssert vOk2.isOk
  doAssert vErr.isErr
  doAssert vErr2.isErr

  vOk.get()
