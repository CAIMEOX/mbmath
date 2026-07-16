///|
fn plot_square(x : @mpf.RawMpf) -> @mpf.RawMpf {
  x.mul(x, 260, Nearest)
}

///|
fn plot_identity(z : @mpc.RawMpc) -> @mpc.RawMpc {
  z
}

///|
fn cli_text_matches(
  got_text : String,
  expected_text : String,
  dps : Int,
) -> Bool raise {
  let p = if dps > 0 { dps * 5 + 80 } else { 160 }
  let got = @mpf.RawMpf::parse(got_text, prec=p, rnd=Nearest)
  let expected = @mpf.RawMpf::parse(expected_text, prec=p, rnd=Nearest)
  let err = got.sub(expected, p, Nearest).abs(p, Nearest)
  let rel_digits = if dps > 2 { dps - 2 } else { 1 }
  let rel_tol = @mpf.RawMpf::parse("1e-\{rel_digits}", prec=p, rnd=Nearest)
  let abs_expected = expected.abs(p, Nearest)
  let scale = if abs_expected > @mpf.RawMpf::one() {
    abs_expected
  } else {
    @mpf.RawMpf::one()
  }
  let tol = scale.mul(rel_tol, p, Nearest)
  err <= tol
}

///|
test "cli literal/version subset from mpmath test_cli" {
  let ctx = MPContext::new(100, Nearest)
  let version = cli_version()
  let parts : Array[String] = []
  for part in version.split(".") {
    parts.push(part.to_owned())
  }
  assert_true(parts.length() >= 3)
  @debug.assert_eq(parts[0], "0")
  @debug.assert_eq(parts[1], "3")
  assert_true(cli_text_matches(ctx.cli_eval_division(1, 2, dps=8), "0.5", 8))
  assert_true(cli_text_matches(ctx.cli_eval_literal("10.9", dps=6), "10.9", 6))
  let low = ctx.cli_eval_literal("1e100", dps=24)
  let up = ctx.cli_eval_literal("1E100", dps=24)
  assert_true(low.has_suffix("e+100"))
  @debug.assert_eq(low, up)
  assert_true(cli_text_matches(ctx.cli_eval_literal("0x1p-1", dps=8), "0.5", 8))
  assert_true(cli_text_matches(ctx.cli_eval_literal("0b10", dps=8), "2", 8))
}

///|
test "visualization plot axes subset from mpmath test_visualization" {
  let ctx = MPContext::new(220, Nearest)
  let axes = PlotAxes::new()
  let points = ctx.plot(
    plot_square,
    (ctx.from_int(0), ctx.from_int(3)),
    axes,
    samples=9,
  )
  @debug.assert_eq(axes.xlabel, "x")
  @debug.assert_eq(axes.ylabel, "f(x)")
  @debug.assert_eq(points.length(), 9)
  let (x0, y0) = points[0]
  assert_true(x0 == @mpf.RawMpf::zero())
  assert_true(y0 == @mpf.RawMpf::zero())
  let (xn, yn) = points[points.length() - 1]
  assert_true(xn == @mpf.RawMpf::from_int(3))
  assert_true(yn == @mpf.RawMpf::from_int(9))
}

///|
test "visualization cplot axes subset from mpmath test_visualization" {
  let ctx = MPContext::new(220, Nearest)
  let axes = PlotAxes::new()
  let values = ctx.cplot(
    plot_identity,
    (ctx.from_int(-2), ctx.from_int(2)),
    (ctx.from_int(-10), ctx.from_int(10)),
    axes,
    samples=5,
  )
  @debug.assert_eq(axes.xlabel, "Re(z)")
  @debug.assert_eq(axes.ylabel, "Im(z)")
  @debug.assert_eq(values.length(), 25)
  let (z0, w0) = values[0]
  let (zn, wn) = values[values.length() - 1]
  @debug.assert_eq(z0, w0)
  @debug.assert_eq(zn, wn)
}
