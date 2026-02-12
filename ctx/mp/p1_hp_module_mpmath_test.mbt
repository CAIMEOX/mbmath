///|
test "p1 module context metadata and isolation subset" {
  let low = new(80, @mpf.round_down)
  let high = new(260, @mpf.round_nearest)
  assert_eq(low.precision(), 80)
  assert_eq(high.precision(), 260)
  assert_eq(low.round_mode(), @mpf.round_down)
  assert_eq(high.round_mode(), @mpf.round_nearest)
  let sqrt2_low = low.sqrt(low.make_int(2))
  let sqrt2_high = high.sqrt(high.make_int(2))
  assert_true(low.to_string(sqrt2_low, dps=8).has_prefix("1.4142136"))
  assert_true(
    high.to_string(sqrt2_high, dps=20).has_prefix("1.4142135623730950488"),
  )
}

///|
test "p1 hp expression a=sqrt(3)+pi/2 from mpmath test_hp" {
  let ctx = new(320, @mpf.round_nearest)
  let sqrt3 = ctx.sqrt(ctx.make_int(3))
  let pi = @libelefun.mpf_pi(ctx.precision(), ctx.round_mode())
  let half_pi = @mpf.mpf_div(
    pi,
    @mpf.from_int(2),
    ctx.precision(),
    ctx.round_mode(),
  )
  let a = ctx.add(sqrt3, half_pi)
  assert_true(ctx.to_string(a, dps=24).has_prefix("3.30284713436377391275877"))
}

///|
test "p1 hp log/exp of a subset from mpmath test_hp" {
  let ctx = new(360, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let log_a = ctx.ln(a)
  let exp_a = ctx.exp(a)
  assert_true(
    ctx.to_string(log_a, dps=22).has_prefix("1.194784864491089550288"),
  )
  assert_true(
    ctx.to_string(exp_a, dps=22).has_prefix("27.18994224087168661137"),
  )
}

///|
test "p1 hp sin/cos of a subset from mpmath test_hp" {
  let ctx = new(360, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let sin_a = ctx.sin(a)
  let cos_a = ctx.cos(a)
  assert_true(
    ctx.to_string(sin_a, dps=22).has_prefix("-0.1605565385746906274027"),
  )
  assert_true(
    ctx.to_string(cos_a, dps=22).has_prefix("-0.9870266449903537839933"),
  )
}

///|
test "p1 hp complex sqrt subset from mpmath test_hp" {
  let ctx = new(420, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let b = ctx.make_float("5.719681166601007617111261398629939965")
  let z = ctx.make_complex(a, b)
  let root = ctx.complex_sqrt(z)
  assert_true(
    @mpf.to_str_opts(root.real, dps=22).has_prefix("2.225720098415113027729"),
  )
  assert_true(
    @mpf.to_str_opts(root.imag, dps=22).has_prefix("1.284905763908469090237"),
  )
}

///|
test "p1 hp complex pow subset from mpmath test_hp" {
  let ctx = new(420, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let b = ctx.make_float("5.719681166601007617111261398629939965")
  let z = ctx.make_complex(a, b)
  let p = ctx.complex_pow(z, z)
  assert_true(
    @mpf.to_str_opts(p.real, dps=20).has_prefix("-0.15171310677859590091"),
  )
  assert_true(
    @mpf.to_str_opts(p.imag, dps=20).has_prefix("1.2697592504953448937"),
  )
}

///|
test "p1 mpmath-style wrapper consistency subset" {
  let ctx = new(260, @mpf.round_nearest)
  let x = ctx.make_float("2.5")
  let y = ctx.make_float("3.5")
  let sum = ctx.add(x, y)
  let manual = @mpf.mpf_add(x, y, 260, @mpf.round_nearest)
  assert_eq(sum, manual)
  let cg = ctx.complex_gamma(
    ctx.make_complex(ctx.make_float("0.5"), @mpf.fzero),
  )
  assert_true(@mpf.to_str_opts(cg.real, dps=16).has_prefix("1.772453850905516"))
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(cg.imag, 260, @mpf.round_nearest),
      @mpf.from_str("1e-18"),
    ),
  )
}

///|
test "p1 mpmath-style e1 branch behavior subset" {
  let ctx = new(260, @mpf.round_nearest)
  let pos = ctx.e1(ctx.make_float("2"))
  let neg = ctx.e1(ctx.make_float("-2"))
  assert_true(
    @mpf.to_str_opts(pos.real, dps=16).has_prefix("0.04890051070806112"),
  )
  assert_true(@mpf.to_str_opts(pos.imag, dps=8).has_prefix("0"))
  assert_true(
    @mpf.to_str_opts(neg.real, dps=16).has_prefix("-4.95423435600189"),
  )
  assert_true(
    @mpf.to_str_opts(neg.imag, dps=16).has_prefix("-3.14159265358979"),
  )
}
