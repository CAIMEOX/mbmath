///|
pub(all) suberror LibElefunError {
  ValueError(String)
  DomainError(String)
  ComplexResult(String)
} derive(Debug, Eq)

///|
pub impl Show for LibElefunError with fn output(self, logger) {
  logger.write_object(self.to_repr())
}
