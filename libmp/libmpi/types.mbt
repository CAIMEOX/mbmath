///|
pub struct RawMpi {
  lo : @mpf.RawMpf
  hi : @mpf.RawMpf
} derive(Show, Eq)

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
} derive(Show, Eq)

///|
pub struct RawMpci {
  real : RawMpi
  imag : RawMpi
} derive(Show, Eq)

///|
pub let mpci_zero : RawMpci = { real: mpi_zero, imag: mpi_zero }

///|
pub let mpci_one : RawMpci = { real: mpi_one, imag: mpi_zero }
