///|
/// Core rounding modes aligned with mpmath's low-level modes:
/// - Nearest: tie-to-even
/// - Floor: towards -inf
/// - Ceiling: towards +inf
/// - Up: away from zero
/// - Down: towards zero
pub enum RoundMode {
  Nearest
  Floor
  Ceiling
  Up
  Down
} derive(Show, Eq)

///|
/// Raw arbitrary-precision floating-point value:
/// value = (-1)^sign * man * 2^exp
/// Canonical invariant: `man` is non-negative and odd unless it is zero.
pub struct RawMpf {
  sign : Int
  man : BigInt
  exp : Int
  bc : Int
} derive(Show, Eq)

///|
pub(all) suberror MpfError {
  ValueError(String)
  DomainError(String)
  DivisionByZero(String)
  ParseError(String)
  FormatError(String)
  UnsupportedError(String)
} derive(Show, Eq)

///|
/// Canonicalize `(sign, man, exp)` into the internal normalized `RawMpf` form.
///
/// Applies precision truncation and rounding mode, preserving mpmath-style
/// invariants (`man` odd unless zero, canonical signed zero handling).
#declaration_only
pub fn normalize(
  sign : Int,
  man : BigInt,
  exp : Int,
  bc : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
/// Construct an `mpf` from an exact mantissa/exponent pair.
///
/// Equivalent to mpmath `from_man_exp`, followed by normalization at `prec`.
#declaration_only
pub fn from_man_exp(
  man : BigInt,
  exp : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
/// Exact conversion from machine integer to arbitrary-precision float.
#declaration_only
pub fn from_int(n : Int) -> RawMpf {
  ...
}

///|
/// Return `true` iff value is either `+0` or `-0` canonical zero.
#declaration_only
pub fn is_zero(x : RawMpf) -> Bool {
  ...
}

///|
/// Return `true` for ordinary finite numbers (not NaN/Inf).
#declaration_only
pub fn is_finite(x : RawMpf) -> Bool {
  ...
}

///|
/// Return `true` for `+inf` or `-inf`.
#declaration_only
pub fn is_inf(x : RawMpf) -> Bool {
  ...
}

///|
/// Return `true` for quiet NaN payload used by libmp.
#declaration_only
pub fn is_nan(x : RawMpf) -> Bool {
  ...
}

///|
/// Parse string into `RawMpf`.
///
/// Supports mpmath-compatible forms including decimal/scientific notation,
/// `inf`/`-inf`/`nan`, and selected base prefixes.
#declaration_only
pub fn from_str(
  s : String,
  prec? : Int = 0,
  rnd? : RoundMode = round_nearest,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Convert to canonical decimal string without formatting options.
#declaration_only
pub fn to_str(x : RawMpf) -> String raise MpfError {
  ...
}

///|
/// Rich string conversion with precision/base/binary-exponent controls.
///
/// This is the primary mpmath-like conversion entry used by tests and wrappers.
#declaration_only
pub fn to_str_opts(
  x : RawMpf,
  dps? : Int = 15,
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String raise MpfError {
  ...
}

///|
/// Python/mpmath-style format mini-language entry for `RawMpf`.
///
/// Handles sign, alignment, precision, percent, base, alternate form and
/// rounding suffixes in the implemented subset.
#declaration_only
pub fn format_mpf(
  x : RawMpf,
  format_spec : String,
  dps? : Int = 15,
) -> String raise MpfError {
  ...
}

///|
/// Rounded addition `x + y`.
#declaration_only
pub fn mpf_add(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Rounded subtraction `x - y`.
#declaration_only
pub fn mpf_sub(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Rounded multiplication `x * y`.
#declaration_only
pub fn mpf_mul(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Rounded division `x / y`.
///
/// Raises `DivisionByZero` for denominator zero and maps invalid forms to
/// structured `MpfError`.
#declaration_only
pub fn mpf_div(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Unary plus (rounding/precision normalization pass).
#declaration_only
pub fn mpf_pos(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Unary negation.
#declaration_only
pub fn mpf_neg(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Absolute value.
#declaration_only
pub fn mpf_abs(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Sign query: returns `-1`, `0`, or `1` for finite values and special cases.
#declaration_only
pub fn mpf_sign(x : RawMpf) -> Int {
  ...
}

///|
/// Numerical equality with special-value semantics.
#declaration_only
pub fn mpf_eq(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
/// Three-way compare (`-1`, `0`, `1`) with mpmath ordering rules.
#declaration_only
pub fn mpf_cmp(x : RawMpf, y : RawMpf) -> Int {
  ...
}

///|
/// Strict less-than comparison.
#declaration_only
pub fn mpf_lt(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
/// Less-or-equal comparison.
#declaration_only
pub fn mpf_le(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
/// Strict greater-than comparison.
#declaration_only
pub fn mpf_gt(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
/// Greater-or-equal comparison.
#declaration_only
pub fn mpf_ge(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
/// Exact power-of-two shift (`x * 2^n`) without rounding.
#declaration_only
pub fn mpf_shift(x : RawMpf, n : Int) -> RawMpf {
  ...
}

///|
/// Multiply by integer with target precision and rounding.
#declaration_only
pub fn mpf_mul_int(x : RawMpf, n : Int, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Compute exact integer-over-float quotient `n / x` with rounding.
#declaration_only
pub fn mpf_rdiv_int(
  n : Int,
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Round to integral value using explicit rounding mode.
#declaration_only
pub fn mpf_round_int(x : RawMpf, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Floor to integer (`<= x`) then represent as `RawMpf`.
#declaration_only
pub fn mpf_floor(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Ceiling to integer (`>= x`) then represent as `RawMpf`.
#declaration_only
pub fn mpf_ceil(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Nearest integer (ties follow current rounding rule / tie strategy).
#declaration_only
pub fn mpf_nint(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Fractional part of `x` (`x - floor(x)` with special handling).
#declaration_only
pub fn mpf_frac(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
/// Compute `(min, max)` over a non-empty sequence.
///
/// Raises `ValueError` for empty input.
#declaration_only
pub fn mpf_min_max(seq : ArrayView[RawMpf]) -> (RawMpf, RawMpf) raise MpfError {
  ...
}

///|
/// Accurate summation over `xs`.
///
/// Uses compensated strategy similar to mpmath `fsum`; `absolute=true` sums
/// absolute values.
#declaration_only
pub fn mpf_sum(
  xs : ArrayView[RawMpf],
  prec : Int,
  rnd : RoundMode,
  absolute? : Bool = false,
) -> RawMpf {
  ...
}

///|
/// Floating-point remainder `x mod y` with mpmath-compatible special cases.
#declaration_only
pub fn mpf_mod(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Stable Euclidean norm `sqrt(x^2 + y^2)`.
///
/// Uses scaling to avoid overflow/underflow.
#declaration_only
pub fn mpf_hypot(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Integer exponentiation `x^n` (fast pow, handles negative exponents).
#declaration_only
pub fn mpf_pow_int(
  x : RawMpf,
  n : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Principal real square root.
///
/// Raises `DomainError` on negative finite inputs.
#declaration_only
pub fn mpf_sqrt(
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  ...
}

///|
/// Decompose `x = m * 2^e` with `m` in normalized interval.
///
/// Analogous to C/Python `frexp`.
#declaration_only
pub fn mpf_frexp(x : RawMpf) -> (RawMpf, Int) raise MpfError {
  ...
}

///|
/// Deterministic hash compatible with Python/mpmath expectations for specials.
#declaration_only
pub fn mpf_hash(x : RawMpf) -> Int {
  ...
}

///|
/// Apply a one-ulp-like directed perturbation.
///
/// Used by interval-style outward rounding and boundary constructions.
#declaration_only
pub fn mpf_perturb(
  x : RawMpf,
  eps_sign : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
/// Generate pseudo-random `RawMpf` in `[0, 1)` with requested precision.
#declaration_only
pub fn mpf_rand(prec : Int) -> RawMpf {
  ...
}

///|
/// Canonical positive zero.
pub let fzero : RawMpf = { sign: 0, man: 0N, exp: 0, bc: 0 }

///|
/// Canonical positive one.
pub let fone : RawMpf = { sign: 0, man: 1N, exp: 0, bc: 1 }

///|
/// Canonical negative one.
pub let fnone : RawMpf = { sign: 1, man: 1N, exp: 0, bc: 1 }

///|
/// Canonical NaN sentinel.
pub let fnan : RawMpf = { sign: 0, man: 0N, exp: -123, bc: -1 }

///|
/// Canonical positive infinity.
pub let finf : RawMpf = { sign: 0, man: 0N, exp: -456, bc: -2 }

///|
/// Canonical negative infinity.
pub let fninf : RawMpf = { sign: 1, man: 0N, exp: -789, bc: -3 }

///|
/// Rounding mode alias: nearest (tie-to-even).
pub let round_nearest : RoundMode = RoundMode::Nearest

///|
/// Rounding mode alias: toward negative infinity.
pub let round_floor : RoundMode = RoundMode::Floor

///|
/// Rounding mode alias: toward positive infinity.
pub let round_ceiling : RoundMode = RoundMode::Ceiling

///|
/// Rounding mode alias: away from zero.
pub let round_up : RoundMode = RoundMode::Up

///|
/// Rounding mode alias: toward zero.
pub let round_down : RoundMode = RoundMode::Down
