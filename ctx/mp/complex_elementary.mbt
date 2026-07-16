///|
fn MPContext::complex_unary(
  self : MPContext,
  z : @mpc.RawMpc,
  f : (@mpc.RawMpc, Int, @mpf.RoundMode) -> @mpc.RawMpc raise @mpc.MpcError,
) -> @mpc.RawMpc raise MPError {
  f(z, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Return the Euclidean magnitude of a complex value.
pub fn MPContext::complex_abs(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpf.RawMpf raise MPError {
  checked_mpc_abs(z, self.precision(), self.round_mode())
}

///|
/// Return the principal argument of a complex value in radians.
pub fn MPContext::complex_arg(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpf.RawMpf raise MPError {
  z.arg(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Return the complex conjugate, rounded in the current context.
pub fn MPContext::complex_conjugate(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc {
  z.conjugate(self.precision(), self.round_mode())
}

///|
/// Compute the complex exponential.
pub fn MPContext::complex_exp(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  checked_mpc_exp(z, self.precision(), self.round_mode())
}

///|
/// Compute the complex sine.
pub fn MPContext::complex_sin(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::sin)
}

///|
/// Compute the complex cosine.
pub fn MPContext::complex_cos(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::cos)
}

///|
/// Compute the complex tangent, propagating poles as `MPError::PoleError`.
pub fn MPContext::complex_tan(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::tan)
}

///|
/// Compute the complex hyperbolic sine.
pub fn MPContext::complex_sinh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::sinh)
}

///|
/// Compute the complex hyperbolic cosine.
pub fn MPContext::complex_cosh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::cosh)
}

///|
/// Compute the complex hyperbolic tangent.
pub fn MPContext::complex_tanh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::tanh)
}

///|
/// Compute the principal complex arcsine.
pub fn MPContext::complex_asin(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::asin)
}

///|
/// Compute the principal complex arccosine.
pub fn MPContext::complex_acos(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::acos)
}

///|
/// Compute the principal complex arctangent.
pub fn MPContext::complex_atan(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::atan)
}

///|
/// Compute the principal complex inverse hyperbolic sine.
pub fn MPContext::complex_asinh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::asinh)
}

///|
/// Compute the principal complex inverse hyperbolic cosine.
pub fn MPContext::complex_acosh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::acosh)
}

///|
/// Compute the principal complex inverse hyperbolic tangent.
pub fn MPContext::complex_atanh(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::atanh)
}

///|
/// Compute the principal complex `n`th root.
///
/// Unlike `MPContext::nthroot`, this always follows the principal complex
/// branch; therefore odd roots of negative reals need not be negative real.
pub fn MPContext::complex_nthroot(
  self : MPContext,
  z : @mpc.RawMpc,
  n : Int,
) -> @mpc.RawMpc raise MPError {
  z.nthroot(n, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the principal complex cube root.
pub fn MPContext::complex_cbrt(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::cbrt)
}

///|
/// Compute complex cosine and sine together as `(cos(z), sin(z))`.
pub fn MPContext::complex_cos_sin(
  self : MPContext,
  z : @mpc.RawMpc,
) -> (@mpc.RawMpc, @mpc.RawMpc) raise MPError {
  z.cos_sin(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute `(cos(pi*z), sin(pi*z))` using a shared complex reduction.
pub fn MPContext::complex_cos_sin_pi(
  self : MPContext,
  z : @mpc.RawMpc,
) -> (@mpc.RawMpc, @mpc.RawMpc) raise MPError {
  z.cos_sin_pi(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the complex `sin(pi*z)` function.
pub fn MPContext::complex_sin_pi(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::sin_pi)
}

///|
/// Compute the complex `cos(pi*z)` function.
pub fn MPContext::complex_cos_pi(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::cos_pi)
}

///|
/// Compute `exp(i*z)` on the principal complex exponential branch.
pub fn MPContext::complex_exp_i(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::exp_i)
}

///|
/// Compute `exp(i*pi*z)` without separately rounding `pi*z`.
pub fn MPContext::complex_exp_i_pi(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_unary(z, @mpc.RawMpc::exp_i_pi)
}
