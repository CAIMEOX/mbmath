///|
fn assert_text_close_to_str_mp(
  actual_text : String,
  expected_text : String,
  tol : String,
) -> Unit raise {
  let actual = @mpf.RawMpf::parse(actual_text, prec=460, rnd=Nearest)
  let expected = @mpf.RawMpf::parse(expected_text, prec=460, rnd=Nearest)
  let err = actual.sub(expected, 420, Nearest).abs(420, Nearest)
  let tol_v = @mpf.RawMpf::parse(tol, prec=420, rnd=Nearest)
  assert_true(err < tol_v)
}

///|
test "ctx mpf basic wrappers" {
  let ctx = MPContext::new(160, Nearest)
  let a = ctx.parse("1.5")
  let b = ctx.from_int(2)
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.add(a, b), dps=8),
    "3.5",
    "1e-8",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.sub(a, b), dps=8),
    "-0.5",
    "1e-8",
  )
  assert_text_close_to_str_mp(ctx.to_string(ctx.mul(a, b), dps=8), "3", "1e-8")
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.div(@mpf.RawMpf::one(), @mpf.RawMpf::from_int(3)), dps=12),
    "0.333333333333",
    "1e-12",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.sqrt(ctx.from_int(2)), dps=12),
    "1.41421356237",
    "1e-11",
  )
}

///|
test "ctx high-level transcendentals subset" {
  let ctx = MPContext::new(180, Nearest)
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.exp(ctx.from_int(1)), dps=10),
    "2.718281828",
    "1e-9",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.ln(ctx.from_int(2)), dps=10),
    "0.693147180",
    "1e-9",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(
      ctx.gamma(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)),
      dps=10,
    ),
    "1.772453",
    "1e-6",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.zeta(ctx.from_int(2)), dps=9),
    "1.6449340",
    "1e-7",
  )
}

///|
test "ctx e1 real/complex semantics" {
  let ctx = MPContext::new(180, Nearest)
  let pos = ctx.e1(ctx.parse("2"))
  assert_text_close_to_str_mp(pos.real.format(dps=10), "0.048900510", "1e-9")
  @debug.assert_eq(pos.imag, @mpf.RawMpf::zero())
  let neg = ctx.e1(ctx.parse("-2"))
  assert_text_close_to_str_mp(neg.real.format(dps=8), "-4.95423", "1e-5")
  assert_text_close_to_str_mp(neg.imag.format(dps=9), "-3.14159265", "1e-8")
  try ctx.e1_real(ctx.parse("-2")) catch {
    ComplexResult(msg) => assert_true(msg.contains("e1_real"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex-result error for negative input")
  }
}

///|
test "ctx expint negative real principal-branch subset" {
  let ctx = MPContext::new(220, Nearest)
  let pi = @libelefun.pi(220, Nearest)
  let e2 = ctx.exponential_integral(2, ctx.parse("-2"))
  assert_text_close_to_str_mp(e2.real.format(dps=9), "-2.51941261", "1e-8")
  let e2_im_ratio = e2.imag.div(pi, 220, Nearest)
  assert_text_close_to_str_mp(e2_im_ratio.format(dps=8), "-2", "1e-6")
  let e3 = ctx.exponential_integral(3, ctx.parse("-2"))
  assert_text_close_to_str_mp(e3.real.format(dps=7), "1.17511", "1e-5")
  let e3_im_ratio = e3.imag.div(pi, 220, Nearest)
  assert_text_close_to_str_mp(e3_im_ratio.format(dps=8), "-2", "1e-6")
  let ge2 = ctx.exponential_integral(2, ctx.parse("-2"), gamma=true)
  let ge2_target = ctx.exp(ctx.from_int(2)).negated(220, Nearest)
  let ge2_err = ge2.real.sub(ge2_target, 220, Nearest).abs(220, Nearest)
  assert_true(ge2_err < @mpf.RawMpf::parse("1e-10"))
  assert_true(ge2.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-20"))
  let ge3 = ctx.exponential_integral(3, ctx.parse("-2"), gamma=true)
  let ge3_target = ctx.exp(ctx.from_int(2)).mul_int(2, 220, Nearest)
  let ge3_err = ge3.real.sub(ge3_target, 220, Nearest).abs(220, Nearest)
  assert_true(ge3_err < @mpf.RawMpf::parse("1e-10"))
  assert_true(ge3.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-20"))
}

///|
test "ctx complex api and structured errors" {
  let ctx = MPContext::new(180, Nearest)
  let zero = @mpc.RawMpc::zero()
  try ctx.complex_log(zero) catch {
    PoleError(msg) => assert_true(msg.contains("complex_log"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_log pole error")
  }
  try
    ctx.complex_pow(
      zero,
      @mpc.RawMpc::new(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::zero()),
    )
  catch {
    DomainError(msg) => assert_true(msg.contains("complex_pow"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_pow domain error")
  }
  let minus_one = @mpc.RawMpc::new(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::zero(),
  )
  let sqrt_minus_one = ctx.complex_sqrt(minus_one)
  assert_text_close_to_str_mp(sqrt_minus_one.real.format(dps=6), "0", "1e-6")
  assert_text_close_to_str_mp(sqrt_minus_one.imag.format(dps=10), "1", "1e-9")
  try
    ctx.complex_gamma(
      @mpc.RawMpc::new(@mpf.RawMpf::from_int(0), @mpf.RawMpf::zero()),
    )
  catch {
    PoleError(msg) => assert_true(msg.contains("complex_gamma"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_gamma pole error")
  }
  try
    ctx.complex_zeta(@mpc.RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::zero()))
  catch {
    PoleError(msg) => assert_true(msg.contains("complex_zeta"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_zeta pole error")
  }
  let zeta_alt_one = ctx.complex_zeta(
    @mpc.RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::zero()),
    alt=true,
  )
  assert_text_close_to_str_mp(
    zeta_alt_one.real.format(dps=10),
    "0.693147180",
    "1e-9",
  )
  @debug.assert_eq(zeta_alt_one.imag, @mpf.RawMpf::zero())
}

///|
test "ctx mpmath wrapper critical-line zeta subset" {
  let ctx = MPContext::new(300, Nearest)
  let s = ctx.complex(ctx.parse("0.5"), ctx.parse("14.134725141734693"))
  let z = ctx.complex_zeta(s)
  let z_abs = z.abs(300, Nearest)
  assert_true(z_abs < @mpf.RawMpf::parse("1e-8"))
}

///|
test "ctx mpmath wrapper zeta conjugation subset" {
  let ctx = MPContext::new(300, Nearest)
  let sp = ctx.complex(ctx.parse("0.7"), ctx.parse("13"))
  let sn = ctx.complex(ctx.parse("0.7"), ctx.parse("-13"))
  let zp = ctx.complex_zeta(sp)
  let zn = ctx.complex_zeta(sn)
  let re_diff = zp.real.sub(zn.real, 320, Nearest).abs(320, Nearest)
  let im_sum = zp.imag.add(zn.imag, 320, Nearest).abs(320, Nearest)
  assert_true(re_diff < @mpf.RawMpf::parse("2e-12"))
  assert_true(im_sum < @mpf.RawMpf::parse("2e-12"))
}
