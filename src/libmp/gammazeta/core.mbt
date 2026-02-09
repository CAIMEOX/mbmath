///|
fn wp(prec : Int) -> Int {
  if prec > 0 {
    prec + 24
  } else {
    80
  }
}

///|
let euler_gamma : @mpf.RawMpf = @mpf.from_str(
  "0.57721566490153286060651209008240243104215933593992",
  prec=240,
  rnd=@mpf.round_nearest,
)

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
pub fn mpf_factorial(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if n < 0 {
    abort("mpf_factorial: n must be non-negative")
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
pub fn mpf_bernoulli(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if n < 0 {
    abort("mpf_bernoulli: n must be non-negative")
  }
  if n == 1 {
    return @mpf.from_man_exp(-1N, -1, prec, rnd)
  }
  if n > 1 && (n & 1) == 1 {
    return @mpf.fzero
  }
  let p = wp(prec)
  let a = Array::make(n + 1, @mpf.fzero)
  for m in 0..<=n {
    a[m] = @mpf.mpf_div(@mpf.fone, @mpf.from_int(m + 1), p, @mpf.round_nearest)
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
fn zeta_even_via_bernoulli(n : Int, p : Int) -> @mpf.RawMpf {
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
    @mpf.mpf_pow_int(two_pi, n, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let denom = @mpf.mpf_mul_int(
    mpf_factorial(n, p, @mpf.round_nearest),
    2,
    p,
    @mpf.round_nearest,
  )
  let mut z = @mpf.mpf_div(numer, denom, p, @mpf.round_nearest)
  if (k & 1) == 0 {
    z = @mpf.mpf_neg(z, p, @mpf.round_nearest)
  }
  z
}

///|
fn zeta_eta_series(n : Int, p : Int) -> @mpf.RawMpf {
  let mut eta = @mpf.fzero
  let mut k = 1
  while k < 200000 {
    let odd = 2 * k - 1
    let even = 2 * k
    let odd_term = @mpf.mpf_div(
      @mpf.fone,
      @mpf.mpf_pow_int(@mpf.from_int(odd), n, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let even_term = @mpf.mpf_div(
      @mpf.fone,
      @mpf.mpf_pow_int(@mpf.from_int(even), n, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let term = @mpf.mpf_sub(odd_term, even_term, p, @mpf.round_nearest)
    eta = @mpf.mpf_add(eta, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 10) && k > 8 {
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
  @mpf.mpf_div(eta, denom, p, @mpf.round_nearest)
}

///|
pub fn mpf_zeta_int(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if n <= 1 {
    abort("mpf_zeta_int: n must be > 1")
  }
  let p = wp(prec) + 16
  let z = if (n & 1) == 0 {
    zeta_even_via_bernoulli(n, p)
  } else {
    zeta_eta_series(n, p)
  }
  @mpf.mpf_pos(z, prec, rnd)
}

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !@mpf.is_finite(x) || @mpf.is_zero(x) {
    return None
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
pub fn mpf_gamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
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
        abort("mpf_gamma: pole at non-positive integer")
      }
      return mpf_factorial(n - 1, prec, rnd)
    }
    None => ()
  }
  let p = wp(prec)
  let half = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)
  if @mpf.mpf_eq(x, half) {
    return @mpf.mpf_sqrt(@libelefun.mpf_pi(p, @mpf.round_nearest), prec, rnd)
  }
  if @mpf.mpf_eq(x, @mpf.mpf_neg(half, 0, @mpf.round_down)) {
    let root_pi = @mpf.mpf_sqrt(
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
    abort("mpf_gamma: unsupported negative non-integer input")
  }
  let mut y = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut scale = @mpf.fone
  while @mpf.mpf_lt(y, @mpf.from_int(8)) {
    scale = @mpf.mpf_div(scale, y, p, @mpf.round_nearest)
    y = @mpf.mpf_add(y, @mpf.fone, p, @mpf.round_nearest)
  }
  let ln_y = @libelefun.mpf_ln(y, p, @mpf.round_nearest)
  let one = @mpf.fone
  let stirling_main = @mpf.mpf_mul(y, ln_y, p, @mpf.round_nearest)
  let exp_part = @libelefun.mpf_exp(
    @mpf.mpf_sub(stirling_main, y, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let two_pi = @mpf.mpf_mul_int(
    @libelefun.mpf_pi(p, @mpf.round_nearest),
    2,
    p,
    @mpf.round_nearest,
  )
  let root = @mpf.mpf_sqrt(
    @mpf.mpf_div(two_pi, y, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let corr = @mpf.mpf_add(
    one,
    @mpf.mpf_div(
      one,
      @mpf.mpf_mul_int(y, 12, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let val = @mpf.mpf_mul(
    scale,
    @mpf.mpf_mul(
      root,
      @mpf.mpf_mul(exp_part, corr, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(val, prec, rnd)
}

///|
pub fn mpf_rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  let p = wp(prec) + 8
  let g = mpf_gamma(x, p, @mpf.round_nearest)
  @mpf.mpf_pos(@mpf.mpf_div(@mpf.fone, g, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_loggamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  let p = wp(prec) + 8
  let g = mpf_gamma(x, p, @mpf.round_nearest)
  @mpf.mpf_pos(@libelefun.mpf_log(g, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_gamma_int(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if n <= 0 {
    abort("mpf_gamma_int: n must be positive")
  }
  mpf_factorial(n - 1, prec, rnd)
}

///|
fn harmonic_int(n : Int, p : Int) -> @mpf.RawMpf {
  if n <= 0 {
    return @mpf.fzero
  }
  let mut sum = @mpf.fzero
  for k in 1..<=n {
    sum = @mpf.mpf_add(
      sum,
      @mpf.mpf_div(@mpf.fone, @mpf.from_int(k), p, @mpf.round_nearest),
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
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      abort("mpf_psi0: non-positive input is unsupported")
    }
    return @mpf.finf
  }
  match maybe_integer(x) {
    Some(n) => {
      if n <= 0 {
        abort("mpf_psi0: poles at non-positive integers")
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
  if x.sign == 1 || @mpf.is_zero(x) {
    abort("mpf_psi0: non-positive input is unsupported")
  }
  let p = wp(prec) + 24
  let mut y = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut acc = @mpf.fzero
  while @mpf.mpf_lt(y, @mpf.from_int(8)) {
    acc = @mpf.mpf_sub(
      acc,
      @mpf.mpf_div(@mpf.fone, y, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    y = @mpf.mpf_add(y, @mpf.fone, p, @mpf.round_nearest)
  }
  let inv = @mpf.mpf_div(@mpf.fone, y, p, @mpf.round_nearest)
  let inv2 = @mpf.mpf_mul(inv, inv, p, @mpf.round_nearest)
  let inv4 = @mpf.mpf_mul(inv2, inv2, p, @mpf.round_nearest)
  let inv6 = @mpf.mpf_mul(inv4, inv2, p, @mpf.round_nearest)
  let series = @mpf.mpf_add(
    @libelefun.mpf_log(y, p, @mpf.round_nearest),
    @mpf.mpf_sub(
      @mpf.mpf_neg(@mpf.mpf_shift(inv, -1), p, @mpf.round_nearest),
      @mpf.mpf_div(inv2, @mpf.from_int(12), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let series = @mpf.mpf_add(
    series,
    @mpf.mpf_sub(
      @mpf.mpf_div(inv4, @mpf.from_int(120), p, @mpf.round_nearest),
      @mpf.mpf_div(inv6, @mpf.from_int(252), p, @mpf.round_nearest),
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
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      abort("mpf_harmonic: non-positive input is unsupported")
    }
    return @mpf.finf
  }
  match maybe_integer(x) {
    Some(n) => {
      if n < 0 {
        abort("mpf_harmonic: poles at negative integers")
      }
      let p = wp(prec) + 8
      return @mpf.mpf_pos(harmonic_int(n, p), prec, rnd)
    }
    None => ()
  }
  if x.sign == 1 {
    abort("mpf_harmonic: negative non-integer input is unsupported")
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
      let sqrt5 = @mpf.mpf_sqrt(@mpf.from_int(5), p, @mpf.round_nearest)
      let phix = @libelefun.mpf_pow(phi, x, p, @mpf.round_nearest)
      let phimx = @libelefun.mpf_pow(
        phi,
        @mpf.mpf_neg(x, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
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
      @mpf.mpf_pos(@mpf.mpf_div(numer, sqrt5, p, @mpf.round_nearest), prec, rnd)
    }
  }
}

///|
fn zeta_eta_real(s : @mpf.RawMpf, p : Int) -> @mpf.RawMpf {
  let mut eta = @mpf.fzero
  let mut k = 1
  while k < 300000 {
    let term_abs = @mpf.mpf_div(
      @mpf.fone,
      @libelefun.mpf_pow(@mpf.from_int(k), s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let term = if (k & 1) == 1 {
      term_abs
    } else {
      @mpf.mpf_neg(term_abs, p, @mpf.round_nearest)
    }
    eta = @mpf.mpf_add(eta, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term_abs, p, @mpf.round_nearest), 24) && k > 24 {
      break
    }
    k += 1
  }
  eta
}

///|
pub fn mpf_zeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf {
  if @mpf.is_nan(s) {
    return @mpf.fnan
  }
  if @mpf.is_inf(s) {
    if s.sign == 1 {
      return @mpf.fnan
    }
    return @mpf.fone
  }
  match maybe_integer(s) {
    Some(n) => {
      if n == 1 {
        abort("mpf_zeta: pole at s=1")
      }
      if n > 1 {
        let p = wp(prec) + 16
        let z = mpf_zeta_int(n, p, @mpf.round_nearest)
        if alt {
          let factor = @mpf.mpf_sub(
            @mpf.fone,
            @mpf.from_man_exp(1N, 1 - n, 0, @mpf.round_down),
            p,
            @mpf.round_nearest,
          )
          return @mpf.mpf_pos(
            @mpf.mpf_mul(z, factor, p, @mpf.round_nearest),
            prec,
            rnd,
          )
        }
        return @mpf.mpf_pos(z, prec, rnd)
      }
    }
    None => ()
  }
  if s.sign == 1 || @mpf.is_zero(s) {
    abort("mpf_zeta: only positive real s is currently supported")
  }
  let p = wp(prec) + 24
  let eta = zeta_eta_real(s, p)
  if alt {
    return @mpf.mpf_pos(eta, prec, rnd)
  }
  let denom = @mpf.mpf_sub(
    @mpf.fone,
    @libelefun.mpf_pow(
      @mpf.from_int(2),
      @mpf.mpf_sub(@mpf.fone, s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  if @mpf.is_zero(denom) {
    abort("mpf_zeta: pole at s=1")
  }
  @mpf.mpf_pos(@mpf.mpf_div(eta, denom, p, @mpf.round_nearest), prec, rnd)
}

///|
fn const_str(v : String, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  @mpf.from_str(v, prec=if prec > 0 { prec + 8 } else { 64 }, rnd~)
}

///|
pub fn mpf_altzeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
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
pub fn mpf_psi(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if m < 0 {
    abort("mpf_psi: m must be non-negative")
  }
  if m == 0 {
    return mpf_psi0(x, prec, rnd)
  }
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if x.sign == 1 || @mpf.is_zero(x) || @mpf.is_inf(x) {
    abort("mpf_psi: only positive finite x is supported for m>0")
  }
  let p = wp(prec) + 24
  let mut sum = @mpf.fzero
  let mut k = 0
  while k < 200000 {
    let t = @mpf.mpf_div(
      @mpf.fone,
      @libelefun.mpf_pow(
        @mpf.mpf_add(x, @mpf.from_int(k), p, @mpf.round_nearest),
        @mpf.from_int(m + 1),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
    sum = @mpf.mpf_add(sum, t, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(t, p, @mpf.round_nearest), 24) && k > 24 {
      break
    }
    k += 1
  }
  let mut val = @mpf.mpf_mul(
    factorial_small_mpf(m, p),
    sum,
    p,
    @mpf.round_nearest,
  )
  if (m & 1) == 0 {
    val = @mpf.mpf_neg(val, p, @mpf.round_nearest)
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
    let term = @mpf.mpf_div(
      @mpf.fone,
      @libelefun.mpf_pow(@mpf.from_int(k), s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(sum, prec, rnd)
}
