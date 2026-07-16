///|
pub struct RawMpi {
  lo : @mpf.RawMpf
  hi : @mpf.RawMpf
} derive(Debug, Eq)

///|
let zero_interval : RawMpi = {
  lo: @mpf.RawMpf::zero(),
  hi: @mpf.RawMpf::zero(),
}

///|
pub fn RawMpi::zero() -> RawMpi {
  zero_interval
}

///|
let one_interval : RawMpi = { lo: @mpf.RawMpf::one(), hi: @mpf.RawMpf::one() }

///|
pub fn RawMpi::one() -> RawMpi {
  one_interval
}

///|
pub(all) suberror MpiError {
  ValueError(String)
  DomainError(String)
  ParseError(String)
  UnsupportedError(String)
  UnorderedError(String)
  ConvergenceError(String)
} derive(Debug, Eq)

///|
pub struct RawMpci {
  real : RawMpi
  imag : RawMpi
} derive(Debug, Eq)

///|
let zero_complex_interval : RawMpci = {
  real: zero_interval,
  imag: zero_interval,
}

///|
pub fn RawMpci::zero() -> RawMpci {
  zero_complex_interval
}

///|
let one_complex_interval : RawMpci = { real: one_interval, imag: zero_interval }

///|
pub fn RawMpci::one() -> RawMpci {
  one_complex_interval
}
