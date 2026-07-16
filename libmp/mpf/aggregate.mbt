///|
fn signed_man_for_aggregate(x : RawMpf) -> BigInt {
  if x.sign == 1 {
    -x.man
  } else {
    x.man
  }
}

///|
pub fn RawMpf::sum(
  xs : ArrayView[RawMpf],
  prec : Int,
  rnd : RoundMode,
  absolute? : Bool = false,
) -> RawMpf {
  let mut man = 0N
  let mut exp = 0
  let max_extra_prec = if prec > 0 { prec * 2 } else { 1000000 }
  let mut special : RawMpf? = None
  for x0 in xs {
    let x = if absolute { x0.abs(0, Down) } else { x0 }
    if !x.is_finite() {
      let prev = match special {
        None => RawMpf::zero()
        Some(v) => v
      }
      special = Some(prev.add(x, 1, Nearest))
      continue
    }
    if x.is_zero() {
      continue
    }
    let xm = signed_man_for_aggregate(x)
    if man == 0N {
      man = xm
      exp = x.exp
      continue
    }
    if x.exp >= exp {
      let delta = x.exp - exp
      if delta > max_extra_prec &&
        (man == 0N || delta - man.bit_length() > max_extra_prec) {
        man = xm
        exp = x.exp
      } else {
        man += xm << delta
      }
    } else {
      let delta = exp - x.exp
      if delta - x.bc > max_extra_prec {
        ignore(delta)
      } else {
        man = (man << delta) + xm
        exp = x.exp
      }
    }
  }
  match special {
    Some(v) => v
    None => RawMpf::from_mantissa_exponent(man, exp, prec, rnd)
  }
}

///|
pub fn RawMpf::modulo(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if (!x.is_finite() && !x.is_zero()) || (!y.is_finite() && !y.is_zero()) {
    if y.is_infinite() {
      return x
    }
    return RawMpf::nan()
  }
  if y.is_zero() {
    raise DivisionByZero("RawMpf::modulo: modulo by zero")
  }
  if x.sign == y.sign && y.exp > x.exp + x.bc {
    return x.rounded(prec, rnd)
  }
  if y.man == 1N && x.exp > y.exp + y.bc {
    return RawMpf::zero()
  }
  let base = if x.exp < y.exp { x.exp } else { y.exp }
  let sm = signed_man_for_aggregate(x) << (x.exp - base)
  let tm = signed_man_for_aggregate(y) << (y.exp - base)
  let mut man = sm % tm
  if man != 0N && ((man < 0N && tm > 0N) || (man > 0N && tm < 0N)) {
    man += tm
  }
  let mut sign = 0
  if man < 0N {
    sign = 1
    man = -man
  }
  RawMpf::from_raw_parts(sign, man, base, man.bit_length(), prec, rnd)
}

///|
pub fn RawMpf::hypot(
  x : RawMpf,
  y : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if y == RawMpf::zero() {
    return x.abs(prec, rnd)
  }
  if x == RawMpf::zero() {
    return y.abs(prec, rnd)
  }
  let wp = if prec > 0 { prec + 4 } else { 0 }
  let hypot2 = x.mul(x, 0, Down).add(y.mul(y, 0, Down), wp, Nearest)
  hypot2.sqrt(prec, rnd)
}
