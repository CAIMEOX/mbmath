///|
/// Evaluate the real logarithmic integral. Negative inputs have a complex
/// principal value and must use `complex_logarithmic_integral`.
pub fn MPContext::logarithmic_integral(
  self : MPContext,
  x : @mpf.RawMpf,
  offset? : Bool = false,
) -> @mpf.RawMpf raise MPError {
  if x.sign == 1 && !x.is_zero() {
    raise ComplexResult(
      "logarithmic integral is complex on the negative real axis",
    )
  }
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).logarithmic_integral(
    self.precision(),
    self.round_mode(),
    offset~,
  ) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the principal complex logarithmic integral.
pub fn MPContext::complex_logarithmic_integral(
  self : MPContext,
  z : @mpc.RawMpc,
  offset? : Bool = false,
) -> @mpc.RawMpc raise MPError {
  z.logarithmic_integral(self.precision(), self.round_mode(), offset~) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the hyperbolic cosine integral on its real-valued nonnegative
/// branch.
pub fn MPContext::hyperbolic_cosine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.sign == 1 && !x.is_zero() {
    raise ComplexResult(
      "hyperbolic cosine integral is complex on the negative real axis",
    )
  }
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).hyperbolic_cosine_integral(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the entire hyperbolic sine integral on the real axis.
pub fn MPContext::hyperbolic_sine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).hyperbolic_sine_integral(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the principal complex hyperbolic cosine integral.
pub fn MPContext::complex_hyperbolic_cosine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.hyperbolic_cosine_integral(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the entire complex hyperbolic sine integral.
pub fn MPContext::complex_hyperbolic_sine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  z.hyperbolic_sine_integral(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the real Fresnel cosine and sine integrals as a pair.
pub fn MPContext::fresnel_integrals(
  self : MPContext,
  x : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  let (cosine, sine) = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).fresnel_integrals(
    self.precision(),
    self.round_mode(),
  ) catch {
    err => raise from_mpc_error(err)
  }
  (cosine.real, sine.real)
}

///|
/// Evaluate the real Fresnel cosine integral.
pub fn MPContext::fresnel_cosine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.fresnel_integrals(x).0
}

///|
/// Evaluate the real Fresnel sine integral.
pub fn MPContext::fresnel_sine_integral(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  self.fresnel_integrals(x).1
}

///|
/// Evaluate the complex Fresnel cosine and sine integrals as a pair.
pub fn MPContext::complex_fresnel_integrals(
  self : MPContext,
  z : @mpc.RawMpc,
) -> (@mpc.RawMpc, @mpc.RawMpc) raise MPError {
  z.fresnel_integrals(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the complex Fresnel cosine integral.
pub fn MPContext::complex_fresnel_cosine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_fresnel_integrals(z).0
}

///|
/// Evaluate the complex Fresnel sine integral.
pub fn MPContext::complex_fresnel_sine_integral(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  self.complex_fresnel_integrals(z).1
}
