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
let euler_gamma : @mpf.RawMpf = @mpf.RawMpf::from_mantissa_exponent(
  254962950818844203052873526785993192115782030385265309526297679521529565N,
  -238,
  0,
  Down,
)

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
  v = v.mul(zeta_eta_series(n, p), p, Nearest)
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
  let p = wp(prec)
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
fn zeta_eta_series(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  let mut eta = @mpf.RawMpf::zero()
  let mut max_terms = 64 + p * 3
  if n <= 3 {
    max_terms += p * 8
  } else if n <= 7 {
    max_terms += p * 4
  }
  if max_terms < 512 {
    max_terms = 512
  }
  if max_terms > 3000000 {
    max_terms = 3000000
  }
  let mut conv_bits = p + 14
  if conv_bits > p + 192 {
    conv_bits = p + 192
  }
  let mut k = 1
  while k < max_terms {
    let odd = 2 * k - 1
    let even = 2 * k
    let odd_term = mpf_div_checked(
      @mpf.RawMpf::one(),
      mpf_pow_int_checked(@mpf.RawMpf::from_int(odd), n, p, Nearest),
      p,
      Nearest,
    )
    let even_term = mpf_div_checked(
      @mpf.RawMpf::one(),
      mpf_pow_int_checked(@mpf.RawMpf::from_int(even), n, p, Nearest),
      p,
      Nearest,
    )
    let term = odd_term.sub(even_term, p, Nearest)
    eta = eta.add(term, p, Nearest)
    if tiny_enough(term.abs(p, Nearest), conv_bits) && k > 8 {
      break
    }
    k += 1
  }
  let denom = @mpf.RawMpf::one().sub(
    @mpf.RawMpf::from_mantissa_exponent(1N, 1 - n, 0, Down),
    p,
    Nearest,
  )
  mpf_div_checked(eta, denom, p, Nearest)
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
  } else if n <= 7 || p >= 220 {
    zeta_euler_maclaurin_real(@mpf.RawMpf::from_int(n), p)
  } else {
    zeta_eta_series(n, p)
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
fn gamma_lanczos_coeff(i : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  match i {
    0 => mpf_from_str_checked("0.99999999999980993", prec=p, rnd=Nearest)
    1 => mpf_from_str_checked("676.5203681218851", prec=p, rnd=Nearest)
    2 => mpf_from_str_checked("-1259.1392167224028", prec=p, rnd=Nearest)
    3 => mpf_from_str_checked("771.32342877765313", prec=p, rnd=Nearest)
    4 => mpf_from_str_checked("-176.61502916214059", prec=p, rnd=Nearest)
    5 => mpf_from_str_checked("12.507343278686905", prec=p, rnd=Nearest)
    6 => mpf_from_str_checked("-0.13857109526572012", prec=p, rnd=Nearest)
    7 => mpf_from_str_checked("0.0000099843695780195716", prec=p, rnd=Nearest)
    _ => mpf_from_str_checked("0.00000015056327351493116", prec=p, rnd=Nearest)
  }
}

///|
fn gamma_lanczos_positive(
  x : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let z1 = x.sub(@mpf.RawMpf::one(), p, Nearest)
  let mut series = gamma_lanczos_coeff(0, p)
  for i in 1..<9 {
    series = series.add(
      mpf_div_checked(
        gamma_lanczos_coeff(i, p),
        z1.add(@mpf.RawMpf::from_int(i), p, Nearest),
        p,
        Nearest,
      ),
      p,
      Nearest,
    )
  }
  let t = z1.add(mpf_from_str_checked("7.5", prec=p, rnd=Nearest), p, Nearest)
  let pow_term = mpf_pow_checked(
    t,
    z1.add(mpf_from_str_checked("0.5", prec=p, rnd=Nearest), p, Nearest),
    p,
    Nearest,
  )
  let exp_term = mpf_exp_checked(t.negated(p, Nearest), p, Nearest)
  mpf_from_str_checked(
    "2.5066282746310005024157652848110452",
    prec=p,
    rnd=Nearest,
  ).mul(pow_term.mul(exp_term.mul(series, p, Nearest), p, Nearest), p, Nearest)
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
    let sin_term = mpf_sin_checked(pi.mul(x, p, Nearest), p, Nearest)
    if sin_term.is_zero() {
      raise PoleError("gamma: pole at non-positive integer")
    }
    let gamma_term = gamma(@mpf.RawMpf::one().sub(x, p, Nearest), p, Nearest)
    return mpf_div_checked(pi, sin_term.mul(gamma_term, p, Nearest), p, Nearest).rounded(
      prec, rnd,
    )
  }
  gamma_lanczos_positive(x, p).rounded(prec, rnd)
}

///|
pub fn rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
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
  let p = wp(prec) + 8
  let g = gamma(x, p, Nearest)
  mpf_log_checked(g, p, Nearest).rounded(prec, rnd)
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
        .sub(euler_gamma.rounded(p, Nearest), p, Nearest)
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
  while y < @mpf.RawMpf::from_int(8) {
    acc = acc.sub(
      mpf_div_checked(@mpf.RawMpf::one(), y, p, Nearest),
      p,
      Nearest,
    )
    y = y.add(@mpf.RawMpf::one(), p, Nearest)
  }
  let inv = mpf_div_checked(@mpf.RawMpf::one(), y, p, Nearest)
  let inv2 = inv.mul(inv, p, Nearest)
  let inv4 = inv2.mul(inv2, p, Nearest)
  let inv6 = inv4.mul(inv2, p, Nearest)
  let series = mpf_log_checked(y, p, Nearest).add(
    inv
    .scale_pow2(-1)
    .negated(p, Nearest)
    .sub(
      mpf_div_checked(inv2, @mpf.RawMpf::from_int(12), p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
  let series = series.add(
    mpf_div_checked(inv4, @mpf.RawMpf::from_int(120), p, Nearest).sub(
      mpf_div_checked(inv6, @mpf.RawMpf::from_int(252), p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
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
  psi.add(euler_gamma.rounded(p, Nearest), p, Nearest).rounded(prec, rnd)
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
  let mut max_terms = 96 + p * 3 + pole_bits * 4
  if max_terms < 512 {
    max_terms = 512
  }
  if max_terms > 4000000 {
    max_terms = 4000000
  }
  let mut conv_bits = p + 10 + pole_bits
  if conv_bits > p + 384 {
    conv_bits = p + 384
  }
  let mut eta = @mpf.RawMpf::zero()
  let mut k = 1
  while k < max_terms {
    let term_abs = mpf_div_checked(
      @mpf.RawMpf::one(),
      mpf_pow_checked(@mpf.RawMpf::from_int(k), s, p, Nearest),
      p,
      Nearest,
    )
    let term = if (k & 1) == 1 {
      term_abs
    } else {
      term_abs.negated(p, Nearest)
    }
    eta = eta.add(term, p, Nearest)
    if tiny_enough(term_abs.abs(p, Nearest), conv_bits) && k > 24 {
      break
    }
    k += 1
  }
  eta
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
  if n > 4096 {
    n = 4096
  }
  let mut terms = 6 + p / 10 + pole_bits / 2
  if terms < 6 {
    terms = 6
  }
  if terms > 256 {
    terms = 256
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
  let mut corr = @mpf.RawMpf::zero()
  for m in 1..<=terms {
    let two_m = 2 * m
    let mut poch = @mpf.RawMpf::one()
    for r in 0..<(two_m - 1) {
      poch = poch.mul(s.add(@mpf.RawMpf::from_int(r), p, Nearest), p, Nearest)
    }
    let coeff = mpf_div_checked(
      bernoulli(two_m, p, Nearest),
      factorial(two_m, p, Nearest),
      p,
      Nearest,
    )
    let mut n_pow = n_neg_s
    for _ in 0..<(two_m - 1) {
      n_pow = mpf_div_checked(n_pow, n_mpf, p, Nearest)
    }
    let corr_term = coeff.mul(poch.mul(n_pow, p, Nearest), p, Nearest)
    corr = corr.add(corr_term, p, Nearest)
    if m >= 4 && tiny_enough(corr_term.abs(p, Nearest), p + 12 + pole_bits) {
      break
    }
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
  let half = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
  if @mpf.RawMpf::zero() < s && (@mpf.RawMpf::one() < s || pole_dist < half) {
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
    let mut p_work = p + 24 + pole_bits * 2
    if p_work > p + 1024 {
      p_work = p + 1024
    }
    let z = zeta_euler_maclaurin_real(s, p_work)
    if alt {
      return z
        .mul(zeta_alt_factor(s, p_work), p_work, Nearest)
        .rounded(prec, rnd)
    }
    return z.rounded(prec, rnd)
  }
  let eta = zeta_eta_real(s, p)
  if alt {
    return eta.rounded(prec, rnd)
  }
  let denom = zeta_alt_factor(s, p)
  if denom.is_zero() {
    raise PoleError("zeta: pole at s=1")
  }
  mpf_div_checked(eta, denom, p, Nearest).rounded(prec, rnd)
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
  let mut n = 12 + p / 8
  if n < 12 {
    n = 12
  }
  if n > 512 {
    n = 512
  }
  let mut terms = 4 + p / 24
  if terms < 4 {
    terms = 4
  }
  if terms > 24 {
    terms = 24
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
  const_str(
    "1.20205690315959428539973816151144999076498629234049888179227", prec, rnd,
  )
}

///|
pub fn catalan(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "0.915965594177219015054603514932384110774149374281672134266498", prec, rnd,
  )
}

///|
pub fn euler(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "0.577215664901532860606512090082402431042159335939923598805767", prec, rnd,
  )
}

///|
pub fn glaisher(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  const_str(
    "1.28242712910062263687534256886979172776768892732500119206374", prec, rnd,
  )
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
