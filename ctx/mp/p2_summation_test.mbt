///|
test "p2 summation fsum subset from mpmath test_summation" {
  let ctx = new(220, @mpf.round_nearest)
  assert_eq(ctx.fsum([]), @mpf.fzero)
  assert_eq(ctx.fsum([ctx.make_int(-4)]), ctx.make_int(-4))
  assert_eq(ctx.fsum([ctx.make_int(2), ctx.make_int(3)]), ctx.make_int(5))
  assert_close_mpf_str(
    ctx.fsum([@mpf.from_str("1e-100"), @mpf.fone]),
    "1",
    "1e-8",
  )
  assert_close_mpf_str(
    ctx.fsum([@mpf.fone, @mpf.from_str("1e100")]),
    "1e100",
    "1e95",
  )
  assert_eq(
    ctx.fsum([ctx.make_int(2), ctx.make_int(-1)], absolute=true),
    ctx.make_int(3),
  )
  assert_eq(
    ctx.fsum([ctx.make_int(2), ctx.make_int(-1)], squared=true),
    ctx.make_int(5),
  )
  let nan_sum = ctx.fsum([@mpf.finf, @mpf.fninf])
  assert_true(@mpf.is_nan(nan_sum))
  let abs_inf = ctx.fsum([@mpf.finf, @mpf.fninf], absolute=true)
  assert_true(@mpf.is_inf(abs_inf))
  assert_eq(abs_inf.sign, 0)
}

///|
test "p2 summation fprod subset from mpmath test_summation" {
  let ctx = new(220, @mpf.round_nearest)
  assert_eq(ctx.fprod([]), @mpf.fone)
  assert_eq(ctx.fprod([ctx.make_int(2), ctx.make_int(3)]), ctx.make_int(6))
}
