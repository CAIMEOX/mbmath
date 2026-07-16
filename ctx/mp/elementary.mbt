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

///|
fn MPContext::rounded_reciprocal(
  self : MPContext,
  x : @mpf.RawMpf,
  wp : Int,
) -> @mpf.RawMpf raise MPError {
  @mpf.RawMpf::one()
  .div(x, wp, Nearest)
  .rounded(self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn reciprocal_input(x : @mpf.RawMpf, wp : Int) -> @mpf.RawMpf raise MPError {
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  @mpf.RawMpf::one().div(x, wp, Nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Compute the real cotangent as `cos(x)/sin(x)` from one shared reduction.
pub fn MPContext::cot(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let (cosine, sine) = @libelefun.cos_sin(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  cosine.div(sine, wp, Nearest).rounded(self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Compute the real secant `1/cos(x)`.
pub fn MPContext::sec(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let cosine = @libelefun.cos(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  self.rounded_reciprocal(cosine, wp)
}

///|
/// Compute the real cosecant `1/sin(x)`.
pub fn MPContext::csc(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let sine = @libelefun.sin(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  self.rounded_reciprocal(sine, wp)
}

///|
/// Compute the real hyperbolic cotangent `1/tanh(x)`.
pub fn MPContext::coth(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let value = @libelefun.tanh(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  self.rounded_reciprocal(value, wp)
}

///|
/// Compute the real hyperbolic secant `1/cosh(x)`.
pub fn MPContext::sech(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let value = @libelefun.cosh(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  self.rounded_reciprocal(value, wp)
}

///|
/// Compute the real hyperbolic cosecant `1/sinh(x)`.
pub fn MPContext::csch(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let value = @libelefun.sinh(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  self.rounded_reciprocal(value, wp)
}

///|
/// Compute the principal real inverse cotangent as `atan(1/x)`.
///
/// Zero maps to `pi/2` and either infinity maps to zero.
pub fn MPContext::acot(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_zero() {
    return self.pi().scale_pow2(-1)
  }
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  let wp = self.elementary_work_precision()
  let reciprocal = reciprocal_input(x, wp)
  @libelefun.atan(reciprocal, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute the principal real inverse secant `acos(1/x)`.
pub fn MPContext::asec(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let reciprocal = reciprocal_input(x, self.elementary_work_precision())
  self.acos(reciprocal)
}

///|
/// Compute the principal real inverse cosecant `asin(1/x)`.
pub fn MPContext::acsc(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let reciprocal = reciprocal_input(x, self.elementary_work_precision())
  self.asin(reciprocal)
}

///|
/// Compute the principal real inverse hyperbolic cotangent `atanh(1/x)`.
///
/// This real-only method requires `|x| >= 1`. At zero the mathematical value
/// is complex and `MPError::ComplexResult` is raised.
pub fn MPContext::acoth(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_zero() {
    raise ComplexResult("acoth: complex result at zero")
  }
  let reciprocal = reciprocal_input(x, self.elementary_work_precision())
  self.atanh(reciprocal)
}

///|
/// Compute the principal real inverse hyperbolic secant `acosh(1/x)`.
pub fn MPContext::asech(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let reciprocal = reciprocal_input(x, self.elementary_work_precision())
  self.acosh(reciprocal)
}

///|
/// Compute the real inverse hyperbolic cosecant `asinh(1/x)`.
pub fn MPContext::acsch(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let reciprocal = reciprocal_input(x, self.elementary_work_precision())
  self.asinh(reciprocal)
}

///|
/// Return `-1`, `0`, or `1` for finite real inputs, preserving NaN.
pub fn MPContext::sign(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  ignore(self)
  if x.is_nan() {
    @mpf.RawMpf::nan()
  } else {
    match x.signum() {
      -1 => @mpf.RawMpf::negative_one()
      1 => @mpf.RawMpf::one()
      _ => @mpf.RawMpf::zero()
    }
  }
}

///|
/// Return the principal argument of a real value: pi for negatives, zero
/// otherwise, and NaN for NaN.
pub fn MPContext::arg(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libelefun.atan2(@mpf.RawMpf::zero(), x, self.precision(), self.round_mode()) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Compute the arithmetic-geometric mean of two non-negative real values.
///
/// The second argument defaults to one. Inputs whose AGM lies outside the real
/// branch raise a structured context error.
pub fn MPContext::agm(
  self : MPContext,
  a : @mpf.RawMpf,
  b? : @mpf.RawMpf = @mpf.RawMpf::one(),
) -> @mpf.RawMpf raise MPError {
  @libhyper.agm(a, b, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Compute the unnormalized sinc function `sin(x)/x`, with value one at zero.
pub fn MPContext::sinc(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_zero() {
    return @mpf.RawMpf::one()
  }
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  let wp = self.elementary_work_precision()
  let numerator = @libelefun.sin(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  numerator.div(x, wp, Nearest).rounded(self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Compute the normalized sinc function `sin(pi*x)/(pi*x)`.
///
/// Integer zeros are exact because `sin_pi` performs exact dyadic reduction.
pub fn MPContext::sinc_pi(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_zero() {
    return @mpf.RawMpf::one()
  }
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  let wp = self.elementary_work_precision()
  let numerator = @libelefun.sin_pi(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let denominator = @libelefun.pi(wp, Nearest).mul(x, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  numerator
  .div(denominator, wp, Nearest)
  .rounded(self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Compute `exp(x)-1` with full relative accuracy for small `x`.
pub fn MPContext::expm1(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_unary(x, @libelefun.expm1)
}

///|
/// Compute `x^y-1` without cancellation when the result is near zero.
pub fn MPContext::pow_minus_one(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.elementary_binary(x, y, @libelefun.pow_minus_one)
}

///|
/// Compute the base-ten logarithm on the real branch.
pub fn MPContext::log10(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.log(x, base=@mpf.RawMpf::ten())
}

///|
/// Compute the base-two logarithm on the real branch.
pub fn MPContext::log2(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.log(x, base=@mpf.RawMpf::two())
}

///|
/// Compute `2^x` on the real branch.
pub fn MPContext::exp2(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.pow(@mpf.RawMpf::two(), x)
}

///|
/// Convert an angle in radians to degrees.
pub fn MPContext::to_degrees(
  self : MPContext,
  radians : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let unit = @libelefun.degree(wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  radians.div(unit, wp, Nearest).rounded(self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Convert an angle in degrees to radians.
pub fn MPContext::to_radians(
  self : MPContext,
  degrees : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = self.elementary_work_precision()
  let unit = @libelefun.degree(wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  degrees.mul(unit, wp, Nearest).rounded(self.precision(), self.round_mode())
}

///|
/// Return the floor-division remainder with the sign of the divisor.
pub fn MPContext::modulo(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  x.modulo(y, self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}
