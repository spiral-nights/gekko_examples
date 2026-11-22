import calculator/ast.{type CalcError}
import calculator/eval.{type StepOutcome, BoundVar, DefinedFn, ValueOutcome}
import ffi/env
import gleam/float
import gleam/int
import gleam/io
import gleam/list

pub fn run_program(lines: List(String)) -> List(String) {
  let #(_, rev_output) =
    list.fold(lines, #(eval.default_env(), []), fn(acc, line) {
      let #(env, out) = acc
      case eval.eval_stmt(env, line) {
        Ok(#(next_env, outcome)) -> #(next_env, [
          format_step(line, outcome),
          ..out
        ])
        Error(err) -> #(env, [format_err_step(line, err), ..out])
      }
    })
  list.reverse(rev_output)
}

fn format_step(line: String, outcome: StepOutcome) -> String {
  let rendered = case outcome {
    ValueOutcome(v) -> "= " <> float.to_string(v)
    BoundVar(name:, value:) -> name <> " = " <> float.to_string(value)
    DefinedFn(name:, arity:) ->
      "defined " <> name <> "/" <> int.to_string(arity)
  }
  line <> "  =>  " <> rendered
}

fn format_err_step(line: String, err: CalcError) -> String {
  line <> "  =>  ERROR: " <> ast.format_error(err)
}

pub fn main() -> Nil {
  case eval.extract_cli_statements(env.args()) {
    [] -> {
      let program = [
        "fn hypot(a, b) = sqrt(a^2 + b^2)",
        "fn circle_area(r) = pi * r^2",
        "fn quadratic_disc(a, b, c) = b^2 - 4 * a * c",
        "let radius = 5",
        "circle_area(radius)",
        "hypot(3, 4)",
        "avg(10, 20, 30, 40)",
        "2 ^ 3 ^ 2",
        "clamp(quadratic_disc(1, -5, 6), 0, 10)",
        "10 / (5 - 5)",
        "let broken = 1 + * 2",
      ]
      io.println("=== calculator (Pure Gleam + party parser combinators) ===")
      list.each(run_program(program), io.println)
    }
    cli_stmts -> list.each(run_program(cli_stmts), io.println)
  }
}
