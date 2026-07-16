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
    Floor => sign == 0
    Ceiling => sign == 1
    Down => true
    Up => false
    Nearest => true
  }
}

///|
fn round_mantissa(sign : Int, man : BigInt, n : Int, rnd : RoundMode) -> BigInt {
  if n <= 0 {
    man
  } else {
    match rnd {
      Nearest => {
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
pub fn RawMpf::from_raw_parts(
  sign : Int,
  man : BigInt,
  exp : Int,
  bc : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if man == 0N {
    RawMpf::zero()
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
      RawMpf::zero()
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
pub fn RawMpf::from_mantissa_exponent(
  man : BigInt,
  exp : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if man == 0N {
    RawMpf::zero()
  } else {
    let sign = if man < 0N { 1 } else { 0 }
    let abs_man = if sign == 1 { -man } else { man }
    let bc = abs_man.bit_length()
    if prec <= 0 {
      RawMpf::from_raw_parts(sign, abs_man, exp, bc, 0, rnd)
    } else {
      RawMpf::from_raw_parts(sign, abs_man, exp, bc, prec, rnd)
    }
  }
}

///|
pub fn RawMpf::from_int(n : Int) -> RawMpf {
  RawMpf::from_mantissa_exponent(BigInt::from_int(n), 0, 0, Down)
}

///|
pub fn RawMpf::is_zero(x : RawMpf) -> Bool {
  x.man == 0N && x.bc == 0
}

///|
pub fn RawMpf::is_finite(x : RawMpf) -> Bool {
  x.bc >= 0
}

///|
pub fn RawMpf::is_infinite(x : RawMpf) -> Bool {
  x.bc == -2 || x.bc == -3
}

///|
pub fn RawMpf::is_nan(x : RawMpf) -> Bool {
  x.bc == -1
}
