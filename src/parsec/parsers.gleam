import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import parsec.{type Parser, fail, succeed}

pub const keep = parsec.do

pub fn drop(parser: Parser(i, a), then: fn() -> Parser(i, b)) -> Parser(i, b) {
  keep(parser, fn(_) { then() })
}

pub fn nil(parser: Parser(i, v)) -> Parser(i, Nil) {
  drop(parser, fn() { succeed(Nil) })
}

pub fn any() -> Parser(i, i) {
  parsec.expect(fn(_) { True })
}

pub fn end() -> Parser(i, Nil) {
  not_followed_by(any())
}

pub fn not_followed_by(parser: Parser(i, v)) -> Parser(i, Nil) {
  parsec.try(parsec.choice(drop(parser, fail), succeed(Nil)))
}

pub fn sequence(parsers: List(Parser(i, v))) -> Parser(i, List(v)) {
  use result, parser <- list.fold_right(parsers, succeed([]))
  use value <- keep(parser)
  use result <- map(result, _)
  [value, ..result]
}

pub fn maybe(parser: Parser(i, v)) -> Parser(i, Option(v)) {
  parsec.choice(map(parser, Some), succeed(None))
}

pub fn get(parser: Parser(i, b), until end: Parser(i, a)) -> Parser(i, b) {
  drop(not_followed_by(end), fn() { parser })
}

pub fn map(parser: Parser(i, a), mapper: fn(a) -> b) -> Parser(i, b) {
  use value <- keep(parser)
  succeed(mapper(value))
}

pub fn one_of(parsers: List(Parser(i, v))) -> Parser(i, v) {
  use result, parser <- list.fold_right(parsers, fail())
  parsec.choice(parser, result)
}

pub fn many(parser: Parser(i, v)) -> Parser(i, List(v)) {
  parsec.choice(some(parser), succeed([]))
}

pub fn some(parser: Parser(i, v)) -> Parser(i, List(v)) {
  use first <- keep(parser)
  use rest <- keep(many(parser))
  succeed([first, ..rest])
}

pub fn join(
  parser: Parser(i, List(String)),
  separator: String,
) -> Parser(i, String) {
  map(parser, string.join(_, separator))
}

pub fn unwrap(parser: Parser(i, Option(v)), or default: v) -> Parser(i, v) {
  map(parser, option.unwrap(_, default))
}

pub fn between(
  a: Parser(i, a),
  b: Parser(i, b),
  p: Parser(i, v),
) -> Parser(i, List(v)) {
  use <- drop(a)
  use v <- keep(many(get(p, until: b)))
  use <- drop(b)
  succeed(v)
}
