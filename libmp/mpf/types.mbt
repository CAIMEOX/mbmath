///|
/// Core rounding modes aligned with mpmath's low-level modes:
/// - Nearest: tie-to-even
/// - Floor: towards -inf
/// - Ceiling: towards +inf
/// - Up: away from zero
/// - Down: towards zero
pub(all) enum RoundMode {
  Nearest
  Floor
  Ceiling
  Up
  Down
} derive(Debug, Eq)

///|
/// Raw arbitrary-precision floating-point value:
/// value = (-1)^sign * man * 2^exp
/// Canonical invariant: `man` is non-negative and odd unless it is zero.
pub struct RawMpf {
  sign : Int
  man : BigInt
  exp : Int
  bc : Int
} derive(Debug)

///|
pub(all) suberror MpfError {
  ValueError(String)
  DomainError(String)
  DivisionByZero(String)
  ParseError(String)
  FormatError(String)
  UnsupportedError(String)
} derive(Debug, Eq)

///|
/// Canonical positive zero.
let zero_value : RawMpf = { sign: 0, man: 0N, exp: 0, bc: 0 }

///|
pub fn RawMpf::zero() -> RawMpf {
  zero_value
}

///|
/// Canonical positive one.
let one_value : RawMpf = { sign: 0, man: 1N, exp: 0, bc: 1 }

///|
pub fn RawMpf::one() -> RawMpf {
  one_value
}

///|
/// Canonical negative one.
let negative_one_value : RawMpf = { sign: 1, man: 1N, exp: 0, bc: 1 }

///|
pub fn RawMpf::negative_one() -> RawMpf {
  negative_one_value
}

///|
/// Canonical NaN sentinel.
let nan_value : RawMpf = { sign: 0, man: 0N, exp: -123, bc: -1 }

///|
pub fn RawMpf::nan() -> RawMpf {
  nan_value
}

///|
/// Canonical positive infinity.
let infinity_value : RawMpf = { sign: 0, man: 0N, exp: -456, bc: -2 }

///|
pub fn RawMpf::infinity() -> RawMpf {
  infinity_value
}

///|
/// Canonical negative infinity.
let negative_infinity_value : RawMpf = { sign: 1, man: 0N, exp: -789, bc: -3 }

///|

///|
pub fn RawMpf::negative_infinity() -> RawMpf {
  negative_infinity_value
}
