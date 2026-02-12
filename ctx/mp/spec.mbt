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
pub fn new(prec : Int, rounding : @mpf.RoundMode) -> MPContext {
  { prec, rounding }
}

///|
pub fn MPContext::precision(self : MPContext) -> Int {
  self.prec
}

///|
pub fn MPContext::round_mode(self : MPContext) -> @mpf.RoundMode {
  self.rounding
}

///|
pub fn MPContext::make_int(self : MPContext, n : Int) -> @mpf.RawMpf {
  @mpf.from_man_exp(BigInt::from_int(n), 0, self.prec, self.rounding)
}

///|
pub fn MPContext::make_float(
  self : MPContext,
  s : String,
) -> @mpf.RawMpf raise MPError {
  @mpf.from_str(s, prec=self.prec, rnd=self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
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
pub fn MPContext::make_complex(
  self : MPContext,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> @mpc.RawMpc {
  ignore(self)
  @mpc.from_parts(re, im)
}

///|
pub fn MPContext::complex_to_string(
  self : MPContext,
  z : @mpc.RawMpc,
  dps? : Int = 15,
) -> String {
  ignore(self)
  @mpc.mpc_to_str(z, dps~)
}

///|
pub fn MPContext::add(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_add(x, y, self.prec, self.rounding)
}

///|
pub fn MPContext::sub(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_sub(x, y, self.prec, self.rounding)
}

///|
pub fn MPContext::mul(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf {
  @mpf.mpf_mul(x, y, self.prec, self.rounding)
}

///|
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
pub fn MPContext::neg(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_neg(x, self.prec, self.rounding)
}

///|
pub fn MPContext::abs(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_abs(x, self.prec, self.rounding)
}

///|
pub fn MPContext::sqrt(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @mpf.mpf_sqrt(x, self.prec, self.rounding) catch {
    err => raise from_mpf_error(err)
  }
}

///|
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
pub fn MPContext::exp(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_exp(x, self.prec, self.rounding)
}

///|
pub fn MPContext::ln(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libelefun.mpf_ln(x, self.prec, self.rounding) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
pub fn MPContext::sin(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_sin(x, self.prec, self.rounding)
}

///|
pub fn MPContext::cos(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_cos(x, self.prec, self.rounding)
}

///|
pub fn MPContext::tan(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_tan(x, self.prec, self.rounding)
}

///|
pub fn MPContext::gamma(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.mpf_gamma(x, self.prec, self.rounding) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
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
pub fn MPContext::complex_sqrt(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc {
  @mpc.mpc_sqrt(z, self.prec, self.rounding)
}

///|
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
pub fn MPContext::e1(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpc.RawMpc raise MPError {
  e1_complex_principal(x, self.prec, self.rounding)
}

///|
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
