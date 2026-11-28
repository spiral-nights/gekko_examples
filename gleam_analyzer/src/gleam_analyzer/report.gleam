import gleam/int
import gleam/list
import gleam/string
import gleam_analyzer/analyzer.{
  type FunctionMetric, type ModuleMetrics, type ParseFailure, type ProjectReport,
}

pub fn format_report(r: ProjectReport) -> String {
  let header = [
    "=== Gleam Project Analysis: " <> r.project_name <> " ===",
    "Root: " <> r.root_dir,
    "Files discovered: "
      <> int.to_string(r.src_files + r.test_files)
      <> " (src: "
      <> int.to_string(r.src_files)
      <> ", test: "
      <> int.to_string(r.test_files)
      <> ")",
    "Parsed OK: "
      <> int.to_string(r.parsed_ok)
      <> " | Parse errors: "
      <> int.to_string(list.length(r.parse_failures))
      <> " | Read errors: "
      <> int.to_string(list.length(r.read_failures)),
  ]

  let source_stats = [
    "",
    "[Source Stats]",
    "Lines: "
      <> int.to_string(r.total_lines.total)
      <> " (code: "
      <> int.to_string(r.total_lines.code)
      <> ", comment: "
      <> int.to_string(r.total_lines.comment)
      <> ", blank: "
      <> int.to_string(r.total_lines.blank)
      <> ")",
    "UTF-8 bytes: " <> int.to_string(r.total_lines.bytes),
  ]

  let decls = [
    "",
    "[Declarations]",
    "Imports: "
      <> int.to_string(r.total_imports)
      <> " (internal: "
      <> int.to_string(r.internal_imports)
      <> ", external: "
      <> int.to_string(r.external_imports)
      <> ", unqualified items: "
      <> int.to_string(r.total_unqualified_imports)
      <> ")",
    "Custom types: "
      <> int.to_string(r.custom_types)
      <> " (pub: "
      <> int.to_string(r.pub_custom_types)
      <> ", opaque: "
      <> int.to_string(r.opaque_types)
      <> ", variants: "
      <> int.to_string(r.variants)
      <> ", fields: "
      <> int.to_string(r.variant_fields)
      <> ")",
    "Type aliases: "
      <> int.to_string(r.type_aliases)
      <> " (pub: "
      <> int.to_string(r.pub_type_aliases)
      <> ")",
    "Constants: "
      <> int.to_string(r.constants)
      <> " (pub: "
      <> int.to_string(r.pub_constants)
      <> ")",
    "Functions: "
      <> int.to_string(r.functions)
      <> " (pub: "
      <> int.to_string(r.pub_functions)
      <> ", priv: "
      <> int.to_string(r.functions - r.pub_functions)
      <> ", @external: "
      <> int.to_string(r.external_functions)
      <> ")",
    "Deprecated items: " <> int.to_string(r.deprecated_items),
  ]

  let w = r.ast_walk
  let ast_section = [
    "",
    "[AST & Expression Metrics]",
    "Statements: "
      <> int.to_string(w.statements)
      <> " (let: "
      <> int.to_string(w.let_count)
      <> ", let assert: "
      <> int.to_string(w.let_assert_count)
      <> ", use: "
      <> int.to_string(w.use_count)
      <> ", assert: "
      <> int.to_string(w.assert_count)
      <> ")",
    "AST expression nodes: "
      <> int.to_string(w.ast_nodes)
      <> " (max depth: "
      <> int.to_string(w.max_depth)
      <> ")",
    "Control flow: case="
      <> int.to_string(w.case_count)
      <> ", clauses="
      <> int.to_string(w.clause_count)
      <> ", pipes="
      <> int.to_string(w.pipe_count)
      <> ", fn closures="
      <> int.to_string(w.fn_literal_count),
    "Special exprs: panic="
      <> int.to_string(w.panic_count)
      <> ", todo="
      <> int.to_string(w.todo_count)
      <> ", echo="
      <> int.to_string(w.echo_count)
      <> ", bit_array="
      <> int.to_string(w.bit_string_count)
      <> ", record_update="
      <> int.to_string(w.record_update_count),
    "Total function span sum: " <> int.to_string(r.total_fn_span_sum),
  ]

  let top_mods_section =
    ["", "[Top Modules by AST Size]"]
    |> list.append(format_numbered(r.top_modules, format_module_line))

  let top_fns_section =
    ["", "[Top Functions by Branching Score]"]
    |> list.append(format_numbered(r.top_functions, format_function_line))

  let top_imp_section =
    ["", "[Most Imported Internal Modules]"]
    |> list.append(format_numbered(r.top_imported, format_imported_line))

  let err_section = case r.parse_failures, r.read_failures {
    [], [] -> []
    p_errs, r_errs ->
      ["", "[Errors]"]
      |> list.append(list.map(r_errs, format_error_line("read", _)))
      |> list.append(list.map(p_errs, format_error_line("parse", _)))
  }

  [
    header,
    source_stats,
    decls,
    ast_section,
    top_mods_section,
    top_fns_section,
    top_imp_section,
    err_section,
  ]
  |> list.flatten
  |> string.join("\n")
}

fn format_numbered(items: List(a), render: fn(a) -> String) -> List(String) {
  case items {
    [] -> ["  (none)"]
    _ ->
      items
      |> list.index_map(fn(item, idx) {
        "  " <> int.to_string(idx + 1) <> ". " <> render(item)
      })
  }
}

fn format_module_line(m: ModuleMetrics) -> String {
  m.path
  <> " | ast_nodes="
  <> int.to_string(m.ast_walk.ast_nodes)
  <> " | lines="
  <> int.to_string(m.lines.total)
  <> " | fns="
  <> int.to_string(m.functions)
  <> " | types="
  <> int.to_string(m.custom_types)
}

fn format_function_line(f: FunctionMetric) -> String {
  let vis = case f.is_public {
    True -> "pub"
    False -> "priv"
  }
  f.qualified_name
  <> " ("
  <> vis
  <> ", params="
  <> int.to_string(f.param_count)
  <> ") | branch="
  <> int.to_string(f.branching_score)
  <> " | ast_nodes="
  <> int.to_string(f.ast_nodes)
  <> " | depth="
  <> int.to_string(f.max_depth)
}

fn format_imported_line(entry: #(String, Int)) -> String {
  let #(mod_name, count) = entry
  mod_name <> " | imported_by=" <> int.to_string(count)
}

fn format_error_line(kind: String, err: ParseFailure) -> String {
  "  [" <> kind <> "] " <> err.path <> ": " <> err.reason
}
