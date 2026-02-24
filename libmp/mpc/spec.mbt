///|
/// Stage-0 placeholder for complex arbitrary-precision values.
pub struct RawMpc {
  real : @mpf.RawMpf
  imag : @mpf.RawMpf
} derive(Show, Eq)

///|
pub(all) suberror MpcError {
  ValueError(String)
  DomainError(String)
  PoleError(String)
} derive(Show, Eq)

///|
/// Additive identity `0 + 0j`.
pub fn zero() -> RawMpc {
  { real: @mpf.fzero, imag: @mpf.fzero }
}

///|
/// Multiplicative identity `1 + 0j`.
#declaration_only
pub fn one() -> RawMpc {
  ...
}

///|
/// Build a complex value from explicit real/imaginary `mpf` parts.
#declaration_only
pub fn from_parts(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpc {
  ...
}

///|
/// Return `true` if either component is infinite.
#declaration_only
pub fn mpc_is_inf(z : RawMpc) -> Bool {
  ...
}

///|
/// Return `true` if value is infinite or NaN in any component.
#declaration_only
pub fn mpc_is_infnan(z : RawMpc) -> Bool {
  ...
}

///|
/// Return `true` when complex number is not exactly zero.
#declaration_only
pub fn mpc_is_nonzero(z : RawMpc) -> Bool {
  ...
}

///|
/// Unary plus with component-wise rounding to target precision.
#declaration_only
pub fn mpc_pos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Unary negation `-z`.
#declaration_only
pub fn mpc_neg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex conjugate `conj(z) = re - im*j`.
#declaration_only
pub fn mpc_conjugate(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Multiply by power of two: `z * 2^n`.
#declaration_only
pub fn mpc_shift(z : RawMpc, n : Int) -> RawMpc {
  ...
}

///|
/// Complex addition `z + w`.
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
/// Add real scalar to complex number: `z + x`.
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
/// Complex subtraction `z - w`.
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
/// Subtract real scalar from complex number: `z - x`.
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
/// Real-minus-complex operation: `x - z`.
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
/// Complex multiplication `z * w`.
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
/// Multiply complex by real scalar: `z * x`.
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
/// Multiply complex by machine integer.
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
/// Complex division `z / w` with special-value handling.
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
/// Divide complex by real scalar: `z / x`.
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
/// Reciprocal `1 / z`.
#declaration_only
pub fn mpc_reciprocal(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Real-over-complex division: `x / z`.
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
/// Integer exponentiation `z^n`.
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
/// Component-wise floor applied to `(re, im)`.
#declaration_only
pub fn mpc_floor(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Component-wise ceiling applied to `(re, im)`.
#declaration_only
pub fn mpc_ceil(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Component-wise nearest-integer rounding.
#declaration_only
pub fn mpc_nint(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Component-wise fractional part.
#declaration_only
pub fn mpc_frac(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Magnitude `|z| = sqrt(re^2 + im^2)`.
#declaration_only
pub fn mpc_abs(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Principal argument `arg(z)` in radians.
#declaration_only
pub fn mpc_arg(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> @mpf.RawMpf {
  ...
}

///|
/// Principal square root on complex plane.
#declaration_only
pub fn mpc_sqrt(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex squaring shortcut `z*z`.
#declaration_only
pub fn mpc_square(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex exponential `exp(z)`.
#declaration_only
pub fn mpc_exp(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex logarithm.
///
/// Raises `MpcError::PoleError` at branch singularity (`z=0`).
#declaration_only
pub fn mpc_log(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  ...
}

///|
/// Principal complex power `z^w`.
///
/// Branches and singular cases follow mpmath-compatible principal semantics.
#declaration_only
pub fn mpc_pow(
  z : RawMpc,
  w : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  ...
}

///|
/// Complex power with real exponent: `z^x`.
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
/// Complex sine function.
#declaration_only
pub fn mpc_sin(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex cosine function.
#declaration_only
pub fn mpc_cos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex tangent function.
#declaration_only
pub fn mpc_tan(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex hyperbolic sine.
#declaration_only
pub fn mpc_sinh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex hyperbolic cosine.
#declaration_only
pub fn mpc_cosh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex hyperbolic tangent.
#declaration_only
pub fn mpc_tanh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Human-readable complex string conversion.
///
/// Produces mpmath-style output with configurable decimal digits.
#declaration_only
pub fn mpc_to_str(z : RawMpc, dps? : Int = 15) -> String {
  ...
}

///|
/// Convert to pair of decimal strings `(re, im)` for interop/testing.
#declaration_only
pub fn mpc_to_complex(z : RawMpc, dps? : Int = 17) -> (String, String) {
  ...
}

///|
/// Deterministic hash compatible with Python/mpmath expectations.
#declaration_only
pub fn mpc_hash(z : RawMpc) -> Int {
  ...
}

///|
/// Alias of principal complex logarithm.
#declaration_only
pub fn mpc_ln(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Compute `cos(pi*z)` with branch/argument reduction tuned for accuracy.
#declaration_only
pub fn mpc_cos_pi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Compute `sin(pi*z)` with branch/argument reduction tuned for accuracy.
#declaration_only
pub fn mpc_sin_pi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Joint evaluation `(cos(z), sin(z))` sharing intermediate reductions.
#declaration_only
pub fn mpc_cos_sin(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) {
  ...
}

///|
/// Joint evaluation `(cos(pi*z), sin(pi*z))`.
#declaration_only
pub fn mpc_cos_sin_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) {
  ...
}

///|
/// Complex `exp(j*z)` helper used in periodic/spectral formulas.
#declaration_only
pub fn mpc_expj(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex `exp(j*pi*z)` helper.
#declaration_only
pub fn mpc_expjpi(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse tangent.
#declaration_only
pub fn mpc_atan(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse sine.
#declaration_only
pub fn mpc_asin(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse cosine.
#declaration_only
pub fn mpc_acos(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse hyperbolic sine.
#declaration_only
pub fn mpc_asinh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse hyperbolic cosine.
#declaration_only
pub fn mpc_acosh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex inverse hyperbolic tangent.
#declaration_only
pub fn mpc_atanh(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex `n`-th root.
///
/// Returns the principal branch used by mpmath-compatible `nthroot`.
#declaration_only
pub fn mpc_nthroot(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
/// Fixed-point integer backend for principal `n`-th root.
///
/// Operates on Gaussian-integer-like fixed representation `(a, b)`.
#declaration_only
pub fn mpc_nthroot_fixed(
  a : BigInt,
  b : BigInt,
  n : Int,
  prec : Int,
) -> (BigInt, BigInt) {
  ...
}

///|
/// Complex cube root convenience wrapper.
#declaration_only
pub fn mpc_cbrt(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Analytic continuation of Fibonacci sequence to complex arguments.
#declaration_only
pub fn mpc_fibonacci(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex arithmetic-geometric mean `agm(a, b)`.
#declaration_only
pub fn mpc_agm(
  a : RawMpc,
  b : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
/// Convenience `agm(1, a)`.
#declaration_only
pub fn mpc_agm1(a : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex exponential integral `Ei(z)` on principal branches.
///
/// Raises structured errors on branch/pole-domain incompatibilities where
/// applicable.
#declaration_only
pub fn mpc_ei(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  ...
}

///|
/// Complex `E1(z)` principal branch.
#declaration_only
pub fn mpc_e1(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex cosine integral `Ci(z)`.
#declaration_only
pub fn mpc_ci(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Taylor-series kernel for `Ci/Si` around small complex inputs.
///
/// `which` selects the specific target integral variant.
#declaration_only
pub fn mpc_ci_si_taylor(
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> RawMpc {
  ...
}

///|
/// Complex sine integral `Si(z)`.
#declaration_only
pub fn mpc_si(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Bessel function of first kind `J_n(z)` for integer order `n`.
#declaration_only
pub fn mpc_besseljn(
  n : Int,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc {
  ...
}

///|
/// Complete elliptic integral of first kind `K(z)`.
#declaration_only
pub fn mpc_ellipk(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complete elliptic integral of second kind `E(z)`.
#declaration_only
pub fn mpc_ellipe(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex gamma function `Gamma(z)`.
#declaration_only
pub fn mpc_gamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Reciprocal gamma `1/Gamma(z)`.
#declaration_only
pub fn mpc_rgamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Principal complex log-gamma `log(Gamma(z))`.
#declaration_only
pub fn mpc_loggamma(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Complex factorial continuation `Gamma(z+1)`.
#declaration_only
pub fn mpc_factorial(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Analytic continuation of harmonic numbers to complex `z`.
#declaration_only
pub fn mpc_harmonic(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Digamma function `psi(z)`.
#declaration_only
pub fn mpc_psi0(z : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Polygamma `psi^(m)(z)` for integer order `m`.
#declaration_only
pub fn mpc_psi(
  m : Int,
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  ...
}

///|
/// Complex zeta continuation.
///
/// `alt=true` computes alternating eta-form continuation.
#declaration_only
pub fn mpc_zeta(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> RawMpc {
  ...
}

///|
/// Alternating zeta (Dirichlet eta) as standalone entry.
#declaration_only
pub fn mpc_altzeta(s : RawMpc, prec : Int, rnd : @mpf.RoundMode) -> RawMpc {
  ...
}

///|
/// Partial complex zeta sum:
/// `sum_{k=start}^{start+terms-1} k^(-s)`.
#declaration_only
pub fn mpc_zetasum(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> RawMpc {
  ...
}
