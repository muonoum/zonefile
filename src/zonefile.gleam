import argv
import filepath
import gleam/bool
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/string
import gleam_community/ansi
import parsec/strings
import simplifile
import zonefile/format
import zonefile/parser

pub fn main() -> Nil {
  let assert [path] = argv.load().arguments
  let assert Ok(is_file) = simplifile.is_file(path)
  use <- bool.guard(is_file, read(path))
  let assert Ok(dir) = simplifile.read_directory(path)
  use file <- list.each(dir)
  read(filepath.join(path, file))
}

fn read(path: String) -> Nil {
  case simplifile.read(path) {
    Ok(source) ->
      case strings.parse(source, parser.nodes()) {
        Ok(nodes) -> {
          format.print_nodes(nodes, last_node: None, last_domain: None)
          io.println_error(ansi.green("ok ") <> path)
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
