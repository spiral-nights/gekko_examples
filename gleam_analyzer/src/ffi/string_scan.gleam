import gleam/option.{type Option}

/// @external(moonbit, "string_scan", "utf16_length")
pub fn utf16_length(s: String) -> Int {
  let _ = s
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "string_scan", "utf16_slice")
pub fn utf16_slice(s: String, start: Int, length: Int) -> String {
  let _ = s
  let _ = start
  let _ = length
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "string_scan", "utf16_drop_one")
pub fn utf16_drop_one(s: String) -> String {
  let _ = s
  panic as "Implemented in MoonBit"
}

/// @external(moonbit, "string_scan", "find_first")
pub fn find_first(
  haystack: String,
  patterns: List(String),
) -> Option(#(Int, Int)) {
  let _ = haystack
  let _ = patterns
  panic as "Implemented in MoonBit"
}
