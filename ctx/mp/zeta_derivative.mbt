///|
fn require_real_special_value(
  value : @mpc.RawMpc,
  name : StringView,
) -> @mpf.RawMpf raise MPError {
  if !value.imag.is_zero() && !value.imag.is_nan() {
    raise ComplexResult("\{name}: principal value is complex")
  }
  value.real
}

///|
/// Evaluate the `order`th derivative of the Riemann zeta function on the real
/// axis.
///
/// `order` may be any nonnegative integer. A negative order raises
/// `DomainError`; if analytic continuation produces a non-real principal value,
/// `ComplexResult` is raised instead of discarding the imaginary component.
pub fn MPContext::zeta_derivative(
  self : MPContext,
  s : @mpf.RawMpf,
  order : Int,
) -> @mpf.RawMpf raise MPError {
  if order == 0 {
    return self.zeta(s)
  }
  let value = @mpc.RawMpc::new(s, @mpf.RawMpf::zero()).zeta_derivative(
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  require_real_special_value(value, "zeta_derivative")
}

///|
/// Evaluate the `order`th derivative of the principal complex Riemann zeta
/// function.
///
/// Derivatives are taken analytically with respect to `s`; no finite-difference
/// approximation is used. Negative orders raise `DomainError`.
pub fn MPContext::complex_zeta_derivative(
  self : MPContext,
  s : @mpc.RawMpc,
  order : Int,
) -> @mpc.RawMpc raise MPError {
  if order == 0 {
    return self.complex_zeta(s)
  }
  s.zeta_derivative(order, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the `order`th derivative of the Hurwitz zeta function for real
/// arguments.
///
/// Differentiation is with respect to `s`. Negative noninteger parameters use
/// principal logarithms, so a non-real result is reported with `ComplexResult`;
/// negative integer and zero parameters raise `DomainError` for positive
/// derivative orders.
pub fn MPContext::hurwitz_zeta_derivative(
  self : MPContext,
  s : @mpf.RawMpf,
  parameter : @mpf.RawMpf,
  order : Int,
) -> @mpf.RawMpf raise MPError {
  if order == 0 {
    return self.hurwitz_zeta(s, parameter)
  }
  let value = @mpc.RawMpc::new(s, @mpf.RawMpf::zero()).hurwitz_zeta_derivative(
    @mpc.RawMpc::new(parameter, @mpf.RawMpf::zero()),
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  require_real_special_value(value, "hurwitz_zeta_derivative")
}

///|
/// Evaluate the `order`th derivative of the principal complex Hurwitz zeta
/// function with respect to `s`.
///
/// The implementation supports arbitrary complex `s` and parameters away from
/// nonpositive-integer parameter singularities. Negative orders raise
/// `DomainError` and nonconvergent asymptotic evaluation raises
/// `ConvergenceError`.
pub fn MPContext::complex_hurwitz_zeta_derivative(
  self : MPContext,
  s : @mpc.RawMpc,
  parameter : @mpc.RawMpc,
  order : Int,
) -> @mpc.RawMpc raise MPError {
  if order == 0 {
    return self.complex_hurwitz_zeta(s, parameter)
  }
  s.hurwitz_zeta_derivative(
    parameter,
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
}
