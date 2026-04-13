import argv
import gleam/io
import gleam/option.{None}
import gleam/string
import gleam_community/ansi
import parsec
import simplifile
import zonefile/format
import zonefile/parser

pub fn main() -> Nil {
  let assert [path] = argv.load().arguments

  case simplifile.read(path) {
    Ok(source) ->
      case parsec.parse_string(source, parser.nodes()) {
        Ok(nodes) -> {
          format.print_nodes(nodes, None, None)
          io.println_error(ansi.green("OK ") <> path)
        }

        Error(message) ->
          format.error_message(path:, source:, message:)
          |> io.println_error
      }

    Error(error) ->
      io.println_error(
        ansi.red("error: ") <> path <> ": " <> string.inspect(error),
      )
  }
}
