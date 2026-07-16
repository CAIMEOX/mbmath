///|
test "quad finite and piecewise subset from mpmath test_quad" {
  let ctx = MPContext::new(260, Nearest)
  let poly = (x : @mpf.RawMpf) => {
    let x2 = x.mul(x, 260, Nearest)
    let x3 = x2.mul(x, 260, Nearest)
    x3.sub(x2.mul_int(3, 260, Nearest), 260, Nearest)
  }
  let i_poly_ts = ctx.quadts(poly, ctx.from_int(-2), ctx.from_int(4))
  let i_poly_gl = ctx.quadgl(poly, ctx.from_int(-2), ctx.from_int(4))
  let i_poly_gl_degree = ctx.quadgl(
    poly,
    ctx.from_int(-2),
    ctx.from_int(4),
    max_degree=12,
  )
  assert_close_mpf_str(i_poly_ts, "-12", "2e-8")
  assert_close_mpf_str(i_poly_gl, "-12", "2e-8")
  assert_close_mpf_str(i_poly_gl_degree, "-12", "2e-8")

  let pi = @libelefun.pi(260, Nearest)
  let i_sin = ctx.quadts(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.RawMpf::zero(),
    pi,
  )
  assert_close_mpf_str(i_sin, "2", "2e-8")
  let i_sin_sym = ctx.quadts(
    (x : @mpf.RawMpf) => ctx.sin(x),
    ctx.from_int(-1),
    ctx.from_int(1),
  )
  assert_close_mpf_str(i_sin_sym, "0", "2e-8")

  let sign_fn = (x : @mpf.RawMpf) => @mpf.RawMpf::from_int(x.signum())
  let i_piece = ctx.quad(sign_fn, [
    ctx.parse("-0.5"),
    ctx.parse("0.9"),
    ctx.from_int(1),
  ])
  let i_piece_degree = ctx.quad(
    sign_fn,
    [ctx.parse("-0.5"), ctx.parse("0.9"), ctx.from_int(1)],
    max_degree=12,
  )
  assert_close_mpf_str(i_piece, "0.5", "3e-5")
  assert_close_mpf_str(i_piece_degree, "0.5", "4e-5")

  let i_left_inf = ctx.quadts(
    (x : @mpf.RawMpf) => @libelefun.exp(x, 260, Nearest),
    @mpf.RawMpf::negative_infinity(),
    ctx.from_int(-1),
  )
  assert_close_mpf_str(i_left_inf, "0.3678794411714423215955238", "2e-5")

  let i_right_inf = ctx.quadts(
    (x : @mpf.RawMpf) => @libelefun.exp(x.negated(260, Nearest), 260, Nearest),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_close_mpf_str(i_right_inf, "1", "2e-5")

  let i_gauss = ctx.quadts(
    (x : @mpf.RawMpf) => {
      let x2 = x.mul(x, 260, Nearest)
      @libelefun.exp(x2.negated(260, Nearest), 260, Nearest)
    },
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  )
  let sqrt_pi = ctx.sqrt(pi)
  assert_true(
    i_gauss.sub(sqrt_pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("2e-4"),
  )

  let i_cauchy = ctx.quadts(
    (x : @mpf.RawMpf) => {
      let x2 = x.mul(x, 260, Nearest)
      let den = @mpf.RawMpf::one().add(x2, 260, Nearest)
      @mpf.RawMpf::one().div(den, 260, Nearest)
    },
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  )
  assert_true(
    i_cauchy.sub(pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("2e-4"),
  )

  let i_mirror = ctx.quad(
    (x : @mpf.RawMpf) => {
      let x2 = x.mul(x, 260, Nearest)
      @libelefun.exp(x2.negated(260, Nearest), 260, Nearest)
    },
    [@mpf.RawMpf::infinity(), @mpf.RawMpf::negative_infinity()],
  )
  assert_true(
    i_mirror.add(sqrt_pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("2e-4"),
  )
}
