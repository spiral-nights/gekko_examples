import gleam/int
import gleam/io

fn classify_altitude(alt_km: Int) -> String {
  case alt_km {
    0 -> "landed"
    km if km < 160 -> "reentry"
    km if km <= 450 -> "leo"
    _ -> "high-orbit"
  }
}

fn route_packet(header: #(String, Int)) -> String {
  case header {
    #("SOS", code) -> "priority-" <> int.to_string(code)
    #("PING", _) -> "ack"
    #(kind, _) -> "unknown-" <> kind
  }
}

fn burn_fuel(fuel: Int, steps: Int, acc: Int) -> Int {
  case steps <= 0 || fuel <= 0 {
    True -> acc
    False -> burn_fuel(fuel - 5, steps - 1, acc + 5)
  }
}

fn count_active(flags: List(Bool), total: Int) -> Int {
  case flags {
    [] -> total
    [True, ..rest] -> count_active(rest, total + 1)
    [False, ..rest] -> count_active(rest, total)
  }
}

pub fn run() -> Nil {
  io.println("[Station Navigation]")

  assert classify_altitude(0) == "landed"
  assert classify_altitude(120) == "reentry"
  assert classify_altitude(408) == "leo"
  assert classify_altitude(900) == "high-orbit"

  assert route_packet(#("SOS", 9)) == "priority-9"
  assert route_packet(#("PING", 1)) == "ack"
  assert route_packet(#("DATA", 3)) == "unknown-DATA"

  // Tail-recursive loops (lowered to MoonBit functional `for` loops)
  let burned = burn_fuel(30, 4, 0)
  assert burned == 20

  let active = count_active([True, False, True, True], 0)
  assert active == 3

  io.println(
    "burned=" <> int.to_string(burned) <> " active=" <> int.to_string(active),
  )
}
