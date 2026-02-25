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

///|
test "p2 summation/nsum finite subset from mpmath test_summation" {
  let ctx = new(260, @mpf.round_nearest)
  let sum_sq = ctx.summation((k : Int) => @mpf.from_int(k * k), 1, 3)
  assert_eq(sum_sq, @mpf.from_int(14))
  let sum_odd = ctx.summation((k : Int) => @mpf.from_int(k), 1, 5, step=2)
  assert_eq(sum_odd, @mpf.from_int(9))
  let nsum_finite = ctx.nsum((k : Int) => @mpf.from_int(k * k), 1, stop=3)
  assert_eq(nsum_finite, @mpf.from_int(14))
}

///|
test "p2 nsum infinite methods subset from mpmath test_summation" {
  let ctx = new(260, @mpf.round_nearest)
  let p = 260
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let pi2 = @mpf.mpf_mul(pi, pi, p, @mpf.round_nearest)
  let pi2_over_6 = @mpf.mpf_div(pi2, @mpf.from_int(6), p, @mpf.round_nearest) catch {
    _ => @mpf.fnan
  }
  let zeta2 = ctx.nsum(
    (k : Int) => {
      let kk = @mpf.from_int(k)
      let k2 = @mpf.mpf_mul(kk, kk, p, @mpf.round_nearest)
      @mpf.mpf_div(@mpf.fone, k2, p, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    1,
    algo="r",
    tol=@mpf.from_str("2e-6"),
    max_terms=500,
  )
  assert_close_mpf_str(
    @mpf.mpf_sub(zeta2, pi2_over_6, p, @mpf.round_nearest),
    "0",
    "2e-5",
  )
  let alt_harm = ctx.nsum(
    (k : Int) => {
      let sign = if (k & 1) == 1 { @mpf.fone } else { @mpf.fnone }
      @mpf.mpf_div(sign, @mpf.from_int(k), p, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    1,
    algo="levin",
    tol=@mpf.from_str("1e-8"),
    max_terms=120,
  )
  let ln2 = @libelefun.mpf_ln2(p, @mpf.round_nearest)
  assert_close_mpf_str(
    @mpf.mpf_sub(alt_harm, ln2, p, @mpf.round_nearest),
    "0",
    "1e-8",
  )
}

///|
test "p2 nprod subset from mpmath test_summation" {
  let ctx = new(260, @mpf.round_nearest)
  let p = 260
  let finite_prod = ctx.nprod((k : Int) => @mpf.from_int(k * k), 1, stop=3)
  assert_eq(finite_prod, @mpf.from_int(36))

  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let pi2 = @mpf.mpf_mul(pi, pi, p, @mpf.round_nearest)
  let pi2_over_6 = @mpf.mpf_div(pi2, @mpf.from_int(6), p, @mpf.round_nearest) catch {
    _ => @mpf.fnan
  }
  let prod_inf = ctx.nprod(
    (k : Int) => {
      let kk = @mpf.from_int(k)
      let k2 = @mpf.mpf_mul(kk, kk, p, @mpf.round_nearest)
      let inv = @mpf.mpf_div(@mpf.fone, k2, p, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
      @libelefun.mpf_exp(inv, p, @mpf.round_nearest)
    },
    1,
    algo="r",
    tol=@mpf.from_str("2e-6"),
    max_terms=500,
  )
  let expected = @libelefun.mpf_exp(pi2_over_6, p, @mpf.round_nearest)
  assert_close_mpf_str(
    @mpf.mpf_sub(prod_inf, expected, p, @mpf.round_nearest),
    "0",
    "4e-5",
  )

  let bad_method : Result[@mpf.RawMpf, MPError] = try? ctx.nsum(
    (k : Int) => @mpf.from_int(k),
    1,
    algo="bad",
    max_terms=12,
  )
  match bad_method {
    Ok(_) => fail("expected ValueError for unknown nsum method")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let bad_domain : Result[@mpf.RawMpf, MPError] = try? ctx.nprod(
    (k : Int) => {
      ignore(k)
      @mpf.fnone
    },
    1,
    max_terms=10,
  )
  match bad_domain {
    Ok(_) => fail("expected DomainError for non-positive infinite term")
    Err(MPError::DomainError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}
