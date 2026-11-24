# AGENTS.md

## Project Overview

Standalone example projects demonstrating `gekko` (Gleam-to-MoonBit compilation).

## Verification

Run the end-to-end verification script across all examples:

```sh
./scripts/test_all.sh
```

Override the compiler binary with `GEKKO=/path/to/gekko ./scripts/test_all.sh` if needed.

## Key Conventions & Invariants

- **Dependencies**: Example `gleam.toml` files should point `gleam_stdlib` and `gleam_json` to unmodified upstream Hex packages alongside the companion shims:
  - `gekko_stdlib` (`https://github.com/spiral-nights/gekko_stdlib.git`, `ref = "main"`)
  - `gekko_json` (`https://github.com/spiral-nights/gekko_json.git`, `ref = "main"`)

## Git

- Use conventional commit messages (e.g. `docs: add AGENTS.md`, `chore: ...`).
- Do not push unless explicitly asked.
