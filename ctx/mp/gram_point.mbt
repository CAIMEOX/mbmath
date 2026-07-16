///|
/// Return the principal Gram point for a real index.
///
/// The index may be nonintegral. Some sufficiently negative indices select a
/// complex principal root; this real entry point then raises `ComplexResult`
/// instead of discarding its imaginary component.
pub fn MPContext::gram_point(
  self : MPContext,
  index : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(index, @mpf.RawMpf::zero()).gram_point(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  require_real_special_value(value, "gram_point")
}

///|
/// Return the principal complex Gram point satisfying
/// `riemann_siegel_theta(g) = pi * index`.
///
/// A principal Lambert-W estimate seeds a complex Newton iteration. The
/// requested precision controls both the residual tolerance and iteration
/// budget; nonconvergence is reported with `ConvergenceError`.
pub fn MPContext::complex_gram_point(
  self : MPContext,
  index : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  index.gram_point(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
