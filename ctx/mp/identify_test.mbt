///|
test "identify zeta4 with pi**4 basis subset" {
  let ctx = new(320, @mpf.round_nearest)
  let z4 = ctx.zeta(ctx.make_int(4))
  let p = ctx.precision() + 40
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let pi4 = @mpf.mpf_pow_int(pi, 4, p, @mpf.round_nearest)
  let basis : Map[String, @mpf.RawMpf] = { "pi**4": pi4 }
  @debug.assert_eq(ctx.identify(z4, constants=basis), "((1/90)*pi**4)")
}

///|
test "identify exp/log subset from mpmath test_identify" {
  let ctx = new(260, @mpf.round_nearest)
  let exp5 = ctx.exp(ctx.make_int(5))
  let exp4 = ctx.exp(ctx.make_int(4))
  let log5 = ctx.ln(ctx.make_int(5))
  @debug.assert_eq(ctx.identify(exp5), "exp(5)")
  @debug.assert_eq(ctx.identify(exp4), "exp(4)")
  @debug.assert_eq(ctx.identify(log5), "log(5)")
}

///|
test "identify exp(3*pi) and custom constant alias subset" {
  let ctx = new(320, @mpf.round_nearest)
  let p = ctx.precision() + 40
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let three_pi = @mpf.mpf_mul_int(pi, 3, p, @mpf.round_nearest)
  let exp_three_pi = @libelefun.mpf_exp(three_pi, p, @mpf.round_nearest)
  @debug.assert_eq(ctx.identify(exp_three_pi), "exp((3*pi))")
  let one_plus_pi = @mpf.mpf_add(@mpf.fone, pi, p, @mpf.round_nearest)
  let constants : Map[String, @mpf.RawMpf] = { "a": pi }
  @debug.assert_eq(ctx.identify(one_plus_pi, constants~), "(1 + 1*a)")
}

///|
test "identify rational fallback subset" {
  let ctx = new(200, @mpf.round_nearest)
  let x = ctx.make_float("0.125")
  @debug.assert_eq(ctx.identify(x), "(1/8)")
  @debug.assert_eq(ctx.identify(ctx.make_int(3)), "3")
}
