///|
/// Evaluate the real principal-value exponential integral `Ei(x)`.
pub fn MPContext::exponential_integral_ei(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.ei(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the real cosine integral for a nonnegative argument.
///
/// Negative real arguments have a complex principal value and therefore raise
/// `ComplexResult`; use `complex_cosine_integral` for that branch.
pub fn MPContext::cosine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.ci(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the real sine integral.
pub fn MPContext::sine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.si(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the principal complex exponential integral `Ei(z)`.
pub fn MPContext::complex_exponential_integral_ei(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.ei(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the principal complex exponential integral `E1(z)`.
pub fn MPContext::complex_exponential_integral_e1(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.e1(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the principal complex cosine integral.
pub fn MPContext::complex_cosine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.ci(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the entire complex sine integral.
pub fn MPContext::complex_sine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.si(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
