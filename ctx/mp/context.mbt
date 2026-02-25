///|
/// Minimal high-level context for libmp.
pub struct MPContext {
  prec : Int
  rounding : @mpf.RoundMode
} derive(Show, Eq)

///|
pub(all) suberror MPError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
  ConvergenceError(String)
} derive(Show, Eq)

///|
fn from_mpf_error(err : @mpf.MpfError) -> MPError {
  match err {
    @mpf.MpfError::ValueError(msg) => MPError::ValueError(msg)
    @mpf.MpfError::DomainError(msg) => MPError::DomainError(msg)
    @mpf.MpfError::DivisionByZero(msg) => MPError::PoleError(msg)
    @mpf.MpfError::ParseError(msg) => MPError::ValueError(msg)
    @mpf.MpfError::FormatError(msg) => MPError::ValueError(msg)
    @mpf.MpfError::UnsupportedError(msg) => MPError::ValueError(msg)
  }
}

///|
fn from_libelefun_error(err : @libelefun.LibElefunError) -> MPError {
  match err {
    @libelefun.LibElefunError::ValueError(msg) => MPError::ValueError(msg)
    @libelefun.LibElefunError::DomainError(msg) => MPError::DomainError(msg)
    @libelefun.LibElefunError::ComplexResult(msg) => MPError::ComplexResult(msg)
  }
}

///|
fn from_libhyper_error(err : @libhyper.LibHyperError) -> MPError {
  match err {
    @libhyper.LibHyperError::ValueError(msg) => MPError::ValueError(msg)
    @libhyper.LibHyperError::DomainError(msg) => MPError::DomainError(msg)
    @libhyper.LibHyperError::PoleError(msg) => MPError::PoleError(msg)
    @libhyper.LibHyperError::ComplexResult(msg) => MPError::ComplexResult(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> MPError {
  match err {
    @gammazeta.GammaZetaError::ValueError(msg) => MPError::ValueError(msg)
    @gammazeta.GammaZetaError::DomainError(msg) => MPError::DomainError(msg)
    @gammazeta.GammaZetaError::PoleError(msg) => MPError::PoleError(msg)
  }
}

///|
fn from_mpc_error(err : @mpc.MpcError) -> MPError {
  match err {
    @mpc.MpcError::ValueError(msg) => MPError::ValueError(msg)
    @mpc.MpcError::DomainError(msg) => MPError::DomainError(msg)
    @mpc.MpcError::PoleError(msg) => MPError::PoleError(msg)
  }
}

///|
/// Create a high-level arbitrary-precision context.
///
/// This is the MoonBit counterpart of constructing an `mpmath.mp`-like runtime
/// state. `prec` is binary precision (bits), and `rounding` controls final
/// rounding for wrapper operations.
pub fn new(prec : Int, rounding : @mpf.RoundMode) -> MPContext {
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
pub fn MPContext::make_int(self : MPContext, n : Int) -> @mpf.RawMpf {
  @mpf.from_man_exp(BigInt::from_int(n), 0, self.prec, self.rounding)
}

///|
/// Parse a decimal string into an `mpf` using context precision.
///
/// Compatible with mpmath-style numeric spellings (`inf`, `nan`, exponents,
/// signed literals). Parse failures are normalized to `MPError::ValueError`.
pub fn MPContext::make_float(
  self : MPContext,
  s : String,
) -> @mpf.RawMpf raise MPError {
  @mpf.from_str(s, prec=self.prec, rnd=self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Convert an `mpf` to a plain decimal string with optional `dps`.
///
/// This wraps `@mpf.to_str_opts` and follows mpmath's default user-facing
/// conversion style for finite/special values.
pub fn MPContext::to_string(
  self : MPContext,
  x : @mpf.RawMpf,
  dps? : Int = 15,
) -> String raise MPError {
  ignore(self)
  @mpf.to_str_opts(x, dps~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Format an `mpf` using mpmath/Python-like format mini-language subset.
///
/// `format_spec` is forwarded to `@mpf.format_mpf` (alignment, sign, percent,
/// base/precision options implemented by libmp).
pub fn MPContext::format(
  self : MPContext,
  x : @mpf.RawMpf,
  format_spec : String,
  dps? : Int = 15,
) -> String raise MPError {
  ignore(self)
  @mpf.format_mpf(x, format_spec, dps~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Build a complex number from real and imaginary `mpf` parts.
pub fn MPContext::make_complex(
  self : MPContext,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> @mpc.RawMpc {
  ignore(self)
  @mpc.from_parts(re, im)
}

///|
/// Convert an `mpc` value to string in `(re + im*j)` style.
///
/// `dps` controls displayed digits. Behavior follows `mpmath.nstr`-style
/// compact conversion for complex numbers.
pub fn MPContext::complex_to_string(
  self : MPContext,
  z : @mpc.RawMpc,
  dps? : Int = 15,
) -> String {
  ignore(self)
  @mpc.mpc_to_str(z, dps~)
}

///|
/// Context-aware floating-point addition.
pub fn MPContext::add(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_add(x, y, self.prec, self.rounding)
}

///|
/// Context-aware floating-point subtraction.
pub fn MPContext::sub(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_sub(x, y, self.prec, self.rounding)
}

///|
/// Context-aware floating-point multiplication.
pub fn MPContext::mul(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_mul(x, y, self.prec, self.rounding)
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
  @mpf.mpf_div(x, y, self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Unary negation with context rounding.
pub fn MPContext::neg(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_neg(x, self.prec, self.rounding)
}

///|
/// Absolute value with context rounding.
pub fn MPContext::abs(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_abs(x, self.prec, self.rounding)
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
  @mpf.mpf_sqrt(x, self.prec, self.rounding) catch {
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
  @mpf.mpf_pow_int(x, n, self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
/// Exponential `exp(x)` for real `mpf`.
pub fn MPContext::exp(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_exp(x, self.prec, self.rounding)
}

///|
/// Natural logarithm `ln(x)` on reals.
///
/// Raises `MPError::DomainError` when called outside the real domain.
pub fn MPContext::ln(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libelefun.mpf_ln(x, self.prec, self.rounding) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
/// Sine function on reals.
pub fn MPContext::sin(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_sin(x, self.prec, self.rounding)
}

///|
/// Cosine function on reals.
pub fn MPContext::cos(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_cos(x, self.prec, self.rounding)
}

///|
/// Tangent function on reals.
pub fn MPContext::tan(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_tan(x, self.prec, self.rounding)
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
  @gammazeta.mpf_gamma(x, self.prec, self.rounding) catch {
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
  @gammazeta.mpf_zeta(s, self.prec, self.rounding, alt~) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn is_real_integer(x : @mpf.RawMpf) -> Bool {
  if !@mpf.is_finite(x) {
    return false
  }
  @mpf.mpf_eq(x, @mpf.mpf_round_int(x, @mpf.round_nearest))
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
  if z == @mpc.zero() {
    raise MPError::PoleError("complex_log: logarithm singular at zero")
  }
  @mpc.mpc_log(z, self.prec, self.rounding) catch {
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
) -> @mpc.RawMpc {
  @mpc.mpc_sqrt(z, self.prec, self.rounding)
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
  if w == @mpc.zero() {
    return @mpc.one()
  }
  if z == @mpc.zero() && (w.imag != @mpf.fzero || @mpf.mpf_sign(w.real) <= 0) {
    raise MPError::DomainError(
      "complex_pow: zero base with non-positive/complex exponent",
    )
  }
  @mpc.mpc_pow(z, w, self.prec, self.rounding) catch {
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
  if z.imag == @mpf.fzero &&
    @mpf.mpf_le(z.real, @mpf.fzero) &&
    is_real_integer(z.real) {
    raise MPError::PoleError("complex_gamma: pole at non-positive integer")
  }
  @mpc.mpc_gamma(z, self.prec, self.rounding)
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
  if s.imag == @mpf.fzero && @mpf.mpf_eq(s.real, @mpf.fone) {
    return if alt {
      @mpc.from_parts(@libelefun.mpf_ln2(self.prec, self.rounding), @mpf.fzero)
    } else {
      raise MPError::PoleError("complex_zeta: pole at s=1")
    }
  }
  @mpc.mpc_zeta(s, self.prec, self.rounding, alt~)
}

///|
fn lift_real(y : @mpf.RawMpf) -> @mpc.RawMpc {
  @mpc.from_parts(y, @mpf.fzero)
}

///|
fn e1_complex_principal(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MPError {
  if @mpf.is_nan(x) {
    return @mpc.from_parts(@mpf.fnan, @mpf.fnan)
  }
  if @mpf.is_zero(x) {
    return @mpc.from_parts(@mpf.finf, @mpf.fzero)
  }
  if x.sign == 1 {
    let p = if prec > 0 { prec + 24 } else { 64 }
    let ax = @mpf.mpf_abs(x, p, @mpf.round_nearest)
    let ei = @libhyper.mpf_ei(ax, p, @mpf.round_nearest)
    let re = @mpf.mpf_neg(ei, p, @mpf.round_nearest)
    let im = @mpf.mpf_neg(
      @libelefun.mpf_pi(p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    return @mpc.mpc_pos(@mpc.from_parts(re, im), prec, rnd)
  }
  let re = @libhyper.mpf_e1(x, prec, rnd) catch {
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
  if !@mpf.is_nan(x) && !@mpf.is_zero(x) && x.sign == 1 {
    raise MPError::ComplexResult("e1_real: E1(x) for x < 0")
  }
  @libhyper.mpf_e1(x, self.prec, self.rounding) catch {
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
pub fn MPContext::expint(
  self : MPContext,
  n : Int,
  x : @mpf.RawMpf,
  gamma? : Bool = false,
) -> @mpc.RawMpc raise MPError {
  if n <= 0 {
    raise MPError::ValueError("expint: n must be positive")
  }
  if @mpf.is_nan(x) {
    return @mpc.from_parts(@mpf.fnan, @mpf.fnan)
  }
  if gamma && @mpf.is_inf(x) {
    return if x.sign == 0 {
      @mpc.zero()
    } else {
      @mpc.from_parts(@mpf.fnan, @mpf.fnan)
    }
  }
  if !gamma && x.sign == 1 && !@mpf.is_zero(x) {
    let p = if self.prec > 0 { self.prec + 24 } else { 64 }
    let mut en = e1_complex_principal(x, p, @mpf.round_nearest)
    let ex = lift_real(
      @libelefun.mpf_exp(
        @mpf.mpf_neg(x, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
    )
    let xz = lift_real(@mpf.mpf_pos(x, p, @mpf.round_nearest))
    let mut k = 1
    while k < n {
      en = @mpc.mpc_div_mpf(
        @mpc.mpc_sub(
          ex,
          @mpc.mpc_mul(xz, en, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        @mpf.from_int(k),
        p,
        @mpf.round_nearest,
      )
      k += 1
    }
    return @mpc.mpc_pos(en, self.prec, self.rounding)
  }
  if gamma && x.sign == 1 && !@mpf.is_zero(x) {
    let p = if self.prec > 0 { self.prec + 24 } else { 64 }
    let xz = lift_real(@mpf.mpf_pos(x, p, @mpf.round_nearest))
    let ex = @mpc.mpc_exp(
      @mpc.mpc_neg(xz, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let mut sum = @mpc.one()
    let mut term = @mpc.one()
    for k in 1..<n {
      term = @mpc.mpc_div_mpf(
        @mpc.mpc_mul(term, xz, p, @mpf.round_nearest),
        @mpf.from_int(k),
        p,
        @mpf.round_nearest,
      )
      sum = @mpc.mpc_add(sum, term, p, @mpf.round_nearest)
    }
    let fac = @gammazeta.mpf_factorial(n - 1, p, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    return @mpc.mpc_pos(
      @mpc.mpc_mul_mpf(
        @mpc.mpc_mul(ex, sum, p, @mpf.round_nearest),
        fac,
        p,
        @mpf.round_nearest,
      ),
      self.prec,
      self.rounding,
    )
  }
  let re = @libhyper.mpf_expint(n, x, self.prec, self.rounding, gamma~) catch {
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
fn identify_tol(prec : Int) -> @mpf.RawMpf {
  let dps = identify_decimals(prec)
  @mpf.from_str(
    "1e-\{dps}",
    prec=identify_work_prec(prec),
    rnd=@mpf.round_nearest,
  ) catch {
    _ => @mpf.from_man_exp(1N, -48, 0, @mpf.round_down)
  }
}

///|
fn mpf_close(
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  p : Int,
  tol : @mpf.RawMpf,
) -> Bool {
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(a, b, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_le(err, tol)
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
) -> (Int, Int)? {
  for den in 1..<=max_den {
    for num in -max_num..<=max_num {
      let cand = @mpf.mpf_div(
        @mpf.from_int(num),
        @mpf.from_int(den),
        p,
        @mpf.round_nearest,
      ) catch {
        _ => @mpf.fnan
      }
      if !@mpf.is_nan(cand) && mpf_close(x, cand, p, tol) {
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
) -> String? {
  for name, base in bases {
    if @mpf.is_zero(base) || !@mpf.is_finite(base) {
      continue
    }
    let ratio = @mpf.mpf_div(x, base, p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    if !@mpf.is_nan(ratio) {
      match find_small_rational(ratio, p, tol, 512, 192) {
        Some((num, den)) => return Some("(\{format_ratio(num, den)}*\{name})")
        None => ()
      }
    }
    for off in -8..<=8 {
      let shifted = @mpf.mpf_sub(x, @mpf.from_int(off), p, @mpf.round_nearest)
      let ratio2 = @mpf.mpf_div(shifted, base, p, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
      if @mpf.is_nan(ratio2) {
        continue
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
/// Minimal symbolic identify subset for Stage-B migration.
///
/// Supported patterns:
/// - small integer/rational values
/// - `exp(n)`, `log(n)` for small integers
/// - linear/rational combinations against provided `constants`
/// - basic builtins (`pi`, `log(2)`, `pi**4`)
pub fn MPContext::identify(
  self : MPContext,
  x : @mpf.RawMpf,
  constants? : Map[String, @mpf.RawMpf] = {},
) -> String raise MPError {
  let p = identify_work_prec(self.prec)
  let tol = identify_tol(self.prec)
  if @mpf.is_nan(x) {
    return "nan"
  }
  if @mpf.is_inf(x) {
    return if x.sign == 1 { "-inf" } else { "inf" }
  }
  if @mpf.is_zero(x) {
    return "0"
  }

  for n in -10..<=10 {
    let e_n = @libelefun.mpf_exp(@mpf.from_int(n), p, @mpf.round_nearest)
    if mpf_close(x, e_n, p, tol) {
      return "exp(\{n})"
    }
  }

  for n in 2..<=20 {
    let l_n = @libelefun.mpf_ln(@mpf.from_int(n), p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    if !@mpf.is_nan(l_n) && mpf_close(x, l_n, p, tol) {
      return "log(\{n})"
    }
  }

  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  if @mpf.mpf_sign(x) > 0 {
    let ln_x = @libelefun.mpf_ln(x, p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    if !@mpf.is_nan(ln_x) {
      let ratio = @mpf.mpf_div(ln_x, pi, p, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
      if !@mpf.is_nan(ratio) {
        match find_small_rational(ratio, p, tol, 64, 32) {
          Some((num, den)) => return "exp((\{format_ratio(num, den)}*pi))"
          None => ()
        }
      }
    }
  }

  match identify_by_basis(x, constants, p, tol) {
    Some(expr) => return expr
    None => ()
  }

  let builtins : Map[String, @mpf.RawMpf] = {
    "pi": pi,
    "log(2)": @libelefun.mpf_ln2(p, @mpf.round_nearest),
  }
  let pi4 = @mpf.mpf_pow_int(pi, 4, p, @mpf.round_nearest) catch {
    _ => @mpf.fnan
  }
  if !@mpf.is_nan(pi4) {
    builtins["pi**4"] = pi4
  }
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
