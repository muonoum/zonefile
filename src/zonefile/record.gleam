// TODO
pub type RecordType {
  Unknown

  //CAA
  //HTTPS
  //SRV
  //TYPE...
  A(String)
  AAAA(String)
  CNAME(String)
  MX(preference: Int, exchange: String)
  NS(String)
  PTR(String)
  TXT(List(String))

  SOA(
    mname: String,
    rname: String,
    serial: Int,
    refresh: Int,
    retry: Int,
    expire: Int,
    minimum: Int,
  )
}
