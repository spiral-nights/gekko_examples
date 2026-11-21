# `moonbit_ffi` Example

Demonstrates handwritten MoonBit FFI from Gleam using `/// @external(moonbit, ...)`: a local `moonbit/` package and direct MoonBit standard library calls.

## What It Demonstrates

1. **Local MoonBit package (`moonbit/text_ffi/text_ffi.mbt`):**
   - Placed in `moonbit/text_ffi/` with no `moon.pkg` file.
   - `gekko` copies the package into the generated workspace and auto-generates a `moon.pkg` importing `"moonbit_ffi/gprelude" @gprelude`, allowing `text_ffi.mbt` to accept and return `@gprelude.GList[T]` (`shout`, `upper_all`, `sum_squares`).
2. **Direct MoonBit standard library calls (no `.mbt` wrapper needed):**
   - `src/moonbit_ffi.gleam` binds directly to `"moonbitlang/core/math"` (`sin`, `cos`, `pow`) using `/// @external(moonbit, "moonbitlang/core/math", "...")`.

## Project Layout

```text
moonbit_ffi/
├── gleam.toml                     # Declares gleam_stdlib dependency
├── moonbit/
│   └── text_ffi/
│       └── text_ffi.mbt           # Local MoonBit package using @gprelude.GList
└── src/
    └── moonbit_ffi.gleam          # `@external(moonbit, ...)` pragmas + `main`
```

## How to Run

First download dependencies if `build/packages/` is not already populated:

```bash
cd moonbit_ffi
gleam deps download
```

Then type-check and run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check

# Run on Wasm or JS
gekko run --target wasm
gekko run --target js
```
