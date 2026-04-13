import gleam/bool
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/set
import gleam/string
import gleam_community/ansi
import parsec
import zonefile/node.{type Node}

pub fn error_message(path path, source source, message message) -> String {
  let parsec.Message(position:, error:, labels:) = message

  format_error(
    path:,
    source:,
    position:,
    message: case error {
      None -> "unknown error"
      Some(parsec.UnexpectedEnd) -> "unexpected end of input"

      Some(parsec.UnexpectedToken(token)) ->
        "unexpected " <> string.inspect(token)
    },
    hint: {
      let labels = set.to_list(labels)
      use <- bool.guard(labels == [], "")
      "expected: " <> string.join(labels, ", ")
    },
  )
}

fn format_error(
  path path,
  source source,
  position position,
  message message,
  hint hint,
) -> String {
  let #(_position, row, column) = get_position(source, position)
  let assert Ok(line) = get_line(source, row)
  let line = string.slice(line, 0, column)
  let position = int.to_string(row) <> ":" <> int.to_string(column)

  let parts = [
    ansi.red("error: ") <> message,
    "┌ " <> path <> ":" <> position,
    "│ " <> line,
    "│" <> string.repeat(" ", column) <> ansi.red("~"),
    hint,
  ]

  list.filter(parts, fn(part) { part != "" })
  |> string.join("\n")
}

fn get_line(source: String, row: Int) -> Result(String, Nil) {
  let lines = string.split(source, "\n") |> list.index_map(pair.new)
  use result, #(line, index) <- list.fold_until(over: lines, from: Error(Nil))
  use <- bool.guard(index + 1 == row, list.Stop(Ok(line)))
  list.Continue(result)
}

fn get_position(source: String, position: Int) -> #(Int, Int, Int) {
  use #(position, row, column), grapheme <- list.fold_until(
    string.to_graphemes(source),
    from: #(position, 1, 1),
  )

  case position, grapheme {
    1, _grapheme -> list.Stop(#(position, row, column))
    _position, "\n" -> list.Continue(#(position - 1, row + 1, 1))
    _position, _grapheme -> list.Continue(#(position - 1, row, column + 1))
  }
}

pub fn error_message2(message: parsec.Message(i)) -> String {
  let parsec.Message(position:, error:, labels:) = message
  let line1 = "parse error at position " <> int.to_string(position)

  let line2 = case error {
    None -> "unknown error"
    Some(parsec.UnexpectedEnd) -> "unexpected end of input"

    Some(parsec.UnexpectedToken(token)) ->
      "unexpected " <> string.inspect(token)
  }

  use <- bool.guard(set.is_empty(labels), string.join([line1, line2], "\n"))
  let expected = set.to_list(labels) |> string.join(", ")
  string.join([line1, line2, "expected: " <> expected], "\n")
}

pub fn print_nodes(
  nodes: List(Node),
  last_node last_node: Option(Node),
  last_domain last_domain: Option(String),
) -> Nil {
  case nodes {
    [] -> Nil
    [node, ..nodes] -> print_node(node, nodes, last_node:, last_domain:)
  }
}

fn format_comment(value, comment) {
  case comment {
    Some(comment) -> value <> "; " <> comment
    None -> value
  }
}

fn print_node(
  node: Node,
  nodes: List(Node),
  last_node last_node: Option(Node),
  last_domain last_domain: Option(String),
) -> Nil {
  case node, last_node {
    node.Empty(None), Some(node.Empty(None)) ->
      print_nodes(nodes, Some(node), last_domain:)

    node.Empty(comment), _last_node -> {
      io.println(format_comment("", comment))
      print_nodes(nodes, Some(node), last_domain:)
    }

    node.Origin(domain:, comment:), _last_node -> {
      io.println(format_comment("$ORIGIN " <> domain, comment))
      print_nodes(nodes, Some(node), last_domain:)
    }

    node.Ttl(duration:, comment:), _last_node -> {
      format_comment("$TTL " <> int.to_string(int.sum(duration)), comment)
      |> io.println
      print_nodes(nodes, Some(node), last_domain:)
    }

    node.Include(path:, origin: None, comment:), _last_node -> {
      format_comment("$INCLUDE " <> path, comment)
      |> io.println
      print_nodes(nodes, Some(node), last_domain:)
    }

    node.Include(path:, origin: Some(domain), comment:), _last_node -> {
      format_comment("$INCLUDE " <> path <> " " <> domain, comment)
      |> io.println
      print_nodes(nodes, Some(node), last_domain:)
    }

    node.Record(domain:, ttl:, class:, type_:, data:), _last_node -> {
      let prefix =
        [
          case domain, last_domain {
            node.EmptyDomain, None -> panic
            node.NamedDomain(name), _ -> Ok(name)
            node.OriginDomain, _ -> Ok("@")

            node.EmptyDomain, Some(domain) ->
              Ok(string.pad_end("", string.length(domain), " "))
          },
          option.map(ttl, int.sum)
            |> option.map(int.to_string)
            |> option.to_result(Nil),
          option.to_result(class, Nil),
          Ok(type_),
        ]
        |> list.filter_map(function.identity)
        |> string.join(" ")

      io.print(prefix <> " ")

      case data {
        [] -> panic
        [data] -> io.println(format_comment(data.value, data.comment))

        data -> {
          io.println("(")
          list.each(data, fn(data) {
            io.println(format_comment("    " <> data.value, data.comment))
          })
          io.println(")")
        }
      }

      print_nodes(nodes, last_node: Some(node), last_domain: case domain {
        node.EmptyDomain -> last_domain
        node.NamedDomain(domain) -> Some(domain)
        node.OriginDomain -> Some("@")
      })
    }
  }
}
