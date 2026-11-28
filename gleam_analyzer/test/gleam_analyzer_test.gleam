import gleam/io
import gleam/list
import gleam_analyzer/analyzer.{SrcFile, TestFile}
import gleam_analyzer/report
import splitter

pub fn main() -> Nil {
  analyze_sample_module_test()
  parse_error_is_recorded_test()
  splitter_operations_test()
  io.println("3 passed, no failures")
}

pub fn analyze_sample_module_test() {
  let sample_src =
    "// Header comment — Unicode arrow: →
import gleam/list.{map}
import gleam/option.{type Option, Some, None}

pub opaque type Box(a) {
  Box(value: a)
}

pub type Mode {
  Fast
  Accurate(passes: Int)
}

pub type AliasList =
  List(Int)

pub const default_limit = 10

@external(erlang, \"foo\", \"bar\")
pub fn ext_helper(x: Int) -> Int {
  x
}

pub fn compute(items: List(Int), mode: Mode) -> Int {
  use total <- list.fold(items, 0)
  let assert True = total >= 0
  case mode {
    Fast -> total + 1
    Accurate(passes:) if passes > 0 ->
      items
      |> map(fn(n) { n * passes })
      |> list.fold(0, fn(a, b) { a + b })
    _ -> 0
  }
}
"

  let sources = [
    analyzer.SourceFile(
      path: "src/sample.gleam",
      module_name: "sample",
      kind: SrcFile,
      contents: sample_src,
    ),
    analyzer.SourceFile(
      path: "test/sample_test.gleam",
      module_name: "sample_test",
      kind: TestFile,
      contents: "import sample\npub fn ok_test() { sample.default_limit }\n",
    ),
  ]

  let r = analyzer.analyze_source_modules("demo", "/tmp/demo", sources)
  assert r.src_files == 1
  assert r.test_files == 1
  assert r.parsed_ok == 2
  assert r.parse_failures == []
  assert r.total_imports == 3
  assert r.internal_imports == 1
  assert r.external_imports == 2
  assert r.custom_types == 2
  assert r.opaque_types == 1
  assert r.variants == 3
  assert r.type_aliases == 1
  assert r.constants == 1
  assert r.functions == 3
  assert r.external_functions == 1
  assert r.ast_walk.use_count == 1
  assert r.ast_walk.let_assert_count == 1
  assert r.ast_walk.case_count == 1
  assert r.ast_walk.clause_count == 3
  assert r.ast_walk.pipe_count == 2

  let formatted = report.format_report(r)
  assert formatted != ""
  Nil
}

pub fn parse_error_is_recorded_test() {
  let bad =
    analyzer.SourceFile(
      path: "src/broken.gleam",
      module_name: "broken",
      kind: SrcFile,
      contents: "pub fn broken( {",
    )
  let r = analyzer.analyze_source_modules("bad", "/tmp/bad", [bad])
  assert r.parsed_ok == 0
  assert list.length(r.parse_failures) == 1
  Nil
}

pub fn splitter_operations_test() {
  let nl = splitter.new(["\r\n", "\n"])
  assert splitter.split(nl, "hello\r\nworld\n!")
    == #("hello", "\r\n", "world\n!")
  assert splitter.split_before(nl, "abc\ndef") == #("abc", "\ndef")
  assert splitter.split_after(nl, "abc\ndef") == #("abc\n", "def")
  assert splitter.would_split(nl, "no newline") == False
  assert splitter.would_split(nl, "has\nnewline") == True
  assert splitter.split_all(nl, "a\nb\r\nc") == ["a", "b", "c"]

  let empty = splitter.new([])
  assert splitter.would_split(empty, "abc") == False
  assert splitter.split_all(empty, "abc") == ["abc"]
  assert splitter.split(empty, "abc") == #("", "", "abc")
  Nil
}
