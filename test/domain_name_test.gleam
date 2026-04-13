import gleam/option.{None}
import gleeunit/should
import parsec
import zonefile/node.{Data, EmptyDomain, NamedDomain, OriginDomain, Record}
import zonefile/parser

pub fn origin_domain_test() {
  "@ CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: OriginDomain, ttl: None, class: None, type_: "CNAME", data: [
      Data(value: "alias", comment: None),
    ]),
  ])
}

pub fn empty_domain_test() {
  " CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: EmptyDomain, ttl: None, class: None, type_: "CNAME", data: [
      Data(value: "alias", comment: None),
    ]),
  ])

  "  CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: EmptyDomain, ttl: None, class: None, type_: "CNAME", data: [
      Data(value: "alias", comment: None),
    ]),
  ])

  "\tCNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(domain: EmptyDomain, ttl: None, class: None, type_: "CNAME", data: [
      Data(value: "alias", comment: None),
    ]),
  ])
}

pub fn domain_name_single_relative_label_test() {
  "foo CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("foo"),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_multiple_relative_labels_test() {
  "foo.bar CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("foo.bar"),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_single_fqdn_label_test() {
  "foo. CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("foo."),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_multiple_fqdn_labels_test() {
  "foo.bar. CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("foo.bar."),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_wildcard_test() {
  "* CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("*"),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_wildcard_relative_prefix_test() {
  "*.foo CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("*.foo"),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}

pub fn domain_name_wildcard_fqdn_prefix_test() {
  "*.foo. CNAME alias\n"
  |> parsec.parse_string(parser.nodes())
  |> should.be_ok
  |> should.equal([
    Record(
      domain: NamedDomain("*.foo."),
      ttl: None,
      class: None,
      type_: "CNAME",
      data: [
        Data(value: "alias", comment: None),
      ],
    ),
  ])
}
