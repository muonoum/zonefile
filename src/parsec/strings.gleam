import gleam/int
import gleam/string
import gleam/yielder
import parsec.{type Message, choice, expect, fail, succeed}
import parsec/parsers.{drop, keep, many, map, some}

pub type Parser(v) =
  parsec.Parser(String, v)

pub fn parse(input: String, parser: Parser(v)) -> Result(v, Message(String)) {
  let input = {
    use state <- yielder.unfold(input)

    case string.pop_grapheme(state) {
      Error(Nil) -> yielder.Done
      Ok(#(grapheme, state)) -> yielder.Next(grapheme, state)
    }
  }

  parsec.parse(input, parser)
}

pub fn concat(parser: Parser(List(String))) -> Parser(String) {
  map(parser, string.concat)
}

pub fn present(in set: String) -> Parser(String) {
  use v <- expect
  string.contains(set, v)
}

pub fn absent(in set: String) -> Parser(String) {
  use v <- expect
  !string.contains(set, v)
}

pub fn grapheme(wanted: String) -> Parser(String) {
  use grapheme <- expect
  grapheme == wanted
}

pub fn string(wanted: String) -> Parser(String) {
  case string.pop_grapheme(wanted) {
    Error(Nil) -> succeed("")

    Ok(#(first, rest)) -> {
      use <- drop(grapheme(first))
      use <- drop(string(rest))
      succeed(wanted)
    }
  }
}

pub fn space() -> Parser(String) {
  choice(grapheme(" "), grapheme("\t"))
}

pub fn line_break() -> Parser(String) {
  choice(grapheme("\n"), grapheme("\r\n"))
}

pub fn digit() -> Parser(String) {
  present("1234567890")
}

pub fn integer() -> Parser(Int) {
  use digits <- keep(concat(some(digit())))

  case int.parse(digits) {
    Ok(int) -> succeed(int)
    Error(Nil) -> fail()
  }
}

pub fn lowercase() -> Parser(String) {
  present("abcdefghijklmnopqrstuvwxyz")
}

pub fn uppercase() -> Parser(String) {
  present("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

pub fn letter() -> Parser(String) {
  choice(lowercase(), uppercase())
}

pub fn alphanumeric() -> Parser(String) {
  choice(letter(), digit())
}

pub fn trim(parser: Parser(v)) -> Parser(v) {
  use <- drop(many(space()))
  use v <- keep(parser)
  use <- drop(many(space()))
  succeed(v)
}
