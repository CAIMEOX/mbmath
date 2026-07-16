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
fn from_mpf_error(err : @mpf.MpfError) -> GammaZetaError {
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
fn from_libelefun_error(err : @libelefun.LibElefunError) -> GammaZetaError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    ComplexResult(msg) => DomainError(msg)
  }
}

///|
fn mpf_from_str_checked(
  s : StringView,
  prec~ : Int,
  rnd~ : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @mpf.RawMpf::parse(s, prec~, rnd~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_div_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  x.div(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_pow_int_checked(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  x.pow_int(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_sqrt_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  x.sqrt(prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_log_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.log(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_pow_checked(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.pow(x, y, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_pi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_exp_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.exp(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_ln_sqrt_2pi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.ln_sqrt_2pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_sin_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.sin(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_cos_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.cos(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_cos_sin_pi_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise GammaZetaError {
  @libelefun.cos_sin_pi(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn mpf_phi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.phi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
pub fn large_bernoulli(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise ValueError("bernoulli_huge: n must be non-negative")
  }
  if n == 0 {
    return @mpf.RawMpf::one()
  }
  if n == 1 {
    return @mpf.RawMpf::from_mantissa_exponent(-1N, -1, prec, rnd)
  }
  if (n & 1) == 1 {
    return @mpf.RawMpf::zero()
  }
  let p = wp(prec) + 10
  let piprec = p + int_bit_length(n)
  let mut v = gamma_integer(n + 1, p, Nearest)
  v = v.mul(zeta_large_integer_em(n, p), p, Nearest)
  v = v.mul(
    mpf_pow_int_checked(mpf_pi_checked(piprec, Nearest), -n, p, Nearest),
    p,
    Nearest,
  )
  v = v.scale_pow2(1 - n)
  if (n & 3) == 0 {
    v = v.negated(p, Nearest)
  }
  v.rounded(prec, rnd)
}

///|
pub fn factorial(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise ValueError("factorial: n must be non-negative")
  }
  if n <= 1 {
    return @mpf.RawMpf::one()
  }
  let mut acc = @mpf.RawMpf::one()
  for i in 2..<=n {
    acc = acc.mul_int(i, 0, Down)
  }
  acc.rounded(prec, rnd)
}

///|
pub fn bernoulli(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise ValueError("bernoulli: n must be non-negative")
  }
  if n == 1 {
    return @mpf.RawMpf::from_mantissa_exponent(-1N, -1, prec, rnd)
  }
  if n > 1 && (n & 1) == 1 {
    return @mpf.RawMpf::zero()
  }
  if n >= 80 {
    return large_bernoulli(n, prec, rnd)
  }
  let p = wp(prec) + 4 * n + 20
  let a = Array::make(n + 1, @mpf.RawMpf::zero())
  for m in 0..<=n {
    a[m] = mpf_div_checked(
      @mpf.RawMpf::one(),
      @mpf.RawMpf::from_int(m + 1),
      p,
      Nearest,
    )
    let mut j = m
    while j > 0 {
      a[j - 1] = a[j - 1].sub(a[j], p, Nearest).mul_int(j, p, Nearest)
      j -= 1
    }
  }
  a[0].rounded(prec, rnd)
}

///|
fn zeta_even_via_bernoulli(
  n : Int,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let k = n / 2
  let b = bernoulli(n, p, Nearest)
  let two_pi = mpf_pi_checked(p, Nearest).mul_int(2, p, Nearest)
  let numer = b.mul(mpf_pow_int_checked(two_pi, n, p, Nearest), p, Nearest)
  let denom = factorial(n, p, Nearest).mul_int(2, p, Nearest)
  let mut z = mpf_div_checked(numer, denom, p, Nearest)
  if (k & 1) == 0 {
    z = z.negated(p, Nearest)
  }
  z
}

///|
fn bernoulli_even_table(
  max_index : Int,
  p : Int,
) -> Array[@mpf.RawMpf] raise GammaZetaError {
  let work = Array::make(max_index + 1, @mpf.RawMpf::zero())
  let values = Array::make(max_index + 1, @mpf.RawMpf::zero())
  for m in 0..<=max_index {
    work[m] = mpf_div_checked(
      @mpf.RawMpf::one(),
      @mpf.RawMpf::from_int(m + 1),
      p,
      Nearest,
    )
    let mut j = m
    while j > 0 {
      work[j - 1] = work[j - 1].sub(work[j], p, Nearest).mul_int(j, p, Nearest)
      j -= 1
    }
    if (m & 1) == 0 {
      values[m] = work[0]
    }
  }
  values
}

///|
fn zeta_large_integer_em(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  let correction_count = p / 32 + 8
  let max_bernoulli = 2 * correction_count
  let work_p = p + 4 * max_bernoulli + 32
  let effective_order = n + max_bernoulli - 1
  let sample_shift = (work_p + effective_order - 1) / effective_order + 2
  let sample_count = 1 << sample_shift
  let sample = @mpf.RawMpf::from_int(sample_count)
  let bernoulli_values = bernoulli_even_table(max_bernoulli, work_p)
  let mut sum = @mpf.RawMpf::zero()
  for k in 1..<sample_count {
    sum = sum.add(
      mpf_div_checked(
        @mpf.RawMpf::one(),
        mpf_pow_int_checked(@mpf.RawMpf::from_int(k), n, work_p, Nearest),
        work_p,
        Nearest,
      ),
      work_p,
      Nearest,
    )
  }
  let inverse_sample = mpf_div_checked(
    @mpf.RawMpf::one(),
    sample,
    work_p,
    Nearest,
  )
  let inverse_sample_squared = inverse_sample.mul(
    inverse_sample,
    work_p,
    Nearest,
  )
  let sample_to_minus_n = mpf_pow_int_checked(sample, -n, work_p, Nearest)
  let integral_tail = mpf_div_checked(
    sample.mul(sample_to_minus_n, work_p, Nearest),
    @mpf.RawMpf::from_int(n - 1),
    work_p,
    Nearest,
  )
  let mut value = sum
    .add(integral_tail, work_p, Nearest)
    .add(sample_to_minus_n.scale_pow2(-1), work_p, Nearest)
  let mut poch = @mpf.RawMpf::from_int(n)
  let mut sample_power = sample_to_minus_n.mul(inverse_sample, work_p, Nearest)
  let mut factorial_value = @mpf.RawMpf::two()
  let mut converged = false
  for m in 1..<=correction_count {
    let two_m = 2 * m
    let coefficient = mpf_div_checked(
      bernoulli_values[two_m],
      factorial_value,
      work_p,
      Nearest,
    )
    let correction = coefficient.mul(
      poch.mul(sample_power, work_p, Nearest),
      work_p,
      Nearest,
    )
    value = value.add(correction, work_p, Nearest)
    if m > 3 && tiny_enough(correction.abs(work_p, Nearest), p + 24) {
      converged = true
      break
    }
    poch = poch
      .mul_int(n + two_m - 1, work_p, Nearest)
      .mul_int(n + two_m, work_p, Nearest)
    sample_power = sample_power.mul(inverse_sample_squared, work_p, Nearest)
    factorial_value = factorial_value
      .mul_int(two_m + 1, 0, Down)
      .mul_int(two_m + 2, 0, Down)
  }
  if !converged {
    raise ConvergenceError(
      "large-integer zeta Euler-Maclaurin did not converge",
    )
  }
  value.rounded(p, Nearest)
}

///|
pub fn zeta_integer(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 1 {
    raise ValueError("zeta_int: n must be > 1")
  }
  let p = wp(prec) + 16
  let z = if (n & 1) == 0 {
    zeta_even_via_bernoulli(n, p)
  } else {
    zeta_euler_maclaurin_real(@mpf.RawMpf::from_int(n), p)
  }
  z.rounded(prec, rnd)
}

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !x.is_finite() {
    return None
  }
  if x.is_zero() {
    return Some(0)
  }
  if x.exp >= 0 {
    let v = x.man << x.exp
    if v.bit_length() > 60 {
      return None
    }
    let n = v.to_int()
    if x == @mpf.RawMpf::from_int(if x.sign == 1 { -n } else { n }) {
      return Some(if x.sign == 1 { -n } else { n })
    }
    None
  } else {
    None
  }
}

///|
fn loggamma_stirling_positive(
  x : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let target = {
    let value = p / 3 + 12
    if value < 32 {
      32
    } else {
      value
    }
  }
  let mut y = x.rounded(p, Nearest)
  let mut recurrence = @mpf.RawMpf::zero()
  while y < @mpf.RawMpf::from_int(target) {
    recurrence = recurrence.add(mpf_log_checked(y, p, Nearest), p, Nearest)
    y = y.add(@mpf.RawMpf::one(), p, Nearest)
  }
  let log_y = mpf_log_checked(y, p, Nearest)
  let half = @mpf.RawMpf::half()
  let mut value = y
    .sub(half, p, Nearest)
    .mul(log_y, p, Nearest)
    .sub(y, p, Nearest)
    .add(mpf_ln_sqrt_2pi_checked(p, Nearest), p, Nearest)
  let inv = mpf_div_checked(@mpf.RawMpf::one(), y, p, Nearest)
  let inv2 = inv.mul(inv, p, Nearest)
  let mut inv_power = inv
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 16
  for k in 1..<=max_terms {
    let two_k = 2 * k
    let denominator = @mpf.RawMpf::from_int(two_k * (two_k - 1))
    let term = mpf_div_checked(
      bernoulli(two_k, p, Nearest).mul(inv_power, p, Nearest),
      denominator,
      p,
      Nearest,
    )
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    value = value.add(term, p, Nearest)
    if k > 3 && tiny_enough(magnitude, p + 12) {
      break
    }
    previous = magnitude
    inv_power = inv_power.mul(inv2, p, Nearest)
  }
  value.sub(recurrence, p, Nearest)
}

///|
fn gamma_positive(x : @mpf.RawMpf, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  mpf_exp_checked(loggamma_stirling_positive(x, p), p, Nearest)
}

///|
pub fn gamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::nan()
    } else {
      return @mpf.RawMpf::infinity()
    }
  }
  match maybe_integer(x) {
    Some(n) => {
      if n <= 0 {
        raise PoleError("gamma: pole at non-positive integer")
      }
      return factorial(n - 1, prec, rnd)
    }
    None => ()
  }
  let p = wp(prec)
  let half = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
  if x == half {
    return mpf_sqrt_checked(mpf_pi_checked(p, Nearest), prec, rnd)
  }
  if x == half.negated(0, Down) {
    let root_pi = mpf_sqrt_checked(mpf_pi_checked(p, Nearest), p, Nearest)
    return root_pi.negated(p, Nearest).mul_int(2, prec, rnd)
  }
  if x.sign == 1 {
    let pi = mpf_pi_checked(p, Nearest)
    let (_, sin_term) = mpf_cos_sin_pi_checked(x, p, Nearest)
    if sin_term.is_zero() {
      raise PoleError("gamma: pole at non-positive integer")
    }
    let gamma_term = gamma(@mpf.RawMpf::one().sub(x, p, Nearest), p, Nearest)
    return mpf_div_checked(pi, sin_term.mul(gamma_term, p, Nearest), p, Nearest).rounded(
      prec, rnd,
    )
  }
  gamma_positive(x, p).rounded(prec, rnd)
}

///|
pub fn rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  match maybe_integer(x) {
    Some(n) => if n <= 0 { return @mpf.RawMpf::zero() }
    None => ()
  }
  let p = wp(prec) + 8
  let g = gamma(x, p, Nearest)
  mpf_div_checked(@mpf.RawMpf::one(), g, p, Nearest).rounded(prec, rnd)
}

///|
pub fn loggamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      raise DomainError("loggamma: negative infinity has a complex value")
    }
    return @mpf.RawMpf::infinity()
  }
  if x.is_zero() {
    raise PoleError("loggamma: pole at zero")
  }
  if x == @mpf.RawMpf::one() || x == @mpf.RawMpf::two() {
    return @mpf.RawMpf::zero()
  }
  if x.sign == 1 {
    raise DomainError("loggamma: negative input has a complex value")
  }
  let p = wp(prec) + 8
  loggamma_stirling_positive(x, p).rounded(prec, rnd)
}

///|
pub fn gamma_integer(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 0 {
    raise ValueError("gamma_int: n must be positive")
  }
  factorial(n - 1, prec, rnd)
}

///|
fn harmonic_int(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 0 {
    return @mpf.RawMpf::zero()
  }
  let mut sum = @mpf.RawMpf::zero()
  for k in 1..<=n {
    sum = sum.add(
      mpf_div_checked(@mpf.RawMpf::one(), @mpf.RawMpf::from_int(k), p, Nearest),
      p,
      Nearest,
    )
  }
  sum
}

///|
pub fn digamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::nan()
    }
    return @mpf.RawMpf::infinity()
  }
  match maybe_integer(x) {
    Some(n) => {
      if n <= 0 {
        raise PoleError("digamma: poles at non-positive integers")
      }
      let p = wp(prec) + 8
      return harmonic_int(n - 1, p)
        .sub(euler(p, Nearest), p, Nearest)
        .rounded(prec, rnd)
    }
    None => ()
  }
  if x.is_zero() {
    raise DomainError("digamma: non-positive input is unsupported")
  }
  if x.sign == 1 {
    let p = wp(prec) + 24
    let one_minus_x = @mpf.RawMpf::one().sub(x, p, Nearest)
    let psi_ref = digamma(one_minus_x, p, Nearest)
    let pi = mpf_pi_checked(p, Nearest)
    let (cos_pix, sin_pix) = mpf_cos_sin_pi_checked(x, p, Nearest)
    let cot_pix = mpf_div_checked(cos_pix, sin_pix, p, Nearest)
    let corr = pi.mul(cot_pix, p, Nearest)
    return psi_ref.sub(corr, p, Nearest).rounded(prec, rnd)
  }
  let p = wp(prec) + 40
  let mut y = x.rounded(p, Nearest)
  let mut acc = @mpf.RawMpf::zero()
  let target = {
    let value = p / 3 + 12
    if value < 32 {
      32
    } else {
      value
    }
  }
  while y < @mpf.RawMpf::from_int(target) {
    acc = acc.sub(
      mpf_div_checked(@mpf.RawMpf::one(), y, p, Nearest),
      p,
      Nearest,
    )
    y = y.add(@mpf.RawMpf::one(), p, Nearest)
  }
  let inv = mpf_div_checked(@mpf.RawMpf::one(), y, p, Nearest)
  let inv2 = inv.mul(inv, p, Nearest)
  let mut power = inv2
  let mut series = mpf_log_checked(y, p, Nearest).sub(
    inv.scale_pow2(-1),
    p,
    Nearest,
  )
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 16
  for k in 1..<=max_terms {
    let term = mpf_div_checked(
      bernoulli(2 * k, p, Nearest).mul(power, p, Nearest),
      @mpf.RawMpf::from_int(2 * k),
      p,
      Nearest,
    )
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    series = series.sub(term, p, Nearest)
    if k > 3 && tiny_enough(magnitude, p + 12) {
      break
    }
    previous = magnitude
    power = power.mul(inv2, p, Nearest)
  }
  series.add(acc, p, Nearest).rounded(prec, rnd)
}

///|
pub fn harmonic(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::nan()
    }
    return @mpf.RawMpf::infinity()
  }
  match maybe_integer(x) {
    Some(n) => {
      if n < 0 {
        raise PoleError("harmonic: poles at negative integers")
      }
      let p = wp(prec) + 8
      return harmonic_int(n, p).rounded(prec, rnd)
    }
    None => ()
  }
  let p = wp(prec) + 16
  let psi = digamma(x.add(@mpf.RawMpf::one(), p, Nearest), p, Nearest)
  psi.add(euler(p, Nearest), p, Nearest).rounded(prec, rnd)
}

///|
fn fib_int(n : Int) -> BigInt {
  if n == 0 {
    return 0N
  }
  let mut abs_n = n
  if abs_n < 0 {
    abs_n = -abs_n
  }
  let mut a = 0N
  let mut b = 1N
  for _ in 0..<abs_n {
    let next = a + b
    a = b
    b = next
  }
  let mut f = a
  if n < 0 && (abs_n & 1) == 0 {
    f = -f
  }
  f
}

///|
pub fn fibonacci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if x.is_nan() || x.is_infinite() {
    return @mpf.RawMpf::nan()
  }
  match maybe_integer(x) {
    Some(n) => @mpf.RawMpf::from_mantissa_exponent(fib_int(n), 0, prec, rnd)
    None => {
      let p = wp(prec) + 24
      let phi = mpf_phi_checked(p, Nearest)
      let sqrt5 = mpf_sqrt_checked(@mpf.RawMpf::from_int(5), p, Nearest)
      let phix = mpf_pow_checked(phi, x, p, Nearest)
      let phimx = mpf_pow_checked(phi, x.negated(p, Nearest), p, Nearest)
      let cospix = mpf_cos_checked(
        mpf_pi_checked(p, Nearest).mul(x, p, Nearest),
        p,
        Nearest,
      )
      let numer = phix.sub(cospix.mul(phimx, p, Nearest), p, Nearest)
      mpf_div_checked(numer, sqrt5, p, Nearest).rounded(prec, rnd)
    }
  }
}

///|
fn zeta_eta_real(s : @mpf.RawMpf, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  let target_bits = p + 20
  let term_count = target_bits + 48
  let work_p = p + term_count + 32
  let differences : Array[@mpf.RawMpf] = []
  for k in 0..<=term_count {
    differences.push(
      mpf_div_checked(
        @mpf.RawMpf::one(),
        mpf_pow_checked(@mpf.RawMpf::from_int(k + 1), s, work_p, Nearest),
        work_p,
        Nearest,
      ),
    )
  }
  let mut eta = @mpf.RawMpf::zero()
  let mut weight_exponent = -1
  let mut active = differences.length()
  let mut converged = false
  for order in 0..<=term_count {
    let term = differences[0].scale_pow2(weight_exponent)
    eta = eta.add(term, work_p, Nearest)
    if order > 8 && tiny_enough(term.abs(work_p, Nearest), target_bits) {
      converged = true
      break
    }
    for k in 0..<(active - 1) {
      differences[k] = differences[k].sub(differences[k + 1], work_p, Nearest)
    }
    active -= 1
    weight_exponent -= 1
  }
  if !converged {
    raise ConvergenceError("Euler-transformed eta series did not converge")
  }
  eta.rounded(p, Nearest)
}

///|
fn zeta_euler_maclaurin_real(
  s : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let pole_dist = s.sub(@mpf.RawMpf::one(), p, Nearest).abs(p, Nearest)
  let pole_bits = if pole_dist.is_zero() {
    p + 16
  } else {
    let bits = -(pole_dist.exp + pole_dist.bc)
    if bits > 0 {
      bits
    } else {
      0
    }
  }
  let top = s.exp + s.bc
  let mut n = 12 + p / 4 + pole_bits * 2 + 2 * (if top > 0 { top } else { 0 })
  if n < 12 {
    n = 12
  }
  let mut terms = 24 + p / 6 + pole_bits / 2
  if terms < 6 {
    terms = 6
  }
  let n_mpf = @mpf.RawMpf::from_int(n)
  let mut sum = @mpf.RawMpf::zero()
  for k in 1..<n {
    sum = sum.add(
      mpf_div_checked(
        @mpf.RawMpf::one(),
        mpf_pow_checked(@mpf.RawMpf::from_int(k), s, p, Nearest),
        p,
        Nearest,
      ),
      p,
      Nearest,
    )
  }
  let n_pow_s = mpf_pow_checked(n_mpf, s, p, Nearest)
  let n_neg_s = mpf_div_checked(@mpf.RawMpf::one(), n_pow_s, p, Nearest)
  let tail_integral = mpf_div_checked(
    n_mpf.mul(n_neg_s, p, Nearest),
    s.sub(@mpf.RawMpf::one(), p, Nearest),
    p,
    Nearest,
  )
  let tail_half = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down).mul(
    n_neg_s,
    p,
    Nearest,
  )
  let inverse_n = mpf_div_checked(@mpf.RawMpf::one(), n_mpf, p, Nearest)
  let inverse_n_squared = inverse_n.mul(inverse_n, p, Nearest)
  let mut poch = s
  let mut n_power = n_neg_s.mul(inverse_n, p, Nearest)
  let mut factorial_value = @mpf.RawMpf::two()
  let mut corr = @mpf.RawMpf::zero()
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  for m in 1..<=terms {
    let two_m = 2 * m
    let coeff = mpf_div_checked(
      bernoulli(two_m, p, Nearest),
      factorial_value,
      p,
      Nearest,
    )
    let corr_term = coeff.mul(poch.mul(n_power, p, Nearest), p, Nearest)
    let magnitude = corr_term.abs(p, Nearest)
    if m > 4 && magnitude >= previous {
      break
    }
    corr = corr.add(corr_term, p, Nearest)
    if m >= 4 && tiny_enough(magnitude, p + 12 + pole_bits) {
      converged = true
      break
    }
    previous = magnitude
    poch = poch
      .mul(s.add(@mpf.RawMpf::from_int(two_m - 1), p, Nearest), p, Nearest)
      .mul(s.add(@mpf.RawMpf::from_int(two_m), p, Nearest), p, Nearest)
    n_power = n_power.mul(inverse_n_squared, p, Nearest)
    factorial_value = factorial_value
      .mul_int(two_m + 1, 0, Down)
      .mul_int(two_m + 2, 0, Down)
  }
  if !converged {
    raise ConvergenceError("zeta Euler-Maclaurin expansion did not converge")
  }
  sum.add(
    tail_integral.add(tail_half.add(corr, p, Nearest), p, Nearest),
    p,
    Nearest,
  )
}

///|
fn zeta_alt_factor(
  s : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  @mpf.RawMpf::one().sub(
    mpf_pow_checked(
      @mpf.RawMpf::from_int(2),
      @mpf.RawMpf::one().sub(s, p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
}

///|
fn zeta_negative_int(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  if (n & 1) == 0 {
    return @mpf.RawMpf::zero()
  }
  let m = -n
  mpf_div_checked(
    bernoulli(m + 1, p, Nearest),
    @mpf.RawMpf::from_int(m + 1),
    p,
    Nearest,
  ).negated(p, Nearest)
}

///|
fn zeta_reflection_real(
  s : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let pi = mpf_pi_checked(p, Nearest)
  let one_minus_s = @mpf.RawMpf::one().sub(s, p, Nearest)
  let two_pow_s = mpf_pow_checked(@mpf.RawMpf::from_int(2), s, p, Nearest)
  let pi_pow = mpf_pow_checked(
    pi,
    s.sub(@mpf.RawMpf::one(), p, Nearest),
    p,
    Nearest,
  )
  let sin_term = mpf_sin_checked(
    pi.mul(s, p, Nearest).scale_pow2(-1),
    p,
    Nearest,
  )
  let gamma_term = gamma(one_minus_s, p, Nearest)
  let zeta_term = zeta(one_minus_s, p, Nearest)
  two_pow_s.mul(
    pi_pow.mul(
      sin_term.mul(gamma_term.mul(zeta_term, p, Nearest), p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
}

///|
pub fn zeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf raise GammaZetaError {
  if s.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if s.is_infinite() {
    if s.sign == 1 {
      return @mpf.RawMpf::nan()
    }
    return @mpf.RawMpf::one()
  }
  if s.is_zero() {
    return if alt {
      @mpf.RawMpf::from_mantissa_exponent(1N, -1, prec, rnd)
    } else {
      @mpf.RawMpf::from_mantissa_exponent(-1N, -1, prec, rnd)
    }
  }
  match maybe_integer(s) {
    Some(n) => {
      if n == 1 {
        if alt {
          let p = wp(prec) + 16
          let ln2 = mpf_log_checked(@mpf.RawMpf::from_int(2), p, Nearest)
          return ln2.rounded(prec, rnd)
        }
        raise PoleError("zeta: pole at s=1")
      }
      if n > 1 {
        let p = wp(prec) + 16
        let z = zeta_integer(n, p, Nearest)
        if alt {
          let factor = zeta_alt_factor(@mpf.RawMpf::from_int(n), p)
          return z.mul(factor, p, Nearest).rounded(prec, rnd)
        }
        return z.rounded(prec, rnd)
      }
      let p = wp(prec) + 24
      let z = zeta_negative_int(n, p)
      if alt {
        return z
          .mul(zeta_alt_factor(@mpf.RawMpf::from_int(n), p), p, Nearest)
          .rounded(prec, rnd)
      }
      return z.rounded(prec, rnd)
    }
    None => ()
  }
  if s.sign == 1 {
    let p = wp(prec) + 28
    let z = zeta_reflection_real(s, p)
    if alt {
      return z.mul(zeta_alt_factor(s, p), p, Nearest).rounded(prec, rnd)
    }
    return z.rounded(prec, rnd)
  }
  let p = wp(prec) + 24
  let pole_dist = s.sub(@mpf.RawMpf::one(), p, Nearest).abs(p, Nearest)
  let pole_bits = if pole_dist.is_zero() {
    p + 16
  } else {
    let bits = -(pole_dist.exp + pole_dist.bc)
    if bits > 0 {
      bits
    } else {
      0
    }
  }
  if alt && pole_bits > 16 {
    return zeta_eta_real(s, p).rounded(prec, rnd)
  }
  let p_work = p + 24 + pole_bits * 2
  let value = zeta_euler_maclaurin_real(s, p_work)
  if alt {
    return value
      .mul(zeta_alt_factor(s, p_work), p_work, Nearest)
      .rounded(prec, rnd)
  }
  value.rounded(prec, rnd)
}

///|
fn const_str(
  v : StringView,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  mpf_from_str_checked(v, prec=if prec > 0 { prec + 8 } else { 64 }, rnd~)
}

///|
pub fn eta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  zeta(s, prec, rnd, alt=true)
}

///|
fn factorial_small_mpf(n : Int, p : Int) -> @mpf.RawMpf {
  if n <= 1 {
    return @mpf.RawMpf::one()
  }
  let mut acc = @mpf.RawMpf::one()
  for i in 2..<=n {
    acc = acc.mul_int(i, p, Nearest)
  }
  acc
}

///|
fn hurwitz_power_sum_em(
  x : @mpf.RawMpf,
  s : Int,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let n = {
    let value = p / 2 + 16
    if value < 32 {
      32
    } else {
      value
    }
  }
  let terms = {
    let value = p / 3 + 12
    if value < 12 {
      12
    } else {
      value
    }
  }
  let mut sum = @mpf.RawMpf::zero()
  for k in 0..<n {
    sum = sum.add(
      mpf_div_checked(
        @mpf.RawMpf::one(),
        mpf_pow_int_checked(
          x.add(@mpf.RawMpf::from_int(k), p, Nearest),
          s,
          p,
          Nearest,
        ),
        p,
        Nearest,
      ),
      p,
      Nearest,
    )
  }
  let xn = x.add(@mpf.RawMpf::from_int(n), p, Nearest)
  let tail_int = mpf_div_checked(
    mpf_pow_int_checked(xn, 1 - s, p, Nearest),
    @mpf.RawMpf::from_int(s - 1),
    p,
    Nearest,
  )
  let tail_half = mpf_div_checked(
    @mpf.RawMpf::one(),
    mpf_pow_int_checked(xn, s, p, Nearest),
    p,
    Nearest,
  ).scale_pow2(-1)
  let mut corr = @mpf.RawMpf::zero()
  for r in 1..<=terms {
    let two_r = 2 * r
    let mut poch = @mpf.RawMpf::one()
    for j in 0..<(two_r - 1) {
      poch = poch.mul_int(s + j, p, Nearest)
    }
    let coeff = mpf_div_checked(
      bernoulli(two_r, p, Nearest),
      factorial(two_r, p, Nearest),
      p,
      Nearest,
    )
    let xpow = mpf_pow_int_checked(xn, -(s + two_r - 1), p, Nearest)
    let term = coeff.mul(poch.mul(xpow, p, Nearest), p, Nearest)
    corr = corr.add(term, p, Nearest)
    if r >= 3 && tiny_enough(term.abs(p, Nearest), p + 8) {
      break
    }
  }
  sum.add(tail_int.add(tail_half.add(corr, p, Nearest), p, Nearest), p, Nearest)
}

///|
pub fn polygamma(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if m < 0 {
    raise ValueError("psi: m must be non-negative")
  }
  if m == 0 {
    return digamma(x, prec, rnd)
  }
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      return @mpf.RawMpf::nan()
    }
    return @mpf.RawMpf::zero()
  }
  if x.is_zero() {
    raise PoleError("psi: poles at non-positive integers")
  }
  match maybe_integer(x) {
    Some(n) =>
      if n <= 0 {
        raise PoleError("psi: poles at non-positive integers")
      }
    None => ()
  }
  let p = wp(prec) + 24
  let mut y = x.rounded(p, Nearest)
  let mut corr = @mpf.RawMpf::zero()
  let fact = factorial_small_mpf(m, p)
  if y.sign == 1 {
    while y.sign == 1 {
      let mut term = mpf_div_checked(
        fact,
        mpf_pow_checked(y, @mpf.RawMpf::from_int(m + 1), p, Nearest),
        p,
        Nearest,
      )
      if (m & 1) == 1 {
        term = term.negated(p, Nearest)
      }
      corr = corr.add(term, p, Nearest)
      let next_y = y.add(@mpf.RawMpf::one(), p, Nearest)
      // Guard against non-progress loops when |y| is too large for +1 to change
      // at the current working precision.
      if next_y == y {
        break
      }
      y = next_y
    }
  }
  let sum = hurwitz_power_sum_em(y, m + 1, p)
  let mut val = fact.mul(sum, p, Nearest)
  if (m & 1) == 0 {
    val = val.negated(p, Nearest)
  }
  if !corr.is_zero() {
    val = val.sub(corr, p, Nearest)
  }
  val.rounded(prec, rnd)
}

///|
pub fn apery(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  zeta_integer(3, prec, rnd)
}

///|
pub fn catalan(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  let p = wp(prec) + 80
  let quarter = @mpf.RawMpf::one().scale_pow2(-2)
  let three_quarters = @mpf.RawMpf::from_int(3).scale_pow2(-2)
  polygamma(1, quarter, p, Nearest)
  .sub(polygamma(1, three_quarters, p, Nearest), p, Nearest)
  .scale_pow2(-4)
  .rounded(prec, rnd)
}

///|
pub fn euler(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  let p = wp(prec) + 24
  let n = {
    let value = p / 2 + 16
    if value < 48 {
      48
    } else {
      value
    }
  }
  let n_mpf = @mpf.RawMpf::from_int(n)
  let mut harmonic_sum = @mpf.RawMpf::zero()
  for k in 1..<=n {
    harmonic_sum = harmonic_sum.add(
      mpf_div_checked(@mpf.RawMpf::one(), @mpf.RawMpf::from_int(k), p, Nearest),
      p,
      Nearest,
    )
  }
  let inv_n = mpf_div_checked(@mpf.RawMpf::one(), n_mpf, p, Nearest)
  let inv_n2 = inv_n.mul(inv_n, p, Nearest)
  let mut power = inv_n2
  let mut value = harmonic_sum
    .sub(mpf_log_checked(n_mpf, p, Nearest), p, Nearest)
    .sub(inv_n.scale_pow2(-1), p, Nearest)
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 16
  for k in 1..<=max_terms {
    let term = mpf_div_checked(
      bernoulli(2 * k, p, Nearest).mul(power, p, Nearest),
      @mpf.RawMpf::from_int(2 * k),
      p,
      Nearest,
    )
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    value = value.add(term, p, Nearest)
    if k > 3 && tiny_enough(magnitude, p + 12) {
      break
    }
    previous = magnitude
    power = power.mul(inv_n2, p, Nearest)
  }
  value.rounded(prec, rnd)
}

///|
pub fn glaisher(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  let p = wp(prec) + 80
  let n = {
    let value = p / 2 + 32
    if value < 64 {
      64
    } else {
      value
    }
  }
  let n_mpf = @mpf.RawMpf::from_int(n)
  let n_squared = n_mpf.mul(n_mpf, p, Nearest)
  let mut hyperfactorial_log = @mpf.RawMpf::zero()
  for k in 2..<=n {
    let k_mpf = @mpf.RawMpf::from_int(k)
    hyperfactorial_log = hyperfactorial_log.add(
      mpf_log_checked(k_mpf, p, Nearest).mul_int(k, p, Nearest),
      p,
      Nearest,
    )
  }
  let one_twelfth = mpf_div_checked(
    @mpf.RawMpf::one(),
    @mpf.RawMpf::from_int(12),
    p,
    Nearest,
  )
  let logarithm_coefficient = n_squared
    .add(n_mpf, p, Nearest)
    .scale_pow2(-1)
    .add(one_twelfth, p, Nearest)
  let mut logarithm = hyperfactorial_log
    .sub(
      logarithm_coefficient.mul(mpf_log_checked(n_mpf, p, Nearest), p, Nearest),
      p,
      Nearest,
    )
    .add(n_squared.scale_pow2(-2), p, Nearest)
  let inverse_n = mpf_div_checked(@mpf.RawMpf::one(), n_mpf, p, Nearest)
  let inverse_n_squared = inverse_n.mul(inverse_n, p, Nearest)
  let mut inverse_power = inverse_n_squared
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 32
  for r in 2..<=max_terms {
    let two_r = 2 * r
    let denominator = @mpf.RawMpf::from_int(two_r * (two_r - 1) * (two_r - 2))
    let correction = mpf_div_checked(
      bernoulli(two_r, p, Nearest).mul(inverse_power, p, Nearest),
      denominator,
      p,
      Nearest,
    )
    let magnitude = correction.abs(p, Nearest)
    if r > 5 && magnitude >= previous {
      break
    }
    logarithm = logarithm.add(correction, p, Nearest)
    if r > 4 && tiny_enough(magnitude, p + 16) {
      break
    }
    previous = magnitude
    inverse_power = inverse_power.mul(inverse_n_squared, p, Nearest)
  }
  mpf_exp_checked(logarithm, p, Nearest).rounded(prec, rnd)
}

///|
pub fn khinchin(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "2.68545200106530644530971483548179569382038229399446295305115", prec, rnd,
  )
}

///|
pub fn mertens(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "0.261497212847642783755426838608695859051566648261199206192064", prec, rnd,
  )
}

///|
pub fn twin_prime_constant(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "0.660161815846869573927812110014555778432623360284733413319448", prec, rnd,
  )
}

///|
pub fn zeta_sum(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> @mpf.RawMpf raise GammaZetaError {
  if terms <= 0 {
    return @mpf.RawMpf::zero()
  }
  let p = wp(prec) + 24
  let mut sum = @mpf.RawMpf::zero()
  for i in 0..<terms {
    let k = start + i
    if k <= 0 {
      continue
    }
    let den = mpf_pow_checked(@mpf.RawMpf::from_int(k), s, p, Nearest)
    let term = mpf_div_checked(@mpf.RawMpf::one(), den, p, Nearest)
    sum = sum.add(term, p, Nearest)
  }
  sum.rounded(prec, rnd)
}
