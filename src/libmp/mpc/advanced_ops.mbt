///|
fn ext_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 20
  } else {
    48
  }
}

///|
fn lift_real(x : @mpf.RawMpf) -> RawMpc {
  from_parts(x, @mpf.fzero)
}

///|
fn const_mpf(v : String, p : Int) -> @mpf.RawMpf {
  @mpf.from_str(v, prec=if p > 0 { p + 24 } else { 72 }, rnd=@mpf.round_nearest)
}

///|
fn factorial_mpf_small(n : Int, p : Int) -> @mpf.RawMpf {
  if n <= 1 {
    return @mpf.fone
  }
  let mut acc = @mpf.fone
  for i in 2..<=n {
    acc = @mpf.mpf_mul_int(acc, i, p, @mpf.round_nearest)
  }
  acc
}

///|
fn tiny_enough_mpc(term : RawMpc, p : Int, bits : Int) -> Bool {
  let a = mpc_abs(term, p, @mpf.round_nearest)
  if @mpf.is_zero(a) {
    true
  } else if !@mpf.is_finite(a) {
    false
  } else {
    a.exp + a.bc <= -bits
  }
}

///|
fn int_bit_length(n : Int) -> Int {
  if n == 0 {
    return 0
  }
  let mut x = if n < 0 { -n } else { n }
  let mut bits = 0
  while x > 0 {
    bits += 1
    x = x >> 1
  }
  bits
}

///|
fn shift_big(x : BigInt, n : Int) -> BigInt {
  if n >= 0 {
    x >> n
  } else {
    x << (-n)
  }
}

///|
fn mpf_to_fixed_signed(x : @mpf.RawMpf, prec : Int) -> BigInt {
  if @mpf.is_zero(x) {
    return 0N
  }
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  let offset = x.exp + prec
  if offset >= 0 {
    signed_man << offset
  } else {
    signed_man >> (-offset)
  }
}

///|
fn complex_mul_big(
  are : BigInt,
  aim : BigInt,
  bre : BigInt,
  bim : BigInt,
) -> (BigInt, BigInt) {
  (are * bre - aim * bim, are * bim + aim * bre)
}

///|
fn complex_int_pow_big(re : BigInt, im : BigInt, n : Int) -> (BigInt, BigInt) {
  if n == 0 {
    return (1N, 0N)
  }
  let mut e = n
  let mut base_re = re
  let mut base_im = im
  let mut acc_re = 1N
  let mut acc_im = 0N
  while e > 0 {
    if (e & 1) == 1 {
      let (nr, ni) = complex_mul_big(acc_re, acc_im, base_re, base_im)
      acc_re = nr
      acc_im = ni
    }
    e = e / 2
    if e > 0 {
      let (br, bi) = complex_mul_big(base_re, base_im, base_re, base_im)
      base_re = br
      base_im = bi
    }
  }
  (acc_re, acc_im)
}

///|
pub fn mpc_nthroot_fixed(
  a : BigInt,
  b : BigInt,
  n : Int,
  prec : Int,
) -> (BigInt, BigInt) {
  let start = 50
  let extra = 10
  let z = from_parts(
    @mpf.from_man_exp(a, -prec, 0, @mpf.round_down),
    @mpf.from_man_exp(b, -prec, 0, @mpf.round_down),
  )
  let low_prec = start + 12
  let nth = @mpf.mpf_rdiv_int(1, @mpf.from_int(n), low_prec, @mpf.round_nearest)
  let seed = mpc_pow_mpf(z, nth, low_prec, @mpf.round_nearest)
  let mut re = mpf_to_fixed_signed(seed.real, start)
  let mut im = mpf_to_fixed_signed(seed.imag, start)
  let mut prevp = start
  let target = prec + extra
  let mut p = start
  while p < target {
    p = if p * 2 < target { p * 2 } else { target }
    let (pow_re, pow_im) = complex_int_pow_big(re, im, n - 1)
    let scale = (n - 1) * prevp - p - n
    let re2 = shift_big(pow_re, scale)
    let im2 = shift_big(pow_im, scale)
    let r4 = (re2 * re2 + im2 * im2) >> (p + n)
    let ap = shift_big(a, prec - p)
    let bp = shift_big(b, prec - p)
    let rec = (ap * re2 + bp * im2) >> p
    let imc = ((-ap) * im2 + bp * re2) >> p
    let reb = (rec << p) / r4
    let imb = (imc << p) / r4
    re = (reb + BigInt::from_int(n - 1) * (re << (p - prevp))) / BigInt::from_int(n)
    im = (imb + BigInt::from_int(n - 1) * (im << (p - prevp))) / BigInt::from_int(n)
    prevp = p
  }
  (re, im)
}

///|
fn lanczos_coeff(i : Int, p : Int) -> @mpf.RawMpf {
  match i {
    0 => const_mpf("0.99999999999980993", p)
    1 => const_mpf("676.5203681218851", p)
    2 => const_mpf("-1259.1392167224028", p)
    3 => const_mpf("771.32342877765313", p)
    4 => const_mpf("-176.61502916214059", p)
    5 => const_mpf("12.507343278686905", p)
    6 => const_mpf("-0.13857109526572012", p)
    7 => const_mpf("0.0000099843695780195716", p)
    _ => const_mpf("0.00000015056327351493116", p)
  }
}

///|
fn mpc_gamma_lanczos(z : RawMpc, p : Int) -> RawMpc {
  let z1 = mpc_sub_mpf(z, @mpf.fone, p, @mpf.round_nearest)
  let mut x = from_parts(lanczos_coeff(0, p), @mpf.fzero)
  for i in 1..<9 {
    let den = mpc_add_mpf(z1, @mpf.from_int(i), p, @mpf.round_nearest)
    let add = mpc_mpf_div(lanczos_coeff(i, p), den, p, @mpf.round_nearest)
    x = mpc_add(x, add, p, @mpf.round_nearest)
  }
  let t = mpc_add_mpf(z1, const_mpf("7.5", p), p, @mpf.round_nearest)
  let pow = mpc_pow(
    t,
    mpc_add_mpf(z1, const_mpf("0.5", p), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let exp_term = mpc_exp(
    mpc_neg(t, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let y = mpc_mul(
    pow,
    mpc_mul(exp_term, x, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  mpc_mul_mpf(
    y,
    const_mpf("2.5066282746310005024157652848110452", p),
    p,
    @mpf.round_nearest,
  )
}

///|
fn clamp_series_terms(prec : Int) -> Int {
  if prec <= 0 {
    256
  } else {
    let n = prec * 4
    if n < 256 {
      256
    } else if n > 8000 {
      8000
    } else {
      n
    }
  }
}

///|
fn mpc_mag_bound(z : RawMpc) -> Int {
  let mut mag = if @mpf.is_zero(z.real) {
    if @mpf.is_zero(z.imag) { 0 } else { z.imag.exp + z.imag.bc }
  } else {
    z.real.exp + z.real.bc
  }
  if !@mpf.is_zero(z.imag) {
    let im_mag = z.imag.exp + z.imag.bc
    if im_mag > mag {
      mag = im_mag
    }
  }
  mag
}

///|
fn mpc_ci_si_asymptotic(
  z : RawMpc,
  p : Int,
) -> (RawMpc, RawMpc) {
  let z_inv = mpc_reciprocal(z, p, @mpf.round_nearest)
  let z_inv2 = mpc_mul(z_inv, z_inv, p, @mpf.round_nearest)
  let mut f_term = z_inv
  let mut f_sum = f_term
  let mut g_term = z_inv2
  let mut g_sum = g_term
  let max_terms = clamp_series_terms(p)
  let mut m = 0
  while m < max_terms {
    let a = 2 * m + 2
    f_term = mpc_mul(f_term, z_inv2, p, @mpf.round_nearest)
    f_term = mpc_mul_int(f_term, -(a * (a - 1)), p, @mpf.round_nearest)
    g_term = mpc_mul(g_term, z_inv2, p, @mpf.round_nearest)
    g_term = mpc_mul_int(g_term, -((a + 1) * a), p, @mpf.round_nearest)
    f_sum = mpc_add(f_sum, f_term, p, @mpf.round_nearest)
    g_sum = mpc_add(g_sum, g_term, p, @mpf.round_nearest)
    if tiny_enough_mpc(f_term, p, p + 6) &&
      tiny_enough_mpc(g_term, p, p + 6) &&
      m > 3 {
      break
    }
    m += 1
  }
  let (cos_z, sin_z) = mpc_cos_sin(z, p, @mpf.round_nearest)
  let ci = mpc_sub(
    mpc_mul(sin_z, f_sum, p, @mpf.round_nearest),
    mpc_mul(cos_z, g_sum, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let half_pi = from_parts(
    @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1),
    @mpf.fzero,
  )
  let si = mpc_sub(
    half_pi,
    mpc_add(
      mpc_mul(cos_z, f_sum, p, @mpf.round_nearest),
      mpc_mul(sin_z, g_sum, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  (ci, si)
}

///|
fn zeta_series_sum(
  s : RawMpc,
  p : Int,
  start : Int,
  terms : Int,
  alternating : Bool,
) -> RawMpc {
  if terms <= 0 {
    return zero()
  }
  let minus_s = mpc_neg(s, p, @mpf.round_nearest)
  let mut sum = zero()
  let mut counted = 0
  for i in 0..<terms {
    let k = start + i
    if k <= 0 {
      continue
    }
    let base = from_parts(@mpf.from_int(k), @mpf.fzero)
    let term = mpc_pow(base, minus_s, p, @mpf.round_nearest)
    if alternating && (k & 1) == 0 {
      sum = mpc_sub(sum, term, p, @mpf.round_nearest)
    } else {
      sum = mpc_add(sum, term, p, @mpf.round_nearest)
    }
    counted += 1
    let abs_term = mpc_abs(term, p, @mpf.round_nearest)
    if counted > 32 &&
      @mpf.is_finite(abs_term) &&
      abs_term.exp + abs_term.bc <= -p + 4 {
      break
    }
  }
  sum
}

///|
pub fn mpc_to_str(z : RawMpc, dps? : Int = 15) -> String {
  let rs = @mpf.to_str_opts(z.real, dps~)
  if z.imag.sign == 1 && !@mpf.is_zero(z.imag) {
    let im_abs = @mpf.mpf_neg(z.imag, 0, @mpf.round_down)
    rs + " - " + @mpf.to_str_opts(im_abs, dps~) + "j"
  } else {
    rs + " + " + @mpf.to_str_opts(z.imag, dps~) + "j"
  }
}

///|
pub fn mpc_to_complex(z : RawMpc, dps? : Int = 17) -> (String, String) {
  (@mpf.to_str_opts(z.real, dps~), @mpf.to_str_opts(z.imag, dps~))
}

///|
pub fn mpc_hash(z : RawMpc) -> Int {
  let mut h = @mpf.mpf_hash(z.real) + 1000003 * @mpf.mpf_hash(z.imag)
  if h == -1 {
    h = -2
  }
  h
}

///|
pub fn mpc_ln(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  mpc_log(z, prec, rnd)
}

///|
pub fn mpc_cos_pi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return from_parts(@libelefun.mpf_cos_pi(z.real, prec, rnd), @mpf.fzero)
  }
  let p = ext_prec(prec) + 6
  let b_pi = @mpf.mpf_mul(
    z.imag,
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  if z.real == @mpf.fzero {
    return from_parts(@libelefun.mpf_cosh(b_pi, prec, rnd), @mpf.fzero)
  }
  let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, p, @mpf.round_nearest)
  let (ch, sh) = @libelefun.mpf_cosh_sinh(b_pi, p, @mpf.round_nearest)
  from_parts(
    @mpf.mpf_mul(c, ch, prec, rnd),
    @mpf.mpf_neg(@mpf.mpf_mul(s, sh, p, @mpf.round_nearest), prec, rnd),
  )
}

///|
pub fn mpc_sin_pi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return from_parts(@libelefun.mpf_sin_pi(z.real, prec, rnd), @mpf.fzero)
  }
  let p = ext_prec(prec) + 6
  let b_pi = @mpf.mpf_mul(
    z.imag,
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  if z.real == @mpf.fzero {
    return from_parts(@mpf.fzero, @libelefun.mpf_sinh(b_pi, prec, rnd))
  }
  let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, p, @mpf.round_nearest)
  let (ch, sh) = @libelefun.mpf_cosh_sinh(b_pi, p, @mpf.round_nearest)
  from_parts(@mpf.mpf_mul(s, ch, prec, rnd), @mpf.mpf_mul(c, sh, prec, rnd))
}

///|
pub fn mpc_cos_sin(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) {
  if z.real == @mpf.fzero {
    let (ch, sh) = @libelefun.mpf_cosh_sinh(z.imag, prec, rnd)
    return (from_parts(ch, @mpf.fzero), from_parts(@mpf.fzero, sh))
  }
  if z.imag == @mpf.fzero {
    let (c, s) = @libelefun.mpf_cos_sin(z.real, prec, rnd)
    return (from_parts(c, @mpf.fzero), from_parts(s, @mpf.fzero))
  }
  let p = ext_prec(prec) + 6
  let (c, s) = @libelefun.mpf_cos_sin(z.real, p, @mpf.round_nearest)
  let (ch, sh) = @libelefun.mpf_cosh_sinh(z.imag, p, @mpf.round_nearest)
  let cz = from_parts(
    @mpf.mpf_mul(c, ch, prec, rnd),
    @mpf.mpf_neg(@mpf.mpf_mul(s, sh, p, @mpf.round_nearest), prec, rnd),
  )
  let sz = from_parts(
    @mpf.mpf_mul(s, ch, prec, rnd),
    @mpf.mpf_mul(c, sh, prec, rnd),
  )
  (cz, sz)
}

///|
pub fn mpc_cos_sin_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) {
  if z.imag == @mpf.fzero {
    let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, prec, rnd)
    return (from_parts(c, @mpf.fzero), from_parts(s, @mpf.fzero))
  }
  let p = ext_prec(prec) + 6
  let b_pi = @mpf.mpf_mul(
    z.imag,
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  if z.real == @mpf.fzero {
    let (ch, sh) = @libelefun.mpf_cosh_sinh(b_pi, prec, rnd)
    return (from_parts(ch, @mpf.fzero), from_parts(@mpf.fzero, sh))
  }
  let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, p, @mpf.round_nearest)
  let (ch, sh) = @libelefun.mpf_cosh_sinh(b_pi, p, @mpf.round_nearest)
  let cz = from_parts(
    @mpf.mpf_mul(c, ch, prec, rnd),
    @mpf.mpf_neg(@mpf.mpf_mul(s, sh, p, @mpf.round_nearest), prec, rnd),
  )
  let sz = from_parts(
    @mpf.mpf_mul(s, ch, prec, rnd),
    @mpf.mpf_mul(c, sh, prec, rnd),
  )
  (cz, sz)
}

///|
pub fn mpc_expj(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    let (c, s) = @libelefun.mpf_cos_sin(z.real, prec, rnd)
    return from_parts(c, s)
  }
  if z.real == @mpf.fzero {
    return from_parts(
      @libelefun.mpf_exp(@mpf.mpf_neg(z.imag, 0, @mpf.round_down), prec, rnd),
      @mpf.fzero,
    )
  }
  let p = ext_prec(prec)
  let ey = @libelefun.mpf_exp(
    @mpf.mpf_neg(z.imag, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let (c, s) = @libelefun.mpf_cos_sin(z.real, p, @mpf.round_nearest)
  from_parts(@mpf.mpf_mul(ey, c, prec, rnd), @mpf.mpf_mul(ey, s, prec, rnd))
}

///|
pub fn mpc_expjpi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, prec, rnd)
    return from_parts(c, s)
  }
  let p = ext_prec(prec)
  let im = @mpf.mpf_neg(
    @mpf.mpf_mul(
      @libelefun.mpf_pi(p, @mpf.round_nearest),
      z.imag,
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  if z.real == @mpf.fzero {
    return from_parts(@libelefun.mpf_exp(im, prec, rnd), @mpf.fzero)
  }
  let ey = @libelefun.mpf_exp(im, p, @mpf.round_nearest)
  let (c, s) = @libelefun.mpf_cos_sin_pi(z.real, p, @mpf.round_nearest)
  from_parts(@mpf.mpf_mul(ey, c, prec, rnd), @mpf.mpf_mul(ey, s, prec, rnd))
}

///|
pub fn mpc_atan(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let x = from_parts(
    @mpf.mpf_add(@mpf.fone, z.imag, p, @mpf.round_nearest),
    @mpf.mpf_neg(z.real, 0, @mpf.round_down),
  )
  let y = from_parts(
    @mpf.mpf_sub(@mpf.fone, z.imag, p, @mpf.round_nearest),
    z.real,
  )
  let l1 = mpc_ln(x, p, @mpf.round_nearest)
  let l2 = mpc_ln(y, p, @mpf.round_nearest)
  let d = mpc_sub(l1, l2, p, @mpf.round_nearest)
  let mut v = from_parts(
    @mpf.mpf_neg(@mpf.mpf_shift(d.imag, -1), p, @mpf.round_nearest),
    @mpf.mpf_shift(d.real, -1),
  )
  v = mpc_pos(v, prec, rnd)
  if @mpf.is_nan(v.imag) && mpc_is_inf(z) {
    v = from_parts(v.real, @mpf.fzero)
  }
  v
}

///|
pub fn mpc_asinh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let inside = mpc_add(
    mpc_square(z, p, @mpf.round_nearest),
    one(),
    p,
    @mpf.round_nearest,
  )
  let root = mpc_sqrt(inside, p, @mpf.round_nearest)
  mpc_ln(mpc_add(z, root, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpc_asin(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let iz = from_parts(@mpf.mpf_neg(z.imag, 0, @mpf.round_down), z.real)
  let w = mpc_asinh(iz, p, @mpf.round_nearest)
  mpc_pos(
    from_parts(w.imag, @mpf.mpf_neg(w.real, 0, @mpf.round_down)),
    prec,
    rnd,
  )
}

///|
pub fn mpc_acos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1)
  let a = mpc_asin(z, p, @mpf.round_nearest)
  mpc_pos(
    from_parts(
      @mpf.mpf_sub(half_pi, a.real, p, @mpf.round_nearest),
      @mpf.mpf_neg(a.imag, 0, @mpf.round_down),
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_acosh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let one_z = one()
  let s1 = mpc_sqrt(
    mpc_sub(z, one_z, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let s2 = mpc_sqrt(
    mpc_add(z, one_z, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  mpc_ln(
    mpc_add(z, mpc_mul(s1, s2, p, @mpf.round_nearest), p, @mpf.round_nearest),
    prec,
    rnd,
  )
}

///|
pub fn mpc_atanh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 10
  let a = mpc_ln(
    mpc_add(z, one(), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let b = mpc_ln(
    mpc_sub(one(), z, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let mut v = mpc_shift(mpc_sub(a, b, p, @mpf.round_nearest), -1)
  v = mpc_pos(v, prec, rnd)
  if @mpf.is_nan(v.real) && mpc_is_inf(z) {
    v = from_parts(@mpf.fzero, v.imag)
  }
  v
}

///|
pub fn mpc_nthroot(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if n < 2 {
    if n == 0 {
      return one()
    }
    if n == 1 {
      return mpc_pos(z, prec, rnd)
    }
    if n == -1 {
      return mpc_reciprocal(z, prec, rnd)
    }
    let inv = mpc_nthroot(z, -n, prec + 8, @mpf.round_nearest)
    return mpc_reciprocal(inv, prec, rnd)
  }
  if z.imag == @mpf.fzero && z.real.sign == 0 {
    return from_parts(@libelefun.mpf_nthroot(z.real, n, prec, rnd), @mpf.fzero)
  }
  if n <= 20 {
    let prec2 = ((prec + 10) * 6) / 5
    let abs_z = mpc_abs(z, prec2, @mpf.round_nearest)
    let mag = abs_z.exp + abs_z.bc
    if mag > -10 && mag < prec2 {
      let af = mpf_to_fixed_signed(z.real, prec2)
      let bf = mpf_to_fixed_signed(z.imag, prec2)
      let extra = 10
      let (re_fix, im_fix) = mpc_nthroot_fixed(af, bf, n, prec2)
      let re = @mpf.from_man_exp(re_fix, -(prec2 + extra), prec2, @mpf.round_nearest)
      let im = @mpf.from_man_exp(im_fix, -(prec2 + extra), prec2, @mpf.round_nearest)
      return mpc_pos(from_parts(re, im), prec, rnd)
    }
  }
  let p = ext_prec(prec) + 10
  let inv_n = @mpf.mpf_rdiv_int(1, @mpf.from_int(n), p, @mpf.round_nearest)
  mpc_pos(mpc_pow_mpf(z, inv_n, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpc_cbrt(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  mpc_nthroot(z, 3, prec, rnd)
}

///|
pub fn mpc_fibonacci(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_fibonacci(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 12
  let phi = @libelefun.mpf_phi(p, @mpf.round_nearest)
  let denom = @mpf.mpf_add(
    @mpf.mpf_shift(phi, 1),
    @mpf.fnone,
    p,
    @mpf.round_nearest,
  )
  let u = mpc_pow(from_parts(phi, @mpf.fzero), z, p, @mpf.round_nearest)
  let v = mpc_div(
    mpc_cos_pi(z, p, @mpf.round_nearest),
    u,
    p,
    @mpf.round_nearest,
  )
  let num = mpc_sub(u, v, p, @mpf.round_nearest)
  mpc_div_mpf(num, denom, prec, rnd)
}

///|
pub fn mpc_agm(
  a : RawMpc,
  b : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if mpc_is_infnan(a) || mpc_is_infnan(b) {
    return from_parts(@mpf.fnan, @mpf.fnan)
  }
  if a == zero() || b == zero() || mpc_neg(a, 0, @mpf.round_down) == b {
    return zero()
  }
  let p = ext_prec(prec) + 10
  let eps = @mpf.mpf_shift(@mpf.fone, -p + 8)
  let mut x = a
  let mut y = b
  for _ in 0..<80 {
    let x1 = mpc_shift(mpc_add(x, y, p, @mpf.round_nearest), -1)
    let y1 = mpc_sqrt(
      mpc_mul(x, y, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    x = x1
    y = y1
    let size = mpc_abs(x, 16, @mpf.round_nearest)
    let err = mpc_abs(
      mpc_sub(x, y, 16, @mpf.round_nearest),
      16,
      @mpf.round_nearest,
    )
    if size == @mpf.fzero ||
      @mpf.mpf_lt(err, @mpf.mpf_mul(eps, size, p, @mpf.round_nearest)) {
      break
    }
  }
  mpc_pos(x, prec, rnd)
}

///|
pub fn mpc_agm1(a : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  mpc_agm(one(), a, prec, rnd)
}

///|
pub fn mpc_ei(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@libhyper.mpf_ei(z.real, prec, rnd))
  }
  if z == zero() {
    abort("mpc_ei: singularity at zero")
  }
  if mpc_is_infnan(z) {
    return from_parts(@mpf.fnan, @mpf.fnan)
  }
  let p = ext_prec(prec) + 24
  let mut term = mpc_pos(z, p, @mpf.round_nearest)
  let mut sum = term
  let mut k = 1
  let max_terms = clamp_series_terms(p)
  while k < max_terms {
    let kp1 = k + 1
    term = mpc_mul(term, z, p, @mpf.round_nearest)
    term = mpc_mul_int(term, k, p, @mpf.round_nearest)
    term = mpc_div_mpf(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
    term = mpc_div_mpf(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
    sum = mpc_add(sum, term, p, @mpf.round_nearest)
    if tiny_enough_mpc(term, p, p + 6) && k > 6 {
      break
    }
    k += 1
  }
  let lg = mpc_ln(z, p, @mpf.round_nearest)
  let gamma = from_parts(
    @gammazeta.mpf_euler(p, @mpf.round_nearest),
    @mpf.fzero,
  )
  mpc_pos(
    mpc_add(
      mpc_add(sum, lg, p, @mpf.round_nearest),
      gamma,
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_e1(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@libhyper.mpf_e1(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 12
  let mut v = mpc_neg(
    mpc_ei(mpc_neg(z, p, @mpf.round_nearest), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  v = if z.imag.sign == 0 {
    from_parts(v.real, @mpf.mpf_sub(v.imag, pi, p, @mpf.round_nearest))
  } else {
    from_parts(v.real, @mpf.mpf_add(v.imag, pi, p, @mpf.round_nearest))
  }
  mpc_pos(v, prec, rnd)
}

///|
pub fn mpc_ci_si_taylor(
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> RawMpc {
  let mag = mpc_mag_bound(from_parts(re, im))
  if mag > 2 || mag < -wp {
    abort("mpc_ci_si_taylor: argument magnitude out of supported range")
  }
  let p = wp + (2 - mag)
  let z = from_parts(
    @mpf.mpf_pos(re, p, @mpf.round_nearest),
    @mpf.mpf_pos(im, p, @mpf.round_nearest),
  )
  let z2 = mpc_neg(mpc_square(z, p, @mpf.round_nearest), p, @mpf.round_nearest)
  let mut sum = if which == 0 { zero() } else { z }
  let mut term = if which == 0 { one() } else { z }
  let mut k = if which == 0 { 2 } else { 3 }
  let max_terms = clamp_series_terms(p)
  while k < max_terms {
    let den = @mpf.from_int(k * (k - 1))
    term = mpc_div_mpf(
      mpc_mul(term, z2, p, @mpf.round_nearest),
      den,
      p,
      @mpf.round_nearest,
    )
    let add = mpc_div_mpf(term, @mpf.from_int(k), p, @mpf.round_nearest)
    sum = mpc_add(sum, add, p, @mpf.round_nearest)
    if tiny_enough_mpc(add, p, p + 6) && k > 7 {
      break
    }
    k += 2
  }
  sum
}

///|
pub fn mpc_ci(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    let x = z.real
    if x.sign == 1 && !@mpf.is_zero(x) {
      let p = ext_prec(prec)
      let re = @libhyper.mpf_ci(
        @mpf.mpf_abs(x, p, @mpf.round_nearest),
        prec,
        rnd,
      )
      return from_parts(re, @libelefun.mpf_pi(prec, rnd))
    }
    return lift_real(@libhyper.mpf_ci(x, prec, rnd))
  }
  if z == zero() {
    return from_parts(@mpf.fninf, @mpf.fzero)
  }
  let p = ext_prec(prec) + 20
  let mag = mpc_mag_bound(z)
  let gamma = from_parts(
    @gammazeta.mpf_euler(p, @mpf.round_nearest),
    @mpf.fzero,
  )
  if mag < -p {
    return mpc_pos(mpc_add(gamma, mpc_ln(z, p, @mpf.round_nearest), p, @mpf.round_nearest), prec, rnd)
  }
  if mag > 2 {
    let (ci_as, _) = mpc_ci_si_asymptotic(z, p)
    return mpc_pos(ci_as, prec, rnd)
  }
  let sum = mpc_ci_si_taylor(z.real, z.imag, p, which=0)
  mpc_pos(
    mpc_add(
      mpc_add(gamma, mpc_ln(z, p, @mpf.round_nearest), p, @mpf.round_nearest),
      sum,
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_si(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@libhyper.mpf_si(z.real, prec, rnd))
  }
  if z == zero() {
    return zero()
  }
  let p = ext_prec(prec) + 20
  let mag = mpc_mag_bound(z)
  if mag < -p {
    return mpc_pos(z, prec, rnd)
  }
  if mag > 2 {
    let (_, si_as) = mpc_ci_si_asymptotic(z, p)
    return mpc_pos(si_as, prec, rnd)
  }
  let sum = mpc_ci_si_taylor(z.real, z.imag, p, which=1)
  mpc_pos(sum, prec, rnd)
}

///|
pub fn mpc_besseljn(
  n : Int,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@libhyper.mpf_besseljn(n, z.real, prec, rnd))
  }
  if mpc_is_infnan(z) {
    return from_parts(@mpf.fnan, @mpf.fnan)
  }
  let mut m = n
  let mut negate = false
  if m < 0 {
    m = -m
    negate = (m & 1) == 1
  }
  if z == zero() {
    return if m == 0 { one() } else { zero() }
  }
  let p = ext_prec(prec) + 24 + int_bit_length(m)
  let half_z = mpc_shift(z, -1)
  let z2 = mpc_mul(half_z, half_z, p, @mpf.round_nearest)
  let mut term = if m == 0 {
    one()
  } else {
    let num = mpc_pow_int(half_z, m, p, @mpf.round_nearest)
    mpc_div_mpf(num, factorial_mpf_small(m, p), p, @mpf.round_nearest)
  }
  let mut sum = term
  let mut k = 0
  let max_terms = clamp_series_terms(p)
  while k < max_terms {
    term = mpc_mul(term, z2, p, @mpf.round_nearest)
    term = mpc_neg(term, p, @mpf.round_nearest)
    term = mpc_div_mpf(term, @mpf.from_int(k + 1), p, @mpf.round_nearest)
    term = mpc_div_mpf(term, @mpf.from_int(k + m + 1), p, @mpf.round_nearest)
    sum = mpc_add(sum, term, p, @mpf.round_nearest)
    if tiny_enough_mpc(term, p, p + 6) && k > 4 {
      break
    }
    k += 1
  }
  if negate {
    sum = mpc_neg(sum, p, @mpf.round_nearest)
  }
  mpc_pos(sum, prec, rnd)
}

///|
pub fn mpc_ellipk(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    if z.real == @mpf.finf {
      return zero()
    }
    if @mpf.mpf_le(z.real, @mpf.fone) {
      return lift_real(@libhyper.mpf_ellipk(z.real, prec, rnd))
    }
  }
  let p = ext_prec(prec) + 16
  let a = mpc_sqrt(
    mpc_sub(one(), z, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let v = mpc_agm1(a, p, @mpf.round_nearest)
  let r = mpc_mpf_div(
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    v,
    p,
    @mpf.round_nearest,
  )
  mpc_pos(mpc_shift(r, -1), prec, rnd)
}

///|
pub fn mpc_ellipe(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    if z.real == @mpf.finf {
      return from_parts(@mpf.fzero, @mpf.finf)
    }
    if @mpf.mpf_le(z.real, @mpf.fone) {
      return lift_real(@libhyper.mpf_ellipe(z.real, prec, rnd))
    }
  }
  let p = ext_prec(prec) + 16
  let mag = mpc_abs(z, 16, @mpf.round_nearest)
  let step = (if mag.exp + mag.bc > 0 { mag.exp + mag.bc } else { 0 }) - p
  let h = @mpf.mpf_shift(@mpf.fone, step)
  let k = mpc_ellipk(z, 2 * p, @mpf.round_nearest)
  let kh = mpc_ellipk(
    mpc_add_mpf(z, h, 2 * p, @mpf.round_nearest),
    2 * p,
    @mpf.round_nearest,
  )
  let kdiff = mpc_shift(mpc_sub(kh, k, p, @mpf.round_nearest), -step)
  let t = mpc_sub(one(), z, p, @mpf.round_nearest)
  let b = mpc_mul(kdiff, mpc_shift(z, 1), p, @mpf.round_nearest)
  mpc_pos(
    mpc_mul(t, mpc_add(k, b, p, @mpf.round_nearest), p, @mpf.round_nearest),
    prec,
    rnd,
  )
}

///|
pub fn mpc_gamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_gamma(z.real, prec, rnd))
  }
  if mpc_is_infnan(z) {
    return from_parts(@mpf.fnan, @mpf.fnan)
  }
  let p = ext_prec(prec) + 24
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  if @mpf.mpf_lt(z.real, half) {
    let sin_pi_z = mpc_sin_pi(z, p, @mpf.round_nearest)
    let g = mpc_gamma(
      mpc_sub(one(), z, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let denom = mpc_mul(sin_pi_z, g, p, @mpf.round_nearest)
    return mpc_pos(
      mpc_mpf_div(
        @libelefun.mpf_pi(p, @mpf.round_nearest),
        denom,
        p,
        @mpf.round_nearest,
      ),
      prec,
      rnd,
    )
  }
  mpc_pos(mpc_gamma_lanczos(z, p), prec, rnd)
}

///|
pub fn mpc_rgamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_rgamma(z.real, prec, rnd))
  }
  mpc_pos(
    mpc_reciprocal(
      mpc_gamma(z, ext_prec(prec) + 16, @mpf.round_nearest),
      ext_prec(prec) + 16,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_loggamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_loggamma(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 20
  mpc_pos(
    mpc_ln(mpc_gamma(z, p, @mpf.round_nearest), p, @mpf.round_nearest),
    prec,
    rnd,
  )
}

///|
pub fn mpc_factorial(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  let p = ext_prec(prec) + 16
  mpc_gamma(mpc_add_mpf(z, @mpf.fone, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpc_harmonic(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_harmonic(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 20
  let psi = mpc_psi0(
    mpc_add_mpf(z, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  mpc_pos(
    mpc_add_mpf(
      psi,
      @gammazeta.mpf_euler(p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_psi0(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_psi0(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 44
  let shift = if prec > 0 { prec / 2 + 6 } else { 26 }
  let h = @mpf.mpf_shift(@mpf.fone, -shift)
  let zp = mpc_add_mpf(z, h, p, @mpf.round_nearest)
  let zm = mpc_sub_mpf(z, h, p, @mpf.round_nearest)
  let lgp = mpc_loggamma(zp, p, @mpf.round_nearest)
  let lgm = mpc_loggamma(zm, p, @mpf.round_nearest)
  let num = mpc_sub(lgp, lgm, p, @mpf.round_nearest)
  mpc_pos(
    mpc_div_mpf(
      num,
      @mpf.mpf_mul_int(h, 2, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpc_psi(m : Int, z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if z.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_psi(m, z.real, prec, rnd))
  }
  if m < 0 {
    abort("mpc_psi: m must be non-negative")
  }
  if m == 0 {
    return mpc_psi0(z, prec, rnd)
  }
  let p = ext_prec(prec) + 36
  let mut w = mpc_pos(z, p, @mpf.round_nearest)
  let target = 2 * p / 5 + 4 * m + 2
  let mut s = zero()
  for _ in 0..<512 {
    if @mpf.mpf_ge(w.real, @mpf.from_int(target)) {
      break
    }
    let t = mpc_reciprocal(
      mpc_pow_int(w, m + 1, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    s = mpc_add(s, t, p, @mpf.round_nearest)
    w = mpc_add_mpf(w, @mpf.fone, p, @mpf.round_nearest)
  }
  let mut zm = mpc_reciprocal(
    mpc_pow_int(w, m, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let z2 = mpc_reciprocal(
    mpc_square(w, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  s = mpc_add(
    s,
    mpc_div_mpf(zm, @mpf.from_int(m), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let endpoint = mpc_mul_mpf(
    mpc_div(zm, w, p, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    p,
    @mpf.round_nearest,
  )
  s = mpc_add(s, endpoint, p, @mpf.round_nearest)
  let magn = mpc_abs(s, 20, @mpf.round_nearest)
  let eps = @mpf.mpf_shift(@mpf.fone, magn.exp + magn.bc - p + 2)
  let mut ratio = @mpf.mpf_div(
    @mpf.from_int(m + 1),
    @mpf.from_int(2),
    p,
    @mpf.round_nearest,
  )
  let mut k = 1
  while k < 128 {
    zm = mpc_mul(zm, z2, p, @mpf.round_nearest)
    let bern = @gammazeta.mpf_bernoulli(2 * k, p, @mpf.round_nearest)
    let scal = @mpf.mpf_mul(bern, ratio, p, @mpf.round_nearest)
    let term = mpc_mul_mpf(zm, scal, p, @mpf.round_nearest)
    s = mpc_add(s, term, p, @mpf.round_nearest)
    let szterm = mpc_abs(term, 20, @mpf.round_nearest)
    if k > 2 && @mpf.mpf_le(szterm, eps) {
      break
    }
    ratio = @mpf.mpf_mul_int(ratio, m + 2 * k, p, @mpf.round_nearest)
    ratio = @mpf.mpf_mul_int(ratio, m + 2 * k + 1, p, @mpf.round_nearest)
    ratio = @mpf.mpf_div(ratio, @mpf.from_int(2 * k + 1), p, @mpf.round_nearest)
    ratio = @mpf.mpf_div(ratio, @mpf.from_int(2 * k + 2), p, @mpf.round_nearest)
    k += 1
  }
  let mut v = mpc_mul_mpf(
    s,
    @gammazeta.mpf_gamma(@mpf.from_int(m + 1), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  if (m & 1) == 0 {
    v = mpc_neg(v, p, @mpf.round_nearest)
  }
  mpc_pos(v, prec, rnd)
}

///|
pub fn mpc_zetasum(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> RawMpc {
  let p = ext_prec(prec) + 12
  mpc_pos(zeta_series_sum(s, p, start, terms, false), prec, rnd)
}

///|
pub fn mpc_altzeta(s : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  if s.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_altzeta(s.real, prec, rnd))
  }
  let p = ext_prec(prec) + 12
  mpc_pos(zeta_series_sum(s, p, 1, clamp_series_terms(prec), true), prec, rnd)
}

///|
pub fn mpc_zeta(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> RawMpc {
  if s.imag == @mpf.fzero {
    return lift_real(@gammazeta.mpf_zeta(s.real, prec, rnd, alt~))
  }
  if alt {
    return mpc_altzeta(s, prec, rnd)
  }
  let p = ext_prec(prec) + 16
  let eta = zeta_series_sum(s, p, 1, clamp_series_terms(prec), true)
  let one_minus_s = mpc_sub(one(), s, p, @mpf.round_nearest)
  let two_pow = mpc_pow(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    one_minus_s,
    p,
    @mpf.round_nearest,
  )
  let denom = mpc_sub(one(), two_pow, p, @mpf.round_nearest)
  mpc_pos(mpc_div(eta, denom, p, @mpf.round_nearest), prec, rnd)
}
