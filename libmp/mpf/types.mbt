///|
/// Core rounding modes aligned with mpmath's low-level modes:
/// - Nearest: tie-to-even
/// - Floor: towards -inf
/// - Ceiling: towards +inf
/// - Up: away from zero
/// - Down: towards zero
pub enum RoundMode {
  Nearest
  Floor
  Ceiling
  Up
  Down
} derive(Show, Eq)

///|
/// Raw arbitrary-precision floating-point value:
/// value = (-1)^sign * man * 2^exp
/// Canonical invariant: `man` is non-negative and odd unless it is zero.
pub struct RawMpf {
  sign : Int
  man : BigInt
  exp : Int
  bc : Int
} derive(Show, Eq)

///|
pub(all) suberror MpfError {
  ValueError(String)
  DomainError(String)
  DivisionByZero(String)
  ParseError(String)
  FormatError(String)
  UnsupportedError(String)
} derive(Show, Eq)

///|
/// Canonical positive zero.
pub let fzero : RawMpf = { sign: 0, man: 0N, exp: 0, bc: 0 }

///|
/// Canonical positive one.
pub let fone : RawMpf = { sign: 0, man: 1N, exp: 0, bc: 1 }

///|
/// Canonical negative one.
pub let fnone : RawMpf = { sign: 1, man: 1N, exp: 0, bc: 1 }

///|
/// Canonical NaN sentinel.
pub let fnan : RawMpf = { sign: 0, man: 0N, exp: -123, bc: -1 }

///|
/// Canonical positive infinity.
pub let finf : RawMpf = { sign: 0, man: 0N, exp: -456, bc: -2 }

///|
/// Canonical negative infinity.
pub let fninf : RawMpf = { sign: 1, man: 0N, exp: -789, bc: -3 }

///|
/// Rounding mode alias: nearest (tie-to-even).
pub let round_nearest : RoundMode = RoundMode::Nearest

///|
/// Rounding mode alias: toward negative infinity.
pub let round_floor : RoundMode = RoundMode::Floor

///|
/// Rounding mode alias: toward positive infinity.
pub let round_ceiling : RoundMode = RoundMode::Ceiling

///|
/// Rounding mode alias: away from zero.
pub let round_up : RoundMode = RoundMode::Up

///|
/// Rounding mode alias: toward zero.
pub let round_down : RoundMode = RoundMode::Down
