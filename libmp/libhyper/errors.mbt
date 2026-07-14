///|
pub(all) suberror LibHyperError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
} derive(Debug, Eq)

///|
pub impl Show for LibHyperError with fn output(self, logger) {
  logger.write_object(self.to_repr())
}
