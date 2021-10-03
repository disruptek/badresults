import std/macros

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

func newResultError[E](e: E; s: string): ResultError[E] {.inline, nimcall.} =
  ## capturing ResultError...
  ResultError[E](error: e, msg: s)

macro toException*[E](err: E): ResultError[E] =
  err.expectKind nnkCheckedFieldExpr
  # err is `self.e`, a checked field expr
  let e = err[0]              # unwrap checked-field to get dot expr
  let re = bindSym"newResultError"
  quote:
    when compiles($`e`):
      `re`(`e`, "Result isErr: " & $`e`)
    else:
      `re`(`e`, "Result isErr; no `$` in scope.")

macro raiseResultError[T, E](self: Result[T, E]): untyped =
  quote:
    when `E` is ref Exception:
      if `self`.e.isNil: # for example Result.default()!
        raise ResultError[void](msg: "Result isErr; no exception.")
      else:
        raise `self`.e
    else:
      raise `self`.e.toException

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

macro get*[T: not void, E](self: Result[T, E]): T =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  quote:
    if `self`.isErr:
      raiseResultError `self`
    else:
      `self`.v

macro get*[T, E](self: Result[T, E]; otherwise: T): T =
  ## Fetch value of result if set, or raise error as an Exception
  ## See also: Option.get
  quote:
    if `self`.isErr:
      `otherwise`
    else:
      `self`.v

macro get*[T, E](self: var Result[T, E]): untyped =
  ## Fetch mutable value of result if set, or raise error as an Exception
  ## See also: Option.get
  quote:
    var r: typeOf(`self`.v)
    if `self`.isErr:
      raiseResultError `self`
    else:
      r = `self`.v
    r

macro get*[E](self: Result[void, E]) =
  ## Raise error as an Exception if `self.isErr`.
  ## See also: Option.get
  quote:
    if `self`.isErr:
      raiseResultError `self`

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
