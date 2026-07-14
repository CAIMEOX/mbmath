///|
fn plot_square(x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
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
  let got = @mpf.from_str(got_text, prec=p, rnd=@mpf.round_nearest)
  let expected = @mpf.from_str(expected_text, prec=p, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(got, expected, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let rel_digits = if dps > 2 { dps - 2 } else { 1 }
  let rel_tol = @mpf.from_str(
    "1e-\{rel_digits}",
    prec=p,
    rnd=@mpf.round_nearest,
  )
  let abs_expected = @mpf.mpf_abs(expected, p, @mpf.round_nearest)
  let scale = if @mpf.mpf_gt(abs_expected, @mpf.fone) {
    abs_expected
  } else {
    @mpf.fone
  }
  let tol = @mpf.mpf_mul(scale, rel_tol, p, @mpf.round_nearest)
  @mpf.mpf_le(err, tol)
}

///|
test "cli literal/version subset from mpmath test_cli" {
  let ctx = new(100, @mpf.round_nearest)
  let version = cli_version()
  let parts : Array[String] = []
  for part in version.split(".") {
    parts.push(part.to_owned())
  }
  assert_true(parts.length() >= 3)
  assert_eq(parts[0], "0")
  assert_eq(parts[1], "3")
  assert_true(cli_text_matches(ctx.cli_eval_division(1, 2, dps=8), "0.5", 8))
  assert_true(cli_text_matches(ctx.cli_eval_literal("10.9", dps=6), "10.9", 6))
  let low = ctx.cli_eval_literal("1e100", dps=24)
  let up = ctx.cli_eval_literal("1E100", dps=24)
  assert_true(low.has_suffix("e+100"))
  assert_eq(low, up)
  assert_true(cli_text_matches(ctx.cli_eval_literal("0x1p-1", dps=8), "0.5", 8))
  assert_true(cli_text_matches(ctx.cli_eval_literal("0b10", dps=8), "2", 8))
}

///|
test "visualization plot axes subset from mpmath test_visualization" {
  let ctx = new(220, @mpf.round_nearest)
  let axes = plot_axes()
  let points = ctx.plot(
    plot_square,
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
test "visualization cplot axes subset from mpmath test_visualization" {
  let ctx = new(220, @mpf.round_nearest)
  let axes = plot_axes()
  let values = ctx.cplot(
    plot_identity,
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
