///|
fn ceil_rshift(man : BigInt, n : Int) -> BigInt {
  if n <= 0 {
    man
  } else {
    (man + ((1N << n) - 1N)) >> n
  }
}

///|
fn should_shift_down(rnd : RoundMode, sign : Int) -> Bool {
  match rnd {
    RoundMode::Floor => sign == 0
    RoundMode::Ceiling => sign == 1
    RoundMode::Down => true
    RoundMode::Up => false
    RoundMode::Nearest => true
  }
}

///|
fn round_mantissa(sign : Int, man : BigInt, n : Int, rnd : RoundMode) -> BigInt {
  if n <= 0 {
    man
  } else {
    match rnd {
      RoundMode::Nearest => {
        let t = man >> (n - 1)
        let sticky_mask = (1N << (n - 1)) - 1N
        let tie_break = (t & 2N) == 2N
        let sticky = (man & sticky_mask) != 0N
        if (t & 1N) == 1N && (tie_break || sticky) {
          (t >> 1) + 1N
        } else {
          t >> 1
        }
      }
      _ =>
        if should_shift_down(rnd, sign) {
          man >> n
        } else {
          ceil_rshift(man, n)
        }
    }
  }
}

///|
pub fn normalize(
  sign : Int,
  man : BigInt,
  exp : Int,
  bc : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if man == 0N {
    fzero
  } else {
    let mut m = man
    let mut e = exp
    let mut bits = bc
    if prec > 0 {
      let cut = bits - prec
      if cut > 0 {
        m = round_mantissa(sign, m, cut, rnd)
        e += cut
      }
    }
    if m == 0N {
      fzero
    } else {
      if (m & 1N) == 0N {
        let t = m.ctz()
        m = m >> t
        e += t
      }
      bits = m.bit_length()
      { sign, man: m, exp: e, bc: bits }
    }
  }
}

///|
pub fn from_man_exp(
  man : BigInt,
  exp : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if man == 0N {
    fzero
  } else {
    let sign = if man < 0N { 1 } else { 0 }
    let abs_man = if sign == 1 { -man } else { man }
    let bc = abs_man.bit_length()
    if prec <= 0 {
      normalize(sign, abs_man, exp, bc, 0, rnd)
    } else {
      normalize(sign, abs_man, exp, bc, prec, rnd)
    }
  }
}

///|
pub fn from_int(n : Int) -> RawMpf {
  from_man_exp(BigInt::from_int(n), 0, 0, round_down)
}

///|
pub fn is_zero(x : RawMpf) -> Bool {
  x.man == 0N && x.bc == 0
}

///|
pub fn is_finite(x : RawMpf) -> Bool {
  x.bc >= 0
}

///|
pub fn is_inf(x : RawMpf) -> Bool {
  x.bc == -2 || x.bc == -3
}

///|
pub fn is_nan(x : RawMpf) -> Bool {
  x.bc == -1
}
