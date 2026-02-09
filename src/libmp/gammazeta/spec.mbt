///|
#declaration_only
pub fn mpf_factorial(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_bernoulli(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_bernoulli_huge(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_zeta_int(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_gamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_loggamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_gamma_int(n : Int, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_psi0(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_harmonic(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_fibonacci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_zeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_altzeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_psi(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_apery(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_catalan(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_euler(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_glaisher(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_khinchin(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_mertens(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_twinprime(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpf_zetasum(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> @mpf.RawMpf {
  ...
}
