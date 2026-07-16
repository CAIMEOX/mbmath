///|
fn assert_close(
  v : @mpf.RawMpf,
  expected : @mpf.RawMpf,
  tol : String,
) -> Unit raise {
  let err = v.sub(expected, 300, Nearest).abs(300, Nearest)
  assert_true(err < @mpf.RawMpf::parse(tol))
}

///|
test "elliptic agm identity m=0.25 from mpmath test_elliptic" {
  let m = @mpf.RawMpf::parse("0.25")
  let one_minus_m = @mpf.RawMpf::one().sub(m, 260, Nearest)
  let k = ellipk(m, 260, Nearest)
  let rhs = @libelefun.pi(260, Nearest).div(
    agm(@mpf.RawMpf::one(), one_minus_m.sqrt(260, Nearest), 260, Nearest).mul_int(
      2,
      260,
      Nearest,
    ),
    260,
    Nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "elliptic agm identity m=0.5 from mpmath test_elliptic" {
  let m = @mpf.RawMpf::parse("0.5")
  let one_minus_m = @mpf.RawMpf::one().sub(m, 260, Nearest)
  let k = ellipk(m, 260, Nearest)
  let rhs = @libelefun.pi(260, Nearest).div(
    agm(@mpf.RawMpf::one(), one_minus_m.sqrt(260, Nearest), 260, Nearest).mul_int(
      2,
      260,
      Nearest,
    ),
    260,
    Nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "elliptic agm identity m=0.75 from mpmath test_elliptic" {
  let m = @mpf.RawMpf::parse("0.75")
  let one_minus_m = @mpf.RawMpf::one().sub(m, 260, Nearest)
  let k = ellipk(m, 260, Nearest)
  let rhs = @libelefun.pi(260, Nearest).div(
    agm(@mpf.RawMpf::one(), one_minus_m.sqrt(260, Nearest), 260, Nearest).mul_int(
      2,
      260,
      Nearest,
    ),
    260,
    Nearest,
  )
  assert_close(k, rhs, "1e-20")
}

///|
test "elliptic legendre relation subset from mpmath test_elliptic" {
  let m = @mpf.RawMpf::parse("0.2")
  let mp = @mpf.RawMpf::one().sub(m, 260, Nearest)
  let km = ellipk(m, 260, Nearest)
  let em = ellipe(m, 260, Nearest)
  let kmp = ellipk(mp, 260, Nearest)
  let emp = ellipe(mp, 260, Nearest)
  let lhs = km
    .mul(emp, 260, Nearest)
    .add(em.mul(kmp, 260, Nearest), 260, Nearest)
    .sub(km.mul(kmp, 260, Nearest), 260, Nearest)
  let rhs = @libelefun.pi(260, Nearest).div(
    @mpf.RawMpf::from_int(2),
    260,
    Nearest,
  )
  assert_close(lhs, rhs, "1e-14")
}

///|
test "elliptic near-one growth from mpmath test_elliptic" {
  let k = ellipk(@mpf.RawMpf::parse("0.9999"), 220, Nearest)
  assert_true(k > @mpf.RawMpf::parse("5.0"))
  assert_true(k < @mpf.RawMpf::parse("6.5"))
}

///|
test "elliptic E monotone subset from mpmath test_elliptic" {
  let e02 = ellipe(@mpf.RawMpf::parse("0.2"), 220, Nearest)
  let e08 = ellipe(@mpf.RawMpf::parse("0.8"), 220, Nearest)
  assert_true(e02 > e08)
  assert_true(e08 > @mpf.RawMpf::one())
}

///|
test "elliptic complex-real consistency subset from mpmath test_elliptic" {
  let z = @mpc.RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero())
  let k_real = ellipk(@mpf.RawMpf::parse("0.25"), 220, Nearest)
  let e_real = ellipe(@mpf.RawMpf::parse("0.25"), 220, Nearest)
  let k_complex = z.ellipk(220, Nearest)
  let e_complex = z.ellipe(220, Nearest)
  assert_close(k_complex.real, k_real, "1e-20")
  assert_close(e_complex.real, e_real, "1e-20")
  assert_true(k_complex.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-20"))
  assert_true(e_complex.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-20"))
}

///|
test "elliptic complex finite subset from mpmath test_elliptic" {
  let z = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("0.25"),
    @mpf.RawMpf::parse("0.1"),
  )
  let k = z.ellipk(180, Nearest)
  let e = z.ellipe(180, Nearest)
  assert_true(k.real.is_finite())
  assert_true(k.imag.is_finite())
  assert_true(e.real.is_finite())
  assert_true(e.imag.is_finite())
}
