#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEKKO="${GEKKO:-gekko}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

STDLIB_ABS=""
if [ -n "${GEKKO_STDLIB_DIR:-}" ]; then
  STDLIB_ABS="$(cd "$GEKKO_STDLIB_DIR" && pwd)"
fi

JSON_ABS=""
if [ -n "${GEKKO_JSON_DIR:-}" ]; then
  JSON_ABS="$(cd "$GEKKO_JSON_DIR" && pwd)"
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

  local staged="$TMP_DIR/staged/$name"
  rm -rf "$staged"
  mkdir -p "$staged"
  (cd "$ROOT/$name" && tar cf - --exclude=build --exclude=manifest.toml .) | (cd "$staged" && tar xf -)

  if [ -n "$STDLIB_ABS" ]; then
    sed -i -E "s|^gekko_stdlib = .*|gekko_stdlib = { path = \"$STDLIB_ABS\" }|" "$staged/gleam.toml"
  fi
  if [ -n "$JSON_ABS" ]; then
    sed -i -E "s|^gekko_json = .*|gekko_json = { path = \"$JSON_ABS\" }|" "$staged/gleam.toml"
  fi

  (cd "$staged" && gleam deps download >/dev/null)
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
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/weather_app" --target wasm
(cd "$TMP_DIR/weather_app" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/weather_app" --target "$target")"
  assert_contains "$out" "New York City, NY: Temp 43.0 °F | Wind 1.8 mp/h | Humidity 67% | Condition: Clear sky" "weather_app ($target)"
  assert_contains "$out" "Beverly Hills, CA: Temp 57.9 °F | Wind 11.9 mp/h | Humidity 32% | Condition: Clear sky" "weather_app ($target)"
done

echo "=== Verifying orbital_station ==="
prepare_example "orbital_station"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/orbital_station" --target wasm
(cd "$TMP_DIR/orbital_station" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/orbital_station" --target "$target")"
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
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/moonbit_ffi" --target wasm
(cd "$TMP_DIR/moonbit_ffi" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/moonbit_ffi" --target "$target")"
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

mkdir -p "$TMP_DIR/file_io"
cp "$EXAMPLE_DIR/sample.txt" "$TMP_DIR/file_io/sample.txt"
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/file_io" --target wasm
(cd "$TMP_DIR/file_io" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/file_io" --target "$target")"
  assert_contains "$out" "first_line=Hello from Gleam + MoonBit file I/O!" "file_io ($target)"
  assert_contains "$out" "roundtrip=roundtrip-ok" "file_io ($target)"
  assert_contains "$out" "missing_is_err=True" "file_io ($target)"
done

echo "=== Verifying wit_greeter ==="
prepare_example "wit_greeter"
(cd "$EXAMPLE_DIR" && gleam check)
"$GEKKO" wit check --root "$EXAMPLE_DIR" --out "$TMP_DIR/wit_greeter"
(cd "$TMP_DIR/wit_greeter" && moon check --deny-warn --target wasm)
if command -v wasm-tools >/dev/null 2>&1; then
  "$GEKKO" wit build --root "$EXAMPLE_DIR" --out "$TMP_DIR/wit_greeter" --output "$TMP_DIR/greeter.wasm"
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
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/fibonacci_cli" --target wasm
(cd "$TMP_DIR/fibonacci_cli" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/fibonacci_cli" --target "$target")"
  assert_contains "$out" "fib(10) = 55" "fibonacci_cli ($target)"
  assert_contains "$out" "fib(20) = 6765" "fibonacci_cli ($target)"
done
"$GEKKO" build --root "$EXAMPLE_DIR" --target native --out "$TMP_DIR/fibonacci_cli.exe"
native_out="$("$TMP_DIR/fibonacci_cli.exe" 10 20 50)"
assert_contains "$native_out" "fib(10) = 55" "fibonacci_cli (native cli)"
assert_contains "$native_out" "fib(20) = 6765" "fibonacci_cli (native cli)"
assert_contains "$native_out" "fib(50) = 12586269025" "fibonacci_cli (native cli)"

echo "=== Verifying calculator ==="
prepare_example "calculator"
(cd "$EXAMPLE_DIR" && gleam format --check src test && gleam check)
"$GEKKO" check --root "$EXAMPLE_DIR" --out "$TMP_DIR/calculator" --target wasm
(cd "$TMP_DIR/calculator" && moon check --deny-warn --target wasm)
"$GEKKO" test --root "$EXAMPLE_DIR" --out "$TMP_DIR/calculator_test_out" --target wasm
for target in wasm js; do
  out="$("$GEKKO" run --root "$EXAMPLE_DIR" --out "$TMP_DIR/calculator" --target "$target")"
  assert_contains "$out" "hypot(3, 4)  =>  = 5.0" "calculator ($target)"
  assert_contains "$out" "avg(10, 20, 30, 40)  =>  = 25.0" "calculator ($target)"
  assert_contains "$out" "2 ^ 3 ^ 2  =>  = 512.0" "calculator ($target)"
  assert_contains "$out" "clamp(quadratic_disc(1, -5, 6), 0, 10)  =>  = 1.0" "calculator ($target)"
  assert_contains "$out" "10 / (5 - 5)  =>  ERROR: Division by zero" "calculator ($target)"
done
"$GEKKO" build --root "$EXAMPLE_DIR" --target native --out "$TMP_DIR/calculator.exe"
calc_cli_out="$("$TMP_DIR/calculator.exe" "fn hypot(a, b) = sqrt(a^2 + b^2)" "let c = hypot(3, 4); c * 10")"
assert_contains "$calc_cli_out" "defined hypot/2" "calculator (native cli fn)"
assert_contains "$calc_cli_out" "c = 5.0" "calculator (native cli let)"
assert_contains "$calc_cli_out" "c * 10  =>  = 50.0" "calculator (native cli eval)"

echo "All 7 gekko examples passed."
