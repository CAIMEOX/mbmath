///|
/// Minimal high-level context for libmp.
pub struct MPContext {
  prec : Int
  rounding : @mpf.RoundMode
} derive(Show, Eq)

///|
pub(all) enum MPError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
  ComplexResult(String)
} derive(Show, Eq)

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
pub fn MPContext::make_float(self : MPContext, s : String) -> @mpf.RawMpf {
  @mpf.from_str(s, prec=self.prec, rnd=self.rounding)
}

///|
pub fn MPContext::to_string(
  self : MPContext,
  x : @mpf.RawMpf,
  dps? : Int = 15,
) -> String {
  ignore(self)
  @mpf.to_str_opts(x, dps~)
}

///|
pub fn MPContext::format(
  self : MPContext,
  x : @mpf.RawMpf,
  format_spec : String,
  dps? : Int = 15,
) -> String {
  ignore(self)
  @mpf.format_mpf(x, format_spec, dps~)
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
) -> @mpf.RawMpf {
  @mpf.mpf_div(x, y, self.prec, self.rounding)
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
pub fn MPContext::sqrt(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_sqrt(x, self.prec, self.rounding)
}

///|
pub fn MPContext::pow_int(
  self : MPContext,
  x : @mpf.RawMpf,
  n : Int,
) -> @mpf.RawMpf {
  @mpf.mpf_pow_int(x, n, self.prec, self.rounding)
}

///|
pub fn MPContext::exp(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_exp(x, self.prec, self.rounding)
}

///|
pub fn MPContext::ln(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @libelefun.mpf_ln(x, self.prec, self.rounding)
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
pub fn MPContext::gamma(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @gammazeta.mpf_gamma(x, self.prec, self.rounding)
}

///|
pub fn MPContext::zeta(
  self : MPContext,
  s : @mpf.RawMpf,
  alt? : Bool = false,
) -> @mpf.RawMpf {
  @gammazeta.mpf_zeta(s, self.prec, self.rounding, alt~)
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
) -> Result[@mpc.RawMpc, MPError] {
  if z == @mpc.zero() {
    return Err(MPError::PoleError("complex_log: logarithm singular at zero"))
  }
  Ok(@mpc.mpc_log(z, self.prec, self.rounding))
}

///|
pub fn MPContext::complex_sqrt(
  self : MPContext,
  z : @mpc.RawMpc,
) -> Result[@mpc.RawMpc, MPError] {
  Ok(@mpc.mpc_sqrt(z, self.prec, self.rounding))
}

///|
pub fn MPContext::complex_pow(
  self : MPContext,
  z : @mpc.RawMpc,
  w : @mpc.RawMpc,
) -> Result[@mpc.RawMpc, MPError] {
  if w == @mpc.zero() {
    return Ok(@mpc.one())
  }
  if z == @mpc.zero() && (w.imag != @mpf.fzero || @mpf.mpf_sign(w.real) <= 0) {
    return Err(
      MPError::DomainError(
        "complex_pow: zero base with non-positive/complex exponent",
      ),
    )
  }
  Ok(@mpc.mpc_pow(z, w, self.prec, self.rounding))
}

///|
pub fn MPContext::complex_gamma(
  self : MPContext,
  z : @mpc.RawMpc,
) -> Result[@mpc.RawMpc, MPError] {
  if z.imag == @mpf.fzero &&
    @mpf.mpf_le(z.real, @mpf.fzero) &&
    is_real_integer(z.real) {
    return Err(
      MPError::PoleError("complex_gamma: pole at non-positive integer"),
    )
  }
  Ok(@mpc.mpc_gamma(z, self.prec, self.rounding))
}

///|
pub fn MPContext::complex_zeta(
  self : MPContext,
  s : @mpc.RawMpc,
  alt? : Bool = false,
) -> Result[@mpc.RawMpc, MPError] {
  if s.imag == @mpf.fzero && @mpf.mpf_eq(s.real, @mpf.fone) {
    return if alt {
      Ok(
        @mpc.from_parts(
          @libelefun.mpf_ln2(self.prec, self.rounding),
          @mpf.fzero,
        ),
      )
    } else {
      Err(MPError::PoleError("complex_zeta: pole at s=1"))
    }
  }
  Ok(@mpc.mpc_zeta(s, self.prec, self.rounding, alt~))
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
) -> @mpc.RawMpc {
  if @mpf.is_nan(x) {
    return @mpc.from_parts(@mpf.fnan, @mpf.fnan)
  }
  if @mpf.is_zero(x) {
    return @mpc.from_parts(@mpf.finf, @mpf.fzero)
  }
  if x.sign == 1 {
    let p = if prec > 0 { prec + 24 } else { 64 }
    let ax = @mpf.mpf_abs(x, p, @mpf.round_nearest)
    let re = @mpf.mpf_neg(
      @libhyper.mpf_ei(ax, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let im = @mpf.mpf_neg(
      @libelefun.mpf_pi(p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    return @mpc.mpc_pos(@mpc.from_parts(re, im), prec, rnd)
  }
  lift_real(@libhyper.mpf_e1(x, prec, rnd))
}

///|
pub fn MPContext::e1_real(
  self : MPContext,
  x : @mpf.RawMpf,
) -> Result[@mpf.RawMpf, MPError] {
  if !@mpf.is_nan(x) && !@mpf.is_zero(x) && x.sign == 1 {
    return Err(MPError::ComplexResult("e1_real: E1(x) for x < 0"))
  }
  Ok(@libhyper.mpf_e1(x, self.prec, self.rounding))
}

///|
pub fn MPContext::e1(self : MPContext, x : @mpf.RawMpf) -> @mpc.RawMpc {
  e1_complex_principal(x, self.prec, self.rounding)
}

///|
pub fn MPContext::expint(
  self : MPContext,
  n : Int,
  x : @mpf.RawMpf,
  gamma? : Bool = false,
) -> Result[@mpc.RawMpc, MPError] {
  if n <= 0 {
    return Err(MPError::ValueError("expint: n must be positive"))
  }
  if @mpf.is_nan(x) {
    return Ok(@mpc.from_parts(@mpf.fnan, @mpf.fnan))
  }
  if gamma && @mpf.is_inf(x) {
    return if x.sign == 0 {
      Ok(@mpc.zero())
    } else {
      Ok(@mpc.from_parts(@mpf.fnan, @mpf.fnan))
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
    return Ok(@mpc.mpc_pos(en, self.prec, self.rounding))
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
    let fac = @gammazeta.mpf_factorial(n - 1, p, @mpf.round_nearest)
    return Ok(
      @mpc.mpc_pos(
        @mpc.mpc_mul_mpf(
          @mpc.mpc_mul(ex, sum, p, @mpf.round_nearest),
          fac,
          p,
          @mpf.round_nearest,
        ),
        self.prec,
        self.rounding,
      ),
    )
  }
  Ok(lift_real(@libhyper.mpf_expint(n, x, self.prec, self.rounding, gamma~)))
}
