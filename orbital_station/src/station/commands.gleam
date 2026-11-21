import gleam/int
import gleam/io

fn apply_thrust(base: Int, multiplier factor: Int) -> Int {
  base * factor
}

fn transform_reading(value: a, mapper: fn(a) -> b) -> b {
  mapper(value)
}

fn with_airlock_seal(
  chamber: String,
  action: fn(String) -> Result(String, String),
) -> Result(String, String) {
  case chamber {
    "" -> Error("empty chamber")
    name -> action("sealed:" <> name)
  }
}

pub fn run() -> Nil {
  io.println("[Station Commands]")

  // Labelled arguments
  let impulse = apply_thrust(12, multiplier: 4)
  assert impulse == 48

  // Anonymous functions and function captures
  let boost = fn(n) { n + 15 }
  let scale = apply_thrust(_, multiplier: 3)
  assert boost(10) == 25
  assert scale(7) == 21

  // Generics and pipelines
  let formatted =
    5
    |> transform_reading(fn(x) { x * 10 })
    |> boost
    |> int.to_string
  assert formatted == "65"

  // `use` expression for callback-style control flow
  let seal_result = {
    use sealed_name <- with_airlock_seal("Node-2")
    Ok(sealed_name <> "->ready")
  }
  assert seal_result == Ok("sealed:Node-2->ready")

  io.println("impulse=" <> int.to_string(impulse) <> " pipe=" <> formatted)
}
