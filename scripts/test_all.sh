#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEKKO="${GEKKO:-gekko}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_deps() {
  local dir="$ROOT/$1"
  if [ ! -d "$dir/build/packages" ]; then
    echo "[$1] Downloading Gleam dependencies..."
    (cd "$dir" && gleam deps download)
  fi
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
ensure_deps "weather_app"
"$GEKKO" check --root "$ROOT/weather_app" --out "$TMP_DIR/weather_app" --target wasm
(cd "$TMP_DIR/weather_app" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/weather_app" --out "$TMP_DIR/weather_app" --target "$target")"
  assert_contains "$out" "New York City, NY: Temp 43.0 °F | Wind 1.8 mp/h | Humidity 67% | Condition: Clear sky" "weather_app ($target)"
  assert_contains "$out" "Beverly Hills, CA: Temp 57.9 °F | Wind 11.9 mp/h | Humidity 32% | Condition: Clear sky" "weather_app ($target)"
done

echo "=== Verifying orbital_station ==="
ensure_deps "orbital_station"
"$GEKKO" check --root "$ROOT/orbital_station" --out "$TMP_DIR/orbital_station" --target wasm
(cd "$TMP_DIR/orbital_station" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/orbital_station" --out "$TMP_DIR/orbital_station" --target "$target")"
  assert_contains "$out" "=== Orbital Station Simulator (orbital_station) ===" "orbital_station ($target)"
  assert_contains "$out" "[Station Telemetry]" "orbital_station ($target)"
  assert_contains "$out" "[Station Commands]" "orbital_station ($target)"
  assert_contains "$out" "[Station Navigation]" "orbital_station ($target)"
  assert_contains "$out" "[Station Manifest]" "orbital_station ($target)"
  assert_contains "$out" "=== All station checks passed ===" "orbital_station ($target)"
  assert_contains "$out" "src/station/manifest.gleam:" "orbital_station ($target)"
done

echo "=== Verifying moonbit_ffi ==="
ensure_deps "moonbit_ffi"
"$GEKKO" check --root "$ROOT/moonbit_ffi" --out "$TMP_DIR/moonbit_ffi" --target wasm
(cd "$TMP_DIR/moonbit_ffi" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/moonbit_ffi" --out "$TMP_DIR/moonbit_ffi" --target "$target")"
  assert_contains "$out" "shout=HELLO MOONBIT!" "moonbit_ffi ($target)"
  assert_contains "$out" "upper=GLEAM,FFI" "moonbit_ffi ($target)"
  assert_contains "$out" "sum_squares=29" "moonbit_ffi ($target)"
  assert_contains "$out" "pow=1024.0" "moonbit_ffi ($target)"
  assert_contains "$out" "sin0=0.0,cos0=1.0" "moonbit_ffi ($target)"
done

echo "=== Verifying file_io ==="
ensure_deps "file_io"
mkdir -p "$TMP_DIR/file_io_bind/src" "$TMP_DIR/file_io_bind/moonbit"
cp "$ROOT/file_io/gleam.toml" "$TMP_DIR/file_io_bind/gleam.toml"
if [ -f "$ROOT/file_io/manifest.toml" ]; then
  cp "$ROOT/file_io/manifest.toml" "$TMP_DIR/file_io_bind/manifest.toml"
fi
cp "$ROOT/file_io/moonbit/moon.mod" "$TMP_DIR/file_io_bind/moonbit/moon.mod"
cat > "$TMP_DIR/file_io_bind/src/file_io.gleam" <<'EOF'
pub fn main() -> Nil {
  Nil
}
EOF
"$GEKKO" moonbit bind moonbitlang/x/fs --root "$TMP_DIR/file_io_bind" --module ffi/fs --out "$TMP_DIR/file_io_bind_out"
test -f "$TMP_DIR/file_io_bind/src/ffi/fs.gleam"
test -f "$TMP_DIR/file_io_bind/moonbit/fs_adapter/fs_adapter.mbt"

mkdir -p "$TMP_DIR/file_io"
cp "$ROOT/file_io/sample.txt" "$TMP_DIR/file_io/sample.txt"
"$GEKKO" check --root "$ROOT/file_io" --out "$TMP_DIR/file_io" --target wasm
(cd "$TMP_DIR/file_io" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/file_io" --out "$TMP_DIR/file_io" --target "$target")"
  assert_contains "$out" "first_line=Hello from Gleam + MoonBit file I/O!" "file_io ($target)"
  assert_contains "$out" "roundtrip=roundtrip-ok" "file_io ($target)"
  assert_contains "$out" "missing_is_err=True" "file_io ($target)"
done

echo "=== Verifying wit_greeter ==="
ensure_deps "wit_greeter"
(cd "$ROOT/wit_greeter" && gleam check)
"$GEKKO" wit check --root "$ROOT/wit_greeter" --out "$TMP_DIR/wit_greeter"
(cd "$TMP_DIR/wit_greeter" && moon check --deny-warn --target wasm)
if command -v wasm-tools >/dev/null 2>&1; then
  "$GEKKO" wit build --root "$ROOT/wit_greeter" --out "$TMP_DIR/wit_greeter" --output "$TMP_DIR/greeter.wasm"
  test -f "$TMP_DIR/greeter.wasm"
  if command -v wasmtime >/dev/null 2>&1; then
    wit_out_title="$(wasmtime run --invoke 'greet({name: "Ada", title: some("Dr.")})' "$TMP_DIR/greeter.wasm")"
    assert_contains "$wit_out_title" "Hello, Dr. Ada! (unix time: " "wit_greeter (wasmtime with title)"
    wit_out_plain="$(wasmtime run --invoke 'greet({name: "Grace", title: none})' "$TMP_DIR/greeter.wasm")"
    assert_contains "$wit_out_plain" "Hello, Grace! (unix time: " "wit_greeter (wasmtime without title)"
  fi
fi

echo "=== Verifying fibonacci_cli ==="
ensure_deps "fibonacci_cli"
"$GEKKO" check --root "$ROOT/fibonacci_cli" --out "$TMP_DIR/fibonacci_cli" --target wasm
(cd "$TMP_DIR/fibonacci_cli" && moon check --deny-warn --target wasm)
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/fibonacci_cli" --out "$TMP_DIR/fibonacci_cli" --target "$target")"
  assert_contains "$out" "fib(10) = 55" "fibonacci_cli ($target)"
  assert_contains "$out" "fib(20) = 6765" "fibonacci_cli ($target)"
done
"$GEKKO" build --root "$ROOT/fibonacci_cli" --target native --out "$TMP_DIR/fibonacci_cli.exe"
native_out="$("$TMP_DIR/fibonacci_cli.exe" 10 20 50)"
assert_contains "$native_out" "fib(10) = 55" "fibonacci_cli (native cli)"
assert_contains "$native_out" "fib(20) = 6765" "fibonacci_cli (native cli)"
assert_contains "$native_out" "fib(50) = 12586269025" "fibonacci_cli (native cli)"

echo "=== Verifying calculator ==="
ensure_deps "calculator"
(cd "$ROOT/calculator" && gleam format --check src test && gleam check)
"$GEKKO" check --root "$ROOT/calculator" --out "$TMP_DIR/calculator" --target wasm
(cd "$TMP_DIR/calculator" && moon check --deny-warn --target wasm)
"$GEKKO" test --root "$ROOT/calculator" --out "$TMP_DIR/calculator_test_out" --target wasm
for target in wasm js; do
  out="$("$GEKKO" run --root "$ROOT/calculator" --out "$TMP_DIR/calculator" --target "$target")"
  assert_contains "$out" "hypot(3, 4)  =>  = 5.0" "calculator ($target)"
  assert_contains "$out" "avg(10, 20, 30, 40)  =>  = 25.0" "calculator ($target)"
  assert_contains "$out" "2 ^ 3 ^ 2  =>  = 512.0" "calculator ($target)"
  assert_contains "$out" "clamp(quadratic_disc(1, -5, 6), 0, 10)  =>  = 1.0" "calculator ($target)"
  assert_contains "$out" "10 / (5 - 5)  =>  ERROR: Division by zero" "calculator ($target)"
done
"$GEKKO" build --root "$ROOT/calculator" --target native --out "$TMP_DIR/calculator.exe"
calc_cli_out="$("$TMP_DIR/calculator.exe" "fn hypot(a, b) = sqrt(a^2 + b^2)" "let c = hypot(3, 4); c * 10")"
assert_contains "$calc_cli_out" "defined hypot/2" "calculator (native cli fn)"
assert_contains "$calc_cli_out" "c = 5.0" "calculator (native cli let)"
assert_contains "$calc_cli_out" "c * 10  =>  = 50.0" "calculator (native cli eval)"

echo "All 7 gekko examples passed."
