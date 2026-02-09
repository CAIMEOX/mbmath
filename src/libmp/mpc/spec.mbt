///|
/// Stage-0 placeholder for complex arbitrary-precision values.
pub struct RawMpc {
  real : @mpf.RawMpf
  imag : @mpf.RawMpf
} derive(Show, Eq)

///|
pub fn zero() -> RawMpc {
  { real: @mpf.fzero, imag: @mpf.fzero }
}

///|
#declaration_only
pub fn one() -> RawMpc {
  ...
}

///|
#declaration_only
pub fn from_parts(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_is_inf(z : RawMpc) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpc_is_infnan(z : RawMpc) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpc_is_nonzero(z : RawMpc) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpc_pos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_neg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_conjugate(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_shift(z : RawMpc, n : Int) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_add(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_add_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_sub(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_sub_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_mpf_sub(
  x : @mpf.RawMpf,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_mul(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_mul_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_mul_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_div(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_div_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_reciprocal(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_mpf_div(
  x : @mpf.RawMpf,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_pow_int(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_floor(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_ceil(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_nint(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_frac(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_abs(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpc_arg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpc_sqrt(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_square(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_exp(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_log(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_pow(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_pow_mpf(
  z : RawMpc,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_sin(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_cos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_tan(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_sinh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_cosh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
#declaration_only
pub fn mpc_tanh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}
