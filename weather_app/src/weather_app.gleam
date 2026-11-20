import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string

pub type Place {
  Place(
    place_name: String,
    state_abbr: String,
    latitude: String,
    longitude: String,
  )
}

pub type ZipLookup {
  ZipLookup(post_code: String, country: String, places: List(Place))
}

pub type CurrentUnits {
  CurrentUnits(
    temperature_2m: String,
    wind_speed_10m: String,
    relative_humidity_2m: String,
  )
}

pub type CurrentWeather {
  CurrentWeather(
    time: String,
    temperature_2m: Float,
    relative_humidity_2m: Int,
    wind_speed_10m: Float,
    weather_code: Int,
  )
}

pub type ForecastResponse {
  ForecastResponse(
    latitude: Float,
    longitude: Float,
    timezone: String,
    current_units: CurrentUnits,
    current: CurrentWeather,
  )
}

const zip_10001_json =
  "{\"country\": \"United States\", \"country abbreviation\": \"US\", \"post code\": \"10001\", \"places\": [{\"place name\": \"New York City\", \"longitude\": \"-73.9967\", \"latitude\": \"40.7484\", \"state\": \"New York\", \"state abbreviation\": \"NY\"}]}"

const forecast_10001_json =
  "{\"latitude\":40.736412,\"longitude\":-73.9841,\"generationtime_ms\":0.18608570098876953,\"utc_offset_seconds\":0,\"timezone\":\"GMT\",\"timezone_abbreviation\":\"GMT\",\"elevation\":17.0,\"current_units\":{\"time\":\"iso8601\",\"interval\":\"seconds\",\"temperature_2m\":\"°F\",\"relative_humidity_2m\":\"%\",\"wind_speed_10m\":\"mp/h\",\"weather_code\":\"wmo code\"},\"current\":{\"time\":\"2026-11-18T05:00\",\"interval\":900,\"temperature_2m\":43.0,\"relative_humidity_2m\":67,\"wind_speed_10m\":1.8,\"weather_code\":0}}"

const zip_90210_json =
  "{\"country\": \"United States\", \"country abbreviation\": \"US\", \"post code\": \"90210\", \"places\": [{\"place name\": \"Beverly Hills\", \"longitude\": \"-118.4065\", \"latitude\": \"34.0901\", \"state\": \"California\", \"state abbreviation\": \"CA\"}]}"

const forecast_90210_json =
  "{\"latitude\":34.082523,\"longitude\":-118.40714,\"generationtime_ms\":0.2535581588745117,\"utc_offset_seconds\":0,\"timezone\":\"GMT\",\"timezone_abbreviation\":\"GMT\",\"elevation\":168.0,\"current_units\":{\"time\":\"iso8601\",\"interval\":\"seconds\",\"temperature_2m\":\"°F\",\"relative_humidity_2m\":\"%\",\"wind_speed_10m\":\"mp/h\",\"weather_code\":\"wmo code\"},\"current\":{\"time\":\"2026-11-18T05:00\",\"interval\":900,\"temperature_2m\":57.9,\"relative_humidity_2m\":32,\"wind_speed_10m\":11.9,\"weather_code\":0}}"

fn number_as_float_decoder() -> Decoder(Float) {
  decode.one_of(decode.float, or: [decode.map(decode.int, int.to_float)])
}

fn place_decoder() -> Decoder(Place) {
  use place_name <- decode.field("place name", decode.string)
  use state_abbr <- decode.field("state abbreviation", decode.string)
  use latitude <- decode.field("latitude", decode.string)
  use longitude <- decode.field("longitude", decode.string)
  decode.success(Place(place_name:, state_abbr:, latitude:, longitude:))
}

fn zip_lookup_decoder() -> Decoder(ZipLookup) {
  use post_code <- decode.field("post code", decode.string)
  use country <- decode.field("country", decode.string)
  use places <- decode.field("places", decode.list(place_decoder()))
  decode.success(ZipLookup(post_code:, country:, places:))
}

fn current_units_decoder() -> Decoder(CurrentUnits) {
  use temperature_2m <- decode.field("temperature_2m", decode.string)
  use wind_speed_10m <- decode.field("wind_speed_10m", decode.string)
  use relative_humidity_2m <- decode.field(
    "relative_humidity_2m",
    decode.string,
  )
  decode.success(CurrentUnits(
    temperature_2m:,
    wind_speed_10m:,
    relative_humidity_2m:,
  ))
}

fn current_weather_decoder() -> Decoder(CurrentWeather) {
  use time <- decode.field("time", decode.string)
  use temperature_2m <- decode.field(
    "temperature_2m",
    number_as_float_decoder(),
  )
  use relative_humidity_2m <- decode.field("relative_humidity_2m", decode.int)
  use wind_speed_10m <- decode.field(
    "wind_speed_10m",
    number_as_float_decoder(),
  )
  use weather_code <- decode.field("weather_code", decode.int)
  decode.success(CurrentWeather(
    time:,
    temperature_2m:,
    relative_humidity_2m:,
    wind_speed_10m:,
    weather_code:,
  ))
}

fn forecast_response_decoder() -> Decoder(ForecastResponse) {
  use latitude <- decode.field("latitude", number_as_float_decoder())
  use longitude <- decode.field("longitude", number_as_float_decoder())
  use timezone <- decode.field("timezone", decode.string)
  use current_units <- decode.field("current_units", current_units_decoder())
  use current <- decode.field("current", current_weather_decoder())
  decode.success(ForecastResponse(
    latitude:,
    longitude:,
    timezone:,
    current_units:,
    current:,
  ))
}

pub fn parse_zip_lookup(raw: String) -> Result(ZipLookup, String) {
  json.parse(from: raw, using: zip_lookup_decoder())
  |> result.map_error(fn(_) { "Failed to decode zip lookup JSON" })
}

pub fn parse_forecast(raw: String) -> Result(ForecastResponse, String) {
  json.parse(from: raw, using: forecast_response_decoder())
  |> result.map_error(fn(_) { "Failed to decode weather forecast JSON" })
}

pub fn describe_wmo_code(code: Int) -> String {
  case code {
    0 -> "Clear sky"
    1 | 2 | 3 -> "Partly cloudy"
    45 | 48 -> "Fog"
    51 | 53 | 55 -> "Drizzle"
    61 | 63 | 65 -> "Rain"
    71 | 73 | 75 -> "Snow"
    80 | 81 | 82 -> "Showers"
    95 | 96 | 99 -> "Thunderstorm"
    _ -> "Code " <> int.to_string(code)
  }
}

pub fn format_weather_report(
  zip_json: String,
  forecast_json: String,
) -> Result(String, String) {
  use zip_info <- result.try(parse_zip_lookup(zip_json))
  use forecast <- result.try(parse_forecast(forecast_json))
  use place <- result.try(
    list.first(zip_info.places)
    |> result.map_error(fn(_) { "No places returned for zip code" }),
  )

  let temp_str =
    float.to_string(forecast.current.temperature_2m)
    <> " "
    <> forecast.current_units.temperature_2m
  let wind_str =
    float.to_string(forecast.current.wind_speed_10m)
    <> " "
    <> forecast.current_units.wind_speed_10m
  let humidity_str =
    int.to_string(forecast.current.relative_humidity_2m)
    <> forecast.current_units.relative_humidity_2m
  let condition = describe_wmo_code(forecast.current.weather_code)

  Ok(
    "Zip "
    <> zip_info.post_code
    <> " ("
    <> place.place_name
    <> ", "
    <> place.state_abbr
    <> "): Temp "
    <> temp_str
    <> " | Wind "
    <> wind_str
    <> " | Humidity "
    <> humidity_str
    <> " | Condition: "
    <> condition,
  )
}

pub fn run_reports() -> String {
  let samples = [
    #(zip_10001_json, forecast_10001_json),
    #(zip_90210_json, forecast_90210_json),
  ]
  let lines =
    list.map(samples, fn(pair) {
      case format_weather_report(pair.0, pair.1) {
        Ok(line) -> line
        Error(err) -> "Error: " <> err
      }
    })
  string.join(lines, "\n")
}

pub fn main() -> Nil {
  io.println(run_reports())
}
