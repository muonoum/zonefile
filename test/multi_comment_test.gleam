import gleam/option.{None, Some}
import gleeunit/should
import muomono/parsec
import zonefile/node.{Data, OriginDomain, Record}
import zonefile/parser

pub fn multi_comment_test() {
  "@ TXT leading ; leading\n"
  |> parsec.from_string
  |> parsec.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "leading ", comment: Some("leading")),
    ]),
  ])

  "@ TXT leading ( one two ) trailing ; trailing\n"
  |> parsec.from_string
  |> parsec.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "leading ", comment: None),
      Data(value: "one two ", comment: None),
      Data(value: "trailing ", comment: Some("trailing")),
    ]),
  ])

  "@ TXT leading ( one two ) ; one two\n"
  |> parsec.from_string
  |> parsec.parse(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "TXT", data: [
      Data(value: "leading ", comment: None),
      Data(value: "one two ", comment: Some("one two")),
    ]),
  ])
}
