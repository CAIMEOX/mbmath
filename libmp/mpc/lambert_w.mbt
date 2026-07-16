///|
fn lambert_branch_shift(branch : Int, p : Int) -> @mpf.RawMpf raise MpcError {
  elefun_pi_checked(p, Nearest).mul_int(branch, p, Nearest).scale_pow2(1)
}

///|
fn lambert_branch_series(
  delta : RawMpc,
  reflected : Bool,
  p : Int,
) -> RawMpc raise MpcError {
  let mut root = delta.scale_pow2(1).sqrt(p, Nearest)
  if reflected {
    root = root.negated(p, Nearest)
  }
  let root2 = root.square(p, Nearest)
  let root3 = root2.mul(root, p, Nearest)
  let root4 = root3.mul(root, p, Nearest)
  let root5 = root4.mul(root, p, Nearest)
  let root6 = root5.mul(root, p, Nearest)
  let mut value = RawMpc::new(@mpf.RawMpf::negative_one(), @mpf.RawMpf::zero()).add(
    root,
    p,
    Nearest,
  )
  value = value.sub(
    root2.div_real(@mpf.RawMpf::from_int(3), p, Nearest),
    p,
    Nearest,
  )
  value = value.add(
    root3
    .mul_int(11, p, Nearest)
    .div_real(@mpf.RawMpf::from_int(72), p, Nearest),
    p,
    Nearest,
  )
  value = value.sub(
    root4
    .mul_int(43, p, Nearest)
    .div_real(@mpf.RawMpf::from_int(540), p, Nearest),
    p,
    Nearest,
  )
  value = value.add(
    root5
    .mul_int(769, p, Nearest)
    .div_real(@mpf.RawMpf::from_int(17280), p, Nearest),
    p,
    Nearest,
  )
  value.sub(
    root6
    .mul_int(221, p, Nearest)
    .div_real(@mpf.RawMpf::from_int(8505), p, Nearest),
    p,
    Nearest,
  )
}

///|
fn lambert_asymptotic_initial(
  z : RawMpc,
  branch : Int,
  p : Int,
) -> RawMpc raise MpcError {
  let mut first_logarithm = z.log(p, Nearest)
  first_logarithm = RawMpc::new(
    first_logarithm.real,
    first_logarithm.imag.add(lambert_branch_shift(branch, p), p, Nearest),
  )
  let second_logarithm = first_logarithm.log(p, Nearest)
  let inverse_first = first_logarithm.reciprocal(p, Nearest)
  let first_correction = second_logarithm.mul(inverse_first, p, Nearest)
  let second_correction = second_logarithm
    .mul(second_logarithm.sub_real(@mpf.RawMpf::two(), p, Nearest), p, Nearest)
    .mul(inverse_first.square(p, Nearest), p, Nearest)
    .scale_pow2(-1)
  first_logarithm
  .sub(second_logarithm, p, Nearest)
  .add(first_correction, p, Nearest)
  .add(second_correction, p, Nearest)
}

///|
fn lambert_initial(
  z : RawMpc,
  branch : Int,
  p : Int,
  delta : RawMpc,
  near_branch_point : Bool,
) -> RawMpc raise MpcError {
  let branch_series = branch == 0 ||
    (branch == -1 && z.imag.sign == 0) ||
    (branch == 1 && z.imag.sign == 1)
  if near_branch_point && branch_series {
    return lambert_branch_series(delta, branch != 0, p)
  }
  let magnitude = z.abs(32, Nearest)
  if branch == 0 && magnitude < @mpf.RawMpf::half() {
    return z.mul(RawMpc::one().sub(z, p, Nearest), p, Nearest)
  }
  if branch == 0 && z.imag.is_zero() && z.real.sign == 0 {
    return z.add_real(@mpf.RawMpf::one(), p, Nearest).log(p, Nearest)
  }
  if branch == -1 &&
    z.imag.is_zero() &&
    z.real.sign == 1 &&
    delta.real.sign == 0 {
    let first = mpf_log_checked(z.real.negated(p, Nearest), p, Nearest)
    let second = mpf_log_checked(first.negated(p, Nearest), p, Nearest)
    return RawMpc::new(first.sub(second, p, Nearest), @mpf.RawMpf::zero())
  }
  lambert_asymptotic_initial(z, branch, p)
}

///|
fn lambert_working_precision(
  z : RawMpc,
  branch : Int,
  prec : Int,
) -> (Int, RawMpc, Bool) raise MpcError {
  let target = if prec > 0 { prec } else { 64 }
  let branch_value = @mpf.RawMpf::from_int(branch)
  let branch_bits = if branch == 0 {
    0
  } else {
    branch_value.exp + branch_value.bc
  }
  let base_p = target + 112 + 2 * branch_bits
  let approximate_e = elefun_exp_checked(@mpf.RawMpf::one(), base_p, Nearest)
  let approximate_delta = z
    .mul_real(approximate_e, base_p, Nearest)
    .add_real(@mpf.RawMpf::one(), base_p, Nearest)
  let near_branch_point = approximate_delta.abs(32, Nearest) <
    @mpf.RawMpf::half()
  let input_bits = {
    let real_bits = if z.real.bc > 0 { z.real.bc } else { 0 }
    let imaginary_bits = if z.imag.bc > 0 { z.imag.bc } else { 0 }
    if real_bits > imaginary_bits {
      real_bits
    } else {
      imaginary_bits
    }
  }
  let p = if near_branch_point && input_bits + 96 > base_p {
    input_bits + 96
  } else {
    base_p
  }
  let e = elefun_exp_checked(@mpf.RawMpf::one(), p, Nearest)
  let delta = z.mul_real(e, p, Nearest).add_real(@mpf.RawMpf::one(), p, Nearest)
  (p, delta, near_branch_point)
}

///|
/// Evaluate the Lambert W function on an arbitrary integer branch.
pub fn RawMpc::lambert_w(
  z : RawMpc,
  prec : Int,
  rnd : @mpf.RoundMode,
  branch? : Int = 0,
) -> RawMpc raise MpcError {
  if z == RawMpc::zero() {
    return if branch == 0 {
      z
    } else {
      RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero())
    }
  }
  if z.imag.is_zero() && z.real == @mpf.RawMpf::infinity() {
    return RawMpc::new(
      @mpf.RawMpf::infinity(),
      if branch == 0 {
        @mpf.RawMpf::zero()
      } else {
        lambert_branch_shift(branch, prec)
      },
    )
  }
  if z.imag.is_zero() && z.real == @mpf.RawMpf::negative_infinity() {
    let pi = elefun_pi_checked(prec, Nearest)
    let branch_argument = pi
      .mul_int(branch, prec, Nearest)
      .scale_pow2(1)
      .add(pi, prec, Nearest)
    return RawMpc::new(
      @mpf.RawMpf::infinity(),
      branch_argument.rounded(prec, rnd),
    )
  }
  if z.is_non_finite() {
    return RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::nan())
  }
  let (p, delta, near_branch_point) = lambert_working_precision(z, branch, prec)
  let target = if prec > 0 { prec } else { 64 }
  let mut value = lambert_initial(z, branch, p, delta, near_branch_point)
  let mut level_count = 0
  let mut remaining = p
  while remaining > 1 {
    level_count += 1
    remaining = remaining >> 1
  }
  let max_steps = 2 * level_count + 24
  let mut converged = false
  for _ in 0..<max_steps {
    let exponential = value.exp(p, Nearest)
    let product = value.mul(exponential, p, Nearest)
    let residual = product.sub(z, p, Nearest)
    if residual == RawMpc::zero() {
      converged = true
      break
    }
    let twice_successor = value
      .add_real(@mpf.RawMpf::one(), p, Nearest)
      .scale_pow2(1)
    let halley_correction = value
      .add_real(@mpf.RawMpf::two(), p, Nearest)
      .mul(residual, p, Nearest)
      .div(twice_successor, p, Nearest)
    let denominator = product
      .add(exponential, p, Nearest)
      .sub(halley_correction, p, Nearest)
    let step = residual.div(denominator, p, Nearest)
    let next = value.sub(step, p, Nearest)
    let scale = {
      let magnitude = next.abs(p, Nearest)
      if magnitude < @mpf.RawMpf::one() {
        @mpf.RawMpf::one()
      } else {
        magnitude
      }
    }
    value = next
    if step.abs(p, Nearest) <= scale.scale_pow2(-(target + 40)) {
      converged = true
      break
    }
  }
  if !converged {
    raise ConvergenceError("Lambert W iteration did not converge")
  }
  value.rounded(prec, rnd)
}
