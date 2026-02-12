///|
test "p0 convert to_str base16 subset from mpmath test_convert" {
  assert_eq(to_str_opts(from_str("0xABC.ABC"), dps=6, base=16), "0xabc.abc")
  assert_eq(to_str_opts(from_str("0x3.a7p10"), dps=3, base=16), "0xe9c.0")
  assert_eq(
    to_str_opts(from_str("0o1101.100101"), dps=8, base=8),
    "0o1101.100101",
  )
  assert_eq(
    to_str_opts(from_str("0b1101.100101"), dps=10, base=2),
    "0b1101.100101",
  )
}

///|
test "p0 convert to_str binary-exp subset from mpmath test_convert" {
  let x = from_str("0x1.4ace478p+33")
  assert_eq(to_str_opts(x, dps=8, base=16, binary_exp=true), "0x1.4ace4780p+33")
  assert_eq(to_str_opts(x, dps=7, base=16, binary_exp=true), "0x1.4ace478p+33")
  assert_eq(to_str_opts(x, dps=5, base=16, binary_exp=true), "0x1.4ace4p+33")
  assert_eq(
    to_str_opts(from_int(1), dps=6, base=16, binary_exp=true),
    "0x1.000000p+0",
  )
}

///|
test "p0 convert non-dyadic parse precision subset from mpmath test_convert" {
  let x = from_str("1.99999999", prec=0)
  assert_eq(to_str_opts(x, dps=16), "1.99999999")
}

///|
test "p0 convert whitespace and underscore subset from mpmath test_convert" {
  assert_eq(to_str(from_str("1.26 ")), "1.26")
  assert_eq(to_str(from_str("1_234.567891")), "1234.567891")
  assert_eq(to_str(from_str("1_234.567_891")), "1234.567891")
  assert_eq(to_str(from_str("1_234.567_8_9_1")), "1234.567891")
  assert_eq(to_str(from_str("1.0_0")), "1.0")
  assert_eq(to_str(from_str(".000")), "0.0")
}

///|
test "p0 convert tight 0.5 conversion subset from mpmath test_convert" {
  let h = from_man_exp(1N, -1, 0, round_down)
  assert_eq(from_str("0.5", prec=10, rnd=round_floor), h)
  assert_eq(from_str("0.5", prec=10, rnd=round_ceiling), h)
}

///|
test "p0 convert scientific exponent formatting bugfix subset" {
  assert_eq(to_str(from_str("1e600")), "1.0e+600")
  assert_eq(to_str(from_str("1e10000")), "1.0e+10000")
  assert_eq(to_str(from_str("2.5e120")), "2.5e+120")
  assert_eq(to_str(from_str("2.6e-120")), "2.6e-120")
}

///|
test "p0 format default-rounding subset from mpmath test_format" {
  let x = from_str("2.5")
  assert_eq(format_mpf(x, ".0f"), "2")
  assert_eq(format_mpf(x, ".0Yf"), "3")
  assert_eq(format_mpf(from_str("-2.5"), ".0f"), "-2")
  assert_eq(format_mpf(from_str("-2.5"), ".0Yf"), "-3")
}

///|
test "p0 format hex and binary subset from mpmath test_format" {
  assert_eq(format_mpf(from_str("26.5"), ".3a"), "0x1.a80p+4")
  assert_eq(format_mpf(from_str("26.5"), "#.3a"), "0x1.a80p+4")
  assert_eq(format_mpf(from_str("26.5"), ".4b"), "1.1010p+4")
  assert_eq(format_mpf(from_str("26.5"), "#.4b"), "0b1.1010p+4")
}
