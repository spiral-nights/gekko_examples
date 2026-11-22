import gleam/int

pub type BinOp {
  Add
  Sub
  Mul
  Div
  Mod
  Pow
}

pub type UnaryOp {
  Neg
  Pos
}

pub type Expr {
  Number(Float)
  Var(String)
  Unary(UnaryOp, Expr)
  Binary(BinOp, Expr, Expr)
  Call(name: String, args: List(Expr))
}

pub type Stmt {
  EvalStmt(Expr)
  LetStmt(name: String, value: Expr)
  FnDefStmt(name: String, params: List(String), body: Expr)
}

pub type CalcError {
  SyntaxError(row: Int, col: Int, detail: String)
  UndefinedVariable(name: String)
  UndefinedFunction(name: String)
  ArityMismatch(name: String, expected: Int, got: Int)
  DivisionByZero
  DomainError(detail: String)
}

pub fn format_error(err: CalcError) -> String {
  case err {
    SyntaxError(row:, col:, detail:) ->
      "Syntax error at line "
      <> int.to_string(row)
      <> ", col "
      <> int.to_string(col)
      <> ": "
      <> detail
    UndefinedVariable(name:) -> "Undefined variable: " <> name
    UndefinedFunction(name:) -> "Undefined function: " <> name
    ArityMismatch(name:, expected:, got:) ->
      "Function '"
      <> name
      <> "' expects "
      <> int.to_string(expected)
      <> " argument(s), got "
      <> int.to_string(got)
    DivisionByZero -> "Division by zero"
    DomainError(detail:) -> "Domain error: " <> detail
  }
}
