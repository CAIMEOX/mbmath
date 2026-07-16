///|
let log2_10 : Double = 3.3219280948873626

///|
/// Return the number of reliable decimal digits represented by `bits` binary
/// precision bits, following mpmath's precision conversion convention.
pub fn precision_to_decimal_digits(bits : Int) -> Int {
  ((Double::from_int(bits) / log2_10).round().to_int() - 1).max(1)
}

///|
/// Return the binary precision required for `digits` reliable decimal digits.
pub fn decimal_digits_to_precision(digits : Int) -> Int {
  (Double::from_int(digits + 1) * log2_10).round().to_int().max(1)
}

///|
/// Return enough decimal digits to reconstruct a value at `bits` precision.
pub fn representation_digits(bits : Int) -> Int {
  let digits = precision_to_decimal_digits(bits)
  if digits == 15 {
    17
  } else {
    digits + 3
  }
}

///|
/// Exact binary representation of two.
pub fn RawMpf::two() -> RawMpf {
  RawMpf::from_mantissa_exponent(1N, 1, 0, Down)
}

///|
/// Exact binary representation of ten.
pub fn RawMpf::ten() -> RawMpf {
  RawMpf::from_mantissa_exponent(5N, 1, 0, Down)
}

///|
/// Exact binary representation of one half.
pub fn RawMpf::half() -> RawMpf {
  RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
}

///|
/// Construct an exact arbitrary-precision float from an arbitrary-size integer.
pub fn RawMpf::from_bigint(value : BigInt) -> RawMpf {
  RawMpf::from_mantissa_exponent(value, 0, 0, Down)
}

///|
/// Return the canonical `(mantissa, exponent)` pair for a finite value.
///
/// The mantissa is signed by default. Passing `signed=false` returns the
/// non-negative stored mantissa separately from the value's sign field.
pub fn RawMpf::mantissa_exponent(
  x : RawMpf,
  signed? : Bool = true,
) -> (BigInt, Int) raise MpfError {
  if !x.is_finite() {
    raise ValueError("RawMpf::mantissa_exponent: finite value required")
  }
  let man = if signed && x.sign == 1 { -x.man } else { x.man }
  (man, x.exp)
}

///|
fn round_scaled_integer(
  sign : Int,
  man : BigInt,
  exp : Int,
  rnd : RoundMode,
) -> BigInt {
  if man == 0N {
    return 0N
  }
  if exp >= 0 {
    let value = man << exp
    return if sign == 1 { -value } else { value }
  }
  if exp < -man.bit_length() {
    let magnitude = match rnd {
      Nearest => 0N
      Down => 0N
      Up => 1N
      Floor => if sign == 1 { 1N } else { 0N }
      Ceiling => if sign == 0 { 1N } else { 0N }
    }
    return if sign == 1 { -magnitude } else { magnitude }
  }
  let shift = -exp
  let quotient = man >> shift
  let remainder = man - (quotient << shift)
  let increment = if remainder == 0N {
    false
  } else {
    match rnd {
      Down => false
      Up => true
      Floor => sign == 1
      Ceiling => sign == 0
      Nearest => {
        let half = 1N << (shift - 1)
        remainder > half || (remainder == half && (quotient & 1N) == 1N)
      }
    }
  }
  let magnitude = if increment { quotient + 1N } else { quotient }
  if sign == 1 {
    -magnitude
  } else {
    magnitude
  }
}

///|
/// Convert a finite value to an arbitrary-size integer with explicit rounding.
pub fn RawMpf::to_integer(
  x : RawMpf,
  rnd? : RoundMode = Down,
) -> BigInt raise MpfError {
  if x.is_nan() {
    raise ValueError("RawMpf::to_integer: cannot convert nan")
  }
  if x.is_infinite() {
    raise OverflowError("RawMpf::to_integer: cannot convert infinity")
  }
  round_scaled_integer(x.sign, x.man, x.exp, rnd)
}

///|
/// Construct `numerator / denominator`, rounded to `prec` binary bits.
pub fn RawMpf::from_ratio(
  numerator : BigInt,
  denominator : BigInt,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  if denominator == 0N {
    raise DivisionByZero("RawMpf::from_ratio: zero denominator")
  }
  let normalized_numerator = if denominator < 0N {
    -numerator
  } else {
    numerator
  }
  let normalized_denominator = if denominator < 0N {
    -denominator
  } else {
    denominator
  }
  RawMpf::from_bigint(normalized_numerator).div(
    RawMpf::from_bigint(normalized_denominator),
    prec,
    rnd,
  )
}

///|
/// Return an exact reduced dyadic ratio `(numerator, denominator)`.
pub fn RawMpf::to_ratio(x : RawMpf) -> (BigInt, BigInt) raise MpfError {
  if x.is_nan() {
    raise ValueError("RawMpf::to_ratio: cannot convert nan")
  }
  if x.is_infinite() {
    raise OverflowError("RawMpf::to_ratio: cannot convert infinity")
  }
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  if x.exp >= 0 {
    (signed_man << x.exp, 1N)
  } else {
    (signed_man, 1N << -x.exp)
  }
}

///|
/// Convert `x * 2^precision` to a fixed-point integer using floor rounding.
pub fn RawMpf::to_fixed(x : RawMpf, precision : Int) -> BigInt raise MpfError {
  if !x.is_finite() {
    raise ValueError("RawMpf::to_fixed: finite value required")
  }
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  let offset = x.exp + precision
  if offset >= 0 {
    signed_man << offset
  } else {
    signed_man >> -offset
  }
}

///|
/// Construct a value from the exact IEEE-754 binary64 representation.
pub fn RawMpf::from_double(
  value : Double,
  prec? : Int = 53,
  rnd? : RoundMode = Nearest,
) -> RawMpf {
  let bits = value.reinterpret_as_uint64()
  let sign = if bits >> 63 == 0UL { 0 } else { 1 }
  let exponent_field = ((bits >> 52) & 0x7ffUL).to_int()
  let fraction = bits & 0x000fffffffffffffUL
  if exponent_field == 0x7ff {
    if fraction != 0UL {
      RawMpf::nan()
    } else if sign == 1 {
      RawMpf::negative_infinity()
    } else {
      RawMpf::infinity()
    }
  } else if exponent_field == 0 {
    if fraction == 0UL {
      RawMpf::zero()
    } else {
      RawMpf::from_raw_parts(
        sign,
        BigInt::from_uint64(fraction),
        -1074,
        64 - fraction.clz(),
        prec,
        rnd,
      )
    }
  } else {
    let man = BigInt::from_uint64(fraction | 0x0010000000000000UL)
    RawMpf::from_raw_parts(sign, man, exponent_field - 1075, 53, prec, rnd)
  }
}

///|
fn double_overflow(
  sign : Int,
  rnd : RoundMode,
  strict : Bool,
) -> Double raise MpfError {
  if strict {
    raise OverflowError("RawMpf::to_double: value outside binary64 range")
  }
  let infinite = match rnd {
    Nearest => true
    Up => true
    Down => false
    Floor => sign == 1
    Ceiling => sign == 0
  }
  let magnitude = if infinite {
    0x7ff0000000000000UL
  } else {
    0x7fefffffffffffffUL
  }
  let sign_bits = if sign == 1 { 0x8000000000000000UL } else { 0UL }
  (sign_bits | magnitude).reinterpret_as_double()
}

///|
/// Convert to IEEE-754 binary64 with explicit rounding and overflow policy.
///
/// `strict=true` raises `MpfError::OverflowError` instead of returning an
/// infinity or the largest finite value when the result exceeds binary64.
pub fn RawMpf::to_double(
  x : RawMpf,
  rnd? : RoundMode = Nearest,
  strict? : Bool = false,
) -> Double raise MpfError {
  if x.is_nan() {
    return 0x7ff8000000000000UL.reinterpret_as_double()
  }
  if x.is_infinite() {
    let bits = if x.sign == 1 {
      0xfff0000000000000UL
    } else {
      0x7ff0000000000000UL
    }
    return bits.reinterpret_as_double()
  }
  if x.is_zero() {
    return 0.0
  }
  let top = x.exp + x.bc - 1
  if top > 1023 {
    return double_overflow(x.sign, rnd, strict)
  }
  if top < -1022 {
    let scaled = round_scaled_integer(x.sign, x.man, x.exp + 1074, rnd)
    let magnitude = if scaled < 0N { -scaled } else { scaled }
    if magnitude >= 1N << 52 {
      let bits = (if x.sign == 1 { 0x8000000000000000UL } else { 0UL }) |
        0x0010000000000000UL
      return bits.reinterpret_as_double()
    }
    let sign_bits = if x.sign == 1 { 0x8000000000000000UL } else { 0UL }
    return (sign_bits | magnitude.to_uint64()).reinterpret_as_double()
  }
  let rounded = x.rounded(53, rnd)
  let rounded_top = rounded.exp + rounded.bc - 1
  if rounded_top > 1023 {
    return double_overflow(x.sign, rnd, strict)
  }
  let significand = rounded.man << (53 - rounded.bc)
  let fraction = significand - (1N << 52)
  let exponent_bits = BigInt::from_int(rounded_top + 1023).to_uint64() << 52
  let sign_bits = if rounded.sign == 1 { 0x8000000000000000UL } else { 0UL }
  (sign_bits | exponent_bits | fraction.to_uint64()).reinterpret_as_double()
}
