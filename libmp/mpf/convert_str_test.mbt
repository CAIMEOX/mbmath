///|
test "from_str basic decimal forms" {
  @debug.assert_eq(RawMpf::parse("3"), RawMpf::parse("3.0"))
  @debug.assert_eq(RawMpf::parse("3"), RawMpf::parse("0003."))
  @debug.assert_eq(RawMpf::parse("3"), RawMpf::parse("0.03e2"))
  @debug.assert_eq(RawMpf::parse("30"), RawMpf::parse("30.0"))
  @debug.assert_eq(RawMpf::parse("30"), RawMpf::parse("00030."))
}

///|
test "from_str supports exponent, sign, whitespace and underscore" {
  @debug.assert_eq(RawMpf::parse("  +3.125E+1  ").to_string(), "31.25")
  @debug.assert_eq(RawMpf::parse("125e-2").to_string(), "1.25")
  @debug.assert_eq(RawMpf::parse("2_5_0_0.0").to_string(), "2500.0")
}

///|
test "from_str hex subset" {
  @debug.assert_eq(RawMpf::parse("0x1.8p+2").to_string(), "6.0")
  @debug.assert_eq(
    RawMpf::parse("0x1.4ace478p+33").to_string(),
    "11100000000.0",
  )
  @debug.assert_eq(
    RawMpf::parse("0x1.8p+2").format(base=16, binary_exp=true, dps=0),
    "0x1.8p+2",
  )
}

///|
test "from_str pow2 base literals subset" {
  @debug.assert_eq(RawMpf::parse("0b11010.1").to_string(), "26.5")
  @debug.assert_eq(RawMpf::parse("0o32.4").to_string(), "26.5")
  @debug.assert_eq(RawMpf::parse("0b1_010.01").to_string(), "10.25")
}

///|
test "from_str special values" {
  @debug.assert_eq(RawMpf::parse("inf"), RawMpf::infinity())
  @debug.assert_eq(RawMpf::parse("+inf"), RawMpf::infinity())
  @debug.assert_eq(RawMpf::parse("Infinity"), RawMpf::infinity())
  @debug.assert_eq(RawMpf::parse("-inf"), RawMpf::negative_infinity())
  assert_true(RawMpf::parse("nan").is_nan())
  assert_true(RawMpf::parse("-nan").is_nan())
}

///|
test "to_str special values" {
  @debug.assert_eq(RawMpf::infinity().to_string(), "inf")
  @debug.assert_eq(RawMpf::negative_infinity().to_string(), "-inf")
  @debug.assert_eq(RawMpf::nan().to_string(), "nan")
}

///|
test "to_str basic fixed formatting" {
  @debug.assert_eq(RawMpf::parse("25000.0").to_string(), "25000.0")
  @debug.assert_eq(RawMpf::parse("2.5").to_string(), "2.5")
  @debug.assert_eq(RawMpf::parse("0.25").to_string(), "0.25")
  @debug.assert_eq(RawMpf::parse("0.00025").to_string(), "0.00025")
  @debug.assert_eq(RawMpf::parse("-1.25").to_string(), "-1.25")
  @debug.assert_eq(RawMpf::from_int(0).to_string(), "0.0")
}

///|
test "to_str from binary values" {
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(1N, -1, 0, Down).to_string(),
    "0.5",
  )
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(1N, -4, 0, Down).to_string(),
    "0.0625",
  )
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(5N, 1, 0, Down).to_string(),
    "10.0",
  )
}

///|
test "to_str scientific formatting thresholds" {
  @debug.assert_eq(RawMpf::parse("0.000025").to_string(), "2.5e-5")
  @debug.assert_eq(RawMpf::parse("0.0000001").to_string(), "1.0e-7")
  @debug.assert_eq(RawMpf::parse("1e20").to_string(), "1.0e+20")
  @debug.assert_eq(
    RawMpf::parse("1250000000000000000000").to_string(),
    "1.25e+21",
  )
  @debug.assert_eq(RawMpf::parse("1e600").to_string(), "1.0e+600")
}

///|
test "to_str opts base subset" {
  let x = RawMpf::parse("26.5")
  @debug.assert_eq(x.format(base=2), "0b11010.1")
  @debug.assert_eq(x.format(base=8), "0o32.4")
  @debug.assert_eq(x.format(base=16), "0x1a.8")
  @debug.assert_eq(x.format(base=16, binary_exp=true, dps=0), "0x1.a8p+4")
  @debug.assert_eq(
    RawMpf::from_int(16).format(base=16, binary_exp=true),
    "0x1.000000000000000p+4",
  )
  @debug.assert_eq(RawMpf::parse("12345.6789").format(dps=4), "1.235e+4")
}

///|
test "format_mpf minimal subset" {
  let pi = RawMpf::parse("3.1415926535")
  @debug.assert_eq(pi.format_spec(".2f"), "3.14")
  @debug.assert_eq(pi.format_spec(".3e"), "3.142e+0")
  @debug.assert_eq(pi.format_spec("+.2f"), "+3.14")
  @debug.assert_eq(pi.format_spec(" .2f"), " 3.14")
  @debug.assert_eq(pi.format_spec(".2E"), "3.14E+0")
  @debug.assert_eq(pi.format_spec(".4G"), "3.142")
  @debug.assert_eq(pi.format_spec("10.2f"), "      3.14")
  @debug.assert_eq(pi.format_spec("*<10.2f"), "3.14******")
  @debug.assert_eq(pi.format_spec("*^10.2f"), "***3.14***")
  @debug.assert_eq(RawMpf::parse("12345.67").format_spec(",.2f"), "12,345.67")
  @debug.assert_eq(RawMpf::parse("12345.67").format_spec("_.2f"), "12_345.67")
  @debug.assert_eq(RawMpf::parse("1234").format_spec("012,.0f"), "00000001,234")
  @debug.assert_eq(RawMpf::parse("-12.3").format_spec("08.1f"), "-00012.3")
  @debug.assert_eq(
    RawMpf::parse("0.0000004999").format_spec(".9_f"),
    "0.000_000_500",
  )
  @debug.assert_eq(RawMpf::from_int(2).format_spec("#.0f"), "2.")
  @debug.assert_eq(RawMpf::from_int(2).format_spec("#.0e"), "2.e+0")
  @debug.assert_eq(RawMpf::from_int(12).format_spec("#.4g"), "12.00")
  @debug.assert_eq(RawMpf::parse("0.125").format_spec(".1%"), "12.5%")
  @debug.assert_eq(RawMpf::parse("0.125").format_spec("+010.1%"), "+000012.5%")
  @debug.assert_eq(RawMpf::from_int(3).format_spec("b"), "1.1p+1")
  @debug.assert_eq(RawMpf::from_int(3).format_spec(".2b"), "1.10p+1")
  @debug.assert_eq(RawMpf::from_int(3).format_spec("+.2b"), "+1.10p+1")
  @debug.assert_eq(RawMpf::from_int(3).format_spec("#.2b"), "0b1.10p+1")
  @debug.assert_eq(RawMpf::from_int(0).format_spec(".2b"), "0.00p+0")
  @debug.assert_eq(RawMpf::from_int(0).format_spec("b"), "0p+0")
  @debug.assert_eq(RawMpf::parse("1.5").format_spec(".2a"), "0x1.80p+0")
  @debug.assert_eq(RawMpf::parse("1.5").format_spec(".0a"), "0x1p+0")
  @debug.assert_eq(RawMpf::parse("1.5").format_spec("#.0a"), "0x1.p+0")
  @debug.assert_eq(RawMpf::parse("1.5").format_spec("+.0A"), "+0X1P+0")
  @debug.assert_eq(RawMpf::from_int(1000).format_spec(".0g"), "1e+3")
  @debug.assert_eq(RawMpf::from_int(1000).format_spec("#.0g"), "1.e+3")
  @debug.assert_eq(RawMpf::parse("-0.0001").format_spec(".2f"), "-0.00")
  @debug.assert_eq(RawMpf::parse("-0.0001").format_spec("z.2f"), "0.00")
  @debug.assert_eq(RawMpf::parse("-0.0001").format_spec("+z.2f"), "+0.00")
  @debug.assert_eq(RawMpf::parse("12500").format_spec(".4g"), "1.25e+4")
  @debug.assert_eq(RawMpf::infinity().format_spec(">8g"), "     inf")
  @debug.assert_eq(RawMpf::infinity().format_spec("+8G"), "    +INF")
  @debug.assert_eq(RawMpf::infinity().format_spec("08G"), "00000INF")
  @debug.assert_eq(RawMpf::infinity().format_spec("+%"), "+inf%")
  @debug.assert_eq(RawMpf::negative_infinity().format_spec("%"), "-inf%")
  @debug.assert_eq(RawMpf::nan().format_spec("+%"), "+nan%")
  @debug.assert_eq(RawMpf::nan().format_spec("+G"), "+NAN")
  @debug.assert_eq(RawMpf::negative_infinity().format_spec("+G"), "-INF")
}

///|
test "format_mpf rounding suffix subset" {
  let neg = RawMpf::parse("-1.23456789999901234567")
  @debug.assert_eq(neg.format_spec(".2Uf"), "-1.23")
  @debug.assert_eq(neg.format_spec(".2Df"), "-1.24")
  @debug.assert_eq(neg.format_spec(".2Zf"), "-1.23")
  @debug.assert_eq(neg.format_spec(".2Nf"), "-1.23")
  @debug.assert_eq(neg.format_spec(".2Yf"), "-1.24")
  let pos = RawMpf::parse("1.23456789999901234567")
  @debug.assert_eq(pos.format_spec(".2Uf"), "1.24")
  @debug.assert_eq(pos.format_spec(".2Df"), "1.23")
  @debug.assert_eq(pos.format_spec(".2Zf"), "1.23")
  @debug.assert_eq(pos.format_spec(".2Nf"), "1.23")
  @debug.assert_eq(pos.format_spec(".2Yf"), "1.24")
  @debug.assert_eq(RawMpf::parse("123.456").format_spec(".2Ug"), "1.3e+2")
  @debug.assert_eq(RawMpf::parse("123.456").format_spec(".2Dg"), "1.2e+2")
  @debug.assert_eq(RawMpf::parse("-123.456").format_spec(".2Ug"), "-1.2e+2")
  @debug.assert_eq(RawMpf::parse("-123.456").format_spec(".2Dg"), "-1.3e+2")
}

///|
test "from_str non-dyadic with explicit precision" {
  let x = RawMpf::parse("0.1", prec=20, rnd=Nearest)
  let y = RawMpf::parse("0.1", prec=20, rnd=Nearest)
  @debug.assert_eq(x, y)
}

///|
test "panic from_str invalid" {
  ignore(RawMpf::parse("1e"))
}

///|
test "panic format_mpf invalid type" {
  ignore(RawMpf::from_int(4).format_spec("22.15k"))
}

///|
test "panic format_mpf invalid precision forms" {
  ignore(RawMpf::parse("-0.01").format_spec("<z15.e"))
}

///|
test "panic format_mpf unsupported trailer" {
  ignore(RawMpf::from_int(4).format_spec("10.5fk"))
}

///|
test "panic format_mpf dot without precision" {
  ignore(RawMpf::from_int(1).format_spec(".f"))
}

///|
test "panic format_mpf separator without precision digits" {
  ignore(RawMpf::from_int(1).format_spec("._6f"))
}
