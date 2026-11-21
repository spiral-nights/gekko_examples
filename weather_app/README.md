# `weather_app` Example

An end-to-end JSON decoding and report-formatting application written in pure Gleam (`gleam/json` and `gleam/dynamic/decode`) and transpiled to MoonBit.

## What It Demonstrates

- Structured JSON decoding using `gleam/json` and `gleam/dynamic/decode` (`parse_zip_lookup`, `parse_forecast`).
- Decoding into nested Gleam custom types (`ZipLookup`, `Place`, `ForecastResponse`, `CurrentUnits`, `CurrentWeather`).
- Chaining fallible operations cleanly with `use ... <- result.try(...)`.
- Transpiles the MoonBit-enabled [`gleam_stdlib`](https://github.com/spiral-nights/gleam_stdlib) and [`gleam_json`](https://github.com/spiral-nights/gleam_json) forks directly, using their bundled `moonbit/` FFI packages (`gleam_stdlib_ffi` and `gleam_json_ffi`).

## Project Layout

```text
weather_app/
├── gleam.toml               # Declares gleam_stdlib and gleam_json dependencies
└── src/
    └── weather_app.gleam    # JSON decoders, sample payloads, report formatter, and `main`
```

## How It Was Created

No manual FFI or binding generation steps were needed:

1. Created a `gleam.toml` pointing `gleam_stdlib` and `gleam_json` at the MoonBit-enabled forks.
2. Implemented all data types, `decode.Decoder` definitions, and formatting logic in pure Gleam inside `src/weather_app.gleam`.

When `gekko` transpiles the project, it compiles the Gleam sources alongside each package's bundled MoonBit FFI bindings (`Map`, `@json.Json`, dynamic decoders).

## How to Run

First download dependencies if `build/packages/` is not already populated:

```bash
cd weather_app
gleam deps download
cd ..
```

Then type-check and run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check --root weather_app

# Run on Wasm or JS
gekko run --root weather_app --target wasm
gekko run --root weather_app --target js
```
