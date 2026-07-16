///|
/// Compute the reciprocal gamma function `1/Gamma(x)` on the real axis.
///
/// Unlike a literal reciprocal, this entire continuation is zero at every
/// non-positive integer rather than raising at gamma's poles.
pub fn MPContext::reciprocal_gamma(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.rgamma(x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute real `log(Gamma(x))` where gamma is positive.
///
/// Negative inputs whose gamma value requires a complex logarithm are outside
/// this real-only API; use `complex_log_gamma` for the analytic principal
/// branch.
pub fn MPContext::log_gamma(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.loggamma(x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the real factorial continuation `Gamma(x+1)`.
pub fn MPContext::factorial(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let wp = if self.precision() > 0 { self.precision() + 20 } else { 80 }
  let argument = x.add(@mpf.RawMpf::one(), wp, Nearest)
  @gammazeta.gamma(argument, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the real digamma function, the logarithmic derivative of gamma.
pub fn MPContext::digamma(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.digamma(x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the order-`m` real polygamma function.
pub fn MPContext::polygamma(
  self : MPContext,
  m : Int,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.polygamma(m, x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the analytic continuation of the harmonic numbers.
pub fn MPContext::harmonic(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.harmonic(x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the analytic Fibonacci function, agreeing with exact Fibonacci
/// integers at integral arguments.
pub fn MPContext::fibonacci(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.fibonacci(x, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the Dirichlet eta function, the entire alternating zeta form.
pub fn MPContext::eta(
  self : MPContext,
  s : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.eta(s, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the `n`th Bernoulli number at context precision.
pub fn MPContext::bernoulli_number(
  self : MPContext,
  n : Int,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.bernoulli(n, self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Compute the entire reciprocal gamma function for a complex argument.
pub fn MPContext::complex_reciprocal_gamma(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.rgamma(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the principal analytic complex log-gamma function.
pub fn MPContext::complex_log_gamma(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.loggamma(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the complex factorial continuation `Gamma(z+1)`.
pub fn MPContext::complex_factorial(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.factorial(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the complex digamma function.
pub fn MPContext::complex_digamma(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.digamma(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the order-`m` complex polygamma function.
pub fn MPContext::complex_polygamma(
  self : MPContext,
  m : Int,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.polygamma(m, self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the complex harmonic-number continuation.
pub fn MPContext::complex_harmonic(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.harmonic(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the analytic complex Fibonacci function.
pub fn MPContext::complex_fibonacci(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.fibonacci(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Compute the complex Dirichlet eta function.
pub fn MPContext::complex_eta(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.eta(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
