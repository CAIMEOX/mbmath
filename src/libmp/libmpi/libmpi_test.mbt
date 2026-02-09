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
  assert_mpi_eq(
    mpi_from_str("1.25"),
    @mpf.from_str("1.25"),
    @mpf.from_str("1.25"),
  )
  assert_mpi_eq(mpi_from_str("1.5 +- 0.5"), i(1), i(2))
  assert_contains(mpi_from_str("1.5 (33.33333333333333333333333333333%)"), i(1))
  assert_contains(mpi_from_str("1.5 (33.33333333333333333333333333333%)"), i(2))
  assert_mpi_eq(mpi_from_str("[1,2]"), i(1), i(2))
  assert_mpi_eq(mpi_from_str("1[2,3]"), i(12), i(13))
  assert_mpi_eq(
    mpi_from_str("1.[23,46]e-8"),
    @mpf.from_str("1.23e-8"),
    @mpf.from_str("1.46e-8"),
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
  let y = mpi_make(
    @mpf.from_str("5.2582327113062393041"),
    @mpf.from_str("5.2582327113062749951"),
  )
  let diff = mpi_to_str_opts(y, dps=15, mode="diff")
  assert_true(diff.has_prefix("5.2582327113062"))
  assert_true(diff.contains("["))
  assert_true(diff.contains(","))
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
