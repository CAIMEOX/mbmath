///|
test "ode rk4 rational and harmonic subset from mpmath test_ode" {
  let ctx = MPContext::new(260, Nearest)
  let p = 300

  let rational = (x : @mpf.RawMpf, y : ArrayView[@mpf.RawMpf]) => {
    let y2 = y[0].mul(y[0], p, Nearest)
    let two_x = x.mul_int(2, p, Nearest)
    [two_x.mul(y2, p, Nearest).negated(p, Nearest)]
  }
  let y2 = ctx.ode_solve(
    rational,
    @mpf.RawMpf::zero(),
    [@mpf.RawMpf::one()],
    ctx.from_int(2),
    steps=600,
  )
  assert_close_mpf_str(y2[0], "0.2", "2e-5")

  let harmonic = (x : @mpf.RawMpf, y : ArrayView[@mpf.RawMpf]) => {
    ignore(x)
    [y[1].negated(p, Nearest), y[0]]
  }
  let ts : Array[@mpf.RawMpf] = [
    @mpf.RawMpf::zero(),
    ctx.from_int(1),
    ctx.parse("2.5"),
    ctx.parse("3.7"),
    ctx.from_int(8),
  ]
  let ys = ctx.ode_solve_grid(
    harmonic,
    @mpf.RawMpf::zero(),
    [@mpf.RawMpf::one(), @mpf.RawMpf::zero()],
    ts,
    steps_per_interval=320,
  )
  @debug.assert_eq(ys.length(), ts.length())
  for i in 0..<ts.length() {
    let c = ctx.cos(ts[i])
    let s = ctx.sin(ts[i])
    assert_true(
      ys[i][0].sub(c, p, Nearest).abs(p, Nearest) < @mpf.RawMpf::parse("3e-5"),
    )
    assert_true(
      ys[i][1].sub(s, p, Nearest).abs(p, Nearest) < @mpf.RawMpf::parse("3e-5"),
    )
  }
}

///|
test "ode dimension mismatch error subset" {
  let ctx = MPContext::new(220, Nearest)
  try
    ctx.ode_step_rk4(
      (_x : @mpf.RawMpf, _y : ArrayView[@mpf.RawMpf]) => [],
      @mpf.RawMpf::zero(),
      [@mpf.RawMpf::one()],
      ctx.parse("0.01"),
    )
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for derivative dimension mismatch")
  }
}
