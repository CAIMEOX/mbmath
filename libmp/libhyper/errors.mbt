///|
pub(all) suberror LibHyperError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
} derive(Show, Eq)
