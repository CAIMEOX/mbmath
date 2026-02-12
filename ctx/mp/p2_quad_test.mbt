///|
test "p2 quad finite and piecewise subset from mpmath test_quad" {
  let ctx = new(260, @mpf.round_nearest)
  let poly = (x : @mpf.RawMpf) => {
    let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
    let x3 = @mpf.mpf_mul(x2, x, 260, @mpf.round_nearest)
    @mpf.mpf_sub(
      x3,
      @mpf.mpf_mul_int(x2, 3, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    )
  }
  let i_poly_ts = ctx.quadts(poly, ctx.make_int(-2), ctx.make_int(4))
  let i_poly_gl = ctx.quadgl(poly, ctx.make_int(-2), ctx.make_int(4))
  assert_close_mpf_str(i_poly_ts, "-12", "2e-8")
  assert_close_mpf_str(i_poly_gl, "-12", "2e-8")

  let pi = @libelefun.mpf_pi(260, @mpf.round_nearest)
  let i_sin = ctx.quadts((x : @mpf.RawMpf) => ctx.sin(x), @mpf.fzero, pi)
  assert_close_mpf_str(i_sin, "2", "2e-8")
  let i_sin_sym = ctx.quadts(
    (x : @mpf.RawMpf) => ctx.sin(x),
    ctx.make_int(-1),
    ctx.make_int(1),
  )
  assert_close_mpf_str(i_sin_sym, "0", "2e-8")

  let sign_fn = (x : @mpf.RawMpf) => @mpf.from_int(@mpf.mpf_sign(x))
  let i_piece = ctx.quad(sign_fn, [
    ctx.make_float("-0.5"),
    ctx.make_float("0.9"),
    ctx.make_int(1),
  ])
  assert_close_mpf_str(i_piece, "0.5", "3e-5")

  let i_left_inf = ctx.quadts(
    (x : @mpf.RawMpf) => @libelefun.mpf_exp(x, 260, @mpf.round_nearest),
    @mpf.fninf,
    ctx.make_int(-1),
  )
  assert_close_mpf_str(i_left_inf, "0.3678794411714423215955238", "2e-5")

  let i_right_inf = ctx.quadts(
    (x : @mpf.RawMpf) => {
      @libelefun.mpf_exp(
        @mpf.mpf_neg(x, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      )
    },
    @mpf.fzero,
    @mpf.finf,
  )
  assert_close_mpf_str(i_right_inf, "1", "2e-5")

  let i_gauss = ctx.quadts(
    (x : @mpf.RawMpf) => {
      let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
      @libelefun.mpf_exp(
        @mpf.mpf_neg(x2, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      )
    },
    @mpf.fninf,
    @mpf.finf,
  )
  let sqrt_pi = ctx.sqrt(pi)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(i_gauss, sqrt_pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("2e-4"),
    ),
  )

  let i_cauchy = ctx.quadts(
    (x : @mpf.RawMpf) => {
      let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
      let den = @mpf.mpf_add(@mpf.fone, x2, 260, @mpf.round_nearest)
      @mpf.mpf_div(@mpf.fone, den, 260, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    @mpf.fninf,
    @mpf.finf,
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(i_cauchy, pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("2e-4"),
    ),
  )

  let i_mirror = ctx.quad(
    (x : @mpf.RawMpf) => {
      let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
      @libelefun.mpf_exp(
        @mpf.mpf_neg(x2, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      )
    },
    [@mpf.finf, @mpf.fninf],
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_add(i_mirror, sqrt_pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("2e-4"),
    ),
  )
}
