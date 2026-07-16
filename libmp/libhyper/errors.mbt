///|
pub(all) suberror LibHyperError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
  ConvergenceError(String)
} derive(Debug, Eq)
