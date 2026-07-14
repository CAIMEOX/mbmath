///|
pub struct RawMpi {
  lo : @mpf.RawMpf
  hi : @mpf.RawMpf
} derive(Debug, Eq)

///|
pub impl Show for RawMpi with fn output(self, logger) {
  logger.write_object(self.to_repr())
}

///|
pub let mpi_zero : RawMpi = { lo: @mpf.fzero, hi: @mpf.fzero }

///|
pub let mpi_one : RawMpi = { lo: @mpf.fone, hi: @mpf.fone }

///|
pub(all) suberror MpiError {
  ValueError(String)
  DomainError(String)
  ParseError(String)
  UnsupportedError(String)
  UnorderedError(String)
} derive(Debug, Eq)

///|
pub impl Show for MpiError with fn output(self, logger) {
  logger.write_object(self.to_repr())
}

///|
pub struct RawMpci {
  real : RawMpi
  imag : RawMpi
} derive(Debug, Eq)

///|
pub impl Show for RawMpci with fn output(self, logger) {
  logger.write_object(self.to_repr())
}

///|
pub let mpci_zero : RawMpci = { real: mpi_zero, imag: mpi_zero }

///|
pub let mpci_one : RawMpci = { real: mpi_one, imag: mpi_zero }
