///|
fn assert_prefix(x : @mpf.RawMpf, prefix : String, dps : Int) -> Unit raise {
  assert_true(@mpf.to_str_opts(x, dps~).has_prefix(prefix))
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, @mpf.from_str(expected), 280, @mpf.round_nearest),
    280,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
test "p1 extra_gamma gamma real subset from mpmath test_fp" {
  assert_prefix(mpf_gamma(@mpf.from_int(1), 180, @mpf.round_nearest), "1", 8)
  assert_prefix(
    mpf_gamma(@mpf.from_str("1.5"), 200, @mpf.round_nearest),
    "0.886226925452758",
    16,
  )
  assert_prefix(
    mpf_gamma(@mpf.from_str("-0.5"), 200, @mpf.round_nearest),
    "-3.544907701811032",
    16,
  )
  assert_prefix(
    mpf_gamma(@mpf.from_str("-7.1"), 220, @mpf.round_nearest),
    "0.001647824457026",
    16,
  )
  assert_prefix(
    mpf_gamma(@mpf.from_str("12.3"), 220, @mpf.round_nearest),
    "83385367.89997",
    14,
  )
}

///|
test "p1 extra_gamma pole neighborhood subset from mpmath test_extra_gamma" {
  let left = mpf_gamma(@mpf.from_str("-1e-20"), 260, @mpf.round_nearest)
  let right = mpf_gamma(@mpf.from_str("1e-20"), 260, @mpf.round_nearest)
  assert_true(@mpf.mpf_lt(left, @mpf.from_str("-1e18")))
  assert_true(@mpf.mpf_gt(right, @mpf.from_str("1e18")))
}

///|
test "p1 extra_gamma pole error subset from mpmath test_extra_gamma" {
  let at_zero : Result[@mpf.RawMpf, GammaZetaError] = try? mpf_gamma(
    @mpf.fzero, 160, @mpf.round_nearest,
  )
  match at_zero {
    Ok(_) => fail("expected pole error at gamma(0)")
    Err(GammaZetaError::PoleError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}

///|
test "p1 extra_gamma loggamma positive subset from mpmath test_fp" {
  assert_prefix(
    mpf_loggamma(@mpf.from_int(3), 200, @mpf.round_nearest),
    "0.693147180559945",
    16,
  )
  assert_prefix(
    mpf_loggamma(@mpf.from_str("7.25"), 220, @mpf.round_nearest),
    "7.05218545073854",
    15,
  )
}

///|
test "p1 extra_gamma rgamma infinity subset from mpmath issue_510" {
  assert_eq(mpf_rgamma(@mpf.finf, 160, @mpf.round_nearest), @mpf.fzero)
  assert_eq(mpf_rgamma(@mpf.from_int(1), 160, @mpf.round_nearest), @mpf.fone)
}

///|
test "p1 extra_gamma psi harmonic subset from mpmath test_fp" {
  assert_close_to_str(
    mpf_psi0(@mpf.from_str("3.7"), 220, @mpf.round_nearest),
    "1.1671535393615114409",
    "2e-7",
  )
  assert_close_to_str(
    mpf_psi0(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    "-1.9635100260214234794",
    "2e-7",
  )
  assert_close_to_str(
    mpf_harmonic(@mpf.from_int(100), 220, @mpf.round_nearest),
    "5.1873775176396202608",
    "2e-7",
  )
  assert_close_to_str(
    mpf_harmonic(@mpf.from_str("-2.5"), 220, @mpf.round_nearest),
    "1.2803723055467760478",
    "2e-7",
  )
}

///|
test "p1 extra_zeta real subset from mpmath test_fp" {
  assert_prefix(
    mpf_zeta(@mpf.from_int(3), 220, @mpf.round_nearest),
    "1.202056903159594",
    16,
  )
  assert_prefix(
    mpf_zeta(@mpf.from_str("0.93"), 260, @mpf.round_nearest),
    "-13.713619351638",
    15,
  )
  assert_prefix(
    mpf_zeta(@mpf.from_str("1.74"), 220, @mpf.round_nearest),
    "1.979686354577177",
    16,
  )
  assert_prefix(mpf_zeta(@mpf.from_int(0), 220, @mpf.round_nearest), "-0.5", 8)
  assert_prefix(
    mpf_zeta(@mpf.from_int(-1), 220, @mpf.round_nearest),
    "-0.083333333333333",
    16,
  )
  assert_prefix(
    mpf_zeta(@mpf.from_int(-3), 220, @mpf.round_nearest),
    "0.008333333333333",
    16,
  )
}

///|
test "p1 extra_zeta altzeta subset from mpmath test_fp" {
  assert_prefix(
    mpf_altzeta(@mpf.from_int(1), 220, @mpf.round_nearest),
    "0.693147180559945",
    16,
  )
  assert_prefix(
    mpf_altzeta(@mpf.from_int(2), 220, @mpf.round_nearest),
    "0.822467033424113",
    16,
  )
  assert_prefix(
    mpf_altzeta(@mpf.from_int(0), 220, @mpf.round_nearest),
    "0.5",
    8,
  )
}

///|
test "p1 extra_zeta near-pole subset from mpmath test_fp" {
  assert_prefix(
    mpf_zeta(@mpf.from_str("1.0000000001"), 300, @mpf.round_nearest),
    "9999999173.17357",
    17,
  )
  assert_prefix(
    mpf_zeta(@mpf.from_str("0.9999999999"), 300, @mpf.round_nearest),
    "-9999999172.01914",
    17,
  )
}

///|
test "p1 extra_zeta pole error subset" {
  let at_one : Result[@mpf.RawMpf, GammaZetaError] = try? mpf_zeta(
    @mpf.fone, 180, @mpf.round_nearest,
  )
  match at_one {
    Ok(_) => fail("expected pole error at zeta(1)")
    Err(GammaZetaError::PoleError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}

///|
test "p1 extra_zeta zetasum consistency subset" {
  let z = mpf_zeta(@mpf.from_int(2), 220, @mpf.round_nearest)
  let zs = mpf_zetasum(@mpf.from_int(2), 220, @mpf.round_nearest, terms=4000)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(z, zs, 220, @mpf.round_nearest),
    220,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("3e-4")))
}
