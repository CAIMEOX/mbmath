///|
fn i(n : Int) -> @mpf.RawMpf {
  @mpf.from_int(n)
}

///|
fn interval(a : Int, b : Int) -> RawMpi {
  mpi_make(i(a), i(b))
}

///|
fn assert_mpi_eq(x : RawMpi, lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> Unit raise {
  assert_true(@mpf.mpf_eq(x.lo, lo))
  assert_true(@mpf.mpf_eq(x.hi, hi))
}

///|
fn assert_contains(x : RawMpi, v : @mpf.RawMpf) -> Unit raise {
  assert_true(@mpf.mpf_le(x.lo, v))
  assert_true(@mpf.mpf_ge(x.hi, v))
}

///|
test "mpi_make and comparisons" {
  assert_mpi_eq(mpi_make(i(3), i(1)), i(1), i(3))
  assert_mpi_eq(mpi_make(@mpf.fnan, i(2)), @mpf.fninf, @mpf.finf)
  let a = interval(1, 2)
  let b = interval(3, 4)
  assert_true(mpi_eq(a, interval(1, 2)))
  assert_true(mpi_ne(a, b))
  assert_true(mpi_lt(a, b))
  assert_true(mpi_le(a, b))
  assert_true(mpi_gt(b, a))
  assert_true(mpi_ge(b, a))
  assert_false(mpi_overlap(a, b))
  assert_true(mpi_overlap(a, interval(2, 3)))
}

///|
test "panic mpi_lt overlapping intervals" {
  ignore(mpi_lt(interval(1, 3), interval(2, 4)))
}

///|
test "panic mpi_le overlapping intervals" {
  ignore(mpi_le(interval(1, 3), interval(2, 4)))
}

///|
test "mpi add sub mul div" {
  let a = interval(1, 2)
  let b = interval(3, 4)
  assert_mpi_eq(mpi_add(a, b), i(4), i(6))
  assert_mpi_eq(mpi_sub(a, b), i(-3), i(-1))
  assert_mpi_eq(mpi_mul(interval(2, 3), interval(-5, -4)), i(-15), i(-8))
  assert_mpi_eq(mpi_mul(interval(-2, 3), interval(4, 5)), i(-10), i(15))
  assert_mpi_eq(mpi_div(interval(4, 8), interval(2, 4), 80), i(1), i(4))
  assert_mpi_eq(
    mpi_div(interval(1, 2), interval(-1, 1), 80),
    @mpf.fninf,
    @mpf.finf,
  )
}

///|
test "mpi unary and metrics" {
  assert_mpi_eq(mpi_pos(interval(-2, 3), 40), i(-2), i(3))
  assert_mpi_eq(mpi_neg(interval(-2, 3)), i(-3), i(2))
  assert_mpi_eq(mpi_abs(interval(-3, -2)), i(2), i(3))
  assert_mpi_eq(mpi_abs(interval(-2, 5)), i(0), i(5))
  assert_eq(mpi_delta(interval(2, 6), 80), i(4))
  assert_eq(mpi_mid(interval(2, 6), 80), i(4))
}

///|
test "mpi elementary monotone functions" {
  let e = mpi_exp(interval(1, 1), 120)
  assert_true(@mpf.mpf_le(e.lo, @mpf.from_str("2.71828182846")))
  assert_true(@mpf.mpf_ge(e.hi, @mpf.from_str("2.71828182845")))
  assert_mpi_eq(mpi_log(interval(1, 1), 120), i(0), i(0))
  assert_mpi_eq(mpi_sqrt(interval(4, 9), 80), i(2), i(3))
  let a = mpi_atan(interval(0, 1), 120)
  assert_eq(a.lo, i(0))
  assert_true(@mpf.mpf_le(a.hi, @mpf.from_str("0.785398163398")))
  assert_true(@mpf.mpf_ge(a.hi, @mpf.from_str("0.785398163397")))
  let p = mpi_pi(120)
  assert_true(@mpf.mpf_le(p.lo, @mpf.from_str("3.14159265359")))
  assert_true(@mpf.mpf_ge(p.hi, @mpf.from_str("3.14159265358")))
}

///|
test "mpi pow_int" {
  assert_mpi_eq(mpi_pow_int(interval(2, 3), 2, 80), i(4), i(9))
  assert_mpi_eq(mpi_pow_int(interval(-3, -2), 2, 80), i(4), i(9))
  assert_mpi_eq(mpi_pow_int(interval(-2, 3), 2, 80), i(0), i(9))
  assert_mpi_eq(
    mpi_pow_int(interval(2, 4), -1, 80),
    @mpf.from_str("0.25"),
    @mpf.from_str("0.5"),
  )
}

///|
test "mpi pow and to_str" {
  assert_mpi_eq(mpi_pow(interval(2, 2), interval(3, 3), 80), i(8), i(8))
  let half = @mpf.from_str("0.5")
  assert_mpi_eq(mpi_pow(interval(4, 4), mpi_make(half, half), 80), i(2), i(2))
  assert_mpi_eq(mpi_pow(interval(2, 3), mpi_zero, 80), i(1), i(1))
  let s = mpi_to_str(interval(1, 2))
  assert_true(s.has_prefix("[1"))
  assert_true(s.contains(","))
}

///|
test "mpi_from_str variants" {
  let one_twenty_five = mpi_from_str("1.25")
  if !(@mpf.mpf_le(one_twenty_five.lo, @mpf.from_str("1.25")) &&
    @mpf.mpf_ge(one_twenty_five.hi, @mpf.from_str("1.25"))) {
    fail("mpi_from_str single literal containment failed")
  }
  assert_mpi_eq(mpi_from_str("1.5 +- 0.5"), i(1), i(2))
  let pct = mpi_from_str("1.5 (33.33333333333333333333333333333%)", prec=53)
  if !(@mpf.mpf_le(pct.lo, i(1)) && @mpf.mpf_ge(pct.hi, i(1))) {
    fail("mpi_from_str percent lower containment failed")
  }
  if !(@mpf.mpf_le(pct.lo, i(2)) && @mpf.mpf_ge(pct.hi, i(2))) {
    fail("mpi_from_str percent upper containment failed")
  }
  assert_mpi_eq(mpi_from_str("[1,2]"), i(1), i(2))
  assert_mpi_eq(mpi_from_str("1[2,3]"), i(12), i(13))
  assert_mpi_eq(
    mpi_from_str("1.[23,46]e-8"),
    @mpf.from_str("1.23e-8", prec=256, rnd=@mpf.round_floor),
    @mpf.from_str("1.46e-8", prec=256, rnd=@mpf.round_ceiling),
  )
  assert_mpi_eq(
    mpi_from_str("12[3.4,5.9]e4"),
    @mpf.from_str("123.4e4", prec=256, rnd=@mpf.round_floor),
    @mpf.from_str("125.9e4", prec=256, rnd=@mpf.round_ceiling),
  )
}

///|
test "mpi_to_str_opts modes" {
  let x = interval(1, 2)
  assert_eq(mpi_to_str_opts(x, dps=2, mode="plusminus"), "1.5 +- 0.5")
  assert_true(
    mpi_to_str_opts(x, dps=2, mode="percent").has_prefix("1.5 (33.33"),
  )
  assert_eq(mpi_to_str_opts(x, dps=2, mode="brackets"), "[1.0, 2.0]")
  assert_eq(
    mpi_to_str_opts(x, dps=2, mode="brackets", use_spaces=false),
    "[1.0,2.0]",
  )
  assert_eq(
    mpi_to_str_opts(
      x,
      dps=2,
      mode="brackets",
      left_bracket="<",
      right_bracket=">",
    ),
    "<1.0, 2.0>",
  )
  let y = mpi_make(
    @mpf.from_str("5.2582327113062393041"),
    @mpf.from_str("5.2582327113062749951"),
  )
  let diff = mpi_to_str_opts(y, dps=15, mode="diff")
  assert_true(diff.has_prefix("5.2582327113062"))
  assert_true(diff.contains("["))
  assert_true(diff.contains(","))
  let exp_diff = mpi_to_str_opts(
    mpi_from_str("[1e123, 1e129]"),
    dps=30,
    mode="diff",
  )
  assert_eq(exp_diff, "[1.0e+123, 1.0e+129]")
  let s = mpi_str(interval(1, 2), 80)
  assert_true(s.has_prefix("["))
  assert_true(s.contains(","))
}

///|
test "panic mpi_to_str_opts unknown mode" {
  ignore(mpi_to_str_opts(interval(1, 2), mode="unknown"))
}

///|
test "mpi trig subset" {
  let (c0, s0) = mpi_cos_sin(interval(0, 0), 120)
  assert_mpi_eq(c0, i(1), i(1))
  assert_mpi_eq(s0, i(0), i(0))
  let pi = @libelefun.mpf_pi(120, @mpf.round_nearest)
  let (c1, s1) = mpi_cos_sin(mpi_make(@mpf.fzero, pi), 120)
  assert_contains(c1, @mpf.fone)
  assert_contains(c1, @mpf.fnone)
  assert_true(@mpf.mpf_le(s1.lo, @mpf.fzero))
  assert_true(@mpf.mpf_ge(s1.hi, @mpf.fone))
  let t = mpi_tan(mpi_make(@mpf.from_str("1.4"), @mpf.from_str("1.7")), 80)
  assert_eq(t.lo, @mpf.fninf)
  assert_eq(t.hi, @mpf.finf)
  let cot = mpi_cot(mpi_make(@mpf.from_str("-0.1"), @mpf.from_str("0.1")), 80)
  assert_eq(cot.lo, @mpf.fninf)
  assert_eq(cot.hi, @mpf.finf)
  let c = mpi_cos(interval(0, 0), 80)
  let s = mpi_sin(interval(0, 0), 80)
  assert_mpi_eq(c, i(1), i(1))
  assert_mpi_eq(s, i(0), i(0))
}

///|
test "mpi shift cosh_sinh atan2 subset" {
  assert_mpi_eq(mpi_shift(interval(1, 2), 1), i(2), i(4))
  let (ch, sh) = mpi_cosh_sinh(interval(0, 0), 120)
  assert_mpi_eq(ch, i(1), i(1))
  assert_mpi_eq(sh, i(0), i(0))
  assert_mpi_eq(mpi_atan2(interval(0, 0), interval(2, 3), 120), i(0), i(0))
  let pi = @libelefun.mpf_pi(120, @mpf.round_nearest)
  let arg_neg = mpi_atan2(interval(0, 0), interval(-3, -2), 120)
  assert_contains(arg_neg, pi)
  let arg_full = mpi_atan2(interval(-1, 1), interval(-1, 1), 120)
  assert_contains(arg_full, pi)
  assert_contains(arg_full, @mpf.mpf_neg(pi, 0, @mpf.round_down))
}

///|
test "mpi gamma family subset and pole behavior" {
  let g = mpi_gamma(interval(2, 3), 160)
  assert_contains(
    g,
    @gammazeta.mpf_gamma(@mpf.from_str("2.2"), 160, @mpf.round_nearest),
  )
  assert_contains(
    g,
    @gammazeta.mpf_gamma(@mpf.from_str("2.8"), 160, @mpf.round_nearest),
  )
  let rg = mpi_rgamma(interval(2, 3), 160)
  assert_contains(
    rg,
    @gammazeta.mpf_rgamma(@mpf.from_str("2.2"), 160, @mpf.round_nearest),
  )
  assert_contains(
    rg,
    @gammazeta.mpf_rgamma(@mpf.from_str("2.8"), 160, @mpf.round_nearest),
  )
  let lg = mpi_loggamma(interval(2, 3), 160)
  assert_contains(
    lg,
    @gammazeta.mpf_loggamma(@mpf.from_str("2.2"), 160, @mpf.round_nearest),
  )
  assert_contains(
    lg,
    @gammazeta.mpf_loggamma(@mpf.from_str("2.8"), 160, @mpf.round_nearest),
  )
  let fac = mpi_factorial(interval(2, 3), 160)
  assert_contains(
    fac,
    @gammazeta.mpf_gamma(@mpf.from_str("3.2"), 160, @mpf.round_nearest),
  )
  assert_contains(
    fac,
    @gammazeta.mpf_gamma(@mpf.from_str("3.8"), 160, @mpf.round_nearest),
  )
  let pole = mpi_gamma(
    mpi_make(@mpf.from_str("-0.2"), @mpf.from_str("0.2")),
    160,
  )
  assert_eq(pole.lo, @mpf.fninf)
  assert_eq(pole.hi, @mpf.finf)
  let rg_pole = mpi_rgamma(
    mpi_make(@mpf.from_str("-0.2"), @mpf.from_str("0.2")),
    160,
  )
  assert_contains(rg_pole, @mpf.fzero)
}

///|
test "mpi gamma scalar identity subset from mpmath interval tests" {
  assert_mpi_eq(mpi_rgamma(interval(0, 0), 180), @mpf.fzero, @mpf.fzero)
  assert_mpi_eq(mpi_factorial(interval(0, 0), 180), @mpf.fone, @mpf.fone)
  assert_mpi_eq(mpi_factorial(interval(1, 1), 180), @mpf.fone, @mpf.fone)
  assert_mpi_eq(
    mpi_factorial(interval(2, 2), 180),
    @mpf.from_int(2),
    @mpf.from_int(2),
  )
  assert_mpi_eq(
    mpi_factorial(interval(3, 3), 180),
    @mpf.from_int(6),
    @mpf.from_int(6),
  )
  assert_mpi_eq(mpi_gamma(interval(0, 0), 180), @mpf.fninf, @mpf.finf)
  assert_mpi_eq(mpi_gamma(interval(1, 1), 180), @mpf.fone, @mpf.fone)
  assert_mpi_eq(mpi_gamma(interval(2, 2), 180), @mpf.fone, @mpf.fone)
  assert_mpi_eq(
    mpi_gamma(interval(3, 3), 180),
    @mpf.from_int(2),
    @mpf.from_int(2),
  )
  let minus_half = @mpf.from_str("-0.5", prec=240, rnd=@mpf.round_nearest)
  let gamma_mhalf = mpi_gamma(mpi_make(minus_half, minus_half), 220)
  assert_true(
    @mpf.to_str_opts(mpi_mid(gamma_mhalf, 220), dps=14).has_prefix(
      "-3.544907701811",
    ),
  )
  assert_mpi_eq(mpi_loggamma(interval(1, 1), 180), @mpf.fzero, @mpf.fzero)
  assert_mpi_eq(mpi_loggamma(interval(2, 2), 180), @mpf.fzero, @mpf.fzero)
  let lg3 = mpi_loggamma(interval(3, 3), 220)
  assert_true(
    @mpf.to_str_opts(mpi_mid(lg3, 220), dps=14).has_prefix("0.6931471805599"),
  )
}

///|
test "mpi nstr parity subset from mpmath interval tests" {
  let n = 30
  let x = interval(1, 2)
  assert_eq(
    mpi_to_str_opts(x, dps=n, mode="plusminus", error_dps=6),
    "1.5 +- 0.5",
  )
  assert_eq(
    mpi_to_str_opts(x, dps=n, mode="plusminus", use_spaces=false, error_dps=6),
    "1.5+-0.5",
  )
  assert_eq(mpi_to_str_opts(x, dps=n, mode="percent"), "1.5 (33.33%)")
  assert_eq(
    mpi_to_str_opts(x, dps=n, mode="brackets", use_spaces=false),
    "[1.0,2.0]",
  )
  assert_eq(
    mpi_to_str_opts(
      x,
      dps=n,
      mode="brackets",
      left_bracket="<",
      right_bracket=">",
    ),
    "<1.0, 2.0>",
  )
  let y = mpi_make(
    @mpf.from_str("5.2582327113062393041", prec=120, rnd=@mpf.round_floor),
    @mpf.from_str("5.2582327113062749951", prec=120, rnd=@mpf.round_ceiling),
  )
  assert_eq(
    mpi_to_str_opts(y, dps=n, mode="diff"),
    "5.2582327113062[393041, 749951]",
  )
}

///|
test "mpi mul/div edge parity subset from mpmath interval tests" {
  let m1 = mpi_mul(interval(-1, 0), mpi_from_mpf(@mpf.finf))
  if !(@mpf.mpf_eq(m1.lo, @mpf.fninf) && @mpf.mpf_eq(m1.hi, @mpf.fzero)) {
    fail("mul [-1,0]*[inf,inf] mismatch: \{mpi_to_str(m1, dps=20)}")
  }
  let m2 = mpi_mul(interval(0, 1), mpi_from_mpf(@mpf.finf))
  if !(@mpf.mpf_eq(m2.lo, @mpf.fzero) && @mpf.mpf_eq(m2.hi, @mpf.finf)) {
    fail("mul [0,1]*[inf,inf] mismatch: \{mpi_to_str(m2, dps=20)}")
  }
  let m3 = mpi_mul(interval(-1, 1), mpi_from_mpf(@mpf.finf))
  if !(@mpf.mpf_eq(m3.lo, @mpf.fninf) && @mpf.mpf_eq(m3.hi, @mpf.finf)) {
    fail("mul [-1,1]*[inf,inf] mismatch: \{mpi_to_str(m3, dps=20)}")
  }
  let d1 = mpi_div(interval(0, 1), interval(0, 1), 120)
  if !(@mpf.mpf_eq(d1.lo, @mpf.fzero) && @mpf.mpf_eq(d1.hi, @mpf.finf)) {
    fail("div [0,1]/[0,1] mismatch: \{mpi_to_str(d1, dps=20)}")
  }
  let d2 = mpi_div(interval(1, 2), mpi_make(@mpf.fzero, @mpf.finf), 120)
  if !(@mpf.mpf_eq(d2.lo, @mpf.fzero) && @mpf.mpf_eq(d2.hi, @mpf.finf)) {
    fail("div [1,2]/[0,inf] mismatch: \{mpi_to_str(d2, dps=20)}")
  }
  let d3 = mpi_div(interval(-1, 0), mpi_make(@mpf.fzero, @mpf.fone), 120)
  if !(@mpf.mpf_eq(d3.lo, @mpf.fninf) && @mpf.mpf_eq(d3.hi, @mpf.fzero)) {
    fail("div [-1,0]/[0,1] mismatch: \{mpi_to_str(d3, dps=20)}")
  }
  let d4 = mpi_div(interval(-1, 0), mpi_make(@mpf.fnone, @mpf.fzero), 120)
  if !(@mpf.mpf_eq(d4.lo, @mpf.fzero) && @mpf.mpf_eq(d4.hi, @mpf.finf)) {
    fail("div [-1,0]/[-1,0] mismatch: \{mpi_to_str(d4, dps=20)}")
  }
}

///|
test "mpi pow with infinite exponent subset from mpmath interval tests" {
  assert_mpi_eq(
    mpi_pow(interval(0, 1), mpi_from_mpf(@mpf.finf), 160),
    @mpf.fzero,
    @mpf.fone,
  )
  assert_mpi_eq(
    mpi_pow(interval(0, 1), mpi_from_mpf(@mpf.fninf), 160),
    @mpf.fone,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_pow(mpi_make(@mpf.fzero, @mpf.finf), mpi_from_mpf(@mpf.finf), 160),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_pow(mpi_make(@mpf.fzero, @mpf.finf), mpi_from_mpf(@mpf.fninf), 160),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_pow(mpi_make(@mpf.fone, @mpf.finf), mpi_from_mpf(@mpf.finf), 160),
    @mpf.fone,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_pow(mpi_make(@mpf.fone, @mpf.finf), mpi_from_mpf(@mpf.fninf), 160),
    @mpf.fzero,
    @mpf.fone,
  )
}

///|
test "mpi trigonometric numeric parity subset from mpmath interval tests" {
  let p = 53
  let c01 = mpi_cos(interval(0, 1), p)
  assert_true(@mpf.mpf_le(c01.lo, @mpf.from_str("0.54030230586813965399")))
  assert_true(@mpf.mpf_ge(c01.hi, @mpf.fone))
  let s01 = mpi_sin(interval(0, 1), p)
  assert_true(@mpf.mpf_le(s01.lo, @mpf.fzero))
  assert_true(@mpf.mpf_ge(s01.hi, @mpf.from_str("0.8414709848078966159")))
  let c12 = mpi_cos(interval(1, 2), p)
  assert_true(@mpf.mpf_le(c12.lo, @mpf.from_str("-0.4161468365471424069")))
  assert_true(@mpf.mpf_ge(c12.hi, @mpf.from_str("0.54030230586813976501")))
  let s12 = mpi_sin(interval(1, 2), p)
  assert_true(@mpf.mpf_le(s12.lo, @mpf.from_str("0.84147098480789650488")))
  assert_true(@mpf.mpf_ge(s12.hi, @mpf.fone))
  assert_mpi_eq(mpi_cos(mpi_make(i(2), @mpf.finf), 120), @mpf.fnone, @mpf.fone)
  assert_mpi_eq(mpi_sin(mpi_make(i(2), @mpf.finf), 120), @mpf.fnone, @mpf.fone)
  let t = mpi_tan(mpi_make(@mpf.from_str("0.5"), @mpf.from_str("1.0")), 180)
  assert_contains(
    t,
    @libelefun.mpf_tan(@mpf.from_str("0.5"), 180, @mpf.round_nearest),
  )
  assert_contains(
    t,
    @libelefun.mpf_tan(@mpf.from_str("1.0"), 180, @mpf.round_nearest),
  )
}

///|
test "mpi div matrix extended subset from mpmath interval tests" {
  let half = @mpf.from_str("0.5")
  let quarter = @mpf.from_str("0.25")
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.finf, @mpf.finf), mpi_make(@mpf.finf, @mpf.finf), 120),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.finf, @mpf.finf), mpi_make(i(2), @mpf.finf), 120),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.finf, @mpf.finf), interval(2, 2), 120),
    @mpf.finf,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.fzero, @mpf.finf), mpi_make(i(2), @mpf.finf), 120),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_div(mpi_make(i(2), @mpf.finf), interval(2, 2), 120),
    @mpf.fone,
    @mpf.finf,
  )
  assert_mpi_eq(
    mpi_div(interval(-4, 8), mpi_make(@mpf.fone, @mpf.finf), 120),
    i(-4),
    i(8),
  )
  assert_mpi_eq(
    mpi_div(interval(-4, 8), mpi_make(half, @mpf.finf), 120),
    i(-8),
    i(16),
  )
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.fninf, i(8)), mpi_make(half, @mpf.finf), 120),
    @mpf.fninf,
    i(16),
  )
  assert_mpi_eq(
    mpi_div(mpi_make(@mpf.fzero, i(8)), mpi_make(@mpf.finf, @mpf.finf), 120),
    @mpf.fzero,
    @mpf.fzero,
  )
  assert_mpi_eq(
    mpi_div(
      mpi_make(@mpf.fninf, @mpf.fzero),
      mpi_make(@mpf.finf, @mpf.finf),
      120,
    ),
    @mpf.fninf,
    @mpf.fzero,
  )
  assert_mpi_eq(
    mpi_div(mpi_make(i(8), @mpf.finf), mpi_make(@mpf.finf, @mpf.finf), 120),
    @mpf.fzero,
    @mpf.finf,
  )
  assert_mpi_eq(mpi_div(interval(-1, 2), interval(-2, -1), 120), i(-2), i(1))
  assert_mpi_eq(
    mpi_div(
      mpi_make(@mpf.from_str("-0.5"), @mpf.from_str("-0.25")),
      interval(0, 1),
      120,
    ),
    @mpf.fninf,
    @mpf.from_str("-0.25"),
  )
  assert_mpi_eq(
    mpi_div(
      mpi_make(@mpf.from_str("-0.5"), @mpf.from_str("-0.25")),
      mpi_make(half, @mpf.fone),
      120,
    ),
    @mpf.from_str("-1.0"),
    @mpf.from_str("-0.25"),
  )
  assert_mpi_eq(
    mpi_div(mpi_make(half, i(4)), mpi_make(half, @mpf.fone), 120),
    half,
    i(8),
  )
  assert_mpi_eq(
    mpi_div(
      mpi_make(i(-4), @mpf.from_str("-0.5")),
      mpi_make(i(-2), @mpf.from_str("-0.5")),
      120,
    ),
    quarter,
    i(8),
  )
}

///|
test "mpi trig large-argument parity subset from mpmath interval tests" {
  let huge = @mpf.from_str("4e50", prec=320, rnd=@mpf.round_nearest)
  let half = @mpf.from_str("0.5")
  let p_list = [15, 40, 80]
  for p in p_list {
    let pi_iv = mpi_pi(p + 80)
    let arg4pi = mpi_mul(mpi_from_mpf(i(4)), pi_iv, prec=p + 80)
    assert_contains(mpi_sin(arg4pi, p + 80), @mpf.fzero)
    assert_contains(mpi_cos(arg4pi, p + 80), @mpf.fone)
    let arg_big = mpi_mul(mpi_from_mpf(huge), pi_iv, prec=p + 80)
    assert_contains(mpi_sin(arg_big, p + 80), @mpf.fzero)
    assert_contains(mpi_cos(arg_big, p + 80), @mpf.fone)
    let w = mpi_add(mpi_from_mpf(huge), mpi_from_mpf(half))
    let arg_w = mpi_mul(w, pi_iv, prec=p + 80)
    assert_contains(mpi_cos(arg_w, p + 80), @mpf.fzero)
  }
}

///|
test "mpi nstr and convert boundary subset from mpmath interval tests" {
  let n = 30
  let cos_diff = mpi_to_str_opts(
    mpi_cos(interval(1, 1), 140),
    dps=n,
    mode="diff",
    use_spaces=false,
  )
  assert_true(cos_diff.has_prefix("0.540302305868139"))
  assert_true(cos_diff.contains("["))
  assert_true(cos_diff.contains("]"))
  let exp_diff = mpi_to_str_opts(
    mpi_exp(mpi_from_str("5000.1"), 260),
    dps=n,
    mode="diff",
  )
  assert_true(exp_diff.contains("["))
  assert_true(exp_diff.contains("]"))
  assert_true(exp_diff.contains("e+2171"))
  assert_mpi_eq(mpi_from_str(" [ 1 , 2 ] "), i(1), i(2))
  assert_mpi_eq(mpi_from_str("0 (33.3%)"), @mpf.fzero, @mpf.fzero)
}

///|
test "mpi trig pi-grid sanity subset from mpmath interval tests" {
  let p = 220
  let pi_iv = mpi_pi(p + 40)
  let half_iv = mpi_from_mpf(@mpf.from_str("0.5"))
  let odd_ns : Array[Int] = [-5, -3, -1, 1, 3, 5]
  for n in odd_ns {
    let n_iv = mpi_from_mpf(@mpf.from_int(n))
    let arg_n = mpi_mul(n_iv, pi_iv, prec=p + 40)
    let c = mpi_cos(arg_n, p)
    assert_contains(c, @mpf.fnone)
    assert_false(@mpf.mpf_eq(c.lo, @mpf.fnone) && @mpf.mpf_eq(c.hi, @mpf.fnone))
    let n_half_iv = mpi_add(n_iv, half_iv)
    let arg_half = mpi_mul(n_half_iv, pi_iv, prec=p + 40)
    let s = mpi_sin(arg_half, p)
    assert_contains(s, @mpf.fnone)
    assert_false(@mpf.mpf_eq(s.lo, @mpf.fnone) && @mpf.mpf_eq(s.hi, @mpf.fnone))
  }
  let even_ns : Array[Int] = [-6, -4, -2, 0, 2, 4, 6]
  for n in even_ns {
    let n_iv = mpi_from_mpf(@mpf.from_int(n))
    let arg_n = mpi_mul(n_iv, pi_iv, prec=p + 40)
    let c = mpi_cos(arg_n, p)
    assert_contains(c, @mpf.fone)
    if n != 0 {
      assert_false(@mpf.mpf_eq(c.lo, @mpf.fone) && @mpf.mpf_eq(c.hi, @mpf.fone))
    }
    let n_half_iv = mpi_add(n_iv, half_iv)
    let arg_half = mpi_mul(n_half_iv, pi_iv, prec=p + 40)
    let s = mpi_sin(arg_half, p)
    assert_contains(s, @mpf.fone)
    assert_false(@mpf.mpf_eq(s.lo, @mpf.fone) && @mpf.mpf_eq(s.hi, @mpf.fone))
  }
  let all_ns : Array[Int] = [-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6]
  for n in all_ns {
    let n_iv = mpi_from_mpf(@mpf.from_int(n))
    let n_half_iv = mpi_add(n_iv, half_iv)
    let c_half = mpi_cos(mpi_mul(n_half_iv, pi_iv, prec=p + 40), p)
    assert_true(@mpf.mpf_lt(c_half.lo, @mpf.fzero))
    assert_true(@mpf.mpf_gt(c_half.hi, @mpf.fzero))
    let s_n = mpi_sin(mpi_mul(n_iv, pi_iv, prec=p + 40), p)
    if n == 0 {
      assert_contains(s_n, @mpf.fzero)
    } else {
      assert_true(@mpf.mpf_lt(s_n.lo, @mpf.fzero))
      assert_true(@mpf.mpf_gt(s_n.hi, @mpf.fzero))
    }
  }
}

///|
test "mpi nstr and convert edge extras from mpmath interval tests" {
  assert_eq(mpi_to_str_opts(mpi_zero, dps=2, mode="percent"), "0.0 (0.0%)")
  let s = mpi_to_str_opts(
    mpi_cos(mpi_from_mpf(@mpf.from_int(1)), 220),
    dps=30,
    mode="diff",
    use_spaces=false,
  )
  assert_true(s.has_prefix("0.540302305868139"))
  assert_true(s.contains("["))
  assert_true(s.contains("]"))
  assert_mpi_eq(mpi_from_str(" 1.5 +- 0.5 "), i(1), i(2))
  assert_mpi_eq(
    mpi_from_str(" 1.[23,46]e-8 "),
    @mpf.from_str("1.23e-8", prec=256, rnd=@mpf.round_floor),
    @mpf.from_str("1.46e-8", prec=256, rnd=@mpf.round_ceiling),
  )
}
