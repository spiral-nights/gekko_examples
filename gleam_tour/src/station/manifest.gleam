import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type ModuleStatus {
  Operational
  Degraded(reason: String, power_pct: Int)
  Offline
}

pub type Thruster {
  Thruster(id: String, fuel_kg: Int, active: Bool)
}

pub opaque type DockingCode {
  DockingCode(code: String)
}

pub fn make_docking_code(raw: String) -> Result(DockingCode, String) {
  case string.length(raw) >= 4 {
    True -> Ok(DockingCode(raw))
    False -> Error("docking code too short")
  }
}

pub fn read_docking_code(dc: DockingCode) -> String {
  dc.code
}

fn describe_status(status: ModuleStatus) -> String {
  case status {
    Operational -> "operational"
    Degraded(reason:, power_pct:) ->
      "degraded:" <> reason <> "@" <> int.to_string(power_pct) <> "%"
    Offline -> "offline"
  }
}

pub fn run() -> Nil {
  io.println("[Station Manifest]")

  // Multi-variant custom type
  assert describe_status(Operational) == "operational"
  assert describe_status(Degraded(reason: "coolant", power_pct: 65))
    == "degraded:coolant@65%"
  assert describe_status(Offline) == "offline"

  // Record creation, uniform field accessors, and immutable record updates
  let main_thruster = Thruster(id: "RCS-1", fuel_kg: 120, active: True)
  let updated_thruster = Thruster(..main_thruster, fuel_kg: 95)
  assert main_thruster.fuel_kg == 120
  assert updated_thruster.id == "RCS-1"
  assert updated_thruster.fuel_kg == 95
  assert updated_thruster.active == True

  // Opaque type smart constructor
  let assert Ok(dock) = make_docking_code("PORT-A")
  assert read_docking_code(dock) == "PORT-A"
  assert make_docking_code("AB") == Error("docking code too short")

  // Stdlib: List, Dict, Option, inspect, and echo
  let bays = [2, 4, 6]
  let doubled = list.map(bays, fn(n) { n * 2 })
  assert doubled == [4, 8, 12]

  let crew_counts = dict.from_list([#("alpha", 3), #("beta", 2)])
  let alpha_opt: Option(Int) = case dict.get(crew_counts, "alpha") {
    Ok(n) -> Some(n)
    Error(_) -> None
  }
  assert alpha_opt == Some(3)

  let inspected = string.inspect(Operational)
  assert inspected == "Operational"

  let _ = echo updated_thruster.fuel_kg
  io.println("dock=" <> read_docking_code(dock) <> " bays=3")
}
