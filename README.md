# `gekko_examples`

Standalone example projects demonstrating [`gekko`](https://github.com/spiral-nights/gekko) — a Gleam-to-MoonBit transpiler and WebAssembly Component compiler.

## Prerequisites

- **Gleam**: `1.19.x` (verified with `gleam 1.19.2`)
- **MoonBit**: `moon >= 0.1.20261104` / `moonc >= 0.10.20` (verified with `moon 0.1.20261119` / `moonc v0.10.22`; `wasm-gc`, `wasm`, `js`, `native`)
- **`gekko`**: installed or built from the `gekko` repository

## Examples

Each example directory includes its own `README.md` with setup, generation commands (where applicable), and run instructions:

| Example | What It Shows | Guide |
| --- | --- | --- |
| **Orbital Station** | Pure Gleam language tour (basics, TCO loops, records, `echo`, stdlib) | [`orbital_station/README.md`](./orbital_station/README.md) |
| **Weather App** | `gleam/json` & `gleam/dynamic/decode` with custom forecast records | [`weather_app/README.md`](./weather_app/README.md) |
| **WIT Greeter** | Minimal Wasm Component importing `wasi:clocks/wall-clock` and running under `wasmtime` | [`wit_greeter/README.md`](./wit_greeter/README.md) |
| **MoonBit FFI** | Local `moonbit/` package and `moonbitlang/core/math` via `@external` | [`moonbit_ffi/README.md`](./moonbit_ffi/README.md) |
| **File I/O** | Reading/writing files via `moonbit/moon.mod` (`moonbitlang/x/fs`) + `gekko moonbit bind` | [`file_io/README.md`](./file_io/README.md) |
| **Fibonacci CLI** | Reading CLI arguments via `moonbitlang/core/env` + native `gekko build --target native` | [`fibonacci_cli/README.md`](./fibonacci_cli/README.md) |
| **Calculator** | Pure-Gleam AST/evaluator with `party` parser combinators from Hex (no custom FFI) | [`calculator/README.md`](./calculator/README.md) |
| **Simplifile Shim** | Pure-Gleam `/// @patch` shims for `simplifile` and `filepath` using `gekko moonbit bind moonbitlang/x/fs` | [`simplifile_shim/README.md`](./simplifile_shim/README.md) |

## Verification

Run the end-to-end verification script across all eight examples:

```sh
./scripts/test_all.sh
```

To test against a specific `gekko` binary (for example, an uninstalled build):

```sh
GEKKO=/path/to/gekko ./scripts/test_all.sh
```
