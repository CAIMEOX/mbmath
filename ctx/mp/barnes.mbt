///|
/// Evaluate the Barnes G-function on the real axis.
pub fn MPContext::barnes_g_function(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).barnes_g(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the principal complex Barnes G-function continuation.
pub fn MPContext::complex_barnes_g_function(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.barnes_g(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the superfactorial continuation `G(x+2)`.
pub fn MPContext::superfactorial(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  match small_nonnegative_integer(x) {
    Some(n) => {
      let mut product = @mpf.RawMpf::one()
      for k in 1..<=n {
        let factorial = @gammazeta.factorial(k, 0, Down) catch {
          err => raise from_gammazeta_error(err)
        }
        product = product.mul(factorial, 0, Down)
      }
      return product
    }
    None => ()
  }
  let p = ratio_working_precision(self)
  let argument = @mpc.RawMpc::new(
    x.add(@mpf.RawMpf::two(), p, Nearest),
    @mpf.RawMpf::zero(),
  )
  let value = argument.barnes_g(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the principal complex superfactorial continuation `G(z+2)`.
pub fn MPContext::complex_superfactorial(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  let p = ratio_working_precision(self)
  z
  .add_real(@mpf.RawMpf::two(), p, Nearest)
  .barnes_g(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
