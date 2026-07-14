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
  let expected = @mpf.from_str(expected_text, prec~, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, expected, prec, @mpf.round_nearest),
    prec,
    @mpf.round_nearest,
  )
  let digits = mantissa_digit_count(expected_text)
  let sig_digits = if digits <= 1 { 0 } else { digits - 1 }
  let rel_tol = if sig_digits == 0 {
    @mpf.fone
  } else {
    @mpf.from_str("1e-\{sig_digits}", prec~, rnd=@mpf.round_nearest)
  }
  let mut scale = @mpf.mpf_abs(expected, prec, @mpf.round_nearest)
  if @mpf.mpf_lt(scale, @mpf.fone) {
    scale = @mpf.fone
  }
  let tol = @mpf.mpf_mul(scale, rel_tol, prec, @mpf.round_nearest)
  assert_true(@mpf.mpf_le(err, tol))
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let expected_v = @mpf.from_str(expected, prec=280, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, expected_v, 280, @mpf.round_nearest),
    280,
    @mpf.round_nearest,
  )
  let tol_v = @mpf.from_str(tol, prec=280, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_lt(err, tol_v))
}

///|
test "extra_gamma gamma real subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    mpf_gamma(@mpf.from_int(1), 180, @mpf.round_nearest),
    "1",
    8,
  )
  assert_gamma_zeta_close(
    mpf_gamma(@mpf.from_str("1.5"), 200, @mpf.round_nearest),
    "0.886226925452758",
    16,
  )
  assert_gamma_zeta_close(
    mpf_gamma(@mpf.from_str("-0.5"), 200, @mpf.round_nearest),
    "-3.544907701811032",
    16,
  )
  assert_gamma_zeta_close(
    mpf_gamma(@mpf.from_str("-7.1"), 220, @mpf.round_nearest),
    "0.001647824457026",
    16,
  )
  assert_gamma_zeta_close(
    mpf_gamma(@mpf.from_str("12.3"), 220, @mpf.round_nearest),
    "83385367.89997",
    14,
  )
}

///|
test "extra_gamma pole neighborhood subset from mpmath test_extra_gamma" {
  let left = mpf_gamma(@mpf.from_str("-1e-20"), 260, @mpf.round_nearest)
  let right = mpf_gamma(@mpf.from_str("1e-20"), 260, @mpf.round_nearest)
  assert_true(@mpf.mpf_lt(left, @mpf.from_str("-1e18")))
  assert_true(@mpf.mpf_gt(right, @mpf.from_str("1e18")))
}

///|
test "extra_gamma pole error subset from mpmath test_extra_gamma" {
  try mpf_gamma(@mpf.fzero, 160, @mpf.round_nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected pole error at gamma(0)")
  }
}

///|
test "extra_gamma loggamma positive subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    mpf_loggamma(@mpf.from_int(3), 200, @mpf.round_nearest),
    "0.693147180559945",
    16,
  )
  assert_gamma_zeta_close(
    mpf_loggamma(@mpf.from_str("7.25"), 220, @mpf.round_nearest),
    "7.05218545073854",
    15,
  )
}

///|
test "extra_gamma rgamma infinity subset from mpmath issue_510" {
  assert_eq(mpf_rgamma(@mpf.finf, 160, @mpf.round_nearest), @mpf.fzero)
  assert_eq(mpf_rgamma(@mpf.from_int(1), 160, @mpf.round_nearest), @mpf.fone)
}

///|
test "extra_gamma psi harmonic subset from mpmath test_fp" {
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
test "extra_zeta real subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_int(3), 220, @mpf.round_nearest),
    "1.202056903159594",
    16,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_str("0.93"), 260, @mpf.round_nearest),
    "-13.713619351638",
    15,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_str("1.74"), 220, @mpf.round_nearest),
    "1.979686354577177",
    16,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_int(0), 220, @mpf.round_nearest),
    "-0.5",
    8,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_int(-1), 220, @mpf.round_nearest),
    "-0.083333333333333",
    16,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_int(-3), 220, @mpf.round_nearest),
    "0.008333333333333",
    16,
  )
}

///|
test "extra_zeta altzeta subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    mpf_altzeta(@mpf.from_int(1), 220, @mpf.round_nearest),
    "0.693147180559945",
    16,
  )
  assert_gamma_zeta_close(
    mpf_altzeta(@mpf.from_int(2), 220, @mpf.round_nearest),
    "0.822467033424113",
    16,
  )
  assert_gamma_zeta_close(
    mpf_altzeta(@mpf.from_int(0), 220, @mpf.round_nearest),
    "0.5",
    8,
  )
}

///|
test "extra_zeta near-pole subset from mpmath test_fp" {
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_str("1.0000000001"), 300, @mpf.round_nearest),
    "9999999173.17357",
    17,
  )
  assert_gamma_zeta_close(
    mpf_zeta(@mpf.from_str("0.9999999999"), 300, @mpf.round_nearest),
    "-9999999172.01914",
    17,
  )
}

///|
test "extra_zeta pole error subset" {
  try mpf_zeta(@mpf.fone, 180, @mpf.round_nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected pole error at zeta(1)")
  }
}

///|
test "extra_zeta zetasum consistency subset" {
  let z = mpf_zeta(@mpf.from_int(2), 220, @mpf.round_nearest)
  let zs = mpf_zetasum(@mpf.from_int(2), 220, @mpf.round_nearest, terms=4000)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(z, zs, 220, @mpf.round_nearest),
    220,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("3e-4")))
}
