///|
/// Evaluate the prime zeta function for a real argument.
///
/// For `x > 1`, this equals the convergent sum over primes
/// `sum(p^(-x))`. The principal analytic continuation is used for
/// `0 < x <= 1`; if that continuation is non-real, this method raises
/// `MPError::ComplexResult` and the caller must use `complex_prime_zeta`.
/// The point `x=1` is positive infinity, `+inf` maps to zero, and non-positive
/// inputs raise `MPError::DomainError`.
pub fn MPContext::prime_zeta(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).prime_zeta(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  if !value.imag.is_zero() && !value.imag.is_nan() {
    raise ComplexResult("prime_zeta: continuation is complex")
  }
  value.real
}

///|
/// Evaluate the principal analytic continuation of the prime zeta function.
///
/// The domain is `Re(s) > 0`. For `Re(s) > 1`, the result is the sum of
/// `p^(-s)` over all primes. Elsewhere it is evaluated by Mobius inversion of
/// `log(zeta(k*s))`, with principal logarithm branches and signed infinities at
/// reciprocal square-free singularities.
pub fn MPContext::complex_prime_zeta(
  self : MPContext,
  s : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  s.prime_zeta(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
