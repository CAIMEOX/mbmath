///|
fn assert_prefix(v : @mpf.RawMpf, dps : Int, prefix : String) -> Unit raise {
  let _ = dps
  // mpmath/mbmath may render decimals with different formatting
  // (fixed vs scientific, trailing zeros), so compare numerically.
  let expected = @mpf.from_str(prefix)
  let diff = @mpf.mpf_abs(
    @mpf.mpf_sub(v, expected, 260, @mpf.round_nearest),
    260,
    @mpf.round_nearest,
  )
  if !@mpf.mpf_lt(diff, @mpf.from_str("1e-12")) {
    fail(
      "numeric mismatch expected=\{prefix} actual=\{@mpf.to_str_opts(v, dps=18)}",
    )
  }
}

///|
test "mpmath bulk exp special values" {
  assert_true(
    @mpf.mpf_eq(mpf_exp(@mpf.fzero, 180, @mpf.round_nearest), @mpf.fone),
  )
  assert_true(
    @mpf.mpf_eq(mpf_exp(@mpf.finf, 180, @mpf.round_nearest), @mpf.finf),
  )
  assert_true(
    @mpf.mpf_eq(mpf_exp(@mpf.fninf, 180, @mpf.round_nearest), @mpf.fzero),
  )
  assert_true(@mpf.is_nan(mpf_exp(@mpf.fnan, 180, @mpf.round_nearest)))
}

///|
test "mpmath bulk exp x=1 and x=-1" {
  assert_prefix(
    mpf_exp(@mpf.fone, 220, @mpf.round_nearest),
    18,
    "2.71828182845904523",
  )
  assert_prefix(
    mpf_exp(@mpf.from_int(-1), 220, @mpf.round_nearest),
    18,
    "0.36787944117144232",
  )
}

///|
test "mpmath bulk ln baseline and inf" {
  assert_true(
    @mpf.mpf_eq(mpf_ln(@mpf.fone, 220, @mpf.round_nearest), @mpf.fzero),
  )
  assert_prefix(
    mpf_ln(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.69314718055994530",
  )
  assert_prefix(
    mpf_ln(@mpf.from_int(10), 220, @mpf.round_nearest),
    18,
    "2.30258509299404568",
  )
  assert_true(
    @mpf.mpf_eq(mpf_ln(@mpf.finf, 220, @mpf.round_nearest), @mpf.finf),
  )
}

///|
test "mpmath bulk log alias" {
  let x = @mpf.from_str("1.5")
  let a = mpf_log(x, 220, @mpf.round_nearest)
  let b = mpf_ln(x, 220, @mpf.round_nearest)
  assert_true(@mpf.mpf_eq(a, b))
}

///|
test "mpmath bulk log1p values" {
  assert_prefix(
    mpf_log1p(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.40546510810816438",
  )
  assert_prefix(
    mpf_log1p(@mpf.from_str("1e-10"), 240, @mpf.round_nearest),
    18,
    "0.00000000009999999",
  )
}

///|
test "mpmath bulk trig values around 0.5" {
  let x = @mpf.from_str("0.5")
  assert_prefix(mpf_sin(x, 220, @mpf.round_nearest), 18, "0.47942553860420300")
  assert_prefix(mpf_cos(x, 220, @mpf.round_nearest), 18, "0.87758256189037271")
  assert_prefix(mpf_tan(x, 220, @mpf.round_nearest), 18, "0.54630248984379051")
}

///|
test "mpmath bulk trig values around 2" {
  let x = @mpf.from_int(2)
  assert_prefix(mpf_sin(x, 220, @mpf.round_nearest), 18, "0.90929742682568169")
  assert_prefix(mpf_cos(x, 220, @mpf.round_nearest), 18, "-0.4161468365471423")
  assert_prefix(mpf_tan(x, 220, @mpf.round_nearest), 18, "-2.1850398632615189")
}

///|
test "mpmath bulk trig x=inf produces nan" {
  assert_true(@mpf.is_nan(mpf_sin(@mpf.finf, 220, @mpf.round_nearest)))
  assert_true(@mpf.is_nan(mpf_cos(@mpf.finf, 220, @mpf.round_nearest)))
  assert_true(@mpf.is_nan(mpf_tan(@mpf.finf, 220, @mpf.round_nearest)))
}

///|
test "mpmath bulk hyperbolic values around 0.5" {
  let x = @mpf.from_str("0.5")
  assert_prefix(mpf_sinh(x, 220, @mpf.round_nearest), 18, "0.52109530549374736")
  assert_prefix(mpf_cosh(x, 220, @mpf.round_nearest), 18, "1.12762596520638078")
  assert_prefix(mpf_tanh(x, 220, @mpf.round_nearest), 18, "0.46211715726000975")
}

///|
test "mpmath bulk hyperbolic values around 2" {
  let x = @mpf.from_int(2)
  assert_prefix(mpf_sinh(x, 220, @mpf.round_nearest), 18, "3.62686040784701876")
  assert_prefix(mpf_cosh(x, 220, @mpf.round_nearest), 18, "3.76219569108363145")
  assert_prefix(mpf_tanh(x, 220, @mpf.round_nearest), 18, "0.96402758007581688")
}

///|
test "mpmath bulk hyperbolic infinities" {
  assert_true(
    @mpf.mpf_eq(mpf_sinh(@mpf.finf, 220, @mpf.round_nearest), @mpf.finf),
  )
  assert_true(
    @mpf.mpf_eq(mpf_sinh(@mpf.fninf, 220, @mpf.round_nearest), @mpf.fninf),
  )
  assert_true(
    @mpf.mpf_eq(mpf_cosh(@mpf.finf, 220, @mpf.round_nearest), @mpf.finf),
  )
  assert_true(
    @mpf.mpf_eq(mpf_tanh(@mpf.finf, 220, @mpf.round_nearest), @mpf.fone),
  )
  assert_true(
    @mpf.mpf_eq(mpf_tanh(@mpf.fninf, 220, @mpf.round_nearest), @mpf.fnone),
  )
}

///|
test "mpmath bulk atan values" {
  assert_prefix(
    mpf_atan(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.46364760900080611",
  )
  assert_prefix(
    mpf_atan(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "1.10714871779409050",
  )
  assert_prefix(
    mpf_atan(@mpf.from_int(-2), 220, @mpf.round_nearest),
    18,
    "-1.1071487177940905",
  )
}

///|
test "mpmath bulk atan2 values" {
  assert_prefix(
    mpf_atan2(@mpf.from_int(1), @mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.78539816339744830",
  )
  assert_prefix(
    mpf_atan2(@mpf.from_int(-2), @mpf.from_int(3), 220, @mpf.round_nearest),
    18,
    "-0.5880026035475675",
  )
  assert_prefix(
    mpf_atan2(@mpf.from_int(2), @mpf.from_int(-3), 220, @mpf.round_nearest),
    18,
    "2.55359005004222568",
  )
}

///|
test "mpmath bulk inverse trig and hyperbolic values" {
  assert_prefix(
    mpf_asin(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.52359877559829887",
  )
  assert_prefix(
    mpf_acos(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "1.04719755119659774",
  )
  assert_prefix(
    mpf_asinh(@mpf.fone, 220, @mpf.round_nearest),
    18,
    "0.88137358701954302",
  )
  assert_prefix(
    mpf_acosh(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "1.31695789692481670",
  )
  assert_prefix(
    mpf_atanh(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.54930614433405484",
  )
}

///|
test "mpmath bulk pow and roots values" {
  assert_prefix(
    mpf_pow(@mpf.from_int(2), @mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "1.41421356237309504",
  )
  assert_prefix(
    mpf_pow(@mpf.from_int(2), @mpf.from_str("1.5"), 220, @mpf.round_nearest),
    18,
    "2.82842712474619009",
  )
  assert_prefix(
    mpf_nthroot(@mpf.from_int(2), 5, 220, @mpf.round_nearest),
    18,
    "1.14869835499703500",
  )
  assert_prefix(
    mpf_cbrt(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "1.25992104989487316",
  )
}

///|
test "mpmath bulk constants e ln2 ln10" {
  assert_prefix(mpf_e(220, @mpf.round_nearest), 18, "2.71828182845904523")
  assert_prefix(mpf_ln2(220, @mpf.round_nearest), 18, "0.69314718055994530")
  assert_prefix(mpf_ln10(220, @mpf.round_nearest), 18, "2.30258509299404568")
}
