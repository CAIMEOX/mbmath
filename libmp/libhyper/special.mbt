///|
fn wp(prec : Int) -> Int {
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
fn from_mpf_error(err : @mpf.MpfError) -> LibHyperError {
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
fn from_libelefun_error(err : @libelefun.LibElefunError) -> LibHyperError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    ComplexResult(msg) => ComplexResult(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> LibHyperError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => PoleError(msg)
  }
}

///|
fn euler_constant_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  @gammazeta.euler(prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn div_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
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
) -> @mpf.RawMpf raise LibHyperError {
  x.int_divided_by(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn sqrt_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  x.sqrt(prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn ln_positive_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  @libelefun.ln(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn pow_real_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  @libelefun.pow(x, y, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn pi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  @libelefun.pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn cos_sin_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibHyperError {
  @libelefun.cos_sin(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn exp_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  @libelefun.exp(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
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
pub fn agm(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() || y.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.sign == 1 || y.sign == 1 {
    raise ComplexResult("agm of a negative number")
  }
  if x.is_zero() || y.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let p = if prec > 0 { prec + 12 } else { 64 }
  let mut a = x.rounded(p, Nearest)
  let mut b = y.rounded(p, Nearest)
  for _ in 0..<64 {
    let next_a = a.add(b, p, Nearest).scale_pow2(-1)
    let next_b = sqrt_checked(a.mul(b, p, Nearest), p, Nearest)
    let diff = next_a.sub(next_b, p, Nearest).abs(p, Nearest)
    a = next_a
    b = next_b
    if diff.is_zero() {
      break
    }
    if diff.is_finite() && diff.exp + diff.bc <= -p {
      break
    }
  }
  a.rounded(prec, rnd)
}

///|
pub fn ci_si_taylor(
  x : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> @mpf.RawMpf raise LibHyperError {
  let p = if wp > 0 { wp } else { 32 }
  let x2 = x.mul(x, p, Nearest).negated(p, Nearest)
  let mut sum = if which == 0 {
    @mpf.RawMpf::zero()
  } else {
    x.rounded(p, Nearest)
  }
  let mut term = if which == 0 {
    @mpf.RawMpf::one()
  } else {
    x.rounded(p, Nearest)
  }
  let mut k = if which == 0 { 2 } else { 3 }
  let max_terms = if p <= 128 { 256 } else if p <= 512 { 1024 } else { p * 3 }
  while k < max_terms {
    let den = k * (k - 1)
    term = div_checked(
      term.mul(x2, p, Nearest),
      @mpf.RawMpf::from_int(den),
      p,
      Nearest,
    )
    let add = div_checked(term, @mpf.RawMpf::from_int(k), p, Nearest)
    sum = sum.add(add, p, Nearest)
    if tiny_enough(add.abs(p, Nearest), p + 8) && k > 7 {
      break
    }
    k += 2
  }
  sum
}

///|
pub fn ci_si(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 2,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise LibHyperError {
  let p0 = wp(prec) + 20
  let mut ci = @mpf.RawMpf::zero()
  let mut si = @mpf.RawMpf::zero()
  if x.is_nan() {
    return (@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if x.is_zero() {
    return (@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero())
  }
  if x.is_infinite() {
    if which != 0 {
      let half_pi = pi_checked(p0, Nearest).scale_pow2(-1)
      si = if x.sign == 1 {
        half_pi.negated(prec, rnd)
      } else {
        half_pi.rounded(prec, rnd)
      }
    }
    return (ci, si)
  }
  let mag = x.exp + x.bc
  let x_abs = x.abs(p0, Nearest)
  if mag < -p0 {
    if which != 0 {
      si = x.rounded(prec, rnd)
    }
    if which != 1 {
      ci = euler_constant_checked(p0, Nearest)
        .add(ln_positive_checked(x_abs, p0, Nearest), p0, Nearest)
        .rounded(prec, rnd)
    }
    return (ci, si)
  }
  let p = p0 + (if mag > 0 { mag } else { -mag })
  let asymptotic = mag - 1 > int_bit_length(p)
  if !asymptotic {
    if which != 0 {
      si = ci_si_taylor(x, p, which=1).rounded(prec, rnd)
    }
    if which != 1 {
      let core = ci_si_taylor(x_abs, p, which=0)
      ci = core
        .add(euler_constant_checked(p, Nearest), p, Nearest)
        .add(ln_positive_checked(x_abs, p, Nearest), p, Nearest)
        .rounded(prec, rnd)
    }
    return (ci, si)
  }
  let inv_x = div_checked(@mpf.RawMpf::one(), x_abs, p, Nearest)
  let inv_x2 = inv_x.mul(inv_x, p, Nearest)
  let mut f_term = inv_x
  let mut f_sum = f_term
  let mut g_term = inv_x2
  let mut g_sum = g_term
  let mut m = 0
  let max_terms = if p <= 256 { 256 } else if p <= 1024 { 1024 } else { p * 2 }
  while m < max_terms {
    let a = 2 * m + 2
    f_term = f_term.mul_int(-(a * (a - 1)), p, Nearest).mul(inv_x2, p, Nearest)
    g_term = g_term.mul_int(-((a + 1) * a), p, Nearest).mul(inv_x2, p, Nearest)
    f_sum = f_sum.add(f_term, p, Nearest)
    g_sum = g_sum.add(g_term, p, Nearest)
    if tiny_enough(f_term.abs(p, Nearest), p + 8) &&
      tiny_enough(g_term.abs(p, Nearest), p + 8) &&
      m > 3 {
      break
    }
    m += 1
  }
  let (cos_x, sin_x) = cos_sin_checked(x_abs, p, Nearest)
  if which != 1 {
    ci = sin_x
      .mul(f_sum, p, Nearest)
      .sub(cos_x.mul(g_sum, p, Nearest), p, Nearest)
      .rounded(prec, rnd)
  }
  if which != 0 {
    let mut si_abs = pi_checked(p, Nearest)
      .scale_pow2(-1)
      .sub(
        cos_x
        .mul(f_sum, p, Nearest)
        .add(sin_x.mul(g_sum, p, Nearest), p, Nearest),
        p,
        Nearest,
      )
    if x.sign == 1 {
      si_abs = si_abs.negated(p, Nearest)
    }
    si = si_abs.rounded(prec, rnd)
  }
  (ci, si)
}

///|
pub fn ci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.sign == 1 {
    raise ComplexResult("")
  }
  if x.is_zero() {
    return @mpf.RawMpf::negative_infinity()
  }
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  let (ci, _) = ci_si(x, prec, rnd, which=0)
  ci
}

///|
pub fn si(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  let (_, si) = ci_si(x, prec, rnd, which=1)
  si
}

///|
pub fn ei(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
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
    return @mpf.RawMpf::negative_infinity()
  }
  let p = wp(prec) + 8
  let abs_x = x.abs(p, Nearest)
  let mut sum = euler_constant_checked(p, Nearest).add(
    ln_positive_checked(abs_x, p, Nearest),
    p,
    Nearest,
  )
  let mut term = x.rounded(p, Nearest)
  sum = sum.add(term, p, Nearest)
  let mut k = 1
  while k < 60000 {
    if tiny_enough(term.abs(p, Nearest), p + 10) && k > 3 {
      break
    }
    let kp1 = k + 1
    term = term.mul(x, p, Nearest)
    term = term.mul_int(k, p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(kp1), p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(kp1), p, Nearest)
    sum = sum.add(term, p, Nearest)
    k += 1
  }
  sum.rounded(prec, rnd)
}

///|
pub fn ellipk(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if m.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if m == @mpf.RawMpf::one() {
    return @mpf.RawMpf::infinity()
  }
  if m > @mpf.RawMpf::one() {
    raise ComplexResult("square root of a negative number")
  }
  let p = wp(prec)
  let t = @mpf.RawMpf::one().sub(m, p, Nearest)
  let root = sqrt_checked(t, p, Nearest)
  let agm = agm(@mpf.RawMpf::one(), root, p, Nearest)
  let half_pi = pi_checked(p, Nearest).scale_pow2(-1)
  div_checked(half_pi, agm, p, Nearest).rounded(prec, rnd)
}

///|
pub fn ellipe(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if m.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if m == @mpf.RawMpf::one() {
    return @mpf.RawMpf::one()
  }
  if m > @mpf.RawMpf::one() {
    raise ComplexResult("square root of a negative number")
  }
  let p = wp(prec) + 16
  let half_pi = pi_checked(p, Nearest).scale_pow2(-1)
  let mut a = @mpf.RawMpf::one()
  let mut b = sqrt_checked(@mpf.RawMpf::one().sub(m, p, Nearest), p, Nearest)
  let mut sum = m.rounded(p, Nearest).scale_pow2(-1)
  let mut factor = @mpf.RawMpf::from_int(1)
  for _ in 0..<80 {
    let c = a.sub(b, p, Nearest).scale_pow2(-1)
    let c2 = c.mul(c, p, Nearest)
    sum = sum.add(factor.mul(c2, p, Nearest), p, Nearest)
    let next_a = a.add(b, p, Nearest).scale_pow2(-1)
    let next_b = sqrt_checked(a.mul(b, p, Nearest), p, Nearest)
    a = next_a
    b = next_b
    factor = factor.mul_int(2, p, Nearest)
    if tiny_enough(c2.abs(p, Nearest), p + 10) {
      break
    }
  }
  let k = div_checked(half_pi, a, p, Nearest)
  let e = k.mul(@mpf.RawMpf::one().sub(sum, p, Nearest), p, Nearest)
  e.rounded(prec, rnd)
}

///|
pub fn agm_with_one(
  a : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  agm(@mpf.RawMpf::one(), a, prec, rnd)
}

///|
pub fn e1(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_zero() {
    return @mpf.RawMpf::infinity()
  }
  if x.sign == 1 {
    raise ComplexResult("E1(x) for x < 0")
  }
  ei(x.negated(wp(prec) + 8, Nearest), wp(prec) + 8, Nearest)
  .negated(wp(prec) + 8, Nearest)
  .rounded(prec, rnd)
}

///|
fn erf_series_positive(
  x : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise LibHyperError {
  let x2 = x.mul(x, p, Nearest)
  let mut term = x.rounded(p, Nearest)
  let mut sum = term
  let mut converged = false
  let max_terms = 2 * p + 64
  for k in 0..<max_terms {
    term = term.mul(x2, p, Nearest).mul_int(-(2 * k + 1), p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(k + 1), p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(2 * k + 3), p, Nearest)
    sum = sum.add(term, p, Nearest)
    if k > 3 && tiny_enough(term.abs(p, Nearest), p + 16) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError("error function power series did not converge")
  }
  let scale = div_checked(
    @mpf.RawMpf::two(),
    sqrt_checked(pi_checked(p, Nearest), p, Nearest),
    p,
    Nearest,
  )
  scale.mul(sum, p, Nearest)
}

///|
fn erfc_positive_continued_fraction(
  x : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise LibHyperError {
  let x2 = x.mul(x, p, Nearest)
  let tiny = @mpf.RawMpf::one().scale_pow2(-(4 * p + 64))
  let mut b = x2.add(@mpf.RawMpf::half(), p, Nearest)
  let mut c = div_checked(@mpf.RawMpf::one(), tiny, p, Nearest)
  let mut d = div_checked(@mpf.RawMpf::one(), b, p, Nearest)
  let mut fraction = d
  let mut converged = false
  let max_terms = 4 * p + 128
  for k in 1..<=max_terms {
    let k_mpf = @mpf.RawMpf::from_int(k)
    let k_minus_half = @mpf.RawMpf::from_int(2 * k - 1).scale_pow2(-1)
    let coefficient = k_mpf.mul(k_minus_half, p, Nearest).negated(p, Nearest)
    b = b.add(@mpf.RawMpf::two(), p, Nearest)
    d = b.add(coefficient.mul(d, p, Nearest), p, Nearest)
    if d.abs(p, Nearest) < tiny {
      d = tiny
    }
    c = b.add(div_checked(coefficient, c, p, Nearest), p, Nearest)
    if c.abs(p, Nearest) < tiny {
      c = tiny
    }
    d = div_checked(@mpf.RawMpf::one(), d, p, Nearest)
    let delta = c.mul(d, p, Nearest)
    fraction = fraction.mul(delta, p, Nearest)
    if k > 3 &&
      tiny_enough(
        delta.sub(@mpf.RawMpf::one(), p, Nearest).abs(p, Nearest),
        p + 16,
      ) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError(
      "complementary error continued fraction did not converge",
    )
  }
  let gaussian = exp_checked(x2.negated(p, Nearest), p, Nearest)
  let sqrt_pi = sqrt_checked(pi_checked(p, Nearest), p, Nearest)
  div_checked(gaussian.mul(x, p, Nearest), sqrt_pi, p, Nearest).mul(
    fraction,
    p,
    Nearest,
  )
}

///|
fn erfc_positive(x : @mpf.RawMpf, p : Int) -> @mpf.RawMpf raise LibHyperError {
  if x < @mpf.RawMpf::two() {
    @mpf.RawMpf::one().sub(erf_series_positive(x, p), p, Nearest)
  } else {
    erfc_positive_continued_fraction(x, p)
  }
}

///|
/// Evaluate the real Gaussian error function at arbitrary precision.
pub fn erf(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return if x.sign == 1 {
      @mpf.RawMpf::negative_one()
    } else {
      @mpf.RawMpf::one()
    }
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let p = wp(prec) + 32
  let magnitude = x.abs(p, Nearest)
  let mut value = if magnitude < @mpf.RawMpf::two() {
    erf_series_positive(magnitude, p)
  } else {
    @mpf.RawMpf::one().sub(erfc_positive(magnitude, p), p, Nearest)
  }
  if x.sign == 1 {
    value = value.negated(p, Nearest)
  }
  value.rounded(prec, rnd)
}

///|
/// Evaluate the real complementary error function without subtractive loss in
/// the exponentially small positive tail.
pub fn erfc(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return if x.sign == 1 { @mpf.RawMpf::two() } else { @mpf.RawMpf::zero() }
  }
  if x.is_zero() {
    return @mpf.RawMpf::one()
  }
  let p = wp(prec) + 32
  let magnitude = x.abs(p, Nearest)
  let tail = erfc_positive(magnitude, p)
  let value = if x.sign == 1 {
    @mpf.RawMpf::two().sub(tail, p, Nearest)
  } else {
    tail
  }
  value.rounded(prec, rnd)
}

///|
/// Evaluate the real imaginary error function `-i erf(i x)`.
pub fn erfi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return if x.sign == 1 {
      @mpf.RawMpf::negative_infinity()
    } else {
      @mpf.RawMpf::infinity()
    }
  }
  if x.is_zero() {
    return @mpf.RawMpf::zero()
  }
  let base_p = wp(prec) + 32
  let magnitude = x.abs(base_p, Nearest)
  let square = magnitude.mul(magnitude, base_p, Nearest)
  let mut value = @mpf.RawMpf::zero()
  if square > @mpf.RawMpf::from_int(base_p) {
    let p = base_p + 32
    let inverse_square = div_checked(@mpf.RawMpf::one(), square, p, Nearest)
    let mut term = @mpf.RawMpf::one()
    let mut sum = term
    let mut previous = @mpf.RawMpf::infinity()
    let mut converged = false
    let max_terms = 2 * p + 64
    for k in 1..<=max_terms {
      term = term
        .mul_int(2 * k - 1, p, Nearest)
        .mul(inverse_square, p, Nearest)
        .scale_pow2(-1)
      let term_abs = term.abs(p, Nearest)
      if k > 3 && term_abs >= previous {
        break
      }
      sum = sum.add(term, p, Nearest)
      let relative_bound = sum.abs(p, Nearest).scale_pow2(-(p + 16))
      if k > 3 && term_abs <= relative_bound {
        converged = true
        break
      }
      previous = term_abs
    }
    if !converged {
      raise ConvergenceError(
        "imaginary error asymptotic series did not converge",
      )
    }
    let gaussian = exp_checked(square, p, Nearest)
    let denominator = sqrt_checked(pi_checked(p, Nearest), p, Nearest).mul(
      magnitude,
      p,
      Nearest,
    )
    value = div_checked(gaussian, denominator, p, Nearest).mul(sum, p, Nearest)
  } else {
    let p = 2 * base_p + 64
    let x2 = magnitude.mul(magnitude, p, Nearest)
    let mut term = magnitude.rounded(p, Nearest)
    let mut sum = term
    let mut converged = false
    let max_terms = 4 * p + 128
    for k in 0..<max_terms {
      term = term.mul(x2, p, Nearest).mul_int(2 * k + 1, p, Nearest)
      term = div_checked(term, @mpf.RawMpf::from_int(k + 1), p, Nearest)
      term = div_checked(term, @mpf.RawMpf::from_int(2 * k + 3), p, Nearest)
      sum = sum.add(term, p, Nearest)
      let relative_bound = sum.abs(p, Nearest).scale_pow2(-(p + 16))
      if k > 3 && term.abs(p, Nearest) <= relative_bound {
        converged = true
        break
      }
    }
    if !converged {
      raise ConvergenceError("imaginary error power series did not converge")
    }
    let scale = div_checked(
      @mpf.RawMpf::two(),
      sqrt_checked(pi_checked(p, Nearest), p, Nearest),
      p,
      Nearest,
    )
    value = scale.mul(sum, p, Nearest)
  }
  if x.sign == 1 {
    value = value.negated(base_p, Nearest)
  }
  value.rounded(prec, rnd)
}

///|
fn factorial_mpf(n : Int, p : Int) -> @mpf.RawMpf {
  let mut acc = @mpf.RawMpf::one()
  if n <= 1 {
    return acc
  }
  for i in 2..<=n {
    acc = acc.mul_int(i, p, Nearest)
  }
  acc
}

///|
pub fn exponential_integral(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  gamma? : Bool = false,
) -> @mpf.RawMpf raise LibHyperError {
  if n <= 0 {
    raise ValueError("exponential_integral: n must be positive")
  }
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if gamma {
    let p = wp(prec) + 16
    if x.is_zero() {
      return factorial_mpf(n - 1, p)
    }
    if x.is_infinite() {
      return if x.sign == 0 { @mpf.RawMpf::zero() } else { @mpf.RawMpf::nan() }
    }
    let ex = exp_checked(x.negated(p, Nearest), p, Nearest)
    let mut sum = @mpf.RawMpf::one()
    let mut term = @mpf.RawMpf::one()
    for k in 1..<n {
      term = term.mul(x, p, Nearest)
      term = div_checked(term, @mpf.RawMpf::from_int(k), p, Nearest)
      sum = sum.add(term, p, Nearest)
    }
    return factorial_mpf(n - 1, p)
      .mul(ex.mul(sum, p, Nearest), p, Nearest)
      .rounded(prec, rnd)
  }
  if x.is_infinite() {
    return if x.sign == 0 { @mpf.RawMpf::zero() } else { @mpf.RawMpf::nan() }
  }
  if x.is_zero() {
    if n == 1 {
      return @mpf.RawMpf::infinity()
    }
    return rdiv_int_checked(1, @mpf.RawMpf::from_int(n - 1), prec, rnd)
  }
  let p = wp(prec) + 16
  let mut en = if x.sign == 1 {
    ei(x.negated(p, Nearest), p, Nearest).negated(p, Nearest)
  } else {
    e1(x, p, Nearest)
  }
  if n == 1 {
    return en.rounded(prec, rnd)
  }
  let ex = exp_checked(x.negated(p, Nearest), p, Nearest)
  let mut k = 1
  while k < n {
    en = div_checked(
      ex.sub(x.mul(en, p, Nearest), p, Nearest),
      @mpf.RawMpf::from_int(k),
      p,
      Nearest,
    )
    k += 1
  }
  en.rounded(prec, rnd)
}

///|
pub fn bessel_j(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    return @mpf.RawMpf::zero()
  }
  let p = wp(prec) + 24
  let mut m = n
  let mut sign = 0
  if m < 0 {
    m = -m
    if (m & 1) == 1 {
      sign = 1
    }
  }
  let half_x = x.scale_pow2(-1)
  let x2_over4 = half_x.mul(half_x, p, Nearest)
  let mut term = pow_real_checked(
    half_x.abs(p, Nearest),
    @mpf.RawMpf::from_int(m),
    p,
    Nearest,
  )
  term = div_checked(term, factorial_mpf(m, p), p, Nearest)
  let mut sum = term
  let mut k = 0
  while k < 20000 {
    term = term.mul(x2_over4, p, Nearest)
    term = term.mul_int(-1, p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(k + 1), p, Nearest)
    term = div_checked(term, @mpf.RawMpf::from_int(k + m + 1), p, Nearest)
    sum = sum.add(term, p, Nearest)
    if tiny_enough(term.abs(p, Nearest), p + 12) && k > 4 {
      break
    }
    k += 1
  }
  if x.sign == 1 && (m & 1) == 1 {
    sign = 1 - sign
  }
  if sign == 1 {
    sum.negated(prec, rnd)
  } else {
    sum.rounded(prec, rnd)
  }
}
