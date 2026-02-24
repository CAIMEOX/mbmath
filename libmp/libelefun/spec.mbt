///|
pub(all) suberror LibElefunError {
  ValueError(String)
  DomainError(String)
  ComplexResult(String)
} derive(Show, Eq)

///|
/// Two-argument arctangent returning the principal angle of `(x, y)`.
///
/// Equivalent to mpmath `atan2(y, x)` with quadrant-correct branch selection.
#declaration_only
pub fn mpf_atan2(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Principal real arctangent.
///
/// Matches mpmath `atan(x)` on real arguments, including signed-zero behavior.
#declaration_only
pub fn mpf_atan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Archimedes' constant `pi` at requested precision.
#declaration_only
pub fn mpf_pi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Exponential function `exp(x)` on real `mpf`.
#declaration_only
pub fn mpf_exp(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Natural logarithm `ln(x)` on real inputs.
///
/// Raises `LibElefunError::DomainError` outside real domain.
#declaration_only
pub fn mpf_ln(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Alias of natural logarithm, kept for mpmath naming compatibility.
#declaration_only
pub fn mpf_log(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Accurate `log(1+x)` for small `x`.
///
/// Uses cancellation-aware algorithms aligned with mpmath `log1p`.
#declaration_only
pub fn mpf_log1p(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real sine function.
#declaration_only
pub fn mpf_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Real cosine function.
#declaration_only
pub fn mpf_cos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Real tangent function.
#declaration_only
pub fn mpf_tan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Hyperbolic sine `sinh(x)`.
#declaration_only
pub fn mpf_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Hyperbolic cosine `cosh(x)`.
#declaration_only
pub fn mpf_cosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Hyperbolic tangent `tanh(x)`.
#declaration_only
pub fn mpf_tanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Real inverse sine on principal branch.
///
/// Raises domain errors for `|x| > 1` in real mode.
#declaration_only
pub fn mpf_asin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real inverse cosine on principal branch.
///
/// Raises domain errors for `|x| > 1` in real mode.
#declaration_only
pub fn mpf_acos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real inverse hyperbolic sine.
#declaration_only
pub fn mpf_asinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Real inverse hyperbolic cosine.
///
/// Raises domain errors on inputs below 1 in real mode.
#declaration_only
pub fn mpf_acosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real inverse hyperbolic tangent.
///
/// Raises domain errors for inputs outside `(-1, 1)` in real mode.
#declaration_only
pub fn mpf_atanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real power `x^y` with analytic continuation rules used by mpmath.
///
/// May raise when a complex continuation would be required in real mode.
#declaration_only
pub fn mpf_pow(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise {
  ...
}

///|
/// Real `n`-th root with mpmath-compatible branch/domain handling.
#declaration_only
pub fn mpf_nthroot(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise {
  ...
}

///|
/// Real cube root convenience wrapper.
#declaration_only
pub fn mpf_cbrt(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Euler's number `e`.
#declaration_only
pub fn mpf_e(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Natural logarithm of 2.
#declaration_only
pub fn mpf_ln2(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Natural logarithm of 10.
#declaration_only
pub fn mpf_ln10(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Constant `sqrt(pi)`.
#declaration_only
pub fn mpf_sqrtpi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Constant `log(sqrt(2*pi))`.
#declaration_only
pub fn mpf_ln_sqrt2pi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Golden ratio constant `phi`.
#declaration_only
pub fn mpf_phi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Degrees-per-radian conversion constant `180/pi`.
#declaration_only
pub fn mpf_degree(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Compute `sin(pi*x)` with argument reduction tuned for large/near-integer `x`.
#declaration_only
pub fn mpf_sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Compute `cos(pi*x)` with argument reduction tuned for large/near-integer `x`.
#declaration_only
pub fn mpf_cos_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Joint cosine/sine evaluator with shared reduction.
///
/// `which`/`pi` options mirror the low-level mpmath helper shape used by
/// multiple trig routines.
#declaration_only
pub fn mpf_cos_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 0,
  pi? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
/// Joint evaluation of `cos(pi*x)` and `sin(pi*x)`.
#declaration_only
pub fn mpf_cos_sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
/// Joint evaluation of hyperbolic pair.
///
/// Returns `(cosh(x), sinh(x))`, and when `tanh=true` may also use a faster
/// shared path for tanh-related computations.
#declaration_only
pub fn mpf_cosh_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  tanh? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
/// Stable `log(hypot(a, b))` computation.
///
/// Uses scaling to avoid overflow/underflow and cancellation.
#declaration_only
pub fn mpf_log_hypot(
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Real-only projection of complex exponential-on-imaginary-axis helper.
///
/// This is a compatibility hook used by higher layers; real-domain constraints
/// are enforced via `LibElefunError`.
#declaration_only
pub fn mpf_expj(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}

///|
/// Real-only projection of `exp(j*pi*x)` helper.
///
/// Used for mpmath-compatible periodic special-value semantics.
#declaration_only
pub fn mpf_expjpi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ...
}
