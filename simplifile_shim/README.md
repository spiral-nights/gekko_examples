# Simplifile Shim Example

Demonstrates writing pure-Gleam `/// @patch(...)` shims for the unmodified Hex packages `simplifile` and `filepath`, backed exclusively by FFI bindings generated via `gekko moonbit bind moonbitlang/x/fs`.

## Generating the FFI Bindings

```sh
gekko moonbit bind moonbitlang/x/fs --module ffi/fs
```

## Running

```sh
gekko run --target wasm
gekko run --target js
```
