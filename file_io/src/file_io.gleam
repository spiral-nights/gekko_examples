import ffi/fs
import gleam/bit_array
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/string

pub fn main() -> Nil {
  assert fs.path_exists("sample.txt") == True
  assert fs.is_file("sample.txt") == Ok(True)

  let assert Ok(text) = fs.read_file_to_string("sample.txt", None)
  let first_line = case string.split(text, "\n") {
    [line, ..] -> string.trim_end(line)
    [] -> ""
  }
  assert first_line == "Hello from Gleam + MoonBit file I/O!"

  let assert Ok(bytes) = fs.read_file_to_bytes("sample.txt")
  let byte_len = bit_array.byte_size(bytes)
  assert byte_len > 0

  let assert Ok(Nil) =
    fs.write_string_to_file("roundtrip.txt", "roundtrip-ok", None)
  let assert Ok(rt) = fs.read_file_to_string("roundtrip.txt", None)
  assert rt == "roundtrip-ok"
  let assert Ok(Nil) = fs.remove_file("roundtrip.txt")

  let missing_is_err = case fs.read_file_to_string("missing_file.txt", None) {
    Error(_) -> True
    Ok(_) -> False
  }
  assert missing_is_err == True

  io.println("first_line=" <> first_line)
  io.println("bytes=" <> int.to_string(byte_len))
  io.println("roundtrip=" <> rt)
  io.println("missing_is_err=True")
}
