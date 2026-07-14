///|
test "convert to_str base16 subset from mpmath test_convert" {
  @debug.assert_eq(
    to_str_opts(from_str("0xABC.ABC"), dps=6, base=16),
    "0xabc.abc",
  )
  @debug.assert_eq(
    to_str_opts(from_str("0x3.a7p10"), dps=3, base=16),
    "0xe9c.0",
  )
  @debug.assert_eq(
    to_str_opts(from_str("0o1101.100101"), dps=8, base=8),
    "0o1101.100101",
  )
  @debug.assert_eq(
    to_str_opts(from_str("0b1101.100101"), dps=10, base=2),
    "0b1101.100101",
  )
}

///|
test "convert to_str binary-exp subset from mpmath test_convert" {
  let x = from_str("0x1.4ace478p+33")
  @debug.assert_eq(
    to_str_opts(x, dps=8, base=16, binary_exp=true),
    "0x1.4ace4780p+33",
  )
  @debug.assert_eq(
    to_str_opts(x, dps=7, base=16, binary_exp=true),
    "0x1.4ace478p+33",
  )
  @debug.assert_eq(
    to_str_opts(x, dps=5, base=16, binary_exp=true),
    "0x1.4ace4p+33",
  )
  @debug.assert_eq(
    to_str_opts(from_int(1), dps=6, base=16, binary_exp=true),
    "0x1.000000p+0",
  )
}

///|
test "convert non-dyadic parse precision subset from mpmath test_convert" {
  let x = from_str("1.99999999", prec=0)
  @debug.assert_eq(to_str_opts(x, dps=16), "1.99999999")
}

///|
test "convert whitespace and underscore subset from mpmath test_convert" {
  @debug.assert_eq(to_str(from_str("1.26 ")), "1.26")
  @debug.assert_eq(to_str(from_str("1_234.567891")), "1234.567891")
  @debug.assert_eq(to_str(from_str("1_234.567_891")), "1234.567891")
  @debug.assert_eq(to_str(from_str("1_234.567_8_9_1")), "1234.567891")
  @debug.assert_eq(to_str(from_str("1.0_0")), "1.0")
  @debug.assert_eq(to_str(from_str(".000")), "0.0")
}

///|
test "convert tight 0.5 conversion subset from mpmath test_convert" {
  let h = from_man_exp(1N, -1, 0, round_down)
  @debug.assert_eq(from_str("0.5", prec=10, rnd=round_floor), h)
  @debug.assert_eq(from_str("0.5", prec=10, rnd=round_ceiling), h)
}

///|
test "convert scientific exponent formatting bugfix subset" {
  @debug.assert_eq(to_str(from_str("1e600")), "1.0e+600")
  @debug.assert_eq(to_str(from_str("1e10000")), "1.0e+10000")
  @debug.assert_eq(to_str(from_str("2.5e120")), "2.5e+120")
  @debug.assert_eq(to_str(from_str("2.6e-120")), "2.6e-120")
}

///|
test "format default-rounding subset from mpmath test_format" {
  let x = from_str("2.5")
  @debug.assert_eq(format_mpf(x, ".0f"), "2")
  @debug.assert_eq(format_mpf(x, ".0Yf"), "3")
  @debug.assert_eq(format_mpf(from_str("-2.5"), ".0f"), "-2")
  @debug.assert_eq(format_mpf(from_str("-2.5"), ".0Yf"), "-3")
}

///|
test "format hex and binary subset from mpmath test_format" {
  @debug.assert_eq(format_mpf(from_str("26.5"), ".3a"), "0x1.a80p+4")
  @debug.assert_eq(format_mpf(from_str("26.5"), "#.3a"), "0x1.a80p+4")
  @debug.assert_eq(format_mpf(from_str("26.5"), ".4b"), "1.1010p+4")
  @debug.assert_eq(format_mpf(from_str("26.5"), "#.4b"), "0b1.1010p+4")
}
