///|
let euler_gamma : @mpf.RawMpf = @mpf.from_str(
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
pub fn mpf_agm(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(x) || @mpf.is_nan(y) {
    return @mpf.fnan
  }
  if x.sign == 1 || y.sign == 1 {
    abort("mpf_agm: negative input")
  }
  if @mpf.is_zero(x) || @mpf.is_zero(y) {
    return @mpf.fzero
  }
  let p = if prec > 0 { prec + 12 } else { 64 }
  let mut a = @mpf.mpf_pos(x, p, @mpf.round_nearest)
  let mut b = @mpf.mpf_pos(y, p, @mpf.round_nearest)
  for _ in 0..<64 {
    let next_a = @mpf.mpf_shift(@mpf.mpf_add(a, b, p, @mpf.round_nearest), -1)
    let next_b = @mpf.mpf_sqrt(
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
pub fn mpf_si(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_zero(x) {
    return @mpf.fzero
  }
  if @mpf.is_inf(x) {
    let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(prec, rnd), -1)
    if x.sign == 1 {
      return @mpf.mpf_neg(half_pi, prec, rnd)
    } else {
      return half_pi
    }
  }
  let p = wp(prec) + 8
  let x_abs = @mpf.mpf_abs(x, p, @mpf.round_nearest)
  let x2 = @mpf.mpf_mul(x_abs, x_abs, p, @mpf.round_nearest)
  let mut term = x_abs
  let mut sum = x_abs
  let mut k = 0
  while k < 40000 {
    let num = 2 * k + 1
    let den1 = 2 * k + 2
    let den2 = 2 * k + 3
    term = @mpf.mpf_mul(term, x2, p, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, -num, p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den1), p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den2), p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den2), p, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 10) && k > 3 {
      break
    }
    k += 1
  }
  if x.sign == 1 {
    @mpf.mpf_neg(sum, prec, rnd)
  } else {
    @mpf.mpf_pos(sum, prec, rnd)
  }
}

///|
pub fn mpf_ci(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    return @mpf.fnan
  }
  if @mpf.is_inf(x) {
    if x.sign == 1 {
      abort("mpf_ci: non-positive input")
    }
    return @mpf.fzero
  }
  if @mpf.is_zero(x) || x.sign == 1 {
    abort("mpf_ci: non-positive input")
  }
  let p = wp(prec) + 8
  let ln_x = @libelefun.mpf_ln(x, p, @mpf.round_nearest)
  let mut sum = @mpf.mpf_add(euler_gamma, ln_x, p, @mpf.round_nearest)
  let x2 = @mpf.mpf_mul(x, x, p, @mpf.round_nearest)
  let mut term = @mpf.mpf_neg(
    @mpf.mpf_div(x2, @mpf.from_int(4), p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
  let mut k = 1
  while k < 40000 {
    if tiny_enough(@mpf.mpf_abs(term, p, @mpf.round_nearest), p + 10) && k > 2 {
      break
    }
    let num = 2 * k
    let den1 = 2 * k + 1
    let den2 = 2 * k + 2
    term = @mpf.mpf_mul(term, x2, p, @mpf.round_nearest)
    term = @mpf.mpf_mul_int(term, -num, p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den1), p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den2), p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(den2), p, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, p, @mpf.round_nearest)
    k += 1
  }
  @mpf.mpf_pos(sum, prec, rnd)
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
    abort("mpf_ei: singularity at zero")
  }
  let p = wp(prec) + 8
  let abs_x = @mpf.mpf_abs(x, p, @mpf.round_nearest)
  let mut sum = @mpf.mpf_add(
    euler_gamma,
    @libelefun.mpf_ln(abs_x, p, @mpf.round_nearest),
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
    term = @mpf.mpf_div(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
    term = @mpf.mpf_div(term, @mpf.from_int(kp1), p, @mpf.round_nearest)
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
) -> @mpf.RawMpf {
  if @mpf.is_nan(m) {
    return @mpf.fnan
  }
  if @mpf.mpf_ge(m, @mpf.fone) {
    abort("mpf_ellipk: m must be < 1")
  }
  let p = wp(prec)
  let t = @mpf.mpf_sub(@mpf.fone, m, p, @mpf.round_nearest)
  let root = @mpf.mpf_sqrt(t, p, @mpf.round_nearest)
  let agm = mpf_agm(@mpf.fone, root, p, @mpf.round_nearest)
  let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1)
  @mpf.mpf_pos(@mpf.mpf_div(half_pi, agm, p, @mpf.round_nearest), prec, rnd)
}

///|
pub fn mpf_ellipe(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  if @mpf.is_nan(m) {
    return @mpf.fnan
  }
  if @mpf.mpf_ge(m, @mpf.fone) {
    abort("mpf_ellipe: m must be < 1")
  }
  let p = wp(prec) + 16
  let half_pi = @mpf.mpf_shift(@libelefun.mpf_pi(p, @mpf.round_nearest), -1)
  let mut a = @mpf.fone
  let mut b = @mpf.mpf_sqrt(
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
    let next_b = @mpf.mpf_sqrt(
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
  let k = @mpf.mpf_div(half_pi, a, p, @mpf.round_nearest)
  let e = @mpf.mpf_mul(
    k,
    @mpf.mpf_sub(@mpf.fone, sum, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_pos(e, prec, rnd)
}
