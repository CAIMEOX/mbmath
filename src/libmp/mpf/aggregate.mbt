///|
fn signed_man_for_aggregate(x : RawMpf) -> BigInt {
  if x.sign == 1 {
    -x.man
  } else {
    x.man
  }
}

///|
pub fn mpf_sum(
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
    let x = if absolute { mpf_abs(x0, 0, round_down) } else { x0 }
    if !is_finite(x) {
      let prev = match special {
        None => fzero
        Some(v) => v
      }
      special = Some(mpf_add(prev, x, 1, round_nearest))
      continue
    }
    if is_zero(x) {
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
    None => from_man_exp(man, exp, prec, rnd)
  }
}

///|
pub fn mpf_mod(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if (!is_finite(x) && !is_zero(x)) || (!is_finite(y) && !is_zero(y)) {
    if is_inf(y) {
      return x
    }
    return fnan
  }
  if is_zero(y) {
    abort("mpf_mod: modulo by zero")
  }
  if x.sign == y.sign && y.exp > x.exp + x.bc {
    return mpf_pos(x, prec, rnd)
  }
  if y.man == 1N && x.exp > y.exp + y.bc {
    return fzero
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
  normalize(sign, man, base, man.bit_length(), prec, rnd)
}

///|
pub fn mpf_hypot(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if y == fzero {
    return mpf_abs(x, prec, rnd)
  }
  if x == fzero {
    return mpf_abs(y, prec, rnd)
  }
  let wp = if prec > 0 { prec + 4 } else { 0 }
  let hypot2 = mpf_add(
    mpf_mul(x, x, 0, round_down),
    mpf_mul(y, y, 0, round_down),
    wp,
    round_nearest,
  )
  mpf_sqrt(hypot2, prec, rnd)
}
