import calculator/ast.{
  type CalcError, type Expr, Add, ArityMismatch, Binary, Call, Div,
  DivisionByZero, DomainError, EvalStmt, FnDefStmt, LetStmt, Mod, Mul, Neg,
  Number, Pos, Pow, Sub, Unary, UndefinedFunction, UndefinedVariable, Var,
}
import calculator/parser
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type UserFn {
  UserFn(params: List(String), body: Expr)
}

pub type Env {
  Env(vars: Dict(String, Float), fns: Dict(String, UserFn))
}

pub type StepOutcome {
  ValueOutcome(value: Float)
  BoundVar(name: String, value: Float)
  DefinedFn(name: String, arity: Int)
}

pub fn default_env() -> Env {
  let vars =
    dict.from_list([
      #("pi", 3.141592653589793),
      #("e", 2.718281828459045),
      #("tau", 6.283185307179586),
    ])
  Env(vars:, fns: dict.new())
}

pub fn eval_expr(env: Env, expr: Expr) -> Result(Float, CalcError) {
  case expr {
    Number(n) -> Ok(n)
    Var(name) ->
      dict.get(env.vars, name)
      |> result.replace_error(UndefinedVariable(name))
    Unary(Neg, inner) -> {
      use v <- result.try(eval_expr(env, inner))
      Ok(float.negate(v))
    }
    Unary(Pos, inner) -> eval_expr(env, inner)
    Binary(op, left, right) -> {
      use lhs <- result.try(eval_expr(env, left))
      use rhs <- result.try(eval_expr(env, right))
      eval_binop(op, lhs, rhs)
    }
    Call(name:, args:) -> {
      use evaluated <- result.try(list.try_map(args, eval_expr(env, _)))
      eval_call(env, name, evaluated)
    }
  }
}

fn eval_binop(
  op: ast.BinOp,
  lhs: Float,
  rhs: Float,
) -> Result(Float, CalcError) {
  case op {
    Add -> Ok(lhs +. rhs)
    Sub -> Ok(lhs -. rhs)
    Mul -> Ok(lhs *. rhs)
    Div ->
      case rhs == 0.0 {
        True -> Error(DivisionByZero)
        False -> Ok(lhs /. rhs)
      }
    Mod ->
      case rhs == 0.0 {
        True -> Error(DivisionByZero)
        False ->
          float.modulo(lhs, by: rhs)
          |> result.replace_error(DivisionByZero)
      }
    Pow ->
      float.power(lhs, of: rhs)
      |> result.replace_error(DomainError("invalid exponentiation"))
  }
}

fn eval_call(
  env: Env,
  name: String,
  args: List(Float),
) -> Result(Float, CalcError) {
  case dict.get(env.fns, name) {
    Ok(user_fn) -> eval_user_fn(env, name, user_fn, args)
    Error(Nil) -> eval_builtin(name, args)
  }
}

fn eval_user_fn(
  env: Env,
  name: String,
  user_fn: UserFn,
  args: List(Float),
) -> Result(Float, CalcError) {
  let expected = list.length(user_fn.params)
  let got = list.length(args)
  case expected == got {
    False -> Error(ArityMismatch(name:, expected:, got:))
    True -> {
      let local_vars =
        list.zip(user_fn.params, args)
        |> list.fold(env.vars, fn(acc, pair) {
          dict.insert(acc, pair.0, pair.1)
        })
      let call_env = Env(..env, vars: local_vars)
      eval_expr(call_env, user_fn.body)
    }
  }
}

fn eval_builtin(name: String, args: List(Float)) -> Result(Float, CalcError) {
  let got = list.length(args)
  case name {
    "sqrt" ->
      case args {
        [x] ->
          float.square_root(x)
          |> result.replace_error(DomainError("sqrt requires x >= 0"))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "abs" ->
      case args {
        [x] -> Ok(float.absolute_value(x))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "floor" ->
      case args {
        [x] -> Ok(float.floor(x))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "ceil" ->
      case args {
        [x] -> Ok(float.ceiling(x))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "round" ->
      case args {
        [x] -> Ok(int.to_float(float.round(x)))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "ln" ->
      case args {
        [x] ->
          float.logarithm(x)
          |> result.replace_error(DomainError("ln requires x > 0"))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "exp" ->
      case args {
        [x] -> Ok(float.exponential(x))
        _ -> Error(ArityMismatch(name:, expected: 1, got:))
      }
    "min" ->
      case args {
        [a, b] -> Ok(float.min(a, b))
        _ -> Error(ArityMismatch(name:, expected: 2, got:))
      }
    "max" ->
      case args {
        [a, b] -> Ok(float.max(a, b))
        _ -> Error(ArityMismatch(name:, expected: 2, got:))
      }
    "pow" ->
      case args {
        [a, b] ->
          float.power(a, of: b)
          |> result.replace_error(DomainError("invalid pow arguments"))
        _ -> Error(ArityMismatch(name:, expected: 2, got:))
      }
    "clamp" ->
      case args {
        [x, lo, hi] ->
          case lo <=. hi {
            True -> Ok(float.clamp(x, min: lo, max: hi))
            False -> Error(DomainError("clamp requires min <= max"))
          }
        _ -> Error(ArityMismatch(name:, expected: 3, got:))
      }
    "sum" ->
      case args {
        [] -> Error(ArityMismatch(name:, expected: 1, got: 0))
        _ -> Ok(float.sum(args))
      }
    "avg" ->
      case args {
        [] -> Error(ArityMismatch(name:, expected: 1, got: 0))
        _ -> Ok(float.sum(args) /. int.to_float(got))
      }
    _ -> Error(UndefinedFunction(name))
  }
}

pub fn eval_stmt(
  env: Env,
  input: String,
) -> Result(#(Env, StepOutcome), CalcError) {
  use s <- result.try(parser.parse_stmt(input))
  case s {
    EvalStmt(e) -> {
      use value <- result.try(eval_expr(env, e))
      Ok(#(env, ValueOutcome(value)))
    }
    LetStmt(name:, value: e) -> {
      use value <- result.try(eval_expr(env, e))
      let next_env = Env(..env, vars: dict.insert(env.vars, name, value))
      Ok(#(next_env, BoundVar(name:, value:)))
    }
    FnDefStmt(name:, params:, body:) -> {
      let user_fn = UserFn(params:, body:)
      let next_env = Env(..env, fns: dict.insert(env.fns, name, user_fn))
      Ok(#(next_env, DefinedFn(name:, arity: list.length(params))))
    }
  }
}

pub fn eval(input: String) -> Result(Float, CalcError) {
  use expr <- result.try(parser.parse_expr(input))
  eval_expr(default_env(), expr)
}

pub fn extract_cli_statements(raw_args: List(String)) -> List(String) {
  let user_args = case raw_args {
    [_, second, ..rest] ->
      case string.ends_with(second, ".js") || string.ends_with(second, ".mjs") {
        True -> rest
        False -> [second, ..rest]
      }
    [_, ..rest] -> rest
    [] -> []
  }
  user_args
  |> list.flat_map(fn(arg) { string.split(arg, ";") })
  |> list.map(string.trim)
  |> list.filter(fn(s) { s != "" })
}
