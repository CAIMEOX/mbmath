///|
test "summation fsum subset from mpmath test_summation" {
  let ctx = MPContext::new(220, Nearest)
  @debug.assert_eq(ctx.fsum([]), @mpf.RawMpf::zero())
  @debug.assert_eq(ctx.fsum([ctx.from_int(-4)]), ctx.from_int(-4))
  @debug.assert_eq(
    ctx.fsum([ctx.from_int(2), ctx.from_int(3)]),
    ctx.from_int(5),
  )
  assert_close_mpf_str(
    ctx.fsum([@mpf.RawMpf::parse("1e-100"), @mpf.RawMpf::one()]),
    "1",
    "1e-8",
  )
  assert_close_mpf_str(
    ctx.fsum([@mpf.RawMpf::one(), @mpf.RawMpf::parse("1e100")]),
    "1e100",
    "1e95",
  )
  @debug.assert_eq(
    ctx.fsum([ctx.from_int(2), ctx.from_int(-1)], absolute=true),
    ctx.from_int(3),
  )
  @debug.assert_eq(
    ctx.fsum([ctx.from_int(2), ctx.from_int(-1)], squared=true),
    ctx.from_int(5),
  )
  let nan_sum = ctx.fsum([
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::negative_infinity(),
  ])
  assert_true(nan_sum.is_nan())
  let abs_inf = ctx.fsum(
    [@mpf.RawMpf::infinity(), @mpf.RawMpf::negative_infinity()],
    absolute=true,
  )
  assert_true(abs_inf.is_infinite())
  @debug.assert_eq(abs_inf.sign, 0)
}

///|
test "summation fprod subset from mpmath test_summation" {
  let ctx = MPContext::new(220, Nearest)
  @debug.assert_eq(ctx.fprod([]), @mpf.RawMpf::one())
  @debug.assert_eq(
    ctx.fprod([ctx.from_int(2), ctx.from_int(3)]),
    ctx.from_int(6),
  )
}

///|
test "summation/nsum finite subset from mpmath test_summation" {
  let ctx = MPContext::new(260, Nearest)
  let sum_sq = ctx.summation((k : Int) => @mpf.RawMpf::from_int(k * k), 1, 3)
  @debug.assert_eq(sum_sq, @mpf.RawMpf::from_int(14))
  let sum_odd = ctx.summation(
    (k : Int) => @mpf.RawMpf::from_int(k),
    1,
    5,
    step=2,
  )
  @debug.assert_eq(sum_odd, @mpf.RawMpf::from_int(9))
  let nsum_finite = ctx.nsum(
    (k : Int) => @mpf.RawMpf::from_int(k * k),
    1,
    stop=3,
  )
  @debug.assert_eq(nsum_finite, @mpf.RawMpf::from_int(14))
}

///|
test "nsum infinite methods subset from mpmath test_summation" {
  let ctx = MPContext::new(260, Nearest)
  let p = 260
  let pi = @libelefun.pi(p, Nearest)
  let pi2 = pi.mul(pi, p, Nearest)
  let pi2_over_6 = pi2.div(@mpf.RawMpf::from_int(6), p, Nearest)
  let zeta2 = ctx.nsum(
    (k : Int) => {
      let kk = @mpf.RawMpf::from_int(k)
      let k2 = kk.mul(kk, p, Nearest)
      @mpf.RawMpf::one().div(k2, p, Nearest)
    },
    1,
    algo="r",
    tol=@mpf.RawMpf::parse("2e-6"),
    max_terms=500,
  )
  assert_close_mpf_str(zeta2.sub(pi2_over_6, p, Nearest), "0", "2e-5")
  let alt_harm = ctx.nsum(
    (k : Int) => {
      let sign = if (k & 1) == 1 {
        @mpf.RawMpf::one()
      } else {
        @mpf.RawMpf::negative_one()
      }
      sign.div(@mpf.RawMpf::from_int(k), p, Nearest)
    },
    1,
    algo="levin",
    tol=@mpf.RawMpf::parse("1e-8"),
    max_terms=120,
  )
  let ln2 = @libelefun.ln2(p, Nearest)
  assert_close_mpf_str(alt_harm.sub(ln2, p, Nearest), "0", "1e-8")
}

///|
test "nprod subset from mpmath test_summation" {
  let ctx = MPContext::new(260, Nearest)
  let p = 260
  let finite_prod = ctx.nprod(
    (k : Int) => @mpf.RawMpf::from_int(k * k),
    1,
    stop=3,
  )
  @debug.assert_eq(finite_prod, @mpf.RawMpf::from_int(36))

  let pi = @libelefun.pi(p, Nearest)
  let pi2 = pi.mul(pi, p, Nearest)
  let pi2_over_6 = pi2.div(@mpf.RawMpf::from_int(6), p, Nearest)
  let prod_inf = ctx.nprod(
    (k : Int) => {
      let kk = @mpf.RawMpf::from_int(k)
      let k2 = kk.mul(kk, p, Nearest)
      let inv = @mpf.RawMpf::one().div(k2, p, Nearest)
      @libelefun.exp(inv, p, Nearest)
    },
    1,
    algo="r",
    tol=@mpf.RawMpf::parse("2e-6"),
    max_terms=500,
  )
  let expected = @libelefun.exp(pi2_over_6, p, Nearest)
  assert_close_mpf_str(prod_inf.sub(expected, p, Nearest), "0", "4e-5")

  try
    ctx.nsum((k : Int) => @mpf.RawMpf::from_int(k), 1, algo="bad", max_terms=12)
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for unknown nsum method")
  }

  try
    ctx.nprod(
      (k : Int) => {
        ignore(k)
        @mpf.RawMpf::negative_one()
      },
      1,
      max_terms=10,
    )
  catch {
    MPError::DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected DomainError for non-positive infinite term")
  }
}
