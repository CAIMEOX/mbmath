///|
let euler_gamma : @mpf.RawMpf = try! @mpf.from_str(
  "0.57721566490153286060651209008240243104215933593992",
  prec=200,
  rnd=@mpf.round_nearest,
)

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
pub fn mpf_agm(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if @mpf.is_nan(x) || @mpf.is_nan(y) {
    return @mpf.fnan
  }
  if x.sign == 1 || y.sign == 1 {
    raise LibHyperError::ComplexResult("agm of a negative number")
  }
  if @mpf.is_zero(x) || @mpf.is_zero(y) {
    return @mpf.fzero
  }
  let p = if prec > 0 { prec + 12 } else { 64 }
  let mut a = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut b = @mpf.mpf_pos(y, p, @mpf.round_nearest)
  for _ in 0..<64 {
    let next_a = @mpf.mpf_shift(@mpf.mpf_add(a, b, p, @mpf.round_nearest), -1)
    let next_b = try! @mpf.mpf_sqrt(
      @mpf.mpf_mul(a, b, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let diff = @mpf.mpf_abs(
      @mpf.mpf_sub(next_a, next_b, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    a = next_a
    b = next_b
    if @mpf.is_zero(diff) {
      break
    }
    if @mpf.is_finite(diff) && diff.exp + diff.bc <= -p {
      break
    }
  }
  @mpf.mpf_pos(a, prec, rnd)
}

///|
pub fn mpf_ci_si_taylor(
  x : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> @mpf.RawMpf {
  let p = if wp > 0 { wp } else { 32 }
  let x2 = @mpf.mpf_neg(
    @mpf.mpf_mul(x, x, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let mut sum = if which == 0 {
    @mpf.fzero
  } else {
    @mpf.mpf_pos(x, p, @mpf.round_nearest)
  }
  let mut term = if which == 0 {
    @mpf.fone
  } else {
    @mpf.mpf_pos(x, p, @mpf.round_nearest)
  }
  let mut k = if which == 0 { 2 } else { 3 }
  let max_terms = if p <= 128 { 256 } else if p <= 512 { 1024 } else { p * 3 }
  while k < max_terms {
    let den = k * (k - 1)
    term = try! @mpf.mpf_div(
      @mpf.mpf_mul(term, x2, p, @mpf.round_nearest),
      @mpf.from_int(den),
      p,
      @mpf.round_nearest,
    )
    let add = try! @mpf.mpf_div(term, @mpf.from_int(k), p, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, add, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(add, p, @mpf.round_nearest), p + 8) && k > 7 {
      break
    }
    k += 2
  }
  sum
}

///|
pub fn mpf_ci_si(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 2,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  let p0 = wp(prec) + 20
  let mut ci = @mpf.fzero
  let mut si = @mpf.fzero
  if @mpf.is_nan(x) {
    return (@mpf.fnan, @mpf.fnan)
  }
  if @mpf.is_zero(x) {
    return (@mpf.fninf, @mpf.fzero)
  }
  if @mpf.is_inf(x) {
    if which != 0 {
      let half_pi = @mpf.mpf_shift(
        @libelefun.mpf_pi(p0, @mpf.round_nearest),
        -1,
      )
      si = if x.sign == 1 {
        @mpf.mpf_neg(half_pi, prec, rnd)
      } else {
        @mpf.mpf_pos(half_pi, prec, rnd)
      }
    }
    return (ci, si)
  }
  let mag = x.exp + x.bc
  let x_abs = @mpf.mpf_abs(x, p0, @mpf.round_nearest)
  if mag < -p0 {
    if which != 0 {
      si = @mpf.mpf_pos(x, prec, rnd)
    }
    if which != 1 {
      ci = @mpf.mpf_pos(
        @mpf.mpf_add(
          @mpf.mpf_pos(euler_gamma, p0, @mpf.round_nearest),
          try! @libelefun.mpf_ln(x_abs, p0, @mpf.round_nearest),
          p0,
          @mpf.round_nearest,
        ),
        prec,
        rnd,
      )
    }
    return (ci, si)
  }
  let p = p0 + (if mag > 0 { mag } else { -mag })
  let asymptotic = mag - 1 > int_bit_length(p)
  if !asymptotic {
    if which != 0 {
      si = @mpf.mpf_pos(mpf_ci_si_taylor(x, p, which=1), prec, rnd)
    }
    if which != 1 {
      let core = mpf_ci_si_taylor(x_abs, p, which=0)
      ci = @mpf.mpf_pos(
        @mpf.mpf_add(
          @mpf.mpf_add(
            core,
            @mpf.mpf_pos(euler_gamma, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          ),
          try! @libelefun.mpf_ln(x_abs, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        prec,
        rnd,
      )
    }
    return (ci, si)
  }
  let inv_x = try! @mpf.mpf_div(@mpf.fone, x_abs, p, @mpf.round_nearest)
  let inv_x2 = @mpf.mpf_mul(inv_x, inv_x, p, @mpf.round_nearest)
  let mut f_term = inv_x
  let mut f_sum = f_term
  let mut g_term = inv_x2
  let mut g_sum = g_term
  let mut m = 0
  let max_terms = if p <= 256 { 256 } else if p <= 1024 { 1024 } else { p * 2 }
  while m < max_terms {
    let a = 2 * m + 2
    f_term = @mpf.mpf_mul(
      @mpf.mpf_mul_int(f_term, -(a * (a - 1)), p, @mpf.round_nearest),
      inv_x2,
      p,
      @mpf.round_nearest,
    )
    g_term = @mpf.mpf_mul(
      @mpf.mpf_mul_int(g_term, -((a + 1) * a), p, @mpf.round_nearest),
      inv_x2,
      p,
      @mpf.round_nearest,
    )
    f_sum = @mpf.mpf_add(f_sum, f_term, p, @mpf.round_nearest)
    g_sum = @mpf.mpf_add(g_sum, g_term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(f_term, p, @mpf.round_nearest), p + 8) &&
      tiny_enough(@mpf.mpf_abs(g_term, p, @mpf.round_nearest), p + 8) &&
      m > 3 {
      break
    }
    m += 1
  }
  let (cos_x, sin_x) = @libelefun.mpf_cos_sin(x_abs, p, @mpf.round_nearest)
  if which != 1 {
    ci = @mpf.mpf_pos(
      @mpf.mpf_sub(
        @mpf.mpf_mul(sin_x, f_sum, p, @mpf.round_nearest),
        @mpf.mpf_mul(cos_x, g_sum, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      prec,
      rnd,
    )
  }
  if which != 0 {
    let mut si_abs = @mpf.mpf_sub(
      @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1),
      @mpf.mpf_add(
        @mpf.mpf_mul(cos_x, f_sum, p, @mpf.round_nearest),
        @mpf.mpf_mul(sin_x, g_sum, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
    if x.sign == 1 {
      si_abs = @mpf.mpf_neg(si_abs, p, @mpf.round_nearest)
    }
    si = @mpf.mpf_pos(si_abs, prec, rnd)
  }
  (ci, si)
}

///|
pub fn mpf_ci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if x.sign == 1 {
    raise LibHyperError::ComplexResult("")
  }
  if @mpf.is_zero(x) {
    return @mpf.fninf
  }
  if @mpf.is_inf(x) {
    return @mpf.fzero
  }
  let (ci, _) = mpf_ci_si(x, prec, rnd, which=0)
  ci
}

///|
pub fn mpf_si(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  let (_, si) = mpf_ci_si(x, prec, rnd, which=1)
  si
}

///|
pub fn mpf_ei(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
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
    return @mpf.fninf
  }
  let p = wp(prec) + 8
  let abs_x = @mpf.mpf_abs(x, p, @mpf.round_nearest)
  let mut sum = @mpf.mpf_add(
    euler_gamma,
    try! @libelefun.mpf_ln(abs_x, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let mut term = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
  let mut k = 1
  while k < 60000 {
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 10) && k > 3 {
      break
    }
    let kp1 = k + 1
    term = @mpf.mpf_mul(term, x, p, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, k, p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    k += 1
  }
  @mpf.mpf_pos(sum, prec, rnd)
}

///|
pub fn mpf_ellipk(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if @mpf.is_nan(m) {
    return @mpf.fnan
  }
  if @mpf.mpf_eq(m, @mpf.fone) {
    return @mpf.finf
  }
  if @mpf.mpf_gt(m, @mpf.fone) {
    raise LibHyperError::ComplexResult("square root of a negative number")
  }
  let p = wp(prec)
  let t = @mpf.mpf_sub(@mpf.fone, m, p, @mpf.round_nearest)
  let root = try! @mpf.mpf_sqrt(t, p, @mpf.round_nearest)
  let agm = mpf_agm(@mpf.fone, root, p, @mpf.round_nearest)
  let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1)
  @mpf.mpf_pos(
    try! @mpf.mpf_div(half_pi, agm, p, @mpf.round_nearest),
    prec,
    rnd,
  )
}

///|
pub fn mpf_ellipe(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if @mpf.is_nan(m) {
    return @mpf.fnan
  }
  if @mpf.mpf_eq(m, @mpf.fone) {
    return @mpf.fone
  }
  if @mpf.mpf_gt(m, @mpf.fone) {
    raise LibHyperError::ComplexResult("square root of a negative number")
  }
  let p = wp(prec) + 16
  let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1)
  let mut a = @mpf.fone
  let mut b = try! @mpf.mpf_sqrt(
    @mpf.mpf_sub(@mpf.fone, m, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let mut sum = @mpf.mpf_shift(@mpf.mpf_pos(m, p, @mpf.round_nearest), -1)
  let mut factor = @mpf.from_int(1)
  for _ in 0..<80 {
    let c = @mpf.mpf_shift(@mpf.mpf_sub(a, b, p, @mpf.round_nearest), -1)
    let c2 = @mpf.mpf_mul(c, c, p, @mpf.round_nearest)
    sum = @mpf.mpf_add(
      sum,
      @mpf.mpf_mul(factor, c2, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let next_a = @mpf.mpf_shift(@mpf.mpf_add(a, b, p, @mpf.round_nearest), -1)
    let next_b = try! @mpf.mpf_sqrt(
      @mpf.mpf_mul(a, b, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    a = next_a
    b = next_b
    factor = @mpf.mpf_mul_int(factor, 2, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(c2, p, @mpf.round_nearest), p + 10) {
      break
    }
  }
  let k = try! @mpf.mpf_div(half_pi, a, p, @mpf.round_nearest)
  let e = @mpf.mpf_mul(
    k,
    @mpf.mpf_sub(@mpf.fone, sum, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(e, prec, rnd)
}

///|
pub fn mpf_agm1(
  a : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  mpf_agm(@mpf.fone, a, prec, rnd)
}

///|
pub fn mpf_e1(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise LibHyperError {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_zero(x) {
    return @mpf.finf
  }
  if x.sign == 1 {
    raise LibHyperError::ComplexResult("E1(x) for x < 0")
  }
  @mpf.mpf_pos(
    @mpf.mpf_neg(
      mpf_ei(
        @mpf.mpf_neg(x, wp(prec) + 8, @mpf.round_nearest),
        wp(prec) + 8,
        @mpf.round_nearest,
      ),
      wp(prec) + 8,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
pub fn mpf_erf(
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
  if @mpf.is_zero(x) {
    return @mpf.fzero
  }
  let p = wp(prec) + 16
  let ax = @mpf.mpf_abs(x, p, @mpf.round_nearest)
  let x2 = @mpf.mpf_mul(ax, ax, p, @mpf.round_nearest)
  let mut term = ax
  let mut sum = ax
  let mut k = 0
  while k < 60000 {
    let num = 2 * k + 1
    let den1 = k + 1
    let den2 = 2 * k + 3
    term = @mpf.mpf_mul(term, x2, p, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, -num, p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(term, @mpf.from_int(den1), p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(term, @mpf.from_int(den2), p, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 10) && k > 3 {
      break
    }
    k += 1
  }
  let two_over_sqrt_pi = try! @mpf.mpf_div(
    @mpf.from_int(2),
    try! @mpf.mpf_sqrt(
      @libelefun.mpf_pi(p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let mut v = @mpf.mpf_mul(two_over_sqrt_pi, sum, p, @mpf.round_nearest)
  if x.sign == 1 {
    v = @mpf.mpf_neg(v, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(v, prec, rnd)
}

///|
pub fn mpf_erfc(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      return @mpf.from_int(2)
    } else {
      return @mpf.fzero
    }
  }
  let p = wp(prec) + 16
  @mpf.mpf_pos(
    @mpf.mpf_sub(
      @mpf.fone,
      mpf_erf(x, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    prec,
    rnd,
  )
}

///|
fn factorial_mpf(n : Int, p : Int) -> @mpf.RawMpf {
  let mut acc = @mpf.fone
  if n <= 1 {
    return acc
  }
  for i in 2..<=n {
    acc = @mpf.mpf_mul_int(acc, i, p, @mpf.round_nearest)
  }
  acc
}

///|
pub fn mpf_expint(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  gamma? : Bool = false,
) -> @mpf.RawMpf raise LibHyperError {
  if n <= 0 {
    raise LibHyperError::ValueError("mpf_expint: n must be positive")
  }
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if gamma {
    let p = wp(prec) + 16
    if @mpf.is_zero(x) {
      return factorial_mpf(n - 1, p)
    }
    if @mpf.is_inf(x) {
      return if x.sign == 0 { @mpf.fzero } else { @mpf.fnan }
    }
    let ex = @libelefun.mpf_exp(
      @mpf.mpf_neg(x, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let mut sum = @mpf.fone
    let mut term = @mpf.fone
    for k in 1..<n {
      term = @mpf.mpf_mul(term, x, p, @mpf.round_nearest)
      term = try! @mpf.mpf_div(term, @mpf.from_int(k), p, @mpf.round_nearest)
      sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    }
    return @mpf.mpf_pos(
      @mpf.mpf_mul(
        factorial_mpf(n - 1, p),
        @mpf.mpf_mul(ex, sum, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      prec,
      rnd,
    )
  }
  if @mpf.is_inf(x) {
    return if x.sign == 0 { @mpf.fzero } else { @mpf.fnan }
  }
  if @mpf.is_zero(x) {
    if n == 1 {
      return @mpf.finf
    }
    return try! @mpf.mpf_rdiv_int(1, @mpf.from_int(n - 1), prec, rnd)
  }
  let p = wp(prec) + 16
  let mut en = if x.sign == 1 {
    @mpf.mpf_neg(
      mpf_ei(@mpf.mpf_neg(x, p, @mpf.round_nearest), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  } else {
    mpf_e1(x, p, @mpf.round_nearest)
  }
  if n == 1 {
    return @mpf.mpf_pos(en, prec, rnd)
  }
  let ex = @libelefun.mpf_exp(
    @mpf.mpf_neg(x, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let mut k = 1
  while k < n {
    en = try! @mpf.mpf_div(
      @mpf.mpf_sub(
        ex,
        @mpf.mpf_mul(x, en, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      @mpf.from_int(k),
      p,
      @mpf.round_nearest,
    )
    k += 1
  }
  @mpf.mpf_pos(en, prec, rnd)
}

///|
pub fn mpf_besseljn(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    return @mpf.fzero
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
  let half_x = @mpf.mpf_shift(x, -1)
  let x2_over4 = @mpf.mpf_mul(half_x, half_x, p, @mpf.round_nearest)
  let mut term = try! @libelefun.mpf_pow(
    @mpf.mpf_abs(half_x, p, @mpf.round_nearest),
    @mpf.from_int(m),
    p,
    @mpf.round_nearest,
  )
  term = try! @mpf.mpf_div(term, factorial_mpf(m, p), p, @mpf.round_nearest)
  let mut sum = term
  let mut k = 0
  while k < 20000 {
    term = @mpf.mpf_mul(term, x2_over4, p, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, -1, p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(term, @mpf.from_int(k + 1), p, @mpf.round_nearest)
    term = try! @mpf.mpf_div(
      term,
      @mpf.from_int(k + m + 1),
      p,
      @mpf.round_nearest,
    )
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 12) && k > 4 {
      break
    }
    k += 1
  }
  if x.sign == 1 && (m & 1) == 1 {
    sign = 1 - sign
  }
  if sign == 1 {
    @mpf.mpf_neg(sum, prec, rnd)
  } else {
    @mpf.mpf_pos(sum, prec, rnd)
  }
}
