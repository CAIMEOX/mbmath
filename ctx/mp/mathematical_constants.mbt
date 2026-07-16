///|
/// Return Apery's constant `zeta(3)` at the current context precision.
pub fn MPContext::apery_constant(self : MPContext) -> @mpf.RawMpf raise MPError {
  @gammazeta.apery(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return Catalan's constant at the current context precision.
pub fn MPContext::catalan_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.catalan(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the Euler-Mascheroni constant at the current context precision.
pub fn MPContext::euler_mascheroni_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.euler(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the Glaisher-Kinkelin constant at the current context precision.
pub fn MPContext::glaisher_kinkelin_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.glaisher(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return Khinchin's constant at the current arbitrary precision.
///
/// The value is computed from its convergent even-zeta series rather than a
/// stored decimal expansion.
pub fn MPContext::khinchin_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.khinchin(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the Meissel-Mertens constant at the current arbitrary precision.
///
/// This is the constant in the asymptotic harmonic sum over reciprocal primes,
/// evaluated through its Mobius-weighted log-zeta series.
pub fn MPContext::meissel_mertens_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.mertens(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the twin-prime constant at the current arbitrary precision.
///
/// The accelerated zeta product removes the first four prime powers exactly
/// and accumulates the remaining product in logarithmic form.
pub fn MPContext::twin_prime_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.twin_prime_constant(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}
