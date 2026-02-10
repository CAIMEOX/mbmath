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
#declaration_only
pub fn mpi_make(lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_from_mpf(x : @mpf.RawMpf) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_eq(s : RawMpi, t : RawMpi) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpi_ne(s : RawMpi, t : RawMpi) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpi_lt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_le(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_gt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_ge(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_overlap(x : RawMpi, y : RawMpi) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpi_add(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_sub(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_delta(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpi_mid(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  ...
}

///|
#declaration_only
pub fn mpi_pos(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_neg(s : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_abs(s : RawMpi, prec? : Int = 0) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_mul_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_div_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_mul(
  s : RawMpi,
  t : RawMpi,
  prec? : Int = 0,
) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_square(s : RawMpi, prec? : Int = 0) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_div(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_pi(prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_exp(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_log(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_sqrt(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_atan(s : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_pow_int(s : RawMpi, n : Int, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_pow(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_to_str(s : RawMpi, dps? : Int = 15) -> String raise MpiError {
  ...
}

///|
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
#declaration_only
pub fn mpi_str(s : RawMpi, prec : Int) -> String raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_from_str(s : String, prec? : Int = 0) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_cos_sin(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_cos(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_sin(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_tan(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_cot(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_shift(s : RawMpi, n : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_cosh_sinh(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_atan2(y : RawMpi, x : RawMpi, prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpi_gamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_loggamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpi_rgamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
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
#declaration_only
pub fn mpci_make(real : RawMpi, imag : RawMpi) -> RawMpci {
  ...
}

///|
#declaration_only
pub fn mpci_pos(z : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
#declaration_only
pub fn mpci_neg(z : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
#declaration_only
pub fn mpci_add(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
#declaration_only
pub fn mpci_sub(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  ...
}

///|
#declaration_only
pub fn mpci_mul(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_div(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_contains_mpf(
  z : RawMpci,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn mpci_exp(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_cos(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_sin(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_abs(z : RawMpci, prec : Int) -> RawMpi raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_arg(z : RawMpci, prec : Int) -> RawMpi {
  ...
}

///|
#declaration_only
pub fn mpci_log(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_pow(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_square(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_pow_int(z : RawMpci, n : Int, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_gamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_loggamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_rgamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}

///|
#declaration_only
pub fn mpci_factorial(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  ...
}
