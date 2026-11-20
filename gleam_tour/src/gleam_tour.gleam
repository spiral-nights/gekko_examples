import gleam/io
import station/commands
import station/manifest
import station/navigation
import station/telemetry

pub fn main() -> Nil {
  io.println("=== Orbital Station Simulator (gleam_tour) ===")
  telemetry.run()
  commands.run()
  navigation.run()
  manifest.run()
  io.println("=== All station checks passed ===")
}
