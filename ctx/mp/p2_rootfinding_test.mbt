///|
test "p2 rootfinding findroot subset from mpmath test_rootfinding" {
  let ctx = new(260, @mpf.round_nearest)
  let four = ctx.make_int(4)
  let three = ctx.make_int(3)
  let f_linear = (x : @mpf.RawMpf) => ctx.sub(ctx.mul(four, x), three)
  let r_linear = ctx.findroot(f_linear, ctx.make_int(5))
  assert_close_mpf_str(r_linear, "0.75", "1e-12")

  let pi = @libelefun.mpf_pi(260, @mpf.round_nearest)
  let f_sin = (x : @mpf.RawMpf) => ctx.sin(x)
  let r_sin_newton = ctx.findroot(f_sin, ctx.make_int(3))
  let r_sin_secant = ctx.findroot(
    f_sin,
    ctx.make_int(3),
    x1=ctx.make_float("3.14"),
  )
  let r_sin_newton_solver = ctx.findroot(
    f_sin,
    ctx.make_int(3),
    solver="newton",
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(r_sin_newton, pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-9"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(r_sin_newton_solver, pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-9"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(r_sin_secant, pi, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-9"),
    ),
  )

  assert_eq(
    ctx.findroot((_ : @mpf.RawMpf) => @mpf.fzero, ctx.make_int(1)),
    ctx.make_int(1),
  )
  assert_eq(ctx.findroot((x : @mpf.RawMpf) => x, @mpf.fzero), @mpf.fzero)

  let bad : Result[@mpf.RawMpf, MPError] = try? ctx.findroot(
    (x : @mpf.RawMpf) => {
      ignore(x)
      ctx.make_int(-1)
    },
    @mpf.fzero,
  )
  match bad {
    Ok(_) => fail("expected convergence error")
    Err(MPError::ConvergenceError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let sq_minus_1 = (x : @mpf.RawMpf) => {
    @mpf.mpf_sub(
      @mpf.mpf_mul(x, x, 260, @mpf.round_nearest),
      @mpf.fone,
      260,
      @mpf.round_nearest,
    )
  }
  let r_bisect = ctx.findroot_interval(sq_minus_1, @mpf.fzero, ctx.make_int(2))
  let r_bisect_solver = ctx.findroot(
    sq_minus_1,
    @mpf.fzero,
    x1=ctx.make_int(2),
    solver="bisect",
  )
  let r_bisect_rev = ctx.findroot_interval(
    sq_minus_1,
    ctx.make_int(2),
    @mpf.fzero,
  )
  assert_close_mpf_str(r_bisect, "1", "1e-18")
  assert_close_mpf_str(r_bisect_solver, "1", "1e-18")
  assert_close_mpf_str(r_bisect_rev, "1", "1e-18")

  let bracket_bad : Result[@mpf.RawMpf, MPError] = try? ctx.findroot_interval(
    (x : @mpf.RawMpf) => {
      @mpf.mpf_add(
        @mpf.mpf_mul(x, x, 260, @mpf.round_nearest),
        @mpf.fone,
        260,
        @mpf.round_nearest,
      )
    },
    @mpf.fzero,
    ctx.make_int(2),
  )
  match bracket_bad {
    Ok(_) => fail("expected bracketing ValueError")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let solver_bad : Result[@mpf.RawMpf, MPError] = try? ctx.findroot(
    (x : @mpf.RawMpf) => x,
    @mpf.fzero,
    solver="bad",
  )
  match solver_bad {
    Ok(_) => fail("expected ValueError for unknown solver")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let sys = (x : @mpf.RawMpf, y : @mpf.RawMpf) => {
    (
      @mpf.mpf_sub(
        @mpf.mpf_add(x, y, 260, @mpf.round_nearest),
        ctx.make_int(3),
        260,
        @mpf.round_nearest,
      ),
      @mpf.mpf_sub(
        @mpf.mpf_sub(x, y, 260, @mpf.round_nearest),
        @mpf.fone,
        260,
        @mpf.round_nearest,
      ),
    )
  }
  let (rx, ry) = ctx.findroot2(sys, ctx.make_int(7), ctx.make_int(-3))
  assert_close_mpf_str(rx, "2", "1e-15")
  assert_close_mpf_str(ry, "1", "1e-15")
}
