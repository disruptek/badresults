# badresults
[![Test Matrix](https://github.com/disruptek/badresults/workflows/CI/badge.svg)](https://github.com/disruptek/badresults/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/badresults?style=flat)](https://github.com/disruptek/badresults/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.0.8%2B-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/badresults?style=flat)](#license)
[![buy me a coffee](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/disruptek)

This is a copy of [the Status nim-result
package](https://github.com/arnetheduck/nim-result) that differs only in that
you do not need to provide a side-effect-free (`func`) implementation of `$`
for all types used as results.

## Documentation
See [the documentation for the badresults module](https://disruptek.github.io/badresults/badresults.html) as generated directly from the source.

Here's the type we provide:
```nim
Result[T; E] = object
  case o: bool
  of false:
      e: E

  of true:
      v: T
```

## Usage

This example is from the documentation:

```nim
# It's convenient to create an alias - most likely, you'll do just fine
# with strings as error!

type R = Result[int, string]

# Once you have a type, use `ok` and `err`:

func works(): R =
  # ok says it went... ok!
  R.ok 42
func fails(): R =
  # or type it like this, to not repeat the type!
  result.err "bad luck"

if (let w = works(); w.isOk):
  echo w[], " or use value: ", w.value

# In case you think your callers want to differentiate between errors:
type
  Error = enum
    a, b, c
  type RE[T] = Result[T, Error]

# In the expriments corner, you'll find the following syntax for passing
# errors up the stack:
func f(): R =
  let x = ?works() - ?fails()
  assert false, "will never reach"

# If you provide this exception converter, this exception will be raised
# on dereference
func toException(v: Error): ref CatchableException = (ref CatchableException)(msg: $v)
try:
  RE[int].err(a)[]
except CatchableException:
  echo "in here!"
```

## Installation

```
$ nimph clone badresults
```
or if you're still using Nimble like it's 2012,
```
$ nimble install https://github.com/disruptek/badresults
```


## License
MIT
