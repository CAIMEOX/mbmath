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
    fninf
  } else {
    finf
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
  if is_nan(x) {
    fnan
  } else if is_inf(x) {
    if x.sign == 1 {
      finf
    } else {
      fninf
    }
  } else if is_zero(x) {
    x
  } else {
    { sign: 1 - x.sign, man: x.man, exp: x.exp, bc: x.bc }
  }
}

///|
pub fn mpf_add(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_nan(x) || is_nan(y) {
    return fnan
  }
  if is_inf(x) || is_inf(y) {
    if is_inf(x) && is_inf(y) {
      if x.sign == y.sign {
        return inf_with_sign(x.sign)
      }
      return fnan
    }
    if is_inf(x) {
      return inf_with_sign(x.sign)
    }
    return inf_with_sign(y.sign)
  }
  if is_zero(x) {
    return normalize(y.sign, y.man, y.exp, y.bc, prec, rnd)
  }
  if is_zero(y) {
    return normalize(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
  let xm = signed_man(x)
  let ym = signed_man(y)
  if x.exp >= y.exp {
    let delta = x.exp - y.exp
    from_man_exp((xm << delta) + ym, y.exp, prec, rnd)
  } else {
    let delta = y.exp - x.exp
    from_man_exp(xm + (ym << delta), x.exp, prec, rnd)
  }
}

///|
pub fn mpf_sub(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  mpf_add(x, negated(y), prec, rnd)
}

///|
pub fn mpf_mul(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_nan(x) || is_nan(y) {
    return fnan
  }
  if is_inf(x) || is_inf(y) {
    if is_zero(x) || is_zero(y) {
      return fnan
    }
    return inf_with_sign(xor_sign(x, y))
  }
  if is_zero(x) || is_zero(y) {
    return fzero
  }
  let sign = xor_sign(x, y)
  let man = x.man * y.man
  normalize(sign, man, x.exp + y.exp, man.bit_length(), prec, rnd)
}

///|
pub fn mpf_div(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_nan(x) || is_nan(y) {
    return fnan
  }
  if is_zero(x) {
    if is_zero(y) {
      abort("mpf_div: division by zero")
    }
    return fzero
  }
  if is_zero(y) {
    abort("mpf_div: division by zero")
  }
  if is_inf(x) && is_inf(y) {
    return fnan
  }
  if is_inf(x) {
    return inf_with_sign(xor_sign(x, y))
  }
  if is_inf(y) {
    return fzero
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
  normalize(sign, man, exp, man.bit_length(), target_prec, rnd)
}
