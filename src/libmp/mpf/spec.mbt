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
#declaration_only
pub fn normalize(
  sign : Int,
  man : BigInt,
  exp : Int,
  bc : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn from_man_exp(
  man : BigInt,
  exp : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn from_int(n : Int) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn is_zero(x : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn is_finite(x : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn is_inf(x : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn is_nan(x : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn from_str(
  s : String,
  prec? : Int = 0,
  rnd? : RoundMode = round_nearest,
) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn to_str(x : RawMpf) -> String {
  ...
}

///|
#declaration_only
pub fn to_str_opts(
  x : RawMpf,
  dps? : Int = 15,
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String {
  ...
}

///|
#declaration_only
pub fn format_mpf(x : RawMpf, format_spec : String, dps? : Int = 15) -> String {
  ...
}

///|
#declaration_only
pub fn mpf_add(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sub(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_mul(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_div(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_pos(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_neg(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_abs(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sign(x : RawMpf) -> Int {
  ...
}

///|
#declaration_only
pub fn mpf_eq(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpf_cmp(x : RawMpf, y : RawMpf) -> Int {
  ...
}

///|
#declaration_only
pub fn mpf_lt(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpf_le(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpf_gt(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpf_ge(x : RawMpf, y : RawMpf) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpf_shift(x : RawMpf, n : Int) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_mul_int(x : RawMpf, n : Int, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_rdiv_int(n : Int, x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_round_int(x : RawMpf, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_floor(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ceil(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_nint(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_frac(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_min_max(seq : ArrayView[RawMpf]) -> (RawMpf, RawMpf) {
  ...
}

///|
#declaration_only
pub fn mpf_sum(
  xs : ArrayView[RawMpf],
  prec : Int,
  rnd : RoundMode,
  absolute? : Bool = false,
) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_mod(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_hypot(x : RawMpf, y : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_pow_int(x : RawMpf, n : Int, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sqrt(x : RawMpf, prec : Int, rnd : RoundMode) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_frexp(x : RawMpf) -> (RawMpf, Int) {
  ...
}

///|
#declaration_only
pub fn mpf_hash(x : RawMpf) -> Int {
  ...
}

///|
#declaration_only
pub fn mpf_perturb(
  x : RawMpf,
  eps_sign : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_rand(prec : Int) -> RawMpf {
  ...
}

///|
pub let fzero : RawMpf = { sign: 0, man: 0N, exp: 0, bc: 0 }

///|
pub let fone : RawMpf = { sign: 0, man: 1N, exp: 0, bc: 1 }

///|
pub let fnone : RawMpf = { sign: 1, man: 1N, exp: 0, bc: 1 }

///|
pub let fnan : RawMpf = { sign: 0, man: 0N, exp: -123, bc: -1 }

///|
pub let finf : RawMpf = { sign: 0, man: 0N, exp: -456, bc: -2 }

///|
pub let fninf : RawMpf = { sign: 1, man: 0N, exp: -789, bc: -3 }

///|
pub let round_nearest : RoundMode = RoundMode::Nearest

///|
pub let round_floor : RoundMode = RoundMode::Floor

///|
pub let round_ceiling : RoundMode = RoundMode::Ceiling

///|
pub let round_up : RoundMode = RoundMode::Up

///|
pub let round_down : RoundMode = RoundMode::Down
