///|
test "identify zeta4 with pi**4 basis subset" {
  let ctx = MPContext::new(320, Nearest)
  let z4 = ctx.zeta(ctx.from_int(4))
  let p = ctx.precision() + 40
  let pi = @libelefun.pi(p, Nearest)
  let pi4 = pi.pow_int(4, p, Nearest)
  let basis : Map[String, @mpf.RawMpf] = { "pi**4": pi4 }
  @debug.assert_eq(ctx.identify(z4, constants=basis), "((1/90)*pi**4)")
}

///|
test "identify exp/log subset from mpmath test_identify" {
  let ctx = MPContext::new(260, Nearest)
  let exp5 = ctx.exp(ctx.from_int(5))
  let exp4 = ctx.exp(ctx.from_int(4))
  let log5 = ctx.ln(ctx.from_int(5))
  @debug.assert_eq(ctx.identify(exp5), "exp(5)")
  @debug.assert_eq(ctx.identify(exp4), "exp(4)")
  @debug.assert_eq(ctx.identify(log5), "log(5)")
}

///|
test "identify exp(3*pi) and custom constant alias subset" {
  let ctx = MPContext::new(320, Nearest)
  let p = ctx.precision() + 40
  let pi = @libelefun.pi(p, Nearest)
  let three_pi = pi.mul_int(3, p, Nearest)
  let exp_three_pi = @libelefun.exp(three_pi, p, Nearest)
  @debug.assert_eq(ctx.identify(exp_three_pi), "exp((3*pi))")
  let one_plus_pi = @mpf.RawMpf::one().add(pi, p, Nearest)
  let constants : Map[String, @mpf.RawMpf] = { "a": pi }
  @debug.assert_eq(ctx.identify(one_plus_pi, constants~), "(1 + 1*a)")
}

///|
test "identify rational fallback subset" {
  let ctx = MPContext::new(200, Nearest)
  let x = ctx.parse("0.125")
  @debug.assert_eq(ctx.identify(x), "(1/8)")
  @debug.assert_eq(ctx.identify(ctx.from_int(3)), "3")
}
