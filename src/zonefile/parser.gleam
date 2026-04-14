import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import parsec.{fail, label, succeed, try}

import parsec/parsers.{
  any, between, drop, end, get, keep, many, maybe, one_of, some, unwrap,
}

import parsec/strings.{
  type Parser, absent, alphanumeric, concat, grapheme, integer, letter,
  line_break, present, space, string, trim,
}

import zonefile/node.{
  type Data, type Domain, type Node, Data, Empty, EmptyDomain, Include,
  NamedDomain, Origin, OriginDomain, Record, Ttl,
}

pub fn nodes() -> Parser(List(Node)) {
  let node = [try(directive()), try(empty_line()), record()]
  use nodes <- keep(many(one_of(node)))
  use <- drop(end())
  succeed(nodes)
}

// common

fn comment() -> Parser(String) {
  use <- drop(grapheme(";"))
  trim(concat(many(get(any(), until: line_break()))))
}

fn line_suffix() -> Parser(Option(String)) {
  use <- drop(many(space()))
  use comment <- keep(maybe(comment()))
  use <- drop(line_break())
  succeed(comment)
}

fn quoted_string() -> Parser(String) {
  let quote = grapheme("\"")
  let quoted = one_of([try(string("\\\"")), absent("\"")])
  use value <- keep(concat(between(quote, quote, quoted)))
  succeed("\"" <> value <> "\"")
}

// TODO
fn file_name() -> Parser(String) {
  concat(some(one_of([alphanumeric(), present("./_-")])))
}

fn domain_name() -> Parser(String) {
  one_of([wildcard(), concat(some(domain_label()))])
}

fn wildcard() -> Parser(String) {
  use wildcard <- keep(grapheme("*"))

  use labels <- keep(
    maybe({
      use dot <- keep(grapheme("."))
      use labels <- keep(concat(some(domain_label())))
      succeed(dot <> labels)
    }),
  )

  succeed(wildcard <> option.unwrap(labels, or: ""))
}

fn domain_label() -> Parser(String) {
  use underscore <- keep(unwrap(maybe(grapheme("_")), or: ""))
  use first <- keep(alphanumeric())
  use rest <- keep(concat(many(one_of([alphanumeric(), grapheme("-")]))))
  use trailing <- keep(unwrap(maybe(grapheme(".")), or: ""))
  succeed(underscore <> first <> rest <> trailing)
}

// empty line

fn empty_line() -> Parser(Node) {
  use comment <- keep(line_suffix())
  succeed(Empty(comment:))
}

// directive

fn directive() -> Parser(Node) {
  use <- drop(many(space()))
  use <- drop(grapheme("$"))
  let node = [origin_directive(), ttl_directive(), include_directive()]
  use directive <- keep(one_of(node))
  use comment <- keep(line_suffix())
  succeed(directive(comment))
}

fn origin_directive() -> Parser(fn(Option(String)) -> Node) {
  use <- drop(string("ORIGIN"))
  use <- drop(some(space()))
  use domain <- keep(domain_name())
  succeed(Origin(domain:, comment: _))
}

fn ttl_directive() -> Parser(fn(Option(String)) -> Node) {
  use <- drop(string("TTL"))
  use <- drop(some(space()))
  use duration <- keep(some(duration()))
  succeed(Ttl(duration:, comment: _))
}

fn include_directive() -> Parser(fn(Option(String)) -> Node) {
  use <- drop(string("INCLUDE"))
  use <- drop(some(space()))
  use <- drop(grapheme("\""))
  use path <- keep(file_name())
  use <- drop(grapheme("\""))
  use origin <- keep(maybe(try(drop(some(space()), domain_name))))
  succeed(Include(path:, origin:, comment: _))
}

// record

pub fn record() -> Parser(Node) {
  use domain <- keep(label(record_domain(), "domain"))
  use #(ttl, class) <- keep(record_ttl_and_class())
  use type_ <- keep(label(record_type(), type_label(ttl, class)))
  use data <- keep(record_data())

  // TODO?
  let data = list.filter(data, node.non_empty_data)
  use <- bool.guard(data == [], fail())
  succeed(Record(domain:, ttl:, class:, type_:, data:))
}

fn type_label(ttl: Option(List(Int)), class: Option(String)) -> String {
  case ttl, class {
    None, None -> "class, ttl or type"
    None, Some(..) -> "ttl or type"
    Some(..), None -> "class or type"
    Some(..), Some(..) -> "type"
  }
}

// domain

fn record_domain() -> Parser(Domain) {
  one_of([origin_domain(), named_domain(), empty_domain()])
}

fn named_domain() -> Parser(Domain) {
  use name <- keep(domain_name())
  use <- drop(some(space()))
  succeed(NamedDomain(name))
}

fn origin_domain() -> Parser(Domain) {
  use <- drop(grapheme("@"))
  use <- drop(some(space()))
  succeed(OriginDomain)
}

fn empty_domain() -> Parser(Domain) {
  use <- drop(concat(some(space())))
  succeed(EmptyDomain)
}

// ttl and class

fn record_ttl_and_class() -> Parser(#(Option(List(Int)), Option(String))) {
  one_of([
    try(ttl_and_class()),
    try(class_and_ttl()),
    ttl_only(),
    class_only(),
    succeed(#(None, None)),
  ])
}

fn record_ttl() -> Parser(List(Int)) {
  use duration <- keep(some(duration()))
  use <- drop(some(space()))
  succeed(duration)
}

fn record_class() -> Parser(String) {
  use class <- keep(string("IN"))
  use <- drop(some(space()))
  succeed(class)
}

fn ttl_and_class() -> Parser(#(Option(List(Int)), Option(String))) {
  use ttl <- keep(record_ttl())
  use class <- keep(record_class())
  succeed(#(Some(ttl), Some(class)))
}

fn class_and_ttl() -> Parser(#(Option(List(Int)), Option(String))) {
  use class <- keep(record_class())
  use ttl <- keep(record_ttl())
  succeed(#(Some(ttl), Some(class)))
}

fn ttl_only() -> Parser(#(Option(List(Int)), Option(a))) {
  use ttl <- keep(record_ttl())
  succeed(#(Some(ttl), None))
}

fn class_only() -> Parser(#(Option(a), Option(String))) {
  use class <- keep(record_class())
  succeed(#(None, Some(class)))
}

// type

fn record_type() -> Parser(String) {
  use first <- keep(letter())
  use rest <- keep(concat(many(alphanumeric())))
  use <- drop(some(space()))
  succeed(first <> rest)
}

// duration

fn duration() -> Parser(Int) {
  use seconds <- keep(integer())

  let unit = fn(set, multiplier) {
    use <- drop(present(set))
    succeed(multiplier)
  }

  use multiplier <- keep(
    maybe({
      one_of([
        unit("sS", 1),
        unit("mM", 60),
        unit("hH", 60 * 60),
        unit("dD", 60 * 60 * 24),
        unit("wW", 60 * 60 * 24 * 7),
      ])
    }),
  )

  succeed(seconds * option.unwrap(multiplier, 1))
}

fn record_data() -> Parser(List(Data)) {
  let until = one_of([grapheme("("), grapheme(";"), line_break()])
  use leading <- keep(data_value(until:))
  one_of([multi_line_data(leading), single_line_data(leading)])
}

fn single_line_data(value: String) -> Parser(List(Data)) {
  use <- drop(many(space()))
  use comment <- keep(maybe(comment()))
  use <- drop(line_break())
  succeed([Data(value:, comment:)])
}

fn multi_line_data(value: String) -> Parser(List(Data)) {
  use <- drop(grapheme("("))
  let inside = data_line(until: [grapheme(")"), grapheme(";")])
  use data <- keep(many(get(inside, until: grapheme(")"))))
  use <- drop(grapheme(")"))
  use data <- keep(trailing_data(data))
  leading_data(value, data)
}

// TODO?
fn trailing_data(data: List(Data)) -> Parser(List(Data)) {
  use trailing <- keep(data_line(until: [grapheme(";")]))

  succeed(case trailing.value, list.reverse(data) {
    "", [Data(value:, comment: None), ..rest] ->
      // data ) ; comment --> (data, comment)
      list.reverse([Data(..trailing, value:), ..rest])

    "", _data -> panic
    _other, _wise -> list.append(data, [trailing])
  })
}

// TODO?
fn leading_data(value: String, data: List(Data)) -> Parser(List(Data)) {
  case value, data {
    "", _data -> succeed(data)
    value, [Data(value: "", ..) as first, ..rest] ->
      // data ( ; comment --> (data, comment)
      succeed([Data(..first, value:), ..rest])

    value, _data -> succeed([Data(value:, comment: None), ..data])
    // _other, _wise -> panic
  }
}

fn data_line(until ends: List(Parser(String))) -> Parser(Data) {
  use value <- keep(data_value(until: one_of([line_break(), ..ends])))
  use <- drop(many(space()))
  use comment <- keep(maybe(comment()))
  use <- drop(maybe(line_break()))
  succeed(Data(value:, comment:))
}

fn data_value(until until: Parser(v)) -> Parser(String) {
  trim(concat(many(get(one_of([quoted_string(), any()]), until:))))
}
