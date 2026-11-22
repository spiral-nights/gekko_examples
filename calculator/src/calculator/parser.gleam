import calculator/ast.{type CalcError, type Expr, type Stmt}
import gleam/float
import gleam/list
import gleam/result
import party.{type ParseError, type Parser, Unexpected, UserError}

fn ws() -> Parser(String, String) {
  party.many_concat(
    party.choice([
      party.char(" "),
      party.char("\t"),
      party.char("\n"),
      party.char("\r"),
    ]),
  )
}

fn ws1() -> Parser(String, String) {
  party.many1_concat(
    party.choice([
      party.char(" "),
      party.char("\t"),
      party.char("\n"),
      party.char("\r"),
    ]),
  )
}

fn lexeme(p: Parser(a, String)) -> Parser(a, String) {
  use value <- party.do(p)
  use _ <- party.do(ws())
  party.return(value)
}

fn symbol(s: String) -> Parser(String, String) {
  lexeme(party.string(s))
}

fn ident_start() -> Parser(String, String) {
  party.either(party.letter(), party.char("_"))
}

fn ident_continue() -> Parser(String, String) {
  party.either(party.alphanum(), party.char("_"))
}

fn identifier() -> Parser(String, String) {
  lexeme({
    use first <- party.do(ident_start())
    use rest <- party.do(party.many_concat(ident_continue()))
    party.return(first <> rest)
  })
}

fn keyword(kw: String) -> Parser(String, String) {
  use _ <- party.do(party.string(kw))
  use _ <- party.do(party.not(ident_continue()))
  use _ <- party.do(ws1())
  party.return(kw)
}

fn number_literal() -> Parser(Float, String) {
  lexeme({
    use whole <- party.do(party.digits())
    use frac <- party.do(
      party.perhaps({
        use _ <- party.do(party.char("."))
        party.digits()
      }),
    )
    let normalized = case frac {
      Ok(f) -> whole <> "." <> f
      Error(Nil) -> whole <> ".0"
    }
    party.try(party.return(normalized), fn(s) {
      float.parse(s)
      |> result.replace_error("Invalid float literal: " <> s)
    })
  })
}

fn paren_expr() -> Parser(Expr, String) {
  party.between(symbol("("), party.lazy(expr), symbol(")"))
}

fn call_or_var() -> Parser(Expr, String) {
  use name <- party.do(identifier())
  use args_opt <- party.do(
    party.perhaps(party.between(
      symbol("("),
      party.sep(party.lazy(expr), by: symbol(",")),
      symbol(")"),
    )),
  )
  case args_opt {
    Ok(args) -> party.return(ast.Call(name:, args:))
    Error(Nil) -> party.return(ast.Var(name))
  }
}

fn atom() -> Parser(Expr, String) {
  party.choice([
    party.map(number_literal(), ast.Number),
    paren_expr(),
    call_or_var(),
  ])
}

fn power() -> Parser(Expr, String) {
  use base <- party.do(atom())
  use exp_opt <- party.do(
    party.perhaps(party.seq(symbol("^"), party.lazy(unary))),
  )
  case exp_opt {
    Ok(exp) -> party.return(ast.Binary(ast.Pow, base, exp))
    Error(Nil) -> party.return(base)
  }
}

fn unary() -> Parser(Expr, String) {
  party.either(
    {
      use op <- party.do(party.either(
        symbol("-") |> party.map(fn(_) { ast.Neg }),
        symbol("+") |> party.map(fn(_) { ast.Pos }),
      ))
      use operand <- party.do(party.lazy(unary))
      party.return(ast.Unary(op, operand))
    },
    party.lazy(power),
  )
}

fn mul_op() -> Parser(ast.BinOp, String) {
  party.choice([
    symbol("*") |> party.map(fn(_) { ast.Mul }),
    symbol("/") |> party.map(fn(_) { ast.Div }),
    symbol("%") |> party.map(fn(_) { ast.Mod }),
  ])
}

fn term() -> Parser(Expr, String) {
  use first <- party.do(unary())
  use rest <- party.do(
    party.many({
      use op <- party.do(mul_op())
      use rhs <- party.do(unary())
      party.return(#(op, rhs))
    }),
  )
  let folded =
    list.fold(rest, first, fn(acc, pair) {
      let #(op, rhs) = pair
      ast.Binary(op, acc, rhs)
    })
  party.return(folded)
}

fn add_op() -> Parser(ast.BinOp, String) {
  party.either(
    symbol("+") |> party.map(fn(_) { ast.Add }),
    symbol("-") |> party.map(fn(_) { ast.Sub }),
  )
}

fn expr() -> Parser(Expr, String) {
  use first <- party.do(term())
  use rest <- party.do(
    party.many({
      use op <- party.do(add_op())
      use rhs <- party.do(term())
      party.return(#(op, rhs))
    }),
  )
  let folded =
    list.fold(rest, first, fn(acc, pair) {
      let #(op, rhs) = pair
      ast.Binary(op, acc, rhs)
    })
  party.return(folded)
}

fn let_stmt() -> Parser(Stmt, String) {
  use _ <- party.do(keyword("let"))
  use name <- party.do(identifier())
  use _ <- party.do(symbol("="))
  use value <- party.do(expr())
  party.return(ast.LetStmt(name:, value:))
}

fn fn_def_stmt() -> Parser(Stmt, String) {
  use _ <- party.do(keyword("fn"))
  use name <- party.do(identifier())
  use params <- party.do(party.between(
    symbol("("),
    party.sep(identifier(), by: symbol(",")),
    symbol(")"),
  ))
  use _ <- party.do(symbol("="))
  use body <- party.do(expr())
  party.return(ast.FnDefStmt(name:, params:, body:))
}

fn stmt() -> Parser(Stmt, String) {
  use _ <- party.do(ws())
  use parsed <- party.do(
    party.choice([
      let_stmt(),
      fn_def_stmt(),
      party.map(expr(), ast.EvalStmt),
    ]),
  )
  use _ <- party.do(ws())
  use _ <- party.do(party.end())
  party.return(parsed)
}

pub fn parse_expr(input: String) -> Result(Expr, CalcError) {
  let full_expr = {
    use _ <- party.do(ws())
    use e <- party.do(expr())
    use _ <- party.do(ws())
    use _ <- party.do(party.end())
    party.return(e)
  }
  party.go(full_expr, input)
  |> result.map_error(map_parse_error)
}

pub fn parse_stmt(input: String) -> Result(Stmt, CalcError) {
  party.go(stmt(), input)
  |> result.map_error(map_parse_error)
}

fn map_parse_error(err: ParseError(String)) -> CalcError {
  case err {
    Unexpected(pos:, error: found) -> {
      let detail = case found {
        "EOF" -> "unexpected end of input"
        tok -> "unexpected token '" <> tok <> "'"
      }
      ast.SyntaxError(row: pos.row, col: pos.col, detail:)
    }
    UserError(pos:, error: detail) ->
      ast.SyntaxError(row: pos.row, col: pos.col, detail:)
  }
}
