///|
pub(all) suberror GammaZetaError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Show, Eq)

///|
/// Factorial `n!` as arbitrary-precision float.
///
/// Validates integer domain and raises structured errors for unsupported input.
#declaration_only
pub fn mpf_factorial(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Bernoulli number `B_n`.
#declaration_only
pub fn mpf_bernoulli(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// High-index Bernoulli evaluator specialized for large `n`.
///
/// Uses asymptotic/accelerated strategy beyond the small-`n` path.
#declaration_only
pub fn mpf_bernoulli_huge(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Zeta at positive integer argument: `zeta(n)`.
#declaration_only
pub fn mpf_zeta_int(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Euler gamma function `Gamma(x)` on real axis.
#declaration_only
pub fn mpf_gamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Reciprocal gamma `1/Gamma(x)`.
#declaration_only
pub fn mpf_rgamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Principal real log-gamma `log(Gamma(x))`.
#declaration_only
pub fn mpf_loggamma(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Integer-gamma helper for integer argument paths.
#declaration_only
pub fn mpf_gamma_int(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Digamma function `psi(x)`.
#declaration_only
pub fn mpf_psi0(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Harmonic-number continuation `H_x` on real axis.
#declaration_only
pub fn mpf_harmonic(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Fibonacci continuation to real argument via analytic formula.
#declaration_only
pub fn mpf_fibonacci(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf {
  ...
}

///|
/// Riemann zeta continuation on reals.
///
/// `alt=true` selects the alternating eta-based continuation branch.
#declaration_only
pub fn mpf_zeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Alternating zeta / Dirichlet eta standalone entry.
#declaration_only
pub fn mpf_altzeta(
  s : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Polygamma `psi^(m)(x)` for integer order `m`.
#declaration_only
pub fn mpf_psi(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise GammaZetaError {
  ...
}

///|
/// Apery's constant `zeta(3)`.
#declaration_only
pub fn mpf_apery(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Catalan's constant.
#declaration_only
pub fn mpf_catalan(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Euler-Mascheroni constant `gamma`.
#declaration_only
pub fn mpf_euler(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Glaisher-Kinkelin constant.
#declaration_only
pub fn mpf_glaisher(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Khinchin's constant.
#declaration_only
pub fn mpf_khinchin(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Mertens constant.
#declaration_only
pub fn mpf_mertens(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Twin-prime constant.
#declaration_only
pub fn mpf_twinprime(prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Finite partial zeta sum:
/// `sum_{k=start}^{start+terms-1} k^(-s)`.
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
