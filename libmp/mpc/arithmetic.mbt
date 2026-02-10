///|
fn work_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 10
  } else {
    20
  }
}

///|
pub fn one() -> RawMpc {
  { real: @mpf.fone, imag: @mpf.fzero }
}

///|
pub fn from_parts(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpc {
  { real, imag }
}

///|
pub fn mpc_is_inf(z : RawMpc) -> Bool {
  @mpf.is_inf(z.real) || @mpf.is_inf(z.imag)
}

///|
pub fn mpc_is_infnan(z : RawMpc) -> Bool {
  mpc_is_inf(z) || @mpf.is_nan(z.real) || @mpf.is_nan(z.imag)
}

///|
pub fn mpc_is_nonzero(z : RawMpc) -> Bool {
  z != zero()
}

///|
pub fn mpc_pos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_pos(z.real, prec, rnd),
    imag: @mpf.mpf_pos(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_neg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_neg(z.real, prec, rnd),
    imag: @mpf.mpf_neg(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_conjugate(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_pos(z.real, prec, rnd),
    imag: @mpf.mpf_neg(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_shift(z : RawMpc, n : Int) -> RawMpc {
  { real: @mpf.mpf_shift(z.real, n), imag: @mpf.mpf_shift(z.imag, n) }
}

///|
pub fn mpc_add(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: @mpf.mpf_add(z.real, w.real, prec, rnd),
    imag: @mpf.mpf_add(z.imag, w.imag, prec, rnd),
  }
}

///|
pub fn mpc_add_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: @mpf.mpf_add(z.real, x, prec, rnd), imag: z.imag }
}

///|
pub fn mpc_sub(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: @mpf.mpf_sub(z.real, w.real, prec, rnd),
    imag: @mpf.mpf_sub(z.imag, w.imag, prec, rnd),
  }
}

///|
pub fn mpc_sub_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  { real: @mpf.mpf_sub(z.real, x, prec, rnd), imag: z.imag }
}

///|
pub fn mpc_mpf_sub(
  x : @mpf.RawMpf,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: @mpf.mpf_sub(x, z.real, prec, rnd),
    imag: @mpf.mpf_neg(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_mul(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  let ac = @mpf.mpf_mul(z.real, w.real, 0, @mpf.round_down)
  let bd = @mpf.mpf_mul(z.imag, w.imag, 0, @mpf.round_down)
  let ad = @mpf.mpf_mul(z.real, w.imag, 0, @mpf.round_down)
  let bc = @mpf.mpf_mul(z.imag, w.real, 0, @mpf.round_down)
  {
    real: @mpf.mpf_sub(ac, bd, prec, rnd),
    imag: @mpf.mpf_add(ad, bc, prec, rnd),
  }
}

///|
pub fn mpc_mul_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: @mpf.mpf_mul(z.real, x, prec, rnd),
    imag: @mpf.mpf_mul(z.imag, x, prec, rnd),
  }
}

///|
pub fn mpc_mul_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: @mpf.mpf_mul_int(z.real, n, prec, rnd),
    imag: @mpf.mpf_mul_int(z.imag, n, prec, rnd),
  }
}

///|
pub fn mpc_div(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if mpc_is_inf(w) && !mpc_is_infnan(z) {
    return zero()
  }
  let wp = work_prec(prec)
  let cc = @mpf.mpf_mul(w.real, w.real, 0, @mpf.round_down)
  let dd = @mpf.mpf_mul(w.imag, w.imag, 0, @mpf.round_down)
  let mag = @mpf.mpf_add(cc, dd, wp, @mpf.round_nearest)
  let ac = @mpf.mpf_mul(z.real, w.real, 0, @mpf.round_down)
  let bd = @mpf.mpf_mul(z.imag, w.imag, 0, @mpf.round_down)
  let bc = @mpf.mpf_mul(z.imag, w.real, 0, @mpf.round_down)
  let ad = @mpf.mpf_mul(z.real, w.imag, 0, @mpf.round_down)
  let t = @mpf.mpf_add(ac, bd, wp, @mpf.round_nearest)
  let u = @mpf.mpf_sub(bc, ad, wp, @mpf.round_nearest)
  {
    real: try! @mpf.mpf_div(t, mag, prec, rnd),
    imag: try! @mpf.mpf_div(u, mag, prec, rnd),
  }
}

///|
pub fn mpc_div_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  {
    real: try! @mpf.mpf_div(z.real, x, prec, rnd),
    imag: try! @mpf.mpf_div(z.imag, x, prec, rnd),
  }
}

///|
pub fn mpc_reciprocal(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if mpc_is_inf(z) {
    return zero()
  }
  let wp = work_prec(prec)
  let aa = @mpf.mpf_mul(z.real, z.real, 0, @mpf.round_down)
  let bb = @mpf.mpf_mul(z.imag, z.imag, 0, @mpf.round_down)
  let mag = @mpf.mpf_add(aa, bb, wp, @mpf.round_nearest)
  {
    real: try! @mpf.mpf_div(z.real, mag, prec, rnd),
    imag: @mpf.mpf_neg(try! @mpf.mpf_div(z.imag, mag, prec, rnd), prec, rnd),
  }
}

///|
pub fn mpc_mpf_div(
  x : @mpf.RawMpf,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if mpc_is_inf(z) && !@mpf.is_inf(x) && !@mpf.is_nan(x) {
    return zero()
  }
  let wp = work_prec(prec)
  let aa = @mpf.mpf_mul(z.real, z.real, 0, @mpf.round_down)
  let bb = @mpf.mpf_mul(z.imag, z.imag, 0, @mpf.round_down)
  let mag = @mpf.mpf_add(aa, bb, wp, @mpf.round_nearest)
  let ax = @mpf.mpf_mul(z.real, x, wp, @mpf.round_nearest)
  let bx = @mpf.mpf_mul(z.imag, x, wp, @mpf.round_nearest)
  {
    real: try! @mpf.mpf_div(ax, mag, prec, rnd),
    imag: @mpf.mpf_neg(try! @mpf.mpf_div(bx, mag, prec, rnd), prec, rnd),
  }
}

///|
pub fn mpc_pow_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if z.imag == @mpf.fzero {
    return { real: try! @mpf.mpf_pow_int(z.real, n, prec, rnd), imag: @mpf.fzero }
  }
  if n == 0 {
    return one()
  }
  if n == 1 {
    return mpc_pos(z, prec, rnd)
  }
  if n == -1 {
    return mpc_reciprocal(z, prec, rnd)
  }
  if n < 0 {
    let p = mpc_pow_int(z, -n, prec + 8, @mpf.round_nearest)
    return mpc_reciprocal(p, prec, rnd)
  }
  let work = if prec > 0 { prec + 8 } else { 0 }
  let mut e = n
  let mut base = z
  let mut acc = one()
  while e > 0 {
    if (e & 1) == 1 {
      acc = mpc_mul(acc, base, work, @mpf.round_nearest)
    }
    e = e / 2
    if e > 0 {
      base = mpc_mul(base, base, work, @mpf.round_nearest)
    }
  }
  mpc_pos(acc, prec, rnd)
}

///|
pub fn mpc_floor(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_floor(z.real, prec, rnd),
    imag: @mpf.mpf_floor(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_ceil(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_ceil(z.real, prec, rnd),
    imag: @mpf.mpf_ceil(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_nint(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_nint(z.real, prec, rnd),
    imag: @mpf.mpf_nint(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_frac(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  {
    real: @mpf.mpf_frac(z.real, prec, rnd),
    imag: @mpf.mpf_frac(z.imag, prec, rnd),
  }
}

///|
pub fn mpc_abs(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  try! @mpf.mpf_hypot(z.real, z.imag, prec, rnd)
}

///|
pub fn mpc_arg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  @libelefun.mpf_atan2(z.imag, z.real, prec, rnd)
}

///|
pub fn mpc_sqrt(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let a = z.real
  let b = z.imag
  if b == @mpf.fzero {
    if a == @mpf.fzero {
      return z
    }
    if a.sign == 1 {
      let im = try! @mpf.mpf_sqrt(@mpf.mpf_neg(a, 0, @mpf.round_down), prec, rnd)
      return { real: @mpf.fzero, imag: im }
    } else {
      let re = try! @mpf.mpf_sqrt(a, prec, rnd)
      return { real: re, imag: @mpf.fzero }
    }
  }
  if b == @mpf.finf || b == @mpf.fninf {
    return { real: @mpf.finf, imag: b }
  }
  let wp = if prec > 0 { prec + 20 } else { 40 }
  if a.sign == 0 {
    let t = @mpf.mpf_add(
      mpc_abs(z, wp, @mpf.round_nearest),
      a,
      wp,
      @mpf.round_nearest,
    )
    let u = @mpf.mpf_shift(t, -1)
    let re = try! @mpf.mpf_sqrt(u, prec, rnd)
    let v = @mpf.mpf_shift(t, 1)
    let w = try! @mpf.mpf_sqrt(v, wp, @mpf.round_nearest)
    let im = try! @mpf.mpf_div(b, w, prec, rnd)
    { real: re, imag: im }
  } else {
    let t = @mpf.mpf_sub(
      mpc_abs(z, wp, @mpf.round_nearest),
      a,
      wp,
      @mpf.round_nearest,
    )
    let u = @mpf.mpf_shift(t, -1)
    let mut im = try! @mpf.mpf_sqrt(u, prec, rnd)
    let v = @mpf.mpf_shift(t, 1)
    let w = try! @mpf.mpf_sqrt(v, wp, @mpf.round_nearest)
    let mut re = try! @mpf.mpf_div(b, w, prec, rnd)
    if b.sign == 1 {
      re = @mpf.mpf_neg(re, prec, rnd)
      im = @mpf.mpf_neg(im, prec, rnd)
    }
    { real: re, imag: im }
  }
}

///|
pub fn mpc_square(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  mpc_mul(z, z, prec, rnd)
}

///|
pub fn mpc_exp(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  let ea = @libelefun.mpf_exp(z.real, p, @mpf.round_nearest)
  let cb = @libelefun.mpf_cos(z.imag, p, @mpf.round_nearest)
  let sb = @libelefun.mpf_sin(z.imag, p, @mpf.round_nearest)
  {
    real: @mpf.mpf_mul(ea, cb, prec, rnd),
    imag: @mpf.mpf_mul(ea, sb, prec, rnd),
  }
}

///|
pub fn mpc_log(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z == zero() {
    raise MpcError::PoleError("mpc_log: logarithm singular at zero")
  }
  let p = work_prec(prec)
  {
    real: try! @libelefun.mpf_log(mpc_abs(z, p, @mpf.round_nearest), prec, rnd),
    imag: mpc_arg(z, prec, rnd),
  }
}

///|
pub fn mpc_pow(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if w == zero() {
    return one()
  }
  if z == zero() {
    if w.imag != @mpf.fzero || @mpf.mpf_sign(w.real) <= 0 {
      raise MpcError::DomainError(
        "mpc_pow: undefined for zero base with non-positive/complex exponent",
      )
    }
    return zero()
  }
  let p = work_prec(prec)
  let lz = mpc_log(z, p, @mpf.round_nearest)
  let t = mpc_mul(w, lz, p, @mpf.round_nearest)
  mpc_exp(t, prec, rnd)
}

///|
pub fn mpc_pow_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  try! mpc_pow(z, from_parts(x, @mpf.fzero), prec, rnd)
}

///|
pub fn mpc_sin(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  let sa = @libelefun.mpf_sin(z.real, p, @mpf.round_nearest)
  let ca = @libelefun.mpf_cos(z.real, p, @mpf.round_nearest)
  let shb = @libelefun.mpf_sinh(z.imag, p, @mpf.round_nearest)
  let chb = @libelefun.mpf_cosh(z.imag, p, @mpf.round_nearest)
  {
    real: @mpf.mpf_mul(sa, chb, prec, rnd),
    imag: @mpf.mpf_mul(ca, shb, prec, rnd),
  }
}

///|
pub fn mpc_cos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  let sa = @libelefun.mpf_sin(z.real, p, @mpf.round_nearest)
  let ca = @libelefun.mpf_cos(z.real, p, @mpf.round_nearest)
  let shb = @libelefun.mpf_sinh(z.imag, p, @mpf.round_nearest)
  let chb = @libelefun.mpf_cosh(z.imag, p, @mpf.round_nearest)
  {
    real: @mpf.mpf_mul(ca, chb, prec, rnd),
    imag: @mpf.mpf_neg(@mpf.mpf_mul(sa, shb, p, @mpf.round_nearest), prec, rnd),
  }
}

///|
pub fn mpc_tan(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  mpc_div(
    mpc_sin(z, p, @mpf.round_nearest),
    mpc_cos(z, p, @mpf.round_nearest),
    prec,
    rnd,
  )
}

///|
pub fn mpc_sinh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  let sha = @libelefun.mpf_sinh(z.real, p, @mpf.round_nearest)
  let cha = @libelefun.mpf_cosh(z.real, p, @mpf.round_nearest)
  let sb = @libelefun.mpf_sin(z.imag, p, @mpf.round_nearest)
  let cb = @libelefun.mpf_cos(z.imag, p, @mpf.round_nearest)
  {
    real: @mpf.mpf_mul(sha, cb, prec, rnd),
    imag: @mpf.mpf_mul(cha, sb, prec, rnd),
  }
}

///|
pub fn mpc_cosh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  let sha = @libelefun.mpf_sinh(z.real, p, @mpf.round_nearest)
  let cha = @libelefun.mpf_cosh(z.real, p, @mpf.round_nearest)
  let sb = @libelefun.mpf_sin(z.imag, p, @mpf.round_nearest)
  let cb = @libelefun.mpf_cos(z.imag, p, @mpf.round_nearest)
  {
    real: @mpf.mpf_mul(cha, cb, prec, rnd),
    imag: @mpf.mpf_mul(sha, sb, prec, rnd),
  }
}

///|
pub fn mpc_tanh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = work_prec(prec)
  mpc_div(
    mpc_sinh(z, p, @mpf.round_nearest),
    mpc_cosh(z, p, @mpf.round_nearest),
    prec,
    rnd,
  )
}
