///|
fn gz_dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn gz_mantissa_digit_count(expected_text : String) -> Int {
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
fn assert_close_numeric(
  got : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = gz_dps_to_prec(dps)
  let expected = @mpf.from_str(expected_text, prec~, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(got, expected, prec, @mpf.round_nearest),
    prec,
    @mpf.round_nearest,
  )
  let digits = gz_mantissa_digit_count(expected_text)
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
test "mpf_factorial basic" {
  assert_eq(mpf_factorial(0, 80, @mpf.round_nearest), @mpf.fone)
  assert_eq(mpf_factorial(1, 80, @mpf.round_nearest), @mpf.fone)
  assert_eq(mpf_factorial(5, 80, @mpf.round_nearest), @mpf.from_int(120))
  assert_eq(mpf_factorial(10, 80, @mpf.round_nearest), @mpf.from_int(3628800))
}

///|
test "mpf_bernoulli small values" {
  assert_eq(mpf_bernoulli(0, 120, @mpf.round_nearest), @mpf.from_int(1))
  assert_eq(
    mpf_bernoulli(1, 120, @mpf.round_nearest),
    @mpf.from_man_exp(-1N, -1, 0, @mpf.round_down),
  )
  assert_close_numeric(
    mpf_bernoulli(2, 120, @mpf.round_nearest),
    "0.166666666666666",
    16,
  )
  assert_close_numeric(
    mpf_bernoulli(4, 120, @mpf.round_nearest),
    "-0.033333333333333",
    16,
  )
  assert_eq(mpf_bernoulli(3, 120, @mpf.round_nearest), @mpf.fzero)
}

///|
test "mpf_bernoulli_huge subset" {
  let b100 = mpf_bernoulli_huge(100, 220, @mpf.round_nearest)
  assert_close_numeric(b100, "-2.83822495706937069592642e+78", 24)
  let b100_auto = mpf_bernoulli(100, 220, @mpf.round_nearest)
  assert_close_numeric(b100_auto, "-2.83822495706937069592642e+78", 24)
}

///|
test "mpf_zeta_int subset" {
  let z2 = mpf_zeta_int(2, 120, @mpf.round_nearest)
  let z3 = mpf_zeta_int(3, 120, @mpf.round_nearest)
  assert_close_numeric(z2, "1.644934066848226", 16)
  assert_close_numeric(z3, "1.202056903159594", 16)
}

///|
test "mpf_gamma subset" {
  assert_eq(
    mpf_gamma(@mpf.from_int(6), 120, @mpf.round_nearest),
    @mpf.from_int(120),
  )
  let ghalf = mpf_gamma(
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    120,
    @mpf.round_nearest,
  )
  assert_close_numeric(ghalf, "1.772453850905516", 16)
}

///|
test "mpmath diff subset for gammazeta" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_close_numeric(
    mpf_gamma(
      @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
      140,
      @mpf.round_nearest,
    ),
    "1.772453850905",
    14,
  )
  assert_close_numeric(
    mpf_zeta_int(2, 140, @mpf.round_nearest),
    "1.644934066848",
    14,
  )
  assert_close_numeric(
    mpf_zeta_int(3, 140, @mpf.round_nearest),
    "1.202056903159",
    14,
  )
  assert_close_numeric(
    mpf_bernoulli(10, 140, @mpf.round_nearest),
    "0.075757575757",
    14,
  )
}

///|
test "mpf rgamma/loggamma/gamma_int subset" {
  assert_close_numeric(
    mpf_rgamma(
      @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
      140,
      @mpf.round_nearest,
    ),
    "0.564189583547",
    14,
  )
  assert_close_numeric(
    mpf_loggamma(@mpf.from_str("3.5"), 140, @mpf.round_nearest),
    "1.200973602347",
    14,
  )
  assert_eq(mpf_gamma_int(6, 120, @mpf.round_nearest), @mpf.from_int(120))
}

///|
test "mpf psi harmonic fibonacci zeta subset" {
  assert_close_numeric(
    mpf_psi0(@mpf.from_str("3.5"), 140, @mpf.round_nearest),
    "1.1031566404",
    14,
  )
  assert_close_numeric(
    mpf_harmonic(@mpf.from_int(10), 140, @mpf.round_nearest),
    "2.928968253968",
    14,
  )
  assert_close_numeric(
    mpf_harmonic(@mpf.from_str("2.5"), 140, @mpf.round_nearest),
    "1.6803723053",
    14,
  )
  assert_close_numeric(
    mpf_psi0(@mpf.from_str("-0.5"), 140, @mpf.round_nearest),
    "0.0364899738",
    14,
  )
  assert_close_numeric(
    mpf_harmonic(@mpf.from_str("-0.5"), 140, @mpf.round_nearest),
    "-1.3862943612",
    14,
  )
  assert_close_numeric(
    mpf_harmonic(@mpf.from_str("-2.5"), 140, @mpf.round_nearest),
    "1.2803723053",
    14,
  )
  assert_eq(
    mpf_fibonacci(@mpf.from_int(10), 120, @mpf.round_nearest),
    @mpf.from_int(55),
  )
  assert_close_numeric(
    mpf_fibonacci(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
    "0.568864481005",
    14,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_str("2.5"), 140, @mpf.round_nearest),
    "1.34148725",
    14,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_str("2.5"), 140, @mpf.round_nearest, alt=true),
    "0.86719988",
    14,
  )
}

///|
test "mpf gamma/zeta negative real subset" {
  assert_close_numeric(
    mpf_gamma(@mpf.from_str("-0.5"), 160, @mpf.round_nearest),
    "-3.54490770181103",
    15,
  )
  assert_close_numeric(
    mpf_gamma(@mpf.from_str("-2.5"), 160, @mpf.round_nearest),
    "-0.94530872048294",
    15,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(0), 160, @mpf.round_nearest),
    "-0.5",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(-1), 160, @mpf.round_nearest),
    "-0.083333333333333",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(-3), 160, @mpf.round_nearest),
    "0.008333333333333",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_str("-0.5"), 160, @mpf.round_nearest),
    "-0.20788622",
    12,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(0), 160, @mpf.round_nearest, alt=true),
    "0.5",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(-1), 160, @mpf.round_nearest, alt=true),
    "0.25",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_int(-3), 160, @mpf.round_nearest, alt=true),
    "-0.125",
    16,
  )
  assert_close_numeric(
    mpf_zeta(@mpf.from_str("-0.5"), 160, @mpf.round_nearest, alt=true),
    "0.38010481",
    12,
  )
  assert_close_numeric(
    mpf_psi(1, @mpf.from_str("-0.5"), 180, @mpf.round_nearest),
    "8.934802200544",
    14,
  )
  assert_close_numeric(
    mpf_psi(2, @mpf.from_str("-0.5"), 180, @mpf.round_nearest),
    "-0.828796644234",
    14,
  )
  assert_eq(mpf_psi(1, @mpf.finf, 120, @mpf.round_nearest), @mpf.fzero)
}

///|
test "mpf psi0 harmonic infinity semantics and large-negative stability" {
  assert_true(@mpf.is_nan(mpf_psi0(@mpf.fninf, 140, @mpf.round_nearest)))
  assert_eq(mpf_psi0(@mpf.finf, 140, @mpf.round_nearest), @mpf.finf)
  assert_true(@mpf.is_nan(mpf_harmonic(@mpf.fninf, 140, @mpf.round_nearest)))
  assert_eq(mpf_harmonic(@mpf.finf, 140, @mpf.round_nearest), @mpf.finf)
  let psi1_large_neg = mpf_psi(
    1,
    @mpf.from_str("-1e80"),
    180,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(psi1_large_neg))
  let psi2_large_neg = mpf_psi(
    2,
    @mpf.from_str("-1e80"),
    180,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(psi2_large_neg))
}

///|
test "mpf zeta higher precision subset" {
  assert_close_numeric(
    mpf_zeta_int(3, 260, @mpf.round_nearest),
    "1.2020569031595942853997381615",
    30,
  )
  assert_close_numeric(
    mpf_zeta_int(5, 260, @mpf.round_nearest),
    "1.0369277551433699263313654864",
    30,
  )
  let s_near_1 = @mpf.from_str("1.0001", prec=360, rnd=@mpf.round_nearest)
  assert_close_numeric(
    mpf_zeta(s_near_1, 260, @mpf.round_nearest),
    "10000.5772229464376290700",
    25,
  )
  let s_near_1_minus = @mpf.from_str("0.999", prec=360, rnd=@mpf.round_nearest)
  assert_close_numeric(
    mpf_altzeta(s_near_1_minus, 260, @mpf.round_nearest),
    "0.69298727896833835736749",
    24,
  )
}

///|
test "panic mpf_factorial negative" {
  ignore(mpf_factorial(-1, 80, @mpf.round_nearest))
}

///|
test "panic mpf_zeta_int pole" {
  ignore(mpf_zeta_int(1, 80, @mpf.round_nearest))
}

///|
test "panic mpf_gamma pole" {
  ignore(mpf_gamma(@mpf.from_int(0), 80, @mpf.round_nearest))
}

///|
test "panic unsupported branches in gammazeta subset" {
  ignore(mpf_psi0(@mpf.from_int(0), 80, @mpf.round_nearest))
}
