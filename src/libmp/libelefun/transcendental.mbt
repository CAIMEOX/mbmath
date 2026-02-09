///|
fn work_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 24
  } else {
    80
  }
}

///|
fn tiny_enough(x : @mpf.RawMpf, bits : Int) -> Bool {
  if @mpf.is_zero(x) {
    true
  } else if !@mpf.is_finite(x) {
    false
  } else {
    x.exp + x.bc <= -bits
  }
}

///|
fn abs_mpf(x : @mpf.RawMpf, prec : Int) -> @mpf.RawMpf {
  @mpf.mpf_abs(x, prec, @mpf.round_nearest)
}

///|
fn atan_series_small(x : @mpf.RawMpf, wp : Int) -> @mpf.RawMpf {
  let x2 = @mpf.mpf_mul(x, x, wp, @mpf.round_nearest)
  let mut term = x
  let mut sum = x
  let mut k = 0
  while k < 20000 {
    let num = 2 * k + 1
    let den = num + 2
    term = @mpf.mpf_mul(term, x2, wp, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, -num, wp, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den), wp, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, wp, @mpf.round_nearest)
    if tiny_enough(abs_mpf(term, wp), wp + 8) {
      break
    }
    k += 1
  }
  sum
}

///|
fn ln_series_near_one(y : @mpf.RawMpf, wp : Int) -> @mpf.RawMpf {
  let one = @mpf.fone
  let t = @mpf.mpf_div(
    @mpf.mpf_sub(y, one, wp, @mpf.round_nearest),
    @mpf.mpf_add(y, one, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  let t2 = @mpf.mpf_mul(t, t, wp, @mpf.round_nearest)
  let mut term = t
  let mut sum = t
  let mut n = 1
  while n < 50000 {
    term = @mpf.mpf_mul(term, t2, wp, @mpf.round_nearest)
    let frac = @mpf.mpf_div(
      term,
      @mpf.from_int(2 * n + 1),
      wp,
      @mpf.round_nearest,
    )
    sum = @mpf.mpf_add(sum, frac, wp, @mpf.round_nearest)
    if tiny_enough(abs_mpf(frac, wp), wp + 10) {
      break
    }
    n += 1
  }
  @mpf.mpf_mul_int(sum, 2, wp, @mpf.round_nearest)
}

///|
fn exp_series_small(x : @mpf.RawMpf, wp : Int) -> @mpf.RawMpf {
  let mut term = @mpf.fone
  let mut sum = @mpf.fone
  let mut n = 1
  while n < 50000 {
    term = @mpf.mpf_mul(term, x, wp, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(n), wp, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, wp, @mpf.round_nearest)
    if tiny_enough(abs_mpf(term, wp), wp + 10) {
      break
    }
    n += 1
  }
  sum
}

///|
pub fn mpf_atan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_zero(x) {
    return @mpf.fzero
  }
  let wp = work_prec(prec)
  if @mpf.is_inf(x) {
    let half_pi = @mpf.mpf_shift(mpf_pi(wp, @mpf.round_nearest), -1)
    if x.sign == 1 {
      return @mpf.mpf_neg(half_pi, prec, rnd)
    } else {
      return @mpf.mpf_pos(half_pi, prec, rnd)
    }
  }
  let mut y = abs_mpf(x, wp)
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  let mut scale = 1
  while @mpf.mpf_gt(y, half) && scale < 1 << 16 {
    let y2 = @mpf.mpf_mul(y, y, wp, @mpf.round_nearest)
    let root = @mpf.mpf_sqrt(
      @mpf.mpf_add(@mpf.fone, y2, wp, @mpf.round_nearest),
      wp,
      @mpf.round_nearest,
    )
    y = @mpf.mpf_div(
      y,
      @mpf.mpf_add(@mpf.fone, root, wp, @mpf.round_nearest),
      wp,
      @mpf.round_nearest,
    )
    scale *= 2
  }
  let mut res = atan_series_small(y, wp)
  if scale != 1 {
    res = @mpf.mpf_mul_int(res, scale, wp, @mpf.round_nearest)
  }
  if x.sign == 1 {
    res = @mpf.mpf_neg(res, wp, @mpf.round_nearest)
  }
  @mpf.mpf_pos(res, prec, rnd)
}

///|
pub fn mpf_pi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  let wp = work_prec(prec)
  let a = @mpf.mpf_div(@mpf.fone, @mpf.from_int(5), wp, @mpf.round_nearest)
  let b = @mpf.mpf_div(@mpf.fone, @mpf.from_int(239), wp, @mpf.round_nearest)
  let t1 = mpf_atan(a, wp, @mpf.round_nearest)
  let t2 = mpf_atan(b, wp, @mpf.round_nearest)
  let p = @mpf.mpf_sub(
    @mpf.mpf_mul_int(t1, 16, wp, @mpf.round_nearest),
    @mpf.mpf_mul_int(t2, 4, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(p, prec, rnd)
}

///|
pub fn mpf_atan2(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(y) || @mpf.is_nan(x) {
    return @mpf.fnan
  }
  let wp = work_prec(prec)
  let sx = @mpf.mpf_sign(x)
  let sy = @mpf.mpf_sign(y)
  if sx == 0 {
    if sy > 0 {
      return @mpf.mpf_shift(mpf_pi(prec, rnd), -1)
    }
    if sy < 0 {
      return @mpf.mpf_neg(@mpf.mpf_shift(mpf_pi(prec, rnd), -1), prec, rnd)
    }
    return @mpf.fzero
  }
  let q = @mpf.mpf_div(y, x, wp, @mpf.round_nearest)
  let a = mpf_atan(q, wp, @mpf.round_nearest)
  if sx > 0 {
    return @mpf.mpf_pos(a, prec, rnd)
  }
  let p = mpf_pi(wp, @mpf.round_nearest)
  if sy >= 0 {
    @mpf.mpf_pos(@mpf.mpf_add(a, p, wp, @mpf.round_nearest), prec, rnd)
  } else {
    @mpf.mpf_pos(@mpf.mpf_sub(a, p, wp, @mpf.round_nearest), prec, rnd)
  }
}

///|
pub fn mpf_exp(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fzero
    } else {
      return @mpf.finf
    }
  }
  if @mpf.is_zero(x) {
    return @mpf.fone
  }
  let wp = work_prec(prec)
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  let mut r = @mpf.mpf_pos(x, wp, @mpf.round_nearest)
  let mut k = 0
  while @mpf.mpf_gt(abs_mpf(r, wp), half) && k < 2048 {
    r = @mpf.mpf_shift(r, -1)
    k += 1
  }
  let mut y = exp_series_small(r, wp)
  for _ in 0..<k {
    y = @mpf.mpf_mul(y, y, wp, @mpf.round_nearest)
  }
  @mpf.mpf_pos(y, prec, rnd)
}

///|
pub fn mpf_ln(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      abort("mpf_ln: non-positive input")
    } else {
      return @mpf.finf
    }
  }
  if @mpf.is_zero(x) || x.sign == 1 {
    abort("mpf_ln: non-positive input")
  }
  if x == @mpf.fone {
    return @mpf.fzero
  }
  let wp = work_prec(prec)
  let k = x.exp + x.bc - 1
  let m = @mpf.mpf_shift(x, -k)
  let ln_m = ln_series_near_one(m, wp)
  let ln2 = ln_series_near_one(@mpf.from_int(2), wp)
  let kln2 = @mpf.mpf_mul_int(ln2, k, wp, @mpf.round_nearest)
  let v = @mpf.mpf_add(ln_m, kln2, wp, @mpf.round_nearest)
  @mpf.mpf_pos(v, prec, rnd)
}

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !@mpf.is_finite(x) || @mpf.is_zero(x) || x.exp < 0 {
    return None
  }
  let v = x.man << x.exp
  if v.bit_length() > 60 {
    return None
  }
  let n = v.to_int()
  let signed_n = if x.sign == 1 { -n } else { n }
  if @mpf.mpf_eq(x, @mpf.from_int(signed_n)) {
    Some(signed_n)
  } else {
    None
  }
}

///|
fn sin_cos_series_small(
  x : @mpf.RawMpf,
  wp : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  let x2 = @mpf.mpf_mul(x, x, wp, @mpf.round_nearest)
  let mut sin_term = x
  let mut sin_sum = x
  let mut cos_term = @mpf.fone
  let mut cos_sum = @mpf.fone
  let mut k = 1
  while k < 50000 {
    sin_term = @mpf.mpf_mul(sin_term, x2, wp, @mpf.round_nearest)
    sin_term = @mpf.mpf_mul_int(sin_term, -1, wp, @mpf.round_nearest)
    sin_term = @mpf.mpf_div(
      sin_term,
      @mpf.from_int(2 * k),
      wp,
      @mpf.round_nearest,
    )
    sin_term = @mpf.mpf_div(
      sin_term,
      @mpf.from_int(2 * k + 1),
      wp,
      @mpf.round_nearest,
    )
    sin_sum = @mpf.mpf_add(sin_sum, sin_term, wp, @mpf.round_nearest)
    cos_term = @mpf.mpf_mul(cos_term, x2, wp, @mpf.round_nearest)
    cos_term = @mpf.mpf_mul_int(cos_term, -1, wp, @mpf.round_nearest)
    cos_term = @mpf.mpf_div(
      cos_term,
      @mpf.from_int(2 * k - 1),
      wp,
      @mpf.round_nearest,
    )
    cos_term = @mpf.mpf_div(
      cos_term,
      @mpf.from_int(2 * k),
      wp,
      @mpf.round_nearest,
    )
    cos_sum = @mpf.mpf_add(cos_sum, cos_term, wp, @mpf.round_nearest)
    if tiny_enough(abs_mpf(sin_term, wp), wp + 10) &&
      tiny_enough(abs_mpf(cos_term, wp), wp + 10) {
      break
    }
    k += 1
  }
  (sin_sum, cos_sum)
}

///|
fn sin_cos_reduced(x : @mpf.RawMpf, wp : Int) -> (@mpf.RawMpf, @mpf.RawMpf) {
  let pi = mpf_pi(wp, @mpf.round_nearest)
  let two_pi = @mpf.mpf_mul_int(pi, 2, wp, @mpf.round_nearest)
  let half_pi = @mpf.mpf_shift(pi, -1)
  let quarter_pi = @mpf.mpf_shift(pi, -2)
  let neg_half_pi = @mpf.mpf_neg(half_pi, 0, @mpf.round_down)
  let neg_quarter_pi = @mpf.mpf_neg(quarter_pi, 0, @mpf.round_down)
  let mut y = @mpf.mpf_pos(x, wp, @mpf.round_nearest)
  let turns = @mpf.mpf_nint(
    @mpf.mpf_div(y, two_pi, wp, @mpf.round_nearest),
    0,
    @mpf.round_nearest,
  )
  y = @mpf.mpf_sub(
    y,
    @mpf.mpf_mul(turns, two_pi, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  let mut cos_sign = 1
  if @mpf.mpf_gt(y, half_pi) {
    y = @mpf.mpf_sub(pi, y, wp, @mpf.round_nearest)
    cos_sign = -1
  } else if @mpf.mpf_lt(y, neg_half_pi) {
    y = @mpf.mpf_neg(
      @mpf.mpf_add(pi, y, wp, @mpf.round_nearest),
      wp,
      @mpf.round_nearest,
    )
    cos_sign = -1
  }
  let (s0, c0) = if @mpf.mpf_gt(y, quarter_pi) {
    let t = @mpf.mpf_sub(half_pi, y, wp, @mpf.round_nearest)
    let (s, c) = sin_cos_series_small(t, wp)
    (c, s)
  } else if @mpf.mpf_lt(y, neg_quarter_pi) {
    let t = @mpf.mpf_add(half_pi, y, wp, @mpf.round_nearest)
    let (s, c) = sin_cos_series_small(t, wp)
    (@mpf.mpf_neg(c, wp, @mpf.round_nearest), s)
  } else {
    sin_cos_series_small(y, wp)
  }
  let s = s0
  let mut c = c0
  if cos_sign == -1 {
    c = @mpf.mpf_neg(c, wp, @mpf.round_nearest)
  }
  (s, c)
}

///|
pub fn mpf_log(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  mpf_ln(x, prec, rnd)
}

///|
pub fn mpf_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) || @mpf.is_inf(x) {
    return @mpf.fnan
  }
  if @mpf.is_zero(x) {
    return @mpf.fzero
  }
  let wp = work_prec(prec) + 8
  let (s, _) = sin_cos_reduced(x, wp)
  @mpf.mpf_pos(s, prec, rnd)
}

///|
pub fn mpf_cos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) || @mpf.is_inf(x) {
    return @mpf.fnan
  }
  if @mpf.is_zero(x) {
    return @mpf.fone
  }
  let wp = work_prec(prec) + 8
  let (_, c) = sin_cos_reduced(x, wp)
  @mpf.mpf_pos(c, prec, rnd)
}

///|
pub fn mpf_tan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) || @mpf.is_inf(x) {
    return @mpf.fnan
  }
  let wp = work_prec(prec) + 8
  let (s, c) = sin_cos_reduced(x, wp)
  @mpf.mpf_pos(@mpf.mpf_div(s, c, wp, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    return x
  }
  let wp = work_prec(prec) + 8
  let ex = mpf_exp(x, wp, @mpf.round_nearest)
  let enx = mpf_exp(
    @mpf.mpf_neg(x, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(
    @mpf.mpf_shift(@mpf.mpf_sub(ex, enx, wp, @mpf.round_nearest), -1),
    prec,
    rnd,
  )
}

///|
pub fn mpf_cosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    return @mpf.finf
  }
  let wp = work_prec(prec) + 8
  let ex = mpf_exp(x, wp, @mpf.round_nearest)
  let enx = mpf_exp(
    @mpf.mpf_neg(x, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(
    @mpf.mpf_shift(@mpf.mpf_add(ex, enx, wp, @mpf.round_nearest), -1),
    prec,
    rnd,
  )
}

///|
pub fn mpf_tanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fnone
    } else {
      return @mpf.fone
    }
  }
  let wp = work_prec(prec) + 8
  let sh = mpf_sinh(x, wp, @mpf.round_nearest)
  let ch = mpf_cosh(x, wp, @mpf.round_nearest)
  @mpf.mpf_pos(@mpf.mpf_div(sh, ch, wp, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_asin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    abort("mpf_asin: |x| must be <= 1")
  }
  let wp = work_prec(prec) + 8
  let ax = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, @mpf.fone) {
    abort("mpf_asin: |x| must be <= 1")
  }
  let t = @mpf.mpf_sub(
    @mpf.fone,
    @mpf.mpf_mul(x, x, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  let root = @mpf.mpf_sqrt(t, wp, @mpf.round_nearest)
  mpf_atan2(x, root, prec, rnd)
}

///|
pub fn mpf_acos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    abort("mpf_acos: |x| must be <= 1")
  }
  let wp = work_prec(prec) + 8
  let ax = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, @mpf.fone) {
    abort("mpf_acos: |x| must be <= 1")
  }
  let t = @mpf.mpf_sub(
    @mpf.fone,
    @mpf.mpf_mul(x, x, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  let root = @mpf.mpf_sqrt(t, wp, @mpf.round_nearest)
  mpf_atan2(root, x, prec, rnd)
}

///|
pub fn mpf_asinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    return x
  }
  let wp = work_prec(prec) + 8
  let x2 = @mpf.mpf_mul(x, x, wp, @mpf.round_nearest)
  let root = @mpf.mpf_sqrt(
    @mpf.mpf_add(x2, @mpf.fone, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  mpf_ln(@mpf.mpf_add(x, root, wp, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_acosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      abort("mpf_acosh: x must be >= 1")
    }
    return @mpf.finf
  }
  if @mpf.mpf_lt(x, @mpf.fone) {
    abort("mpf_acosh: x must be >= 1")
  }
  if @mpf.mpf_eq(x, @mpf.fone) {
    return @mpf.fzero
  }
  let wp = work_prec(prec) + 8
  let xm1 = @mpf.mpf_sub(x, @mpf.fone, wp, @mpf.round_nearest)
  let xp1 = @mpf.mpf_add(x, @mpf.fone, wp, @mpf.round_nearest)
  let root = @mpf.mpf_mul(
    @mpf.mpf_sqrt(xm1, wp, @mpf.round_nearest),
    @mpf.mpf_sqrt(xp1, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  mpf_ln(@mpf.mpf_add(x, root, wp, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_atanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    abort("mpf_atanh: |x| must be <= 1")
  }
  if @mpf.mpf_eq(x, @mpf.fone) {
    return @mpf.finf
  }
  if @mpf.mpf_eq(x, @mpf.fnone) {
    return @mpf.fninf
  }
  let wp = work_prec(prec) + 8
  let ax = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, @mpf.fone) {
    abort("mpf_atanh: |x| must be <= 1")
  }
  let ratio = @mpf.mpf_div(
    @mpf.mpf_add(@mpf.fone, x, wp, @mpf.round_nearest),
    @mpf.mpf_sub(@mpf.fone, x, wp, @mpf.round_nearest),
    wp,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(
    @mpf.mpf_shift(mpf_ln(ratio, wp, @mpf.round_nearest), -1),
    prec,
    rnd,
  )
}

///|
pub fn mpf_pow(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(y) {
    return @mpf.fnan
  }
  if @mpf.is_zero(y) {
    return @mpf.fone
  }
  match maybe_integer(y) {
    Some(n) => @mpf.mpf_pow_int(x, n, prec, rnd)
    None => {
      if @mpf.is_nan(x) {
        return @mpf.fnan
      }
      if @mpf.is_zero(x) {
        if @mpf.mpf_sign(y) > 0 {
          return @mpf.fzero
        } else {
          return @mpf.finf
        }
      }
      if x.sign == 1 {
        abort("mpf_pow: negative base with non-integer exponent")
      }
      let wp = work_prec(prec) + 8
      let t = @mpf.mpf_mul(
        y,
        mpf_ln(x, wp, @mpf.round_nearest),
        wp,
        @mpf.round_nearest,
      )
      @mpf.mpf_pos(mpf_exp(t, wp, @mpf.round_nearest), prec, rnd)
    }
  }
}

///|
pub fn mpf_nthroot(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if n == 0 {
    abort("mpf_nthroot: n must be non-zero")
  }
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if n < 0 {
    let wp = work_prec(prec) + 8
    let y = mpf_nthroot(x, -n, wp, @mpf.round_nearest)
    return @mpf.mpf_div(@mpf.fone, y, prec, rnd)
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      if (n & 1) == 0 {
        abort("mpf_nthroot: even root of negative value")
      }
      return @mpf.fninf
    }
    return @mpf.finf
  }
  if @mpf.is_zero(x) {
    return @mpf.fzero
  }
  if x.sign == 1 && (n & 1) == 0 {
    abort("mpf_nthroot: even root of negative value")
  }
  let wp = work_prec(prec) + 8
  let inv_n = @mpf.mpf_rdiv_int(1, @mpf.from_int(n), wp, @mpf.round_nearest)
  if x.sign == 1 {
    let ax = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
    @mpf.mpf_neg(mpf_pow(ax, inv_n, prec, rnd), prec, rnd)
  } else {
    mpf_pow(x, inv_n, prec, rnd)
  }
}

///|
pub fn mpf_cbrt(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  mpf_nthroot(x, 3, prec, rnd)
}

///|
pub fn mpf_e(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  mpf_exp(@mpf.fone, prec, rnd)
}

///|
pub fn mpf_ln2(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  mpf_ln(@mpf.from_int(2), prec, rnd)
}

///|
pub fn mpf_ln10(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  mpf_ln(@mpf.from_int(10), prec, rnd)
}

///|
pub fn mpf_phi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  let wp = work_prec(prec) + 8
  let root5 = @mpf.mpf_sqrt(@mpf.from_int(5), wp, @mpf.round_nearest)
  let t = @mpf.mpf_shift(
    @mpf.mpf_add(@mpf.fone, root5, wp, @mpf.round_nearest),
    -1,
  )
  @mpf.mpf_pos(t, prec, rnd)
}

///|
pub fn mpf_degree(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  let wp = work_prec(prec) + 8
  @mpf.mpf_pos(
    @mpf.mpf_div(
      mpf_pi(wp, @mpf.round_nearest),
      @mpf.from_int(180),
      wp,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}
