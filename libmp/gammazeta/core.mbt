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
  if @mpf.is_zero(x) {
    true
  } else if !@mpf.is_finite(x) {
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
    @mpf.MpfError::ValueError(msg) => GammaZetaError::ValueError(msg)
    @mpf.MpfError::DomainError(msg) => GammaZetaError::DomainError(msg)
    @mpf.MpfError::DivisionByZero(msg) => GammaZetaError::PoleError(msg)
    @mpf.MpfError::ParseError(msg) => GammaZetaError::ValueError(msg)
    @mpf.MpfError::FormatError(msg) => GammaZetaError::ValueError(msg)
    @mpf.MpfError::UnsupportedError(msg) => GammaZetaError::ValueError(msg)
  }
}

///|
fn from_libelefun_error(err : @libelefun.LibElefunError) -> GammaZetaError {
  match err {
    @libelefun.LibElefunError::ValueError(msg) =>
      GammaZetaError::ValueError(msg)
    @libelefun.LibElefunError::DomainError(msg) =>
      GammaZetaError::DomainError(msg)
    @libelefun.LibElefunError::ComplexResult(msg) =>
      GammaZetaError::DomainError(msg)
  }
}

///|
fn mpf_from_str_checked(
  s : String,
  prec~ : Int,
  rnd~ : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @mpf.from_str(s, prec~, rnd~) catch {
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
  @mpf.mpf_div(x, y, prec, rnd) catch {
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
  @mpf.mpf_pow_int(x, n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_sqrt_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @mpf.mpf_sqrt(x, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpf_log_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  @libelefun.mpf_log(x, prec, rnd) catch {
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
  @libelefun.mpf_pow(x, y, prec, rnd) catch {
    _ =>
      raise GammaZetaError::DomainError(
        "mpf_pow: invalid real-domain continuation",
      )
  }
}

///|
let euler_gamma : @mpf.RawMpf = mpf_from_str_checked(
  "0.57721566490153286060651209008240243104215933593992",
  prec=240,
  rnd=@mpf.round_nearest,
) catch {
  _ => @mpf.fnan
}

///|
pub fn mpf_bernoulli_huge(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise GammaZetaError::ValueError(
      "mpf_bernoulli_huge: n must be non-negative",
    )
  }
  if n == 0 {
    return @mpf.fone
  }
  if n == 1 {
    return @mpf.from_man_exp(-1N, -1, prec, rnd)
  }
  if (n & 1) == 1 {
    return @mpf.fzero
  }
  let p = wp(prec) + 10
  let piprec = p + int_bit_length(n)
  let mut v = mpf_gamma_int(n + 1, p, @mpf.round_nearest)
  v = @mpf.mpf_mul(v, zeta_eta_series(n, p), p, @mpf.round_nearest)
  v = @mpf.mpf_mul(
    v,
    mpf_pow_int_checked(
      @libelefun.mpf_pi(piprec, @mpf.round_nearest),
      -n,
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  v = @mpf.mpf_shift(v, 1 - n)
  if (n & 3) == 0 {
    v = @mpf.mpf_neg(v, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(v, prec, rnd)
}

///|
pub fn mpf_factorial(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise GammaZetaError::ValueError("mpf_factorial: n must be non-negative")
  }
  if n <= 1 {
    return @mpf.fone
  }
  let mut acc = @mpf.fone
  for i in 2..<=n {
    acc = @mpf.mpf_mul_int(acc, i, 0, @mpf.round_down)
  }
  @mpf.mpf_pos(acc, prec, rnd)
}

///|
pub fn mpf_bernoulli(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n < 0 {
    raise GammaZetaError::ValueError("mpf_bernoulli: n must be non-negative")
  }
  if n == 1 {
    return @mpf.from_man_exp(-1N, -1, prec, rnd)
  }
  if n > 1 && (n & 1) == 1 {
    return @mpf.fzero
  }
  if n >= 80 {
    return mpf_bernoulli_huge(n, prec, rnd)
  }
  let p = wp(prec)
  let a = Array::make(n + 1, @mpf.fzero)
  for m in 0..<=n {
    a[m] = mpf_div_checked(
      @mpf.fone,
      @mpf.from_int(m + 1),
      p,
      @mpf.round_nearest,
    )
    let mut j = m
    while j > 0 {
      a[j - 1] = @mpf.mpf_mul_int(
        @mpf.mpf_sub(a[j - 1], a[j], p, @mpf.round_nearest),
        j,
        p,
        @mpf.round_nearest,
      )
      j -= 1
    }
  }
  @mpf.mpf_pos(a[0], prec, rnd)
}

///|
fn zeta_even_via_bernoulli(
  n : Int,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let k = n / 2
  let b = mpf_bernoulli(n, p, @mpf.round_nearest)
  let two_pi = @mpf.mpf_mul_int(
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    2,
    p,
    @mpf.round_nearest,
  )
  let numer = @mpf.mpf_mul(
    b,
    mpf_pow_int_checked(two_pi, n, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let denom = @mpf.mpf_mul_int(
    mpf_factorial(n, p, @mpf.round_nearest),
    2,
    p,
    @mpf.round_nearest,
  )
  let mut z = mpf_div_checked(numer, denom, p, @mpf.round_nearest)
  if (k & 1) == 0 {
    z = @mpf.mpf_neg(z, p, @mpf.round_nearest)
  }
  z
}

///|
fn zeta_eta_series(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  let mut eta = @mpf.fzero
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
      @mpf.fone,
      mpf_pow_int_checked(@mpf.from_int(odd), n, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let even_term = mpf_div_checked(
      @mpf.fone,
      mpf_pow_int_checked(@mpf.from_int(even), n, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let term = @mpf.mpf_sub(odd_term, even_term, p, @mpf.round_nearest)
    eta = @mpf.mpf_add(eta, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), conv_bits) &&
      k > 8 {
      break
    }
    k += 1
  }
  let denom = @mpf.mpf_sub(
    @mpf.fone,
    @mpf.from_man_exp(1N, 1 - n, 0, @mpf.round_down),
    p,
    @mpf.round_nearest,
  )
  mpf_div_checked(eta, denom, p, @mpf.round_nearest)
}

///|
pub fn mpf_zeta_int(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 1 {
    raise GammaZetaError::ValueError("mpf_zeta_int: n must be > 1")
  }
  let p = wp(prec) + 16
  let z = if (n & 1) == 0 {
    zeta_even_via_bernoulli(n, p)
  } else if n <= 7 || p >= 220 {
    zeta_euler_maclaurin_real(@mpf.from_int(n), p)
  } else {
    zeta_eta_series(n, p)
  }
  @mpf.mpf_pos(z, prec, rnd)
}

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !@mpf.is_finite(x) {
    return None
  }
  if @mpf.is_zero(x) {
    return Some(0)
  }
  if x.exp >= 0 {
    let v = x.man << x.exp
    if v.bit_length() > 60 {
      return None
    }
    let n = v.to_int()
    if @mpf.mpf_eq(x, @mpf.from_int(if x.sign == 1 { -n } else { n })) {
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
    0 =>
      mpf_from_str_checked(
        "0.99999999999980993",
        prec=p,
        rnd=@mpf.round_nearest,
      )
    1 =>
      mpf_from_str_checked("676.5203681218851", prec=p, rnd=@mpf.round_nearest)
    2 =>
      mpf_from_str_checked(
        "-1259.1392167224028",
        prec=p,
        rnd=@mpf.round_nearest,
      )
    3 =>
      mpf_from_str_checked("771.32342877765313", prec=p, rnd=@mpf.round_nearest)
    4 =>
      mpf_from_str_checked(
        "-176.61502916214059",
        prec=p,
        rnd=@mpf.round_nearest,
      )
    5 =>
      mpf_from_str_checked("12.507343278686905", prec=p, rnd=@mpf.round_nearest)
    6 =>
      mpf_from_str_checked(
        "-0.13857109526572012",
        prec=p,
        rnd=@mpf.round_nearest,
      )
    7 =>
      mpf_from_str_checked(
        "0.0000099843695780195716",
        prec=p,
        rnd=@mpf.round_nearest,
      )
    _ =>
      mpf_from_str_checked(
        "0.00000015056327351493116",
        prec=p,
        rnd=@mpf.round_nearest,
      )
  }
}

///|
fn gamma_lanczos_positive(
  x : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let z1 = @mpf.mpf_sub(x, @mpf.fone, p, @mpf.round_nearest)
  let mut series = gamma_lanczos_coeff(0, p)
  for i in 1..<9 {
    series = @mpf.mpf_add(
      series,
      mpf_div_checked(
        gamma_lanczos_coeff(i, p),
        @mpf.mpf_add(z1, @mpf.from_int(i), p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
  }
  let t = @mpf.mpf_add(
    z1,
    mpf_from_str_checked("7.5", prec=p, rnd=@mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let pow_term = mpf_pow_checked(
    t,
    @mpf.mpf_add(
      z1,
      mpf_from_str_checked("0.5", prec=p, rnd=@mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let exp_term = @libelefun.mpf_exp(
    @mpf.mpf_neg(t, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_mul(
    mpf_from_str_checked(
      "2.5066282746310005024157652848110452",
      prec=p,
      rnd=@mpf.round_nearest,
    ),
    @mpf.mpf_mul(
      pow_term,
      @mpf.mpf_mul(exp_term, series, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
pub fn mpf_gamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fnan
    } else {
      return @mpf.finf
    }
  }
  match maybe_integer(x) {
    Some(n) => {
      if n <= 0 {
        raise GammaZetaError::PoleError(
          "mpf_gamma: pole at non-positive integer",
        )
      }
      return mpf_factorial(n - 1, prec, rnd)
    }
    None => ()
  }
  let p = wp(prec)
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  if @mpf.mpf_eq(x, half) {
    return mpf_sqrt_checked(@libelefun.mpf_pi(p, @mpf.round_nearest), prec, rnd)
  }
  if @mpf.mpf_eq(x, @mpf.mpf_neg(half, 0, @mpf.round_down)) {
    let root_pi = mpf_sqrt_checked(
      @libelefun.mpf_pi(p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    return @mpf.mpf_mul_int(
      @mpf.mpf_neg(root_pi, p, @mpf.round_nearest),
      2,
      prec,
      rnd,
    )
  }
  if x.sign == 1 {
    let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
    let sin_term = @libelefun.mpf_sin(
      @mpf.mpf_mul(pi, x, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    if @mpf.is_zero(sin_term) {
      raise GammaZetaError::PoleError("mpf_gamma: pole at non-positive integer")
    }
    let gamma_term = mpf_gamma(
      @mpf.mpf_sub(@mpf.fone, x, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    return @mpf.mpf_pos(
      mpf_div_checked(
        pi,
        @mpf.mpf_mul(sin_term, gamma_term, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      prec,
      rnd,
    )
  }
  @mpf.mpf_pos(gamma_lanczos_positive(x, p), prec, rnd)
}

///|
pub fn mpf_rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  let p = wp(prec) + 8
  let g = mpf_gamma(x, p, @mpf.round_nearest)
  @mpf.mpf_pos(mpf_div_checked(@mpf.fone, g, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_loggamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  let p = wp(prec) + 8
  let g = mpf_gamma(x, p, @mpf.round_nearest)
  @mpf.mpf_pos(mpf_log_checked(g, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_gamma_int(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 0 {
    raise GammaZetaError::ValueError("mpf_gamma_int: n must be positive")
  }
  mpf_factorial(n - 1, prec, rnd)
}

///|
fn harmonic_int(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  if n <= 0 {
    return @mpf.fzero
  }
  let mut sum = @mpf.fzero
  for k in 1..<=n {
    sum = @mpf.mpf_add(
      sum,
      mpf_div_checked(@mpf.fone, @mpf.from_int(k), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  sum
}

///|
pub fn mpf_psi0(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fnan
    }
    return @mpf.finf
  }
  match maybe_integer(x) {
    Some(n) => {
      if n <= 0 {
        raise GammaZetaError::PoleError(
          "mpf_psi0: poles at non-positive integers",
        )
      }
      let p = wp(prec) + 8
      return @mpf.mpf_pos(
        @mpf.mpf_sub(
          harmonic_int(n - 1, p),
          @mpf.mpf_pos(euler_gamma, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        prec,
        rnd,
      )
    }
    None => ()
  }
  if @mpf.is_zero(x) {
    raise GammaZetaError::DomainError(
      "mpf_psi0: non-positive input is unsupported",
    )
  }
  if x.sign == 1 {
    let p = wp(prec) + 24
    let one_minus_x = @mpf.mpf_sub(@mpf.fone, x, p, @mpf.round_nearest)
    let psi_ref = mpf_psi0(one_minus_x, p, @mpf.round_nearest)
    let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
    let (cos_pix, sin_pix) = @libelefun.mpf_cos_sin_pi(x, p, @mpf.round_nearest)
    let cot_pix = mpf_div_checked(cos_pix, sin_pix, p, @mpf.round_nearest)
    let corr = @mpf.mpf_mul(pi, cot_pix, p, @mpf.round_nearest)
    return @mpf.mpf_pos(
      @mpf.mpf_sub(psi_ref, corr, p, @mpf.round_nearest),
      prec,
      rnd,
    )
  }
  let p = wp(prec) + 40
  let mut y = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut acc = @mpf.fzero
  while @mpf.mpf_lt(y, @mpf.from_int(8)) {
    acc = @mpf.mpf_sub(
      acc,
      mpf_div_checked(@mpf.fone, y, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    y = @mpf.mpf_add(y, @mpf.fone, p, @mpf.round_nearest)
  }
  let inv = mpf_div_checked(@mpf.fone, y, p, @mpf.round_nearest)
  let inv2 = @mpf.mpf_mul(inv, inv, p, @mpf.round_nearest)
  let inv4 = @mpf.mpf_mul(inv2, inv2, p, @mpf.round_nearest)
  let inv6 = @mpf.mpf_mul(inv4, inv2, p, @mpf.round_nearest)
  let series = @mpf.mpf_add(
    mpf_log_checked(y, p, @mpf.round_nearest),
    @mpf.mpf_sub(
      @mpf.mpf_neg(@mpf.mpf_shift(inv, -1), p, @mpf.round_nearest),
      mpf_div_checked(inv2, @mpf.from_int(12), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let series = @mpf.mpf_add(
    series,
    @mpf.mpf_sub(
      mpf_div_checked(inv4, @mpf.from_int(120), p, @mpf.round_nearest),
      mpf_div_checked(inv6, @mpf.from_int(252), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(@mpf.mpf_add(series, acc, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_harmonic(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fnan
    }
    return @mpf.finf
  }
  match maybe_integer(x) {
    Some(n) => {
      if n < 0 {
        raise GammaZetaError::PoleError(
          "mpf_harmonic: poles at negative integers",
        )
      }
      let p = wp(prec) + 8
      return @mpf.mpf_pos(harmonic_int(n, p), prec, rnd)
    }
    None => ()
  }
  let p = wp(prec) + 16
  let psi = mpf_psi0(
    @mpf.mpf_add(x, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(
    @mpf.mpf_add(
      psi,
      @mpf.mpf_pos(euler_gamma, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
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
pub fn mpf_fibonacci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) || @mpf.is_inf(x) {
    return @mpf.fnan
  }
  match maybe_integer(x) {
    Some(n) => @mpf.from_man_exp(fib_int(n), 0, prec, rnd)
    None => {
      let p = wp(prec) + 24
      let phi = @libelefun.mpf_phi(p, @mpf.round_nearest)
      let sqrt5 = mpf_sqrt_checked(@mpf.from_int(5), p, @mpf.round_nearest) catch {
        _ => return @mpf.fnan
      }
      let phix = mpf_pow_checked(phi, x, p, @mpf.round_nearest) catch {
        _ => return @mpf.fnan
      }
      let phimx = mpf_pow_checked(
        phi,
        @mpf.mpf_neg(x, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ) catch {
        _ => return @mpf.fnan
      }
      let cospix = @libelefun.mpf_cos(
        @mpf.mpf_mul(
          @libelefun.mpf_pi(p, @mpf.round_nearest),
          x,
          p,
          @mpf.round_nearest,
        ),
        p,
        @mpf.round_nearest,
      )
      let numer = @mpf.mpf_sub(
        phix,
        @mpf.mpf_mul(cospix, phimx, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      @mpf.mpf_pos(
        mpf_div_checked(numer, sqrt5, p, @mpf.round_nearest) catch {
          _ => return @mpf.fnan
        },
        prec,
        rnd,
      )
    }
  }
}

///|
fn zeta_eta_real(s : @mpf.RawMpf, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  let pole_dist = @mpf.mpf_abs(
    @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let pole_bits = if @mpf.is_zero(pole_dist) {
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
  let mut eta = @mpf.fzero
  let mut k = 1
  while k < max_terms {
    let term_abs = mpf_div_checked(
      @mpf.fone,
      mpf_pow_checked(@mpf.from_int(k), s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let term = if (k & 1) == 1 {
      term_abs
    } else {
      @mpf.mpf_neg(term_abs, p, @mpf.round_nearest)
    }
    eta = @mpf.mpf_add(eta, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term_abs, p, @mpf.round_nearest), conv_bits) &&
      k > 24 {
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
  let pole_dist = @mpf.mpf_abs(
    @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let pole_bits = if @mpf.is_zero(pole_dist) {
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
  let n_mpf = @mpf.from_int(n)
  let mut sum = @mpf.fzero
  for k in 1..<n {
    sum = @mpf.mpf_add(
      sum,
      mpf_div_checked(
        @mpf.fone,
        mpf_pow_checked(@mpf.from_int(k), s, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
  }
  let n_pow_s = mpf_pow_checked(n_mpf, s, p, @mpf.round_nearest)
  let n_neg_s = mpf_div_checked(@mpf.fone, n_pow_s, p, @mpf.round_nearest)
  let tail_integral = mpf_div_checked(
    @mpf.mpf_mul(n_mpf, n_neg_s, p, @mpf.round_nearest),
    @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let tail_half = @mpf.mpf_mul(
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    n_neg_s,
    p,
    @mpf.round_nearest,
  )
  let mut corr = @mpf.fzero
  for m in 1..<=terms {
    let two_m = 2 * m
    let mut poch = @mpf.fone
    for r in 0..<(two_m - 1) {
      poch = @mpf.mpf_mul(
        poch,
        @mpf.mpf_add(s, @mpf.from_int(r), p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let coeff = mpf_div_checked(
      mpf_bernoulli(two_m, p, @mpf.round_nearest),
      mpf_factorial(two_m, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let mut n_pow = n_neg_s
    for _ in 0..<(two_m - 1) {
      n_pow = mpf_div_checked(n_pow, n_mpf, p, @mpf.round_nearest)
    }
    let corr_term = @mpf.mpf_mul(
      coeff,
      @mpf.mpf_mul(poch, n_pow, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    corr = @mpf.mpf_add(corr, corr_term, p, @mpf.round_nearest)
    if m >= 4 &&
      tiny_enough(
        @mpf.mpf_abs(corr_term, p, @mpf.round_nearest),
        p + 12 + pole_bits,
      ) {
      break
    }
  }
  @mpf.mpf_add(
    sum,
    @mpf.mpf_add(
      tail_integral,
      @mpf.mpf_add(tail_half, corr, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
fn zeta_alt_factor(
  s : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  @mpf.mpf_sub(
    @mpf.fone,
    mpf_pow_checked(
      @mpf.from_int(2),
      @mpf.mpf_sub(@mpf.fone, s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
fn zeta_negative_int(n : Int, p : Int) -> @mpf.RawMpf raise GammaZetaError {
  if (n & 1) == 0 {
    return @mpf.fzero
  }
  let m = -n
  @mpf.mpf_neg(
    mpf_div_checked(
      mpf_bernoulli(m + 1, p, @mpf.round_nearest),
      @mpf.from_int(m + 1),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
fn zeta_reflection_real(
  s : @mpf.RawMpf,
  p : Int,
) -> @mpf.RawMpf raise GammaZetaError {
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let one_minus_s = @mpf.mpf_sub(@mpf.fone, s, p, @mpf.round_nearest)
  let two_pow_s = mpf_pow_checked(@mpf.from_int(2), s, p, @mpf.round_nearest)
  let pi_pow = mpf_pow_checked(
    pi,
    @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let sin_term = @libelefun.mpf_sin(
    @mpf.mpf_shift(@mpf.mpf_mul(pi, s, p, @mpf.round_nearest), -1),
    p,
    @mpf.round_nearest,
  )
  let gamma_term = mpf_gamma(one_minus_s, p, @mpf.round_nearest)
  let zeta_term = mpf_zeta(one_minus_s, p, @mpf.round_nearest)
  @mpf.mpf_mul(
    two_pow_s,
    @mpf.mpf_mul(
      pi_pow,
      @mpf.mpf_mul(
        sin_term,
        @mpf.mpf_mul(gamma_term, zeta_term, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
pub fn mpf_zeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf raise GammaZetaError {
  if @mpf.is_nan(s) {
    return @mpf.fnan
  }
  if @mpf.is_inf(s) {
    if s.sign == 1 {
      return @mpf.fnan
    }
    return @mpf.fone
  }
  if @mpf.is_zero(s) {
    return if alt {
      @mpf.from_man_exp(1N, -1, prec, rnd)
    } else {
      @mpf.from_man_exp(-1N, -1, prec, rnd)
    }
  }
  match maybe_integer(s) {
    Some(n) => {
      if n == 1 {
        if alt {
          let p = wp(prec) + 16
          let ln2 = mpf_log_checked(@mpf.from_int(2), p, @mpf.round_nearest)
          return @mpf.mpf_pos(ln2, prec, rnd)
        }
        raise GammaZetaError::PoleError("mpf_zeta: pole at s=1")
      }
      if n > 1 {
        let p = wp(prec) + 16
        let z = mpf_zeta_int(n, p, @mpf.round_nearest)
        if alt {
          let factor = zeta_alt_factor(@mpf.from_int(n), p)
          return @mpf.mpf_pos(
            @mpf.mpf_mul(z, factor, p, @mpf.round_nearest),
            prec,
            rnd,
          )
        }
        return @mpf.mpf_pos(z, prec, rnd)
      }
      let p = wp(prec) + 24
      let z = zeta_negative_int(n, p)
      if alt {
        return @mpf.mpf_pos(
          @mpf.mpf_mul(
            z,
            zeta_alt_factor(@mpf.from_int(n), p),
            p,
            @mpf.round_nearest,
          ),
          prec,
          rnd,
        )
      }
      return @mpf.mpf_pos(z, prec, rnd)
    }
    None => ()
  }
  if s.sign == 1 {
    let p = wp(prec) + 28
    let z = zeta_reflection_real(s, p)
    if alt {
      return @mpf.mpf_pos(
        @mpf.mpf_mul(z, zeta_alt_factor(s, p), p, @mpf.round_nearest),
        prec,
        rnd,
      )
    }
    return @mpf.mpf_pos(z, prec, rnd)
  }
  let p = wp(prec) + 24
  let pole_dist = @mpf.mpf_abs(
    @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  if @mpf.mpf_lt(@mpf.fzero, s) &&
    (@mpf.mpf_lt(@mpf.fone, s) || @mpf.mpf_lt(pole_dist, half)) {
    let pole_dist = @mpf.mpf_abs(
      @mpf.mpf_sub(s, @mpf.fone, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let pole_bits = if @mpf.is_zero(pole_dist) {
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
      return @mpf.mpf_pos(
        @mpf.mpf_mul(z, zeta_alt_factor(s, p_work), p_work, @mpf.round_nearest),
        prec,
        rnd,
      )
    }
    return @mpf.mpf_pos(z, prec, rnd)
  }
  let eta = zeta_eta_real(s, p)
  if alt {
    return @mpf.mpf_pos(eta, prec, rnd)
  }
  let denom = zeta_alt_factor(s, p)
  if @mpf.is_zero(denom) {
    raise GammaZetaError::PoleError("mpf_zeta: pole at s=1")
  }
  @mpf.mpf_pos(mpf_div_checked(eta, denom, p, @mpf.round_nearest), prec, rnd)
}

///|
fn const_str(v : String, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  mpf_from_str_checked(v, prec=if prec > 0 { prec + 8 } else { 64 }, rnd~) catch {
    _ => @mpf.fnan
  }
}

///|
pub fn mpf_altzeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  mpf_zeta(s, prec, rnd, alt=true)
}

///|
fn factorial_small_mpf(n : Int, p : Int) -> @mpf.RawMpf {
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
  let mut sum = @mpf.fzero
  for k in 0..<n {
    sum = @mpf.mpf_add(
      sum,
      mpf_div_checked(
        @mpf.fone,
        mpf_pow_int_checked(
          @mpf.mpf_add(x, @mpf.from_int(k), p, @mpf.round_nearest),
          s,
          p,
          @mpf.round_nearest,
        ),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
  }
  let xn = @mpf.mpf_add(x, @mpf.from_int(n), p, @mpf.round_nearest)
  let tail_int = mpf_div_checked(
    mpf_pow_int_checked(xn, 1 - s, p, @mpf.round_nearest),
    @mpf.from_int(s - 1),
    p,
    @mpf.round_nearest,
  )
  let tail_half = @mpf.mpf_shift(
    mpf_div_checked(
      @mpf.fone,
      mpf_pow_int_checked(xn, s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    -1,
  )
  let mut corr = @mpf.fzero
  for r in 1..<=terms {
    let two_r = 2 * r
    let mut poch = @mpf.fone
    for j in 0..<(two_r - 1) {
      poch = @mpf.mpf_mul_int(poch, s + j, p, @mpf.round_nearest)
    }
    let coeff = mpf_div_checked(
      mpf_bernoulli(two_r, p, @mpf.round_nearest),
      mpf_factorial(two_r, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let xpow = mpf_pow_int_checked(xn, -(s + two_r - 1), p, @mpf.round_nearest)
    let term = @mpf.mpf_mul(
      coeff,
      @mpf.mpf_mul(poch, xpow, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    corr = @mpf.mpf_add(corr, term, p, @mpf.round_nearest)
    if r >= 3 && tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 8) {
      break
    }
  }
  @mpf.mpf_add(
    sum,
    @mpf.mpf_add(
      tail_int,
      @mpf.mpf_add(tail_half, corr, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
}

///|
pub fn mpf_psi(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  if m < 0 {
    raise GammaZetaError::ValueError("mpf_psi: m must be non-negative")
  }
  if m == 0 {
    return mpf_psi0(x, prec, rnd)
  }
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.fnan
    }
    return @mpf.fzero
  }
  if @mpf.is_zero(x) {
    raise GammaZetaError::PoleError("mpf_psi: poles at non-positive integers")
  }
  match maybe_integer(x) {
    Some(n) =>
      if n <= 0 {
        raise GammaZetaError::PoleError(
          "mpf_psi: poles at non-positive integers",
        )
      }
    None => ()
  }
  let p = wp(prec) + 24
  let mut y = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut corr = @mpf.fzero
  let fact = factorial_small_mpf(m, p)
  if y.sign == 1 {
    while y.sign == 1 {
      let mut term = mpf_div_checked(
        fact,
        mpf_pow_checked(y, @mpf.from_int(m + 1), p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      if (m & 1) == 1 {
        term = @mpf.mpf_neg(term, p, @mpf.round_nearest)
      }
      corr = @mpf.mpf_add(corr, term, p, @mpf.round_nearest)
      let next_y = @mpf.mpf_add(y, @mpf.fone, p, @mpf.round_nearest)
      // Guard against non-progress loops when |y| is too large for +1 to change
      // at the current working precision.
      if next_y == y {
        break
      }
      y = next_y
    }
  }
  let sum = hurwitz_power_sum_em(y, m + 1, p)
  let mut val = @mpf.mpf_mul(fact, sum, p, @mpf.round_nearest)
  if (m & 1) == 0 {
    val = @mpf.mpf_neg(val, p, @mpf.round_nearest)
  }
  if !@mpf.is_zero(corr) {
    val = @mpf.mpf_sub(val, corr, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(val, prec, rnd)
}

///|
pub fn mpf_apery(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "1.20205690315959428539973816151144999076498629234049888179227", prec, rnd,
  )
}

///|
pub fn mpf_catalan(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "0.915965594177219015054603514932384110774149374281672134266498", prec, rnd,
  )
}

///|
pub fn mpf_euler(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "0.577215664901532860606512090082402431042159335939923598805767", prec, rnd,
  )
}

///|
pub fn mpf_glaisher(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "1.28242712910062263687534256886979172776768892732500119206374", prec, rnd,
  )
}

///|
pub fn mpf_khinchin(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "2.68545200106530644530971483548179569382038229399446295305115", prec, rnd,
  )
}

///|
pub fn mpf_mertens(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "0.261497212847642783755426838608695859051566648261199206192064", prec, rnd,
  )
}

///|
pub fn mpf_twinprime(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  const_str(
    "0.660161815846869573927812110014555778432623360284733413319448", prec, rnd,
  )
}

///|
pub fn mpf_zetasum(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> @mpf.RawMpf {
  if terms <= 0 {
    return @mpf.fzero
  }
  let p = wp(prec) + 24
  let mut sum = @mpf.fzero
  for i in 0..<terms {
    let k = start + i
    if k <= 0 {
      continue
    }
    let den = mpf_pow_checked(@mpf.from_int(k), s, p, @mpf.round_nearest) catch {
      _ => return @mpf.fnan
    }
    let term = mpf_div_checked(@mpf.fone, den, p, @mpf.round_nearest) catch {
      _ => return @mpf.fnan
    }
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(sum, prec, rnd)
}
