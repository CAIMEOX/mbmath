///|
fn reciprocal_round(rnd : RoundMode) -> RoundMode {
  match rnd {
    RoundMode::Down => round_up
    RoundMode::Up => round_down
    RoundMode::Floor => round_ceiling
    RoundMode::Ceiling => round_floor
    RoundMode::Nearest => round_nearest
  }
}

///|
fn big_pow(base : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("mpf_pow_int: exponent must be non-negative")
  }
  let mut result = 1N
  let mut b = base
  let mut e = n
  while e > 0 {
    if (e & 1) == 1 {
      result = result * b
    }
    e = e / 2
    if e > 0 {
      b = b * b
    }
  }
  result
}

///|
fn bigint_isqrt(n : BigInt) -> BigInt {
  if n <= 0N {
    0N
  } else if n == 1N {
    1N
  } else {
    let mut x = 1N << ((n.bit_length() + 1) / 2)
    while x > n / x {
      x = (x + n / x) >> 1
    } else {
      x
    }
  }
}

///|
fn bigint_isqrt_rem(n : BigInt) -> (BigInt, BigInt) {
  let r = bigint_isqrt(n)
  (r, n - r * r)
}

///|
pub fn mpf_pow_int(x : RawMpf, n : Int, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_inf(x) {
    if n > 0 {
      if x.sign == 1 && (n & 1) == 1 {
        return fninf
      }
      return finf
    } else if n == 0 {
      return fone
    } else {
      return fzero
    }
  }
  if is_nan(x) {
    if n == 0 {
      return fone
    }
    return fnan
  }
  if n == 0 {
    return fone
  }
  if n == 1 {
    return normalize(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
  if n == -1 {
    return mpf_div(fone, x, prec, rnd)
  }
  if n < 0 {
    let inverse = mpf_pow_int(x, -n, prec + 5, reciprocal_round(rnd))
    return mpf_div(fone, inverse, prec, rnd)
  }
  if is_zero(x) {
    return fzero
  }
  let sign = if x.sign == 1 && (n & 1) == 1 { 1 } else { 0 }
  let man = big_pow(x.man, n)
  normalize(sign, man, x.exp * n, man.bit_length(), prec, rnd)
}

///|
pub fn mpf_sqrt(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_nan(x) {
    return fnan
  }
  if is_inf(x) {
    if x.sign == 1 {
      abort("mpf_sqrt: square root of a negative number")
    }
    return finf
  }
  if x.sign == 1 {
    abort("mpf_sqrt: square root of a negative number")
  }
  if is_zero(x) {
    return x
  }
  let mut man = x.man
  let mut exp = x.exp
  let mut bc = x.bc
  if (exp & 1) == 1 {
    exp -= 1
    man = man << 1
    bc += 1
  } else if man == 1N {
    return normalize(0, man, exp / 2, bc, prec, rnd)
  }
  let target_prec = if prec > 0 { prec } else { bc }
  let mut shift = 2 * target_prec - bc + 4
  if shift < 4 {
    shift = 4
  }
  if (shift & 1) == 1 {
    shift += 1
  }
  let scaled = man << shift
  let (root0, rem) = bigint_isqrt_rem(scaled)
  let mut root = root0
  if rnd != round_floor && rnd != round_down && rem != 0N {
    root = (root << 1) + 1N
    shift += 2
  }
  from_man_exp(root, (exp - shift) / 2, target_prec, rnd)
}
