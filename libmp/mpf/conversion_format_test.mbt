///|
test "convert to_str base16 subset from mpmath test_convert" {
  @debug.assert_eq(
    RawMpf::parse("0xABC.ABC").format(dps=6, base=16),
    "0xabc.abc",
  )
  @debug.assert_eq(RawMpf::parse("0x3.a7p10").format(dps=3, base=16), "0xe9c.0")
  @debug.assert_eq(
    RawMpf::parse("0o1101.100101").format(dps=8, base=8),
    "0o1101.100101",
  )
  @debug.assert_eq(
    RawMpf::parse("0b1101.100101").format(dps=10, base=2),
    "0b1101.100101",
  )
}

///|
test "convert to_str binary-exp subset from mpmath test_convert" {
  let x = RawMpf::parse("0x1.4ace478p+33")
  @debug.assert_eq(
    x.format(dps=8, base=16, binary_exp=true),
    "0x1.4ace4780p+33",
  )
  @debug.assert_eq(x.format(dps=7, base=16, binary_exp=true), "0x1.4ace478p+33")
  @debug.assert_eq(x.format(dps=5, base=16, binary_exp=true), "0x1.4ace4p+33")
  @debug.assert_eq(
    RawMpf::from_int(1).format(dps=6, base=16, binary_exp=true),
    "0x1.000000p+0",
  )
}

///|
test "convert non-dyadic parse precision subset from mpmath test_convert" {
  let x = RawMpf::parse("1.99999999", prec=0)
  @debug.assert_eq(x.format(dps=16), "1.99999999")
}

///|
test "convert whitespace and underscore subset from mpmath test_convert" {
  @debug.assert_eq(RawMpf::parse("1.26 ").to_string(), "1.26")
  @debug.assert_eq(RawMpf::parse("1_234.567891").to_string(), "1234.567891")
  @debug.assert_eq(RawMpf::parse("1_234.567_891").to_string(), "1234.567891")
  @debug.assert_eq(RawMpf::parse("1_234.567_8_9_1").to_string(), "1234.567891")
  @debug.assert_eq(RawMpf::parse("1.0_0").to_string(), "1.0")
  @debug.assert_eq(RawMpf::parse(".000").to_string(), "0.0")
}

///|
test "convert tight 0.5 conversion subset from mpmath test_convert" {
  let h = RawMpf::from_mantissa_exponent(1N, -1, 0, Down)
  @debug.assert_eq(RawMpf::parse("0.5", prec=10, rnd=Floor), h)
  @debug.assert_eq(RawMpf::parse("0.5", prec=10, rnd=Ceiling), h)
}

///|
test "convert scientific exponent formatting bugfix subset" {
  @debug.assert_eq(RawMpf::parse("1e600").to_string(), "1.0e+600")
  @debug.assert_eq(RawMpf::parse("1e10000").to_string(), "1.0e+10000")
  @debug.assert_eq(RawMpf::parse("2.5e120").to_string(), "2.5e+120")
  @debug.assert_eq(RawMpf::parse("2.6e-120").to_string(), "2.6e-120")
}

///|
test "format default-rounding subset from mpmath test_format" {
  let x = RawMpf::parse("2.5")
  @debug.assert_eq(x.format_spec(".0f"), "2")
  @debug.assert_eq(x.format_spec(".0Yf"), "3")
  @debug.assert_eq(RawMpf::parse("-2.5").format_spec(".0f"), "-2")
  @debug.assert_eq(RawMpf::parse("-2.5").format_spec(".0Yf"), "-3")
}

///|
test "format hex and binary subset from mpmath test_format" {
  @debug.assert_eq(RawMpf::parse("26.5").format_spec(".3a"), "0x1.a80p+4")
  @debug.assert_eq(RawMpf::parse("26.5").format_spec("#.3a"), "0x1.a80p+4")
  @debug.assert_eq(RawMpf::parse("26.5").format_spec(".4b"), "1.1010p+4")
  @debug.assert_eq(RawMpf::parse("26.5").format_spec("#.4b"), "0b1.1010p+4")
}
