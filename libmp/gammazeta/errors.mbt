///|
pub(all) suberror GammaZetaError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Debug, Eq)
