import ffi/string_scan
import gleam/list
import gleam/option.{None, Some}

/// @patch_type("splitter:splitter.Splitter")
pub type Splitter {
  Splitter(patterns: List(String))
}

/// @patch("splitter:splitter.make")
pub fn make(patterns: List(String)) -> Splitter {
  Splitter(patterns)
}

/// @patch("splitter:splitter.split")
pub fn split(splitter: Splitter, string: String) -> #(String, String, String) {
  case splitter.patterns {
    [] -> #("", "", string)
    patterns ->
      case string_scan.find_first(string, patterns) {
        None -> #(string, "", "")
        Some(#(idx, pat_len)) -> {
          let total = string_scan.utf16_length(string)
          let before = string_scan.utf16_slice(string, 0, idx)
          let delim = string_scan.utf16_slice(string, idx, pat_len)
          let after_start = idx + pat_len
          let after =
            string_scan.utf16_slice(string, after_start, total - after_start)
          #(before, delim, after)
        }
      }
  }
}

/// @patch("splitter:splitter.split_before")
pub fn split_before(splitter: Splitter, string: String) -> #(String, String) {
  case splitter.patterns {
    [] -> #("", string)
    patterns ->
      case string_scan.find_first(string, patterns) {
        None -> #(string, "")
        Some(#(idx, _pat_len)) -> {
          let total = string_scan.utf16_length(string)
          let before = string_scan.utf16_slice(string, 0, idx)
          let after = string_scan.utf16_slice(string, idx, total - idx)
          #(before, after)
        }
      }
  }
}

/// @patch("splitter:splitter.split_after")
pub fn split_after(splitter: Splitter, string: String) -> #(String, String) {
  case splitter.patterns {
    [] -> #("", string)
    patterns ->
      case string_scan.find_first(string, patterns) {
        None -> #(string, "")
        Some(#(idx, pat_len)) -> {
          let total = string_scan.utf16_length(string)
          let split_at = idx + pat_len
          let before = string_scan.utf16_slice(string, 0, split_at)
          let after =
            string_scan.utf16_slice(string, split_at, total - split_at)
          #(before, after)
        }
      }
  }
}

/// @patch("splitter:splitter.would_split")
pub fn would_split(splitter: Splitter, string: String) -> Bool {
  case splitter.patterns {
    [] -> False
    patterns ->
      case string_scan.find_first(string, patterns) {
        None -> False
        Some(_) -> True
      }
  }
}

/// @patch("splitter:splitter.split_all")
pub fn split_all(splitter: Splitter, string: String) -> List(String) {
  case splitter.patterns {
    [] -> [string]
    patterns -> split_all_loop(patterns, string, [])
  }
}

fn split_all_loop(
  patterns: List(String),
  remaining: String,
  acc: List(String),
) -> List(String) {
  case string_scan.find_first(remaining, patterns) {
    None -> list.reverse([remaining, ..acc])
    Some(#(idx, pat_len)) -> {
      let total = string_scan.utf16_length(remaining)
      let before = string_scan.utf16_slice(remaining, 0, idx)
      let after_start = idx + pat_len
      let after =
        string_scan.utf16_slice(remaining, after_start, total - after_start)
      split_all_loop(patterns, after, [before, ..acc])
    }
  }
}
