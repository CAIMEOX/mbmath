///|
/// Evaluate the inverse real error function on `[-1, 1]`.
pub fn MPContext::inverse_error_function(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.inverse_error_function(x, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the normal probability density with the given mean and standard
/// deviation.
pub fn MPContext::normal_probability_density(
  self : MPContext,
  x : @mpf.RawMpf,
  mean? : @mpf.RawMpf = @mpf.RawMpf::zero(),
  standard_deviation? : @mpf.RawMpf = @mpf.RawMpf::one(),
) -> @mpf.RawMpf raise MPError {
  if standard_deviation.is_zero() {
    raise PoleError("normal probability density requires nonzero deviation")
  }
  let p = self.working_precision() + 64
  let normalized = checked_mpf_div(
    x.sub(mean, p, Nearest),
    standard_deviation,
    p,
    Nearest,
  )
  let exponent = normalized
    .mul(normalized, p, Nearest)
    .scale_pow2(-1)
    .negated(p, Nearest)
  let two_pi = checked_mpf_pi(p, Nearest).mul(@mpf.RawMpf::two(), p, Nearest)
  let sqrt_two_pi = two_pi.sqrt(p, Nearest) catch {
    err => raise from_mpf_error(err)
  }
  let normalization = standard_deviation.mul(sqrt_two_pi, p, Nearest)
  checked_mpf_div(
    checked_mpf_exp(exponent, p, Nearest),
    normalization,
    self.precision(),
    self.round_mode(),
  )
}

///|
/// Evaluate the normal cumulative distribution. Negative real tails are
/// computed directly through the complementary error function.
pub fn MPContext::normal_cumulative_distribution(
  self : MPContext,
  x : @mpf.RawMpf,
  mean? : @mpf.RawMpf = @mpf.RawMpf::zero(),
  standard_deviation? : @mpf.RawMpf = @mpf.RawMpf::one(),
) -> @mpf.RawMpf raise MPError {
  if standard_deviation.is_zero() {
    raise PoleError("normal cumulative distribution requires nonzero deviation")
  }
  let p = self.working_precision() + 64
  let sqrt_two = @mpf.RawMpf::two().sqrt(p, Nearest) catch {
    err => raise from_mpf_error(err)
  }
  let normalized = checked_mpf_div(
    x.sub(mean, p, Nearest),
    standard_deviation.mul(sqrt_two, p, Nearest),
    p,
    Nearest,
  )
  if normalized.is_nan() {
    return @mpf.RawMpf::nan()
  }
  let value = if normalized.sign == 1 {
    @libhyper.erfc(normalized.negated(p, Nearest), p, Nearest) catch {
      err => raise from_libhyper_error(err)
    }
  } else {
    @mpf.RawMpf::one().add(
      @libhyper.erf(normalized, p, Nearest) catch {
        err => raise from_libhyper_error(err)
      },
      p,
      Nearest,
    )
  }
  value.scale_pow2(-1).rounded(self.precision(), self.round_mode())
}

///|
/// Evaluate the normal probability density for complex parameters.
pub fn MPContext::complex_normal_probability_density(
  self : MPContext,
  z : @mpc.RawMpc,
  mean? : @mpc.RawMpc = @mpc.RawMpc::zero(),
  standard_deviation? : @mpc.RawMpc = @mpc.RawMpc::one(),
) -> @mpc.RawMpc raise MPError {
  if standard_deviation == @mpc.RawMpc::zero() {
    raise PoleError(
      "complex normal probability density requires nonzero deviation",
    )
  }
  let p = self.working_precision() + 64
  let normalized = checked_mpc_div(
    z.sub(mean, p, Nearest),
    standard_deviation,
    p,
    Nearest,
  )
  let exponent = normalized
    .square(p, Nearest)
    .scale_pow2(-1)
    .negated(p, Nearest)
  let two_pi = checked_mpf_pi(p, Nearest).mul(@mpf.RawMpf::two(), p, Nearest)
  let scale = two_pi.sqrt(p, Nearest) catch { err => raise from_mpf_error(err) }
  checked_mpc_div(
    checked_mpc_exp(exponent, p, Nearest),
    standard_deviation.mul_real(scale, p, Nearest),
    self.precision(),
    self.round_mode(),
  )
}

///|
/// Evaluate the entire complex continuation of the normal cumulative
/// distribution.
pub fn MPContext::complex_normal_cumulative_distribution(
  self : MPContext,
  z : @mpc.RawMpc,
  mean? : @mpc.RawMpc = @mpc.RawMpc::zero(),
  standard_deviation? : @mpc.RawMpc = @mpc.RawMpc::one(),
) -> @mpc.RawMpc raise MPError {
  if standard_deviation == @mpc.RawMpc::zero() {
    raise PoleError(
      "complex normal cumulative distribution requires nonzero deviation",
    )
  }
  let p = self.working_precision() + 64
  let sqrt_two = @mpf.RawMpf::two().sqrt(p, Nearest) catch {
    err => raise from_mpf_error(err)
  }
  let normalized = checked_mpc_div(
    z.sub(mean, p, Nearest),
    standard_deviation.mul_real(sqrt_two, p, Nearest),
    p,
    Nearest,
  )
  let error_value = normalized.error_function(p, Nearest) catch {
    err => raise from_mpc_error(err)
  }
  error_value
  .add_real(@mpf.RawMpf::one(), p, Nearest)
  .scale_pow2(-1)
  .rounded(self.precision(), self.round_mode())
}
