///|
#declaration_only
pub fn mpf_atan2(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_atan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_pi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_exp(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ln(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_log(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_cos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_tan(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_cosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_tanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_asin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_acos(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_asinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_acosh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_atanh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_pow(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_nthroot(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_cbrt(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_e(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ln2(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ln10(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_phi(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_degree(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_cos_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_cos_sin(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 0,
  pi? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
#declaration_only
pub fn mpf_cos_sin_pi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
#declaration_only
pub fn mpf_cosh_sinh(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  tanh? : Bool = false,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
#declaration_only
pub fn mpf_log_hypot(
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_expj(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_expjpi(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}
