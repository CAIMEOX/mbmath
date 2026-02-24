///|
pub(all) suberror LibHyperError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
} derive(Show, Eq)

///|
/// Arithmetic-geometric mean `agm(x, y)` on real arguments.
///
/// Uses the classical AGM iteration and raises structured errors for invalid
/// domain/special-value combinations.
#declaration_only
pub fn mpf_agm(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Exponential integral `Ei(x)` on real axis.
#declaration_only
pub fn mpf_ei(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Taylor-series kernel used by `Ci`/`Si` near zero.
///
/// `which` selects the target integral variant.
#declaration_only
pub fn mpf_ci_si_taylor(
  x : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> @mpf.RawMpf {
  ...
}

///|
/// Sine integral `Si(x)`.
#declaration_only
pub fn mpf_si(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Cosine integral `Ci(x)` on the real branch.
///
/// Raises domain/branch errors when real-valued result is not defined.
#declaration_only
pub fn mpf_ci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Complete elliptic integral of first kind `K(m)`.
#declaration_only
pub fn mpf_ellipk(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Complete elliptic integral of second kind `E(m)`.
#declaration_only
pub fn mpf_ellipe(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Convenience wrapper `agm(1, a)`.
#declaration_only
pub fn mpf_agm1(
  a : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Joint evaluator returning `(Ci(x), Si(x))` variants.
///
/// `which` controls whether one or both values are targeted by internal path.
#declaration_only
pub fn mpf_ci_si(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 2,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
/// Exponential integral `E1(x)` principal real branch.
#declaration_only
pub fn mpf_e1(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Error function `erf(x)`.
#declaration_only
pub fn mpf_erf(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Complementary error function `erfc(x)`.
#declaration_only
pub fn mpf_erfc(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Generalized exponential integral family `expint(n, x)`.
///
/// With `gamma=true`, computes the upper incomplete-gamma related form.
#declaration_only
pub fn mpf_expint(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  gamma? : Bool = false,
) -> @mpf.RawMpf raise LibHyperError {
  ...
}

///|
/// Bessel function of the first kind `J_n(x)` for integer order `n`.
#declaration_only
pub fn mpf_besseljn(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}
