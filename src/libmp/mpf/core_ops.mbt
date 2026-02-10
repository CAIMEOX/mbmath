///|
pub fn mpf_pos(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if prec <= 0 || !is_finite(x) {
    x
  } else {
    normalize(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
}

///|
pub fn mpf_neg(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
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
    let sign = 1 - x.sign
    if prec <= 0 {
      { sign, man: x.man, exp: x.exp, bc: x.bc }
    } else {
      normalize(sign, x.man, x.exp, x.bc, prec, rnd)
    }
  }
}

///|
pub fn mpf_abs(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if is_nan(x) {
    fnan
  } else if is_inf(x) {
    finf
  } else if is_zero(x) {
    x
  } else if x.sign == 0 {
    mpf_pos(x, prec, rnd)
  } else if prec <= 0 {
    { sign: 0, man: x.man, exp: x.exp, bc: x.bc }
  } else {
    normalize(0, x.man, x.exp, x.bc, prec, rnd)
  }
}

///|
pub fn mpf_sign(x : RawMpf) -> Int {
  if is_nan(x) || is_zero(x) {
    0
  } else if x.sign == 1 {
    -1
  } else {
    1
  }
}

///|
pub fn mpf_eq(x : RawMpf, y : RawMpf) -> Bool {
  if is_nan(x) || is_nan(y) {
    false
  } else {
    x == y
  }
}

///|
pub fn mpf_cmp(x : RawMpf, y : RawMpf) -> Int {
  if x == y {
    return 0
  }
  if is_nan(y) {
    return 1
  }
  if is_nan(x) {
    return -1
  }
  if is_inf(x) {
    return if x.sign == 1 { -1 } else { 1 }
  }
  if is_inf(y) {
    return if y.sign == 1 { 1 } else { -1 }
  }
  if is_zero(x) {
    return -mpf_sign(y)
  }
  if is_zero(y) {
    return mpf_sign(x)
  }
  if x.sign != y.sign {
    return if x.sign == 1 { -1 } else { 1 }
  }
  let sign_factor = if x.sign == 1 { -1 } else { 1 }
  let x_top = x.bc + x.exp
  let y_top = y.bc + y.exp
  if x_top > y_top {
    return sign_factor
  }
  if x_top < y_top {
    return -sign_factor
  }
  if x.exp == y.exp {
    if x.man > y.man {
      sign_factor
    } else {
      -sign_factor
    }
  } else if x.exp > y.exp {
    let lhs = x.man << (x.exp - y.exp)
    if lhs > y.man {
      sign_factor
    } else {
      -sign_factor
    }
  } else {
    let rhs = y.man << (y.exp - x.exp)
    if x.man > rhs {
      sign_factor
    } else {
      -sign_factor
    }
  }
}

///|
pub fn mpf_lt(x : RawMpf, y : RawMpf) -> Bool {
  if is_nan(x) || is_nan(y) {
    false
  } else {
    mpf_cmp(x, y) < 0
  }
}

///|
pub fn mpf_le(x : RawMpf, y : RawMpf) -> Bool {
  if is_nan(x) || is_nan(y) {
    false
  } else {
    mpf_cmp(x, y) <= 0
  }
}

///|
pub fn mpf_gt(x : RawMpf, y : RawMpf) -> Bool {
  if is_nan(x) || is_nan(y) {
    false
  } else {
    mpf_cmp(x, y) > 0
  }
}

///|
pub fn mpf_ge(x : RawMpf, y : RawMpf) -> Bool {
  if is_nan(x) || is_nan(y) {
    false
  } else {
    mpf_cmp(x, y) >= 0
  }
}

///|
pub fn mpf_shift(x : RawMpf, n : Int) -> RawMpf {
  if is_zero(x) || !is_finite(x) {
    x
  } else {
    { sign: x.sign, man: x.man, exp: x.exp + n, bc: x.bc }
  }
}

///|
pub fn mpf_mul_int(x : RawMpf, n : Int, prec : Int, rnd : RoundMode) -> RawMpf {
  if n == 0 || !is_finite(x) || is_zero(x) {
    return mpf_mul(x, from_int(n), prec, rnd)
  }
  let mut sign = x.sign
  let mut abs_n = n
  if n < 0 {
    sign = 1 - sign
    abs_n = -n
  }
  let man = x.man * BigInt::from_int(abs_n)
  normalize(sign, man, x.exp, man.bit_length(), prec, rnd)
}

///|
pub fn mpf_rdiv_int(
  n : Int,
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if n == 0 || is_zero(x) || !is_finite(x) {
    return mpf_div(from_int(n), x, prec, rnd)
  }
  let mut sign = x.sign
  let mut abs_n = n
  if n < 0 {
    sign = 1 - sign
    abs_n = -n
  }
  let target_prec = if prec > 0 { prec } else { 1 }
  let mut extra = target_prec + x.bc + 5
  let numerator = BigInt::from_int(abs_n) << extra
  let q = numerator / x.man
  let r = numerator % x.man
  let mut man = q
  if r != 0N {
    man = (man << 1) + 1N
    extra += 1
  }
  let exp = -x.exp - extra
  normalize(sign, man, exp, man.bit_length(), target_prec, rnd)
}

///|
fn mpf_round_int_inner(x : RawMpf, mode : RoundMode) -> RawMpf {
  if !is_finite(x) || is_zero(x) || x.exp >= 0 {
    return x
  }
  let shift = -x.exp
  let int_part = x.man >> shift
  let rem_mask = (1N << shift) - 1N
  let rem = x.man & rem_mask
  let has_frac = rem != 0N
  let bump = if has_frac { 1N } else { 0N }
  let signed = match mode {
    RoundMode::Floor => if x.sign == 0 { int_part } else { -(int_part + bump) }
    RoundMode::Ceiling => if x.sign == 0 { int_part + bump } else { -int_part }
    RoundMode::Down => if x.sign == 0 { int_part } else { -int_part }
    RoundMode::Up => if x.sign == 0 { int_part + bump } else { -(int_part + bump) }
    RoundMode::Nearest => {
      let half = 1N << (shift - 1)
      let nearest = if rem > half || (rem == half && (int_part & 1N) == 1N) {
        int_part + 1N
      } else {
        int_part
      }
      if x.sign == 1 {
        -nearest
      } else {
        nearest
      }
    }
  }
  from_man_exp(signed, 0, 0, round_down)
}

///|
pub fn mpf_round_int(x : RawMpf, rnd : RoundMode) -> RawMpf {
  match rnd {
    RoundMode::Floor => mpf_round_int_inner(x, round_floor)
    RoundMode::Ceiling => mpf_round_int_inner(x, round_ceiling)
    RoundMode::Down => mpf_round_int_inner(x, round_down)
    RoundMode::Up => mpf_round_int_inner(x, round_up)
    RoundMode::Nearest => mpf_round_int_inner(x, round_nearest)
  }
}

///|
pub fn mpf_min_max(seq : ArrayView[RawMpf]) -> (RawMpf, RawMpf) raise MpfError {
  if seq.length() == 0 {
    raise MpfError::ValueError("mpf_min_max: empty input")
  }
  let mut min_v = seq[0]
  let mut max_v = seq[0]
  for i in 1..<seq.length() {
    let x = seq[i]
    if mpf_lt(x, min_v) {
      min_v = x
    }
    if mpf_gt(x, max_v) {
      max_v = x
    }
  }
  (min_v, max_v)
}

///|
pub fn mpf_floor(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  let v = mpf_round_int_inner(x, round_floor)
  if prec > 0 {
    mpf_pos(v, prec, rnd)
  } else {
    v
  }
}

///|
pub fn mpf_ceil(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  let v = mpf_round_int_inner(x, round_ceiling)
  if prec > 0 {
    mpf_pos(v, prec, rnd)
  } else {
    v
  }
}

///|
pub fn mpf_nint(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  let v = mpf_round_int_inner(x, round_nearest)
  if prec > 0 {
    mpf_pos(v, prec, rnd)
  } else {
    v
  }
}

///|
pub fn mpf_frac(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  mpf_sub(x, mpf_floor(x, 0, round_down), prec, rnd)
}
