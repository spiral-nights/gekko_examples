import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string

/// @external_type(moonbit, "text_ffi", "Counter")
pub type Counter

pub type NamedCounter {
  NamedCounter(name: String, counter: Counter)
}

/// @external(moonbit, "text_ffi", "new_counter")
pub fn new_counter(start: Int) -> Counter {
  let _ = start
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "text_ffi", "increment_counter")
pub fn increment_counter(c: Counter, delta: Int) -> Nil {
  let _ = c
  let _ = delta
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "text_ffi", "read_counter")
pub fn read_counter(c: Counter) -> Int {
  let _ = c
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "text_ffi", "shout")
pub fn shout(s: String) -> String {
  let _ = s
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "text_ffi", "upper_all")
pub fn upper_all(xs: List(String)) -> List(String) {
  let _ = xs
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "text_ffi", "sum_squares")
pub fn sum_squares(xs: List(Int)) -> Int {
  let _ = xs
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "byte_ffi", "repeat_utf8_byte_size")
pub fn repeat_utf8_byte_size(s: String, times: Int) -> Int {
  let _ = s
  let _ = times
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "moonbitlang/core/math", "sin")
pub fn math_sin(x: Float) -> Float {
  let _ = x
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "moonbitlang/core/math", "cos")
pub fn math_cos(x: Float) -> Float {
  let _ = x
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "moonbitlang/core/math", "pow")
pub fn math_pow(base: Float, exp: Float) -> Float {
  let _ = base
  let _ = exp
  panic as "Implemented in MoonBit"
}

pub fn main() -> Nil {
  let greeting = shout("hello moonbit")
  assert greeting == "HELLO MOONBIT!"

  let words = upper_all(["gleam", "ffi"])
  assert words == ["GLEAM", "FFI"]

  let sq_sum = sum_squares([2, 3, 4])
  assert sq_sum == 29

  let utf8_bytes = repeat_utf8_byte_size("🌙", 3)
  assert utf8_bytes == 12

  let p = math_pow(2.0, 10.0)
  assert p == 1024.0

  let s0 = math_sin(0.0)
  let c0 = math_cos(0.0)
  assert s0 == 0.0
  assert c0 == 1.0

  let c1 = new_counter(10)
  let c2 = new_counter(100)
  increment_counter(c1, 5)
  let named = NamedCounter(name: "hits", counter: c1)
  let counters = [named.counter, c2]
  let counter_total =
    list.fold(counters, 0, fn(acc, c) { acc + read_counter(c) })
  assert counter_total == 115

  io.println("shout=" <> greeting)
  io.println("upper=" <> string.join(words, ","))
  io.println("sum_squares=" <> int.to_string(sq_sum))
  io.println("utf8_bytes=" <> int.to_string(utf8_bytes))
  io.println("pow=" <> float.to_string(p))
  io.println("sin0=" <> float.to_string(s0) <> ",cos0=" <> float.to_string(c0))
  io.println("counter_total=" <> int.to_string(counter_total))
}
