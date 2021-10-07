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

when defined(windows) and not (defined(gcArc) or defined(gcOrc)):
  proc error*[T, E](self: Result[T, E]): E =
    ## Retrieve the error from a Result; raises ResultError
    ## if the Result is not in error.
    if self.isOk:
      raise ResultError[void](msg: "Result does not contain an error")
    else:
      result = self.e

  proc unsafeGet*[T, E](self: var Result[T, E]): var T =
    ## Fetch value of result if set, undefined behavior if unset
    ## See also: Option.unsafeGet
    assert not isErr(self)
    result = self.v

  proc unsafeGet*[T, E](self: Result[T, E]): T =
    ## Fetch value of result if set, undefined behavior if unset
    ## See also: Option.unsafeGet
    assert not isErr(self)
    result = self.v

  proc unsafeGet*[E](self: Result[void, E]) =
    ## Raise an exception if Result is an error.
    ## See also: Option.unsafeGet
    assert not self.isErr
else:
  proc error*[T, E](self: Result[T, E]): E {.inline.} =
    ## Retrieve the error from a Result; raises ResultError
    ## if the Result is not in error.
    if self.isOk:
      raise ResultError[void](msg: "Result does not contain an error")
    else:
      result = self.e

  proc unsafeGet*[T, E](self: var Result[T, E]): var T {.inline.} =
    ## Fetch value of result if set, undefined behavior if unset
    ## See also: Option.unsafeGet
    assert not isErr(self)
    result = self.v

  proc unsafeGet*[T, E](self: Result[T, E]): T {.inline.} =
    ## Fetch value of result if set, undefined behavior if unset
    ## See also: Option.unsafeGet
    assert not isErr(self)
    result = self.v

  proc unsafeGet*[E](self: Result[void, E]) {.inline.} =
    ## Raise an exception if Result is an error.
    ## See also: Option.unsafeGet
    assert not self.isErr

func newResultError[E](e: E; s: string): ResultError[E] {.inline, nimcall.} =
  ## capturing ResultError...
  ResultError[E](error: e, msg: s)

template toException*[E](err: E): ResultError[E] =
  mixin `$`
  when compiles($err):
    newResultError(err, "Result isErr: " & $err)
  else:
    newResultError(err, "Result isErr; no `$` in scope.")

template raiseResultError[T, E](self: Result[T, E]) =
  mixin toException
  when E is ref Exception:
    if self.error.isNil: # for example Result.default()!
      raise ResultError[void](msg: "Result isErr; no exception.")
    else:
      raise self.error
  else:
    raise self.error.toException

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

template get*[T: not void, E](self: Result[T, E]): untyped =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    raiseResultError self
  unsafeGet self

template get*[T, E](self: Result[T, E]; otherwise: T): untyped =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    otherwise
  else:
    unsafeGet self

template get*[T, E](self: var Result[T, E]): untyped =
  ## Fetch mutable value of result if set, or raise error as an Exception
  ## See also: Option.get
  if self.isErr:
    raiseResultError self
  unsafeGet self

template get*[E](self: Result[void, E]) =
  ## Raise error as an Exception if `self.isErr`.
  ## See also: Option.get
  if self.isErr:
    raiseResultError self

proc `$`*[T: not void; E](self: Result[T, E]): string =
  ## Returns string representation of `self`
  if self.isOk: "Ok(" & $self.v & ")"
  else: "Err(" & $self.e & ")"

func `$`*[E](self: Result[void, E]): string =
  ## Returns string representation of `self`
  if self.isOk: "Ok()"
  else: "Err(" & $self.e & ")"

template value*[T, E](self: Result[T, E]): T = get self
template value*[T, E](self: var Result[T, E]): T = get self

template value*[E](self: Result[void, E]) = get self
template value*[E](self: var Result[void, E]) = get self

template valueOr*[T, E](self: Result[T, E], def: T): T =
  ## Fetch value of result if set, or supplied default
  ## default will not be evaluated iff value is set
  self.get(def)
