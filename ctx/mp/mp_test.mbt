///|
test "ctx mpf basic wrappers" {
  let ctx = new(160, @mpf.round_nearest)
  let a = ctx.make_float("1.5")
  let b = ctx.make_int(2)
  assert_true(ctx.to_string(ctx.add(a, b), dps=8).has_prefix("3.5"))
  assert_true(ctx.to_string(ctx.sub(a, b), dps=8).has_prefix("-0.5"))
  assert_true(ctx.to_string(ctx.mul(a, b), dps=8).has_prefix("3"))
  assert_true(
    ctx
    .to_string(ctx.div(@mpf.fone, @mpf.from_int(3)), dps=12)
    .has_prefix("0.333333333333"),
  )
  assert_true(
    ctx.to_string(ctx.sqrt(ctx.make_int(2)), dps=12).has_prefix("1.41421356237"),
  )
}

///|
test "ctx high-level transcendentals subset" {
  let ctx = new(180, @mpf.round_nearest)
  assert_true(
    ctx.to_string(ctx.exp(ctx.make_int(1)), dps=10).has_prefix("2.718281828"),
  )
  assert_true(
    ctx.to_string(ctx.ln(ctx.make_int(2)), dps=10).has_prefix("0.693147180"),
  )
  assert_true(
    ctx
    .to_string(ctx.gamma(@mpf.from_man_exp(1N, -1, 0, @mpf.round_down)), dps=10)
    .has_prefix("1.772453"),
  )
  assert_true(
    ctx.to_string(ctx.zeta(ctx.make_int(2)), dps=9).has_prefix("1.6449340"),
  )
}

///|
test "ctx e1 real/complex semantics" {
  let ctx = new(180, @mpf.round_nearest)
  let pos = ctx.e1(ctx.make_float("2"))
  assert_true(@mpf.to_str_opts(pos.real, dps=10).has_prefix("0.048900510"))
  assert_eq(pos.imag, @mpf.fzero)
  let neg = ctx.e1(ctx.make_float("-2"))
  assert_true(@mpf.to_str_opts(neg.real, dps=8).has_prefix("-4.95423"))
  assert_true(@mpf.to_str_opts(neg.imag, dps=9).has_prefix("-3.14159265"))
  let real_e1_neg : Result[@mpf.RawMpf, MPError] = try? ctx.e1_real(
    ctx.make_float("-2"),
  )
  match real_e1_neg {
    Ok(_) => fail("expected complex-result error for negative input")
    Err(MPError::ComplexResult(msg)) => assert_true(msg.contains("e1_real"))
    Err(_) => fail("unexpected error kind")
  }
}

///|
test "ctx expint negative real principal-branch subset" {
  let ctx = new(220, @mpf.round_nearest)
  let pi = @libelefun.mpf_pi(220, @mpf.round_nearest)
  let e2 = ctx.expint(2, ctx.make_float("-2"))
  assert_true(@mpf.to_str_opts(e2.real, dps=9).has_prefix("-2.51941261"))
  let e2_im_ratio = @mpf.mpf_div(e2.imag, pi, 220, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e2_im_ratio, dps=8).has_prefix("-2"))
  let e3 = ctx.expint(3, ctx.make_float("-2"))
  assert_true(@mpf.to_str_opts(e3.real, dps=7).has_prefix("1.17511"))
  let e3_im_ratio = @mpf.mpf_div(e3.imag, pi, 220, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e3_im_ratio, dps=8).has_prefix("-2"))
  let ge2 = ctx.expint(2, ctx.make_float("-2"), gamma=true)
  let ge2_target = @mpf.mpf_neg(
    ctx.exp(ctx.make_int(2)),
    220,
    @mpf.round_nearest,
  )
  let ge2_err = @mpf.mpf_abs(
    @mpf.mpf_sub(ge2.real, ge2_target, 220, @mpf.round_nearest),
    220,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(ge2_err, @mpf.from_str("1e-10")))
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(ge2.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-20"),
    ),
  )
  let ge3 = ctx.expint(3, ctx.make_float("-2"), gamma=true)
  let ge3_target = @mpf.mpf_mul_int(
    ctx.exp(ctx.make_int(2)),
    2,
    220,
    @mpf.round_nearest,
  )
  let ge3_err = @mpf.mpf_abs(
    @mpf.mpf_sub(ge3.real, ge3_target, 220, @mpf.round_nearest),
    220,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(ge3_err, @mpf.from_str("1e-10")))
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(ge3.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-20"),
    ),
  )
}

///|
test "ctx complex api and structured errors" {
  let ctx = new(180, @mpf.round_nearest)
  let zero = @mpc.zero()
  let zero_log : Result[@mpc.RawMpc, MPError] = try? ctx.complex_log(zero)
  match zero_log {
    Ok(_) => fail("expected complex_log pole error")
    Err(MPError::PoleError(msg)) => assert_true(msg.contains("complex_log"))
    Err(_) => fail("unexpected error kind")
  }
  let zero_pow_neg : Result[@mpc.RawMpc, MPError] = try? ctx.complex_pow(
    zero,
    @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero),
  )
  match zero_pow_neg {
    Ok(_) => fail("expected complex_pow domain error")
    Err(MPError::DomainError(msg)) => assert_true(msg.contains("complex_pow"))
    Err(_) => fail("unexpected error kind")
  }
  let minus_one = @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero)
  let sqrt_minus_one = ctx.complex_sqrt(minus_one)
  assert_true(@mpf.to_str_opts(sqrt_minus_one.real, dps=6).has_prefix("0"))
  assert_true(@mpf.to_str_opts(sqrt_minus_one.imag, dps=10).has_prefix("1"))
  let gamma_pole : Result[@mpc.RawMpc, MPError] = try? ctx.complex_gamma(
    @mpc.from_parts(@mpf.from_int(0), @mpf.fzero),
  )
  match gamma_pole {
    Ok(_) => fail("expected complex_gamma pole error")
    Err(MPError::PoleError(msg)) => assert_true(msg.contains("complex_gamma"))
    Err(_) => fail("unexpected error kind")
  }
  let zeta_pole : Result[@mpc.RawMpc, MPError] = try? ctx.complex_zeta(
    @mpc.from_parts(@mpf.fone, @mpf.fzero),
  )
  match zeta_pole {
    Ok(_) => fail("expected complex_zeta pole error")
    Err(MPError::PoleError(msg)) => assert_true(msg.contains("complex_zeta"))
    Err(_) => fail("unexpected error kind")
  }
  let zeta_alt_one = ctx.complex_zeta(
    @mpc.from_parts(@mpf.fone, @mpf.fzero),
    alt=true,
  )
  assert_true(
    @mpf.to_str_opts(zeta_alt_one.real, dps=10).has_prefix("0.693147180"),
  )
  assert_eq(zeta_alt_one.imag, @mpf.fzero)
}
