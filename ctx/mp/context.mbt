///|
/// High-level arbitrary-precision numerical context.
pub struct MPContext {
  prec : Int
  rounding : @mpf.RoundMode
} derive(Debug, Eq)

///|
pub(all) suberror MPError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
  ConvergenceError(String)
} derive(Debug, Eq)

///|
fn from_mpf_error(err : @mpf.MpfError) -> MPError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    DivisionByZero(msg) => PoleError(msg)
    OverflowError(msg) => ValueError(msg)
    ParseError(msg) => ValueError(msg)
    FormatError(msg) => ValueError(msg)
    UnsupportedError(msg) => ValueError(msg)
  }
}

///|
fn from_libelefun_error(err : @libelefun.LibElefunError) -> MPError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    ComplexResult(msg) => ComplexResult(msg)
  }
}

///|
fn from_libhyper_error(err : @libhyper.LibHyperError) -> MPError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
    ComplexResult(msg) => ComplexResult(msg)
    ConvergenceError(msg) => ConvergenceError(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> MPError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
    ConvergenceError(msg) => ConvergenceError(msg)
  }
}

///|
fn from_mpc_error(err : @mpc.MpcError) -> MPError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
    ConvergenceError(msg) => ConvergenceError(msg)
  }
}

///|
fn checked_mpf_pi(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpf_exp(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.exp(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpf_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.sin(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpf_cos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.cos(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpf_tan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.tan(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpf_ln2(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @libelefun.ln2(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn checked_mpc_to_str(z : @mpc.RawMpc, dps? : Int = 15) -> String raise MPError {
  z.format(dps~) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_sqrt(
  z : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  z.sqrt(prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_gamma(
  z : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  z.gamma(prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_zeta(
  z : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpc.RawMpc raise MPError {
  z.zeta(prec, rnd, alt~) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_abs(
  z : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  z.abs(prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_div(
  z : @mpc.RawMpc,
  w : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  z.div(w, prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_div_mpf(
  z : @mpc.RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  z.div_real(x, prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn checked_mpc_exp(
  z : @mpc.RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  z.exp(prec, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Create a high-level arbitrary-precision context.
///
/// This is the MoonBit counterpart of constructing an `mpmath.mp`-like runtime
/// state. `prec` is binary precision (bits), and `rounding` controls final
/// rounding for wrapper operations.
pub fn MPContext::new(prec : Int, rounding : @mpf.RoundMode) -> MPContext {
  { prec, rounding }
}

///|
/// Return the context precision in bits.
pub fn MPContext::precision(self : MPContext) -> Int {
  self.prec
}

///|
/// Return the context rounding mode.
pub fn MPContext::round_mode(self : MPContext) -> @mpf.RoundMode {
  self.rounding
}

///|
/// Construct an `mpf` value from an integer using this context precision.
pub fn MPContext::from_int(self : MPContext, n : Int) -> @mpf.RawMpf {
  @mpf.RawMpf::from_mantissa_exponent(
    BigInt::from_int(n),
    0,
    self.prec,
    self.rounding,
  )
}

///|
/// Parse a decimal string into an `mpf` using context precision.
///
/// Compatible with mpmath-style numeric spellings (`inf`, `nan`, exponents,
/// signed literals). Parse failures are normalized to `MPError::ValueError`.
pub fn MPContext::parse(
  self : MPContext,
  s : StringView,
) -> @mpf.RawMpf raise MPError {
  @mpf.RawMpf::parse(s, prec=self.prec, rnd=self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Convert an `mpf` to a plain decimal string with optional `dps`.
///
/// This wraps `RawMpf::format` and follows mpmath's default user-facing
/// conversion style for finite/special values.
pub fn MPContext::to_string(
  self : MPContext,
  x : @mpf.RawMpf,
  dps? : Int = 15,
) -> String raise MPError {
  ignore(self)
  x.format(dps~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Format an `mpf` using mpmath/Python-like format mini-language subset.
///
/// `format_spec` is forwarded to `RawMpf::format_spec` (alignment, sign, percent,
/// base/precision options implemented by libmp).
pub fn MPContext::format(
  self : MPContext,
  x : @mpf.RawMpf,
  format_spec : StringView,
  dps? : Int = 15,
) -> String raise MPError {
  ignore(self)
  x.format_spec(format_spec, dps~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Build a complex number from real and imaginary `mpf` parts.
pub fn MPContext::complex(
  self : MPContext,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> @mpc.RawMpc {
  ignore(self)
  @mpc.RawMpc::new(re, im)
}

///|
/// Convert an `mpc` value to string in `(re + im*j)` style.
///
/// `dps` controls displayed digits. Behavior follows `mpmath.nstr`-style
/// compact conversion for complex numbers.
pub fn MPContext::format_complex(
  self : MPContext,
  z : @mpc.RawMpc,
  dps? : Int = 15,
) -> String raise MPError {
  ignore(self)
  checked_mpc_to_str(z, dps~)
}

///|
/// Context-aware floating-point addition.
pub fn MPContext::add(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  x.add(y, self.prec, self.rounding)
}

///|
/// Context-aware floating-point subtraction.
pub fn MPContext::sub(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  x.sub(y, self.prec, self.rounding)
}

///|
/// Context-aware floating-point multiplication.
pub fn MPContext::mul(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  x.mul(y, self.prec, self.rounding)
}

///|
/// Context-aware floating-point division.
///
/// Raises `MPError::PoleError` for division-by-zero paths and maps other
/// libmp errors into structured `MPError`.
pub fn MPContext::div(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  x.div(y, self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Unary negation with context rounding.
pub fn MPContext::neg(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  x.negated(self.prec, self.rounding)
}

///|
/// Absolute value with context rounding.
pub fn MPContext::abs(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  x.abs(self.prec, self.rounding)
}

///|
/// Principal square root on real inputs.
///
/// Raises `MPError::DomainError` for negative finite real values, matching
/// mpmath real-domain semantics.
pub fn MPContext::sqrt(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  x.sqrt(self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Integer power `x^n` in the current context.
///
/// Uses fast exponentiation in libmp and propagates structured errors for
/// invalid edge cases.
pub fn MPContext::pow_int(
  self : MPContext,
  x : @mpf.RawMpf,
  n : Int,
) -> @mpf.RawMpf raise MPError {
  x.pow_int(n, self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Exponential `exp(x)` for real `mpf`.
pub fn MPContext::exp(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  checked_mpf_exp(x, self.prec, self.rounding)
}

///|
/// Natural logarithm `ln(x)` on reals.
///
/// Raises `MPError::DomainError` when called outside the real domain.
pub fn MPContext::ln(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libelefun.ln(x, self.prec, self.rounding) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Sine function on reals.
pub fn MPContext::sin(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  checked_mpf_sin(x, self.prec, self.rounding)
}

///|
/// Cosine function on reals.
pub fn MPContext::cos(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  checked_mpf_cos(x, self.prec, self.rounding)
}

///|
/// Tangent function on reals.
pub fn MPContext::tan(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  checked_mpf_tan(x, self.prec, self.rounding)
}

///|
/// Euler gamma `Gamma(x)` for real arguments.
///
/// Pole/domain behavior is mapped to `MPError::PoleError` and
/// `MPError::DomainError`, matching mpmath-style semantics.
pub fn MPContext::gamma(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.gamma(x, self.prec, self.rounding) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Riemann zeta `zeta(s)` (or alternating eta form when `alt=true`) on reals.
///
/// `alt=true` maps to mpmath's alternate zeta continuation behavior.
pub fn MPContext::zeta(
  self : MPContext,
  s : @mpf.RawMpf,
  alt? : Bool = false,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.zeta(s, self.prec, self.rounding, alt~) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn is_real_integer(x : @mpf.RawMpf) -> Bool {
  if !x.is_finite() {
    return false
  }
  x == x.round_to_integer(Nearest)
}

///|
/// Complex principal logarithm.
///
/// Equivalent to mpmath principal branch `log(z)`. Explicitly rejects `z=0`
/// with `MPError::PoleError`.
pub fn MPContext::complex_log(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if z == @mpc.RawMpc::zero() {
    raise PoleError("complex_log: logarithm singular at zero")
  }
  z.log(self.prec, self.rounding) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Complex principal square root.
///
/// Branch behavior follows mpmath principal square root convention.
pub fn MPContext::complex_sqrt(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  checked_mpc_sqrt(z, self.prec, self.rounding)
}

///|
/// Complex power `z^w` on principal branches.
///
/// Matches mpmath's principal-branch definition and explicitly guards the
/// ambiguous `0^w` cases with non-positive/complex exponents.
pub fn MPContext::complex_pow(
  self : MPContext,
  z : @mpc.RawMpc,
  w : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if w == @mpc.RawMpc::zero() {
    return @mpc.RawMpc::one()
  }
  if z == @mpc.RawMpc::zero() &&
    (w.imag != @mpf.RawMpf::zero() || w.real.signum() <= 0) {
    raise DomainError(
      "complex_pow: zero base with non-positive/complex exponent",
    )
  }
  z.pow(w, self.prec, self.rounding) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Complex gamma function.
///
/// Raises `MPError::PoleError` at non-positive integers on the real axis.
pub fn MPContext::complex_gamma(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if z.imag == @mpf.RawMpf::zero() &&
    z.real <= @mpf.RawMpf::zero() &&
    is_real_integer(z.real) {
    raise PoleError("complex_gamma: pole at non-positive integer")
  }
  checked_mpc_gamma(z, self.prec, self.rounding)
}

///|
/// Complex zeta continuation.
///
/// At `s=1`, returns pole error for standard zeta and `log(2)` for alternating
/// zeta (`alt=true`), consistent with mpmath expectations.
pub fn MPContext::complex_zeta(
  self : MPContext,
  s : @mpc.RawMpc,
  alt? : Bool = false,
) -> @mpc.RawMpc raise MPError {
  if s.imag == @mpf.RawMpf::zero() && s.real == @mpf.RawMpf::one() {
    return if alt {
      @mpc.RawMpc::new(
        checked_mpf_ln2(self.prec, self.rounding),
        @mpf.RawMpf::zero(),
      )
    } else {
      raise PoleError("complex_zeta: pole at s=1")
    }
  }
  checked_mpc_zeta(s, self.prec, self.rounding, alt~)
}

///|
fn lift_real(y : @mpf.RawMpf) -> @mpc.RawMpc {
  @mpc.RawMpc::new(y, @mpf.RawMpf::zero())
}

///|
fn e1_complex_principal(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  if x.is_nan() {
    return @mpc.RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if x.is_zero() {
    return @mpc.RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero())
  }
  if x.sign == 1 {
    let p = if prec > 0 { prec + 24 } else { 64 }
    let ax = x.abs(p, Nearest)
    let ei = @libhyper.ei(ax, p, Nearest) catch {
      err => raise from_libhyper_error(err)
    }
    let re = ei.negated(p, Nearest)
    let im = checked_mpf_pi(p, Nearest).negated(p, Nearest)
    return @mpc.RawMpc::new(re, im).rounded(prec, rnd)
  }
  let re = @libhyper.e1(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
  lift_real(re)
}

///|
/// Real-valued `E1(x)` helper.
///
/// For `x < 0`, real `E1` is not single-valued; this API reports
/// `MPError::ComplexResult` to force callers to use complex principal value.
pub fn MPContext::e1_real(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if !x.is_nan() && !x.is_zero() && x.sign == 1 {
    raise ComplexResult("e1_real: E1(x) for x < 0")
  }
  @libhyper.e1(x, self.prec, self.rounding) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Complex principal value of `E1(x)` for real `x`.
///
/// For negative reals this follows the principal branch
/// `E1(x) = -Ei(-x) - i*pi`.
pub fn MPContext::e1(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpc.RawMpc raise MPError {
  e1_complex_principal(x, self.prec, self.rounding)
}

///|
/// Exponential integral family wrapper:
/// - `gamma=false`: `E_n(x)`
/// - `gamma=true`: upper incomplete gamma form.
///
/// For negative real arguments in the non-gamma form, this function returns the
/// complex principal value instead of failing, matching mpmath branch behavior.
pub fn MPContext::exponential_integral(
  self : MPContext,
  n : Int,
  x : @mpf.RawMpf,
  gamma? : Bool = false,
) -> @mpc.RawMpc raise MPError {
  if n <= 0 {
    raise ValueError("exponential_integral: n must be positive")
  }
  if x.is_nan() {
    return @mpc.RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if gamma && x.is_infinite() {
    return if x.sign == 0 {
      @mpc.RawMpc::zero()
    } else {
      @mpc.RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    }
  }
  if !gamma && x.sign == 1 && !x.is_zero() {
    let p = if self.prec > 0 { self.prec + 24 } else { 64 }
    let mut en = e1_complex_principal(x, p, Nearest)
    let ex = lift_real(checked_mpf_exp(x.negated(p, Nearest), p, Nearest))
    let xz = lift_real(x.rounded(p, Nearest))
    let mut k = 1
    while k < n {
      en = checked_mpc_div_mpf(
        ex.sub(xz.mul(en, p, Nearest), p, Nearest),
        @mpf.RawMpf::from_int(k),
        p,
        Nearest,
      )
      k += 1
    }
    return en.rounded(self.prec, self.rounding)
  }
  if gamma && x.sign == 1 && !x.is_zero() {
    let p = if self.prec > 0 { self.prec + 24 } else { 64 }
    let xz = lift_real(x.rounded(p, Nearest))
    let ex = checked_mpc_exp(xz.negated(p, Nearest), p, Nearest)
    let mut sum = @mpc.RawMpc::one()
    let mut term = @mpc.RawMpc::one()
    for k in 1..<n {
      term = checked_mpc_div_mpf(
        term.mul(xz, p, Nearest),
        @mpf.RawMpf::from_int(k),
        p,
        Nearest,
      )
      sum = sum.add(term, p, Nearest)
    }
    let fac = @gammazeta.factorial(n - 1, p, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    return ex
      .mul(sum, p, Nearest)
      .mul_real(fac, p, Nearest)
      .rounded(self.prec, self.rounding)
  }
  let re = @libhyper.exponential_integral(
    n,
    x,
    self.prec,
    self.rounding,
    gamma~,
  ) catch {
    err => raise from_libhyper_error(err)
  }
  lift_real(re)
}

///|
fn identify_work_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 32
  } else {
    96
  }
}

///|
fn identify_decimals(prec : Int) -> Int {
  if prec > 0 {
    let dps = prec / 6
    if dps > 12 {
      dps
    } else {
      12
    }
  } else {
    18
  }
}

///|
fn identify_tol(prec : Int) -> @mpf.RawMpf raise MPError {
  let dps = identify_decimals(prec)
  @mpf.RawMpf::parse("1e-\{dps}", prec=identify_work_prec(prec), rnd=Nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_close(
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  p : Int,
  tol : @mpf.RawMpf,
) -> Bool {
  let err = a.sub(b, p, Nearest).abs(p, Nearest)
  err <= tol
}

///|
fn format_ratio(num : Int, den : Int) -> String {
  if den == 1 {
    "\{num}"
  } else {
    "(\{num}/\{den})"
  }
}

///|
fn find_small_rational(
  x : @mpf.RawMpf,
  p : Int,
  tol : @mpf.RawMpf,
  max_num : Int,
  max_den : Int,
) -> (Int, Int)? raise MPError {
  for den in 1..<=max_den {
    for num in -max_num..<=max_num {
      let cand = @mpf.RawMpf::from_int(num).div(
        @mpf.RawMpf::from_int(den),
        p,
        Nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      if mpf_close(x, cand, p, tol) {
        return Some((num, den))
      }
    }
  }
  None
}

///|
fn identify_by_basis(
  x : @mpf.RawMpf,
  bases : Map[String, @mpf.RawMpf],
  p : Int,
  tol : @mpf.RawMpf,
) -> String? raise MPError {
  for name, base in bases {
    if base.is_zero() || !base.is_finite() {
      continue
    }
    let ratio = x.div(base, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    match find_small_rational(ratio, p, tol, 512, 192) {
      Some((num, den)) => return Some("(\{format_ratio(num, den)}*\{name})")
      None => ()
    }
    for off in -8..<=8 {
      let shifted = x.sub(@mpf.RawMpf::from_int(off), p, Nearest)
      let ratio2 = shifted.div(base, p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
      match find_small_rational(ratio2, p, tol, 128, 128) {
        Some((num, den)) => {
          if num == 0 {
            continue
          }
          return Some("(\{off} + \{format_ratio(num, den)}*\{name})")
        }
        None => ()
      }
    }
  }
  None
}

///|
/// Symbolic identification for common real constants and combinations.
///
/// Supported patterns:
/// - small integer/rational values
/// - `exp(n)`, `log(n)` for small integers
/// - linear/rational combinations against provided `constants`
/// - basic builtins (`pi`, `log(2)`, `pi**4`)
pub fn MPContext::identify(
  self : MPContext,
  x : @mpf.RawMpf,
  constants? : Map[String, @mpf.RawMpf] = Map([]),
) -> String raise MPError {
  let p = identify_work_prec(self.prec)
  let tol = identify_tol(self.prec)
  if x.is_nan() {
    return "nan"
  }
  if x.is_infinite() {
    return if x.sign == 1 { "-inf" } else { "inf" }
  }
  if x.is_zero() {
    return "0"
  }

  for n in -10..<=10 {
    let e_n = checked_mpf_exp(@mpf.RawMpf::from_int(n), p, Nearest)
    if mpf_close(x, e_n, p, tol) {
      return "exp(\{n})"
    }
  }

  for n in 2..<=20 {
    let l_n = @libelefun.ln(@mpf.RawMpf::from_int(n), p, Nearest) catch {
      err => raise from_libelefun_error(err)
    }
    if mpf_close(x, l_n, p, tol) {
      return "log(\{n})"
    }
  }

  let pi = checked_mpf_pi(p, Nearest)
  if x.signum() > 0 {
    let ln_x = @libelefun.ln(x, p, Nearest) catch {
      err => raise from_libelefun_error(err)
    }
    let ratio = ln_x.div(pi, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    match find_small_rational(ratio, p, tol, 64, 32) {
      Some((num, den)) => return "exp((\{format_ratio(num, den)}*pi))"
      None => ()
    }
  }

  match identify_by_basis(x, constants, p, tol) {
    Some(expr) => return expr
    None => ()
  }

  let builtins : Map[String, @mpf.RawMpf] = {
    "pi": pi,
    "log(2)": checked_mpf_ln2(p, Nearest),
  }
  let pi4 = pi.pow_int(4, p, Nearest) catch { err => raise from_mpf_error(err) }
  builtins["pi**4"] = pi4
  match identify_by_basis(x, builtins, p, tol) {
    Some(expr) => return expr
    None => ()
  }

  match find_small_rational(x, p, tol, 2048, 256) {
    Some((num, den)) => {
      if den == 1 {
        return "\{num}"
      }
      return "(\{num}/\{den})"
    }
    None => ()
  }

  self.to_string(x, dps=identify_decimals(self.prec))
}
