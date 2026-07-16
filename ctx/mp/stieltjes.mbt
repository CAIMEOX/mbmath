///|
/// Evaluate the generalized Stieltjes constant of nonnegative `order` for a
/// real Hurwitz parameter.
///
/// The default parameter is one, giving the ordinary Stieltjes constants. A
/// negative noninteger parameter may have a non-real principal value; in that
/// case this real entry point raises `ComplexResult`. Nonpositive integer
/// parameters and negative orders raise `DomainError`.
pub fn MPContext::stieltjes_constant(
  self : MPContext,
  order : Int,
  parameter? : @mpf.RawMpf = @mpf.RawMpf::one(),
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(parameter, @mpf.RawMpf::zero()).stieltjes_constant(
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  if !value.imag.is_zero() && !value.imag.is_nan() {
    raise ComplexResult("stieltjes_constant: principal value is complex")
  }
  value.real
}

///|
/// Evaluate the generalized principal complex Stieltjes constant.
///
/// These are the Laurent coefficients of `zeta(s, a)` after its pole at
/// `s=1` has been removed. The implementation removes the pole analytically;
/// it does not evaluate zeta at two nearby points and subtract large values.
pub fn MPContext::complex_stieltjes_constant(
  self : MPContext,
  order : Int,
  parameter? : @mpc.RawMpc = @mpc.RawMpc::one(),
) -> @mpc.RawMpc raise MPError {
  parameter.stieltjes_constant(order, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
