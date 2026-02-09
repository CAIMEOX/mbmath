///|
#declaration_only
pub fn mpf_agm(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ei(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ci_si_taylor(
  x : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_si(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ci(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ellipk(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ellipe(
  m : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_agm1(
  a : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_ci_si(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  which? : Int = 2,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  ...
}

///|
#declaration_only
pub fn mpf_e1(x : @mpf.RawMpf, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_erf(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_erfc(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_expint(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  gamma? : Bool = false,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_besseljn(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}
