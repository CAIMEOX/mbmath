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
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = got.sub(expected, prec, Nearest).abs(prec, Nearest)
  let digits = gz_mantissa_digit_count(expected_text)
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
test "factorial basic" {
  @debug.assert_eq(factorial(0, 80, Nearest), @mpf.RawMpf::one())
  @debug.assert_eq(factorial(1, 80, Nearest), @mpf.RawMpf::one())
  @debug.assert_eq(factorial(5, 80, Nearest), @mpf.RawMpf::from_int(120))
  @debug.assert_eq(factorial(10, 80, Nearest), @mpf.RawMpf::from_int(3628800))
}

///|
test "bernoulli small values" {
  @debug.assert_eq(bernoulli(0, 120, Nearest), @mpf.RawMpf::from_int(1))
  @debug.assert_eq(
    bernoulli(1, 120, Nearest),
    @mpf.RawMpf::from_mantissa_exponent(-1N, -1, 0, Down),
  )
  assert_close_numeric(bernoulli(2, 120, Nearest), "0.166666666666666", 16)
  assert_close_numeric(bernoulli(4, 120, Nearest), "-0.033333333333333", 16)
  @debug.assert_eq(bernoulli(3, 120, Nearest), @mpf.RawMpf::zero())
}

///|
test "bernoulli_huge subset" {
  let b100 = large_bernoulli(100, 220, Nearest)
  assert_close_numeric(b100, "-2.83822495706937069592642e+78", 24)
  let b100_auto = bernoulli(100, 220, Nearest)
  assert_close_numeric(b100_auto, "-2.83822495706937069592642e+78", 24)
}

///|
test "zeta_int subset" {
  let z2 = zeta_integer(2, 120, Nearest)
  let z3 = zeta_integer(3, 120, Nearest)
  assert_close_numeric(z2, "1.644934066848226", 16)
  assert_close_numeric(z3, "1.202056903159594", 16)
}

///|
test "gamma subset" {
  @debug.assert_eq(
    gamma(@mpf.RawMpf::from_int(6), 120, Nearest),
    @mpf.RawMpf::from_int(120),
  )
  let ghalf = gamma(
    @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down),
    120,
    Nearest,
  )
  assert_close_numeric(ghalf, "1.772453850905516", 16)
}

///|
test "mpmath diff subset for gammazeta" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_close_numeric(
    gamma(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), 140, Nearest),
    "1.772453850905",
    14,
  )
  assert_close_numeric(zeta_integer(2, 140, Nearest), "1.644934066848", 14)
  assert_close_numeric(zeta_integer(3, 140, Nearest), "1.202056903159", 14)
  assert_close_numeric(bernoulli(10, 140, Nearest), "0.075757575757", 14)
}

///|
test "mpf rgamma/loggamma/gamma_int subset" {
  assert_close_numeric(
    rgamma(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), 140, Nearest),
    "0.564189583547",
    14,
  )
  assert_close_numeric(
    loggamma(@mpf.RawMpf::parse("3.5"), 140, Nearest),
    "1.200973602347",
    14,
  )
  @debug.assert_eq(gamma_integer(6, 120, Nearest), @mpf.RawMpf::from_int(120))
}

///|
test "mpf psi harmonic fibonacci zeta subset" {
  assert_close_numeric(
    digamma(@mpf.RawMpf::parse("3.5"), 140, Nearest),
    "1.103156640645243187225690",
    26,
  )
  assert_close_numeric(
    harmonic(@mpf.RawMpf::from_int(10), 140, Nearest),
    "2.928968253968253968253968",
    26,
  )
  assert_close_numeric(
    harmonic(@mpf.RawMpf::parse("2.5"), 140, Nearest),
    "1.680372305546776047832202",
    26,
  )
  assert_close_numeric(
    digamma(@mpf.RawMpf::parse("-0.5"), 140, Nearest),
    "0.03648997397857652055902367",
    26,
  )
  assert_close_numeric(
    harmonic(@mpf.RawMpf::parse("-0.5"), 140, Nearest),
    "-1.386294361119890618834464",
    26,
  )
  assert_close_numeric(
    harmonic(@mpf.RawMpf::parse("-2.5"), 140, Nearest),
    "1.280372305546776047832202",
    26,
  )
  @debug.assert_eq(
    fibonacci(@mpf.RawMpf::from_int(10), 120, Nearest),
    @mpf.RawMpf::from_int(55),
  )
  assert_close_numeric(
    fibonacci(@mpf.RawMpf::parse("0.5"), 140, Nearest),
    "0.5688644810057831072783079",
    26,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::parse("2.5"), 140, Nearest),
    "1.341487257250917179756770",
    26,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::parse("2.5"), 140, Nearest, alt=true),
    "0.8671998890121841381913472",
    26,
  )
}

///|
test "mpf gamma/zeta negative real subset" {
  assert_close_numeric(
    gamma(@mpf.RawMpf::parse("-0.5"), 160, Nearest),
    "-3.54490770181103",
    15,
  )
  assert_close_numeric(
    gamma(@mpf.RawMpf::parse("-2.5"), 160, Nearest),
    "-0.94530872048294",
    15,
  )
  assert_close_numeric(zeta(@mpf.RawMpf::from_int(0), 160, Nearest), "-0.5", 16)
  assert_close_numeric(
    zeta(@mpf.RawMpf::from_int(-1), 160, Nearest),
    "-0.083333333333333",
    16,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::from_int(-3), 160, Nearest),
    "0.008333333333333",
    16,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::parse("-0.5"), 160, Nearest),
    "-0.20788622",
    12,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::from_int(0), 160, Nearest, alt=true),
    "0.5",
    16,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::from_int(-1), 160, Nearest, alt=true),
    "0.25",
    16,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::from_int(-3), 160, Nearest, alt=true),
    "-0.125",
    16,
  )
  assert_close_numeric(
    zeta(@mpf.RawMpf::parse("-0.5"), 160, Nearest, alt=true),
    "0.38010481",
    12,
  )
  assert_close_numeric(
    polygamma(1, @mpf.RawMpf::parse("-0.5"), 180, Nearest),
    "8.934802200544",
    14,
  )
  assert_close_numeric(
    polygamma(2, @mpf.RawMpf::parse("-0.5"), 180, Nearest),
    "-0.828796644234",
    14,
  )
  @debug.assert_eq(
    polygamma(1, @mpf.RawMpf::infinity(), 120, Nearest),
    @mpf.RawMpf::zero(),
  )
}

///|
test "mpf psi0 harmonic infinity and huge-pole semantics" {
  assert_true(digamma(@mpf.RawMpf::negative_infinity(), 140, Nearest).is_nan())
  @debug.assert_eq(
    digamma(@mpf.RawMpf::infinity(), 140, Nearest),
    @mpf.RawMpf::infinity(),
  )
  assert_true(harmonic(@mpf.RawMpf::negative_infinity(), 140, Nearest).is_nan())
  @debug.assert_eq(
    harmonic(@mpf.RawMpf::infinity(), 140, Nearest),
    @mpf.RawMpf::infinity(),
  )
  let huge_negative_integer = @mpf.RawMpf::parse("-1e80")
  try polygamma(1, huge_negative_integer, 180, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected huge trigamma pole error")
  } noraise {
    _ => fail("expected huge non-positive integer trigamma pole")
  }
  try polygamma(2, huge_negative_integer, 180, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected huge tetragamma pole error")
  } noraise {
    _ => fail("expected huge non-positive integer tetragamma pole")
  }
}

///|
test "mpf zeta higher precision subset" {
  assert_close_numeric(
    zeta_integer(3, 260, Nearest),
    "1.2020569031595942853997381615",
    30,
  )
  assert_close_numeric(
    zeta_integer(5, 260, Nearest),
    "1.0369277551433699263313654864",
    30,
  )
  let s_near_1 = @mpf.RawMpf::parse("1.0001", prec=360, rnd=Nearest)
  assert_close_numeric(
    zeta(s_near_1, 260, Nearest),
    "10000.5772229464376290700",
    25,
  )
  let s_near_1_minus = @mpf.RawMpf::parse("0.999", prec=360, rnd=Nearest)
  assert_close_numeric(
    eta(s_near_1_minus, 260, Nearest),
    "0.69298727896833835736749",
    24,
  )
}

///|
test "panic factorial negative" {
  ignore(factorial(-1, 80, Nearest))
}

///|
test "panic zeta_int pole" {
  ignore(zeta_integer(1, 80, Nearest))
}

///|
test "panic gamma pole" {
  ignore(gamma(@mpf.RawMpf::from_int(0), 80, Nearest))
}

///|
test "panic unsupported branches in gammazeta subset" {
  ignore(digamma(@mpf.RawMpf::from_int(0), 80, Nearest))
}
