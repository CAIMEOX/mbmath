///|
test "precision and decimal digit conversion matches mpmath" {
  @debug.assert_eq(precision_to_decimal_digits(1), 1)
  @debug.assert_eq(precision_to_decimal_digits(53), 15)
  @debug.assert_eq(precision_to_decimal_digits(100), 29)
  @debug.assert_eq(decimal_digits_to_precision(15), 53)
  @debug.assert_eq(decimal_digits_to_precision(50), 169)
  @debug.assert_eq(representation_digits(53), 17)
  @debug.assert_eq(representation_digits(100), 32)
}

///|
test "BigInt mantissa and rational conversions are exact" {
  @debug.assert_eq(RawMpf::two(), RawMpf::from_int(2))
  @debug.assert_eq(RawMpf::ten(), RawMpf::from_int(10))
  @debug.assert_eq(RawMpf::half(), RawMpf::parse("0.5"))
  let huge = 1234567890123456789012345678901234567890N
  let x = RawMpf::from_bigint(huge)
  @debug.assert_eq(
    x.mantissa_exponent(),
    (617283945061728394506172839450617283945N, 1),
  )
  @debug.assert_eq(x.to_integer(), huge)
  let q = RawMpf::from_ratio(-7N, 4N, 80, Nearest)
  @debug.assert_eq(q.to_ratio(), (-7N, 4N))
  @debug.assert_eq(
    RawMpf::from_ratio(30N, 5N, 53, Nearest),
    RawMpf::from_int(6),
  )
  @debug.assert_eq(
    RawMpf::from_ratio(7N, -4N, 80, Nearest).to_ratio(),
    (-7N, 4N),
  )
}

///|
test "integer conversion implements all directed rounding modes" {
  let p = RawMpf::parse("1.5")
  let n = RawMpf::parse("-1.5")
  @debug.assert_eq(p.to_integer(rnd=Nearest), 2N)
  @debug.assert_eq(p.to_integer(rnd=Floor), 1N)
  @debug.assert_eq(p.to_integer(rnd=Ceiling), 2N)
  @debug.assert_eq(p.to_integer(rnd=Up), 2N)
  @debug.assert_eq(p.to_integer(rnd=Down), 1N)
  @debug.assert_eq(n.to_integer(rnd=Nearest), -2N)
  @debug.assert_eq(n.to_integer(rnd=Floor), -2N)
  @debug.assert_eq(n.to_integer(rnd=Ceiling), -1N)
  @debug.assert_eq(n.to_integer(rnd=Up), -2N)
  @debug.assert_eq(n.to_integer(rnd=Down), -1N)
  @debug.assert_eq(RawMpf::parse("0.5").to_integer(rnd=Nearest), 0N)
  @debug.assert_eq(RawMpf::parse("-0.5").to_integer(rnd=Nearest), 0N)
  let tiny = RawMpf::from_mantissa_exponent(1N, -100000, 0, Down)
  @debug.assert_eq(tiny.to_integer(rnd=Nearest), 0N)
  @debug.assert_eq(tiny.to_integer(rnd=Up), 1N)
  @debug.assert_eq((-tiny).to_integer(rnd=Floor), -1N)
}

///|
test "fixed-point conversion floors the exact scaled value" {
  @debug.assert_eq(RawMpf::parse("1.75").to_fixed(4), 28N)
  @debug.assert_eq(RawMpf::parse("-1.75").to_fixed(4), -28N)
  @debug.assert_eq(RawMpf::parse("-1.75").to_fixed(0), -2N)
  @debug.assert_eq(RawMpf::parse("0.125").to_fixed(2), 0N)
}

///|
test "Double conversion preserves exact IEEE-754 values" {
  let values = [
    0.0,
    -0.0,
    0.1,
    -13.5,
    1UL.reinterpret_as_double(),
    0x0010000000000000UL.reinterpret_as_double(),
    0x7fefffffffffffffUL.reinterpret_as_double(),
  ]
  for value in values {
    let roundtrip = RawMpf::from_double(value).to_double()
    if value == 0.0 {
      @debug.assert_eq(roundtrip, 0.0)
    } else {
      @debug.assert_eq(
        roundtrip.reinterpret_as_uint64(),
        value.reinterpret_as_uint64(),
      )
    }
  }
  @debug.assert_eq(RawMpf::from_double(1.0 / 0.0), RawMpf::infinity())
  @debug.assert_eq(RawMpf::from_double(-1.0 / 0.0), RawMpf::negative_infinity())
  assert_true(RawMpf::from_double(0.0 / 0.0).is_nan())
}

///|
test "Double conversion honors directed overflow and underflow" {
  let half_ulp = RawMpf::one().add(
    RawMpf::from_mantissa_exponent(1N, -53, 0, Down),
    0,
    Down,
  )
  @debug.assert_eq(
    half_ulp.to_double(rnd=Nearest).reinterpret_as_uint64(),
    0x3ff0000000000000UL,
  )
  @debug.assert_eq(
    half_ulp.to_double(rnd=Up).reinterpret_as_uint64(),
    0x3ff0000000000001UL,
  )
  let half_min = RawMpf::from_mantissa_exponent(1N, -1075, 0, Down)
  @debug.assert_eq(half_min.to_double(rnd=Nearest).reinterpret_as_uint64(), 0UL)
  @debug.assert_eq(half_min.to_double(rnd=Up).reinterpret_as_uint64(), 1UL)
  @debug.assert_eq(
    (-half_min).to_double(rnd=Floor).reinterpret_as_uint64(),
    0x8000000000000001UL,
  )
  @debug.assert_eq(
    (-half_min).to_double(rnd=Ceiling).reinterpret_as_uint64(),
    0x8000000000000000UL,
  )
  let overflow = RawMpf::from_mantissa_exponent(1N, 1024, 0, Down)
  @debug.assert_eq(overflow.to_double(rnd=Nearest).is_pos_inf(), true)
  @debug.assert_eq(
    overflow.to_double(rnd=Down).reinterpret_as_uint64(),
    0x7fefffffffffffffUL,
  )
  @debug.assert_eq(
    (-overflow).to_double(rnd=Ceiling).reinterpret_as_uint64(),
    0xffefffffffffffffUL,
  )
}

///|
test "numeric conversion failures are structured" {
  try RawMpf::from_ratio(1N, 0N, 80, Nearest) catch {
    DivisionByZero(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected DivisionByZero for a zero rational denominator")
  }
  try RawMpf::nan().to_integer() catch {
    ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for nan to integer")
  }
  try RawMpf::infinity().to_ratio() catch {
    OverflowError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected OverflowError for infinity to rational")
  }
  let overflow = RawMpf::from_mantissa_exponent(1N, 1024, 0, Down)
  try overflow.to_double(strict=true) catch {
    OverflowError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected OverflowError for strict Double conversion")
  }
}
