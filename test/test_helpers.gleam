import gleam/bool
import gleam/function.{identity}
import gleam/int
import gleam/list
import gleam/string

pub fn multi_line(string: String) -> String {
  let lines = {
    use line <- list.filter_map(string.split(string, "\n"))
    use <- bool.guard(string.trim(line) == "", Error(Nil))

    let leading = {
      use leading, string, count <- fix2

      case string {
        " " <> rest -> leading(rest, count + 1)
        string -> #(string, count)
      }
    }

    Ok(leading(line, 0))
  }

  use #(first, first_leading), rest <- deconstruct(lines, or: "")

  let rest = {
    use #(line, leading) <- list.map(rest)
    let leading = int.max(leading - first_leading, 0)
    list.repeat(" ", leading) |> string.join("") <> line
  }

  string.join([first, ..rest], "\n") <> "\n"
}

fn fix2(fun: fn(fn(a, b) -> c, a, b) -> c) -> fn(a, b) -> c {
  use a, b <- identity
  fix2(fun) |> fun(a, b)
}

fn deconstruct(
  list: List(a),
  or empty: b,
  then next: fn(a, List(a)) -> b,
) -> b {
  case list {
    [] -> empty
    [first, ..rest] -> next(first, rest)
  }
}
