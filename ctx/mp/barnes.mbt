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

///|
/// Evaluate the hyperfactorial continuation on real-valued branches.
///
/// Some negative noninteger arguments have a genuinely complex principal
/// value. Those inputs raise `ComplexResult`; use `complex_hyperfactorial` to
/// request that branch explicitly.
pub fn MPContext::hyperfactorial(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_nan() || x == @mpf.RawMpf::negative_infinity() {
    return @mpf.RawMpf::nan()
  }
  if x == @mpf.RawMpf::infinity() {
    return x
  }
  let p = ratio_working_precision(self, extra=32)
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).hyperfactorial(
    p,
    Nearest,
  ) catch {
    err => raise from_mpc_error(err)
  }
  if value.imag.is_zero() {
    return value.real.rounded(self.precision(), self.round_mode())
  }
  let scale = {
    let magnitude = value.real.abs(p, Nearest)
    if magnitude < @mpf.RawMpf::one() {
      @mpf.RawMpf::one()
    } else {
      magnitude
    }
  }
  let target = if self.precision() > 0 { self.precision() } else { 64 }
  let tolerance = scale.scale_pow2(-(target + 16))
  if value.imag.abs(p, Nearest) <= tolerance {
    value.real.rounded(self.precision(), self.round_mode())
  } else {
    raise ComplexResult(
      "hyperfactorial: principal value is complex; use complex_hyperfactorial",
    )
  }
}

///|
/// Evaluate the principal complex hyperfactorial continuation.
pub fn MPContext::complex_hyperfactorial(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.hyperfactorial(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
