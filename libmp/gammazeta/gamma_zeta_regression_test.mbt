///|
fn dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn mantissa_digit_count(expected_text : String) -> Int {
  let mut digits = 0
  for c in expected_text {
    if c == 'e' || c == 'E' {
      break
    }
    if c >= '0' && c <= '9' {
      digits += 1
    }
  }
  digits
}

///|
fn assert_gamma_zeta_close(
  x : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = dps_to_prec(dps)
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = x.sub(expected, prec, Nearest).abs(prec, Nearest)
  let digits = mantissa_digit_count(expected_text)
  let sig_digits = if digits <= 1 { 0 } else { digits - 1 }
  let rel_tol = if sig_digits == 0 {
    @mpf.RawMpf::one()
  } else {
    @mpf.RawMpf::parse("1e-\{sig_digits}", prec~, rnd=Nearest)
  }
  let mut scale = expected.abs(prec, Nearest)
  if scale < @mpf.RawMpf::one() {
    scale = @mpf.RawMpf::one()
  }
  let tol = scale.mul(rel_tol, prec, Nearest)
  assert_true(err <= tol)
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let expected_v = @mpf.RawMpf::parse(expected, prec=280, rnd=Nearest)
  let err = x.sub(expected_v, 280, Nearest).abs(280, Nearest)
  let tol_v = @mpf.RawMpf::parse(tol, prec=280, rnd=Nearest)
  assert_true(err < tol_v)
}

///|
test "extra_gamma gamma real subset from mpmath test_fp" {
  assert_gamma_zeta_close(gamma(@mpf.RawMpf::from_int(1), 180, Nearest), "1", 8)
  assert_gamma_zeta_close(
    gamma(@mpf.RawMpf::parse("1.5"), 200, Nearest),
    "0.886226925452758",
    16,
  )
  assert_gamma_zeta_close(
    gamma(@mpf.RawMpf::parse("-0.5"), 200, Nearest),
    "-3.544907701811032",
    16,
  )
  assert_gamma_zeta_close(
    gamma(@mpf.RawMpf::parse("-7.1"), 220, Nearest),
    "0.001647824457026",
    16,
  )
  assert_gamma_zeta_close(
    gamma(@mpf.RawMpf::parse("12.3"), 220, Nearest),
    "83385367.89997",
    14,
  )
}

///|
test "extra_gamma pole neighborhood subset from mpmath test_extra_gamma" {
  let left = gamma(@mpf.RawMpf::parse("-1e-20"), 260, Nearest)
  let right = gamma(@mpf.RawMpf::parse("1e-20"), 260, Nearest)
  assert_true(left < @mpf.RawMpf::parse("-1e18"))
  assert_true(right > @mpf.RawMpf::parse("1e18"))
}

///|
test "extra_gamma pole error subset from mpmath test_extra_gamma" {
  try gamma(@mpf.RawMpf::zero(), 160, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected pole error at gamma(0)")
  }
}

///|
test "extra_gamma loggamma positive subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    loggamma(@mpf.RawMpf::from_int(3), 200, Nearest),
    "0.693147180559945",
    16,
  )
  assert_gamma_zeta_close(
    loggamma(@mpf.RawMpf::parse("7.25"), 220, Nearest),
    "7.05218545073854",
    15,
  )
}

///|
test "extra_gamma rgamma infinity subset from mpmath issue_510" {
  @debug.assert_eq(
    rgamma(@mpf.RawMpf::infinity(), 160, Nearest),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    rgamma(@mpf.RawMpf::from_int(1), 160, Nearest),
    @mpf.RawMpf::one(),
  )
}

///|
test "extra_gamma psi harmonic subset from mpmath test_fp" {
  assert_close_to_str(
    digamma(@mpf.RawMpf::parse("3.7"), 220, Nearest),
    "1.1671535393615114409",
    "2e-7",
  )
  assert_close_to_str(
    digamma(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    "-1.9635100260214234794",
    "2e-7",
  )
  assert_close_to_str(
    harmonic(@mpf.RawMpf::from_int(100), 220, Nearest),
    "5.1873775176396202608",
    "2e-7",
  )
  assert_close_to_str(
    harmonic(@mpf.RawMpf::parse("-2.5"), 220, Nearest),
    "1.2803723055467760478",
    "2e-7",
  )
}

///|
test "extra_zeta real subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::from_int(3), 220, Nearest),
    "1.202056903159594",
    16,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::parse("0.93"), 260, Nearest),
    "-13.713619351638",
    15,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::parse("1.74"), 220, Nearest),
    "1.979686354577177",
    16,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::from_int(0), 220, Nearest),
    "-0.5",
    8,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::from_int(-1), 220, Nearest),
    "-0.083333333333333",
    16,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::from_int(-3), 220, Nearest),
    "0.008333333333333",
    16,
  )
}

///|
test "extra_zeta altzeta subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    eta(@mpf.RawMpf::from_int(1), 220, Nearest),
    "0.693147180559945",
    16,
  )
  assert_gamma_zeta_close(
    eta(@mpf.RawMpf::from_int(2), 220, Nearest),
    "0.822467033424113",
    16,
  )
  assert_gamma_zeta_close(eta(@mpf.RawMpf::from_int(0), 220, Nearest), "0.5", 8)
}

///|
test "extra_zeta near-pole subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::parse("1.0000000001"), 300, Nearest),
    "9999999173.17357",
    17,
  )
  assert_gamma_zeta_close(
    zeta(@mpf.RawMpf::parse("0.9999999999"), 300, Nearest),
    "-9999999172.01914",
    17,
  )
}

///|
test "extra_zeta pole error subset" {
  try zeta(@mpf.RawMpf::one(), 180, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected pole error at zeta(1)")
  }
}

///|
test "extra_zeta zetasum consistency subset" {
  let z = zeta(@mpf.RawMpf::from_int(2), 220, Nearest)
  let zs = zeta_sum(@mpf.RawMpf::from_int(2), 220, Nearest, terms=4000)
  let err = z.sub(zs, 220, Nearest).abs(220, Nearest)
  assert_true(err < @mpf.RawMpf::parse("3e-4"))
}
