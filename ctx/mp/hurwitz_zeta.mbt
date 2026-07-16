///|
/// Evaluate the Hurwitz zeta function for real arguments.
///
/// This continues `sum((a+k)^(-s), k>=0)` meromorphically in `s` and uses
/// principal powers for a negative noninteger parameter. If the principal
/// value is non-real, `MPError::ComplexResult` is raised and the caller must use
/// `complex_hurwitz_zeta`. Negative integer parameters raise `DomainError`.
pub fn MPContext::hurwitz_zeta(
  self : MPContext,
  s : @mpf.RawMpf,
  parameter : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(s, @mpf.RawMpf::zero()).hurwitz_zeta(
    @mpc.RawMpc::new(parameter, @mpf.RawMpf::zero()),
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  if !value.imag.is_zero() && !value.imag.is_nan() {
    raise ComplexResult("hurwitz_zeta: principal value is complex")
  }
  value.real
}

///|
/// Evaluate the principal complex Hurwitz zeta function.
///
/// The function has a simple pole at `s=1`. Complex and negative noninteger
/// parameters follow principal logarithm branches; negative integer parameters
/// raise `MPError::DomainError`, matching mpmath's complex-infinity semantics.
pub fn MPContext::complex_hurwitz_zeta(
  self : MPContext,
  s : @mpc.RawMpc,
  parameter : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  s.hurwitz_zeta(parameter, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
