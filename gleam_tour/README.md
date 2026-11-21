# `gleam_tour` Example

An original Orbital Station Simulator written in pure Gleam to exercise Gleam's language features—primitives, closures, pipelines, pattern matching, tail-recursive loops, custom types, record updates, opaque types, and standard library modules—compiled through `gekko` to MoonBit.

## What It Demonstrates

- **Telemetry (`src/station/telemetry.gleam`):** Constants (`const`), 64-bit integers (`Int64`), floats (`Double`), booleans, string concatenation and escapes, shadowing, block expressions, and tuples.
- **Commands (`src/station/commands.gleam`):** Labelled arguments, anonymous functions, function captures (`_`), generic higher-order functions, pipelines (`|>`), and `use` expressions.
- **Navigation (`src/station/navigation.gleam`):** `case` pattern matching with guards (`if`), tuple/list destructuring, and tail-recursive loops (lowered by `gekko` to MoonBit functional `for` loops).
- **Manifest (`src/station/manifest.gleam`):** Multi-variant custom types, record types with uniform field accessors and immutable record updates (`Thruster(..t, fuel_kg: ...)`), `opaque type` (`DockingCode`), `Option`, `Result`, `let assert`, `assert`, `list`, `dict`, `string.inspect`, and `echo`.

## Project Layout

```text
gleam_tour/
├── gleam.toml                       # Declares gleam_stdlib and gleam_json dependencies
└── src/
    ├── gleam_tour.gleam             # Entrypoint (`main`)
    └── station/
        ├── commands.gleam
        ├── manifest.gleam
        ├── navigation.gleam
        └── telemetry.gleam
```

## How It Was Created

No FFI, adapters, or code generation steps were required. This is a pure Gleam project written with standard `gleam` conventions and `gleam.toml` dependencies (using the MoonBit-enabled `gleam_stdlib` and `gleam_json` forks); `gekko` transpiles both the modules under `src/` and the resolved dependencies under `build/packages/` directly into a MoonBit workspace.

## How to Run

First ensure dependencies (`gleam_stdlib`, `gleam_json`) are downloaded (run inside `gleam_tour` once if needed):

```bash
cd gleam_tour
gleam deps download
cd ..
```

Then type-check and run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check --root gleam_tour

# Run targeting linear-memory WebAssembly or JavaScript
gekko run --root gleam_tour --target wasm
gekko run --root gleam_tour --target js
```
