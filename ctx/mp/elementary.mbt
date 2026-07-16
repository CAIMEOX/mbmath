///|
fn MPContext::elementary_work_precision(self : MPContext) -> Int {
  if self.precision() > 0 {
    self.precision() + 20
  } else {
    80
  }
}

///|
fn MPContext::elementary_constant(
  self : MPContext,
  f : (Int, @mpf.RoundMode) -> @mpf.RawMpf raise @libelefun.LibElefunError,
) -> @mpf.RawMpf raise MPError {
  f(self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn MPContext::elementary_unary(
  self : MPContext,
  x : @mpf.RawMpf,
  f : (@mpf.RawMpf, Int, @mpf.RoundMode) -> @mpf.RawMpf raise @libelefun.LibElefunError,
) -> @mpf.RawMpf raise MPError {
  f(x, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn MPContext::elementary_binary(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  f : (@mpf.RawMpf, @mpf.RawMpf, Int, @mpf.RoundMode) -> @mpf.RawMpf raise @libelefun.LibElefunError,
) -> @mpf.RawMpf raise MPError {
  f(x, y, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Return pi rounded to this context's binary precision and rounding mode.
pub fn MPContext::pi(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.pi)
}

///|
/// Return Euler's number `e`, computed as `exp(1)` at context precision.
pub fn MPContext::e(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.e)
}

///|
/// Return the natural logarithm of two at context precision.
pub fn MPContext::ln2(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.ln2)
}

///|
/// Return the natural logarithm of ten at context precision.
pub fn MPContext::ln10(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.ln10)
}

///|
/// Return the positive square root of pi at context precision.
pub fn MPContext::sqrt_pi(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.sqrt_pi)
}

///|
/// Return `log(sqrt(2*pi))`, a constant used by gamma asymptotics.
pub fn MPContext::ln_sqrt_2pi(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.ln_sqrt_2pi)
}

///|
/// Return the golden ratio `(1 + sqrt(5)) / 2` at context precision.
pub fn MPContext::golden_ratio(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.phi)
}

///|
/// Return one degree in radians, namely `pi / 180`.
pub fn MPContext::degree(self : MPContext) -> @mpf.RawMpf raise MPError {
  self.elementary_constant(@libelefun.degree)
}

///|
/// Compute a real logarithm, optionally in a caller-supplied real base.
///
/// Without `base`, this is the natural logarithm. With a base, numerator and
/// denominator logarithms are evaluated with guard bits before the quotient is
/// rounded once. Non-positive inputs remain outside this real-only API; base
/// one raises `MPError::PoleError`.
pub fn MPContext::log(
  self : MPContext,
  x : @mpf.RawMpf,
  base? : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  match base {
    None => self.elementary_unary(x, @libelefun.log)
    Some(b) => {
      let wp = self.elementary_work_precision()
      let numerator = @libelefun.ln(x, wp, Nearest) catch {
        err => raise from_libelefun_error(err)
      }
      let denominator = @libelefun.ln(b, wp, Nearest) catch {
        err => raise from_libelefun_error(err)
      }
      numerator
      .div(denominator, wp, Nearest)
      .rounded(self.precision(), self.round_mode()) catch {
        err => raise from_mpf_error(err)
      }
    }
  }
}

///|
/// Compute `log(1+x)` without losing a small increment to cancellation.
///
/// `x=-1` returns negative infinity; values below `-1` raise
/// `MPError::DomainError` in this real-only API.
pub fn MPContext::log1p(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.log1p)
}

///|
/// Compute the principal real arctangent in `[-pi/2, pi/2]`.
pub fn MPContext::atan(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.atan)
}

///|
/// Compute the quadrant-aware argument of the Cartesian point `(x, y)`.
///
/// The first argument is the vertical coordinate `y`, matching the usual
/// `atan2(y, x)` convention and mpmath. The result lies on the principal real
/// branch around `[-pi, pi]`.
pub fn MPContext::atan2(
  self : MPContext,
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_binary(y, x, @libelefun.atan2)
}

///|
/// Compute the real hyperbolic sine.
pub fn MPContext::sinh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.sinh)
}

///|
/// Compute the real hyperbolic cosine.
pub fn MPContext::cosh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.cosh)
}

///|
/// Compute the real hyperbolic tangent, including exact limits at infinity.
pub fn MPContext::tanh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.tanh)
}

///|
/// Compute the principal real arcsine for `-1 <= x <= 1`.
pub fn MPContext::asin(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.asin)
}

///|
/// Compute the principal real arccosine for `-1 <= x <= 1`.
pub fn MPContext::acos(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.acos)
}

///|
/// Compute the real inverse hyperbolic sine.
pub fn MPContext::asinh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.asinh)
}

///|
/// Compute the principal real inverse hyperbolic cosine for `x >= 1`.
pub fn MPContext::acosh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.acosh)
}

///|
/// Compute the principal real inverse hyperbolic tangent.
///
/// The endpoints `-1` and `1` map to signed infinities. Inputs outside the
/// closed real interval raise `MPError::DomainError`.
pub fn MPContext::atanh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.atanh)
}

///|
/// Compute real `x^y` at context precision.
///
/// Negative bases are accepted for integral exponents. A negative base with
/// a non-integral exponent raises `MPError::DomainError`; use
/// `MPContext::complex_pow` when the principal complex branch is required.
pub fn MPContext::pow(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_binary(x, y, @libelefun.pow)
}

///|
/// Compute the real `n`th root of `x`.
///
/// Odd roots preserve the sign of negative inputs. Even roots of negative
/// values are outside the real domain, and `n=0` is invalid. Negative `n`
/// computes the reciprocal root.
pub fn MPContext::nthroot(
  self : MPContext,
  x : @mpf.RawMpf,
  n : Int,
) -> @mpf.RawMpf raise MPError {
  @libelefun.nthroot(x, n, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute the real cube root, preserving the sign of negative inputs.
pub fn MPContext::cbrt(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.cbrt)
}

///|
/// Compute cosine and sine together after one argument reduction.
///
/// The pair is returned as `(cos(x), sin(x))`, matching the low-level paired
/// routine and avoiding inconsistent reductions for large arguments.
pub fn MPContext::cos_sin(
  self : MPContext,
  x : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  @libelefun.cos_sin(x, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute `(cos(pi*x), sin(pi*x))` with a shared high-precision reduction.
pub fn MPContext::cos_sin_pi(
  self : MPContext,
  x : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  @libelefun.cos_sin_pi(x, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute `sin(pi*x)` without first rounding a separate product by pi.
pub fn MPContext::sin_pi(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.sin_pi)
}

///|
/// Compute `cos(pi*x)` without first rounding a separate product by pi.
pub fn MPContext::cos_pi(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.cos_pi)
}

///|
/// Compute hyperbolic cosine and sine as `(cosh(x), sinh(x))`.
pub fn MPContext::cosh_sinh(
  self : MPContext,
  x : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  @libelefun.cosh_sinh(x, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute `sqrt(x*x + y*y)` using the scaled low-level hypot algorithm.
pub fn MPContext::hypot(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  x.hypot(y, self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Compute `log(sqrt(x*x + y*y))` without forming overflow-prone squares.
pub fn MPContext::log_hypot(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_binary(x, y, @libelefun.log_hypot)
}
