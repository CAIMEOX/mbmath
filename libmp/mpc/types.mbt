///|
/// Stage-0 placeholder for complex arbitrary-precision values.
pub struct RawMpc {
  real : @mpf.RawMpf
  imag : @mpf.RawMpf
} derive(Show, Eq)

///|
pub(all) suberror MpcError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Show, Eq)

///|
/// Additive identity `0 + 0j`.
pub fn zero() -> RawMpc {
  { real: @mpf.fzero, imag: @mpf.fzero }
}
