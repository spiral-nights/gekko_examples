# `gekko_examples`

Standalone example projects demonstrating [`gekko`](https://github.com/spiral-nights/gekko) — a Gleam-to-MoonBit transpiler and WebAssembly Component compiler.

## Prerequisites

- **Gleam**: `1.19.x` (verified with `gleam 1.19.2`)
- **MoonBit**: `moon` toolchain (`wasm-gc`, `wasm`, `js`, `native`)
- **`gekko`**: installed or built from the `gekko` repository

## Examples

Each example directory includes its own `README.md` with setup, generation commands (where applicable), and run instructions:

| Example | What It Shows | Guide |
| --- | --- | --- |
| **Gleam Tour** | Pure Gleam language tour (basics, TCO loops, records, `echo`, stdlib) | [`gleam_tour/README.md`](./gleam_tour/README.md) |
| **Weather App** | `gleam/json` & `gleam/dynamic/decode` with custom records and pipelines | [`weather_app/README.md`](./weather_app/README.md) |
| **WIT Greeter** | Wasm Component (`wit/world.wit`, `gekko wit gen`, `wit check`, `wit build`) | [`wit_greeter/README.md`](./wit_greeter/README.md) |
| **MoonBit FFI** | Local `moonbit/` packages, `moonbitlang/core/math`, and `@external_type` | [`moonbit_ffi/README.md`](./moonbit_ffi/README.md) |
| **File I/O** | Reading/writing files via `moonbit/moon.mod` (`moonbitlang/x/fs`) + `gekko moonbit bind` | [`file_io/README.md`](./file_io/README.md) |

## Verification

Run the end-to-end verification script across all five examples:

```sh
./scripts/test_all.sh
```

To test against a specific `gekko` binary (for example, an uninstalled build):

```sh
GEKKO=/path/to/gekko ./scripts/test_all.sh
```
