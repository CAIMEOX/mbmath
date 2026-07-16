///|
fn assert_prefix(v : @mpf.RawMpf, dps : Int, prefix : String) -> Unit raise {
  let _ = dps
  // mpmath/mbmath may render decimals with different formatting
  // (fixed vs scientific, trailing zeros), so compare numerically.
  let expected = @mpf.RawMpf::parse(prefix)
  let diff = v.sub(expected, 260, Nearest).abs(260, Nearest)
  if !(diff < @mpf.RawMpf::parse("1e-12")) {
    fail("numeric mismatch expected=\{prefix} actual=\{v.format(dps=18)}")
  }
}

///|
test "mpmath bulk exp special values" {
  assert_true(exp(@mpf.RawMpf::zero(), 180, Nearest) == @mpf.RawMpf::one())
  assert_true(
    exp(@mpf.RawMpf::infinity(), 180, Nearest) == @mpf.RawMpf::infinity(),
  )
  assert_true(
    exp(@mpf.RawMpf::negative_infinity(), 180, Nearest) == @mpf.RawMpf::zero(),
  )
  assert_true(exp(@mpf.RawMpf::nan(), 180, Nearest).is_nan())
}

///|
test "mpmath bulk exp x=1 and x=-1" {
  assert_prefix(
    exp(@mpf.RawMpf::one(), 220, Nearest),
    18,
    "2.71828182845904523",
  )
  assert_prefix(
    exp(@mpf.RawMpf::from_int(-1), 220, Nearest),
    18,
    "0.36787944117144232",
  )
}

///|
test "mpmath bulk ln baseline and inf" {
  assert_true(ln(@mpf.RawMpf::one(), 220, Nearest) == @mpf.RawMpf::zero())
  assert_prefix(
    ln(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.69314718055994530",
  )
  assert_prefix(
    ln(@mpf.RawMpf::from_int(10), 220, Nearest),
    18,
    "2.30258509299404568",
  )
  assert_true(
    ln(@mpf.RawMpf::infinity(), 220, Nearest) == @mpf.RawMpf::infinity(),
  )
}

///|
test "mpmath bulk log alias" {
  let x = @mpf.RawMpf::parse("1.5")
  let a = log(x, 220, Nearest)
  let b = ln(x, 220, Nearest)
  assert_true(a == b)
}

///|
test "mpmath bulk log1p values" {
  assert_prefix(
    log1p(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.40546510810816438",
  )
  assert_prefix(
    log1p(@mpf.RawMpf::parse("1e-10"), 240, Nearest),
    18,
    "0.00000000009999999",
  )
}

///|
test "mpmath bulk trig values around 0.5" {
  let x = @mpf.RawMpf::parse("0.5")
  assert_prefix(sin(x, 220, Nearest), 18, "0.47942553860420300")
  assert_prefix(cos(x, 220, Nearest), 18, "0.87758256189037271")
  assert_prefix(tan(x, 220, Nearest), 18, "0.54630248984379051")
}

///|
test "mpmath bulk trig values around 2" {
  let x = @mpf.RawMpf::from_int(2)
  assert_prefix(sin(x, 220, Nearest), 18, "0.90929742682568169")
  assert_prefix(cos(x, 220, Nearest), 18, "-0.4161468365471423")
  assert_prefix(tan(x, 220, Nearest), 18, "-2.1850398632615189")
}

///|
test "mpmath bulk trig x=inf produces nan" {
  assert_true(sin(@mpf.RawMpf::infinity(), 220, Nearest).is_nan())
  assert_true(cos(@mpf.RawMpf::infinity(), 220, Nearest).is_nan())
  assert_true(tan(@mpf.RawMpf::infinity(), 220, Nearest).is_nan())
}

///|
test "mpmath bulk hyperbolic values around 0.5" {
  let x = @mpf.RawMpf::parse("0.5")
  assert_prefix(sinh(x, 220, Nearest), 18, "0.52109530549374736")
  assert_prefix(cosh(x, 220, Nearest), 18, "1.12762596520638078")
  assert_prefix(tanh(x, 220, Nearest), 18, "0.46211715726000975")
}

///|
test "mpmath bulk hyperbolic values around 2" {
  let x = @mpf.RawMpf::from_int(2)
  assert_prefix(sinh(x, 220, Nearest), 18, "3.62686040784701876")
  assert_prefix(cosh(x, 220, Nearest), 18, "3.76219569108363145")
  assert_prefix(tanh(x, 220, Nearest), 18, "0.96402758007581688")
}

///|
test "mpmath bulk hyperbolic infinities" {
  assert_true(
    sinh(@mpf.RawMpf::infinity(), 220, Nearest) == @mpf.RawMpf::infinity(),
  )
  assert_true(
    sinh(@mpf.RawMpf::negative_infinity(), 220, Nearest) ==
    @mpf.RawMpf::negative_infinity(),
  )
  assert_true(
    cosh(@mpf.RawMpf::infinity(), 220, Nearest) == @mpf.RawMpf::infinity(),
  )
  assert_true(tanh(@mpf.RawMpf::infinity(), 220, Nearest) == @mpf.RawMpf::one())
  assert_true(
    tanh(@mpf.RawMpf::negative_infinity(), 220, Nearest) ==
    @mpf.RawMpf::negative_one(),
  )
}

///|
test "mpmath bulk atan values" {
  assert_prefix(
    atan(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.46364760900080611",
  )
  assert_prefix(
    atan(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "1.10714871779409050",
  )
  assert_prefix(
    atan(@mpf.RawMpf::from_int(-2), 220, Nearest),
    18,
    "-1.1071487177940905",
  )
}

///|
test "mpmath bulk atan2 values" {
  assert_prefix(
    atan2(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.78539816339744830",
  )
  assert_prefix(
    atan2(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(3), 220, Nearest),
    18,
    "-0.5880026035475675",
  )
  assert_prefix(
    atan2(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(-3), 220, Nearest),
    18,
    "2.55359005004222568",
  )
}

///|
test "mpmath bulk inverse trig and hyperbolic values" {
  assert_prefix(
    asin(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.52359877559829887",
  )
  assert_prefix(
    acos(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "1.04719755119659774",
  )
  assert_prefix(
    asinh(@mpf.RawMpf::one(), 220, Nearest),
    18,
    "0.88137358701954302",
  )
  assert_prefix(
    acosh(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "1.31695789692481670",
  )
  assert_prefix(
    atanh(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.54930614433405484",
  )
}

///|
test "mpmath bulk pow and roots values" {
  assert_prefix(
    pow(@mpf.RawMpf::from_int(2), @mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "1.41421356237309504",
  )
  assert_prefix(
    pow(@mpf.RawMpf::from_int(2), @mpf.RawMpf::parse("1.5"), 220, Nearest),
    18,
    "2.82842712474619009",
  )
  assert_prefix(
    nthroot(@mpf.RawMpf::from_int(2), 5, 220, Nearest),
    18,
    "1.14869835499703500",
  )
  assert_prefix(
    cbrt(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "1.25992104989487316",
  )
}

///|
test "mpmath bulk constants e ln2 ln10" {
  assert_prefix(e(220, Nearest), 18, "2.71828182845904523")
  assert_prefix(ln2(220, Nearest), 18, "0.69314718055994530")
  assert_prefix(ln10(220, Nearest), 18, "2.30258509299404568")
}
