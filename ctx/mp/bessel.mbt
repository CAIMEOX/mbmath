///|
/// Evaluate the first-kind Bessel function `J_n(x)` for an integer order and a
/// real argument.
pub fn MPContext::integer_order_bessel_first_kind(
  self : MPContext,
  order : Int,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.bessel_j(order, x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the first-kind Bessel function `J_n(z)` for an integer order and a
/// complex argument.
pub fn MPContext::complex_integer_order_bessel_first_kind(
  self : MPContext,
  order : Int,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.bessel_j(order, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
