import gleam/option.{None, Some}
import gleeunit/should
import parsec/strings
import zonefile/node.{Data, OriginDomain, Record}
import zonefile/parser

pub fn parens_with_trailing_data_test() {
  "@ TXT ( 1 ) 2\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "1 ", comment: None),
      Data(value: "2", comment: None),
    ]),
  ])

  "@ TXT 1 ( 2 ) 3\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "1 ", comment: None),
      Data(value: "2 ", comment: None),
      Data(value: "3", comment: None),
    ]),
  ])

  "@ TXT 1 (2) 3\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "1 ", comment: None),
      Data(value: "2", comment: None),
      Data(value: "3", comment: None),
    ]),
  ])

  "@ TXT 1 ( 2 ) 3 ; 4\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "1 ", comment: None),
      Data(value: "2 ", comment: None),
      Data(value: "3 ", comment: Some("4")),
    ]),
  ])
}

pub fn origin_no_class_no_ttl_record_test() {
  "@ A 10.0.0.1\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "A", data: [
      Data(value: "10.0.0.1", comment: None),
    ]),
  ])
}

pub fn origin_no_class_record_test() {
  "@    300 A 10.0.0.1\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: OriginDomain,
      ttl: Some([300]),
      class: None,
      type_: "A",
      data: [
        Data(value: "10.0.0.1", comment: None),
      ],
    ),
  ])
}

pub fn origin_no_ttl_record_test() {
  "@    IN  A 10.0.0.1\n"
  |> strings.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: OriginDomain,
      ttl: None,
      class: Some("IN"),
      type_: "A",
      data: [
        Data(value: "10.0.0.1", comment: None),
      ],
    ),
  ])
}
