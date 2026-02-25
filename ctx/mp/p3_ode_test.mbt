///|
test "p3 ode rk4 rational and harmonic subset from mpmath test_ode" {
  let ctx = new(260, @mpf.round_nearest)
  let p = 300

  let rational = (x : @mpf.RawMpf, y : ArrayView[@mpf.RawMpf]) => {
    let y2 = @mpf.mpf_mul(y[0], y[0], p, @mpf.round_nearest)
    let two_x = @mpf.mpf_mul_int(x, 2, p, @mpf.round_nearest)
    [
      @mpf.mpf_neg(
        @mpf.mpf_mul(two_x, y2, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
    ]
  }
  let y2 = ctx.ode_solve(
    rational,
    @mpf.fzero,
    [@mpf.fone],
    ctx.make_int(2),
    steps=600,
  )
  assert_close_mpf_str(y2[0], "0.2", "2e-5")

  let harmonic = (x : @mpf.RawMpf, y : ArrayView[@mpf.RawMpf]) => {
    ignore(x)
    [@mpf.mpf_neg(y[1], p, @mpf.round_nearest), y[0]]
  }
  let ts : Array[@mpf.RawMpf] = [
    @mpf.fzero,
    ctx.make_int(1),
    ctx.make_float("2.5"),
    ctx.make_float("3.7"),
    ctx.make_int(8),
  ]
  let ys = ctx.ode_solve_grid(
    harmonic,
    @mpf.fzero,
    [@mpf.fone, @mpf.fzero],
    ts,
    steps_per_interval=320,
  )
  assert_eq(ys.length(), ts.length())
  for i in 0..<ts.length() {
    let c = ctx.cos(ts[i])
    let s = ctx.sin(ts[i])
    assert_true(
      @mpf.mpf_lt(
        @mpf.mpf_abs(
          @mpf.mpf_sub(ys[i][0], c, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        @mpf.from_str("3e-5"),
      ),
    )
    assert_true(
      @mpf.mpf_lt(
        @mpf.mpf_abs(
          @mpf.mpf_sub(ys[i][1], s, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        @mpf.from_str("3e-5"),
      ),
    )
  }
}

///|
test "p3 ode dimension mismatch error subset" {
  let ctx = new(220, @mpf.round_nearest)
  let bad : Result[Array[@mpf.RawMpf], MPError] = try? ctx.ode_step_rk4(
    (_x : @mpf.RawMpf, _y : ArrayView[@mpf.RawMpf]) => [],
    @mpf.fzero,
    [@mpf.fone],
    ctx.make_float("0.01"),
  )
  match bad {
    Ok(_) => fail("expected ValueError for derivative dimension mismatch")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}
