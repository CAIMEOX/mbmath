///|
/// Arbitrary-precision complex value represented by real and imaginary `mpf` parts.
pub struct RawMpc {
  real : @mpf.RawMpf
  imag : @mpf.RawMpf
} derive(Debug, Eq)

///|
pub(all) suberror MpcError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ConvergenceError(String)
} derive(Debug, Eq)

///|
/// Additive identity `0 + 0j`.
pub fn RawMpc::zero() -> RawMpc {
  { real: @mpf.RawMpf::zero(), imag: @mpf.RawMpf::zero() }
}
