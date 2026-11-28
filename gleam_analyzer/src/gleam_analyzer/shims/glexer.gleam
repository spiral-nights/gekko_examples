import ffi/string_scan

/// @patch("glexer:glexer.length")
pub fn length(string: String) -> Int {
  string_scan.utf16_length(string)
}

/// @patch("glexer:glexer.slice_bytes")
pub fn slice_bytes(string: String, from byte: Int, sized bytes: Int) -> String {
  string_scan.utf16_slice(string, byte, bytes)
}

/// @patch("glexer:glexer.drop_byte")
pub fn drop_byte(string: String) -> String {
  string_scan.utf16_drop_one(string)
}
