///|
fn ratio_working_precision(context : MPContext, extra? : Int = 0) -> Int {
  let base = if context.precision() > 0 { context.precision() } else { 64 }
  base + 64 + extra
}

///|
fn is_integer_value(x : @mpf.RawMpf) -> Bool {
  x.is_finite() && (x.is_zero() || x.exp >= 0)
}

///|
fn is_gamma_pole(x : @mpf.RawMpf) -> Bool {
  is_integer_value(x) && (x.is_zero() || x.sign == 1)
}

///|
fn integer_value_is_odd(x : @mpf.RawMpf) -> Bool {
  !x.is_zero() && x.exp == 0
}

///|
fn small_nonnegative_integer(x : @mpf.RawMpf) -> Int? {
  if x.sign == 1 || !is_integer_value(x) {
    return None
  }
  let integer = x.to_integer() catch { _ => return None }
  if integer > 100000N {
    None
  } else {
    Some(integer.to_int())
  }
}

///|
fn gamma_checked_for_ratio(
  x : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.gamma(x, prec, Nearest) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn complex_gamma_checked_for_ratio(
  z : @mpc.RawMpc,
  prec : Int,
) -> @mpc.RawMpc raise MPError {
  z.gamma(prec, Nearest) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn lift_ratio_real(x : @mpf.RawMpf) -> @mpc.RawMpc {
  @mpc.RawMpc::new(x, @mpf.RawMpf::zero())
}

///|
/// Evaluate a quotient of products of gamma values while analytically
/// cancelling matching nonpositive-integer poles.
pub fn MPContext::gamma_product(
  self : MPContext,
  numerators : ArrayView[@mpf.RawMpf],
  denominators : ArrayView[@mpf.RawMpf],
) -> @mpf.RawMpf raise MPError {
  let numerator_poles : Array[@mpf.RawMpf] = []
  let denominator_poles : Array[@mpf.RawMpf] = []
  let numerator_regular : Array[@mpf.RawMpf] = []
  let denominator_regular : Array[@mpf.RawMpf] = []
  for x in numerators {
    if is_gamma_pole(x) {
      numerator_poles.push(x)
    } else {
      numerator_regular.push(x)
    }
  }
  for x in denominators {
    if is_gamma_pole(x) {
      denominator_poles.push(x)
    } else {
      denominator_regular.push(x)
    }
  }
  if numerator_poles.length() < denominator_poles.length() {
    return @mpf.RawMpf::zero()
  }
  if numerator_poles.length() > denominator_poles.length() {
    return @mpf.RawMpf::infinity()
  }
  let p = ratio_working_precision(
    self,
    extra=(numerators.length() + denominators.length()) * 8,
  )
  let mut product = @mpf.RawMpf::one()
  for i in 0..<numerator_poles.length() {
    let numerator_pole = numerator_poles[i]
    let denominator_pole = denominator_poles[i]
    let residue_ratio = checked_mpf_div(
      gamma_checked_for_ratio(
        @mpf.RawMpf::one().sub(denominator_pole, p, Nearest),
        p,
      ),
      gamma_checked_for_ratio(
        @mpf.RawMpf::one().sub(numerator_pole, p, Nearest),
        p,
      ),
      p,
      Nearest,
    )
    product = product.mul(residue_ratio, p, Nearest)
    if integer_value_is_odd(numerator_pole) !=
      integer_value_is_odd(denominator_pole) {
      product = product.negated(p, Nearest)
    }
  }
  for x in numerator_regular {
    product = product.mul(gamma_checked_for_ratio(x, p), p, Nearest)
  }
  for x in denominator_regular {
    product = checked_mpf_div(
      product,
      gamma_checked_for_ratio(x, p),
      p,
      Nearest,
    )
  }
  product.rounded(self.precision(), self.round_mode())
}

///|
/// Evaluate Euler's beta function on the real axis.
pub fn MPContext::beta_function(
  self : MPContext,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_nan() || y.is_nan() {
    return @mpf.RawMpf::nan()
  }
  let (first, second) = if y.is_infinite() { (y, x) } else { (x, y) }
  if first.is_infinite() {
    if first.sign == 1 {
      return @mpf.RawMpf::nan()
    }
    if second.is_infinite() {
      return if second.sign == 1 {
        @mpf.RawMpf::nan()
      } else {
        @mpf.RawMpf::zero()
      }
    }
    if second.sign == 0 && !second.is_zero() {
      return @mpf.RawMpf::zero()
    }
    if is_integer_value(second) {
      return @mpf.RawMpf::nan()
    }
    if second.sign == 1 {
      let gamma_value = gamma_checked_for_ratio(
        second,
        ratio_working_precision(self),
      )
      return if gamma_value.sign == 1 {
        @mpf.RawMpf::negative_infinity()
      } else {
        @mpf.RawMpf::infinity()
      }
    }
    return @mpf.RawMpf::nan()
  }
  let p = ratio_working_precision(self)
  let sum = x.add(y, p, Nearest)
  self.gamma_product([x, y], [sum])
}

///|
/// Evaluate the generalized binomial coefficient.
pub fn MPContext::binomial_coefficient(
  self : MPContext,
  n : @mpf.RawMpf,
  k : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let p = ratio_working_precision(self)
  let n_minus_k = n.sub(k, p, Nearest)
  let finite_order = match
    (small_nonnegative_integer(k), small_nonnegative_integer(n_minus_k)) {
    (Some(left), Some(right)) => Some(if left < right { left } else { right })
    (Some(left), None) => Some(left)
    (None, Some(right)) => Some(right)
    (None, None) => None
  }
  match finite_order {
    Some(order) => {
      let mut numerator = @mpf.RawMpf::one()
      let mut denominator = @mpf.RawMpf::one()
      for j in 0..<order {
        numerator = numerator.mul(
          n.sub(@mpf.RawMpf::from_int(j), p, Nearest),
          p,
          Nearest,
        )
        denominator = denominator.mul_int(j + 1, p, Nearest)
      }
      return checked_mpf_div(numerator, denominator, p, Nearest).rounded(
        self.precision(),
        self.round_mode(),
      )
    }
    None => ()
  }
  let n_plus_one = n.add(@mpf.RawMpf::one(), p, Nearest)
  let k_plus_one = k.add(@mpf.RawMpf::one(), p, Nearest)
  let n_minus_k_plus_one = n_plus_one.sub(k, p, Nearest)
  self.gamma_product([n_plus_one], [k_plus_one, n_minus_k_plus_one])
}

///|
/// Evaluate the rising factorial `(x)_n` by gamma-ratio continuation.
pub fn MPContext::rising_factorial(
  self : MPContext,
  x : @mpf.RawMpf,
  n : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let p = ratio_working_precision(self)
  self.gamma_product([x.add(n, p, Nearest)], [x])
}

///|
/// Evaluate the falling factorial by gamma-ratio continuation.
pub fn MPContext::falling_factorial(
  self : MPContext,
  x : @mpf.RawMpf,
  n : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let p = ratio_working_precision(self)
  let x_plus_one = x.add(@mpf.RawMpf::one(), p, Nearest)
  let denominator = x.sub(n, p, Nearest).add(@mpf.RawMpf::one(), p, Nearest)
  self.gamma_product([x_plus_one], [denominator])
}

///|
fn exact_nonnegative_double_factorial(x : @mpf.RawMpf) -> @mpf.RawMpf? {
  let mut n = match small_nonnegative_integer(x) {
    Some(value) => value
    None => return None
  }
  let mut result = @mpf.RawMpf::one()
  while n > 1 {
    result = result.mul_int(n, 0, Nearest)
    n -= 2
  }
  Some(result)
}

///|
/// Evaluate the analytic continuation of the double factorial.
pub fn MPContext::double_factorial(
  self : MPContext,
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  if x.is_nan() || x == @mpf.RawMpf::negative_infinity() {
    return @mpf.RawMpf::nan()
  }
  if x == @mpf.RawMpf::infinity() {
    return @mpf.RawMpf::infinity()
  }
  match exact_nonnegative_double_factorial(x) {
    Some(value) => return value
    None => ()
  }
  let p = ratio_working_precision(self, extra=64)
  let half_x = x.scale_pow2(-1)
  let power_of_two = @libelefun.pow(@mpf.RawMpf::two(), half_x, p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let cosine = @libelefun.cos_pi(x, p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let pi_half = checked_mpf_pi(p, Nearest).scale_pow2(-1)
  let pi_exponent = cosine.sub(@mpf.RawMpf::one(), p, Nearest).scale_pow2(-2)
  let power_of_pi = @libelefun.pow(pi_half, pi_exponent, p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let gamma_value = gamma_checked_for_ratio(
    half_x.add(@mpf.RawMpf::one(), p, Nearest),
    p,
  )
  power_of_two
  .mul(power_of_pi, p, Nearest)
  .mul(gamma_value, p, Nearest)
  .rounded(self.precision(), self.round_mode())
}

///|
fn complex_is_gamma_pole(z : @mpc.RawMpc) -> Bool {
  z.imag.is_zero() && is_gamma_pole(z.real)
}

///|
/// Evaluate a complex quotient of gamma products with pole cancellation.
pub fn MPContext::complex_gamma_product(
  self : MPContext,
  numerators : ArrayView[@mpc.RawMpc],
  denominators : ArrayView[@mpc.RawMpc],
) -> @mpc.RawMpc raise MPError {
  let numerator_poles : Array[@mpc.RawMpc] = []
  let denominator_poles : Array[@mpc.RawMpc] = []
  let numerator_regular : Array[@mpc.RawMpc] = []
  let denominator_regular : Array[@mpc.RawMpc] = []
  for z in numerators {
    if complex_is_gamma_pole(z) {
      numerator_poles.push(z)
    } else {
      numerator_regular.push(z)
    }
  }
  for z in denominators {
    if complex_is_gamma_pole(z) {
      denominator_poles.push(z)
    } else {
      denominator_regular.push(z)
    }
  }
  if numerator_poles.length() < denominator_poles.length() {
    return @mpc.RawMpc::zero()
  }
  if numerator_poles.length() > denominator_poles.length() {
    return lift_ratio_real(@mpf.RawMpf::infinity())
  }
  let p = ratio_working_precision(
    self,
    extra=(numerators.length() + denominators.length()) * 8,
  )
  let mut product = @mpc.RawMpc::one()
  for i in 0..<numerator_poles.length() {
    let numerator_pole = numerator_poles[i].real
    let denominator_pole = denominator_poles[i].real
    let residue_ratio = checked_mpf_div(
      gamma_checked_for_ratio(
        @mpf.RawMpf::one().sub(denominator_pole, p, Nearest),
        p,
      ),
      gamma_checked_for_ratio(
        @mpf.RawMpf::one().sub(numerator_pole, p, Nearest),
        p,
      ),
      p,
      Nearest,
    )
    product = product.mul_real(residue_ratio, p, Nearest)
    if integer_value_is_odd(numerator_pole) !=
      integer_value_is_odd(denominator_pole) {
      product = product.negated(p, Nearest)
    }
  }
  for z in numerator_regular {
    product = product.mul(complex_gamma_checked_for_ratio(z, p), p, Nearest)
  }
  for z in denominator_regular {
    product = checked_mpc_div(
      product,
      complex_gamma_checked_for_ratio(z, p),
      p,
      Nearest,
    )
  }
  product.rounded(self.precision(), self.round_mode())
}

///|
/// Evaluate Euler's beta function on the principal complex continuation.
pub fn MPContext::complex_beta_function(
  self : MPContext,
  x : @mpc.RawMpc,
  y : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if x.imag.is_zero() && y.imag.is_zero() {
    return lift_ratio_real(self.beta_function(x.real, y.real))
  }
  if x.is_non_finite() || y.is_non_finite() {
    return @mpc.RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ratio_working_precision(self)
  self.complex_gamma_product([x, y], [x.add(y, p, Nearest)])
}

///|
/// Evaluate the generalized binomial coefficient on the complex plane.
pub fn MPContext::complex_binomial_coefficient(
  self : MPContext,
  n : @mpc.RawMpc,
  k : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if n.imag.is_zero() && k.imag.is_zero() {
    return lift_ratio_real(self.binomial_coefficient(n.real, k.real))
  }
  let p = ratio_working_precision(self)
  let n_plus_one = n.add_real(@mpf.RawMpf::one(), p, Nearest)
  let k_plus_one = k.add_real(@mpf.RawMpf::one(), p, Nearest)
  self.complex_gamma_product([n_plus_one], [
    k_plus_one,
    n_plus_one.sub(k, p, Nearest),
  ])
}

///|
/// Evaluate the complex rising factorial by gamma-ratio continuation.
pub fn MPContext::complex_rising_factorial(
  self : MPContext,
  x : @mpc.RawMpc,
  n : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if x.imag.is_zero() && n.imag.is_zero() {
    return lift_ratio_real(self.rising_factorial(x.real, n.real))
  }
  let p = ratio_working_precision(self)
  self.complex_gamma_product([x.add(n, p, Nearest)], [x])
}

///|
/// Evaluate the complex falling factorial by gamma-ratio continuation.
pub fn MPContext::complex_falling_factorial(
  self : MPContext,
  x : @mpc.RawMpc,
  n : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if x.imag.is_zero() && n.imag.is_zero() {
    return lift_ratio_real(self.falling_factorial(x.real, n.real))
  }
  let p = ratio_working_precision(self)
  let numerator = x.add_real(@mpf.RawMpf::one(), p, Nearest)
  let denominator = x
    .sub(n, p, Nearest)
    .add_real(@mpf.RawMpf::one(), p, Nearest)
  self.complex_gamma_product([numerator], [denominator])
}

///|
/// Evaluate the principal complex continuation of the double factorial.
pub fn MPContext::complex_double_factorial(
  self : MPContext,
  z : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  if z.imag.is_zero() {
    return lift_ratio_real(self.double_factorial(z.real))
  }
  if z.is_non_finite() {
    return @mpc.RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ratio_working_precision(self, extra=80)
  let half_z = z.scale_pow2(-1)
  let two = lift_ratio_real(@mpf.RawMpf::two())
  let power_of_two = two.pow(half_z, p, Nearest) catch {
    err => raise from_mpc_error(err)
  }
  let cosine = z.cos_pi(p, Nearest) catch { err => raise from_mpc_error(err) }
  let exponent = cosine.sub(@mpc.RawMpc::one(), p, Nearest).scale_pow2(-2)
  let pi_half = lift_ratio_real(checked_mpf_pi(p, Nearest).scale_pow2(-1))
  let power_of_pi = pi_half.pow(exponent, p, Nearest) catch {
    err => raise from_mpc_error(err)
  }
  let gamma_value = complex_gamma_checked_for_ratio(
    half_z.add_real(@mpf.RawMpf::one(), p, Nearest),
    p,
  )
  power_of_two
  .mul(power_of_pi, p, Nearest)
  .mul(gamma_value, p, Nearest)
  .rounded(self.precision(), self.round_mode())
}
