///|
fn dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn mantissa_digit_count(expected_text : String) -> Int {
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
  v : @mpf.RawMpf,
  dps : Int,
  expected_text : String,
) -> Unit raise {
  let prec = dps_to_prec(dps)
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = v.sub(expected, prec, Nearest).abs(prec, Nearest)
  let digits = mantissa_digit_count(expected_text)
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
fn assert_small_abs(v : @mpf.RawMpf, bound : String) -> Unit raise {
  let bound_v = @mpf.RawMpf::parse(bound, prec=240, rnd=Nearest)
  assert_true(v.abs(240, Nearest) < bound_v)
}

///|
fn assert_between(v : @mpf.RawMpf, lo : String, hi : String) -> Unit raise {
  let lo_v = @mpf.RawMpf::parse(lo, prec=240, rnd=Nearest)
  let hi_v = @mpf.RawMpf::parse(hi, prec=240, rnd=Nearest)
  assert_true(v > lo_v && v < hi_v)
}

///|
test "mpmath bulk ei zero and infinities" {
  let e0 = ei(@mpf.RawMpf::zero(), 140, Nearest)
  assert_true(e0.is_infinite() && e0.sign == 1)
  let ep = ei(@mpf.RawMpf::infinity(), 140, Nearest)
  assert_true(ep.is_infinite() && ep.sign == 0)
  let en = ei(@mpf.RawMpf::negative_infinity(), 140, Nearest)
  assert_true(en.is_zero())
}

///|
test "mpmath bulk ei x=0.5" {
  assert_between(ei(@mpf.RawMpf::parse("0.5"), 220, Nearest), "0.4", "0.5")
}

///|
test "mpmath bulk ei x=1" {
  assert_between(ei(@mpf.RawMpf::from_int(1), 220, Nearest), "1", "2")
}

///|
test "mpmath bulk ei x=2" {
  assert_close_numeric(
    ei(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "4.95423435600189016",
  )
}

///|
test "mpmath bulk ei x=3" {
  assert_between(ei(@mpf.RawMpf::from_int(3), 220, Nearest), "9", "11")
}

///|
test "mpmath bulk ei x=5" {
  assert_between(ei(@mpf.RawMpf::from_int(5), 220, Nearest), "35", "45")
}

///|
test "mpmath bulk ei x=20" {
  assert_close_numeric(
    ei(@mpf.RawMpf::from_int(20), 220, Nearest),
    18,
    "25615652.66405658",
  )
}

///|
test "mpmath bulk ei x=-0.5" {
  assert_close_numeric(
    ei(@mpf.RawMpf::parse("-0.5"), 220, Nearest),
    18,
    "-0.5597735947761608",
  )
}

///|
test "mpmath bulk ei x=-1" {
  assert_close_numeric(
    ei(@mpf.RawMpf::from_int(-1), 220, Nearest),
    18,
    "-0.2193839343955202",
  )
}

///|
test "mpmath bulk ei x=-2" {
  assert_close_numeric(
    ei(@mpf.RawMpf::from_int(-2), 220, Nearest),
    18,
    "-0.04890051070806111",
  )
}

///|
test "mpmath bulk si x=0" {
  assert_true(si(@mpf.RawMpf::zero(), 160, Nearest).is_zero())
}

///|
test "mpmath bulk si x=0.5" {
  assert_close_numeric(
    si(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.49310741804306668",
  )
}

///|
test "mpmath bulk si x=1" {
  assert_close_numeric(
    si(@mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.94608307036718301",
  )
}

///|
test "mpmath bulk si x=2" {
  assert_between(si(@mpf.RawMpf::from_int(2), 220, Nearest), "1.5", "1.7")
}

///|
test "mpmath bulk si x=3" {
  assert_between(si(@mpf.RawMpf::from_int(3), 220, Nearest), "1.7", "1.95")
}

///|
test "mpmath bulk si x=5" {
  assert_between(si(@mpf.RawMpf::from_int(5), 220, Nearest), "1.4", "1.7")
}

///|
test "mpmath bulk si x=50" {
  assert_close_numeric(
    si(@mpf.RawMpf::from_int(50), 220, Nearest),
    18,
    "1.55161707248593589",
  )
}

///|
test "mpmath bulk si infinities" {
  assert_between(si(@mpf.RawMpf::infinity(), 180, Nearest), "1.5", "1.7")
  assert_between(
    si(@mpf.RawMpf::negative_infinity(), 180, Nearest),
    "-1.7",
    "-1.5",
  )
}

///|
test "mpmath bulk ci x=0" {
  let c0 = ci(@mpf.RawMpf::zero(), 160, Nearest)
  assert_true(c0.is_infinite() && c0.sign == 1)
}

///|
test "mpmath bulk ci x=0.5" {
  assert_close_numeric(
    ci(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "-0.1777840788066129",
  )
}

///|
test "mpmath bulk ci x=1" {
  assert_close_numeric(
    ci(@mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.33740392290096813",
  )
}

///|
test "mpmath bulk ci x=2" {
  assert_close_numeric(
    ci(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.42298082877486499",
  )
}

///|
test "mpmath bulk ci x=3" {
  assert_close_numeric(
    ci(@mpf.RawMpf::from_int(3), 220, Nearest),
    18,
    "0.11962978600800032",
  )
}

///|
test "mpmath bulk ci x=5" {
  assert_close_numeric(
    ci(@mpf.RawMpf::from_int(5), 220, Nearest),
    18,
    "-0.1900297496566438",
  )
}

///|
test "mpmath bulk ci x=50" {
  assert_close_numeric(
    ci(@mpf.RawMpf::from_int(50), 220, Nearest),
    18,
    "-0.0056283863241163",
  )
}

///|
test "mpmath bulk ci x=1e10 small" {
  assert_small_abs(ci(@mpf.RawMpf::parse("1e10"), 240, Nearest), "1e-8")
}

///|
test "mpmath bulk ci infinity" {
  assert_true(ci(@mpf.RawMpf::infinity(), 180, Nearest) == @mpf.RawMpf::zero())
}

///|
test "mpmath bulk e1 special values" {
  let e0 = e1(@mpf.RawMpf::zero(), 180, Nearest)
  assert_true(e0.is_infinite() && e0.sign == 0)
  assert_true(e1(@mpf.RawMpf::infinity(), 180, Nearest) == @mpf.RawMpf::zero())
}

///|
test "mpmath bulk e1 positive points" {
  assert_close_numeric(
    e1(@mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.55977359477616081",
  )
  assert_close_numeric(
    e1(@mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.21938393439552027",
  )
  assert_close_numeric(
    e1(@mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.04890051070806111",
  )
}

///|
test "mpmath bulk expint n1 basic points" {
  assert_close_numeric(
    exponential_integral(1, @mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.55977359477616081",
  )
  assert_close_numeric(
    exponential_integral(1, @mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.21938393439552027",
  )
  assert_close_numeric(
    exponential_integral(1, @mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.04890051070806111",
  )
}

///|
test "mpmath bulk expint n2 basic points" {
  assert_true(
    exponential_integral(2, @mpf.RawMpf::zero(), 180, Nearest) ==
    @mpf.RawMpf::one(),
  )
  assert_close_numeric(
    exponential_integral(2, @mpf.RawMpf::parse("0.5"), 220, Nearest),
    18,
    "0.32664386232455301",
  )
  assert_close_numeric(
    exponential_integral(2, @mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.14849550677592204",
  )
}

///|
test "mpmath bulk expint n3 basic points" {
  assert_close_numeric(
    exponential_integral(3, @mpf.RawMpf::zero(), 220, Nearest),
    18,
    "0.5",
  )
  assert_close_numeric(
    exponential_integral(3, @mpf.RawMpf::from_int(1), 220, Nearest),
    18,
    "0.10969196719776013",
  )
  assert_close_numeric(
    exponential_integral(3, @mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.03013337979781589",
  )
}

///|
test "mpmath bulk expint n4 n5 points" {
  assert_close_numeric(
    exponential_integral(4, @mpf.RawMpf::from_int(2), 220, Nearest),
    18,
    "0.02502284121366030",
  )
  assert_close_numeric(
    exponential_integral(5, @mpf.RawMpf::parse("3.5"), 220, Nearest),
    18,
    "0.00379018173510554",
  )
}

///|
test "mpmath bulk expint high n points" {
  let a = exponential_integral(7, @mpf.RawMpf::parse("3.5"), 220, Nearest)
  let b = exponential_integral(10, @mpf.RawMpf::from_int(10), 240, Nearest)
  assert_true(a > @mpf.RawMpf::zero() && a < @mpf.RawMpf::parse("0.01"))
  assert_true(b > @mpf.RawMpf::zero() && b < @mpf.RawMpf::parse("0.01"))
}

///|
test "mpmath bulk gamma mode positive x" {
  assert_close_numeric(
    exponential_integral(1, @mpf.RawMpf::parse("0.5"), 220, Nearest, gamma=true),
    18,
    "0.60653065971263342",
  )
  assert_close_numeric(
    exponential_integral(2, @mpf.RawMpf::from_int(2), 220, Nearest, gamma=true),
    18,
    "0.40600584970983807",
  )
}

///|
test "mpmath bulk gamma mode negative x subset" {
  assert_true(
    exponential_integral(2, @mpf.RawMpf::from_int(-1), 180, Nearest, gamma=true) ==
    @mpf.RawMpf::zero(),
  )
  assert_between(
    exponential_integral(3, @mpf.RawMpf::from_int(-1), 220, Nearest, gamma=true),
    "2",
    "3",
  )
}
