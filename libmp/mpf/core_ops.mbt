///|
pub fn RawMpf::rounded(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if prec <= 0 || !x.is_finite() {
    x
  } else {
    RawMpf::from_raw_parts(x.sign, x.man, x.exp, x.bc, prec, rnd)
  }
}

///|
pub fn RawMpf::negated(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
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
    let sign = 1 - x.sign
    if prec <= 0 {
      { sign, man: x.man, exp: x.exp, bc: x.bc }
    } else {
      RawMpf::from_raw_parts(sign, x.man, x.exp, x.bc, prec, rnd)
    }
  }
}

///|
pub fn RawMpf::abs(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  if x.is_nan() {
    RawMpf::nan()
  } else if x.is_infinite() {
    RawMpf::infinity()
  } else if x.is_zero() {
    x
  } else if x.sign == 0 {
    x.rounded(prec, rnd)
  } else if prec <= 0 {
    { sign: 0, man: x.man, exp: x.exp, bc: x.bc }
  } else {
    RawMpf::from_raw_parts(0, x.man, x.exp, x.bc, prec, rnd)
  }
}

///|
pub fn RawMpf::signum(x : RawMpf) -> Int {
  if x.is_nan() || x.is_zero() {
    0
  } else if x.sign == 1 {
    -1
  } else {
    1
  }
}

///|
pub impl Eq for RawMpf with fn equal(x, y) {
  if x.is_nan() || y.is_nan() {
    false
  } else {
    x.sign == y.sign && x.man == y.man && x.exp == y.exp && x.bc == y.bc
  }
}

///|
pub impl Compare for RawMpf with fn compare(x, y) {
  if x == y {
    return 0
  }
  if y.is_nan() {
    return 1
  }
  if x.is_nan() {
    return -1
  }
  if x.is_infinite() {
    return if x.sign == 1 { -1 } else { 1 }
  }
  if y.is_infinite() {
    return if y.sign == 1 { 1 } else { -1 }
  }
  if x.is_zero() {
    return -y.signum()
  }
  if y.is_zero() {
    return x.signum()
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
pub impl Compare for RawMpf with fn op_lt(x, y) {
  if x.is_nan() || y.is_nan() {
    false
  } else {
    x.compare(y) < 0
  }
}

///|
pub impl Compare for RawMpf with fn op_le(x, y) {
  if x.is_nan() || y.is_nan() {
    false
  } else {
    x.compare(y) <= 0
  }
}

///|
pub impl Compare for RawMpf with fn op_gt(x, y) {
  if x.is_nan() || y.is_nan() {
    false
  } else {
    x.compare(y) > 0
  }
}

///|
pub impl Compare for RawMpf with fn op_ge(x, y) {
  if x.is_nan() || y.is_nan() {
    false
  } else {
    x.compare(y) >= 0
  }
}

///|
pub fn RawMpf::scale_pow2(x : RawMpf, n : Int) -> RawMpf {
  if x.is_zero() || !x.is_finite() {
    x
  } else {
    { sign: x.sign, man: x.man, exp: x.exp + n, bc: x.bc }
  }
}

///|
pub fn RawMpf::mul_int(
  x : RawMpf,
  n : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if n == 0 || !x.is_finite() || x.is_zero() {
    return x.mul(RawMpf::from_int(n), prec, rnd)
  }
  let mut sign = x.sign
  let mut abs_n = n
  if n < 0 {
    sign = 1 - sign
    abs_n = -n
  }
  let man = x.man * BigInt::from_int(abs_n)
  RawMpf::from_raw_parts(sign, man, x.exp, man.bit_length(), prec, rnd)
}

///|
pub fn RawMpf::int_divided_by(
  x : RawMpf,
  n : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if n == 0 || x.is_zero() || !x.is_finite() {
    return RawMpf::from_int(n).div(x, prec, rnd)
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
  RawMpf::from_raw_parts(sign, man, exp, man.bit_length(), target_prec, rnd)
}

///|
fn mpf_round_int_inner(x : RawMpf, mode : RoundMode) -> RawMpf {
  if !x.is_finite() || x.is_zero() || x.exp >= 0 {
    return x
  }
  let shift = -x.exp
  let int_part = x.man >> shift
  let rem_mask = (1N << shift) - 1N
  let rem = x.man & rem_mask
  let has_frac = rem != 0N
  let bump = if has_frac { 1N } else { 0N }
  let signed = match mode {
    Floor => if x.sign == 0 { int_part } else { -(int_part + bump) }
    Ceiling => if x.sign == 0 { int_part + bump } else { -int_part }
    Down => if x.sign == 0 { int_part } else { -int_part }
    Up => if x.sign == 0 { int_part + bump } else { -(int_part + bump) }
    Nearest => {
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
  RawMpf::from_mantissa_exponent(signed, 0, 0, Down)
}

///|
pub fn RawMpf::round_to_integer(x : RawMpf, rnd : RoundMode) -> RawMpf {
  match rnd {
    Floor => mpf_round_int_inner(x, Floor)
    Ceiling => mpf_round_int_inner(x, Ceiling)
    Down => mpf_round_int_inner(x, Down)
    Up => mpf_round_int_inner(x, Up)
    Nearest => mpf_round_int_inner(x, Nearest)
  }
}

///|
pub fn RawMpf::min_max(
  seq : ArrayView[RawMpf],
) -> (RawMpf, RawMpf) raise MpfError {
  if seq.length() == 0 {
    raise ValueError("RawMpf::min_max: empty input")
  }
  let mut min_v = seq[0]
  let mut max_v = seq[0]
  for i in 1..<seq.length() {
    let x = seq[i]
    if x < min_v {
      min_v = x
    }
    if x > max_v {
      max_v = x
    }
  }
  (min_v, max_v)
}

///|
pub fn RawMpf::floor(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  let v = mpf_round_int_inner(x, Floor)
  if prec > 0 {
    v.rounded(prec, rnd)
  } else {
    v
  }
}

///|
pub fn RawMpf::ceil(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  let v = mpf_round_int_inner(x, Ceiling)
  if prec > 0 {
    v.rounded(prec, rnd)
  } else {
    v
  }
}

///|
pub fn RawMpf::nearest_integer(
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  let v = mpf_round_int_inner(x, Nearest)
  if prec > 0 {
    v.rounded(prec, rnd)
  } else {
    v
  }
}

///|
pub fn RawMpf::fractional_part(
  x : RawMpf,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  x.sub(x.floor(0, Down), prec, rnd)
}
