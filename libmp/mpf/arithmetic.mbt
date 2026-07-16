///|
fn signed_man(x : RawMpf) -> BigInt {
  if x.sign == 0 {
    x.man
  } else {
    -x.man
  }
}

///|
fn inf_with_sign(sign : Int) -> RawMpf {
  if sign == 1 {
    RawMpf::negative_infinity()
  } else {
    RawMpf::infinity()
  }
}

///|
fn xor_sign(x : RawMpf, y : RawMpf) -> Int {
  if x.sign == y.sign {
    0
  } else {
    1
  }
}

///|
fn negated(x : RawMpf) -> RawMpf {
  if x.is_nan() {
    RawMpf::nan()
  } else if x.is_infinite() {
    if x.sign == 1 {
      RawMpf::infinity()
    } else {
      RawMpf::negative_infinity()
    }
  } else if x.is_zero() {
    x
  } else {
    { sign: 1 - x.sign, man: x.man, exp: x.exp, bc: x.bc }
  }
}

///|
pub impl Neg for RawMpf with fn neg(x) {
  negated(x)
}

///|
pub fn RawMpf::add(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if x.is_nan() || y.is_nan() {
    return RawMpf::nan()
  }
  if x.is_infinite() || y.is_infinite() {
    if x.is_infinite() && y.is_infinite() {
      if x.sign == y.sign {
        return inf_with_sign(x.sign)
      }
      return RawMpf::nan()
    }
    if x.is_infinite() {
      return inf_with_sign(x.sign)
    }
    return inf_with_sign(y.sign)
  }
  if x.is_zero() {
    return RawMpf::from_raw_parts(y.sign, y.man, y.exp, y.bc, prec, rnd)
  }
  if y.is_zero() {
    return RawMpf::from_raw_parts(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
  let xm = signed_man(x)
  let ym = signed_man(y)
  if x.exp >= y.exp {
    let delta = x.exp - y.exp
    RawMpf::from_mantissa_exponent((xm << delta) + ym, y.exp, prec, rnd)
  } else {
    let delta = y.exp - x.exp
    RawMpf::from_mantissa_exponent(xm + (ym << delta), x.exp, prec, rnd)
  }
}

///|
pub fn RawMpf::sub(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  x.add(negated(y), prec, rnd)
}

///|
pub fn RawMpf::mul(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if x.is_nan() || y.is_nan() {
    return RawMpf::nan()
  }
  if x.is_infinite() || y.is_infinite() {
    if x.is_zero() || y.is_zero() {
      return RawMpf::nan()
    }
    return inf_with_sign(xor_sign(x, y))
  }
  if x.is_zero() || y.is_zero() {
    return RawMpf::zero()
  }
  let sign = xor_sign(x, y)
  let man = x.man * y.man
  RawMpf::from_raw_parts(sign, man, x.exp + y.exp, man.bit_length(), prec, rnd)
}

///|
pub fn RawMpf::div(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if x.is_nan() || y.is_nan() {
    return RawMpf::nan()
  }
  if x.is_zero() {
    if y.is_zero() {
      raise DivisionByZero("RawMpf::div: division by zero")
    }
    return RawMpf::zero()
  }
  if y.is_zero() {
    raise DivisionByZero("RawMpf::div: division by zero")
  }
  if x.is_infinite() && y.is_infinite() {
    return RawMpf::nan()
  }
  if x.is_infinite() {
    return inf_with_sign(xor_sign(x, y))
  }
  if y.is_infinite() {
    return RawMpf::zero()
  }
  let target_prec = if prec > 0 { prec } else { 1 }
  let sign = xor_sign(x, y)
  let d = y.bc - x.bc + 1
  let extra = if d > 0 { d } else { 0 }
  let p = target_prec + 8 + extra
  let num = x.man << p
  let q = num / y.man
  let r = num % y.man
  let sticky = if r == 0N { 0N } else { 1N }
  let man = (q << 1) + sticky
  let exp = x.exp - y.exp - p - 1
  RawMpf::from_raw_parts(sign, man, exp, man.bit_length(), target_prec, rnd)
}
