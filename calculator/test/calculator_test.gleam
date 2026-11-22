import calculator/ast.{
  ArityMismatch, DivisionByZero, DomainError, SyntaxError, UndefinedVariable,
}
import calculator/eval.{BoundVar, DefinedFn, ValueOutcome}

pub fn arithmetic_precedence_test() {
  assert eval.eval("2 + 3 * 4") == Ok(14.0)
  assert eval.eval("(2 + 3) * 4") == Ok(20.0)
  assert eval.eval("18 / 3 - 2 * 1.5") == Ok(3.0)
  assert eval.eval("17 % 5") == Ok(2.0)
}

pub fn right_associative_power_and_unary_test() {
  assert eval.eval("2 ^ 3 ^ 2") == Ok(512.0)
  assert eval.eval("2 ^ -3") == Ok(0.125)
  assert eval.eval("-3 ^ 2") == Ok(-9.0)
  assert eval.eval("(-3) ^ 2") == Ok(9.0)
}

pub fn builtins_test() {
  assert eval.eval("sqrt(81)") == Ok(9.0)
  assert eval.eval("abs(-42)") == Ok(42.0)
  assert eval.eval("floor(3.9) + ceil(1.1)") == Ok(5.0)
  assert eval.eval("clamp(15, 0, 10)") == Ok(10.0)
  assert eval.eval("sum(1, 2, 3, 4)") == Ok(10.0)
  assert eval.eval("avg(10, 20, 30, 40)") == Ok(25.0)
}

pub fn env_let_and_user_fn_test() {
  let env0 = eval.default_env()
  let assert Ok(#(env1, DefinedFn("hypot", 2))) =
    eval.eval_stmt(env0, "fn hypot(a, b) = sqrt(a^2 + b^2)")
  let assert Ok(#(env2, BoundVar("side", 3.0))) =
    eval.eval_stmt(env1, "let side = 3")
  let assert Ok(#(_, ValueOutcome(5.0))) =
    eval.eval_stmt(env2, "hypot(side, 4)")
  Nil
}

pub fn identifier_starting_with_keyword_prefix_test() {
  let env0 = eval.default_env()
  let assert Ok(#(env1, BoundVar("letter", 7.0))) =
    eval.eval_stmt(env0, "let letter = 7")
  let assert Ok(#(_, ValueOutcome(10.0))) = eval.eval_stmt(env1, "letter + 3")
  Nil
}

pub fn error_reporting_test() {
  assert eval.eval("1 / 0") == Error(DivisionByZero)
  assert eval.eval("missing_var + 1") == Error(UndefinedVariable("missing_var"))
  assert eval.eval("min(1)") == Error(ArityMismatch("min", 2, 1))
  assert eval.eval("sqrt(-4)") == Error(DomainError("sqrt requires x >= 0"))
  assert case eval.eval("1 + * 2") {
    Error(SyntaxError(..)) -> True
    _ -> False
  }
}

pub fn extract_cli_statements_test() {
  assert eval.extract_cli_statements([
      "./calculator.exe",
      "let x = 10; x * 2",
      "sqrt(81)",
    ])
    == ["let x = 10", "x * 2", "sqrt(81)"]
  assert eval.extract_cli_statements([
      "/usr/bin/node",
      "/tmp/calculator.js",
      "2 + 2",
    ])
    == ["2 + 2"]
  assert eval.extract_cli_statements(["./calculator.exe"]) == []
}
