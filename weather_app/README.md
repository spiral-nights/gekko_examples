# `weather_app` Example

A pure-Gleam JSON decoding example using `gleam/json` and `gleam/dynamic/decode`, transpiled to MoonBit by `gekko`.

## What It Demonstrates

- Structured JSON decoding using `gleam/json` and `gleam/dynamic/decode` (`parse_forecast`).
- Decoding Open-Meteo weather forecast JSON payloads into nested Gleam custom types (`ForecastResponse`, `CurrentUnits`, `CurrentWeather`).
- Transpiles [`gleam_stdlib`](https://github.com/spiral-nights/gekko_gleam_stdlib) and [`gleam_json`](https://github.com/spiral-nights/gekko_gleam_json) directly, using their bundled `moonbit/` FFI packages.

## Project Layout

```text
weather_app/
├── gleam.toml               # Declares gleam_stdlib and gleam_json dependencies
└── src/
    └── weather_app.gleam    # Forecast JSON decoders, formatter, and `main`
```

## How to Run

First download dependencies if `build/packages/` is not already populated:

```bash
cd weather_app
gleam deps download
```

Then type-check, build, or run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check

# Run on Wasm, JS, or native
gekko run --target wasm
gekko run --target js
gekko build --target native
./weather_app.exe
```
