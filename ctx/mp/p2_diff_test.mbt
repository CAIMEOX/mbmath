///|
test "p2 diff subset from mpmath test_diff" {
  let ctx = new(260, @mpf.round_nearest)
  let d0 = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.make_int(2), n=0)
  assert_close_mpf_str(
    @mpf.mpf_sub(d0, ctx.cos(ctx.make_int(2)), 260, @mpf.round_nearest),
    "0",
    "1e-30",
  )
  let dcos = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.make_int(1))
  let neg_sin = ctx.neg(ctx.sin(ctx.make_int(1)))
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(dcos, neg_sin, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("2e-8"),
    ),
  )
  let dabs0 = ctx.diff((x : @mpf.RawMpf) => ctx.abs(x), @mpf.fzero)
  assert_eq(dabs0, @mpf.fzero)
  let dabs_pos = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.fzero,
    direction=1,
  )
  let dabs_neg = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.fzero,
    direction=-1,
  )
  assert_close_mpf_str(dabs_pos, "1", "1e-8")
  assert_close_mpf_str(dabs_neg, "-1", "1e-8")
  let dexp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.make_int(1))
  assert_close_mpf_str(dexp, "2.718281828459045235360287", "1e-8")
  let d2poly = ctx.diff(
    (x : @mpf.RawMpf) => {
      let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
      let x4 = @mpf.mpf_mul(x2, x2, 260, @mpf.round_nearest)
      let x5 = @mpf.mpf_mul(x4, x, 260, @mpf.round_nearest)
      @mpf.mpf_add(@mpf.from_int(3), x5, 260, @mpf.round_nearest)
    },
    ctx.make_int(3),
    n=2,
  )
  assert_close_mpf_str(d2poly, "540", "2e-4")

  let d5exp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.make_int(1), n=5)
  assert_close_mpf_str(d5exp, "2.718281828459045235360287", "2e-5")

  let d5sin0 = ctx.diff((x : @mpf.RawMpf) => ctx.sin(x), @mpf.fzero, n=5)
  assert_close_mpf_str(d5sin0, "1", "5e-6")

  let bad : Result[@mpf.RawMpf, MPError] = try? ctx.diff(
    (x : @mpf.RawMpf) => x,
    ctx.make_int(2),
    n=3,
    direction=1,
  )
  match bad {
    Ok(_) => fail("expected ValueError for direction with n>1")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}
