# `weather_app` Example

An end-to-end JSON decoding and report-formatting application written in pure Gleam (`gleam/json` and `gleam/dynamic/decode`) and transpiled to MoonBit.

## What It Demonstrates

- Structured JSON decoding using `gleam/json` and `gleam/dynamic/decode` (`parse_zip_lookup`, `parse_forecast`).
- Decoding into nested Gleam custom types (`ZipLookup`, `Place`, `ForecastResponse`, `CurrentUnits`, `CurrentWeather`).
- Chaining fallible operations cleanly with `use ... <- result.try(...)`.
- Zero-change execution of Hex dependencies (`gleam_stdlib` and `gleam_json`), backed automatically by `gekko`'s built-in MoonBit shims (`gleam_json`, `gleam_dynamic`, `gleam_dynamic_decode`).

## Project Layout

```text
weather_app/
├── gleam.toml               # Declares gleam_stdlib and gleam_json dependencies
└── src/
    └── weather_app.gleam    # JSON decoders, sample payloads, report formatter, and `main`
```

## How It Was Created

No manual FFI or binding generation steps were needed:

1. Created a standard `gleam.toml` depending on `gleam_stdlib` and `gleam_json`.
2. Implemented all data types, `decode.Decoder` definitions, and formatting logic in pure Gleam inside `src/weather_app.gleam`.

When `gekko` transpiles the project, it compiles the Hex sources alongside its built-in MoonBit FFI shims (`Map`, `@json.Json`, dynamic decoders).

## How to Run

First download Hex dependencies if `build/packages/` is not already populated:

```bash
cd weather_app
gleam deps download
cd ../..
```

Then type-check and run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check --root weather_app

# Run on Wasm or JS
gekko run --root weather_app --target wasm
gekko run --root weather_app --target js
```
