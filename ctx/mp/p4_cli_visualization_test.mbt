///|
fn p4_square(x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
}

///|
fn p4_identity(z : @mpc.RawMpc) -> @mpc.RawMpc {
  z
}

///|
test "p4 cli literal/version subset from mpmath test_cli" {
  let ctx = new(100, @mpf.round_nearest)
  assert_true(cli_version().has_prefix("0.2."))
  assert_true(ctx.cli_eval_division(1, 2, dps=8).has_prefix("0.5"))
  assert_true(ctx.cli_eval_literal("10.9", dps=6).has_prefix("10.9"))
  let low = ctx.cli_eval_literal("1e100", dps=24)
  let up = ctx.cli_eval_literal("1E100", dps=24)
  assert_true(low.has_suffix("e+100"))
  assert_eq(low, up)
  assert_true(ctx.cli_eval_literal("0x1p-1", dps=8).has_prefix("0.5"))
  assert_true(ctx.cli_eval_literal("0b10", dps=8).has_prefix("2"))
}

///|
test "p4 visualization plot axes subset from mpmath test_visualization" {
  let ctx = new(220, @mpf.round_nearest)
  let axes = plot_axes()
  let points = ctx.plot(
    p4_square,
    (ctx.make_int(0), ctx.make_int(3)),
    axes,
    samples=9,
  )
  assert_eq(axes.xlabel, "x")
  assert_eq(axes.ylabel, "f(x)")
  assert_eq(points.length(), 9)
  let (x0, y0) = points[0]
  assert_true(@mpf.mpf_eq(x0, @mpf.fzero))
  assert_true(@mpf.mpf_eq(y0, @mpf.fzero))
  let (xn, yn) = points[points.length() - 1]
  assert_true(@mpf.mpf_eq(xn, @mpf.from_int(3)))
  assert_true(@mpf.mpf_eq(yn, @mpf.from_int(9)))
}

///|
test "p4 visualization cplot axes subset from mpmath test_visualization" {
  let ctx = new(220, @mpf.round_nearest)
  let axes = plot_axes()
  let values = ctx.cplot(
    p4_identity,
    (ctx.make_int(-2), ctx.make_int(2)),
    (ctx.make_int(-10), ctx.make_int(10)),
    axes,
    samples=5,
  )
  assert_eq(axes.xlabel, "Re(z)")
  assert_eq(axes.ylabel, "Im(z)")
  assert_eq(values.length(), 25)
  let (z0, w0) = values[0]
  let (zn, wn) = values[values.length() - 1]
  assert_eq(z0, w0)
  assert_eq(zn, wn)
}
