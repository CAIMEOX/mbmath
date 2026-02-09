///|
test "from_str basic decimal forms" {
  assert_eq(from_str("3"), from_str("3.0"))
  assert_eq(from_str("3"), from_str("0003."))
  assert_eq(from_str("3"), from_str("0.03e2"))
  assert_eq(from_str("30"), from_str("30.0"))
  assert_eq(from_str("30"), from_str("00030."))
}

///|
test "from_str supports exponent, sign, whitespace and underscore" {
  assert_eq(to_str(from_str("  +3.125E+1  ")), "31.25")
  assert_eq(to_str(from_str("125e-2")), "1.25")
  assert_eq(to_str(from_str("2_5_0_0.0")), "2500.0")
}

///|
test "from_str hex subset" {
  assert_eq(to_str(from_str("0x1.8p+2")), "6.0")
  assert_eq(to_str(from_str("0x1.4ace478p+33")), "11100000000.0")
  assert_eq(
    to_str_opts(from_str("0x1.8p+2"), base=16, binary_exp=true, dps=0),
    "0x1.8p+2",
  )
}

///|
test "from_str pow2 base literals subset" {
  assert_eq(to_str(from_str("0b11010.1")), "26.5")
  assert_eq(to_str(from_str("0o32.4")), "26.5")
  assert_eq(to_str(from_str("0b1_010.01")), "10.25")
}

///|
test "from_str special values" {
  assert_eq(from_str("inf"), finf)
  assert_eq(from_str("+inf"), finf)
  assert_eq(from_str("Infinity"), finf)
  assert_eq(from_str("-inf"), fninf)
  assert_true(is_nan(from_str("nan")))
  assert_true(is_nan(from_str("-nan")))
}

///|
test "to_str special values" {
  assert_eq(to_str(finf), "inf")
  assert_eq(to_str(fninf), "-inf")
  assert_eq(to_str(fnan), "nan")
}

///|
test "to_str basic fixed formatting" {
  assert_eq(to_str(from_str("25000.0")), "25000.0")
  assert_eq(to_str(from_str("2.5")), "2.5")
  assert_eq(to_str(from_str("0.25")), "0.25")
  assert_eq(to_str(from_str("0.00025")), "0.00025")
  assert_eq(to_str(from_str("-1.25")), "-1.25")
  assert_eq(to_str(from_int(0)), "0.0")
}

///|
test "to_str from binary values" {
  assert_eq(to_str(from_man_exp(1N, -1, 0, round_down)), "0.5")
  assert_eq(to_str(from_man_exp(1N, -4, 0, round_down)), "0.0625")
  assert_eq(to_str(from_man_exp(5N, 1, 0, round_down)), "10.0")
}

///|
test "to_str scientific formatting thresholds" {
  assert_eq(to_str(from_str("0.000025")), "2.5e-5")
  assert_eq(to_str(from_str("0.0000001")), "1.0e-7")
  assert_eq(to_str(from_str("1e20")), "1.0e+20")
  assert_eq(to_str(from_str("1250000000000000000000")), "1.25e+21")
  assert_eq(to_str(from_str("1e600")), "1.0e+600")
}

///|
test "to_str opts base subset" {
  let x = from_str("26.5")
  assert_eq(to_str_opts(x, base=2), "0b11010.1")
  assert_eq(to_str_opts(x, base=8), "0o32.4")
  assert_eq(to_str_opts(x, base=16), "0x1a.8")
  assert_eq(to_str_opts(x, base=16, binary_exp=true, dps=0), "0x1.a8p+4")
  assert_eq(
    to_str_opts(from_int(16), base=16, binary_exp=true),
    "0x1.000000000000000p+4",
  )
  assert_eq(to_str_opts(from_str("12345.6789"), dps=4), "1.235e+4")
}

///|
test "format_mpf minimal subset" {
  let pi = from_str("3.1415926535")
  assert_eq(format_mpf(pi, ".2f"), "3.14")
  assert_eq(format_mpf(pi, ".3e"), "3.142e+0")
  assert_eq(format_mpf(pi, "+.2f"), "+3.14")
  assert_eq(format_mpf(pi, " .2f"), " 3.14")
  assert_eq(format_mpf(pi, ".2E"), "3.14E+0")
  assert_eq(format_mpf(pi, ".4G"), "3.142")
  assert_eq(format_mpf(pi, "10.2f"), "      3.14")
  assert_eq(format_mpf(pi, "*<10.2f"), "3.14******")
  assert_eq(format_mpf(pi, "*^10.2f"), "***3.14***")
  assert_eq(format_mpf(from_str("12345.67"), ",.2f"), "12,345.67")
  assert_eq(format_mpf(from_str("12345.67"), "_.2f"), "12_345.67")
  assert_eq(format_mpf(from_str("1234"), "012,.0f"), "00000001,234")
  assert_eq(format_mpf(from_str("-12.3"), "08.1f"), "-00012.3")
  assert_eq(format_mpf(from_str("0.0000004999"), ".9_f"), "0.000_000_500")
  assert_eq(format_mpf(from_int(2), "#.0f"), "2.")
  assert_eq(format_mpf(from_int(2), "#.0e"), "2.e+0")
  assert_eq(format_mpf(from_int(12), "#.4g"), "12.00")
  assert_eq(format_mpf(from_str("0.125"), ".1%"), "12.5%")
  assert_eq(format_mpf(from_str("0.125"), "+010.1%"), "+000012.5%")
  assert_eq(format_mpf(from_int(3), "b"), "1.1p+1")
  assert_eq(format_mpf(from_int(3), ".2b"), "1.10p+1")
  assert_eq(format_mpf(from_int(3), "+.2b"), "+1.10p+1")
  assert_eq(format_mpf(from_int(3), "#.2b"), "0b1.10p+1")
  assert_eq(format_mpf(from_int(0), ".2b"), "0.00p+0")
  assert_eq(format_mpf(from_int(0), "b"), "0p+0")
  assert_eq(format_mpf(from_str("1.5"), ".2a"), "0x1.80p+0")
  assert_eq(format_mpf(from_str("1.5"), ".0a"), "0x1p+0")
  assert_eq(format_mpf(from_str("1.5"), "#.0a"), "0x1.p+0")
  assert_eq(format_mpf(from_str("1.5"), "+.0A"), "+0X1P+0")
  assert_eq(format_mpf(from_int(1000), ".0g"), "1e+3")
  assert_eq(format_mpf(from_int(1000), "#.0g"), "1.e+3")
  assert_eq(format_mpf(from_str("-0.0001"), ".2f"), "-0.00")
  assert_eq(format_mpf(from_str("-0.0001"), "z.2f"), "0.00")
  assert_eq(format_mpf(from_str("-0.0001"), "+z.2f"), "+0.00")
  assert_eq(format_mpf(from_str("12500"), ".4g"), "1.25e+4")
  assert_eq(format_mpf(finf, ">8g"), "     inf")
  assert_eq(format_mpf(finf, "+8G"), "    +INF")
  assert_eq(format_mpf(finf, "08G"), "00000INF")
  assert_eq(format_mpf(finf, "+%"), "+inf%")
  assert_eq(format_mpf(fninf, "%"), "-inf%")
  assert_eq(format_mpf(fnan, "+%"), "+nan%")
  assert_eq(format_mpf(fnan, "+G"), "+NAN")
  assert_eq(format_mpf(fninf, "+G"), "-INF")
}

///|
test "format_mpf rounding suffix subset" {
  let neg = from_str("-1.23456789999901234567")
  assert_eq(format_mpf(neg, ".2Uf"), "-1.23")
  assert_eq(format_mpf(neg, ".2Df"), "-1.24")
  assert_eq(format_mpf(neg, ".2Zf"), "-1.23")
  assert_eq(format_mpf(neg, ".2Nf"), "-1.23")
  assert_eq(format_mpf(neg, ".2Yf"), "-1.24")
  let pos = from_str("1.23456789999901234567")
  assert_eq(format_mpf(pos, ".2Uf"), "1.24")
  assert_eq(format_mpf(pos, ".2Df"), "1.23")
  assert_eq(format_mpf(pos, ".2Zf"), "1.23")
  assert_eq(format_mpf(pos, ".2Nf"), "1.23")
  assert_eq(format_mpf(pos, ".2Yf"), "1.24")
  assert_eq(format_mpf(from_str("123.456"), ".2Ug"), "1.3e+2")
  assert_eq(format_mpf(from_str("123.456"), ".2Dg"), "1.2e+2")
  assert_eq(format_mpf(from_str("-123.456"), ".2Ug"), "-1.2e+2")
  assert_eq(format_mpf(from_str("-123.456"), ".2Dg"), "-1.3e+2")
}

///|
test "from_str non-dyadic with explicit precision" {
  let x = from_str("0.1", prec=20, rnd=round_nearest)
  let y = from_str("0.1", prec=20, rnd=round_nearest)
  assert_eq(x, y)
}

///|
test "panic from_str invalid" {
  ignore(from_str("1e"))
}

///|
test "panic format_mpf invalid type" {
  ignore(format_mpf(from_int(4), "22.15k"))
}

///|
test "panic format_mpf invalid precision forms" {
  ignore(format_mpf(from_str("-0.01"), "<z15.e"))
}

///|
test "panic format_mpf unsupported trailer" {
  ignore(format_mpf(from_int(4), "10.5fk"))
}

///|
test "panic format_mpf dot without precision" {
  ignore(format_mpf(from_int(1), ".f"))
}

///|
test "panic format_mpf separator without precision digits" {
  ignore(format_mpf(from_int(1), "._6f"))
}
