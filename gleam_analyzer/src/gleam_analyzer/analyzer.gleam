import filepath
import glance.{
  type Attribute, type BinaryOperator, type BitStringSegmentOption, type Clause,
  type Constant, type CustomType, type Definition, type Expression, type Field,
  type Function, type Import, type Module, type RecordUpdateField,
  type Statement, type TypeAlias, And, Assert, Assignment, BinaryOperator,
  BitString, Block, Call, Case, Echo, Expression as StmtExpression, FieldAccess,
  Fn, FnCapture, LabelledField, Let, LetAssert, List as ExprList, NegateBool,
  NegateInt, Or, Panic, Pipe, Private, Public, RecordUpdate, ShorthandField,
  SizeValueOption, Todo, Tuple, TupleIndex, UnlabelledField, Use,
}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

pub type SourceKind {
  SrcFile
  TestFile
}

pub type SourceFile {
  SourceFile(
    path: String,
    module_name: String,
    kind: SourceKind,
    contents: String,
  )
}

pub type LineStats {
  LineStats(total: Int, code: Int, comment: Int, blank: Int, bytes: Int)
}

pub type AstWalkAcc {
  AstWalkAcc(
    statements: Int,
    use_count: Int,
    let_count: Int,
    let_assert_count: Int,
    assert_count: Int,
    ast_nodes: Int,
    case_count: Int,
    clause_count: Int,
    fn_literal_count: Int,
    pipe_count: Int,
    panic_count: Int,
    todo_count: Int,
    echo_count: Int,
    bit_string_count: Int,
    record_update_count: Int,
    branch_points: Int,
    max_depth: Int,
  )
}

pub type FunctionMetric {
  FunctionMetric(
    qualified_name: String,
    is_public: Bool,
    param_count: Int,
    ast_nodes: Int,
    branching_score: Int,
    max_depth: Int,
    span_len: Int,
    is_external: Bool,
  )
}

pub type ParseFailure {
  ParseFailure(path: String, reason: String)
}

pub type ModuleMetrics {
  ModuleMetrics(
    path: String,
    module_name: String,
    kind: SourceKind,
    lines: LineStats,
    imports: List(String),
    unqualified_imports: Int,
    custom_types: Int,
    pub_custom_types: Int,
    opaque_types: Int,
    variants: Int,
    variant_fields: Int,
    type_aliases: Int,
    pub_type_aliases: Int,
    constants: Int,
    pub_constants: Int,
    functions: Int,
    pub_functions: Int,
    external_functions: Int,
    deprecated_items: Int,
    ast_walk: AstWalkAcc,
    fn_span_sum: Int,
    function_metrics: List(FunctionMetric),
  )
}

pub type ProjectReport {
  ProjectReport(
    project_name: String,
    root_dir: String,
    src_files: Int,
    test_files: Int,
    parsed_ok: Int,
    parse_failures: List(ParseFailure),
    read_failures: List(ParseFailure),
    total_lines: LineStats,
    total_imports: Int,
    internal_imports: Int,
    external_imports: Int,
    total_unqualified_imports: Int,
    custom_types: Int,
    pub_custom_types: Int,
    opaque_types: Int,
    variants: Int,
    variant_fields: Int,
    type_aliases: Int,
    pub_type_aliases: Int,
    constants: Int,
    pub_constants: Int,
    functions: Int,
    pub_functions: Int,
    external_functions: Int,
    deprecated_items: Int,
    ast_walk: AstWalkAcc,
    total_fn_span_sum: Int,
    top_modules: List(ModuleMetrics),
    top_functions: List(FunctionMetric),
    top_imported: List(#(String, Int)),
  )
}

pub fn analyze_project(
  root_dir: String,
  src_only: Bool,
) -> Result(ProjectReport, String) {
  case simplifile.is_directory(root_dir) {
    Ok(True) -> Ok(Nil)
    _ -> Error("Target directory does not exist: " <> root_dir)
  }
  |> result.map(fn(_) {
    let project_name = read_project_name(root_dir)
    let src_paths =
      discover_gleam_files(filepath.join(root_dir, "src"), SrcFile)
    let test_paths = case src_only {
      True -> []
      False -> discover_gleam_files(filepath.join(root_dir, "test"), TestFile)
    }
    let all_entries = list.append(src_paths, test_paths)
    analyze_discovered(root_dir, project_name, all_entries)
  })
}

pub fn analyze_source_modules(
  project_name: String,
  root_dir: String,
  sources: List(SourceFile),
) -> ProjectReport {
  let internal_names =
    list.fold(sources, set.new(), fn(acc, s) { set.insert(acc, s.module_name) })

  let #(rev_modules, rev_parse_failures, src_count, test_count) =
    list.fold(sources, #([], [], 0, 0), fn(acc, source) {
      let #(mods, errs, sc, tc) = acc
      let #(next_sc, next_tc) = case source.kind {
        SrcFile -> #(sc + 1, tc)
        TestFile -> #(sc, tc + 1)
      }
      case glance.module(source.contents) {
        Ok(parsed) -> {
          let m = analyze_module(source, parsed)
          #([m, ..mods], errs, next_sc, next_tc)
        }
        Error(err) -> {
          let fail = ParseFailure(source.path, format_parse_error(err))
          #(mods, [fail, ..errs], next_sc, next_tc)
        }
      }
    })

  let modules = list.reverse(rev_modules)
  let parse_failures = list.reverse(rev_parse_failures)
  aggregate_report(
    project_name,
    root_dir,
    src_count,
    test_count,
    modules,
    parse_failures,
    [],
    internal_names,
  )
}

fn analyze_discovered(
  root_dir: String,
  project_name: String,
  entries: List(#(String, String, SourceKind)),
) -> ProjectReport {
  let internal_names =
    list.fold(entries, set.new(), fn(acc, entry) {
      let #(_, mod_name, _) = entry
      set.insert(acc, mod_name)
    })

  let #(rev_modules, rev_parse_failures, rev_read_failures, sc, tc) =
    list.fold(entries, #([], [], [], 0, 0), fn(acc, entry) {
      let #(mods, parse_errs, read_errs, src_count, test_count) = acc
      let #(full_path, mod_name, kind) = entry
      let #(next_sc, next_tc) = case kind {
        SrcFile -> #(src_count + 1, test_count)
        TestFile -> #(src_count, test_count + 1)
      }
      let rel_path = make_relative(root_dir, full_path)
      case simplifile.read(from: full_path) {
        Error(_) -> {
          let fail = ParseFailure(rel_path, "failed to read file")
          #(mods, parse_errs, [fail, ..read_errs], next_sc, next_tc)
        }
        Ok(contents) ->
          case glance.module(contents) {
            Error(err) -> {
              let fail = ParseFailure(rel_path, format_parse_error(err))
              #(mods, [fail, ..parse_errs], read_errs, next_sc, next_tc)
            }
            Ok(parsed) -> {
              let source = SourceFile(rel_path, mod_name, kind, contents)
              let m = analyze_module(source, parsed)
              #([m, ..mods], parse_errs, read_errs, next_sc, next_tc)
            }
          }
      }
    })

  aggregate_report(
    project_name,
    root_dir,
    sc,
    tc,
    list.reverse(rev_modules),
    list.reverse(rev_parse_failures),
    list.reverse(rev_read_failures),
    internal_names,
  )
}

fn read_project_name(root_dir: String) -> String {
  let toml_path = filepath.join(root_dir, "gleam.toml")
  case simplifile.read(from: toml_path) {
    Error(_) -> filepath.base_name(root_dir)
    Ok(contents) ->
      contents
      |> string.split("\n")
      |> list.find_map(extract_toml_name)
      |> result.unwrap(filepath.base_name(root_dir))
  }
}

fn extract_toml_name(line: String) -> Result(String, Nil) {
  let trimmed = string.trim(line)
  case string.starts_with(trimmed, "name") {
    False -> Error(Nil)
    True ->
      case string.split_once(trimmed, "=") {
        Error(_) -> Error(Nil)
        Ok(#(lhs, rhs)) ->
          case string.trim(lhs) == "name" {
            False -> Error(Nil)
            True -> {
              let value = string.trim(rhs)
              case
                string.starts_with(value, "\"") && string.ends_with(value, "\"")
              {
                True -> {
                  let len = string.length(value)
                  case len >= 2 {
                    True -> Ok(string.slice(value, 1, len - 2))
                    False -> Error(Nil)
                  }
                }
                False -> Error(Nil)
              }
            }
          }
      }
  }
}

fn discover_gleam_files(
  base_dir: String,
  kind: SourceKind,
) -> List(#(String, String, SourceKind)) {
  case simplifile.is_directory(base_dir) {
    Ok(True) -> walk_dir(base_dir, "", kind, []) |> list.reverse
    _ -> []
  }
}

fn walk_dir(
  dir: String,
  rel_prefix: String,
  kind: SourceKind,
  acc: List(#(String, String, SourceKind)),
) -> List(#(String, String, SourceKind)) {
  case simplifile.read_directory(at: dir) {
    Error(_) -> acc
    Ok(entries) -> {
      let sorted = list.sort(entries, string.compare)
      list.fold(sorted, acc, fn(cur_acc, entry) {
        let full = filepath.join(dir, entry)
        let rel = case rel_prefix {
          "" -> entry
          _ -> rel_prefix <> "/" <> entry
        }
        case simplifile.is_directory(full) {
          Ok(True) -> walk_dir(full, rel, kind, cur_acc)
          _ ->
            case string.ends_with(entry, ".gleam") {
              False -> cur_acc
              True -> {
                let mod_name = filepath.strip_extension(rel)
                [#(full, mod_name, kind), ..cur_acc]
              }
            }
        }
      })
    }
  }
}

fn make_relative(root_dir: String, full_path: String) -> String {
  let clean_root = case string.ends_with(root_dir, "/") {
    True -> root_dir
    False -> root_dir <> "/"
  }
  case string.starts_with(full_path, clean_root) {
    True -> string.drop_start(full_path, string.length(clean_root))
    False -> full_path
  }
}

fn format_parse_error(err: glance.Error) -> String {
  case err {
    glance.UnexpectedEndOfInput -> "unexpected end of input"
    glance.UnexpectedToken(token:, position:) ->
      "unexpected token at offset "
      <> int.to_string(position.byte_offset)
      <> ": "
      <> string.inspect(token)
  }
}

pub fn count_line_stats(src: String) -> LineStats {
  let bytes = string.byte_size(src)
  case src {
    "" -> LineStats(total: 0, code: 0, comment: 0, blank: 0, bytes: 0)
    _ -> {
      let raw_lines = string.split(src, "\n")
      let lines = case string.ends_with(src, "\n") {
        True -> drop_last_empty(raw_lines)
        False -> raw_lines
      }
      list.fold(
        lines,
        LineStats(total: 0, code: 0, comment: 0, blank: 0, bytes: bytes),
        fn(acc, line) {
          let trimmed = string.trim(line)
          case trimmed {
            "" -> LineStats(..acc, total: acc.total + 1, blank: acc.blank + 1)
            _ ->
              case string.starts_with(trimmed, "//") {
                True ->
                  LineStats(
                    ..acc,
                    total: acc.total + 1,
                    comment: acc.comment + 1,
                  )
                False ->
                  LineStats(..acc, total: acc.total + 1, code: acc.code + 1)
              }
          }
        },
      )
    }
  }
}

fn drop_last_empty(items: List(String)) -> List(String) {
  case list.reverse(items) {
    ["", ..rest] -> list.reverse(rest)
    _ -> items
  }
}

fn empty_walk() -> AstWalkAcc {
  AstWalkAcc(
    statements: 0,
    use_count: 0,
    let_count: 0,
    let_assert_count: 0,
    assert_count: 0,
    ast_nodes: 0,
    case_count: 0,
    clause_count: 0,
    fn_literal_count: 0,
    pipe_count: 0,
    panic_count: 0,
    todo_count: 0,
    echo_count: 0,
    bit_string_count: 0,
    record_update_count: 0,
    branch_points: 0,
    max_depth: 0,
  )
}

fn merge_walk(a: AstWalkAcc, b: AstWalkAcc) -> AstWalkAcc {
  AstWalkAcc(
    statements: a.statements + b.statements,
    use_count: a.use_count + b.use_count,
    let_count: a.let_count + b.let_count,
    let_assert_count: a.let_assert_count + b.let_assert_count,
    assert_count: a.assert_count + b.assert_count,
    ast_nodes: a.ast_nodes + b.ast_nodes,
    case_count: a.case_count + b.case_count,
    clause_count: a.clause_count + b.clause_count,
    fn_literal_count: a.fn_literal_count + b.fn_literal_count,
    pipe_count: a.pipe_count + b.pipe_count,
    panic_count: a.panic_count + b.panic_count,
    todo_count: a.todo_count + b.todo_count,
    echo_count: a.echo_count + b.echo_count,
    bit_string_count: a.bit_string_count + b.bit_string_count,
    record_update_count: a.record_update_count + b.record_update_count,
    branch_points: a.branch_points + b.branch_points,
    max_depth: int.max(a.max_depth, b.max_depth),
  )
}

fn analyze_module(source: SourceFile, parsed: Module) -> ModuleMetrics {
  let lines = count_line_stats(source.contents)

  let #(imp_mods, unqual_count) =
    list.fold(parsed.imports, #([], 0), fn(acc, defn: Definition(Import)) {
      let #(mods, uq) = acc
      let imp = defn.definition
      let added_uq =
        list.length(imp.unqualified_types) + list.length(imp.unqualified_values)
      #([imp.module, ..mods], uq + added_uq)
    })

  let #(ct_total, ct_pub, ct_opaque, ct_variants, ct_fields, ct_deprecated) =
    list.fold(
      parsed.custom_types,
      #(0, 0, 0, 0, 0, 0),
      fn(acc, defn: Definition(CustomType)) {
        let #(tot, pub_c, opq, vars, flds, dep) = acc
        let ct = defn.definition
        let is_pub = case ct.publicity {
          Public -> 1
          Private -> 0
        }
        let is_opq = case ct.opaque_ {
          True -> 1
          False -> 0
        }
        let v_count = list.length(ct.variants)
        let f_count =
          list.fold(ct.variants, 0, fn(f_acc, v) {
            f_acc + list.length(v.fields)
          })
        let dep_inc = count_deprecated(defn.attributes)
        #(
          tot + 1,
          pub_c + is_pub,
          opq + is_opq,
          vars + v_count,
          flds + f_count,
          dep + dep_inc,
        )
      },
    )

  let #(ta_total, ta_pub, ta_deprecated) =
    list.fold(
      parsed.type_aliases,
      #(0, 0, 0),
      fn(acc, defn: Definition(TypeAlias)) {
        let #(tot, pub_c, dep) = acc
        let is_pub = case defn.definition.publicity {
          Public -> 1
          Private -> 0
        }
        #(tot + 1, pub_c + is_pub, dep + count_deprecated(defn.attributes))
      },
    )

  let #(const_total, const_pub, const_deprecated, const_walk) =
    list.fold(
      parsed.constants,
      #(0, 0, 0, empty_walk()),
      fn(acc, defn: Definition(Constant)) {
        let #(tot, pub_c, dep, walk) = acc
        let c = defn.definition
        let is_pub = case c.publicity {
          Public -> 1
          Private -> 0
        }
        let next_walk = walk_expression(c.value, 1, walk)
        #(
          tot + 1,
          pub_c + is_pub,
          dep + count_deprecated(defn.attributes),
          next_walk,
        )
      },
    )

  let #(
    fn_total,
    fn_pub,
    fn_ext,
    fn_deprecated,
    fn_span_sum,
    fn_walk,
    rev_fn_metrics,
  ) =
    list.fold(
      parsed.functions,
      #(0, 0, 0, 0, 0, const_walk, []),
      fn(acc, defn: Definition(Function)) {
        let #(tot, pub_c, ext_c, dep, span_acc, mod_walk, f_metrics) = acc
        let f = defn.definition
        let is_pub = case f.publicity {
          Public -> True
          Private -> False
        }
        let pub_inc = case is_pub {
          True -> 1
          False -> 0
        }
        let is_ext = has_attribute(defn.attributes, "external")
        let ext_inc = case is_ext {
          True -> 1
          False -> 0
        }
        let dep_inc = count_deprecated(defn.attributes)
        let f_walk = walk_statements(f.body, 1, empty_walk())
        let span_len = int.max(0, f.location.end - f.location.start)
        let metric =
          FunctionMetric(
            qualified_name: source.module_name <> "." <> f.name,
            is_public: is_pub,
            param_count: list.length(f.parameters),
            ast_nodes: f_walk.ast_nodes,
            branching_score: 1 + f_walk.branch_points,
            max_depth: f_walk.max_depth,
            span_len: span_len,
            is_external: is_ext,
          )
        #(
          tot + 1,
          pub_c + pub_inc,
          ext_c + ext_inc,
          dep + dep_inc,
          span_acc + span_len,
          merge_walk(mod_walk, f_walk),
          [metric, ..f_metrics],
        )
      },
    )

  ModuleMetrics(
    path: source.path,
    module_name: source.module_name,
    kind: source.kind,
    lines: lines,
    imports: list.reverse(imp_mods),
    unqualified_imports: unqual_count,
    custom_types: ct_total,
    pub_custom_types: ct_pub,
    opaque_types: ct_opaque,
    variants: ct_variants,
    variant_fields: ct_fields,
    type_aliases: ta_total,
    pub_type_aliases: ta_pub,
    constants: const_total,
    pub_constants: const_pub,
    functions: fn_total,
    pub_functions: fn_pub,
    external_functions: fn_ext,
    deprecated_items: ct_deprecated
      + ta_deprecated
      + const_deprecated
      + fn_deprecated,
    ast_walk: fn_walk,
    fn_span_sum: fn_span_sum,
    function_metrics: list.reverse(rev_fn_metrics),
  )
}

fn has_attribute(attributes: List(Attribute), name: String) -> Bool {
  list.any(attributes, fn(attr) { attr.name == name })
}

fn count_deprecated(attributes: List(Attribute)) -> Int {
  case has_attribute(attributes, "deprecated") {
    True -> 1
    False -> 0
  }
}

fn walk_statements(
  stmts: List(Statement),
  depth: Int,
  acc: AstWalkAcc,
) -> AstWalkAcc {
  list.fold(stmts, acc, fn(cur, stmt) { walk_statement(stmt, depth, cur) })
}

fn walk_statement(stmt: Statement, depth: Int, acc: AstWalkAcc) -> AstWalkAcc {
  let acc1 = AstWalkAcc(..acc, statements: acc.statements + 1)
  case stmt {
    Use(function:, ..) ->
      walk_expression(
        function,
        depth,
        AstWalkAcc(..acc1, use_count: acc1.use_count + 1),
      )
    Assignment(kind:, value:, ..) -> {
      let acc2 = case kind {
        Let -> AstWalkAcc(..acc1, let_count: acc1.let_count + 1)
        LetAssert(_) ->
          AstWalkAcc(
            ..acc1,
            let_assert_count: acc1.let_assert_count + 1,
            branch_points: acc1.branch_points + 1,
          )
      }
      let acc3 = case kind {
        LetAssert(Some(msg)) -> walk_expression(msg, depth, acc2)
        _ -> acc2
      }
      walk_expression(value, depth, acc3)
    }
    Assert(expression:, message:, ..) -> {
      let acc2 =
        AstWalkAcc(
          ..acc1,
          assert_count: acc1.assert_count + 1,
          branch_points: acc1.branch_points + 1,
        )
      let acc3 = walk_expression(expression, depth, acc2)
      walk_opt_expression(message, depth, acc3)
    }
    StmtExpression(expr) -> walk_expression(expr, depth, acc1)
  }
}

fn walk_opt_expression(
  opt: Option(Expression),
  depth: Int,
  acc: AstWalkAcc,
) -> AstWalkAcc {
  case opt {
    None -> acc
    Some(expr) -> walk_expression(expr, depth, acc)
  }
}

fn walk_expression(
  expr: Expression,
  depth: Int,
  acc: AstWalkAcc,
) -> AstWalkAcc {
  let acc1 =
    AstWalkAcc(
      ..acc,
      ast_nodes: acc.ast_nodes + 1,
      max_depth: int.max(acc.max_depth, depth),
    )
  let next_depth = depth + 1
  case expr {
    glance.Int(..)
    | glance.Float(..)
    | glance.String(..)
    | glance.Variable(..) -> acc1
    NegateInt(value:, ..) | NegateBool(value:, ..) ->
      walk_expression(value, next_depth, acc1)
    Block(statements:, ..) -> walk_statements(statements, next_depth, acc1)
    Panic(message:, ..) ->
      walk_opt_expression(
        message,
        next_depth,
        AstWalkAcc(..acc1, panic_count: acc1.panic_count + 1),
      )
    Todo(message:, ..) ->
      walk_opt_expression(
        message,
        next_depth,
        AstWalkAcc(..acc1, todo_count: acc1.todo_count + 1),
      )
    Echo(expression:, message:, ..) -> {
      let acc2 = AstWalkAcc(..acc1, echo_count: acc1.echo_count + 1)
      let acc3 = walk_opt_expression(expression, next_depth, acc2)
      walk_opt_expression(message, next_depth, acc3)
    }
    Tuple(elements:, ..) -> walk_expressions(elements, next_depth, acc1)
    ExprList(elements:, rest:, ..) -> {
      let acc2 = walk_expressions(elements, next_depth, acc1)
      walk_opt_expression(rest, next_depth, acc2)
    }
    Fn(body:, ..) ->
      walk_statements(
        body,
        next_depth,
        AstWalkAcc(..acc1, fn_literal_count: acc1.fn_literal_count + 1),
      )
    RecordUpdate(record:, fields:, ..) -> {
      let acc2 =
        AstWalkAcc(..acc1, record_update_count: acc1.record_update_count + 1)
      let acc3 = walk_expression(record, next_depth, acc2)
      list.fold(fields, acc3, fn(cur, field: RecordUpdateField(Expression)) {
        walk_opt_expression(field.item, next_depth, cur)
      })
    }
    FieldAccess(container:, ..) -> walk_expression(container, next_depth, acc1)
    TupleIndex(tuple:, ..) -> walk_expression(tuple, next_depth, acc1)
    Call(function:, arguments:, ..) -> {
      let acc2 = walk_expression(function, next_depth, acc1)
      walk_fields(arguments, next_depth, acc2)
    }
    FnCapture(function:, arguments_before:, arguments_after:, ..) -> {
      let acc2 = walk_expression(function, next_depth, acc1)
      let acc3 = walk_fields(arguments_before, next_depth, acc2)
      walk_fields(arguments_after, next_depth, acc3)
    }
    BitString(segments:, ..) -> {
      let acc2 = AstWalkAcc(..acc1, bit_string_count: acc1.bit_string_count + 1)
      list.fold(segments, acc2, fn(cur, seg) {
        let #(seg_expr, opts) = seg
        let cur1 = walk_expression(seg_expr, next_depth, cur)
        list.fold(
          opts,
          cur1,
          fn(o_cur, opt: BitStringSegmentOption(Expression)) {
            case opt {
              SizeValueOption(size_expr) ->
                walk_expression(size_expr, next_depth, o_cur)
              _ -> o_cur
            }
          },
        )
      })
    }
    Case(subjects:, clauses:, ..) -> {
      let c_len = list.length(clauses)
      let acc2 =
        AstWalkAcc(
          ..acc1,
          case_count: acc1.case_count + 1,
          clause_count: acc1.clause_count + c_len,
          branch_points: acc1.branch_points + int.max(0, c_len - 1),
        )
      let acc3 = walk_expressions(subjects, next_depth, acc2)
      list.fold(clauses, acc3, fn(cur, cl: Clause) {
        let cur1 = walk_opt_expression(cl.guard, next_depth, cur)
        let cur2 = case cl.guard {
          Some(_) -> AstWalkAcc(..cur1, branch_points: cur1.branch_points + 1)
          None -> cur1
        }
        walk_expression(cl.body, next_depth, cur2)
      })
    }
    BinaryOperator(name:, left:, right:, ..) -> {
      let acc2 = update_binop_counts(name, acc1)
      let acc3 = walk_expression(left, next_depth, acc2)
      walk_expression(right, next_depth, acc3)
    }
  }
}

fn update_binop_counts(op: BinaryOperator, acc: AstWalkAcc) -> AstWalkAcc {
  case op {
    Pipe -> AstWalkAcc(..acc, pipe_count: acc.pipe_count + 1)
    And | Or -> AstWalkAcc(..acc, branch_points: acc.branch_points + 1)
    _ -> acc
  }
}

fn walk_expressions(
  exprs: List(Expression),
  depth: Int,
  acc: AstWalkAcc,
) -> AstWalkAcc {
  list.fold(exprs, acc, fn(cur, e) { walk_expression(e, depth, cur) })
}

fn walk_fields(
  fields: List(Field(Expression)),
  depth: Int,
  acc: AstWalkAcc,
) -> AstWalkAcc {
  list.fold(fields, acc, fn(cur, f) {
    case f {
      LabelledField(item:, ..) | UnlabelledField(item:) ->
        walk_expression(item, depth, cur)
      ShorthandField(..) -> cur
    }
  })
}

fn aggregate_report(
  project_name: String,
  root_dir: String,
  src_files: Int,
  test_files: Int,
  modules: List(ModuleMetrics),
  parse_failures: List(ParseFailure),
  read_failures: List(ParseFailure),
  internal_names: Set(String),
) -> ProjectReport {
  let init_lines = LineStats(0, 0, 0, 0, 0)
  let #(
    total_lines,
    imp_total,
    imp_internal,
    imp_external,
    unqual_imp,
    ct_total,
    ct_pub,
    ct_opq,
    vars,
    flds,
    ta_total,
    ta_pub,
    const_total,
    const_pub,
    fn_total,
    fn_pub,
    fn_ext,
    dep_total,
    total_walk,
    total_span_sum,
    fan_in_dict,
    all_fn_metrics,
  ) =
    list.fold(
      modules,
      #(
        init_lines,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        empty_walk(),
        0,
        dict.new(),
        [],
      ),
      fn(acc, m) {
        let #(
          l_acc,
          i_tot,
          i_int,
          i_ext,
          uq_acc,
          ct_t,
          ct_p,
          ct_o,
          v_acc,
          f_acc,
          ta_t,
          ta_p,
          c_t,
          c_p,
          fn_t,
          fn_p,
          fn_e,
          dep_acc,
          w_acc,
          sp_acc,
          fi_dict,
          fns_acc,
        ) = acc

        let next_lines =
          LineStats(
            total: l_acc.total + m.lines.total,
            code: l_acc.code + m.lines.code,
            comment: l_acc.comment + m.lines.comment,
            blank: l_acc.blank + m.lines.blank,
            bytes: l_acc.bytes + m.lines.bytes,
          )

        let #(m_int, m_ext, next_fi) =
          list.fold(m.imports, #(0, 0, fi_dict), fn(i_acc, imp_mod) {
            let #(in_c, ex_c, d) = i_acc
            case set.contains(internal_names, imp_mod) {
              True -> #(in_c + 1, ex_c, increment_dict(d, imp_mod))
              False -> #(in_c, ex_c + 1, d)
            }
          })

        #(
          next_lines,
          i_tot + m_int + m_ext,
          i_int + m_int,
          i_ext + m_ext,
          uq_acc + m.unqualified_imports,
          ct_t + m.custom_types,
          ct_p + m.pub_custom_types,
          ct_o + m.opaque_types,
          v_acc + m.variants,
          f_acc + m.variant_fields,
          ta_t + m.type_aliases,
          ta_p + m.pub_type_aliases,
          c_t + m.constants,
          c_p + m.pub_constants,
          fn_t + m.functions,
          fn_p + m.pub_functions,
          fn_e + m.external_functions,
          dep_acc + m.deprecated_items,
          merge_walk(w_acc, m.ast_walk),
          sp_acc + m.fn_span_sum,
          next_fi,
          list.append(m.function_metrics, fns_acc),
        )
      },
    )

  let top_modules =
    modules
    |> list.sort(fn(a, b) {
      case int.compare(b.ast_walk.ast_nodes, a.ast_walk.ast_nodes) {
        order.Eq -> string.compare(a.path, b.path)
        other -> other
      }
    })
    |> list.take(10)

  let top_functions =
    all_fn_metrics
    |> list.sort(fn(a, b) {
      case int.compare(b.branching_score, a.branching_score) {
        order.Eq ->
          case int.compare(b.ast_nodes, a.ast_nodes) {
            order.Eq -> string.compare(a.qualified_name, b.qualified_name)
            other -> other
          }
        other -> other
      }
    })
    |> list.take(10)

  let top_imported =
    fan_in_dict
    |> dict.to_list
    |> list.sort(fn(a, b) {
      let #(name_a, count_a) = a
      let #(name_b, count_b) = b
      case int.compare(count_b, count_a) {
        order.Eq -> string.compare(name_a, name_b)
        other -> other
      }
    })
    |> list.take(10)

  ProjectReport(
    project_name: project_name,
    root_dir: root_dir,
    src_files: src_files,
    test_files: test_files,
    parsed_ok: list.length(modules),
    parse_failures: parse_failures,
    read_failures: read_failures,
    total_lines: total_lines,
    total_imports: imp_total,
    internal_imports: imp_internal,
    external_imports: imp_external,
    total_unqualified_imports: unqual_imp,
    custom_types: ct_total,
    pub_custom_types: ct_pub,
    opaque_types: ct_opq,
    variants: vars,
    variant_fields: flds,
    type_aliases: ta_total,
    pub_type_aliases: ta_pub,
    constants: const_total,
    pub_constants: const_pub,
    functions: fn_total,
    pub_functions: fn_pub,
    external_functions: fn_ext,
    deprecated_items: dep_total,
    ast_walk: total_walk,
    total_fn_span_sum: total_span_sum,
    top_modules: top_modules,
    top_functions: top_functions,
    top_imported: top_imported,
  )
}

fn increment_dict(d: Dict(String, Int), key: String) -> Dict(String, Int) {
  let cur = dict.get(d, key) |> result.unwrap(0)
  dict.insert(d, key, cur + 1)
}
