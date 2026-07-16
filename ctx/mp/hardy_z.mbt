///|
/// Evaluate an arbitrary nonnegative derivative of the real Hardy Riemann Z
/// function.
///
/// The implementation combines analytic Riemann-Siegel theta and zeta
/// derivatives. A negative order raises `DomainError`; any non-real result is
/// reported with `ComplexResult` instead of truncating its imaginary part.
pub fn MPContext::hardy_z(
  self : MPContext,
  t : @mpf.RawMpf,
  order? : Int = 0,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(t, @mpf.RawMpf::zero()).hardy_z(
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  require_real_special_value(value, "hardy_z")
}

///|
/// Evaluate an arbitrary nonnegative derivative of the analytic complex Hardy
/// Riemann Z function.
///
/// Both the exponential phase jet and the composed zeta jet are formed
/// analytically at the context precision. NaN and nonfinite complex arguments
/// propagate as complex NaN values.
pub fn MPContext::complex_hardy_z(
  self : MPContext,
  t : @mpc.RawMpc,
  order? : Int = 0,
) -> @mpc.RawMpc raise MPError {
  t.hardy_z(order, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
