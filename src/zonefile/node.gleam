import gleam/option.{type Option, None}

pub type Node {
  Empty(comment: Option(String))
  Origin(domain: String, comment: Option(String))
  Ttl(duration: List(Int), comment: Option(String))
  Include(path: String, origin: Option(String), comment: Option(String))

  Record(
    domain: Domain,
    ttl: Option(List(Int)),
    class: Option(String),
    type_: String,
    data: List(Data),
  )
}

pub type Domain {
  EmptyDomain
  OriginDomain
  NamedDomain(String)
}

pub type Data {
  Data(value: String, comment: Option(String))
}

pub fn non_empty_data(data: Data) -> Bool {
  case data {
    Data(value: "", comment: None) -> False
    _else -> True
  }
}
