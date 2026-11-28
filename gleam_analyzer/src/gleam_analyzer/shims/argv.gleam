import ffi/env

/// @patch("argv:argv.do")
pub fn do() -> #(String, String, List(String)) {
  case env.args() {
    [] -> #("native", "", [])
    [program, ..arguments] -> #("native", program, arguments)
  }
}
