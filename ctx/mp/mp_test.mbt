///|
fn assert_text_close_to_str_mp(
  actual_text : String,
  expected_text : String,
  tol : String,
) -> Unit raise {
  let actual = @mpf.from_str(actual_text, prec=460, rnd=@mpf.round_nearest)
  let expected = @mpf.from_str(expected_text, prec=460, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(actual, expected, 420, @mpf.round_nearest),
    420,
    @mpf.round_nearest,
  )
  let tol_v = @mpf.from_str(tol, prec=420, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_lt(err, tol_v))
}

///|
test "ctx mpf basic wrappers" {
  let ctx = new(160, @mpf.round_nearest)
  let a = ctx.make_float("1.5")
  let b = ctx.make_int(2)
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
    ctx.to_string(ctx.div(@mpf.fone, @mpf.from_int(3)), dps=12),
    "0.333333333333",
    "1e-12",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.sqrt(ctx.make_int(2)), dps=12),
    "1.41421356237",
    "1e-11",
  )
}

///|
test "ctx high-level transcendentals subset" {
  let ctx = new(180, @mpf.round_nearest)
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.exp(ctx.make_int(1)), dps=10),
    "2.718281828",
    "1e-9",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.ln(ctx.make_int(2)), dps=10),
    "0.693147180",
    "1e-9",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(
      ctx.gamma(@mpf.from_man_exp(1N, -1, 0, @mpf.round_down)),
      dps=10,
    ),
    "1.772453",
    "1e-6",
  )
  assert_text_close_to_str_mp(
    ctx.to_string(ctx.zeta(ctx.make_int(2)), dps=9),
    "1.6449340",
    "1e-7",
  )
}

///|
test "ctx e1 real/complex semantics" {
  let ctx = new(180, @mpf.round_nearest)
  let pos = ctx.e1(ctx.make_float("2"))
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(pos.real, dps=10),
    "0.048900510",
    "1e-9",
  )
  assert_eq(pos.imag, @mpf.fzero)
  let neg = ctx.e1(ctx.make_float("-2"))
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(neg.real, dps=8),
    "-4.95423",
    "1e-5",
  )
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(neg.imag, dps=9),
    "-3.14159265",
    "1e-8",
  )
  try ctx.e1_real(ctx.make_float("-2")) catch {
    ComplexResult(msg) => assert_true(msg.contains("e1_real"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex-result error for negative input")
  }
}

///|
test "ctx expint negative real principal-branch subset" {
  let ctx = new(220, @mpf.round_nearest)
  let pi = @libelefun.mpf_pi(220, @mpf.round_nearest)
  let e2 = ctx.expint(2, ctx.make_float("-2"))
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(e2.real, dps=9),
    "-2.51941261",
    "1e-8",
  )
  let e2_im_ratio = @mpf.mpf_div(e2.imag, pi, 220, @mpf.round_nearest)
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(e2_im_ratio, dps=8),
    "-2",
    "1e-6",
  )
  let e3 = ctx.expint(3, ctx.make_float("-2"))
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(e3.real, dps=7),
    "1.17511",
    "1e-5",
  )
  let e3_im_ratio = @mpf.mpf_div(e3.imag, pi, 220, @mpf.round_nearest)
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(e3_im_ratio, dps=8),
    "-2",
    "1e-6",
  )
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
  try ctx.complex_log(zero) catch {
    PoleError(msg) => assert_true(msg.contains("complex_log"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_log pole error")
  }
  try
    ctx.complex_pow(zero, @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero))
  catch {
    DomainError(msg) => assert_true(msg.contains("complex_pow"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_pow domain error")
  }
  let minus_one = @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero)
  let sqrt_minus_one = ctx.complex_sqrt(minus_one)
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(sqrt_minus_one.real, dps=6),
    "0",
    "1e-6",
  )
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(sqrt_minus_one.imag, dps=10),
    "1",
    "1e-9",
  )
  try ctx.complex_gamma(@mpc.from_parts(@mpf.from_int(0), @mpf.fzero)) catch {
    PoleError(msg) => assert_true(msg.contains("complex_gamma"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_gamma pole error")
  }
  try ctx.complex_zeta(@mpc.from_parts(@mpf.fone, @mpf.fzero)) catch {
    PoleError(msg) => assert_true(msg.contains("complex_zeta"))
    _ => fail("unexpected error kind")
  } noraise {
    _ => fail("expected complex_zeta pole error")
  }
  let zeta_alt_one = ctx.complex_zeta(
    @mpc.from_parts(@mpf.fone, @mpf.fzero),
    alt=true,
  )
  assert_text_close_to_str_mp(
    @mpf.to_str_opts(zeta_alt_one.real, dps=10),
    "0.693147180",
    "1e-9",
  )
  assert_eq(zeta_alt_one.imag, @mpf.fzero)
}

///|
test "ctx mpmath wrapper critical-line zeta subset" {
  let ctx = new(300, @mpf.round_nearest)
  let s = ctx.make_complex(
    ctx.make_float("0.5"),
    ctx.make_float("14.134725141734693"),
  )
  let z = ctx.complex_zeta(s)
  let z_abs = @mpc.mpc_abs(z, 300, @mpf.round_nearest)
  assert_true(@mpf.mpf_lt(z_abs, @mpf.from_str("1e-8")))
}

///|
test "ctx mpmath wrapper zeta conjugation subset" {
  let ctx = new(300, @mpf.round_nearest)
  let sp = ctx.make_complex(ctx.make_float("0.7"), ctx.make_float("13"))
  let sn = ctx.make_complex(ctx.make_float("0.7"), ctx.make_float("-13"))
  let zp = ctx.complex_zeta(sp)
  let zn = ctx.complex_zeta(sn)
  let re_diff = @mpf.mpf_abs(
    @mpf.mpf_sub(zp.real, zn.real, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  let im_sum = @mpf.mpf_abs(
    @mpf.mpf_add(zp.imag, zn.imag, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(re_diff, @mpf.from_str("2e-12")))
  assert_true(@mpf.mpf_lt(im_sum, @mpf.from_str("2e-12")))
}
