///|
pub(all) suberror GammaZetaError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Show, Eq)
