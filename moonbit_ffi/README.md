# `moonbit_ffi` Example

Demonstrates handwritten local MoonBit FFI packages, direct MoonBit standard library calls, and opaque `@external_type` mappings from Gleam.

## What It Demonstrates

1. **Local MoonBit package with auto-generated `moon.pkg` (`moonbit/text_ffi/text_ffi.mbt`):**
   - Placed in `moonbit/text_ffi/` with no `moon.pkg` file.
   - `gekko` copies the package into the generated workspace and auto-generates a `moon.pkg` importing `"moonbit_ffi/gprelude" @gprelude`, allowing `text_ffi.mbt` to work directly with `@gprelude.GList[T]` (`shout`, `upper_all`, `sum_squares`).
2. **Local MoonBit package with custom `moon.pkg` (`moonbit/byte_ffi/`):**
   - Provides its own `moonbit/byte_ffi/moon.pkg` to import `"moonbitlang/core/buffer" @buffer` alongside `@gprelude` (`repeat_utf8_byte_size`).
3. **Direct MoonBit standard library calls (no `.mbt` wrapper needed):**
   - `src/moonbit_ffi.gleam` binds directly to `"moonbitlang/core/math"` (`sin`, `cos`, `pow`) using `/// @external(moonbit, "moonbitlang/core/math", "...")`.
4. **Opaque external MoonBit types (`/// @external_type`):**
   - `pub type Counter` in `src/moonbit_ffi.gleam` is annotated with `/// @external_type(moonbit, "text_ffi", "Counter")`, emitting `pub type Counter = @text_ffi.Counter`.
   - Values of `Counter` are mutated by MoonBit (`new_counter`, `increment_counter`, `read_counter`) and stored directly in a Gleam record (`NamedCounter`) and `List(Counter)` without marshaling overhead.

## Project Layout

```text
moonbit_ffi/
├── gleam.toml                         # Declares gleam_stdlib dependency
├── moonbit/                           # Hand-written local MoonBit FFI packages
│   ├── text_ffi/
│   │   └── text_ffi.mbt               # Uses @gprelude.GList + `Counter` struct (auto `moon.pkg`)
│   └── byte_ffi/
│       ├── moon.pkg                   # Explicit imports: @gprelude + @buffer
│       └── byte_ffi.mbt               # Uses @buffer.Buffer and @gprelude.BitArray
└── src/
    └── moonbit_ffi.gleam              # `@external_type` / `@external` pragmas + `main`
```

## How It Was Created

1. Created the local MoonBit packages inside `<project_root>/moonbit/<pkg>/` (`moonbit/text_ffi/text_ffi.mbt` without `moon.pkg`, and `moonbit/byte_ffi/{moon.pkg, byte_ffi.mbt}`).
2. Annotated Gleam FFI declarations in `src/moonbit_ffi.gleam` with `/// @external_type(moonbit, ...)` and `/// @external(moonbit, ...)` doc-comment pragmas (using `{ let _ = ...; panic as "Implemented in MoonBit" }` stub bodies so standard `gleam check` continues to pass cleanly).

No `gekko moonbit bind` generation step was used here—this example shows how to author and wire MoonBit FFI packages manually. (See [`file_io`](../file_io/README.md) for auto-generated bindings via `gekko moonbit bind`.)

## How to Run

First download dependencies if `build/packages/` is not already populated:

```bash
cd moonbit_ffi
gleam deps download
cd ..
```

Then type-check and run via `gekko`:

```bash
# Type-check the transpiled MoonBit workspace
gekko check --root moonbit_ffi

# Run on Wasm or JS
gekko run --root moonbit_ffi --target wasm
gekko run --root moonbit_ffi --target js
```
