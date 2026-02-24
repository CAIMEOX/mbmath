///|
pub struct RawMpi {
  lo : @mpf.RawMpf
  hi : @mpf.RawMpf
} derive(Show, Eq)

///|
pub let mpi_zero : RawMpi = { lo: @mpf.fzero, hi: @mpf.fzero }

///|
pub let mpi_one : RawMpi = { lo: @mpf.fone, hi: @mpf.fone }

///|
pub(all) suberror MpiError {
  ValueError(String)
  DomainError(String)
  ParseError(String)
  UnsupportedError(String)
  UnorderedError(String)
} derive(Show, Eq)

///|
/// Construct a canonical interval `[lo, hi]`.
///
/// Endpoints are ordered/canonicalized according to interval conventions.
#declaration_only
pub fn mpi_make(lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> RawMpi {
  ...
}

///|
/// Lift an exact scalar `mpf` into a degenerate interval `[x, x]`.
#declaration_only
pub fn mpi_from_mpf(x : @mpf.RawMpf) -> RawMpi {
  ...
}

///|
/// Interval equality (endpoint-wise exact).
#declaration_only
pub fn mpi_eq(s : RawMpi, t : RawMpi) -> Bool {
  ...
}

///|
/// Interval inequality (endpoint-wise exact negation of `mpi_eq`).
#declaration_only
pub fn mpi_ne(s : RawMpi, t : RawMpi) -> Bool {
  ...
}

///|
/// Strict interval ordering `s < t`.
///
/// Raises `UnorderedError` when comparison is not decidable from overlap.
#declaration_only
pub fn mpi_lt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
/// Non-strict interval ordering `s <= t`.
#declaration_only
pub fn mpi_le(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
/// Strict interval ordering `s > t`.
#declaration_only
pub fn mpi_gt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
/// Non-strict interval ordering `s >= t`.
#declaration_only
pub fn mpi_ge(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
/// Return `true` when two intervals overlap.
#declaration_only
pub fn mpi_overlap(x : RawMpi, y : RawMpi) -> Bool {
  ...
}

///|
/// Interval addition with outward rounding.
#declaration_only
pub fn mpi_add(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
/// Interval subtraction with outward rounding.
#declaration_only
pub fn mpi_sub(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
/// Interval width `delta = hi - lo`.
#declaration_only
pub fn mpi_delta(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  ...
}

///|
/// Interval midpoint `(lo + hi) / 2`.
#declaration_only
pub fn mpi_mid(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  ...
}

///|
/// Unary plus (normalization/outward rounding pass).
#declaration_only
pub fn mpi_pos(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
/// Interval negation `-[lo,hi] = [-hi,-lo]`.
#declaration_only
pub fn mpi_neg(s : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
/// Interval absolute value enclosure.
#declaration_only
pub fn mpi_abs(s : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
/// Multiply interval by scalar `mpf`.
#declaration_only
pub fn mpi_mul_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  ...
}

///|
/// Divide interval by scalar `mpf`.
#declaration_only
pub fn mpi_div_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval multiplication with outward rounding.
#declaration_only
pub fn mpi_mul(
  s : RawMpi,
  t : RawMpi,
  prec? : Int = 0,
) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval squaring enclosure.
#declaration_only
pub fn mpi_square(s : RawMpi, prec? : Int = 0) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval division with zero-crossing detection.
///
/// Raises when divisor interval contains prohibited singular region.
#declaration_only
pub fn mpi_div(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval enclosure for constant `pi`.
#declaration_only
pub fn mpi_pi(prec : Int) -> RawMpi {
  ...
}

///|
/// Interval exponential enclosure.
#declaration_only
pub fn mpi_exp(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
/// Interval natural logarithm enclosure.
///
/// Raises `DomainError` outside positive domain.
#declaration_only
pub fn mpi_log(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval principal square-root enclosure.
#declaration_only
pub fn mpi_sqrt(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval arctangent enclosure.
#declaration_only
pub fn mpi_atan(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
/// Integer-power interval enclosure.
#declaration_only
pub fn mpi_pow_int(s : RawMpi, n : Int, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// General interval power enclosure `s^t`.
#declaration_only
pub fn mpi_pow(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Default human-readable interval string (`[lo, hi]` style).
#declaration_only
pub fn mpi_to_str(s : RawMpi, dps? : Int = 15) -> String raise MpiError {
  ...
}

///|
/// Rich interval formatting:
/// supports bracket/plusminus/percent/diff and base/spacing options.
#declaration_only
pub fn mpi_to_str_opts(
  s : RawMpi,
  dps? : Int = 15,
  mode? : String = "brackets",
  use_spaces? : Bool = true,
  error_dps? : Int = 4,
  left_bracket? : String = "[",
  right_bracket? : String = "]",
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String raise MpiError {
  ...
}

///|
/// Compact interval string helper tied to binary precision.
#declaration_only
pub fn mpi_str(s : RawMpi, prec : Int) -> String raise MpiError {
  ...
}

///|
/// Parse interval string into `RawMpi`.
///
/// Supports bracket and shorthand forms used by mpmath interval APIs.
#declaration_only
pub fn mpi_from_str(s : String, prec? : Int = 0) -> RawMpi raise MpiError {
  ...
}

///|
/// Joint interval trig evaluation `(cos(s), sin(s))`.
#declaration_only
pub fn mpi_cos_sin(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) raise MpiError {
  ...
}

///|
/// Interval cosine enclosure.
#declaration_only
pub fn mpi_cos(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval sine enclosure.
#declaration_only
pub fn mpi_sin(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval tangent enclosure.
#declaration_only
pub fn mpi_tan(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval cotangent enclosure.
#declaration_only
pub fn mpi_cot(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Multiply interval by power of two.
#declaration_only
pub fn mpi_shift(s : RawMpi, n : Int) -> RawMpi {
  ...
}

///|
/// Joint interval hyperbolic evaluation `(cosh(s), sinh(s))`.
#declaration_only
pub fn mpi_cosh_sinh(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) raise MpiError {
  ...
}

///|
/// Interval `atan2(y, x)` enclosure.
#declaration_only
pub fn mpi_atan2(y : RawMpi, x : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
/// Interval gamma enclosure.
#declaration_only
pub fn mpi_gamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval log-gamma enclosure.
#declaration_only
pub fn mpi_loggamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval reciprocal-gamma enclosure.
#declaration_only
pub fn mpi_rgamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Interval factorial enclosure (`Gamma(z+1)` continuation).
#declaration_only
pub fn mpi_factorial(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
pub struct RawMpci {
  real : RawMpi
  imag : RawMpi
} derive(Show, Eq)

///|
pub let mpci_zero : RawMpci = { real: mpi_zero, imag: mpi_zero }

///|
pub let mpci_one : RawMpci = { real: mpi_one, imag: mpi_zero }

///|
/// Build complex interval from real/imaginary interval parts.
#declaration_only
pub fn mpci_make(real : RawMpi, imag : RawMpi) -> RawMpci {
  ...
}

///|
/// Unary plus for complex intervals.
#declaration_only
pub fn mpci_pos(z : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
/// Complex-interval negation.
#declaration_only
pub fn mpci_neg(z : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
/// Complex-interval addition enclosure.
#declaration_only
pub fn mpci_add(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
/// Complex-interval subtraction enclosure.
#declaration_only
pub fn mpci_sub(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
/// Complex-interval multiplication enclosure.
#declaration_only
pub fn mpci_mul(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval division enclosure.
#declaration_only
pub fn mpci_div(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Membership predicate for exact complex point `(re, im)`.
#declaration_only
pub fn mpci_contains_mpf(
  z : RawMpci,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Bool {
  ...
}

///|
/// Complex-interval exponential enclosure.
#declaration_only
pub fn mpci_exp(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval cosine enclosure.
#declaration_only
pub fn mpci_cos(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval sine enclosure.
#declaration_only
pub fn mpci_sin(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Magnitude interval enclosure `|z|`.
#declaration_only
pub fn mpci_abs(z : RawMpci, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
/// Argument interval enclosure `arg(z)`.
#declaration_only
pub fn mpci_arg(z : RawMpci, prec : Int) -> RawMpi {
  ...
}

///|
/// Complex-interval principal logarithm enclosure.
#declaration_only
pub fn mpci_log(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval power enclosure `z^w`.
#declaration_only
pub fn mpci_pow(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval squaring enclosure.
#declaration_only
pub fn mpci_square(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval integer-power enclosure.
#declaration_only
pub fn mpci_pow_int(z : RawMpci, n : Int, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval gamma enclosure.
#declaration_only
pub fn mpci_gamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval log-gamma enclosure.
#declaration_only
pub fn mpci_loggamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval reciprocal-gamma enclosure.
#declaration_only
pub fn mpci_rgamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
/// Complex-interval factorial enclosure (`Gamma(z+1)` continuation).
#declaration_only
pub fn mpci_factorial(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}
