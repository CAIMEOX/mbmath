///|
/// Evaluate the Gaussian error function on the real axis.
pub fn MPContext::error_function(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.erf(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the complementary Gaussian error function on the real axis.
///
/// This method computes the positive tail directly, so values such as
/// `complementary_error_function(50)` remain meaningful instead of rounding to
/// zero through `1 - error_function(50)`.
pub fn MPContext::complementary_error_function(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.erfc(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the imaginary error function on the real axis.
pub fn MPContext::imaginary_error_function(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.erfi(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the entire Gaussian error function for a complex argument.
pub fn MPContext::complex_error_function(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.error_function(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the complementary Gaussian error function for a complex argument.
pub fn MPContext::complex_complementary_error_function(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.complementary_error_function(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the entire imaginary error function for a complex argument.
pub fn MPContext::complex_imaginary_error_function(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.imaginary_error_function(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
