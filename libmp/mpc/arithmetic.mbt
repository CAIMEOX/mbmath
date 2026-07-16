///|
fn work_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 10
  } else {
    20
  }
}

///|
fn from_mpf_error(err : @mpf.MpfError) -> MpcError {
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
fn from_libelefun_error(err : @libelefun.LibElefunError) -> MpcError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    ComplexResult(msg) => DomainError(msg)
  }
}

///|
fn from_libhyper_error(err : @libhyper.LibHyperError) -> MpcError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
    ComplexResult(msg) => DomainError(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> MpcError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
  }
}

///|
fn mpf_div_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  x.div(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_rdiv_int_checked(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  x.int_divided_by(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_sqrt_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  x.sqrt(prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_pow_int_checked(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  x.pow_int(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_hypot_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  x.hypot(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_log_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.log(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_atan2_checked(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.atan2(y, x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_exp_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.exp(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_sin_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.sin(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cos_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.cos(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_sinh_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.sinh(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cosh_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.cosh(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_pi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cos_pi_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.cos_pi(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_sin_pi_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.sin_pi(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cos_sin_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 0,
  pi? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MpcError {
  @libelefun.cos_sin(x, prec, rnd, which~, times_pi=pi) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cos_sin_pi_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MpcError {
  @libelefun.cos_sin_pi(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cosh_sinh_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  tanh? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MpcError {
  @libelefun.cosh_sinh(x, prec, rnd, only_tanh=tanh) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_phi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.phi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpc_pow_checked(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.pow(w, prec, rnd)
}

///|
pub fn RawMpc::one() -> RawMpc {
  { real: @mpf.RawMpf::one(), imag: @mpf.RawMpf::zero() }
}

///|
pub fn RawMpc::new(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpc {
  { real, imag }
}

///|
pub fn RawMpc::is_infinite(z : RawMpc) -> Bool {
  z.real.is_infinite() || z.imag.is_infinite()
}

///|
pub fn RawMpc::is_non_finite(z : RawMpc) -> Bool {
  z.is_infinite() || z.real.is_nan() || z.imag.is_nan()
}

///|
pub fn RawMpc::is_nonzero(z : RawMpc) -> Bool {
  z != RawMpc::zero()
}

///|
pub fn RawMpc::rounded(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  { real: z.real.rounded(prec, rnd), imag: z.imag.rounded(prec, rnd) }
}

///|
pub fn RawMpc::negated(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  { real: z.real.negated(prec, rnd), imag: z.imag.negated(prec, rnd) }
}

///|
pub impl Neg for RawMpc with fn neg(z) {
  RawMpc::new(-z.real, -z.imag)
}

///|
pub fn RawMpc::conjugate(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.rounded(prec, rnd), imag: z.imag.negated(prec, rnd) }
}

///|
pub fn RawMpc::scale_pow2(z : RawMpc, n : Int) -> RawMpc {
  { real: z.real.scale_pow2(n), imag: z.imag.scale_pow2(n) }
}

///|
pub fn RawMpc::add(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.add(w.real, prec, rnd), imag: z.imag.add(w.imag, prec, rnd) }
}

///|
pub fn RawMpc::add_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.add(x, prec, rnd), imag: z.imag }
}

///|
pub fn RawMpc::sub(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.sub(w.real, prec, rnd), imag: z.imag.sub(w.imag, prec, rnd) }
}

///|
pub fn RawMpc::sub_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.sub(x, prec, rnd), imag: z.imag }
}

///|
pub fn RawMpc::subtracted_from_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: x.sub(z.real, prec, rnd), imag: z.imag.negated(prec, rnd) }
}

///|
pub fn RawMpc::mul(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  let ac = z.real.mul(w.real, 0, Down)
  let bd = z.imag.mul(w.imag, 0, Down)
  let ad = z.real.mul(w.imag, 0, Down)
  let bc = z.imag.mul(w.real, 0, Down)
  { real: ac.sub(bd, prec, rnd), imag: ad.add(bc, prec, rnd) }
}

///|
pub fn RawMpc::mul_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.mul(x, prec, rnd), imag: z.imag.mul(x, prec, rnd) }
}

///|
pub fn RawMpc::mul_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: z.real.mul_int(n, prec, rnd), imag: z.imag.mul_int(n, prec, rnd) }
}

///|
pub fn RawMpc::div(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if w.is_infinite() && !z.is_non_finite() {
    return RawMpc::zero()
  }
  let wp = work_prec(prec)
  let cc = w.real.mul(w.real, 0, Down)
  let dd = w.imag.mul(w.imag, 0, Down)
  let mag = cc.add(dd, wp, Nearest)
  let ac = z.real.mul(w.real, 0, Down)
  let bd = z.imag.mul(w.imag, 0, Down)
  let bc = z.imag.mul(w.real, 0, Down)
  let ad = z.real.mul(w.imag, 0, Down)
  let t = ac.add(bd, wp, Nearest)
  let u = bc.sub(ad, wp, Nearest)
  {
    real: mpf_div_checked(t, mag, prec, rnd),
    imag: mpf_div_checked(u, mag, prec, rnd),
  }
}

///|
pub fn RawMpc::div_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  {
    real: mpf_div_checked(z.real, x, prec, rnd),
    imag: mpf_div_checked(z.imag, x, prec, rnd),
  }
}

///|
pub fn RawMpc::reciprocal(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.is_infinite() {
    return RawMpc::zero()
  }
  let wp = work_prec(prec)
  let aa = z.real.mul(z.real, 0, Down)
  let bb = z.imag.mul(z.imag, 0, Down)
  let mag = aa.add(bb, wp, Nearest)
  {
    real: mpf_div_checked(z.real, mag, prec, rnd),
    imag: mpf_div_checked(z.imag, mag, prec, rnd).negated(prec, rnd),
  }
}

///|
pub fn RawMpc::real_divided_by(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.is_infinite() && !x.is_infinite() && !x.is_nan() {
    return RawMpc::zero()
  }
  let wp = work_prec(prec)
  let aa = z.real.mul(z.real, 0, Down)
  let bb = z.imag.mul(z.imag, 0, Down)
  let mag = aa.add(bb, wp, Nearest)
  let ax = z.real.mul(x, wp, Nearest)
  let bx = z.imag.mul(x, wp, Nearest)
  {
    real: mpf_div_checked(ax, mag, prec, rnd),
    imag: mpf_div_checked(bx, mag, prec, rnd).negated(prec, rnd),
  }
}

///|
pub fn RawMpc::pow_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return {
      real: mpf_pow_int_checked(z.real, n, prec, rnd),
      imag: @mpf.RawMpf::zero(),
    }
  }
  if n == 0 {
    return RawMpc::one()
  }
  if n == 1 {
    return z.rounded(prec, rnd)
  }
  if n == -1 {
    return z.reciprocal(prec, rnd)
  }
  if n < 0 {
    let p = z.pow_int(-n, prec + 8, Nearest)
    return p.reciprocal(prec, rnd)
  }
  let work = if prec > 0 { prec + 8 } else { 0 }
  let mut e = n
  let mut base = z
  let mut acc = RawMpc::one()
  while e > 0 {
    if (e & 1) == 1 {
      acc = acc.mul(base, work, Nearest)
    }
    e = e / 2
    if e > 0 {
      base = base.mul(base, work, Nearest)
    }
  }
  acc.rounded(prec, rnd)
}

///|
pub fn RawMpc::floor(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  { real: z.real.floor(prec, rnd), imag: z.imag.floor(prec, rnd) }
}

///|
pub fn RawMpc::ceil(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  { real: z.real.ceil(prec, rnd), imag: z.imag.ceil(prec, rnd) }
}

///|
pub fn RawMpc::nearest_integer(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: z.real.nearest_integer(prec, rnd),
    imag: z.imag.nearest_integer(prec, rnd),
  }
}

///|
pub fn RawMpc::fractional_part(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: z.real.fractional_part(prec, rnd),
    imag: z.imag.fractional_part(prec, rnd),
  }
}

///|
pub fn RawMpc::abs(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  mpf_hypot_checked(z.real, z.imag, prec, rnd)
}

///|
pub fn RawMpc::arg(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  elefun_atan2_checked(z.imag, z.real, prec, rnd)
}

///|
pub fn RawMpc::sqrt(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let a = z.real
  let b = z.imag
  if b == @mpf.RawMpf::zero() {
    if a == @mpf.RawMpf::zero() {
      return z
    }
    if a.sign == 1 {
      let im = mpf_sqrt_checked(a.negated(0, Down), prec, rnd)
      return { real: @mpf.RawMpf::zero(), imag: im }
    } else {
      let re = mpf_sqrt_checked(a, prec, rnd)
      return { real: re, imag: @mpf.RawMpf::zero() }
    }
  }
  if b == @mpf.RawMpf::infinity() || b == @mpf.RawMpf::negative_infinity() {
    return { real: @mpf.RawMpf::infinity(), imag: b }
  }
  let wp = if prec > 0 { prec + 20 } else { 40 }
  if a.sign == 0 {
    let t = z.abs(wp, Nearest).add(a, wp, Nearest)
    let u = t.scale_pow2(-1)
    let re = mpf_sqrt_checked(u, prec, rnd)
    let v = t.scale_pow2(1)
    let w = mpf_sqrt_checked(v, wp, Nearest)
    let im = mpf_div_checked(b, w, prec, rnd)
    { real: re, imag: im }
  } else {
    let t = z.abs(wp, Nearest).sub(a, wp, Nearest)
    let u = t.scale_pow2(-1)
    let mut im = mpf_sqrt_checked(u, prec, rnd)
    let v = t.scale_pow2(1)
    let w = mpf_sqrt_checked(v, wp, Nearest)
    let mut re = mpf_div_checked(b, w, prec, rnd)
    if b.sign == 1 {
      re = re.negated(prec, rnd)
      im = im.negated(prec, rnd)
    }
    { real: re, imag: im }
  }
}

///|
pub fn RawMpc::square(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  z.mul(z, prec, rnd)
}

///|
pub fn RawMpc::exp(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = work_prec(prec)
  let ea = elefun_exp_checked(z.real, p, Nearest)
  let cb = elefun_cos_checked(z.imag, p, Nearest)
  let sb = elefun_sin_checked(z.imag, p, Nearest)
  { real: ea.mul(cb, prec, rnd), imag: ea.mul(sb, prec, rnd) }
}

///|
pub fn RawMpc::log(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    raise PoleError("RawMpc::log: logarithm singular at zero")
  }
  let p = work_prec(prec)
  {
    real: mpf_log_checked(z.abs(p, Nearest), prec, rnd),
    imag: z.arg(prec, rnd),
  }
}

///|
pub fn RawMpc::pow(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if w == RawMpc::zero() {
    return RawMpc::one()
  }
  if z == RawMpc::zero() {
    if w.imag != @mpf.RawMpf::zero() || w.real.signum() <= 0 {
      raise DomainError(
        "RawMpc::pow: undefined for zero base with non-positive/complex exponent",
      )
    }
    return RawMpc::zero()
  }
  let p = work_prec(prec)
  let lz = z.log(p, Nearest)
  let t = w.mul(lz, p, Nearest)
  t.exp(prec, rnd)
}

///|
pub fn RawMpc::pow_real(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  mpc_pow_checked(z, RawMpc::new(x, @mpf.RawMpf::zero()), prec, rnd)
}

///|
pub fn RawMpc::sin(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = work_prec(prec)
  let sa = elefun_sin_checked(z.real, p, Nearest)
  let ca = elefun_cos_checked(z.real, p, Nearest)
  let shb = elefun_sinh_checked(z.imag, p, Nearest)
  let chb = elefun_cosh_checked(z.imag, p, Nearest)
  { real: sa.mul(chb, prec, rnd), imag: ca.mul(shb, prec, rnd) }
}

///|
pub fn RawMpc::cos(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = work_prec(prec)
  let sa = elefun_sin_checked(z.real, p, Nearest)
  let ca = elefun_cos_checked(z.real, p, Nearest)
  let shb = elefun_sinh_checked(z.imag, p, Nearest)
  let chb = elefun_cosh_checked(z.imag, p, Nearest)
  {
    real: ca.mul(chb, prec, rnd),
    imag: sa.mul(shb, p, Nearest).negated(prec, rnd),
  }
}

///|
pub fn RawMpc::tan(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag.is_infinite() {
    return RawMpc::new(
      @mpf.RawMpf::zero(),
      if z.imag.sign == 1 {
        @mpf.RawMpf::from_int(-1)
      } else {
        @mpf.RawMpf::one()
      },
    )
  }
  if z.real.is_infinite() {
    if z.imag.is_zero() {
      return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::zero())
    }
    if z.imag.is_finite() {
      return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    }
  }
  let p = work_prec(prec)
  z.sin(p, Nearest).div(z.cos(p, Nearest), prec, rnd)
}

///|
pub fn RawMpc::sinh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = work_prec(prec)
  let sha = elefun_sinh_checked(z.real, p, Nearest)
  let cha = elefun_cosh_checked(z.real, p, Nearest)
  let sb = elefun_sin_checked(z.imag, p, Nearest)
  let cb = elefun_cos_checked(z.imag, p, Nearest)
  { real: sha.mul(cb, prec, rnd), imag: cha.mul(sb, prec, rnd) }
}

///|
pub fn RawMpc::cosh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = work_prec(prec)
  let sha = elefun_sinh_checked(z.real, p, Nearest)
  let cha = elefun_cosh_checked(z.real, p, Nearest)
  let sb = elefun_sin_checked(z.imag, p, Nearest)
  let cb = elefun_cos_checked(z.imag, p, Nearest)
  { real: cha.mul(cb, prec, rnd), imag: sha.mul(sb, prec, rnd) }
}

///|
pub fn RawMpc::tanh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.real.is_infinite() {
    return RawMpc::new(
      if z.real.sign == 1 {
        @mpf.RawMpf::from_int(-1)
      } else {
        @mpf.RawMpf::one()
      },
      @mpf.RawMpf::zero(),
    )
  }
  if z.imag.is_infinite() {
    if z.real.is_zero() {
      return RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::nan())
    }
    if z.real.is_finite() {
      return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    }
  }
  let p = work_prec(prec)
  z.sinh(p, Nearest).div(z.cosh(p, Nearest), prec, rnd)
}
