#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEKKO="${GEKKO:-gekko}"
EXAMPLE_TARGETS="${EXAMPLE_TARGETS:-wasm js}"
SKIP_NATIVE="${SKIP_NATIVE:-0}"
GEKKO_CACHE_DIR="${GEKKO_CACHE_DIR:-}"
FIRST_TARGET="${EXAMPLE_TARGETS%% *}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -n "$GEKKO_CACHE_DIR" ]; then
  OUT_BASE="$GEKKO_CACHE_DIR/examples_out"
  STAGE_BASE="$GEKKO_CACHE_DIR/examples_staged"
else
  OUT_BASE="$TMP_DIR/out"
  STAGE_BASE="$TMP_DIR/staged"
fi
mkdir -p "$OUT_BASE" "$STAGE_BASE"

LAST_CHANGED=0

copy_if_changed() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    LAST_CHANGED=0
  else
    cp "$src" "$dest"
    LAST_CHANGED=1
  fi
}

sync_tree_preserve() {
  local src_dir="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"
  (
    cd "$dest_dir"
    find . \( -path './build' -o -path './build/*' -o -path './_build' -o -path './_build/*' -o -path './manifest.toml' -o -path './.git' -o -path './.git/*' \) -prune -o -type f -print
  ) | while IFS= read -r rel; do
    if [ ! -f "$src_dir/$rel" ]; then
      rm -f "$dest_dir/$rel"
    fi
  done
  (
    cd "$dest_dir"
    find . \( -path './build' -o -path './build/*' -o -path './_build' -o -path './_build/*' -o -path './.git' -o -path './.git/*' \) -prune -o -type d -empty -print 2>/dev/null || true
  ) | sort -r | while IFS= read -r rel; do
    [ "$rel" = "." ] || rmdir "$dest_dir/$rel" 2>/dev/null || true
  done
  (
    cd "$src_dir"
    find . -type f -print
  ) | while IFS= read -r rel; do
    copy_if_changed "$src_dir/$rel" "$dest_dir/$rel"
  done
}

STDLIB_ABS=""
if [ -n "${GEKKO_STDLIB_DIR:-}" ]; then
  STDLIB_ABS="$(cd "$GEKKO_STDLIB_DIR" && pwd)"
fi

JSON_ABS=""
if [ -n "${GEKKO_JSON_DIR:-}" ]; then
  JSON_ABS="$(cd "$GEKKO_JSON_DIR" && pwd)"
fi

if [ -n "$STDLIB_ABS" ] && [ -n "$JSON_ABS" ]; then
  STAGED_JSON_RAW="$TMP_DIR/raw_gekko_json"
  mkdir -p "$STAGED_JSON_RAW"
  (cd "$JSON_ABS" && tar cf - --exclude=build --exclude=_build --exclude=manifest.toml .) | (cd "$STAGED_JSON_RAW" && tar xf -)
  sed -i -E "s|^gekko_stdlib = .*|gekko_stdlib = { path = \"$STDLIB_ABS\" }|" "$STAGED_JSON_RAW/gleam.toml"
  STAGED_JSON_DEP="$STAGE_BASE/_gekko_json"
  sync_tree_preserve "$STAGED_JSON_RAW" "$STAGED_JSON_DEP"
  JSON_ABS="$STAGED_JSON_DEP"
fi

ensure_deps() {
  local dir="$1"
  if [ ! -d "$dir/build/packages" ]; then
    echo "[$(basename "$dir")] Downloading Gleam dependencies..."
    (cd "$dir" && gleam deps download)
  fi
}

prepare_example() {
  local name="$1"
  if [ -z "$STDLIB_ABS" ] && [ -z "$JSON_ABS" ]; then
    ensure_deps "$ROOT/$name"
    EXAMPLE_DIR="$ROOT/$name"
    return
  fi

  local raw_stage="$TMP_DIR/raw/$name"
  rm -rf "$raw_stage"
  mkdir -p "$raw_stage"
  (cd "$ROOT/$name" && tar cf - --exclude=build --exclude=_build --exclude=manifest.toml .) | (cd "$raw_stage" && tar xf -)

  if [ -n "$STDLIB_ABS" ]; then
    sed -i -E "s|^gekko_stdlib = .*|gekko_stdlib = { path = \"$STDLIB_ABS\" }|" "$raw_stage/gleam.toml"
  fi
  if [ -n "$JSON_ABS" ]; then
    sed -i -E "s|^gekko_json = .*|gekko_json = { path = \"$JSON_ABS\" }|" "$raw_stage/gleam.toml"
  fi

  local staged="$STAGE_BASE/$name"
  local toml_changed=0
  if [ ! -f "$staged/gleam.toml" ] || ! cmp -s "$raw_stage/gleam.toml" "$staged/gleam.toml"; then
    toml_changed=1
  fi
  sync_tree_preserve "$raw_stage" "$staged"

  if [ ! -d "$staged/build/packages" ] || [ "$toml_changed" -eq 1 ]; then
    rm -f "$staged/manifest.toml"
    (cd "$staged" && gleam deps download >/dev/null)
  fi
  EXAMPLE_DIR="$staged"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  case "$haystack" in
    *"$needle"*) ;;
    *)
      echo "FAIL [$label]: expected output to contain: $needle" >&2
      echo "--- Output ---" >&2
      echo "$haystack" >&2
      exit 1
      ;;
  esac
}

echo "=== Verifying weather_app ==="
prepare_example "weather_app"
OUT_DIR="$OUT_BASE/weather_app"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  if [ "$target" = "$FIRST_TARGET" ]; then
    out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$target" 2>&1)"
  else
    out="$(cd "$OUT_DIR" && moon run --target "$target" weather_app 2>&1)"
  fi
  assert_contains "$out" "New York City, NY: Temp 43.0 °F | Wind 1.8 mp/h | Humidity 67% | Condition: Clear sky" "weather_app ($target)"
  assert_contains "$out" "Beverly Hills, CA: Temp 57.9 °F | Wind 11.9 mp/h | Humidity 32% | Condition: Clear sky" "weather_app ($target)"
done

echo "=== Verifying orbital_station ==="
prepare_example "orbital_station"
OUT_DIR="$OUT_BASE/orbital_station"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" orbital_station 2>&1)"
  assert_contains "$out" "=== Orbital Station Simulator (orbital_station) ===" "orbital_station ($target)"
  assert_contains "$out" "[Station Telemetry]" "orbital_station ($target)"
  assert_contains "$out" "[Station Commands]" "orbital_station ($target)"
  assert_contains "$out" "[Station Navigation]" "orbital_station ($target)"
  assert_contains "$out" "[Station Manifest]" "orbital_station ($target)"
  assert_contains "$out" "=== All station checks passed ===" "orbital_station ($target)"
  assert_contains "$out" "src/station/manifest.gleam:" "orbital_station ($target)"
done

echo "=== Verifying moonbit_ffi ==="
prepare_example "moonbit_ffi"
OUT_DIR="$OUT_BASE/moonbit_ffi"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" moonbit_ffi 2>&1)"
  assert_contains "$out" "shout=HELLO MOONBIT!" "moonbit_ffi ($target)"
  assert_contains "$out" "upper=GLEAM,FFI" "moonbit_ffi ($target)"
  assert_contains "$out" "sum_squares=29" "moonbit_ffi ($target)"
  assert_contains "$out" "pow=1024.0" "moonbit_ffi ($target)"
  assert_contains "$out" "sin0=0.0,cos0=1.0" "moonbit_ffi ($target)"
done

echo "=== Verifying file_io ==="
prepare_example "file_io"
mkdir -p "$TMP_DIR/file_io_bind/src" "$TMP_DIR/file_io_bind/moonbit"
cp "$EXAMPLE_DIR/gleam.toml" "$TMP_DIR/file_io_bind/gleam.toml"
if [ -f "$EXAMPLE_DIR/manifest.toml" ]; then
  cp "$EXAMPLE_DIR/manifest.toml" "$TMP_DIR/file_io_bind/manifest.toml"
fi
cp "$EXAMPLE_DIR/moonbit/moon.mod" "$TMP_DIR/file_io_bind/moonbit/moon.mod"
cat > "$TMP_DIR/file_io_bind/src/file_io.gleam" <<'EOF'
pub fn main() -> Nil {
  Nil
}
EOF
"$GEKKO" moonbit bind moonbitlang/x/fs --root "$TMP_DIR/file_io_bind" --module ffi/fs --out "$TMP_DIR/file_io_bind_out"
test -f "$TMP_DIR/file_io_bind/src/ffi/fs.gleam"
test -f "$TMP_DIR/file_io_bind/moonbit/fs_adapter/fs_adapter.mbt"

OUT_DIR="$OUT_BASE/file_io"
mkdir -p "$OUT_DIR"
cp "$EXAMPLE_DIR/sample.txt" "$OUT_DIR/sample.txt"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" file_io 2>&1)"
  assert_contains "$out" "first_line=Hello from Gleam + MoonBit file I/O!" "file_io ($target)"
  assert_contains "$out" "roundtrip=roundtrip-ok" "file_io ($target)"
  assert_contains "$out" "missing_is_err=True" "file_io ($target)"
done

echo "=== Verifying wit_greeter ==="
prepare_example "wit_greeter"
OUT_DIR="$OUT_BASE/wit_greeter"
(cd "$EXAMPLE_DIR" && gleam check)
"$GEKKO" wit check --root "$EXAMPLE_DIR" --out "$OUT_DIR"
(cd "$OUT_DIR" && moon check --deny-warn --target wasm)
if command -v wasm-tools >/dev/null 2>&1; then
  "$GEKKO" wit build --root "$EXAMPLE_DIR" --out "$OUT_DIR" --output "$TMP_DIR/greeter.wasm"
  test -f "$TMP_DIR/greeter.wasm"
  if command -v wasmtime >/dev/null 2>&1; then
    wit_out_title="$(wasmtime run --invoke 'greet({name: "Ada", title: some("Dr.")})' "$TMP_DIR/greeter.wasm")"
    assert_contains "$wit_out_title" "Hello, Dr. Ada! (unix time: " "wit_greeter (wasmtime with title)"
    wit_out_plain="$(wasmtime run --invoke 'greet({name: "Grace", title: none})' "$TMP_DIR/greeter.wasm")"
    assert_contains "$wit_out_plain" "Hello, Grace! (unix time: " "wit_greeter (wasmtime without title)"
  fi
fi

echo "=== Verifying fibonacci_cli ==="
prepare_example "fibonacci_cli"
OUT_DIR="$OUT_BASE/fibonacci_cli"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" fibonacci_cli 2>&1)"
  assert_contains "$out" "fib(10) = 55" "fibonacci_cli ($target)"
  assert_contains "$out" "fib(20) = 6765" "fibonacci_cli ($target)"
done
if [ "$SKIP_NATIVE" != "1" ]; then
  "$GEKKO" build --root "$EXAMPLE_DIR" --target native --work-dir "$OUT_DIR" --out "$TMP_DIR/fibonacci_cli.exe"
  native_out="$("$TMP_DIR/fibonacci_cli.exe" 10 20 50)"
  assert_contains "$native_out" "fib(10) = 55" "fibonacci_cli (native cli)"
  assert_contains "$native_out" "fib(20) = 6765" "fibonacci_cli (native cli)"
  assert_contains "$native_out" "fib(50) = 12586269025" "fibonacci_cli (native cli)"
fi

echo "=== Verifying calculator ==="
prepare_example "calculator"
OUT_DIR="$OUT_BASE/calculator"
(cd "$EXAMPLE_DIR" && gleam format --check src test && gleam check)
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
(cd "$OUT_DIR" && moon test --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" calculator 2>&1)"
  assert_contains "$out" "hypot(3, 4)  =>  = 5.0" "calculator ($target)"
  assert_contains "$out" "avg(10, 20, 30, 40)  =>  = 25.0" "calculator ($target)"
  assert_contains "$out" "2 ^ 3 ^ 2  =>  = 512.0" "calculator ($target)"
  assert_contains "$out" "clamp(quadratic_disc(1, -5, 6), 0, 10)  =>  = 1.0" "calculator ($target)"
  assert_contains "$out" "10 / (5 - 5)  =>  ERROR: Division by zero" "calculator ($target)"
done
if [ "$SKIP_NATIVE" != "1" ]; then
  "$GEKKO" build --root "$EXAMPLE_DIR" --target native --work-dir "$OUT_DIR" --out "$TMP_DIR/calculator.exe"
  calc_cli_out="$("$TMP_DIR/calculator.exe" "fn hypot(a, b) = sqrt(a^2 + b^2)" "let c = hypot(3, 4); c * 10")"
  assert_contains "$calc_cli_out" "defined hypot/2" "calculator (native cli fn)"
  assert_contains "$calc_cli_out" "c = 5.0" "calculator (native cli let)"
  assert_contains "$calc_cli_out" "c * 10  =>  = 50.0" "calculator (native cli eval)"
fi

echo "=== Verifying simplifile_shim ==="
prepare_example "simplifile_shim"
OUT_DIR="$OUT_BASE/simplifile_shim"
(cd "$EXAMPLE_DIR" && gleam format --check src && gleam check)
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$OUT_DIR" --target "$FIRST_TARGET"
(cd "$OUT_DIR" && moon check --deny-warn --target "$FIRST_TARGET")
for target in $EXAMPLE_TARGETS; do
  out="$(cd "$OUT_DIR" && moon run --target "$target" simplifile_shim 2>&1)"
  assert_contains "$out" "joined=simplifile_demo_tmp/sub/note.txt" "simplifile_shim ($target)"
  assert_contains "$out" "content=hello gekko" "simplifile_shim ($target)"
  assert_contains "$out" "entries=note.txt" "simplifile_shim ($target)"
  assert_contains "$out" "missing_is_err=True" "simplifile_shim ($target)"
  assert_contains "$out" "cleaned=True" "simplifile_shim ($target)"
done

echo "All 8 gekko examples passed."
