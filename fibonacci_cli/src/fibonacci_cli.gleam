import ffi/env
import gleam/int
import gleam/io
import gleam/list

pub fn fib(n: Int) -> Int {
  case n <= 0 {
    True -> 0
    False -> fib_loop(n, 0, 1)
  }
}

fn fib_loop(remaining: Int, a: Int, b: Int) -> Int {
  case remaining {
    0 -> a
    _ -> fib_loop(remaining - 1, b, a + b)
  }
}

pub fn parse_cli_numbers(raw_args: List(String)) -> List(Int) {
  case list.filter_map(raw_args, int.parse) {
    [] -> [10, 20]
    nums -> nums
  }
}

pub fn main() -> Nil {
  let numbers = parse_cli_numbers(env.args())
  list.each(numbers, fn(n) {
    io.println("fib(" <> int.to_string(n) <> ") = " <> int.to_string(fib(n)))
  })
}
