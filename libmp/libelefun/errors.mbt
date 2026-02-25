///|
pub(all) suberror LibElefunError {
  ValueError(String)
  DomainError(String)
  ComplexResult(String)
} derive(Show, Eq)
