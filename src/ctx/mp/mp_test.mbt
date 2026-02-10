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
  match ctx.e1_real(ctx.make_float("-2")) {
    Ok(_) => fail("expected complex-result error for negative input")
    Err(ComplexResult(msg)) => assert_true(msg.contains("e1_real"))
    Err(_) => fail("unexpected error kind")
  }
}

///|
test "ctx expint negative real principal-branch subset" {
  let ctx = new(220, @mpf.round_nearest)
  let pi = @libelefun.mpf_pi(220, @mpf.round_nearest)
  match ctx.expint(2, ctx.make_float("-2")) {
    Ok(v) => {
      assert_true(@mpf.to_str_opts(v.real, dps=9).has_prefix("-2.51941261"))
      let im_ratio = @mpf.mpf_div(v.imag, pi, 220, @mpf.round_nearest)
      assert_true(@mpf.to_str_opts(im_ratio, dps=8).has_prefix("-2"))
    }
    Err(msg) => fail("\{msg}")
  }
  match ctx.expint(3, ctx.make_float("-2")) {
    Ok(v) => {
      assert_true(@mpf.to_str_opts(v.real, dps=7).has_prefix("1.17511"))
      let im_ratio = @mpf.mpf_div(v.imag, pi, 220, @mpf.round_nearest)
      assert_true(@mpf.to_str_opts(im_ratio, dps=8).has_prefix("-2"))
    }
    Err(msg) => fail("\{msg}")
  }
  match ctx.expint(2, ctx.make_float("-2"), gamma=true) {
    Ok(v) => {
      let target = @mpf.mpf_neg(
        ctx.exp(ctx.make_int(2)),
        220,
        @mpf.round_nearest,
      )
      let err = @mpf.mpf_abs(
        @mpf.mpf_sub(v.real, target, 220, @mpf.round_nearest),
        220,
        @mpf.round_nearest,
      )
      assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-10")))
      assert_true(
        @mpf.mpf_lt(
          @mpf.mpf_abs(v.imag, 220, @mpf.round_nearest),
          @mpf.from_str("1e-20"),
        ),
      )
    }
    Err(msg) => fail("\{msg}")
  }
  match ctx.expint(3, ctx.make_float("-2"), gamma=true) {
    Ok(v) => {
      let target = @mpf.mpf_mul_int(
        ctx.exp(ctx.make_int(2)),
        2,
        220,
        @mpf.round_nearest,
      )
      let err = @mpf.mpf_abs(
        @mpf.mpf_sub(v.real, target, 220, @mpf.round_nearest),
        220,
        @mpf.round_nearest,
      )
      assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-10")))
      assert_true(
        @mpf.mpf_lt(
          @mpf.mpf_abs(v.imag, 220, @mpf.round_nearest),
          @mpf.from_str("1e-20"),
        ),
      )
    }
    Err(msg) => fail("\{msg}")
  }
}

///|
test "ctx complex api and structured errors" {
  let ctx = new(180, @mpf.round_nearest)
  let zero = @mpc.zero()
  match ctx.complex_log(zero) {
    Ok(_) => fail("expected complex_log pole error")
    Err(PoleError(msg)) => assert_true(msg.contains("complex_log"))
    Err(_) => fail("unexpected error kind")
  }
  match ctx.complex_pow(zero, @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero)) {
    Ok(_) => fail("expected complex_pow domain error")
    Err(DomainError(msg)) => assert_true(msg.contains("complex_pow"))
    Err(_) => fail("unexpected error kind")
  }
  let minus_one = @mpc.from_parts(@mpf.from_int(-1), @mpf.fzero)
  match ctx.complex_sqrt(minus_one) {
    Ok(v) => {
      assert_true(@mpf.to_str_opts(v.real, dps=6).has_prefix("0"))
      assert_true(@mpf.to_str_opts(v.imag, dps=10).has_prefix("1"))
    }
    Err(msg) => fail("\{msg}")
  }
  match ctx.complex_gamma(@mpc.from_parts(@mpf.from_int(0), @mpf.fzero)) {
    Ok(_) => fail("expected complex_gamma pole error")
    Err(PoleError(msg)) => assert_true(msg.contains("complex_gamma"))
    Err(_) => fail("unexpected error kind")
  }
  match ctx.complex_zeta(@mpc.from_parts(@mpf.fone, @mpf.fzero)) {
    Ok(_) => fail("expected complex_zeta pole error")
    Err(PoleError(msg)) => assert_true(msg.contains("complex_zeta"))
    Err(_) => fail("unexpected error kind")
  }
  match ctx.complex_zeta(@mpc.from_parts(@mpf.fone, @mpf.fzero), alt=true) {
    Ok(v) => {
      assert_true(@mpf.to_str_opts(v.real, dps=10).has_prefix("0.693147180"))
      assert_eq(v.imag, @mpf.fzero)
    }
    Err(msg) => fail("\{msg}")
  }
}
