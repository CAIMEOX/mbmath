///|
fn assert_close(
  v : @mpf.RawMpf,
  expected : @mpf.RawMpf,
  tol : String,
) -> Unit raise {
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(v, expected, 300, @mpf.round_nearest),
    300,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
test "p1 elliptic agm identity m=0.25 from mpmath test_elliptic" {
  let m = @mpf.from_str("0.25")
  let one_minus_m = @mpf.mpf_sub(@mpf.fone, m, 260, @mpf.round_nearest)
  let k = mpf_ellipk(m, 260, @mpf.round_nearest)
  let rhs = @mpf.mpf_div(
    @libelefun.mpf_pi(260, @mpf.round_nearest),
    @mpf.mpf_mul_int(
      mpf_agm(
        @mpf.fone,
        @mpf.mpf_sqrt(one_minus_m, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      2,
      260,
      @mpf.round_nearest,
    ),
    260,
    @mpf.round_nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "p1 elliptic agm identity m=0.5 from mpmath test_elliptic" {
  let m = @mpf.from_str("0.5")
  let one_minus_m = @mpf.mpf_sub(@mpf.fone, m, 260, @mpf.round_nearest)
  let k = mpf_ellipk(m, 260, @mpf.round_nearest)
  let rhs = @mpf.mpf_div(
    @libelefun.mpf_pi(260, @mpf.round_nearest),
    @mpf.mpf_mul_int(
      mpf_agm(
        @mpf.fone,
        @mpf.mpf_sqrt(one_minus_m, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      2,
      260,
      @mpf.round_nearest,
    ),
    260,
    @mpf.round_nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "p1 elliptic agm identity m=0.75 from mpmath test_elliptic" {
  let m = @mpf.from_str("0.75")
  let one_minus_m = @mpf.mpf_sub(@mpf.fone, m, 260, @mpf.round_nearest)
  let k = mpf_ellipk(m, 260, @mpf.round_nearest)
  let rhs = @mpf.mpf_div(
    @libelefun.mpf_pi(260, @mpf.round_nearest),
    @mpf.mpf_mul_int(
      mpf_agm(
        @mpf.fone,
        @mpf.mpf_sqrt(one_minus_m, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      2,
      260,
      @mpf.round_nearest,
    ),
    260,
    @mpf.round_nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "p1 elliptic legendre relation subset from mpmath test_elliptic" {
  let m = @mpf.from_str("0.2")
  let mp = @mpf.mpf_sub(@mpf.fone, m, 260, @mpf.round_nearest)
  let km = mpf_ellipk(m, 260, @mpf.round_nearest)
  let em = mpf_ellipe(m, 260, @mpf.round_nearest)
  let kmp = mpf_ellipk(mp, 260, @mpf.round_nearest)
  let emp = mpf_ellipe(mp, 260, @mpf.round_nearest)
  let lhs = @mpf.mpf_sub(
    @mpf.mpf_add(
      @mpf.mpf_mul(km, emp, 260, @mpf.round_nearest),
      @mpf.mpf_mul(em, kmp, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    ),
    @mpf.mpf_mul(km, kmp, 260, @mpf.round_nearest),
    260,
    @mpf.round_nearest,
  )
  let rhs = @mpf.mpf_div(
    @libelefun.mpf_pi(260, @mpf.round_nearest),
    @mpf.from_int(2),
    260,
    @mpf.round_nearest,
  )
  assert_close(lhs, rhs, "1e-14")
}

///|
test "p1 elliptic near-one growth from mpmath test_elliptic" {
  let k = mpf_ellipk(@mpf.from_str("0.9999"), 220, @mpf.round_nearest)
  assert_true(@mpf.mpf_gt(k, @mpf.from_str("5.0")))
  assert_true(@mpf.mpf_lt(k, @mpf.from_str("6.5")))
}

///|
test "p1 elliptic E monotone subset from mpmath test_elliptic" {
  let e02 = mpf_ellipe(@mpf.from_str("0.2"), 220, @mpf.round_nearest)
  let e08 = mpf_ellipe(@mpf.from_str("0.8"), 220, @mpf.round_nearest)
  assert_true(@mpf.mpf_gt(e02, e08))
  assert_true(@mpf.mpf_gt(e08, @mpf.fone))
}

///|
test "p1 elliptic complex-real consistency subset from mpmath test_elliptic" {
  let z = @mpc.from_parts(@mpf.from_str("0.25"), @mpf.fzero)
  let k_real = mpf_ellipk(@mpf.from_str("0.25"), 220, @mpf.round_nearest)
  let e_real = mpf_ellipe(@mpf.from_str("0.25"), 220, @mpf.round_nearest)
  let k_complex = @mpc.mpc_ellipk(z, 220, @mpf.round_nearest)
  let e_complex = @mpc.mpc_ellipe(z, 220, @mpf.round_nearest)
  assert_close(k_complex.real, k_real, "1e-20")
  assert_close(e_complex.real, e_real, "1e-20")
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(k_complex.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-20"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(e_complex.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-20"),
    ),
  )
}

///|
test "p1 elliptic complex finite subset from mpmath test_elliptic" {
  let z = @mpc.from_parts(@mpf.from_str("0.25"), @mpf.from_str("0.1"))
  let k = @mpc.mpc_ellipk(z, 180, @mpf.round_nearest)
  let e = @mpc.mpc_ellipe(z, 180, @mpf.round_nearest)
  assert_true(@mpf.is_finite(k.real))
  assert_true(@mpf.is_finite(k.imag))
  assert_true(@mpf.is_finite(e.real))
  assert_true(@mpf.is_finite(e.imag))
}
