import gleam/int
import gleam/option.{type Option}
import gleam/string

import parsec.{
  type StringParser as Parser, choice, drop, expect, fail, get, grapheme, keep,
  many, map, some, succeed,
}

pub fn trim(parser: Parser(v)) -> Parser(v) {
  use <- drop(many(space()))
  use v <- keep(parser)
  use <- drop(many(space()))
  succeed(v)
}

pub fn concat(parser: Parser(List(String))) -> Parser(String) {
  map(parser, string.concat)
}

pub fn unwrap(parser: Parser(Option(v)), or default: v) -> Parser(v) {
  map(parser, option.unwrap(_, default))
}

pub fn present(set: String) -> Parser(String) {
  use v <- expect
  string.contains(set, v)
}

pub fn absent(set: String) -> Parser(String) {
  use v <- expect
  !string.contains(set, v)
}

pub fn between(a: Parser(a), b: Parser(b), p: Parser(v)) -> Parser(List(v)) {
  use <- drop(a)
  use v <- keep(many(get(p, until: b)))
  use <- drop(b)
  succeed(v)
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
