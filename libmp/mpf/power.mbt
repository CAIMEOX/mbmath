///|
fn reciprocal_round(rnd : RoundMode) -> RoundMode {
  match rnd {
    Down => Up
    Up => Down
    Floor => Ceiling
    Ceiling => Floor
    Nearest => Nearest
  }
}

///|
fn big_pow(base : BigInt, n : Int) -> BigInt raise MpfError {
  if n < 0 {
    raise ValueError("RawMpf::pow_int: exponent must be non-negative")
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
    } nobreak {
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
pub fn RawMpf::pow_int(
  x : RawMpf,
  n : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if x.is_infinite() {
    if n > 0 {
      if x.sign == 1 && (n & 1) == 1 {
        return RawMpf::negative_infinity()
      }
      return RawMpf::infinity()
    } else if n == 0 {
      return RawMpf::one()
    } else {
      return RawMpf::zero()
    }
  }
  if x.is_nan() {
    if n == 0 {
      return RawMpf::one()
    }
    return RawMpf::nan()
  }
  if n == 0 {
    return RawMpf::one()
  }
  if n == 1 {
    return RawMpf::from_raw_parts(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
  if n == -1 {
    return RawMpf::one().div(x, prec, rnd)
  }
  if n < 0 {
    let inverse = x.pow_int(-n, prec + 5, reciprocal_round(rnd))
    return RawMpf::one().div(inverse, prec, rnd)
  }
  if x.is_zero() {
    return RawMpf::zero()
  }
  let sign = if x.sign == 1 && (n & 1) == 1 { 1 } else { 0 }
  let man = big_pow(x.man, n)
  RawMpf::from_raw_parts(sign, man, x.exp * n, man.bit_length(), prec, rnd)
}

///|
pub fn RawMpf::sqrt(
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if x.is_nan() {
    return RawMpf::nan()
  }
  if x.is_infinite() {
    if x.sign == 1 {
      raise DomainError("RawMpf::sqrt: square root of a negative number")
    }
    return RawMpf::infinity()
  }
  if x.sign == 1 {
    raise DomainError("RawMpf::sqrt: square root of a negative number")
  }
  if x.is_zero() {
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
    return RawMpf::from_raw_parts(0, man, exp / 2, bc, prec, rnd)
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
  if rnd != Floor && rnd != Down && rem != 0N {
    root = (root << 1) + 1N
    shift += 2
  }
  RawMpf::from_mantissa_exponent(root, (exp - shift) / 2, target_prec, rnd)
}
