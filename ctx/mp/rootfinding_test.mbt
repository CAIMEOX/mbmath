///|
test "rootfinding findroot subset from mpmath test_rootfinding" {
  let ctx = MPContext::new(260, Nearest)
  let four = ctx.from_int(4)
  let three = ctx.from_int(3)
  let f_linear = (x : @mpf.RawMpf) => ctx.sub(ctx.mul(four, x), three)
  let r_linear = ctx.findroot(f_linear, ctx.from_int(5))
  assert_close_mpf_str(r_linear, "0.75", "1e-12")

  let pi = @libelefun.pi(260, Nearest)
  let f_sin = (x : @mpf.RawMpf) => ctx.sin(x)
  let r_sin_newton = ctx.findroot(f_sin, ctx.from_int(3))
  let r_sin_secant = ctx.findroot(f_sin, ctx.from_int(3), x1=ctx.parse("3.14"))
  let r_sin_newton_solver = ctx.findroot(
    f_sin,
    ctx.from_int(3),
    solver="newton",
  )
  assert_true(
    r_sin_newton.sub(pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("1e-9"),
  )
  assert_true(
    r_sin_newton_solver.sub(pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("1e-9"),
  )
  assert_true(
    r_sin_secant.sub(pi, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("1e-9"),
  )

  @debug.assert_eq(
    ctx.findroot((_ : @mpf.RawMpf) => @mpf.RawMpf::zero(), ctx.from_int(1)),
    ctx.from_int(1),
  )
  @debug.assert_eq(
    ctx.findroot((x : @mpf.RawMpf) => x, @mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )

  try
    ctx.findroot(
      (x : @mpf.RawMpf) => {
        ignore(x)
        ctx.from_int(-1)
      },
      @mpf.RawMpf::zero(),
    )
  catch {
    MPError::ConvergenceError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected convergence error")
  }

  let sq_minus_1 = (x : @mpf.RawMpf) => {
    x.mul(x, 260, Nearest).sub(@mpf.RawMpf::one(), 260, Nearest)
  }
  let r_bisect = ctx.findroot_interval(
    sq_minus_1,
    @mpf.RawMpf::zero(),
    ctx.from_int(2),
  )
  let r_bisect_solver = ctx.findroot(
    sq_minus_1,
    @mpf.RawMpf::zero(),
    x1=ctx.from_int(2),
    solver="bisect",
  )
  let r_bisect_rev = ctx.findroot_interval(
    sq_minus_1,
    ctx.from_int(2),
    @mpf.RawMpf::zero(),
  )
  assert_close_mpf_str(r_bisect, "1", "1e-18")
  assert_close_mpf_str(r_bisect_solver, "1", "1e-18")
  assert_close_mpf_str(r_bisect_rev, "1", "1e-18")

  try
    ctx.findroot_interval(
      (x : @mpf.RawMpf) => {
        x.mul(x, 260, Nearest).add(@mpf.RawMpf::one(), 260, Nearest)
      },
      @mpf.RawMpf::zero(),
      ctx.from_int(2),
    )
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected bracketing ValueError")
  }

  try
    ctx.findroot((x : @mpf.RawMpf) => x, @mpf.RawMpf::zero(), solver="bad")
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for unknown solver")
  }

  let sys = (x : @mpf.RawMpf, y : @mpf.RawMpf) => {
    (
      x.add(y, 260, Nearest).sub(ctx.from_int(3), 260, Nearest),
      x.sub(y, 260, Nearest).sub(@mpf.RawMpf::one(), 260, Nearest),
    )
  }
  let (rx, ry) = ctx.findroot2(sys, ctx.from_int(7), ctx.from_int(-3))
  assert_close_mpf_str(rx, "2", "1e-15")
  assert_close_mpf_str(ry, "1", "1e-15")
}
