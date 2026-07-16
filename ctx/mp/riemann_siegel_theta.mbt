///|
/// Evaluate an arbitrary nonnegative derivative of the real Riemann-Siegel
/// theta function.
///
/// `order=0` returns the function itself. Positive orders are evaluated
/// analytically through complex polygamma values; a negative order raises
/// `DomainError`.
pub fn MPContext::riemann_siegel_theta(
  self : MPContext,
  t : @mpf.RawMpf,
  order? : Int = 0,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(t, @mpf.RawMpf::zero()).riemann_siegel_theta(
    order,
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  require_real_special_value(value, "riemann_siegel_theta")
}

///|
/// Evaluate an arbitrary nonnegative derivative of the analytic complex
/// Riemann-Siegel theta function.
///
/// The log-gamma branches follow the same principal analytic continuation as
/// the complex zeta and gamma APIs. NaN propagates; real infinities follow the
/// limiting theta derivative semantics.
pub fn MPContext::complex_riemann_siegel_theta(
  self : MPContext,
  t : @mpc.RawMpc,
  order? : Int = 0,
) -> @mpc.RawMpc raise MPError {
  t.riemann_siegel_theta(order, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
