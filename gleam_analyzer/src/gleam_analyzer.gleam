import argv
import gleam/int
import gleam/io
import gleam/result
import gleam_analyzer/analyzer
import gleam_analyzer/report

type CliOptions {
  CliOptions(target_dir: String, repeat: Int, src_only: Bool)
}

fn parse_args(args: List(String)) -> Result(CliOptions, String) {
  parse_args_loop(args, CliOptions(target_dir: ".", repeat: 1, src_only: False))
}

fn parse_args_loop(
  args: List(String),
  opts: CliOptions,
) -> Result(CliOptions, String) {
  case args {
    [] -> Ok(opts)
    ["--src-only", ..rest] ->
      parse_args_loop(rest, CliOptions(..opts, src_only: True))
    ["--repeat", raw_n, ..rest] ->
      case int.parse(raw_n) {
        Ok(n) if n >= 1 -> parse_args_loop(rest, CliOptions(..opts, repeat: n))
        _ ->
          Error("Invalid --repeat value (expected positive integer): " <> raw_n)
      }
    ["--repeat"] -> Error("Missing value after --repeat")
    ["--help", ..] | ["-h", ..] ->
      Error("Usage: gleam_analyzer [--src-only] [--repeat <N>] [target_dir]")
    [flag, ..] if flag == "--" -> parse_args_loop([], opts)
    [arg, ..rest] ->
      case arg {
        "-" <> _ -> Error("Unknown option: " <> arg)
        _ -> parse_args_loop(rest, CliOptions(..opts, target_dir: arg))
      }
  }
}

fn run_repeats(
  remaining: Int,
  opts: CliOptions,
) -> Result(analyzer.ProjectReport, String) {
  use res <- result.try(analyzer.analyze_project(opts.target_dir, opts.src_only))
  case remaining <= 1 {
    True -> Ok(res)
    False -> run_repeats(remaining - 1, opts)
  }
}

pub fn main() -> Nil {
  let args = argv.load().arguments
  case parse_args(args) {
    Error(msg) -> io.println_error(msg)
    Ok(opts) ->
      case run_repeats(opts.repeat, opts) {
        Error(err) -> io.println_error("Error: " <> err)
        Ok(res) -> io.println(report.format_report(res))
      }
  }
}
