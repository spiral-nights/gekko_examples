import gleam/float
import gleam/int
import gleam/io

pub const nominal_altitude_km: Int = 408

pub const gravity_mps2: Float = 9.80665

pub fn run() -> Nil {
  io.println("[Station Telemetry]")

  // Integer arithmetic, remainder, and comparisons
  let orbit_period_min = 92
  let orbits_per_day = 1440 / orbit_period_min
  let leftover_min = 1440 % orbit_period_min
  assert orbits_per_day == 15
  assert leftover_min == 60
  assert nominal_altitude_km > 400 && nominal_altitude_km <= 420

  // Float arithmetic and comparisons
  let hull_temp_c = 18.5
  let delta_temp = -3.25
  let adjusted_temp = hull_temp_c +. delta_temp
  assert adjusted_temp == 15.25
  assert gravity_mps2 >. 9.8 && gravity_mps2 <. 9.9

  // Booleans and short-circuiting
  let solar_online = True
  let battery_low = False
  assert { solar_online && !battery_low } == True
  assert { battery_low || solar_online } == True

  // Strings, escapes, and block expressions
  let station_callsign = "ISS-KIBO"
  let banner = {
    let prefix = "Station: "
    prefix <> station_callsign <> " \"Nominal\""
  }
  assert banner == "Station: ISS-KIBO \"Nominal\""

  // Shadowing and tuples
  let reading = 10
  let reading = reading * 3
  assert reading == 30

  let coords = #(408.5, -23.1, 7.66)
  let #(alt, lat, vel) = coords
  assert alt >. 408.0 && lat <. 0.0 && vel >. 7.0

  io.println(
    "orbits="
    <> int.to_string(orbits_per_day)
    <> " temp="
    <> float.to_string(adjusted_temp),
  )
}
