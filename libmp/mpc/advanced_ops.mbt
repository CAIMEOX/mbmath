///|
fn ext_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 20
  } else {
    48
  }
}

///|
fn lift_real(x : @mpf.RawMpf) -> RawMpc {
  RawMpc::new(x, @mpf.RawMpf::zero())
}

///|
fn format_mpf_checked(
  x : @mpf.RawMpf,
  dps? : Int = 15,
) -> String raise MpcError {
  x.format(dps~) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn mpc_log_checked(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.log(prec, rnd)
}

///|
fn mpc_ei_checked(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.ei(prec, rnd)
}

///|
fn nthroot_real_checked(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.nthroot(x, n, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn e1_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.e1(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn ei_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.ei(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn erf_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.erf(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn erfc_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.erfc(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn erfi_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.erfi(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn ci_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.ci(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn si_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.si(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn besseljn_real_checked(
  n : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.bessel_j(n, x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn ellipk_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.ellipk(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn ellipe_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libhyper.ellipe(x, prec, rnd) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
fn fibonacci_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.fibonacci(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn euler_constant_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.euler(prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn ln2_constant_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @libelefun.ln2(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn glaisher_constant_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.glaisher(prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn gamma_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.gamma(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn rgamma_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.rgamma(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn loggamma_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.loggamma(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn harmonic_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.harmonic(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn psi0_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.digamma(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn psi_real_checked(
  m : Int,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.polygamma(m, x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn bernoulli_checked(
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.bernoulli(n, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn altzeta_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.eta(x, prec, rnd) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn zeta_real_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> @mpf.RawMpf raise MpcError {
  @gammazeta.zeta(x, prec, rnd, alt~) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
fn factorial_mpf_small(n : Int, p : Int) -> @mpf.RawMpf {
  if n <= 1 {
    return @mpf.RawMpf::one()
  }
  let mut acc = @mpf.RawMpf::one()
  for i in 2..<=n {
    acc = acc.mul_int(i, p, Nearest)
  }
  acc
}

///|
fn tiny_enough_mpc(term : RawMpc, p : Int, bits : Int) -> Bool raise MpcError {
  let a = term.abs(p, Nearest)
  if a.is_zero() {
    true
  } else if !a.is_finite() {
    false
  } else {
    a.exp + a.bc <= -bits
  }
}

///|
fn int_bit_length(n : Int) -> Int {
  if n == 0 {
    return 0
  }
  let mut x = if n < 0 { -n } else { n }
  let mut bits = 0
  while x > 0 {
    bits += 1
    x = x >> 1
  }
  bits
}

///|
fn shift_big(x : BigInt, n : Int) -> BigInt {
  if n >= 0 {
    x >> n
  } else {
    x << -n
  }
}

///|
fn mpf_to_fixed_signed(x : @mpf.RawMpf, prec : Int) -> BigInt {
  if x.is_zero() {
    return 0N
  }
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  let offset = x.exp + prec
  if offset >= 0 {
    signed_man << offset
  } else {
    signed_man >> -offset
  }
}

///|
fn complex_mul_big(
  are : BigInt,
  aim : BigInt,
  bre : BigInt,
  bim : BigInt,
) -> (BigInt, BigInt) {
  (are * bre - aim * bim, are * bim + aim * bre)
}

///|
fn complex_int_pow_big(re : BigInt, im : BigInt, n : Int) -> (BigInt, BigInt) {
  if n == 0 {
    return (1N, 0N)
  }
  let mut e = n
  let mut base_re = re
  let mut base_im = im
  let mut acc_re = 1N
  let mut acc_im = 0N
  while e > 0 {
    if (e & 1) == 1 {
      let (nr, ni) = complex_mul_big(acc_re, acc_im, base_re, base_im)
      acc_re = nr
      acc_im = ni
    }
    e = e / 2
    if e > 0 {
      let (br, bi) = complex_mul_big(base_re, base_im, base_re, base_im)
      base_re = br
      base_im = bi
    }
  }
  (acc_re, acc_im)
}

///|
pub fn RawMpc::nthroot_fixed(
  a : BigInt,
  b : BigInt,
  n : Int,
  prec : Int,
) -> (BigInt, BigInt) raise MpcError {
  let start = 50
  let extra = 10
  let z = RawMpc::new(
    @mpf.RawMpf::from_mantissa_exponent(a, -prec, 0, Down),
    @mpf.RawMpf::from_mantissa_exponent(b, -prec, 0, Down),
  )
  let low_prec = start + 12
  let nth = mpf_rdiv_int_checked(1, @mpf.RawMpf::from_int(n), low_prec, Nearest)
  let seed = z.pow_real(nth, low_prec, Nearest)
  let mut re = mpf_to_fixed_signed(seed.real, start)
  let mut im = mpf_to_fixed_signed(seed.imag, start)
  let mut prevp = start
  let target = prec + extra
  let mut p = start
  while p < target {
    p = if p * 2 < target { p * 2 } else { target }
    let (pow_re, pow_im) = complex_int_pow_big(re, im, n - 1)
    let scale = (n - 1) * prevp - p - n
    let re2 = shift_big(pow_re, scale)
    let im2 = shift_big(pow_im, scale)
    let r4 = (re2 * re2 + im2 * im2) >> (p + n)
    let ap = shift_big(a, prec - p)
    let bp = shift_big(b, prec - p)
    let rec = (ap * re2 + bp * im2) >> p
    let imc = (-ap * im2 + bp * re2) >> p
    let reb = (rec << p) / r4
    let imb = (imc << p) / r4
    re = (reb + BigInt::from_int(n - 1) * (re << (p - prevp))) /
      BigInt::from_int(n)
    im = (imb + BigInt::from_int(n - 1) * (im << (p - prevp))) /
      BigInt::from_int(n)
    prevp = p
  }
  (re, im)
}

///|
fn complex_loggamma_stirling_right(
  z : RawMpc,
  p : Int,
) -> RawMpc raise MpcError {
  let target = {
    let value = p / 3 + 12
    if value < 32 {
      32
    } else {
      value
    }
  }
  let mut w = z.rounded(p, Nearest)
  let mut recurrence = RawMpc::zero()
  while w.real < @mpf.RawMpf::from_int(target) {
    recurrence = recurrence.add(w.ln(p, Nearest), p, Nearest)
    w = w.add_real(@mpf.RawMpf::one(), p, Nearest)
  }
  let log_w = w.ln(p, Nearest)
  let half = @mpf.RawMpf::half()
  let ln_sqrt_2pi = @libelefun.ln_sqrt_2pi(p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let mut value = w
    .sub_real(half, p, Nearest)
    .mul(log_w, p, Nearest)
    .sub(w, p, Nearest)
    .add_real(ln_sqrt_2pi, p, Nearest)
  let inv = w.reciprocal(p, Nearest)
  let inv2 = inv.square(p, Nearest)
  let mut inv_power = inv
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 16
  for k in 1..<=max_terms {
    let two_k = 2 * k
    let denominator = @mpf.RawMpf::from_int(two_k * (two_k - 1))
    let coefficient = mpf_div_checked(
      bernoulli_checked(two_k, p, Nearest),
      denominator,
      p,
      Nearest,
    )
    let term = inv_power.mul_real(coefficient, p, Nearest)
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    value = value.add(term, p, Nearest)
    if k > 3 && tiny_enough_mpc(term, p, p + 12) {
      break
    }
    previous = magnitude
    inv_power = inv_power.mul(inv2, p, Nearest)
  }
  value.sub(recurrence, p, Nearest)
}

///|
fn complex_loggamma_general(z : RawMpc, p : Int) -> RawMpc raise MpcError {
  if z.real.sign == 0 {
    return complex_loggamma_stirling_right(z, p)
  }
  let neg_z = z.negated(p, Nearest)
  let mut value = complex_loggamma_stirling_right(neg_z, p)
    .negated(p, Nearest)
    .sub(neg_z.ln(p, Nearest), p, Nearest)
  let pi = elefun_pi_checked(p, Nearest)
  value = value.add_real(mpf_log_checked(pi, p, Nearest), p, Nearest)
  let floor_re = z.real.floor(0, Down)
  let fractional = z.sub_real(floor_re, p, Nearest)
  value = value.sub(fractional.sin_pi(p, Nearest).ln(p, Nearest), p, Nearest)
  let branch = pi.mul(floor_re, p, Nearest).mul_int(z.imag.signum(), p, Nearest)
  value.add(RawMpc::new(@mpf.RawMpf::zero(), branch), p, Nearest)
}

///|
fn error_series_work_precision(z : RawMpc, base_p : Int) -> Int {
  let magnitude = mpc_mag_bound(z)
  let exponent = 2 * magnitude + 2
  let cancellation = if exponent <= 0 {
    8
  } else if exponent >= 30 {
    base_p
  } else {
    let estimate = 1 << exponent
    if estimate > base_p {
      base_p
    } else {
      estimate
    }
  }
  base_p + cancellation + 64
}

///|
fn complex_norm_squared(z : RawMpc, p : Int) -> @mpf.RawMpf {
  z.real.mul(z.real, p, Nearest).add(z.imag.mul(z.imag, p, Nearest), p, Nearest)
}

///|
fn complex_error_series(z : RawMpc, base_p : Int) -> RawMpc raise MpcError {
  let p = error_series_work_precision(z, base_p)
  let z_work = z.rounded(p, Nearest)
  let z2 = z_work.square(p, Nearest)
  let mut term = z_work
  let mut sum = term
  let mut converged = false
  let max_terms = 4 * p + 128
  for k in 0..<max_terms {
    term = term.mul(z2, p, Nearest).mul_int(-(2 * k + 1), p, Nearest)
    term = term.div_real(@mpf.RawMpf::from_int(k + 1), p, Nearest)
    term = term.div_real(@mpf.RawMpf::from_int(2 * k + 3), p, Nearest)
    sum = sum.add(term, p, Nearest)
    if k > 3 && tiny_enough_mpc(term, p, base_p + 32) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError(
      "complex error function power series did not converge",
    )
  }
  let scale = @libelefun.sqrt_pi(p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  sum.mul_real(
    mpf_div_checked(@mpf.RawMpf::two(), scale, p, Nearest),
    p,
    Nearest,
  )
}

///|
fn complex_erfc_asymptotic(z : RawMpc, base_p : Int) -> RawMpc raise MpcError {
  let p = base_p + 48
  let z_work = z.rounded(p, Nearest)
  let inverse_square = z_work.square(p, Nearest).reciprocal(p, Nearest)
  let mut term = RawMpc::one()
  let mut sum = term
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  let max_terms = 2 * base_p + 96
  for k in 1..<=max_terms {
    term = term
      .mul(inverse_square, p, Nearest)
      .mul_int(-(2 * k - 1), p, Nearest)
      .scale_pow2(-1)
    let magnitude = term.abs(p, Nearest)
    if k > 3 && magnitude >= previous {
      break
    }
    sum = sum.add(term, p, Nearest)
    let relative_bound = sum.abs(p, Nearest).scale_pow2(-(base_p + 24))
    if k > 3 && magnitude <= relative_bound {
      converged = true
      break
    }
    previous = magnitude
  }
  if !converged {
    raise ConvergenceError(
      "complex complementary error asymptotic did not converge",
    )
  }
  let exponential = z_work
    .square(p, Nearest)
    .negated(p, Nearest)
    .exp(p, Nearest)
  let sqrt_pi = @libelefun.sqrt_pi(p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let denominator = z_work.mul_real(sqrt_pi, p, Nearest)
  let value = exponential.div(denominator, p, Nearest).mul(sum, p, Nearest)
  if z.real.is_zero() {
    RawMpc::new(@mpf.RawMpf::one(), value.imag)
  } else {
    value
  }
}

///|
fn should_use_error_asymptotic(z : RawMpc, p : Int) -> Bool {
  complex_norm_squared(z, 32) > @mpf.RawMpf::from_int(p + 64)
}

///|
fn mpc_mag_bound(z : RawMpc) -> Int {
  let mut mag = if z.real.is_zero() {
    if z.imag.is_zero() {
      0
    } else {
      z.imag.exp + z.imag.bc
    }
  } else {
    z.real.exp + z.real.bc
  }
  if !z.imag.is_zero() {
    let im_mag = z.imag.exp + z.imag.bc
    if im_mag > mag {
      mag = im_mag
    }
  }
  mag
}

///|
fn mpc_ci_si_asymptotic(z : RawMpc, p : Int) -> (RawMpc, RawMpc) raise MpcError {
  let z_inv = z.reciprocal(p, Nearest)
  let z_inv2 = z_inv.mul(z_inv, p, Nearest)
  let mut f_term = z_inv
  let mut f_sum = f_term
  let mut g_term = z_inv2
  let mut g_sum = g_term
  let max_terms = 2 * p + 128
  let mut m = 0
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  while m < max_terms {
    let a = 2 * m + 2
    f_term = f_term.mul(z_inv2, p, Nearest)
    f_term = f_term.mul_int(-(a * (a - 1)), p, Nearest)
    g_term = g_term.mul(z_inv2, p, Nearest)
    g_term = g_term.mul_int(-((a + 1) * a), p, Nearest)
    let magnitude = {
      let f_abs = f_term.abs(p, Nearest)
      let g_abs = g_term.abs(p, Nearest)
      if f_abs > g_abs {
        f_abs
      } else {
        g_abs
      }
    }
    if m > 3 && magnitude >= previous {
      break
    }
    f_sum = f_sum.add(f_term, p, Nearest)
    g_sum = g_sum.add(g_term, p, Nearest)
    if tiny_enough_mpc(f_term, p, p + 6) &&
      tiny_enough_mpc(g_term, p, p + 6) &&
      m > 3 {
      converged = true
      break
    }
    previous = magnitude
    m += 1
  }
  if !converged {
    raise ConvergenceError(
      "complex trigonometric integral asymptotic did not converge",
    )
  }
  let (cos_z, sin_z) = z.cos_sin(p, Nearest)
  let ci = sin_z
    .mul(f_sum, p, Nearest)
    .sub(cos_z.mul(g_sum, p, Nearest), p, Nearest)
  let half_pi = RawMpc::new(
    elefun_pi_checked(p, Nearest).scale_pow2(-1),
    @mpf.RawMpf::zero(),
  )
  let si = half_pi.sub(
    cos_z.mul(f_sum, p, Nearest).add(sin_z.mul(g_sum, p, Nearest), p, Nearest),
    p,
    Nearest,
  )
  (ci, si)
}

///|
fn should_use_inverse_factorial_asymptotic(z : RawMpc, p : Int) -> Bool {
  let threshold = @mpf.RawMpf::from_int(p + 64)
  complex_norm_squared(z, 32) > threshold.mul(threshold, 32, Nearest)
}

///|
fn zeta_series_sum(
  s : RawMpc,
  p : Int,
  start : Int,
  terms : Int,
  alternating : Bool,
) -> RawMpc raise MpcError {
  if terms <= 0 {
    return RawMpc::zero()
  }
  let minus_s = s.negated(p, Nearest)
  let mut sum = RawMpc::zero()
  let mut counted = 0
  for i in 0..<terms {
    let k = start + i
    if k <= 0 {
      continue
    }
    let base = RawMpc::new(@mpf.RawMpf::from_int(k), @mpf.RawMpf::zero())
    let term = mpc_pow_checked(base, minus_s, p, Nearest)
    if alternating && (k & 1) == 0 {
      sum = sum.sub(term, p, Nearest)
    } else {
      sum = sum.add(term, p, Nearest)
    }
    counted += 1
    let abs_term = term.abs(p, Nearest)
    if counted > 32 &&
      abs_term.is_finite() &&
      abs_term.exp + abs_term.bc <= -p + 4 {
      break
    }
  }
  sum
}

///|
fn zeta_alt_factor_complex(s : RawMpc, p : Int) -> RawMpc raise MpcError {
  let one_minus_s = RawMpc::one().sub(s, p, Nearest)
  let two_pow = mpc_pow_checked(
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()),
    one_minus_s,
    p,
    Nearest,
  )
  RawMpc::one().sub(two_pow, p, Nearest)
}

///|
fn nonnegative_ceiling_to_int(x : @mpf.RawMpf) -> Int raise MpcError {
  if !x.is_finite() {
    raise ConvergenceError("complex zeta requires a finite imaginary part")
  }
  let integer = x.abs(0, Down).to_integer(rnd=Ceiling) catch {
      err => raise from_mpf_error(err)
    }
  if integer.bit_length() > 60 {
    raise ConvergenceError(
      "complex zeta argument requires too many Borwein terms",
    )
  }
  integer.to_int()
}

///|
fn zeta_euler_maclaurin_complex(s : RawMpc, p : Int) -> RawMpc raise MpcError {
  let imaginary_size = nonnegative_ceiling_to_int(s.imag)
  let n = (24 + p / 3 + imaginary_size).max(48)
  let mut sum = zeta_series_sum(s, p, 1, n - 1, false)
  let n_mpf = @mpf.RawMpf::from_int(n)
  let n_complex = RawMpc::new(n_mpf, @mpf.RawMpf::zero())
  let n_negative_s = mpc_pow_checked(
    n_complex,
    s.negated(p, Nearest),
    p,
    Nearest,
  )
  let integral_tail = n_negative_s
    .mul_real(n_mpf, p, Nearest)
    .div(s.sub(RawMpc::one(), p, Nearest), p, Nearest)
  sum = sum
    .add(integral_tail, p, Nearest)
    .add(n_negative_s.scale_pow2(-1), p, Nearest)
  let inverse_n = mpf_div_checked(@mpf.RawMpf::one(), n_mpf, p, Nearest)
  let inverse_n_squared = inverse_n.mul(inverse_n, p, Nearest)
  let mut power = n_negative_s.mul_real(inverse_n, p, Nearest)
  let mut rising = s.rounded(p, Nearest)
  let mut factorial_value = @mpf.RawMpf::two()
  let max_terms = p / 2 + 4 * int_bit_length(imaginary_size + 2) + 32
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  for k in 1..<=max_terms {
    let coefficient = mpf_div_checked(
      bernoulli_checked(2 * k, p, Nearest),
      factorial_value,
      p,
      Nearest,
    )
    let term = rising.mul(power, p, Nearest).mul_real(coefficient, p, Nearest)
    let magnitude = term.abs(24, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    sum = sum.add(term, p, Nearest)
    if k > 3 && complex_relative_tiny(term, sum, 24, (p - 48).max(32)) {
      converged = true
      break
    }
    previous = magnitude
    power = power.mul_real(inverse_n_squared, p, Nearest)
    rising = rising
      .mul(s.add_real(@mpf.RawMpf::from_int(2 * k - 1), p, Nearest), p, Nearest)
      .mul(s.add_real(@mpf.RawMpf::from_int(2 * k), p, Nearest), p, Nearest)
    factorial_value = factorial_value
      .mul_int(2 * k + 1, 0, Down)
      .mul_int(2 * k + 2, 0, Down)
  }
  if !converged {
    raise ConvergenceError(
      "complex zeta Euler-Maclaurin expansion did not converge",
    )
  }
  sum
}

///|
fn borwein_coefficients(n : Int) -> Array[BigInt] {
  let coefficients = Array::make(n + 1, 0N)
  let mut d = 1N
  let mut sum = 1N
  coefficients[0] = sum
  for i in 1..<=n {
    d = d *
      4N *
      BigInt::from_int(n + i - 1) *
      BigInt::from_int(n - i + 1) /
      (BigInt::from_int(2 * i) * BigInt::from_int(2 * i - 1))
    sum = sum + d
    coefficients[i] = sum
  }
  coefficients
}

///|
fn zeta_borwein_eta_complex(
  s : RawMpc,
  target_p : Int,
) -> RawMpc raise MpcError {
  let imaginary_size = nonnegative_ceiling_to_int(s.imag)
  // The Borwein error is bounded by roughly 2^(2.28*|Im(s)|-2.54*n).
  // Using 3/2 coefficients below leaves a conservative rounding margin.
  let n = (target_p + 3 * imaginary_size + 1) / 2 + 16
  let p = target_p + 64 + 2 * int_bit_length(n + 1)
  let coefficients = borwein_coefficients(n)
  let denominator = @mpf.RawMpf::from_bigint(coefficients[n])
  let minus_s = s.negated(p, Nearest)
  let mut sum = RawMpc::zero()
  for k in 0..<n {
    let weight = mpf_div_checked(
      @mpf.RawMpf::from_bigint(coefficients[n] - coefficients[k]),
      denominator,
      p,
      Nearest,
    )
    let base = RawMpc::new(@mpf.RawMpf::from_int(k + 1), @mpf.RawMpf::zero())
    let term = mpc_pow_checked(base, minus_s, p, Nearest).mul_real(
      weight,
      p,
      Nearest,
    )
    if (k & 1) == 0 {
      sum = sum.add(term, p, Nearest)
    } else {
      sum = sum.sub(term, p, Nearest)
    }
  }
  sum.rounded(target_p, Nearest)
}

///|
fn zeta_right_half_plane_complex(s : RawMpc, p : Int) -> RawMpc raise MpcError {
  let probe_p = p + 64
  let factor_probe = zeta_alt_factor_complex(s, probe_p)
  let factor_magnitude = factor_probe.abs(24, Nearest)
  let factor_cancellation_bits = if factor_magnitude.is_zero() {
    probe_p
  } else {
    (-(factor_magnitude.exp + factor_magnitude.bc)).max(0)
  }
  if factor_cancellation_bits > 16 {
    return zeta_euler_maclaurin_complex(s, p + 64).rounded(p, Nearest)
  }
  let work_p = p + 32
  let eta = zeta_borwein_eta_complex(s, work_p)
  let factor = zeta_alt_factor_complex(s, work_p)
  eta.div(factor, work_p, Nearest).rounded(p, Nearest)
}

///|
fn zeta_reflection_complex(s : RawMpc, p : Int) -> RawMpc raise MpcError {
  let one_minus_s = RawMpc::one().sub(s, p, Nearest)
  let two_pow_s = mpc_pow_checked(
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()),
    s,
    p,
    Nearest,
  )
  let pi = elefun_pi_checked(p, Nearest)
  let pi_pow = mpc_pow_checked(
    RawMpc::new(pi, @mpf.RawMpf::zero()),
    s.sub(RawMpc::one(), p, Nearest),
    p,
    Nearest,
  )
  let sin_term = s.scale_pow2(-1).sin_pi(p, Nearest)
  let gamma_term = one_minus_s.gamma(p, Nearest)
  let zeta_term = zeta_right_half_plane_complex(one_minus_s, p)
  two_pow_s.mul(
    pi_pow.mul(
      sin_term.mul(gamma_term.mul(zeta_term, p, Nearest), p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
}

///|
pub fn RawMpc::format(z : RawMpc, dps? : Int = 15) -> String raise MpcError {
  let rs = format_mpf_checked(z.real, dps~)
  if z.imag.sign == 1 && !z.imag.is_zero() {
    let im_abs = z.imag.negated(0, Down)
    let im_s = format_mpf_checked(im_abs, dps~)
    rs + " - " + im_s + "j"
  } else {
    let im_s = format_mpf_checked(z.imag, dps~)
    rs + " + " + im_s + "j"
  }
}

///|
pub fn RawMpc::format_components(
  z : RawMpc,
  dps? : Int = 17,
) -> (String, String) raise MpcError {
  (format_mpf_checked(z.real, dps~), format_mpf_checked(z.imag, dps~))
}

///|
pub fn RawMpc::stable_hash(z : RawMpc) -> Int {
  let mut h = z.real.stable_hash() + 1000003 * z.imag.stable_hash()
  if h == -1 {
    h = -2
  }
  h
}

///|
pub impl Hash for RawMpc with fn hash(z) {
  z.stable_hash()
}

///|
pub impl Hash for RawMpc with fn hash_combine(z, hasher) {
  hasher.combine_int(z.stable_hash())
}

///|
pub fn RawMpc::ln(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  mpc_log_checked(z, prec, rnd)
}

///|
pub fn RawMpc::cos_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return RawMpc::new(
      elefun_cos_pi_checked(z.real, prec, rnd),
      @mpf.RawMpf::zero(),
    )
  }
  let p = ext_prec(prec) + 6
  let b_pi = z.imag.mul(elefun_pi_checked(p, Nearest), p, Nearest)
  if z.real == @mpf.RawMpf::zero() {
    return RawMpc::new(
      elefun_cosh_checked(b_pi, prec, rnd),
      @mpf.RawMpf::zero(),
    )
  }
  let (c, s) = elefun_cos_sin_pi_checked(z.real, p, Nearest)
  let (ch, sh) = elefun_cosh_sinh_checked(b_pi, p, Nearest)
  RawMpc::new(c.mul(ch, prec, rnd), s.mul(sh, p, Nearest).negated(prec, rnd))
}

///|
pub fn RawMpc::sin_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return RawMpc::new(
      elefun_sin_pi_checked(z.real, prec, rnd),
      @mpf.RawMpf::zero(),
    )
  }
  let p = ext_prec(prec) + 6
  let b_pi = z.imag.mul(elefun_pi_checked(p, Nearest), p, Nearest)
  if z.real == @mpf.RawMpf::zero() {
    return RawMpc::new(
      @mpf.RawMpf::zero(),
      elefun_sinh_checked(b_pi, prec, rnd),
    )
  }
  let (c, s) = elefun_cos_sin_pi_checked(z.real, p, Nearest)
  let (ch, sh) = elefun_cosh_sinh_checked(b_pi, p, Nearest)
  RawMpc::new(s.mul(ch, prec, rnd), c.mul(sh, prec, rnd))
}

///|
pub fn RawMpc::cos_sin(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) raise MpcError {
  if z.real == @mpf.RawMpf::zero() {
    let (ch, sh) = elefun_cosh_sinh_checked(z.imag, prec, rnd)
    return (
      RawMpc::new(ch, @mpf.RawMpf::zero()),
      RawMpc::new(@mpf.RawMpf::zero(), sh),
    )
  }
  if z.imag == @mpf.RawMpf::zero() {
    let (c, s) = elefun_cos_sin_checked(z.real, prec, rnd)
    return (
      RawMpc::new(c, @mpf.RawMpf::zero()),
      RawMpc::new(s, @mpf.RawMpf::zero()),
    )
  }
  let p = ext_prec(prec) + 6
  let (c, s) = elefun_cos_sin_checked(z.real, p, Nearest)
  let (ch, sh) = elefun_cosh_sinh_checked(z.imag, p, Nearest)
  let cz = RawMpc::new(
    c.mul(ch, prec, rnd),
    s.mul(sh, p, Nearest).negated(prec, rnd),
  )
  let sz = RawMpc::new(s.mul(ch, prec, rnd), c.mul(sh, prec, rnd))
  (cz, sz)
}

///|
pub fn RawMpc::cos_sin_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    let (c, s) = elefun_cos_sin_pi_checked(z.real, prec, rnd)
    return (
      RawMpc::new(c, @mpf.RawMpf::zero()),
      RawMpc::new(s, @mpf.RawMpf::zero()),
    )
  }
  let p = ext_prec(prec) + 6
  let b_pi = z.imag.mul(elefun_pi_checked(p, Nearest), p, Nearest)
  if z.real == @mpf.RawMpf::zero() {
    let (ch, sh) = elefun_cosh_sinh_checked(b_pi, prec, rnd)
    return (
      RawMpc::new(ch, @mpf.RawMpf::zero()),
      RawMpc::new(@mpf.RawMpf::zero(), sh),
    )
  }
  let (c, s) = elefun_cos_sin_pi_checked(z.real, p, Nearest)
  let (ch, sh) = elefun_cosh_sinh_checked(b_pi, p, Nearest)
  let cz = RawMpc::new(
    c.mul(ch, prec, rnd),
    s.mul(sh, p, Nearest).negated(prec, rnd),
  )
  let sz = RawMpc::new(s.mul(ch, prec, rnd), c.mul(sh, prec, rnd))
  (cz, sz)
}

///|
pub fn RawMpc::exp_i(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    let (c, s) = elefun_cos_sin_checked(z.real, prec, rnd)
    return RawMpc::new(c, s)
  }
  if z.real == @mpf.RawMpf::zero() {
    return RawMpc::new(
      elefun_exp_checked(z.imag.negated(0, Down), prec, rnd),
      @mpf.RawMpf::zero(),
    )
  }
  let p = ext_prec(prec)
  let ey = elefun_exp_checked(z.imag.negated(p, Nearest), p, Nearest)
  let (c, s) = elefun_cos_sin_checked(z.real, p, Nearest)
  RawMpc::new(ey.mul(c, prec, rnd), ey.mul(s, prec, rnd))
}

///|
pub fn RawMpc::exp_i_pi(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    let (c, s) = elefun_cos_sin_pi_checked(z.real, prec, rnd)
    return RawMpc::new(c, s)
  }
  let p = ext_prec(prec)
  let im = elefun_pi_checked(p, Nearest)
    .mul(z.imag, p, Nearest)
    .negated(p, Nearest)
  if z.real == @mpf.RawMpf::zero() {
    return RawMpc::new(elefun_exp_checked(im, prec, rnd), @mpf.RawMpf::zero())
  }
  let ey = elefun_exp_checked(im, p, Nearest)
  let (c, s) = elefun_cos_sin_pi_checked(z.real, p, Nearest)
  RawMpc::new(ey.mul(c, prec, rnd), ey.mul(s, prec, rnd))
}

///|
pub fn RawMpc::atan(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  let x = RawMpc::new(
    @mpf.RawMpf::one().add(z.imag, p, Nearest),
    z.real.negated(0, Down),
  )
  let y = RawMpc::new(@mpf.RawMpf::one().sub(z.imag, p, Nearest), z.real)
  let l1 = x.ln(p, Nearest)
  let l2 = y.ln(p, Nearest)
  let d = l1.sub(l2, p, Nearest)
  let mut v = RawMpc::new(
    d.imag.scale_pow2(-1).negated(p, Nearest),
    d.real.scale_pow2(-1),
  )
  v = v.rounded(prec, rnd)
  if v.imag.is_nan() && z.is_infinite() {
    v = RawMpc::new(v.real, @mpf.RawMpf::zero())
  }
  v
}

///|
pub fn RawMpc::asinh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  let reflect = (!z.real.is_nan() && z.real.sign == 1) ||
    (z.real.is_zero() && !z.imag.is_nan() && z.imag.sign == 1)
  if reflect {
    let reflected = z.negated(p, Nearest).asinh(p, Nearest)
    return reflected.negated(p, Nearest).rounded(prec, rnd)
  }
  let inside = z.square(p, Nearest).add(RawMpc::one(), p, Nearest)
  let root = inside.sqrt(p, Nearest)
  z.add(root, p, Nearest).ln(prec, rnd)
}

///|
pub fn RawMpc::asin(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  if z.real.is_infinite() && z.imag.is_infinite() {
    let pi4 = elefun_pi_checked(p, Nearest).scale_pow2(-2)
    return RawMpc::new(
      if z.real.sign == 1 {
        pi4.negated(p, Nearest)
      } else {
        pi4
      },
      if z.imag.sign == 1 {
        @mpf.RawMpf::negative_infinity()
      } else {
        @mpf.RawMpf::infinity()
      },
    ).rounded(prec, rnd)
  }
  if z.real.is_infinite() && z.imag.is_nan() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::negative_infinity())
  }
  if z.real.is_nan() && z.imag.is_infinite() {
    return RawMpc::new(
      @mpf.RawMpf::nan(),
      if z.imag.sign == 1 {
        @mpf.RawMpf::negative_infinity()
      } else {
        @mpf.RawMpf::infinity()
      },
    )
  }
  if z.real.is_infinite() {
    let pi2 = elefun_pi_checked(p, Nearest).scale_pow2(-1)
    return RawMpc::new(
      if z.real.sign == 1 {
        pi2.negated(p, Nearest)
      } else {
        pi2
      },
      if z.imag.sign == 1 {
        @mpf.RawMpf::negative_infinity()
      } else {
        @mpf.RawMpf::infinity()
      },
    ).rounded(prec, rnd)
  }
  if z.imag.is_infinite() {
    return RawMpc::new(
      @mpf.RawMpf::zero(),
      if z.imag.sign == 1 {
        @mpf.RawMpf::negative_infinity()
      } else {
        @mpf.RawMpf::infinity()
      },
    )
  }
  let iz = RawMpc::new(z.imag.negated(0, Down), z.real)
  let w = iz.asinh(p, Nearest)
  RawMpc::new(w.imag, w.real.negated(0, Down)).rounded(prec, rnd)
}

///|
pub fn RawMpc::acos(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  if z.real.is_infinite() && z.imag.is_infinite() {
    let pi = elefun_pi_checked(p, Nearest)
    let pi4 = pi.scale_pow2(-2)
    return RawMpc::new(
      if z.real.sign == 1 {
        pi.sub(pi4, p, Nearest)
      } else {
        pi4
      },
      if z.imag.sign == 1 {
        @mpf.RawMpf::infinity()
      } else {
        @mpf.RawMpf::negative_infinity()
      },
    ).rounded(prec, rnd)
  }
  if z.real.is_infinite() && z.imag.is_nan() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::infinity())
  }
  if z.real.is_nan() && z.imag.is_infinite() {
    return RawMpc::new(
      @mpf.RawMpf::nan(),
      if z.imag.sign == 1 {
        @mpf.RawMpf::infinity()
      } else {
        @mpf.RawMpf::negative_infinity()
      },
    )
  }
  if z.real.is_infinite() {
    let pi = elefun_pi_checked(p, Nearest)
    return RawMpc::new(
      if z.real.sign == 1 {
        pi
      } else {
        @mpf.RawMpf::zero()
      },
      if z.imag.sign == 1 {
        @mpf.RawMpf::infinity()
      } else {
        @mpf.RawMpf::negative_infinity()
      },
    ).rounded(prec, rnd)
  }
  if z.imag.is_infinite() {
    let pi2 = elefun_pi_checked(p, Nearest).scale_pow2(-1)
    return RawMpc::new(
      pi2,
      if z.imag.sign == 1 {
        @mpf.RawMpf::infinity()
      } else {
        @mpf.RawMpf::negative_infinity()
      },
    ).rounded(prec, rnd)
  }
  let half_pi = elefun_pi_checked(p, Nearest).scale_pow2(-1)
  let a = z.asin(p, Nearest)
  RawMpc::new(half_pi.sub(a.real, p, Nearest), a.imag.negated(0, Down)).rounded(
    prec, rnd,
  )
}

///|
pub fn RawMpc::acosh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  let one_z = RawMpc::one()
  let s1 = z.sub(one_z, p, Nearest).sqrt(p, Nearest)
  let s2 = z.add(one_z, p, Nearest).sqrt(p, Nearest)
  z.add(s1.mul(s2, p, Nearest), p, Nearest).ln(prec, rnd)
}

///|
pub fn RawMpc::atanh(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 10
  let a = z.add(RawMpc::one(), p, Nearest).ln(p, Nearest)
  let b = RawMpc::one().sub(z, p, Nearest).ln(p, Nearest)
  let mut v = a.sub(b, p, Nearest).scale_pow2(-1)
  v = v.rounded(prec, rnd)
  if v.real.is_nan() && z.is_infinite() {
    v = RawMpc::new(@mpf.RawMpf::zero(), v.imag)
  }
  v
}

///|
pub fn RawMpc::nthroot(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if n < 2 {
    if n == 0 {
      raise ValueError("RawMpc::nthroot: root index must be non-zero")
    }
    if n == 1 {
      return z.rounded(prec, rnd)
    }
    if n == -1 {
      return z.reciprocal(prec, rnd)
    }
    let inv = z.nthroot(-n, prec + 8, Nearest)
    return inv.reciprocal(prec, rnd)
  }
  if z.imag == @mpf.RawMpf::zero() && z.real.sign == 0 {
    return RawMpc::new(
      nthroot_real_checked(z.real, n, prec, rnd),
      @mpf.RawMpf::zero(),
    )
  }
  if n <= 20 {
    let prec2 = (prec + 10) * 6 / 5
    let abs_z = z.abs(prec2, Nearest)
    let mag = abs_z.exp + abs_z.bc
    if mag > -10 && mag < prec2 {
      let af = mpf_to_fixed_signed(z.real, prec2)
      let bf = mpf_to_fixed_signed(z.imag, prec2)
      let extra = 10
      let (re_fix, im_fix) = RawMpc::nthroot_fixed(af, bf, n, prec2)
      let re = @mpf.RawMpf::from_mantissa_exponent(
        re_fix,
        -(prec2 + extra),
        prec2,
        Nearest,
      )
      let im = @mpf.RawMpf::from_mantissa_exponent(
        im_fix,
        -(prec2 + extra),
        prec2,
        Nearest,
      )
      return RawMpc::new(re, im).rounded(prec, rnd)
    }
  }
  let p = ext_prec(prec) + 10
  let inv_n = mpf_rdiv_int_checked(1, @mpf.RawMpf::from_int(n), p, Nearest)
  z.pow_real(inv_n, p, Nearest).rounded(prec, rnd)
}

///|
pub fn RawMpc::cbrt(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.nthroot(3, prec, rnd)
}

///|
pub fn RawMpc::fibonacci(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(fibonacci_real_checked(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 12
  let phi = elefun_phi_checked(p, Nearest)
  let denom = phi.scale_pow2(1).add(@mpf.RawMpf::negative_one(), p, Nearest)
  let u = mpc_pow_checked(RawMpc::new(phi, @mpf.RawMpf::zero()), z, p, Nearest)
  let v = z.cos_pi(p, Nearest).div(u, p, Nearest)
  let num = u.sub(v, p, Nearest)
  num.div_real(denom, prec, rnd)
}

///|
pub fn RawMpc::agm(
  a : RawMpc,
  b : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if a.is_non_finite() || b.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if a == RawMpc::zero() || b == RawMpc::zero() || a.negated(0, Down) == b {
    return RawMpc::zero()
  }
  let p = ext_prec(prec) + 32
  let eps = @mpf.RawMpf::one().scale_pow2(-(p - 16))
  let mut x = a
  let mut y = b
  let mut converged = false
  let max_iterations = p + 64
  for _ in 0..<max_iterations {
    let x1 = x.add(y, p, Nearest).scale_pow2(-1)
    let y1 = x.mul(y, p, Nearest).sqrt(p, Nearest)
    x = x1
    y = y1
    let size = x.abs(p, Nearest)
    let err = x.sub(y, p, Nearest).abs(p, Nearest)
    if size == @mpf.RawMpf::zero() || err < eps.mul(size, p, Nearest) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError("complex arithmetic-geometric mean did not converge")
  }
  x.rounded(prec, rnd)
}

///|
pub fn RawMpc::agm_with_one(
  a : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  RawMpc::one().agm(a, prec, rnd)
}

///|
/// Evaluate the entire Gaussian error function for a complex argument.
pub fn RawMpc::error_function(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag.is_zero() {
    return lift_real(erf_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if z == RawMpc::zero() {
    return RawMpc::zero()
  }
  let base_p = ext_prec(prec) + 32
  if z.real.sign == 1 {
    return z
      .negated(base_p, Nearest)
      .error_function(base_p, Nearest)
      .negated(prec, rnd)
  }
  if should_use_error_asymptotic(z, base_p) {
    return RawMpc::one()
      .sub(complex_erfc_asymptotic(z, base_p), base_p, Nearest)
      .rounded(prec, rnd)
  }
  complex_error_series(z, base_p).rounded(prec, rnd)
}

///|
/// Evaluate the complementary Gaussian error function in a form that retains
/// exponentially small tails in the right half-plane.
pub fn RawMpc::complementary_error_function(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag.is_zero() {
    return lift_real(erfc_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if z == RawMpc::zero() {
    return RawMpc::one()
  }
  let base_p = ext_prec(prec) + 32
  if z.real.sign == 1 {
    let reflected = z
      .negated(base_p, Nearest)
      .complementary_error_function(base_p, Nearest)
    return RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero())
      .sub(reflected, base_p, Nearest)
      .rounded(prec, rnd)
  }
  if should_use_error_asymptotic(z, base_p) {
    return complex_erfc_asymptotic(z, base_p).rounded(prec, rnd)
  }
  RawMpc::one()
  .sub(complex_error_series(z, base_p), base_p, Nearest)
  .rounded(prec, rnd)
}

///|
/// Evaluate the entire imaginary error function `-i erf(i z)`.
pub fn RawMpc::imaginary_error_function(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag.is_zero() {
    return lift_real(erfi_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 32
  let rotated = RawMpc::new(z.imag.negated(p, Nearest), z.real)
  let value = rotated.error_function(p, Nearest)
  RawMpc::new(value.imag, value.real.negated(p, Nearest)).rounded(prec, rnd)
}

///|
pub fn RawMpc::ei(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(ei_real_checked(z.real, prec, rnd))
  }
  if z == RawMpc::zero() {
    raise PoleError("RawMpc::ei: singularity at zero")
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 32
  if should_use_inverse_factorial_asymptotic(z, base_p) {
    let p = base_p + 48
    let inverse = z.reciprocal(p, Nearest)
    let mut term = RawMpc::one()
    let mut sum = term
    let mut previous = @mpf.RawMpf::infinity()
    let mut converged = false
    let max_terms = 2 * base_p + 128
    for k in 1..<=max_terms {
      term = term.mul(inverse, p, Nearest).mul_int(k, p, Nearest)
      let magnitude = term.abs(p, Nearest)
      if k > 3 && magnitude >= previous {
        break
      }
      sum = sum.add(term, p, Nearest)
      let relative_bound = sum.abs(p, Nearest).scale_pow2(-(base_p + 24))
      if k > 3 && magnitude <= relative_bound {
        converged = true
        break
      }
      previous = magnitude
    }
    if !converged {
      raise ConvergenceError(
        "complex exponential integral asymptotic did not converge",
      )
    }
    let mut value = z
      .exp(p, Nearest)
      .mul(inverse, p, Nearest)
      .mul(sum, p, Nearest)
    let branch = elefun_pi_checked(p, Nearest).mul_int(
      z.imag.signum(),
      p,
      Nearest,
    )
    value = value.add(RawMpc::new(@mpf.RawMpf::zero(), branch), p, Nearest)
    return value.rounded(prec, rnd)
  }
  let p = error_series_work_precision(z, base_p)
  let mut term = z.rounded(p, Nearest)
  let mut sum = term
  let mut converged = false
  let max_terms = 6 * p + 128
  for k in 1..<=max_terms {
    let kp1 = k + 1
    term = term.mul(z, p, Nearest).mul_int(k, p, Nearest)
    term = term.div_real(@mpf.RawMpf::from_int(kp1), p, Nearest)
    term = term.div_real(@mpf.RawMpf::from_int(kp1), p, Nearest)
    sum = sum.add(term, p, Nearest)
    if k > 6 && tiny_enough_mpc(term, p, base_p + 32) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError(
      "complex exponential integral power series did not converge",
    )
  }
  let gamma = RawMpc::new(
    euler_constant_checked(p, Nearest),
    @mpf.RawMpf::zero(),
  )
  sum
  .add(z.ln(p, Nearest), p, Nearest)
  .add(gamma, p, Nearest)
  .rounded(prec, rnd)
}

///|
pub fn RawMpc::e1(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(e1_real_checked(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 12
  let mut v = mpc_ei_checked(z.negated(p, Nearest), p, Nearest).negated(
    p,
    Nearest,
  )
  let pi = elefun_pi_checked(p, Nearest)
  v = if z.imag.sign == 0 {
    RawMpc::new(v.real, v.imag.sub(pi, p, Nearest))
  } else {
    RawMpc::new(v.real, v.imag.add(pi, p, Nearest))
  }
  v.rounded(prec, rnd)
}

///|
/// Evaluate the principal logarithmic integral continuation.
pub fn RawMpc::logarithmic_integral(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  offset? : Bool = false,
) -> RawMpc raise MpcError {
  if offset && z == RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero()) {
    return RawMpc::zero()
  }
  let p = ext_prec(prec) + 64
  let mut value = if z == RawMpc::zero() {
    RawMpc::zero()
  } else if z == RawMpc::one() {
    RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero())
  } else {
    z.log(p, Nearest).ei(p, Nearest)
  }
  if offset {
    let two = RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero())
    let reference = two.log(p, Nearest).ei(p, Nearest)
    value = value.sub(reference, p, Nearest)
  }
  value.rounded(prec, rnd)
}

///|
fn hyperbolic_integral_series(
  z : RawMpc,
  base_p : Int,
  cosine : Bool,
) -> RawMpc raise MpcError {
  let p = error_series_work_precision(z, base_p)
  let z_work = z.rounded(p, Nearest)
  let squared = z_work.square(p, Nearest)
  let mut degree = if cosine { 2 } else { 1 }
  let mut factorial_term = if cosine { squared.scale_pow2(-1) } else { z_work }
  let mut sum = factorial_term.div_real(
    @mpf.RawMpf::from_int(degree),
    p,
    Nearest,
  )
  let mut converged = false
  let max_terms = 4 * p + 128
  for _ in 0..<max_terms {
    let denominator = @mpf.RawMpf::from_int(degree + 1).mul_int(
      degree + 2,
      0,
      Down,
    )
    factorial_term = factorial_term
      .mul(squared, p, Nearest)
      .div_real(denominator, p, Nearest)
    degree += 2
    let correction = factorial_term.div_real(
      @mpf.RawMpf::from_int(degree),
      p,
      Nearest,
    )
    sum = sum.add(correction, p, Nearest)
    if degree > 7 && tiny_enough_mpc(correction, p, base_p + 32) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError(
      "complex hyperbolic integral series did not converge",
    )
  }
  if cosine {
    sum
    .add(z_work.log(p, Nearest), p, Nearest)
    .add_real(euler_constant_checked(p, Nearest), p, Nearest)
  } else {
    sum
  }
}

///|
fn should_use_hyperbolic_integral_series(z : RawMpc, p : Int) -> Bool {
  complex_norm_squared(z, 32) <= @mpf.RawMpf::from_int(p + 64)
}

///|
/// Evaluate the principal hyperbolic cosine integral continuation.
pub fn RawMpc::hyperbolic_cosine_integral(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    return RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero())
  }
  if z.imag.is_zero() && z.real.is_infinite() {
    return RawMpc::new(
      @mpf.RawMpf::infinity(),
      if z.real.sign == 1 {
        elefun_pi_checked(prec, rnd)
      } else {
        @mpf.RawMpf::zero()
      },
    )
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 48
  if should_use_hyperbolic_integral_series(z, base_p) {
    return hyperbolic_integral_series(z, base_p, true).rounded(prec, rnd)
  }
  let p = base_p + 64
  let reflected = z.negated(p, Nearest)
  let mut value = z
    .ei(p, Nearest)
    .add(reflected.ei(p, Nearest), p, Nearest)
    .scale_pow2(-1)
  let pi = elefun_pi_checked(p, Nearest)
  let branch = if z.imag.sign == 1 {
    pi.scale_pow2(-1).negated(p, Nearest)
  } else if !z.imag.is_zero() {
    pi.scale_pow2(-1)
  } else if z.real.sign == 1 {
    pi
  } else {
    @mpf.RawMpf::zero()
  }
  value = value.add(RawMpc::new(@mpf.RawMpf::zero(), branch), p, Nearest)
  value.rounded(prec, rnd)
}

///|
/// Evaluate the entire hyperbolic sine integral.
pub fn RawMpc::hyperbolic_sine_integral(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    return z
  }
  if z.imag.is_zero() && z.real.is_infinite() {
    return z
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 48
  if should_use_hyperbolic_integral_series(z, base_p) {
    return hyperbolic_integral_series(z, base_p, false).rounded(prec, rnd)
  }
  let p = base_p + 64
  let reflected = z.negated(p, Nearest)
  let mut value = z
    .ei(p, Nearest)
    .sub(reflected.ei(p, Nearest), p, Nearest)
    .scale_pow2(-1)
  let pi = elefun_pi_checked(p, Nearest).scale_pow2(-1)
  let branch = if z.imag.sign == 1 {
    pi.negated(p, Nearest)
  } else if !z.imag.is_zero() {
    pi
  } else {
    @mpf.RawMpf::zero()
  }
  value = value.sub(RawMpc::new(@mpf.RawMpf::zero(), branch), p, Nearest)
  value.rounded(prec, rnd)
}

///|
fn fresnel_integral_series(
  z : RawMpc,
  base_p : Int,
) -> (RawMpc, RawMpc) raise MpcError {
  let p = error_series_work_precision(z, base_p)
  let z_work = z.rounded(p, Nearest)
  let squared = z_work.square(p, Nearest)
  let fourth_power = squared.square(p, Nearest)
  let half_pi = elefun_pi_checked(p, Nearest).scale_pow2(-1)
  let ratio = fourth_power.mul_real(
    half_pi.mul(half_pi, p, Nearest).negated(p, Nearest),
    p,
    Nearest,
  )
  let mut cosine_factorial_term = z_work
  let mut sine_factorial_term = z_work
    .mul(squared, p, Nearest)
    .mul_real(half_pi, p, Nearest)
  let mut cosine = cosine_factorial_term
  let mut sine = sine_factorial_term.div_real(
    @mpf.RawMpf::from_int(3),
    p,
    Nearest,
  )
  let mut converged = false
  let max_terms = 4 * p + 128
  for k in 0..<max_terms {
    let cosine_denominator = @mpf.RawMpf::from_int(2 * k + 1).mul_int(
      2 * k + 2,
      0,
      Down,
    )
    cosine_factorial_term = cosine_factorial_term
      .mul(ratio, p, Nearest)
      .div_real(cosine_denominator, p, Nearest)
    let cosine_correction = cosine_factorial_term.div_real(
      @mpf.RawMpf::from_int(4 * k + 5),
      p,
      Nearest,
    )
    cosine = cosine.add(cosine_correction, p, Nearest)
    let sine_denominator = @mpf.RawMpf::from_int(2 * k + 2).mul_int(
      2 * k + 3,
      0,
      Down,
    )
    sine_factorial_term = sine_factorial_term
      .mul(ratio, p, Nearest)
      .div_real(sine_denominator, p, Nearest)
    let sine_correction = sine_factorial_term.div_real(
      @mpf.RawMpf::from_int(4 * k + 7),
      p,
      Nearest,
    )
    sine = sine.add(sine_correction, p, Nearest)
    if k > 2 &&
      tiny_enough_mpc(cosine_correction, p, base_p + 32) &&
      tiny_enough_mpc(sine_correction, p, base_p + 32) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError("complex Fresnel integral series did not converge")
  }
  (cosine, sine)
}

///|
/// Evaluate the complex Fresnel cosine and sine integrals as a pair.
pub fn RawMpc::fresnel_integrals(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> (RawMpc, RawMpc) raise MpcError {
  if z.imag.is_zero() && z.real.is_infinite() {
    let half = if z.real.sign == 1 {
      @mpf.RawMpf::half().negated(0, Down)
    } else {
      @mpf.RawMpf::half()
    }
    let value = RawMpc::new(half, @mpf.RawMpf::zero())
    return (value, value)
  }
  if z == RawMpc::zero() {
    return (z, z)
  }
  if z.is_non_finite() {
    let value = RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    return (value, value)
  }
  let base_p = ext_prec(prec) + 48
  if complex_norm_squared(z, 32) <= @mpf.RawMpf::from_int(base_p + 64) {
    let (cosine, sine) = fresnel_integral_series(z, base_p)
    return (cosine.rounded(prec, rnd), sine.rounded(prec, rnd))
  }
  let p = error_series_work_precision(z, base_p)
  let sqrt_pi = @libelefun.sqrt_pi(p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let half_sqrt_pi = sqrt_pi.scale_pow2(-1)
  let first_argument = z.mul(
    RawMpc::new(half_sqrt_pi, half_sqrt_pi.negated(p, Nearest)),
    p,
    Nearest,
  )
  let second_argument = z.mul(
    RawMpc::new(half_sqrt_pi, half_sqrt_pi),
    p,
    Nearest,
  )
  let half = @mpf.RawMpf::half()
  let first = first_argument
    .error_function(p, Nearest)
    .mul(RawMpc::new(half, half), p, Nearest)
  let second = second_argument
    .error_function(p, Nearest)
    .mul(RawMpc::new(half, half.negated(p, Nearest)), p, Nearest)
  let cosine = first.add(second, p, Nearest).scale_pow2(-1)
  let difference = first.sub(second, p, Nearest)
  let sine = RawMpc::new(
    difference.imag.scale_pow2(-1),
    difference.real.scale_pow2(-1).negated(p, Nearest),
  )
  (cosine.rounded(prec, rnd), sine.rounded(prec, rnd))
}

///|
/// Evaluate the complex Fresnel cosine integral.
pub fn RawMpc::fresnel_cosine_integral(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.fresnel_integrals(prec, rnd).0
}

///|
/// Evaluate the complex Fresnel sine integral.
pub fn RawMpc::fresnel_sine_integral(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  z.fresnel_integrals(prec, rnd).1
}

///|
pub fn RawMpc::ci_si_taylor(
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
  wp : Int,
  which? : Int = 0,
) -> RawMpc raise MpcError {
  let base_p = if wp > 0 { wp } else { 32 }
  let mag = mpc_mag_bound(RawMpc::new(re, im))
  if mag < -base_p {
    return if which == 0 {
      RawMpc::zero()
    } else {
      RawMpc::new(re.rounded(base_p, Nearest), im.rounded(base_p, Nearest))
    }
  }
  let p = error_series_work_precision(RawMpc::new(re, im), base_p)
  let z = RawMpc::new(re.rounded(p, Nearest), im.rounded(p, Nearest))
  let z2 = z.square(p, Nearest).negated(p, Nearest)
  let mut sum = if which == 0 { RawMpc::zero() } else { z }
  let mut term = if which == 0 { RawMpc::one() } else { z }
  let mut k = if which == 0 { 2 } else { 3 }
  let max_terms = 4 * p + 128
  let mut converged = false
  while k < max_terms {
    let den = @mpf.RawMpf::from_int(k * (k - 1))
    term = term.mul(z2, p, Nearest).div_real(den, p, Nearest)
    let add = term.div_real(@mpf.RawMpf::from_int(k), p, Nearest)
    sum = sum.add(add, p, Nearest)
    if tiny_enough_mpc(add, p, base_p + 32) && k > 7 {
      converged = true
      break
    }
    k += 2
  }
  if !converged {
    raise ConvergenceError(
      "complex trigonometric integral Taylor series did not converge",
    )
  }
  sum.rounded(base_p, Nearest)
}

///|
pub fn RawMpc::ci(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    let x = z.real
    if x.sign == 1 && !x.is_zero() {
      let p = ext_prec(prec)
      let re = ci_real_checked(x.abs(p, Nearest), prec, rnd)
      return RawMpc::new(re, elefun_pi_checked(prec, rnd))
    }
    return lift_real(ci_real_checked(x, prec, rnd))
  }
  if z == RawMpc::zero() {
    return RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero())
  }
  let p = ext_prec(prec) + 20
  let mag = mpc_mag_bound(z)
  let gamma = RawMpc::new(
    euler_constant_checked(p, Nearest),
    @mpf.RawMpf::zero(),
  )
  if mag < -p {
    return gamma.add(z.ln(p, Nearest), p, Nearest).rounded(prec, rnd)
  }
  if should_use_inverse_factorial_asymptotic(z, p) {
    let (ci_as, _) = mpc_ci_si_asymptotic(z, p)
    return ci_as.rounded(prec, rnd)
  }
  let sum = RawMpc::ci_si_taylor(z.real, z.imag, p, which=0)
  gamma
  .add(z.ln(p, Nearest), p, Nearest)
  .add(sum, p, Nearest)
  .rounded(prec, rnd)
}

///|
pub fn RawMpc::si(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(si_real_checked(z.real, prec, rnd))
  }
  if z == RawMpc::zero() {
    return RawMpc::zero()
  }
  let p = ext_prec(prec) + 20
  let mag = mpc_mag_bound(z)
  if mag < -p {
    return z.rounded(prec, rnd)
  }
  if should_use_inverse_factorial_asymptotic(z, p) {
    let (_, si_as) = mpc_ci_si_asymptotic(z, p)
    return si_as.rounded(prec, rnd)
  }
  let sum = RawMpc::ci_si_taylor(z.real, z.imag, p, which=1)
  sum.rounded(prec, rnd)
}

///|
fn complex_bessel_j_asymptotic(
  order : Int,
  z : RawMpc,
  base_p : Int,
) -> RawMpc raise MpcError {
  let p = base_p + 64
  let inverse = z.reciprocal(p, Nearest)
  let order_mpf = @mpf.RawMpf::from_int(order)
  let mu = order_mpf.mul(order_mpf, p, Nearest).mul_int(4, p, Nearest)
  let mut term = RawMpc::one()
  let mut cosine_series = term
  let mut sine_series = RawMpc::zero()
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  let max_terms = 2 * base_p + 128
  for k in 1..<=max_terms {
    let odd = 2 * k - 1
    let coefficient = mu.sub(
      @mpf.RawMpf::from_int(odd).mul_int(odd, p, Nearest),
      p,
      Nearest,
    )
    term = term
      .mul_real(coefficient, p, Nearest)
      .mul(inverse, p, Nearest)
      .div_real(@mpf.RawMpf::from_int(8 * k), p, Nearest)
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    if (k & 1) == 0 {
      let signed = if ((k / 2) & 1) == 1 {
        term.negated(p, Nearest)
      } else {
        term
      }
      cosine_series = cosine_series.add(signed, p, Nearest)
    } else {
      let signed = if (((k - 1) / 2) & 1) == 1 {
        term.negated(p, Nearest)
      } else {
        term
      }
      sine_series = sine_series.add(signed, p, Nearest)
    }
    let scale = {
      let a = cosine_series.abs(p, Nearest)
      let b = sine_series.abs(p, Nearest)
      let largest = if a > b { a } else { b }
      if largest < @mpf.RawMpf::one() {
        @mpf.RawMpf::one()
      } else {
        largest
      }
    }
    if k > 4 && magnitude <= scale.scale_pow2(-(base_p + 24)) {
      converged = true
      break
    }
    previous = magnitude
  }
  if !converged {
    raise ConvergenceError("complex Bessel asymptotic series did not converge")
  }
  let pi = elefun_pi_checked(p, Nearest)
  let phase_shift = pi
    .mul_int(order, p, Nearest)
    .scale_pow2(-1)
    .add(pi.scale_pow2(-2), p, Nearest)
  let phase = z.sub_real(phase_shift, p, Nearest)
  let (cosine, sine) = phase.cos_sin(p, Nearest)
  let denominator = z.mul_real(pi, p, Nearest)
  let amplitude = denominator
    .real_divided_by(@mpf.RawMpf::two(), p, Nearest)
    .sqrt(p, Nearest)
  amplitude.mul(
    cosine
    .mul(cosine_series, p, Nearest)
    .sub(sine.mul(sine_series, p, Nearest), p, Nearest),
    p,
    Nearest,
  )
}

///|
/// Evaluate the first-kind Bessel function for an integer order and complex
/// argument.
pub fn RawMpc::bessel_j(
  z : RawMpc,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(besseljn_real_checked(n, z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let mut order = n
  let mut negate = false
  if order < 0 {
    order = -order
    negate = (order & 1) == 1
  }
  if z == RawMpc::zero() {
    return if order == 0 { RawMpc::one() } else { RawMpc::zero() }
  }
  let base_p = ext_prec(prec) + 40 + int_bit_length(order)
  let mut argument = z.rounded(base_p, Nearest)
  if argument.real.sign == 1 {
    argument = argument.negated(base_p, Nearest)
    if (order & 1) == 1 {
      negate = !negate
    }
  }
  let order_mpf = @mpf.RawMpf::from_int(order)
  let threshold = order_mpf
    .mul(order_mpf, 32, Nearest)
    .add(@mpf.RawMpf::from_int(base_p + 64), 32, Nearest)
  let use_asymptotic = complex_norm_squared(argument, 32) >
    threshold.mul(threshold, 32, Nearest)
  let mut value = if use_asymptotic {
    complex_bessel_j_asymptotic(order, argument, base_p)
  } else {
    let p = error_series_work_precision(argument, base_p) + 64
    let half_z = argument.scale_pow2(-1)
    let z2 = half_z.square(p, Nearest)
    let mut term = if order == 0 {
      RawMpc::one()
    } else {
      half_z
      .pow_int(order, p, Nearest)
      .div_real(factorial_mpf_small(order, p), p, Nearest)
    }
    let mut sum = term
    let mut converged = false
    let max_terms = 6 * p + 128
    for k in 0..<max_terms {
      term = term
        .mul(z2, p, Nearest)
        .negated(p, Nearest)
        .div_real(@mpf.RawMpf::from_int(k + 1), p, Nearest)
        .div_real(@mpf.RawMpf::from_int(k + order + 1), p, Nearest)
      sum = sum.add(term, p, Nearest)
      let abs_sum = sum.abs(p, Nearest)
      let scale = if abs_sum < @mpf.RawMpf::one() {
        @mpf.RawMpf::one()
      } else {
        abs_sum
      }
      if k > 4 && term.abs(p, Nearest) <= scale.scale_pow2(-(base_p + 32)) {
        converged = true
        break
      }
    }
    if !converged {
      raise ConvergenceError("complex Bessel power series did not converge")
    }
    sum
  }
  if negate {
    value = value.negated(base_p, Nearest)
  }
  value.rounded(prec, rnd)
}

///|
pub fn RawMpc::ellipk(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    if z.real == @mpf.RawMpf::infinity() {
      return RawMpc::zero()
    }
    if z.real <= @mpf.RawMpf::one() {
      return lift_real(ellipk_real_checked(z.real, prec, rnd))
    }
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 48
  let a = RawMpc::one().sub(z, p, Nearest).sqrt(p, Nearest)
  let v = a.agm_with_one(p, Nearest)
  let r = v.real_divided_by(elefun_pi_checked(p, Nearest), p, Nearest)
  r.scale_pow2(-1).rounded(prec, rnd)
}

///|
pub fn RawMpc::ellipe(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    if z.real == @mpf.RawMpf::infinity() {
      return RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity())
    }
    if z.real <= @mpf.RawMpf::one() {
      return lift_real(ellipe_real_checked(z.real, prec, rnd))
    }
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 64
  let mut a = RawMpc::one()
  let mut b = RawMpc::one().sub(z, p, Nearest).sqrt(p, Nearest)
  let mut correction_sum = z.scale_pow2(-1)
  let mut factor = @mpf.RawMpf::one()
  let mut converged = false
  let max_iterations = p + 64
  for _ in 0..<max_iterations {
    let c = a.sub(b, p, Nearest).scale_pow2(-1)
    let correction = c.square(p, Nearest).mul_real(factor, p, Nearest)
    correction_sum = correction_sum.add(correction, p, Nearest)
    let next_a = a.add(b, p, Nearest).scale_pow2(-1)
    let next_b = a.mul(b, p, Nearest).sqrt(p, Nearest)
    a = next_a
    b = next_b
    factor = factor.mul_int(2, p, Nearest)
    let scale = correction_sum
      .abs(p, Nearest)
      .add(@mpf.RawMpf::one(), p, Nearest)
      .scale_pow2(-(p - 20))
    if correction == RawMpc::zero() || correction.abs(p, Nearest) <= scale {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError(
      "complex complete elliptic second-kind AGM did not converge",
    )
  }
  let first_kind = a
    .real_divided_by(elefun_pi_checked(p, Nearest), p, Nearest)
    .scale_pow2(-1)
  first_kind
  .mul(RawMpc::one().sub(correction_sum, p, Nearest), p, Nearest)
  .rounded(prec, rnd)
}

///|
fn is_barnes_zero(z : RawMpc) -> Bool {
  z.imag.is_zero() &&
  z.real.is_finite() &&
  (z.real.is_zero() || (z.real.sign == 1 && z.real.exp >= 0))
}

///|
fn dilogarithm_power_series(z : RawMpc, p : Int) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    return z
  }
  let mut sum = z
  let mut power = z
  let mut converged = false
  let max_terms = 2 * p + 128
  for k in 2..<=max_terms {
    power = power.mul(z, p, Nearest)
    let denominator = @mpf.RawMpf::from_int(k * k)
    let correction = power.div_real(denominator, p, Nearest)
    sum = sum.add(correction, p, Nearest)
    if tiny_enough_mpc(correction, p, p + 24) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError("complex dilogarithm power series did not converge")
  }
  sum
}

///|
fn dilogarithm_log_series(z : RawMpc, p : Int) -> RawMpc raise MpcError {
  let pi = elefun_pi_checked(p, Nearest)
  let pi_squared_over_six = pi
    .mul(pi, p, Nearest)
    .div(@mpf.RawMpf::from_int(6), p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
  let mu = z.log(p, Nearest)
  if mu == RawMpc::zero() {
    return RawMpc::new(pi_squared_over_six, @mpf.RawMpf::zero())
  }
  let logarithmic_factor = RawMpc::one().sub(
    mu.negated(p, Nearest).log(p, Nearest),
    p,
    Nearest,
  )
  let mu_squared = mu.square(p, Nearest)
  let mut sum = RawMpc::new(pi_squared_over_six, @mpf.RawMpf::zero())
    .add(mu.mul(logarithmic_factor, p, Nearest), p, Nearest)
    .sub(mu_squared.scale_pow2(-2), p, Nearest)
  let mut power = mu.mul(mu_squared, p, Nearest)
  let mut factorial = @mpf.RawMpf::from_int(6)
  let mut converged = false
  let max_terms = p + 128
  for k in 1..<=max_terms {
    let denominator = factorial.mul_int(2 * k, p, Nearest)
    let coefficient = mpf_div_checked(
      bernoulli_checked(2 * k, p, Nearest),
      denominator,
      p,
      Nearest,
    )
    let correction = power.mul_real(coefficient, p, Nearest)
    sum = sum.sub(correction, p, Nearest)
    if k > 2 && tiny_enough_mpc(correction, p, p + 24) {
      converged = true
      break
    }
    power = power.mul(mu_squared, p, Nearest)
    factorial = factorial
      .mul_int(2 * k + 2, p, Nearest)
      .mul_int(2 * k + 3, p, Nearest)
  }
  if !converged {
    raise ConvergenceError(
      "complex dilogarithm logarithmic series did not converge",
    )
  }
  sum
}

///|
fn dilogarithm(z : RawMpc, p : Int) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    return z
  }
  let magnitude = z.abs(p, Nearest)
  let half = @mpf.RawMpf::one().scale_pow2(-1)
  if magnitude <= half {
    return dilogarithm_power_series(z, p)
  }
  if magnitude >= @mpf.RawMpf::two() {
    let reciprocal_value = dilogarithm_power_series(z.reciprocal(p, Nearest), p)
    let logarithm = z.negated(p, Nearest).log(p, Nearest)
    let pi = elefun_pi_checked(p, Nearest)
    let pi_squared_over_six = pi
      .mul(pi, p, Nearest)
      .div(@mpf.RawMpf::from_int(6), p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    return reciprocal_value
      .negated(p, Nearest)
      .sub_real(pi_squared_over_six, p, Nearest)
      .sub(logarithm.square(p, Nearest).scale_pow2(-1), p, Nearest)
  }
  dilogarithm_log_series(z, p)
}

///|
fn barnes_g_reflection(z : RawMpc, p : Int) -> RawMpc raise MpcError {
  let pi = elefun_pi_checked(p, Nearest)
  let two_pi = pi.scale_pow2(1)
  let w = RawMpc::one().sub(z, p, Nearest)
  let phase = RawMpc::new(@mpf.RawMpf::zero(), two_pi).mul(w, p, Nearest)
  let u = phase.exp(p, Nearest)
  let mut exponent = RawMpc::new(
    @mpf.RawMpf::zero(),
    mpf_div_checked(pi, @mpf.RawMpf::from_int(12), p, Nearest),
  )
  exponent = exponent.add(
    w
    .square(p, Nearest)
    .mul_real(pi.scale_pow2(-1), p, Nearest)
    .mul(
      RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::negative_one()),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
  exponent = exponent.add(
    w.mul(RawMpc::one().sub(u, p, Nearest).log(p, Nearest), p, Nearest),
    p,
    Nearest,
  )
  let dilog = dilogarithm(u, p)
  exponent = exponent.add(
    RawMpc::new(dilog.imag, dilog.real.negated(p, Nearest)).div_real(
      two_pi,
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
  let reflected_argument = RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero()).sub(
    z,
    p,
    Nearest,
  )
  let reflected = reflected_argument.barnes_g(p, Nearest)
  let denominator = RawMpc::new(two_pi, @mpf.RawMpf::zero()).pow(w, p, Nearest)
  reflected
  .mul(exponent.exp(p, Nearest), p, Nearest)
  .div(denominator, p, Nearest)
}

///|
/// Evaluate the principal Barnes G-function continuation.
pub fn RawMpc::barnes_g(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if is_barnes_zero(z) {
    return RawMpc::zero()
  }
  if z == RawMpc::one() ||
    z == RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero()) {
    return RawMpc::one()
  }
  if z.imag.is_zero() && z.real == @mpf.RawMpf::infinity() {
    return RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero())
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 80
  let magnitude = z.abs(base_p, Nearest)
  let magnitude_bits = if magnitude > @mpf.RawMpf::one() {
    magnitude.exp + magnitude.bc
  } else {
    0
  }
  let p = base_p + 2 * magnitude_bits + 24
  if z.real < @mpf.RawMpf::from_int(-(p / 3)) {
    return barnes_g_reflection(z, p).rounded(prec, rnd)
  }
  let target = {
    let value = p / 8 + 24
    if value < 48 {
      48
    } else {
      value
    }
  }
  let mut argument = z.rounded(p, Nearest)
  let mut recurrence = RawMpc::one()
  if argument.real < @mpf.RawMpf::from_int(target) {
    let mut gamma_value = argument.gamma(p, Nearest)
    while argument.real < @mpf.RawMpf::from_int(target) {
      recurrence = recurrence.div(gamma_value, p, Nearest)
      gamma_value = gamma_value.mul(argument, p, Nearest)
      argument = argument.add_real(@mpf.RawMpf::one(), p, Nearest)
    }
  }
  let w = argument.sub_real(@mpf.RawMpf::one(), p, Nearest)
  let w_squared = w.square(p, Nearest)
  let one_twelfth = mpf_div_checked(
    @mpf.RawMpf::one(),
    @mpf.RawMpf::from_int(12),
    p,
    Nearest,
  )
  let log_glaisher = mpf_log_checked(
    glaisher_constant_checked(p, Nearest),
    p,
    Nearest,
  )
  let ln_sqrt_2pi = @libelefun.ln_sqrt_2pi(p, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  let mut series = RawMpc::new(
    one_twelfth.sub(log_glaisher, p, Nearest),
    @mpf.RawMpf::zero(),
  )
  series = series.add(w.mul_real(ln_sqrt_2pi, p, Nearest), p, Nearest)
  let logarithmic_coefficient = w_squared
    .scale_pow2(-1)
    .sub_real(one_twelfth, p, Nearest)
  series = series.add(
    logarithmic_coefficient.mul(w.ln(p, Nearest), p, Nearest),
    p,
    Nearest,
  )
  series = series.sub(
    w_squared.mul_real(
      @mpf.RawMpf::from_mantissa_exponent(3N, -2, 0, Down),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
  let inverse_squared = w_squared.reciprocal(p, Nearest)
  let mut inverse_power = inverse_squared
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 32
  for k in 1..<=max_terms {
    let coefficient = mpf_div_checked(
      bernoulli_checked(2 * k + 2, p, Nearest),
      @mpf.RawMpf::from_int(4 * k * (k + 1)),
      p,
      Nearest,
    )
    let correction = inverse_power.mul_real(coefficient, p, Nearest)
    let magnitude = correction.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    series = series.add(correction, p, Nearest)
    if k > 3 && tiny_enough_mpc(correction, p, p + 16) {
      break
    }
    previous = magnitude
    inverse_power = inverse_power.mul(inverse_squared, p, Nearest)
  }
  series.exp(p, Nearest).mul(recurrence, prec, rnd)
}

///|
fn small_hyperfactorial_integer(x : @mpf.RawMpf) -> Int? {
  if !x.is_finite() || (!x.is_zero() && x.exp < 0) {
    return None
  }
  if x.is_zero() {
    return Some(0)
  }
  if x.exp >= 7 {
    return None
  }
  let magnitude = x.man << x.exp
  if magnitude > 64N {
    return None
  }
  let value = magnitude.to_int()
  Some(if x.sign == 1 { -value } else { value })
}

///|
fn exact_hyperfactorial_nonnegative(n : Int) -> @mpf.RawMpf raise MpcError {
  let mut product = @mpf.RawMpf::one()
  for k in 2..<=n {
    product = product.mul(
      mpf_pow_int_checked(@mpf.RawMpf::from_int(k), k, 0, Down),
      0,
      Down,
    )
  }
  product
}

///|
fn negative_integer_hyperfactorial_is_negative(x : @mpf.RawMpf) -> Bool {
  let reflected = x.negated(0, Down).sub(@mpf.RawMpf::one(), 0, Down)
  if reflected.is_zero() || reflected.exp >= 2 {
    false
  } else if reflected.exp == 1 {
    true
  } else {
    (reflected.man & 3N) == 1N
  }
}

///|
/// Evaluate the principal hyperfactorial continuation.
pub fn RawMpc::hyperfactorial(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag.is_zero() {
    match small_hyperfactorial_integer(z.real) {
      Some(n) => {
        if n >= 0 {
          return RawMpc::new(
            exact_hyperfactorial_nonnegative(n),
            @mpf.RawMpf::zero(),
          )
        }
        let value = exact_hyperfactorial_nonnegative(-n - 1)
        return RawMpc::new(
          if ((-n - 1) & 3) == 1 || ((-n - 1) & 3) == 2 {
            value.negated(0, Down)
          } else {
            value
          },
          @mpf.RawMpf::zero(),
        )
      }
      None => ()
    }
    if z.real == @mpf.RawMpf::infinity() {
      return RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero())
    }
    if z.real.is_nan() || z.real == @mpf.RawMpf::negative_infinity() {
      return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    }
    if z.real.sign == 1 && z.real.exp >= 0 {
      let reflected = z.real.negated(0, Down).sub(@mpf.RawMpf::one(), 0, Down)
      let value = RawMpc::new(reflected, @mpf.RawMpf::zero()).hyperfactorial(
        prec, rnd,
      )
      return if negative_integer_hyperfactorial_is_negative(z.real) {
        value.negated(prec, rnd)
      } else {
        value
      }
    }
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 80
  let magnitude = z.abs(base_p, Nearest)
  let magnitude_bits = if magnitude > @mpf.RawMpf::one() {
    magnitude.exp + magnitude.bc
  } else {
    0
  }
  let p = base_p + 2 * magnitude_bits + 24
  let shifted = z.add_real(@mpf.RawMpf::one(), p, Nearest)
  let numerator = z
    .mul(shifted.loggamma(p, Nearest), p, Nearest)
    .exp(p, Nearest)
  numerator.div(shifted.barnes_g(p, Nearest), p, Nearest).rounded(prec, rnd)
}

///|
pub fn RawMpc::gamma(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(gamma_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 40
  complex_loggamma_general(z, p).exp(prec, rnd)
}

///|
pub fn RawMpc::rgamma(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(rgamma_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 40
  complex_loggamma_general(z, p).negated(p, Nearest).exp(prec, rnd)
}

///|
pub fn RawMpc::loggamma(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    if z.real.sign == 0 {
      return lift_real(loggamma_real_checked(z.real, prec, rnd))
    }
    if !z.real.is_finite() {
      return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
    }
    let p = ext_prec(prec) + 32
    let gamma_value = gamma_real_checked(z.real, p, Nearest)
    let real = mpf_log_checked(gamma_value.abs(p, Nearest), p, Nearest)
    let imag = elefun_pi_checked(p, Nearest).mul(
      z.real.floor(0, Down),
      p,
      Nearest,
    )
    return RawMpc::new(real, imag).rounded(prec, rnd)
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  complex_loggamma_general(z, ext_prec(prec) + 40).rounded(prec, rnd)
}

///|
pub fn RawMpc::factorial(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 16
  z.add_real(@mpf.RawMpf::one(), p, Nearest).gamma(prec, rnd)
}

///|
pub fn RawMpc::harmonic(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(harmonic_real_checked(z.real, prec, rnd))
  }
  let p = ext_prec(prec) + 20
  let psi = z.add_real(@mpf.RawMpf::one(), p, Nearest).digamma(p, Nearest)
  psi
  .add_real(euler_constant_checked(p, Nearest), p, Nearest)
  .rounded(prec, rnd)
}

///|
pub fn RawMpc::digamma(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(psi0_real_checked(z.real, prec, rnd))
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let p = ext_prec(prec) + 44
  let half = @mpf.RawMpf::half()
  if z.real < half {
    let reflected = RawMpc::one().sub(z, p, Nearest).digamma(p, Nearest)
    let (cosine, sine) = z.cos_sin_pi(p, Nearest)
    let correction = cosine
      .div(sine, p, Nearest)
      .mul_real(elefun_pi_checked(p, Nearest), p, Nearest)
    return reflected.sub(correction, p, Nearest).rounded(prec, rnd)
  }
  let target = {
    let value = p / 3 + 12
    if value < 32 {
      32
    } else {
      value
    }
  }
  let mut w = z.rounded(p, Nearest)
  let mut recurrence = RawMpc::zero()
  while w.real < @mpf.RawMpf::from_int(target) {
    recurrence = recurrence.sub(w.reciprocal(p, Nearest), p, Nearest)
    w = w.add_real(@mpf.RawMpf::one(), p, Nearest)
  }
  let inv = w.reciprocal(p, Nearest)
  let inv2 = inv.square(p, Nearest)
  let mut power = inv2
  let mut value = w.ln(p, Nearest).sub(inv.scale_pow2(-1), p, Nearest)
  let mut previous = @mpf.RawMpf::infinity()
  let max_terms = p / 2 + 16
  for k in 1..<=max_terms {
    let coefficient = mpf_div_checked(
      bernoulli_checked(2 * k, p, Nearest),
      @mpf.RawMpf::from_int(2 * k),
      p,
      Nearest,
    )
    let term = power.mul_real(coefficient, p, Nearest)
    let magnitude = term.abs(p, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    value = value.sub(term, p, Nearest)
    if k > 3 && tiny_enough_mpc(term, p, p + 12) {
      break
    }
    previous = magnitude
    power = power.mul(inv2, p, Nearest)
  }
  value.add(recurrence, p, Nearest).rounded(prec, rnd)
}

///|
fn complex_cot_derivative_coefficients(order : Int) -> Array[BigInt] {
  let mut coefficients = [0N, 1N]
  for _ in 0..<order {
    let next = Array::make(coefficients.length() + 1, 0N)
    for degree in 1..<coefficients.length() {
      let derivative = coefficients[degree] * BigInt::from_int(degree)
      next[degree - 1] = next[degree - 1] - derivative
      next[degree + 1] = next[degree + 1] - derivative
    }
    coefficients = next
  }
  coefficients
}

///|
fn evaluate_complex_cot_derivative_polynomial(
  order : Int,
  cotangent : RawMpc,
  p : Int,
) -> RawMpc {
  let coefficients = complex_cot_derivative_coefficients(order)
  let mut value = RawMpc::zero()
  let mut index = coefficients.length() - 1
  while index >= 0 {
    value = value
      .mul(cotangent, p, Nearest)
      .add_real(@mpf.RawMpf::from_bigint(coefficients[index]), p, Nearest)
    index -= 1
  }
  value
}

///|
fn complex_top_bit(z : RawMpc, p : Int) -> Int raise MpcError {
  let magnitude = z.abs(p, Nearest)
  if magnitude.is_zero() {
    -1073741824
  } else {
    magnitude.exp + magnitude.bc
  }
}

///|
fn complex_relative_tiny(
  term : RawMpc,
  value : RawMpc,
  p : Int,
  bits : Int,
) -> Bool raise MpcError {
  let term_magnitude = term.abs(p, Nearest)
  if term_magnitude.is_zero() {
    return true
  }
  let value_magnitude = value.abs(p, Nearest)
  if !term_magnitude.is_finite() ||
    value_magnitude.is_zero() ||
    !value_magnitude.is_finite() {
    return false
  }
  term_magnitude.exp + term_magnitude.bc <=
  value_magnitude.exp + value_magnitude.bc - bits
}

///|
fn reflected_complex_polygamma(
  z : RawMpc,
  m : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  let target = ext_prec(prec) + 8
  let polynomial_guard = 64 + (m + 2) * int_bit_length(m + 2)
  let mut p = target + polynomial_guard
  let attempts = int_bit_length(target + polynomial_guard) + 4
  for _ in 0..<attempts {
    let reflected = RawMpc::one().sub(z, p, Nearest).polygamma(m, p, Nearest)
    let signed_reflected = if (m & 1) == 1 {
      reflected.negated(p, Nearest)
    } else {
      reflected
    }
    let (cosine, sine) = z.cos_sin_pi(p, Nearest)
    let cotangent = cosine.div(sine, p, Nearest)
    let derivative = evaluate_complex_cot_derivative_polynomial(m, cotangent, p)
    let pi_power = mpf_pow_int_checked(
      elefun_pi_checked(p, Nearest),
      m + 1,
      p,
      Nearest,
    )
    let correction = derivative.mul_real(pi_power, p, Nearest)
    let value = signed_reflected.sub(correction, p, Nearest)
    let largest = complex_top_bit(signed_reflected, 24).max(
      complex_top_bit(correction, 24),
    )
    let value_is_zero = value.real.is_zero() && value.imag.is_zero()
    let needed = if value_is_zero {
      target + polynomial_guard + largest.max(0)
    } else {
      target + polynomial_guard + (largest - complex_top_bit(value, 24)).max(0)
    }
    if p >= needed {
      return value.rounded(prec, rnd)
    }
    p = needed + 16
  }
  raise ConvergenceError("complex polygamma reflection lost too much precision")
}

///|
pub fn RawMpc::polygamma(
  z : RawMpc,
  m : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if m < 0 {
    raise ValueError("RawMpc::polygamma: m must be non-negative")
  }
  if z.imag == @mpf.RawMpf::zero() {
    return lift_real(psi_real_checked(m, z.real, prec, rnd))
  }
  if m == 0 {
    return z.digamma(prec, rnd)
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if z.real.sign == 1 {
    return reflected_complex_polygamma(z, m, prec, rnd)
  }
  let target_bits = ext_prec(prec) + 8
  let p = target_bits + 64 + 2 * int_bit_length(m + 2)
  let mut w = z.rounded(p, Nearest)
  let target = 2 * p / 5 + 4 * m + 2
  let mut s = RawMpc::zero()
  while w.real < @mpf.RawMpf::from_int(target) {
    let t = w.pow_int(m + 1, p, Nearest).reciprocal(p, Nearest)
    s = s.add(t, p, Nearest)
    w = w.add_real(@mpf.RawMpf::one(), p, Nearest)
  }
  let mut zm = w.pow_int(m, p, Nearest).reciprocal(p, Nearest)
  let z2 = w.square(p, Nearest).reciprocal(p, Nearest)
  s = s.add(zm.div_real(@mpf.RawMpf::from_int(m), p, Nearest), p, Nearest)
  let endpoint = zm
    .div(w, p, Nearest)
    .mul_real(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), p, Nearest)
  s = s.add(endpoint, p, Nearest)
  let mut ratio = mpf_div_checked(
    @mpf.RawMpf::from_int(m + 1),
    @mpf.RawMpf::from_int(2),
    p,
    Nearest,
  )
  let max_terms = p / 2 + m + 32
  let mut previous = @mpf.RawMpf::infinity()
  let mut converged = false
  for k in 1..<=max_terms {
    zm = zm.mul(z2, p, Nearest)
    let bern = bernoulli_checked(2 * k, p, Nearest)
    let scal = bern.mul(ratio, p, Nearest)
    let term = zm.mul_real(scal, p, Nearest)
    let magnitude = term.abs(24, Nearest)
    if k > 4 && magnitude >= previous {
      break
    }
    s = s.add(term, p, Nearest)
    if k > 2 && complex_relative_tiny(term, s, 24, target_bits) {
      converged = true
      break
    }
    previous = magnitude
    ratio = ratio.mul_int(m + 2 * k, p, Nearest)
    ratio = ratio.mul_int(m + 2 * k + 1, p, Nearest)
    ratio = mpf_div_checked(ratio, @mpf.RawMpf::from_int(2 * k + 1), p, Nearest)
    ratio = mpf_div_checked(ratio, @mpf.RawMpf::from_int(2 * k + 2), p, Nearest)
  }
  if !converged {
    raise ConvergenceError(
      "complex polygamma Euler-Maclaurin expansion did not converge",
    )
  }
  let mut v = s.mul_real(factorial_mpf_small(m, p), p, Nearest)
  if (m & 1) == 0 {
    v = v.negated(p, Nearest)
  }
  v.rounded(prec, rnd)
}

///|
pub fn RawMpc::zeta_sum(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  start? : Int = 1,
  terms? : Int = 1000,
) -> RawMpc raise MpcError {
  let p = ext_prec(prec) + 12
  zeta_series_sum(s, p, start, terms, false).rounded(prec, rnd)
}

///|
pub fn RawMpc::eta(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if s.imag == @mpf.RawMpf::zero() {
    return lift_real(altzeta_real_checked(s.real, prec, rnd))
  }
  if s.real.is_nan() || s.imag.is_nan() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if s.real.is_infinite() && s.real.sign == 0 && s.imag.is_finite() {
    return RawMpc::one()
  }
  if s.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 32
  let delta = s.sub(RawMpc::one(), base_p, Nearest)
  let pole_distance = delta.abs(24, Nearest)
  let cancellation_bits = if pole_distance.is_zero() {
    base_p
  } else {
    let bits = -(pole_distance.exp + pole_distance.bc)
    if bits > 0 {
      bits
    } else {
      0
    }
  }
  if cancellation_bits > (base_p + 32) / 2 {
    let p = base_p + 48
    let logarithm_two = ln2_constant_checked(p, Nearest)
    let coefficient = euler_constant_checked(p, Nearest)
      .mul(logarithm_two, p, Nearest)
      .sub(
        logarithm_two.mul(logarithm_two, p, Nearest).scale_pow2(-1),
        p,
        Nearest,
      )
    return delta
      .mul_real(coefficient, p, Nearest)
      .add_real(logarithm_two, p, Nearest)
      .rounded(prec, rnd)
  }
  if s.real.sign == 1 {
    let p = base_p + cancellation_bits + 32
    let zeta_value = s.zeta(p, Nearest)
    let factor = zeta_alt_factor_complex(s, p)
    return zeta_value.mul(factor, p, Nearest).rounded(prec, rnd)
  }
  zeta_borwein_eta_complex(s, base_p + 16).rounded(prec, rnd)
}

///|
pub fn RawMpc::zeta(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  alt? : Bool = false,
) -> RawMpc raise MpcError {
  if s.imag == @mpf.RawMpf::zero() {
    return lift_real(zeta_real_checked(s.real, prec, rnd, alt~))
  }
  if s.real.is_nan() || s.imag.is_nan() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if s.real.is_infinite() && s.real.sign == 0 && s.imag.is_finite() {
    return RawMpc::one()
  }
  if s.real.is_infinite() && s.real.sign == 1 {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if s.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if alt {
    return s.eta(prec, rnd)
  }
  let base_p = ext_prec(prec) + 24
  let delta = s.sub(RawMpc::one(), base_p, Nearest)
  let distance = delta.abs(24, Nearest)
  let cancellation_bits = if distance.is_zero() {
    base_p
  } else {
    (-(distance.exp + distance.bc)).max(0)
  }
  if cancellation_bits > (base_p + 32) / 2 {
    let p = base_p + 48
    return delta
      .reciprocal(p, Nearest)
      .add_real(euler_constant_checked(p, Nearest), p, Nearest)
      .rounded(prec, rnd)
  }
  let p = base_p + 16
  let z = if s.real.sign == 1 {
    zeta_reflection_complex(s, p)
  } else {
    zeta_right_half_plane_complex(s, p)
  }
  z.rounded(prec, rnd)
}

///|
fn prime_zeta_term_count(s : RawMpc, p : Int) -> Int raise MpcError {
  let threshold = @mpf.RawMpf::from_int(p + 64)
  let quotient = mpf_div_checked(threshold, s.real, p, Ceiling)
  let count = quotient.to_integer(rnd=Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  if count.bit_length() > 60 {
    raise ConvergenceError(
      "prime zeta requires too many Mobius-inversion terms",
    )
  }
  count.to_int().max(1) + 2
}

///|
fn prime_zeta_logarithm(argument : RawMpc, p : Int) -> RawMpc raise MpcError {
  if argument.real <= @mpf.RawMpf::from_int((p / 10).max(8)) {
    return argument.zeta(p, Nearest).ln(p, Nearest)
  }
  let minus_argument = argument.negated(p, Nearest)
  let mut tail = RawMpc::zero()
  let mut n = 2
  while true {
    let base = RawMpc::new(@mpf.RawMpf::from_int(n), @mpf.RawMpf::zero())
    let term = mpc_pow_checked(base, minus_argument, p, Nearest)
    tail = tail.add(term, p, Nearest)
    if tiny_enough_mpc(term, p, p + 16) {
      break
    }
    n += 1
  }
  RawMpc::one().add(tail, p, Nearest).ln(p, Nearest)
}

///|
/// Evaluate the prime zeta function by Mobius inversion of `log(zeta(s))`.
///
/// The principal logarithm supplies the standard analytic continuation for
/// `Re(s) > 0`. Logarithmic singularities at reciprocal square-free integers
/// are represented by signed infinity while retaining the accumulated branch
/// imaginary part.
pub fn RawMpc::prime_zeta(
  s : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> RawMpc raise MpcError {
  if s.real.is_nan() || s.imag.is_nan() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  if s.real <= @mpf.RawMpf::zero() {
    raise DomainError("prime zeta is defined only for Re(s) > 0")
  }
  if s.imag.is_zero() && s.real == @mpf.RawMpf::one() {
    return RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero())
  }
  if s.imag.is_zero() && s.real == @mpf.RawMpf::half() {
    return RawMpc::new(
      @mpf.RawMpf::negative_infinity(),
      elefun_pi_checked(prec, rnd),
    )
  }
  if s.real == @mpf.RawMpf::infinity() && s.imag.is_finite() {
    return RawMpc::zero()
  }
  if s.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let base_p = ext_prec(prec) + 48
  if s.real > @mpf.RawMpf::from_int(base_p + 64) {
    let two = RawMpc::new(@mpf.RawMpf::two(), @mpf.RawMpf::zero())
    return mpc_pow_checked(two, s.negated(base_p, Nearest), prec, rnd)
  }
  let max_terms = prime_zeta_term_count(s, base_p)
  let p = base_p + 64 + 4 * int_bit_length(max_terms + 1)
  let mut sum = RawMpc::zero()
  let mut singularity_sign = 0
  for k in 1..<=max_terms {
    let mobius = @intmath.moebius(BigInt::from_int(k))
    if mobius == 0 {
      continue
    }
    let argument = s.mul_int(k, p, Nearest)
    if argument.imag.is_zero() && argument.real == @mpf.RawMpf::one() {
      singularity_sign = mobius
      continue
    }
    let logarithm = prime_zeta_logarithm(argument, p)
    let term = logarithm
      .mul_int(mobius, p, Nearest)
      .div_real(@mpf.RawMpf::from_int(k), p, Nearest)
    sum = sum.add(term, p, Nearest)
    if k > 8 &&
      (
        (term.real.is_zero() && term.imag.is_zero()) ||
        complex_relative_tiny(term, sum, 24, base_p)
      ) {
      break
    }
  }
  if singularity_sign != 0 {
    let real = if singularity_sign < 0 {
      @mpf.RawMpf::negative_infinity()
    } else {
      @mpf.RawMpf::infinity()
    }
    return RawMpc::new(real, sum.imag.rounded(prec, rnd))
  }
  sum.rounded(prec, rnd)
}
