///|
pub(all) suberror GammaZetaError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ConvergenceError(String)
} derive(Debug, Eq)
