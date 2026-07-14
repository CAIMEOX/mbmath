///|
pub(all) suberror GammaZetaError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Debug, Eq)

///|
pub impl Show for GammaZetaError with fn output(self, logger) {
  logger.write_object(self.to_repr())
}
