# Gleam Analyzer Showcase (`gleam_analyzer`)

A Gleam static analyzer powered by [`glance`](https://hex.pm/packages/glance) that runs unmodified on **Erlang** and compiles to a **native** binary via `gekko` using pure-Gleam `/// @patch` shims.

## What It Analyzes

Given any Gleam project directory (`src/` and `test/`), `gleam_analyzer` discovers all `.gleam` files, parses each module with `glance`, and computes:

- Source line statistics (total, code, comment, blank, UTF-8 bytes)
- Declaration counts (internal/external imports, unqualified imports, custom types, opaque types, variants, fields, type aliases, constants, public/private/`@external`/`@deprecated` functions)
- Full AST & expression metrics (`let`, `let assert`, `use`, `assert`, AST expression node count, max expression depth, `case` / clause counts, pipes `|>`, `fn` closures, `panic`, `todo`, `echo`, bit arrays, record updates, and total function span sum)
- Top 10 largest modules by AST nodes, top 10 most complex functions by branching score, and top 10 most imported internal modules

## Architecture & Shims

Application code under `src/gleam_analyzer/` and `src/gleam_analyzer.gleam` depends **only** on standard Hex packages (`glance`, `simplifile`, `filepath`, `argv`, `gleam_stdlib`), so `gleam run` and `gleam export erlang-shipment` execute standard Erlang code.

When building for MoonBit/native with `gekko`, co-located `/// @patch` / `/// @patch_type` shims in `src/gleam_analyzer/shims/` splice cleanly into the upstream Hex packages:

- `simplifile` & `filepath` — backed by `gekko moonbit bind moonbitlang/x/fs` (`src/ffi/fs.gleam`)
- `argv` — backed by `gekko moonbit bind moonbitlang/core/env` (`src/ffi/env.gleam`)
- `glexer` & `splitter` — backed by a small MoonBit string helper (`moonbit/string_scan/string_scan.mbt` + `src/ffi/string_scan.gleam`)

## Build & Run

### Erlang

```sh
gleam test
gleam export erlang-shipment
./build/erlang-shipment/entrypoint.sh run /path/to/gleam/project
```

### Native (via `gekko`)

```sh
gekko test --target native
gekko build --release --target native -o gleam_analyzer.exe
./gleam_analyzer.exe /path/to/gleam/project
```

### CLI Options

```text
gleam_analyzer [--src-only] [--repeat <N>] [target_dir]
```

- `--src-only` — analyze `src/` only (skip `test/`)
- `--repeat <N>` — run `N` full analysis passes (useful for steady-state benchmarking without VM/process startup)
