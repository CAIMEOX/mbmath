///|
fn i(n : Int) -> @mpf.RawMpf {
  @mpf.RawMpf::from_int(n)
}

///|
fn interval(a : Int, b : Int) -> RawMpi {
  RawMpi::new(i(a), i(b))
}

///|
fn assert_mpi_eq(x : RawMpi, lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> Unit raise {
  assert_true(x.lo == lo)
  assert_true(x.hi == hi)
}

///|
fn assert_contains(x : RawMpi, v : @mpf.RawMpf) -> Unit raise {
  assert_true(x.lo <= v)
  assert_true(x.hi >= v)
}

///|
fn dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    64
  } else {
    dps * 4 + 64
  }
}

///|
fn strip_spaces_for_numeric(s : StringView) -> String {
  let out = StringBuilder(size_hint=s.length())
  for c in s {
    if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
      out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn substring_for_numeric(s : StringView, start : Int, end : Int) -> String {
  if start >= end {
    ""
  } else {
    s.view(start_offset=start, end_offset=end).to_owned()
  }
}

///|
fn assert_numeric_close_mpf(
  got_mpf : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = dps_to_prec(dps)
  let safe_dps = if dps < 1 { 1 } else { dps }
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = got_mpf.sub(expected, prec, Nearest).abs(prec, Nearest)
  let tol = @mpf.RawMpf::parse("1e-\{safe_dps}", prec~, rnd=Nearest)
  if !(err <= tol) {
    fail(
      "numeric mismatch got=\{got_mpf.format(dps=safe_dps + 4)} expected=\{expected_text} err=\{err.format(dps=8)} tol=\{tol.format(dps=8)}",
    )
  }
}

///|
fn assert_numeric_close_text(
  got_text : String,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = dps_to_prec(dps)
  let text = strip_spaces_for_numeric(got_text)
  let mut end = 0
  while end < text.length() {
    guard text.get_char(end) is Some(c) else {
      fail("invalid character boundary in numeric text: \{got_text}")
    }
    if (c >= '0' && c <= '9') ||
      c == '+' ||
      c == '-' ||
      c == '.' ||
      c == 'e' ||
      c == 'E' {
      end += 1
    } else {
      break
    }
  }
  if end == 0 {
    fail("numeric prefix not found: \{got_text}")
  }
  let got_prefix = substring_for_numeric(text, 0, end)
  let got_mpf = @mpf.RawMpf::parse(got_prefix, prec~, rnd=Nearest)
  assert_numeric_close_mpf(got_mpf, expected_text, dps)
}

///|
test "mpi_make and comparisons" {
  assert_mpi_eq(RawMpi::new(i(3), i(1)), i(1), i(3))
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::nan(), i(2)),
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  )
  let a = interval(1, 2)
  let b = interval(3, 4)
  assert_true(a == interval(1, 2))
  assert_true(a != b)
  assert_true(a.strictly_less_than(b))
  assert_true(a.less_or_equal(b))
  assert_true(b.strictly_greater_than(a))
  assert_true(b.greater_or_equal(a))
  assert_false(a.overlaps(b))
  assert_true(a.overlaps(interval(2, 3)))
}

///|
test "panic mpi_lt overlapping intervals" {
  ignore(interval(1, 3).strictly_less_than(interval(2, 4)))
}

///|
test "panic mpi_le overlapping intervals" {
  ignore(interval(1, 3).less_or_equal(interval(2, 4)))
}

///|
test "mpi add sub mul div" {
  let a = interval(1, 2)
  let b = interval(3, 4)
  assert_mpi_eq(a.add(b), i(4), i(6))
  assert_mpi_eq(a.sub(b), i(-3), i(-1))
  assert_mpi_eq(interval(2, 3).mul(interval(-5, -4)), i(-15), i(-8))
  assert_mpi_eq(interval(-2, 3).mul(interval(4, 5)), i(-10), i(15))
  assert_mpi_eq(interval(4, 8).div(interval(2, 4), 80), i(1), i(4))
  assert_mpi_eq(
    interval(1, 2).div(interval(-1, 1), 80),
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  )
}

///|
test "mpi unary and metrics" {
  assert_mpi_eq(interval(-2, 3).rounded(40), i(-2), i(3))
  assert_mpi_eq(interval(-2, 3).negated(), i(-3), i(2))
  assert_mpi_eq(interval(-3, -2).abs(), i(2), i(3))
  assert_mpi_eq(interval(-2, 5).abs(), i(0), i(5))
  @debug.assert_eq(interval(2, 6).width(80), i(4))
  @debug.assert_eq(interval(2, 6).midpoint(80), i(4))
}

///|
test "mpi elementary monotone functions" {
  let e = interval(1, 1).exp(120)
  assert_true(e.lo <= @mpf.RawMpf::parse("2.71828182846"))
  assert_true(e.hi >= @mpf.RawMpf::parse("2.71828182845"))
  assert_mpi_eq(interval(1, 1).log(120), i(0), i(0))
  assert_mpi_eq(interval(4, 9).sqrt(80), i(2), i(3))
  let a = interval(0, 1).atan(120)
  @debug.assert_eq(a.lo, i(0))
  assert_true(a.hi <= @mpf.RawMpf::parse("0.785398163398"))
  assert_true(a.hi >= @mpf.RawMpf::parse("0.785398163397"))
  let p = RawMpi::pi(120)
  assert_true(p.lo <= @mpf.RawMpf::parse("3.14159265359"))
  assert_true(p.hi >= @mpf.RawMpf::parse("3.14159265358"))
}

///|
test "mpi pow_int" {
  assert_mpi_eq(interval(2, 3).pow_int(2, 80), i(4), i(9))
  assert_mpi_eq(interval(-3, -2).pow_int(2, 80), i(4), i(9))
  assert_mpi_eq(interval(-2, 3).pow_int(2, 80), i(0), i(9))
  assert_mpi_eq(
    interval(2, 4).pow_int(-1, 80),
    @mpf.RawMpf::parse("0.25"),
    @mpf.RawMpf::parse("0.5"),
  )
}

///|
test "mpi pow and to_str" {
  assert_mpi_eq(interval(2, 2).pow(interval(3, 3), 80), i(8), i(8))
  let half = @mpf.RawMpf::parse("0.5")
  assert_mpi_eq(interval(4, 4).pow(RawMpi::new(half, half), 80), i(2), i(2))
  assert_mpi_eq(interval(2, 3).pow(RawMpi::zero(), 80), i(1), i(1))
  let s = interval(1, 2).format()
  @debug.assert_eq(s.get_char(0), Some('['))
  @debug.assert_eq(s.get_char(1), Some('1'))
  assert_true(s.contains(","))
}

///|
test "mpi_from_str variants" {
  let one_twenty_five = RawMpi::parse("1.25")
  if !(one_twenty_five.lo <= @mpf.RawMpf::parse("1.25") &&
    one_twenty_five.hi >= @mpf.RawMpf::parse("1.25")) {
    fail("mpi_from_str single literal containment failed")
  }
  assert_mpi_eq(RawMpi::parse("1.5 +- 0.5"), i(1), i(2))
  let pct = RawMpi::parse("1.5 (33.33333333333333333333333333333%)", prec=53)
  if !(pct.lo <= i(1) && pct.hi >= i(1)) {
    fail("mpi_from_str percent lower containment failed")
  }
  if !(pct.lo <= i(2) && pct.hi >= i(2)) {
    fail("mpi_from_str percent upper containment failed")
  }
  assert_mpi_eq(RawMpi::parse("[1,2]"), i(1), i(2))
  assert_mpi_eq(RawMpi::parse("1[2,3]"), i(12), i(13))
  assert_mpi_eq(
    RawMpi::parse("1.[23,46]e-8"),
    @mpf.RawMpf::parse("1.23e-8", prec=256, rnd=Floor),
    @mpf.RawMpf::parse("1.46e-8", prec=256, rnd=Ceiling),
  )
  assert_mpi_eq(
    RawMpi::parse("12[3.4,5.9]e4"),
    @mpf.RawMpf::parse("123.4e4", prec=256, rnd=Floor),
    @mpf.RawMpf::parse("125.9e4", prec=256, rnd=Ceiling),
  )
}

///|
test "mpi_to_str_opts modes" {
  let x = interval(1, 2)
  @debug.assert_eq(x.format_with(dps=2, mode="plusminus"), "1.5 +- 0.5")
  assert_numeric_close_text(x.format_with(dps=2, mode="percent"), "1.5", 2)
  @debug.assert_eq(x.format_with(dps=2, mode="brackets"), "[1.0, 2.0]")
  @debug.assert_eq(
    x.format_with(dps=2, mode="brackets", use_spaces=false),
    "[1.0,2.0]",
  )
  @debug.assert_eq(
    x.format_with(dps=2, mode="brackets", left_bracket="<", right_bracket=">"),
    "<1.0, 2.0>",
  )
  let y = RawMpi::new(
    @mpf.RawMpf::parse("5.2582327113062393041"),
    @mpf.RawMpf::parse("5.2582327113062749951"),
  )
  let diff = y.format_with(dps=15, mode="diff")
  assert_numeric_close_text(diff, "5.2582327113062", 13)
  assert_true(diff.contains("["))
  assert_true(diff.contains(","))
  let exp_diff = RawMpi::parse("[1e123, 1e129]").format_with(
    dps=30,
    mode="diff",
  )
  @debug.assert_eq(exp_diff, "[1.0e+123, 1.0e+129]")
  let s = interval(1, 2).format_at_precision(80)
  @debug.assert_eq(s.get_char(0), Some('['))
  assert_true(s.contains(","))
}

///|
test "panic mpi_to_str_opts unknown mode" {
  ignore(interval(1, 2).format_with(mode="unknown"))
}

///|
test "mpi trig subset" {
  let (c0, s0) = interval(0, 0).cos_sin(120)
  assert_mpi_eq(c0, i(1), i(1))
  assert_mpi_eq(s0, i(0), i(0))
  let pi = @libelefun.pi(120, Nearest)
  let (c1, s1) = RawMpi::new(@mpf.RawMpf::zero(), pi).cos_sin(120)
  assert_contains(c1, @mpf.RawMpf::one())
  assert_contains(c1, @mpf.RawMpf::negative_one())
  assert_true(s1.lo <= @mpf.RawMpf::zero())
  assert_true(s1.hi >= @mpf.RawMpf::one())
  let t = RawMpi::new(@mpf.RawMpf::parse("1.4"), @mpf.RawMpf::parse("1.7")).tan(
    80,
  )
  @debug.assert_eq(t.lo, @mpf.RawMpf::negative_infinity())
  @debug.assert_eq(t.hi, @mpf.RawMpf::infinity())
  let cot = RawMpi::new(@mpf.RawMpf::parse("-0.1"), @mpf.RawMpf::parse("0.1")).cot(
    80,
  )
  @debug.assert_eq(cot.lo, @mpf.RawMpf::negative_infinity())
  @debug.assert_eq(cot.hi, @mpf.RawMpf::infinity())
  let c = interval(0, 0).cos(80)
  let s = interval(0, 0).sin(80)
  assert_mpi_eq(c, i(1), i(1))
  assert_mpi_eq(s, i(0), i(0))
}

///|
test "mpi shift cosh_sinh atan2 subset" {
  assert_mpi_eq(interval(1, 2).scale_pow2(1), i(2), i(4))
  let (ch, sh) = interval(0, 0).cosh_sinh(120)
  assert_mpi_eq(ch, i(1), i(1))
  assert_mpi_eq(sh, i(0), i(0))
  assert_mpi_eq(interval(0, 0).atan2(interval(2, 3), 120), i(0), i(0))
  let pi = @libelefun.pi(120, Nearest)
  let arg_neg = interval(0, 0).atan2(interval(-3, -2), 120)
  assert_contains(arg_neg, pi)
  let arg_full = interval(-1, 1).atan2(interval(-1, 1), 120)
  assert_contains(arg_full, pi)
  assert_contains(arg_full, pi.negated(0, Down))
}

///|
test "mpi gamma family subset and pole behavior" {
  let g = interval(2, 3).gamma(160)
  assert_contains(g, @gammazeta.gamma(@mpf.RawMpf::parse("2.2"), 160, Nearest))
  assert_contains(g, @gammazeta.gamma(@mpf.RawMpf::parse("2.8"), 160, Nearest))
  let rg = interval(2, 3).rgamma(160)
  assert_contains(
    rg,
    @gammazeta.rgamma(@mpf.RawMpf::parse("2.2"), 160, Nearest),
  )
  assert_contains(
    rg,
    @gammazeta.rgamma(@mpf.RawMpf::parse("2.8"), 160, Nearest),
  )
  let lg = interval(2, 3).loggamma(160)
  assert_contains(
    lg,
    @gammazeta.loggamma(@mpf.RawMpf::parse("2.2"), 160, Nearest),
  )
  assert_contains(
    lg,
    @gammazeta.loggamma(@mpf.RawMpf::parse("2.8"), 160, Nearest),
  )
  let fac = interval(2, 3).factorial(160)
  assert_contains(
    fac,
    @gammazeta.gamma(@mpf.RawMpf::parse("3.2"), 160, Nearest),
  )
  assert_contains(
    fac,
    @gammazeta.gamma(@mpf.RawMpf::parse("3.8"), 160, Nearest),
  )
  let pole = RawMpi::new(@mpf.RawMpf::parse("-0.2"), @mpf.RawMpf::parse("0.2")).gamma(
    160,
  )
  @debug.assert_eq(pole.lo, @mpf.RawMpf::negative_infinity())
  @debug.assert_eq(pole.hi, @mpf.RawMpf::infinity())
  let rg_pole = RawMpi::new(
    @mpf.RawMpf::parse("-0.2"),
    @mpf.RawMpf::parse("0.2"),
  ).rgamma(160)
  assert_contains(rg_pole, @mpf.RawMpf::zero())
}

///|
test "mpi gamma scalar identity subset from mpmath interval tests" {
  assert_mpi_eq(
    interval(0, 0).rgamma(180),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::zero(),
  )
  assert_mpi_eq(
    interval(0, 0).factorial(180),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    interval(1, 1).factorial(180),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    interval(2, 2).factorial(180),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(2),
  )
  assert_mpi_eq(
    interval(3, 3).factorial(180),
    @mpf.RawMpf::from_int(6),
    @mpf.RawMpf::from_int(6),
  )
  assert_mpi_eq(
    interval(0, 0).gamma(180),
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    interval(1, 1).gamma(180),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    interval(2, 2).gamma(180),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    interval(3, 3).gamma(180),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(2),
  )
  let minus_half = @mpf.RawMpf::parse("-0.5", prec=240, rnd=Nearest)
  let gamma_mhalf = RawMpi::new(minus_half, minus_half).gamma(220)
  assert_numeric_close_mpf(gamma_mhalf.midpoint(220), "-3.544907701811", 12)
  assert_mpi_eq(
    interval(1, 1).loggamma(180),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::zero(),
  )
  assert_mpi_eq(
    interval(2, 2).loggamma(180),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::zero(),
  )
  let lg3 = interval(3, 3).loggamma(220)
  assert_numeric_close_mpf(lg3.midpoint(220), "0.6931471805599", 13)
}

///|
test "mpi nstr parity subset from mpmath interval tests" {
  let n = 30
  let x = interval(1, 2)
  @debug.assert_eq(
    x.format_with(dps=n, mode="plusminus", error_dps=6),
    "1.5 +- 0.5",
  )
  @debug.assert_eq(
    x.format_with(dps=n, mode="plusminus", use_spaces=false, error_dps=6),
    "1.5+-0.5",
  )
  @debug.assert_eq(x.format_with(dps=n, mode="percent"), "1.5 (33.33%)")
  @debug.assert_eq(
    x.format_with(dps=n, mode="brackets", use_spaces=false),
    "[1.0,2.0]",
  )
  @debug.assert_eq(
    x.format_with(dps=n, mode="brackets", left_bracket="<", right_bracket=">"),
    "<1.0, 2.0>",
  )
  let y = RawMpi::new(
    @mpf.RawMpf::parse("5.2582327113062393041", prec=120, rnd=Floor),
    @mpf.RawMpf::parse("5.2582327113062749951", prec=120, rnd=Ceiling),
  )
  @debug.assert_eq(
    y.format_with(dps=n, mode="diff"),
    "5.2582327113062[393041, 749951]",
  )
}

///|
test "mpi mul/div edge parity subset from mpmath interval tests" {
  let m1 = interval(-1, 0).mul(RawMpi::point(@mpf.RawMpf::infinity()))
  if !(m1.lo == @mpf.RawMpf::negative_infinity() && m1.hi == @mpf.RawMpf::zero()) {
    fail("mul [-1,0]*[inf,inf] mismatch: \{m1.format(dps=20)}")
  }
  let m2 = interval(0, 1).mul(RawMpi::point(@mpf.RawMpf::infinity()))
  if !(m2.lo == @mpf.RawMpf::zero() && m2.hi == @mpf.RawMpf::infinity()) {
    fail("mul [0,1]*[inf,inf] mismatch: \{m2.format(dps=20)}")
  }
  let m3 = interval(-1, 1).mul(RawMpi::point(@mpf.RawMpf::infinity()))
  if !(m3.lo == @mpf.RawMpf::negative_infinity() &&
    m3.hi == @mpf.RawMpf::infinity()) {
    fail("mul [-1,1]*[inf,inf] mismatch: \{m3.format(dps=20)}")
  }
  let d1 = interval(0, 1).div(interval(0, 1), 120)
  if !(d1.lo == @mpf.RawMpf::zero() && d1.hi == @mpf.RawMpf::infinity()) {
    fail("div [0,1]/[0,1] mismatch: \{d1.format(dps=20)}")
  }
  let d2 = interval(1, 2).div(
    RawMpi::new(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity()),
    120,
  )
  if !(d2.lo == @mpf.RawMpf::zero() && d2.hi == @mpf.RawMpf::infinity()) {
    fail("div [1,2]/[0,inf] mismatch: \{d2.format(dps=20)}")
  }
  let d3 = interval(-1, 0).div(
    RawMpi::new(@mpf.RawMpf::zero(), @mpf.RawMpf::one()),
    120,
  )
  if !(d3.lo == @mpf.RawMpf::negative_infinity() && d3.hi == @mpf.RawMpf::zero()) {
    fail("div [-1,0]/[0,1] mismatch: \{d3.format(dps=20)}")
  }
  let d4 = interval(-1, 0).div(
    RawMpi::new(@mpf.RawMpf::negative_one(), @mpf.RawMpf::zero()),
    120,
  )
  if !(d4.lo == @mpf.RawMpf::zero() && d4.hi == @mpf.RawMpf::infinity()) {
    fail("div [-1,0]/[-1,0] mismatch: \{d4.format(dps=20)}")
  }
}

///|
test "mpi pow with infinite exponent subset from mpmath interval tests" {
  assert_mpi_eq(
    interval(0, 1).pow(RawMpi::point(@mpf.RawMpf::infinity()), 160),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    interval(0, 1).pow(RawMpi::point(@mpf.RawMpf::negative_infinity()), 160),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity()).pow(
      RawMpi::point(@mpf.RawMpf::infinity()),
      160,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity()).pow(
      RawMpi::point(@mpf.RawMpf::negative_infinity()),
      160,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::one(), @mpf.RawMpf::infinity()).pow(
      RawMpi::point(@mpf.RawMpf::infinity()),
      160,
    ),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::one(), @mpf.RawMpf::infinity()).pow(
      RawMpi::point(@mpf.RawMpf::negative_infinity()),
      160,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::one(),
  )
}

///|
test "mpi trigonometric numeric parity subset from mpmath interval tests" {
  let p = 53
  let c01 = interval(0, 1).cos(p)
  assert_true(c01.lo <= @mpf.RawMpf::parse("0.54030230586813965399"))
  assert_true(c01.hi >= @mpf.RawMpf::one())
  let s01 = interval(0, 1).sin(p)
  assert_true(s01.lo <= @mpf.RawMpf::zero())
  assert_true(s01.hi >= @mpf.RawMpf::parse("0.8414709848078966159"))
  let c12 = interval(1, 2).cos(p)
  assert_true(c12.lo <= @mpf.RawMpf::parse("-0.4161468365471424069"))
  assert_true(c12.hi >= @mpf.RawMpf::parse("0.54030230586813976501"))
  let s12 = interval(1, 2).sin(p)
  assert_true(s12.lo <= @mpf.RawMpf::parse("0.84147098480789650488"))
  assert_true(s12.hi >= @mpf.RawMpf::one())
  assert_mpi_eq(
    RawMpi::new(i(2), @mpf.RawMpf::infinity()).cos(120),
    @mpf.RawMpf::negative_one(),
    @mpf.RawMpf::one(),
  )
  assert_mpi_eq(
    RawMpi::new(i(2), @mpf.RawMpf::infinity()).sin(120),
    @mpf.RawMpf::negative_one(),
    @mpf.RawMpf::one(),
  )
  let t = RawMpi::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::parse("1.0")).tan(
    180,
  )
  assert_contains(t, @libelefun.tan(@mpf.RawMpf::parse("0.5"), 180, Nearest))
  assert_contains(t, @libelefun.tan(@mpf.RawMpf::parse("1.0"), 180, Nearest))
}

///|
test "mpi div matrix extended subset from mpmath interval tests" {
  let half = @mpf.RawMpf::parse("0.5")
  let quarter = @mpf.RawMpf::parse("0.25")
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).div(
      RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).div(
      RawMpi::new(i(2), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).div(
      interval(2, 2),
      120,
    ),
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity()).div(
      RawMpi::new(i(2), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    RawMpi::new(i(2), @mpf.RawMpf::infinity()).div(interval(2, 2), 120),
    @mpf.RawMpf::one(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(
    interval(-4, 8).div(
      RawMpi::new(@mpf.RawMpf::one(), @mpf.RawMpf::infinity()),
      120,
    ),
    i(-4),
    i(8),
  )
  assert_mpi_eq(
    interval(-4, 8).div(RawMpi::new(half, @mpf.RawMpf::infinity()), 120),
    i(-8),
    i(16),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::negative_infinity(), i(8)).div(
      RawMpi::new(half, @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::negative_infinity(),
    i(16),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::zero(), i(8)).div(
      RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::zero(),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero()).div(
      RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::zero(),
  )
  assert_mpi_eq(
    RawMpi::new(i(8), @mpf.RawMpf::infinity()).div(
      RawMpi::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()),
      120,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::infinity(),
  )
  assert_mpi_eq(interval(-1, 2).div(interval(-2, -1), 120), i(-2), i(1))
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::parse("-0.5"), @mpf.RawMpf::parse("-0.25")).div(
      interval(0, 1),
      120,
    ),
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::parse("-0.25"),
  )
  assert_mpi_eq(
    RawMpi::new(@mpf.RawMpf::parse("-0.5"), @mpf.RawMpf::parse("-0.25")).div(
      RawMpi::new(half, @mpf.RawMpf::one()),
      120,
    ),
    @mpf.RawMpf::parse("-1.0"),
    @mpf.RawMpf::parse("-0.25"),
  )
  assert_mpi_eq(
    RawMpi::new(half, i(4)).div(RawMpi::new(half, @mpf.RawMpf::one()), 120),
    half,
    i(8),
  )
  assert_mpi_eq(
    RawMpi::new(i(-4), @mpf.RawMpf::parse("-0.5")).div(
      RawMpi::new(i(-2), @mpf.RawMpf::parse("-0.5")),
      120,
    ),
    quarter,
    i(8),
  )
}

///|
test "mpi trig large-argument parity subset from mpmath interval tests" {
  let huge = @mpf.RawMpf::parse("4e50", prec=320, rnd=Nearest)
  let half = @mpf.RawMpf::parse("0.5")
  let p_list = [15, 40, 80]
  for p in p_list {
    let pi_iv = RawMpi::pi(p + 80)
    let arg4pi = RawMpi::point(i(4)).mul(pi_iv, prec=p + 80)
    assert_contains(arg4pi.sin(p + 80), @mpf.RawMpf::zero())
    assert_contains(arg4pi.cos(p + 80), @mpf.RawMpf::one())
    let arg_big = RawMpi::point(huge).mul(pi_iv, prec=p + 80)
    assert_contains(arg_big.sin(p + 80), @mpf.RawMpf::zero())
    assert_contains(arg_big.cos(p + 80), @mpf.RawMpf::one())
    let w = RawMpi::point(huge).add(RawMpi::point(half))
    let arg_w = w.mul(pi_iv, prec=p + 80)
    assert_contains(arg_w.cos(p + 80), @mpf.RawMpf::zero())
  }
}

///|
test "mpi nstr and convert boundary subset from mpmath interval tests" {
  let n = 30
  let cos_diff = interval(1, 1)
    .cos(140)
    .format_with(dps=n, mode="diff", use_spaces=false)
  assert_numeric_close_text(cos_diff, "0.540302305868139", 15)
  assert_true(cos_diff.contains("["))
  assert_true(cos_diff.contains("]"))
  let exp_diff = RawMpi::parse("5000.1")
    .exp(260)
    .format_with(dps=n, mode="diff")
  assert_true(exp_diff.contains("["))
  assert_true(exp_diff.contains("]"))
  assert_true(exp_diff.contains("e+2171"))
  assert_mpi_eq(RawMpi::parse(" [ 1 , 2 ] "), i(1), i(2))
  assert_mpi_eq(
    RawMpi::parse("0 (33.3%)"),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::zero(),
  )
}

///|
test "mpi trig pi-grid sanity subset from mpmath interval tests" {
  let p = 220
  let pi_iv = RawMpi::pi(p + 40)
  let half_iv = RawMpi::point(@mpf.RawMpf::parse("0.5"))
  let odd_ns : Array[Int] = [-5, -3, -1, 1, 3, 5]
  for n in odd_ns {
    let n_iv = RawMpi::point(@mpf.RawMpf::from_int(n))
    let arg_n = n_iv.mul(pi_iv, prec=p + 40)
    let c = arg_n.cos(p)
    assert_contains(c, @mpf.RawMpf::negative_one())
    assert_false(
      c.lo == @mpf.RawMpf::negative_one() && c.hi == @mpf.RawMpf::negative_one(),
    )
    let n_half_iv = n_iv.add(half_iv)
    let arg_half = n_half_iv.mul(pi_iv, prec=p + 40)
    let s = arg_half.sin(p)
    assert_contains(s, @mpf.RawMpf::negative_one())
    assert_false(
      s.lo == @mpf.RawMpf::negative_one() && s.hi == @mpf.RawMpf::negative_one(),
    )
  }
  let even_ns : Array[Int] = [-6, -4, -2, 0, 2, 4, 6]
  for n in even_ns {
    let n_iv = RawMpi::point(@mpf.RawMpf::from_int(n))
    let arg_n = n_iv.mul(pi_iv, prec=p + 40)
    let c = arg_n.cos(p)
    assert_contains(c, @mpf.RawMpf::one())
    if n != 0 {
      assert_false(c.lo == @mpf.RawMpf::one() && c.hi == @mpf.RawMpf::one())
    }
    let n_half_iv = n_iv.add(half_iv)
    let arg_half = n_half_iv.mul(pi_iv, prec=p + 40)
    let s = arg_half.sin(p)
    assert_contains(s, @mpf.RawMpf::one())
    assert_false(s.lo == @mpf.RawMpf::one() && s.hi == @mpf.RawMpf::one())
  }
  let all_ns : Array[Int] = [-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6]
  for n in all_ns {
    let n_iv = RawMpi::point(@mpf.RawMpf::from_int(n))
    let n_half_iv = n_iv.add(half_iv)
    let c_half = n_half_iv.mul(pi_iv, prec=p + 40).cos(p)
    assert_true(c_half.lo < @mpf.RawMpf::zero())
    assert_true(c_half.hi > @mpf.RawMpf::zero())
    let s_n = n_iv.mul(pi_iv, prec=p + 40).sin(p)
    if n == 0 {
      assert_contains(s_n, @mpf.RawMpf::zero())
    } else {
      assert_true(s_n.lo < @mpf.RawMpf::zero())
      assert_true(s_n.hi > @mpf.RawMpf::zero())
    }
  }
}

///|
test "mpi nstr and convert edge extras from mpmath interval tests" {
  @debug.assert_eq(
    RawMpi::zero().format_with(dps=2, mode="percent"),
    "0.0 (0.0%)",
  )
  let s = RawMpi::point(@mpf.RawMpf::from_int(1))
    .cos(220)
    .format_with(dps=30, mode="diff", use_spaces=false)
  assert_numeric_close_text(s, "0.540302305868139", 15)
  assert_true(s.contains("["))
  assert_true(s.contains("]"))
  assert_mpi_eq(RawMpi::parse(" 1.5 +- 0.5 "), i(1), i(2))
  assert_mpi_eq(
    RawMpi::parse(" 1.[23,46]e-8 "),
    @mpf.RawMpf::parse("1.23e-8", prec=256, rnd=Floor),
    @mpf.RawMpf::parse("1.46e-8", prec=256, rnd=Ceiling),
  )
}
