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
  if x.is_zero() {
    true
  } else if !x.is_finite() {
    false
  } else {
    x.exp + x.bc <= -bits
  }
}

///|
fn abs_mpf(x : @mpf.RawMpf, prec : Int) -> @mpf.RawMpf {
  x.abs(prec, Nearest)
}

///|
fn from_mpf_error(err : @mpf.MpfError) -> LibElefunError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    DivisionByZero(msg) => DomainError(msg)
    OverflowError(msg) => ValueError(msg)
    ParseError(msg) => ValueError(msg)
    FormatError(msg) => ValueError(msg)
    UnsupportedError(msg) => ValueError(msg)
  }
}

///|
fn div_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  x.div(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn rdiv_int_checked(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  x.int_divided_by(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn sqrt_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  x.sqrt(prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn pow_int_checked(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  x.pow_int(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn hypot_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  x.hypot(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn ln_positive_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ln(x, prec, rnd)
}

///|
fn log_positive_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  log(x, prec, rnd)
}

///|
fn nthroot_checked(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  nthroot(x, n, prec, rnd)
}

///|
fn atan_series_small(
  x : @mpf.RawMpf,
  wp : Int,
) -> @mpf.RawMpf raise LibElefunError {
  let x2 = x.mul(x, wp, Nearest)
  let mut term = x
  let mut sum = x
  let mut k = 0
  while k < 20000 {
    let num = 2 * k + 1
    let den = num + 2
    term = term.mul(x2, wp, Nearest)
    term = term.mul_int(-num, wp, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(den), wp, Nearest)
    sum = sum.add(term, wp, Nearest)
    if tiny_enough(abs_mpf(term, wp), wp + 8) {
      break
    }
    k += 1
  }
  sum
}

///|
fn ln_series_near_one(
  y : @mpf.RawMpf,
  wp : Int,
) -> @mpf.RawMpf raise LibElefunError {
  let one = @mpf.RawMpf::one()
  let t = div_checked(
    y.sub(one, wp, Nearest),
    y.add(one, wp, Nearest),
    wp,
    Nearest,
  )
  let t2 = t.mul(t, wp, Nearest)
  let mut term = t
  let mut sum = t
  let mut n = 1
  while n < 50000 {
    term = term.mul(t2, wp, Nearest)
    let frac = div_checked(term, @mpf.RawMpf::from_int(2 * n + 1), wp, Nearest)
    sum = sum.add(frac, wp, Nearest)
    if tiny_enough(abs_mpf(frac, wp), wp + 10) {
      break
    }
    n += 1
  }
  sum.mul_int(2, wp, Nearest)
}

///|
fn exp_series_small(
  x : @mpf.RawMpf,
  wp : Int,
) -> @mpf.RawMpf raise LibElefunError {
  let mut term = @mpf.RawMpf::one()
  let mut sum = @mpf.RawMpf::one()
  let mut n = 1
  while n < 50000 {
    term = term.mul(x, wp, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(n), wp, Nearest)
    sum = sum.add(term, wp, Nearest)
    if tiny_enough(abs_mpf(term, wp), wp + 10) {
      break
    }
    n += 1
  }
  sum
}

///|
fn sinh_series_small(
  x : @mpf.RawMpf,
  wp : Int,
) -> @mpf.RawMpf raise LibElefunError {
  let x2 = x.mul(x, wp, Nearest)
  let mut term = x
  let mut sum = x
  let mut k = 1
  while k < 50000 {
    term = term.mul(x2, wp, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(2 * k), wp, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(2 * k + 1), wp, Nearest)
    sum = sum.add(term, wp, Nearest)
    if tiny_enough(abs_mpf(term, wp), wp + 10) {
      break
    }
    k += 1
  }
  sum
}

///|
pub fn atan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let wp = work_prec(prec)
  if x.is_infinite() {
    let half_pi = pi(wp, Nearest).scale_pow2(-1)
    if x.sign == 1 {
      return half_pi.negated(prec, rnd)
    } else {
      return half_pi.rounded(prec, rnd)
    }
  }
  let mut y = abs_mpf(x, wp)
  let half = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
  let mut scale = 1
  while y > half && scale < 1 << 16 {
    let y2 = y.mul(y, wp, Nearest)
    let root = sqrt_checked(
      @mpf.RawMpf::one().add(y2, wp, Nearest),
      wp,
      Nearest,
    )
    y = div_checked(y, @mpf.RawMpf::one().add(root, wp, Nearest), wp, Nearest)
    scale *= 2
  }
  let mut res = atan_series_small(y, wp)
  if scale != 1 {
    res = res.mul_int(scale, wp, Nearest)
  }
  if x.sign == 1 {
    res = res.negated(wp, Nearest)
  }
  res.rounded(prec, rnd)
}

///|
pub fn pi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf raise LibElefunError {
  let wp = work_prec(prec)
  let a = div_checked(@mpf.RawMpf::one(), @mpf.RawMpf::from_int(5), wp, Nearest)
  let b = div_checked(
    @mpf.RawMpf::one(),
    @mpf.RawMpf::from_int(239),
    wp,
    Nearest,
  )
  let t1 = atan(a, wp, Nearest)
  let t2 = atan(b, wp, Nearest)
  let p = t1
    .mul_int(16, wp, Nearest)
    .sub(t2.mul_int(4, wp, Nearest), wp, Nearest)
  p.rounded(prec, rnd)
}

///|
pub fn atan2(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if y.is_nan() || x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if y.is_infinite() && x.is_infinite() {
    let quarter_pi = pi(prec, rnd).scale_pow2(-2)
    let magnitude = if x.sign == 1 {
      quarter_pi.mul_int(3, prec, rnd)
    } else {
      quarter_pi
    }
    return if y.sign == 1 { magnitude.negated(prec, rnd) } else { magnitude }
  }
  let wp = work_prec(prec)
  let sx = x.signum()
  let sy = y.signum()
  if sx == 0 {
    if sy > 0 {
      return pi(prec, rnd).scale_pow2(-1)
    }
    if sy < 0 {
      return pi(prec, rnd).scale_pow2(-1).negated(prec, rnd)
    }
    return @mpf.RawMpf::zero()
  }
  let q = div_checked(y, x, wp, Nearest)
  let a = atan(q, wp, Nearest)
  if sx > 0 {
    return a.rounded(prec, rnd)
  }
  let p = pi(wp, Nearest)
  if sy >= 0 {
    a.add(p, wp, Nearest).rounded(prec, rnd)
  } else {
    a.sub(p, wp, Nearest).rounded(prec, rnd)
  }
}

///|
pub fn exp(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::zero()
    } else {
      return @mpf.RawMpf::infinity()
    }
  }
  if x.is_zero() {
    return @mpf.RawMpf::one()
  }
  let wp = work_prec(prec)
  let half = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
  let mut r = x.rounded(wp, Nearest)
  let mut k = 0
  while abs_mpf(r, wp) > half && k < 2048 {
    r = r.scale_pow2(-1)
    k += 1
  }
  let mut y = exp_series_small(r, wp)
  for _ in 0..<k {
    y = y.mul(y, wp, Nearest)
  }
  y.rounded(prec, rnd)
}

///|
pub fn ln(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      raise DomainError("ln: non-positive input")
    } else {
      return @mpf.RawMpf::infinity()
    }
  }
  if x.is_zero() {
    return @mpf.RawMpf::negative_infinity()
  }
  if x.sign == 1 {
    raise DomainError("ln: non-positive input")
  }
  if x == @mpf.RawMpf::one() {
    return @mpf.RawMpf::zero()
  }
  let wp = work_prec(prec)
  let k = x.exp + x.bc - 1
  let m = x.scale_pow2(-k)
  let ln_m = ln_series_near_one(m, wp)
  let ln2 = ln_series_near_one(@mpf.RawMpf::from_int(2), wp)
  let kln2 = ln2.mul_int(k, wp, Nearest)
  let v = ln_m.add(kln2, wp, Nearest)
  v.rounded(prec, rnd)
}

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !x.is_finite() || x.is_zero() || x.exp < 0 {
    return None
  }
  let v = x.man << x.exp
  if v.bit_length() > 60 {
    return None
  }
  let n = v.to_int()
  let signed_n = if x.sign == 1 { -n } else { n }
  if x == @mpf.RawMpf::from_int(signed_n) {
    Some(signed_n)
  } else {
    None
  }
}

///|
fn sin_cos_series_small(
  x : @mpf.RawMpf,
  wp : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  let x2 = x.mul(x, wp, Nearest)
  let mut sin_term = x
  let mut sin_sum = x
  let mut cos_term = @mpf.RawMpf::one()
  let mut cos_sum = @mpf.RawMpf::one()
  let mut k = 1
  while k < 50000 {
    sin_term = sin_term.mul(x2, wp, Nearest)
    sin_term = sin_term.mul_int(-1, wp, Nearest)
    sin_term = div_checked(sin_term, @mpf.RawMpf::from_int(2 * k), wp, Nearest)
    sin_term = div_checked(
      sin_term,
      @mpf.RawMpf::from_int(2 * k + 1),
      wp,
      Nearest,
    )
    sin_sum = sin_sum.add(sin_term, wp, Nearest)
    cos_term = cos_term.mul(x2, wp, Nearest)
    cos_term = cos_term.mul_int(-1, wp, Nearest)
    cos_term = div_checked(
      cos_term,
      @mpf.RawMpf::from_int(2 * k - 1),
      wp,
      Nearest,
    )
    cos_term = div_checked(cos_term, @mpf.RawMpf::from_int(2 * k), wp, Nearest)
    cos_sum = cos_sum.add(cos_term, wp, Nearest)
    if tiny_enough(abs_mpf(sin_term, wp), wp + 10) &&
      tiny_enough(abs_mpf(cos_term, wp), wp + 10) {
      break
    }
    k += 1
  }
  (sin_sum, cos_sum)
}

///|
fn sin_cos_reduced(
  x : @mpf.RawMpf,
  wp : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  let pi = pi(wp, Nearest)
  let two_pi = pi.mul_int(2, wp, Nearest)
  let half_pi = pi.scale_pow2(-1)
  let quarter_pi = pi.scale_pow2(-2)
  let neg_half_pi = half_pi.negated(0, Down)
  let neg_quarter_pi = quarter_pi.negated(0, Down)
  let mut y = x.rounded(wp, Nearest)
  let turns = div_checked(y, two_pi, wp, Nearest).nearest_integer(0, Nearest)
  y = y.sub(turns.mul(two_pi, wp, Nearest), wp, Nearest)
  let mut cos_sign = 1
  if y > half_pi {
    y = pi.sub(y, wp, Nearest)
    cos_sign = -1
  } else if y < neg_half_pi {
    y = pi.add(y, wp, Nearest).negated(wp, Nearest)
    cos_sign = -1
  }
  let (s0, c0) = if y > quarter_pi {
    let t = half_pi.sub(y, wp, Nearest)
    let (s, c) = sin_cos_series_small(t, wp)
    (c, s)
  } else if y < neg_quarter_pi {
    let t = half_pi.add(y, wp, Nearest)
    let (s, c) = sin_cos_series_small(t, wp)
    (c.negated(wp, Nearest), s)
  } else {
    sin_cos_series_small(y, wp)
  }
  let s = s0
  let mut c = c0
  if cos_sign == -1 {
    c = c.negated(wp, Nearest)
  }
  (s, c)
}

///|
pub fn log(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ln(x, prec, rnd)
}

///|
pub fn log1p(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      raise DomainError("log1p: x must be >= -1")
    } else {
      return @mpf.RawMpf::infinity()
    }
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  if x == @mpf.RawMpf::negative_one() {
    return @mpf.RawMpf::negative_infinity()
  }
  if x.sign == 1 && x.negated(0, Down) > @mpf.RawMpf::one() {
    raise DomainError("log1p: x must be >= -1")
  }
  let wp = work_prec(prec) + 10
  let u = @mpf.RawMpf::one().add(x, wp * 2, Nearest)
  if u.is_zero() {
    return @mpf.RawMpf::negative_infinity()
  }
  if u.sign == 1 {
    raise DomainError("log1p: x must be >= -1")
  }
  let lnu = ln_positive_checked(u, wp, Nearest)
  let den = u.sub(@mpf.RawMpf::one(), wp, Nearest)
  let corr = if den.is_zero() {
    @mpf.RawMpf::one()
  } else {
    div_checked(x, den, wp, Nearest)
  }
  lnu.mul(corr, wp, Nearest).rounded(prec, rnd)
}

///|
pub fn sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() || x.is_infinite() {
    return @mpf.RawMpf::nan()
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let wp = work_prec(prec) + 8
  let (s, _) = sin_cos_reduced(x, wp)
  s.rounded(prec, rnd)
}

///|
pub fn cos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() || x.is_infinite() {
    return @mpf.RawMpf::nan()
  }
  if x.is_zero() {
    return @mpf.RawMpf::one()
  }
  let wp = work_prec(prec) + 8
  let (_, c) = sin_cos_reduced(x, wp)
  c.rounded(prec, rnd)
}

///|
pub fn tan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() || x.is_infinite() {
    return @mpf.RawMpf::nan()
  }
  let wp = work_prec(prec) + 8
  let (s, c) = sin_cos_reduced(x, wp)
  div_checked(s, c, wp, Nearest).rounded(prec, rnd)
}

///|
pub fn sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return x
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let wp = work_prec(prec) + 8
  let ax = x.abs(wp, Nearest)
  let half = @mpf.RawMpf::half()
  let magnitude = if ax <= half {
    sinh_series_small(ax, wp)
  } else {
    let ex = exp(ax, wp, Nearest)
    let enx = exp(ax.negated(wp, Nearest), wp, Nearest)
    ex.sub(enx, wp, Nearest).scale_pow2(-1)
  }
  let result = if x.sign == 1 {
    magnitude.negated(wp, Nearest)
  } else {
    magnitude
  }
  result.rounded(prec, rnd)
}

///|
pub fn cosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return @mpf.RawMpf::infinity()
  }
  let wp = work_prec(prec) + 8
  let ex = exp(x, wp, Nearest)
  let enx = exp(x.negated(wp, Nearest), wp, Nearest)
  ex.add(enx, wp, Nearest).scale_pow2(-1).rounded(prec, rnd)
}

///|
pub fn tanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::negative_one()
    } else {
      return @mpf.RawMpf::one()
    }
  }
  let wp = work_prec(prec) + 8
  let sh = sinh(x, wp, Nearest)
  let ch = cosh(x, wp, Nearest)
  div_checked(sh, ch, wp, Nearest).rounded(prec, rnd)
}

///|
pub fn asin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    raise DomainError("asin: |x| must be <= 1")
  }
  let wp = work_prec(prec) + 8
  let ax = x.abs(wp, Nearest)
  if ax > @mpf.RawMpf::one() {
    raise DomainError("asin: |x| must be <= 1")
  }
  let t = @mpf.RawMpf::one().sub(x.mul(x, wp, Nearest), wp, Nearest)
  let root = sqrt_checked(t, wp, Nearest)
  atan2(x, root, prec, rnd)
}

///|
pub fn acos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    raise DomainError("acos: |x| must be <= 1")
  }
  let wp = work_prec(prec) + 8
  let ax = x.abs(wp, Nearest)
  if ax > @mpf.RawMpf::one() {
    raise DomainError("acos: |x| must be <= 1")
  }
  let t = @mpf.RawMpf::one().sub(x.mul(x, wp, Nearest), wp, Nearest)
  let root = sqrt_checked(t, wp, Nearest)
  atan2(root, x, prec, rnd)
}

///|
pub fn asinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return x
  }
  let wp = work_prec(prec) + 8
  let ax = x.abs(wp, Nearest)
  let x2 = ax.mul(ax, wp, Nearest)
  let root = sqrt_checked(x2.add(@mpf.RawMpf::one(), wp, Nearest), wp, Nearest)
  let magnitude = ln_positive_checked(ax.add(root, wp, Nearest), wp, Nearest)
  let result = if x.sign == 1 {
    magnitude.negated(wp, Nearest)
  } else {
    magnitude
  }
  result.rounded(prec, rnd)
}

///|
pub fn acosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      raise DomainError("acosh: x must be >= 1")
    }
    return @mpf.RawMpf::infinity()
  }
  if x < @mpf.RawMpf::one() {
    raise DomainError("acosh: x must be >= 1")
  }
  if x == @mpf.RawMpf::one() {
    return @mpf.RawMpf::zero()
  }
  let wp = work_prec(prec) + 8
  let xm1 = x.sub(@mpf.RawMpf::one(), wp, Nearest)
  let xp1 = x.add(@mpf.RawMpf::one(), wp, Nearest)
  let root = sqrt_checked(xm1, wp, Nearest).mul(
    sqrt_checked(xp1, wp, Nearest),
    wp,
    Nearest,
  )
  ln_positive_checked(x.add(root, wp, Nearest), prec, rnd)
}

///|
pub fn atanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    raise DomainError("atanh: |x| must be <= 1")
  }
  if x == @mpf.RawMpf::one() {
    return @mpf.RawMpf::infinity()
  }
  if x == @mpf.RawMpf::negative_one() {
    return @mpf.RawMpf::negative_infinity()
  }
  let wp = work_prec(prec) + 8
  let ax = x.abs(wp, Nearest)
  if ax > @mpf.RawMpf::one() {
    raise DomainError("atanh: |x| must be <= 1")
  }
  let ratio = div_checked(
    @mpf.RawMpf::one().add(x, wp, Nearest),
    @mpf.RawMpf::one().sub(x, wp, Nearest),
    wp,
    Nearest,
  )
  ln_positive_checked(ratio, wp, Nearest).scale_pow2(-1).rounded(prec, rnd)
}

///|
pub fn pow(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if y.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if y.is_zero() {
    return @mpf.RawMpf::one()
  }
  match maybe_integer(y) {
    Some(n) => pow_int_checked(x, n, prec, rnd)
    None => {
      if x.is_nan() {
        return @mpf.RawMpf::nan()
      }
      if x.is_zero() {
        if y.signum() > 0 {
          return @mpf.RawMpf::zero()
        } else {
          return @mpf.RawMpf::infinity()
        }
      }
      if x.sign == 1 {
        raise DomainError("pow: negative base with non-integer exponent")
      }
      let wp = work_prec(prec) + 8
      let t = y.mul(ln_positive_checked(x, wp, Nearest), wp, Nearest)
      exp(t, wp, Nearest).rounded(prec, rnd)
    }
  }
}

///|
pub fn nthroot(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if n == 0 {
    raise ValueError("nthroot: n must be non-zero")
  }
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if n < 0 {
    let wp = work_prec(prec) + 8
    let y = nthroot(x, -n, wp, Nearest)
    return div_checked(@mpf.RawMpf::one(), y, prec, rnd)
  }
  if x.is_infinite() {
    if x.sign == 1 {
      if (n & 1) == 0 {
        raise DomainError("nthroot: even root of negative value")
      }
      return @mpf.RawMpf::negative_infinity()
    }
    return @mpf.RawMpf::infinity()
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  if x.sign == 1 && (n & 1) == 0 {
    raise DomainError("nthroot: even root of negative value")
  }
  let wp = work_prec(prec) + 8
  let inv_n = rdiv_int_checked(1, @mpf.RawMpf::from_int(n), wp, Nearest)
  if x.sign == 1 {
    let ax = x.abs(wp, Nearest)
    pow(ax, inv_n, prec, rnd).negated(prec, rnd)
  } else {
    pow(x, inv_n, prec, rnd)
  }
}

///|
pub fn cbrt(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  nthroot_checked(x, 3, prec, rnd)
}

///|
pub fn e(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf raise LibElefunError {
  exp(@mpf.RawMpf::one(), prec, rnd)
}

///|
pub fn ln2(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ln_positive_checked(@mpf.RawMpf::from_int(2), prec, rnd)
}

///|
pub fn ln10(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  ln_positive_checked(@mpf.RawMpf::from_int(10), prec, rnd)
}

///|
pub fn sqrt_pi(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let wp = work_prec(prec) + 8
  sqrt_checked(pi(wp, Nearest), wp, Nearest).rounded(prec, rnd)
}

///|
pub fn ln_sqrt_2pi(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let wp = work_prec(prec) + 8
  let two_pi = pi(wp, Nearest).mul_int(2, wp, Nearest)
  ln_positive_checked(two_pi, wp, Nearest).scale_pow2(-1).rounded(prec, rnd)
}

///|
pub fn phi(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let wp = work_prec(prec) + 8
  let root5 = sqrt_checked(@mpf.RawMpf::from_int(5), wp, Nearest)
  let t = @mpf.RawMpf::one().add(root5, wp, Nearest).scale_pow2(-1)
  t.rounded(prec, rnd)
}

///|
pub fn degree(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let wp = work_prec(prec) + 8
  div_checked(pi(wp, Nearest), @mpf.RawMpf::from_int(180), wp, Nearest).rounded(
    prec, rnd,
  )
}

///|
fn exact_cos_sin_pi(x : @mpf.RawMpf) -> (@mpf.RawMpf, @mpf.RawMpf)? {
  if !x.is_finite() {
    return None
  }
  if x.is_zero() {
    return Some((@mpf.RawMpf::one(), @mpf.RawMpf::zero()))
  }
  if x.exp >= 0 {
    let even = x.exp > 0 || (x.man & 1N) == 0N
    let cosine = if even {
      @mpf.RawMpf::one()
    } else {
      @mpf.RawMpf::negative_one()
    }
    return Some((cosine, @mpf.RawMpf::zero()))
  }
  if x.exp == -1 {
    let residue = (x.man & 3N).to_int()
    let mut sine = if residue == 1 {
      @mpf.RawMpf::one()
    } else {
      @mpf.RawMpf::negative_one()
    }
    if x.sign == 1 {
      sine = sine.negated(0, Down)
    }
    return Some((@mpf.RawMpf::zero(), sine))
  }
  None
}

///|
fn reduce_pi_units(x : @mpf.RawMpf) -> @mpf.RawMpf {
  // Avoid forming `2^(1-exp)` when the value already lies inside one period.
  if x.exp <= 1 - x.bc {
    return x
  }
  let shift = 1 - x.exp
  let remainder = x.man - (x.man >> shift << shift)
  if remainder == 0N {
    return @mpf.RawMpf::zero()
  }
  let signed_remainder = if x.sign == 1 { -remainder } else { remainder }
  let reduced = @mpf.RawMpf::from_mantissa_exponent(
    signed_remainder,
    x.exp,
    0,
    Down,
  )
  if reduced > @mpf.RawMpf::one() {
    reduced.sub(@mpf.RawMpf::two(), 0, Down)
  } else if reduced < @mpf.RawMpf::negative_one() {
    reduced.add(@mpf.RawMpf::two(), 0, Down)
  } else {
    reduced
  }
}

///|
fn select_cos_sin(
  cosine : @mpf.RawMpf,
  sine : @mpf.RawMpf,
  which : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  if which == 1 {
    (cosine, @mpf.RawMpf::zero())
  } else if which == 2 {
    (sine, @mpf.RawMpf::zero())
  } else if which == 3 {
    (div_checked(sine, cosine, prec, rnd), @mpf.RawMpf::zero())
  } else {
    (cosine, sine)
  }
}

///|
pub fn cos_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 0,
  times_pi? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  if times_pi {
    match exact_cos_sin_pi(x) {
      Some((cosine, sine)) =>
        return select_cos_sin(cosine, sine, which, prec, rnd)
      None => ()
    }
    if !x.is_finite() {
      return select_cos_sin(
        @mpf.RawMpf::nan(),
        @mpf.RawMpf::nan(),
        which,
        prec,
        rnd,
      )
    }
  }
  let wp = work_prec(prec) + 8
  let arg = if times_pi {
    pi(wp, Nearest).mul(reduce_pi_units(x), wp, Nearest)
  } else {
    x.rounded(wp, Nearest)
  }
  let (s, c) = sin_cos_reduced(arg, wp)
  let cos_v = c.rounded(prec, rnd)
  let sin_v = s.rounded(prec, rnd)
  select_cos_sin(cos_v, sin_v, which, prec, rnd)
}

///|
pub fn cos_sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  cos_sin(x, prec, rnd, times_pi=true)
}

///|
pub fn sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let (_, s) = cos_sin(x, prec, rnd, times_pi=true)
  s
}

///|
pub fn cos_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let (c, _) = cos_sin(x, prec, rnd, times_pi=true)
  c
}

///|
pub fn cosh_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  only_tanh? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibElefunError {
  if only_tanh {
    (tanh(x, prec, rnd), @mpf.RawMpf::zero())
  } else {
    (cosh(x, prec, rnd), sinh(x, prec, rnd))
  }
}

///|
pub fn log_hypot(
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  if a.is_nan() || b.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if a.is_zero() && b.is_zero() {
    return @mpf.RawMpf::negative_infinity()
  }
  let wp = work_prec(prec) + 8
  let h = hypot_checked(a, b, wp, Nearest)
  log_positive_checked(h, prec, rnd)
}

///|
pub fn exp_i(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let _ = (x, prec, rnd)
  raise ComplexResult("expj: complex result")
}

///|
pub fn exp_i_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibElefunError {
  let _ = (x, prec, rnd)
  raise ComplexResult("expjpi: complex result")
}
