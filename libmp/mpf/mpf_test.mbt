///|
test "normalize exact strips trailing zeros" {
  let x = normalize(0, 12N, 0, 4, 0, round_down)
  assert_eq(x.sign, 0)
  assert_eq(x.man, 3N)
  assert_eq(x.exp, 2)
  assert_eq(x.bc, 2)
}

///|
test "normalize precision rounding directions" {
  let pos_floor = normalize(0, 13N, 0, 4, 3, round_floor)
  assert_eq(pos_floor.sign, 0)
  assert_eq(pos_floor.man, 3N)
  assert_eq(pos_floor.exp, 2)
  let pos_up = normalize(0, 13N, 0, 4, 3, round_up)
  assert_eq(pos_up.sign, 0)
  assert_eq(pos_up.man, 7N)
  assert_eq(pos_up.exp, 1)
  let neg_floor = normalize(1, 13N, 0, 4, 3, round_floor)
  assert_eq(neg_floor.sign, 1)
  assert_eq(neg_floor.man, 7N)
  assert_eq(neg_floor.exp, 1)
  let neg_ceiling = normalize(1, 13N, 0, 4, 3, round_ceiling)
  assert_eq(neg_ceiling.sign, 1)
  assert_eq(neg_ceiling.man, 3N)
  assert_eq(neg_ceiling.exp, 2)
}

///|
test "mpf add/sub/mul" {
  let a = from_int(3)
  let b = from_man_exp(5N, -1, 0, round_down)
  let sum = mpf_add(a, b, 20, round_nearest)
  assert_eq(sum.sign, 0)
  assert_eq(sum.man, 11N)
  assert_eq(sum.exp, -1)
  let diff = mpf_sub(a, b, 20, round_nearest)
  assert_eq(diff.sign, 0)
  assert_eq(diff.man, 1N)
  assert_eq(diff.exp, -1)
  let prod = mpf_mul(a, b, 20, round_nearest)
  assert_eq(prod.sign, 0)
  assert_eq(prod.man, 15N)
  assert_eq(prod.exp, -1)
}

///|
test "mpf div 1 over 3 rounding" {
  let one = from_int(1)
  let neg_one = from_int(-1)
  let three = from_int(3)
  let d_floor = mpf_div(one, three, 7, round_floor)
  assert_eq(d_floor.sign, 0)
  assert_eq(d_floor.man, 85N)
  assert_eq(d_floor.exp, -8)
  let d_ceiling = mpf_div(one, three, 7, round_ceiling)
  assert_eq(d_ceiling.sign, 0)
  assert_eq(d_ceiling.man, 43N)
  assert_eq(d_ceiling.exp, -7)
  let d_neg_floor = mpf_div(neg_one, three, 7, round_floor)
  assert_eq(d_neg_floor.sign, 1)
  assert_eq(d_neg_floor.man, 43N)
  assert_eq(d_neg_floor.exp, -7)
}

///|
test "mpf_rdiv_int 1 over 3 rounding from mpmath test_division" {
  let three = from_int(3)
  assert_eq(mpf_rdiv_int(1, three, 7, round_floor), from_str("0b0.01010101"))
  assert_eq(mpf_rdiv_int(1, three, 7, round_ceiling), from_str("0b0.01010110"))
  assert_eq(mpf_rdiv_int(1, three, 7, round_down), from_str("0b0.01010101"))
  assert_eq(mpf_rdiv_int(1, three, 7, round_up), from_str("0b0.01010110"))
  assert_eq(mpf_rdiv_int(1, three, 7, round_nearest), from_str("0b0.01010101"))
  assert_eq(mpf_rdiv_int(-1, three, 7, round_floor), from_str("-0b0.01010110"))
  assert_eq(
    mpf_rdiv_int(-1, three, 7, round_ceiling),
    from_str("-0b0.01010101"),
  )
  assert_eq(mpf_rdiv_int(-1, three, 7, round_down), from_str("-0b0.01010101"))
  assert_eq(mpf_rdiv_int(-1, three, 7, round_up), from_str("-0b0.01010110"))
  assert_eq(
    mpf_rdiv_int(-1, three, 7, round_nearest),
    from_str("-0b0.01010101"),
  )
}

///|
test "mpf div half-integer tie-even from mpmath test_division" {
  let q = from_int(1000000)
  let a = from_int(300499999)
  let b = from_int(300500000)
  let c = from_int(300500001)
  assert_eq(mpf_div(a, q, 9, round_down), from_int(300))
  assert_eq(mpf_div(b, q, 9, round_down), from_int(300))
  assert_eq(mpf_div(c, q, 9, round_down), from_int(300))
  assert_eq(mpf_div(a, q, 9, round_up), from_int(301))
  assert_eq(mpf_div(b, q, 9, round_up), from_int(301))
  assert_eq(mpf_div(c, q, 9, round_up), from_int(301))
  assert_eq(mpf_div(a, q, 9, round_nearest), from_int(300))
  assert_eq(mpf_div(b, q, 9, round_nearest), from_int(300))
  assert_eq(mpf_div(c, q, 9, round_nearest), from_int(301))
  let a2 = from_int(301499999)
  let b2 = from_int(301500000)
  let c2 = from_int(301500001)
  assert_eq(mpf_div(a2, q, 9, round_nearest), from_int(301))
  assert_eq(mpf_div(b2, q, 9, round_nearest), from_int(302))
  assert_eq(mpf_div(c2, q, 9, round_nearest), from_int(302))
}

///|
test "mpf arithmetic special values" {
  assert_true(is_nan(mpf_add(fnan, finf, 20, round_nearest)))
  assert_eq(mpf_add(finf, from_int(1), 20, round_nearest), finf)
  assert_eq(mpf_sub(finf, fninf, 20, round_nearest), finf)
  assert_true(is_nan(mpf_add(finf, fninf, 20, round_nearest)))
  assert_true(is_nan(mpf_sub(finf, finf, 20, round_nearest)))
  assert_eq(mpf_mul(finf, from_int(-3), 20, round_nearest), fninf)
  assert_eq(mpf_mul(fninf, from_int(-3), 20, round_nearest), finf)
  assert_true(is_nan(mpf_mul(finf, fzero, 20, round_nearest)))
  assert_true(is_nan(mpf_mul(fnan, from_int(2), 20, round_nearest)))
  assert_eq(mpf_div(finf, from_int(-2), 20, round_nearest), fninf)
  assert_eq(mpf_div(from_int(2), finf, 20, round_nearest), fzero)
  assert_eq(mpf_div(fzero, finf, 20, round_nearest), fzero)
  assert_true(is_nan(mpf_div(finf, finf, 20, round_nearest)))
  assert_true(is_nan(mpf_div(from_int(2), fnan, 20, round_nearest)))
  assert_true(is_nan(mpf_div(fzero, fnan, 20, round_nearest)))
}

///|
test "mpf unary and compare helpers" {
  let x = from_man_exp(5N, -1, 0, round_down)
  let y = from_int(-3)
  assert_eq(mpf_pos(x, 10, round_nearest), x)
  assert_eq(mpf_neg(x, 0, round_nearest), from_man_exp(-5N, -1, 0, round_down))
  assert_eq(mpf_abs(y, 0, round_nearest), from_int(3))
  assert_eq(mpf_neg(finf, 20, round_nearest), fninf)
  assert_eq(mpf_abs(fninf, 20, round_nearest), finf)
  assert_eq(mpf_sign(fnan), 0)
  assert_eq(mpf_sign(fzero), 0)
  assert_eq(mpf_sign(finf), 1)
  assert_eq(mpf_sign(fninf), -1)
  assert_true(mpf_eq(from_int(7), from_str("7.0")))
  assert_false(mpf_eq(fnan, fnan))
  assert_eq(mpf_cmp(from_int(-2), from_int(3)), -1)
  assert_eq(mpf_cmp(from_int(3), from_int(3)), 0)
  assert_eq(mpf_cmp(fnan, from_int(0)), -1)
  assert_eq(mpf_cmp(from_int(0), fnan), 1)
  assert_true(mpf_lt(from_int(-1), from_int(0)))
  assert_true(mpf_le(from_int(-1), from_int(-1)))
  assert_true(mpf_gt(from_int(2), from_int(1)))
  assert_true(mpf_ge(from_int(2), from_int(2)))
  assert_false(mpf_lt(fnan, from_int(0)))
}

///|
test "mpf integer helpers" {
  assert_eq(mpf_shift(from_int(3), 5), from_int(96))
  assert_eq(mpf_mul_int(from_str("1.5"), 4, 40, round_nearest), from_int(6))
  assert_eq(mpf_mul_int(from_int(5), -2, 40, round_nearest), from_int(-10))
  assert_eq(
    mpf_rdiv_int(3, from_int(8), 40, round_nearest),
    from_man_exp(3N, -3, 0, round_down),
  )
  assert_true(is_nan(mpf_mul_int(finf, 0, 40, round_nearest)))
  assert_eq(mpf_shift(finf, 100), finf)
}

///|
test "mpf floor ceil nint frac" {
  let x = from_str("3.75")
  let y = from_str("-3.25")
  assert_eq(mpf_floor(x, 0, round_nearest), from_int(3))
  assert_eq(mpf_ceil(x, 0, round_nearest), from_int(4))
  assert_eq(mpf_nint(x, 0, round_nearest), from_int(4))
  assert_eq(mpf_frac(x, 40, round_nearest), from_man_exp(3N, -2, 0, round_down))
  assert_eq(mpf_floor(y, 0, round_nearest), from_int(-4))
  assert_eq(mpf_ceil(y, 0, round_nearest), from_int(-3))
  assert_eq(mpf_nint(y, 0, round_nearest), from_int(-3))
  assert_eq(mpf_nint(from_str("2.5"), 0, round_nearest), from_int(2))
  assert_eq(mpf_nint(from_str("-2.5"), 0, round_nearest), from_int(-2))
  assert_eq(mpf_floor(finf, 0, round_nearest), finf)
  assert_true(is_nan(mpf_frac(finf, 20, round_nearest)))
}

///|
test "mpf_round_int and mpf_min_max" {
  assert_eq(mpf_round_int(from_str("3.75"), round_floor), from_int(3))
  assert_eq(mpf_round_int(from_str("3.75"), round_ceiling), from_int(4))
  assert_eq(mpf_round_int(from_str("2.5"), round_nearest), from_int(2))
  assert_eq(mpf_round_int(from_str("-2.5"), round_nearest), from_int(-2))
  let xs : Array[RawMpf] = [from_str("3.5"), from_str("-8.25"), from_str("2.0")]
  let (mn, mx) = mpf_min_max(xs)
  assert_eq(mn, from_str("-8.25"))
  assert_eq(mx, from_str("3.5"))
}

///|
test "mpf mod and sum helpers" {
  assert_eq(
    mpf_mod(from_str("5.5"), from_int(2), 40, round_nearest),
    from_str("1.5"),
  )
  assert_eq(
    mpf_mod(from_str("-5.5"), from_int(2), 40, round_nearest),
    from_str("0.5"),
  )
  assert_eq(mpf_mod(from_str("1.5"), finf, 40, round_nearest), from_str("1.5"))
  assert_true(is_nan(mpf_mod(finf, from_int(2), 40, round_nearest)))
  let xs : Array[RawMpf] = [from_int(1), from_int(2), from_int(3)]
  assert_eq(mpf_sum(xs, 40, round_nearest), from_int(6))
  let ys : Array[RawMpf] = [from_int(-2), from_int(3), from_int(-4)]
  assert_eq(mpf_sum(ys, 40, round_nearest, absolute=true), from_int(9))
}

///|
test "mpf mod signed semantics from mpmath test_division" {
  assert_eq(mpf_mod(from_int(234), from_int(1), 20, round_nearest), fzero)
  assert_eq(
    mpf_mod(from_int(-3), from_int(256), 20, round_nearest),
    from_int(253),
  )
  assert_eq(
    mpf_mod(from_str("0.25"), from_str("23490.5"), 80, round_nearest),
    from_str("0.25"),
  )
  assert_eq(
    mpf_mod(from_str("0.25"), from_str("-23490.5"), 80, round_nearest),
    from_str("-23490.25"),
  )
  assert_eq(
    mpf_mod(from_str("-0.25"), from_str("23490.5"), 80, round_nearest),
    from_str("23490.25"),
  )
  assert_eq(
    mpf_mod(from_str("-0.25"), from_str("-23490.5"), 80, round_nearest),
    from_str("-0.25"),
  )
  assert_eq(
    mpf_mod(from_int(3), from_str("1.75"), 80, round_nearest),
    from_str("1.25"),
  )
}

///|
test "mpf_hypot basic" {
  assert_eq(mpf_hypot(from_int(3), from_int(4), 50, round_nearest), from_int(5))
  assert_eq(mpf_hypot(fzero, from_int(-2), 50, round_nearest), from_int(2))
}

///|
test "panic mpf_mod by zero" {
  ignore(mpf_mod(from_int(1), fzero, 20, round_nearest))
}

///|
test "mpf pow_int basic and special values" {
  assert_eq(mpf_pow_int(from_int(2), 10, 20, round_nearest), from_int(1024))
  assert_eq(
    mpf_pow_int(from_int(2), -3, 20, round_nearest),
    from_man_exp(1N, -3, 0, round_down),
  )
  assert_eq(mpf_pow_int(from_int(-2), 3, 20, round_nearest), from_int(-8))
  assert_eq(mpf_pow_int(finf, 2, 20, round_nearest), finf)
  assert_eq(mpf_pow_int(fninf, 3, 20, round_nearest), fninf)
  assert_eq(mpf_pow_int(fninf, 2, 20, round_nearest), finf)
  assert_eq(mpf_pow_int(finf, -1, 20, round_nearest), fzero)
  assert_eq(mpf_pow_int(fnan, 0, 20, round_nearest), fone)
  assert_true(is_nan(mpf_pow_int(fnan, 2, 20, round_nearest)))
}

///|
test "mpf sqrt basic and special values" {
  assert_eq(mpf_sqrt(from_int(4), 20, round_nearest), from_int(2))
  assert_eq(
    mpf_sqrt(from_man_exp(1N, -4, 0, round_down), 20, round_nearest),
    from_man_exp(1N, -2, 0, round_down),
  )
  assert_eq(mpf_sqrt(finf, 20, round_nearest), finf)
  assert_true(is_nan(mpf_sqrt(fnan, 20, round_nearest)))
}

///|
test "panic mpf_pow_int zero negative exponent" {
  ignore(mpf_pow_int(fzero, -1, 20, round_nearest))
}

///|
test "panic mpf_sqrt negative finite" {
  ignore(mpf_sqrt(from_int(-1), 20, round_nearest))
}

///|
test "panic mpf_sqrt negative inf" {
  ignore(mpf_sqrt(fninf, 20, round_nearest))
}

///|
test "panic mpf_div by zero" {
  ignore(mpf_div(from_int(1), fzero, 10, round_down))
}

///|
test "panic mpf_div inf by zero" {
  ignore(mpf_div(finf, fzero, 10, round_down))
}

///|
test "mpf frexp basic" {
  let (m0, e0) = mpf_frexp(from_int(0))
  assert_eq(m0, fzero)
  assert_eq(e0, 0)
  let (m1, e1) = mpf_frexp(from_int(9))
  assert_eq(m1, from_man_exp(9N, -4, 0, round_down))
  assert_eq(e1, 4)
  let (m2, e2) = mpf_frexp(from_int(1))
  assert_eq(m2, from_man_exp(1N, -1, 0, round_down))
  assert_eq(e2, 1)
  let (m3, e3) = mpf_frexp(from_int(1000))
  assert_eq(m3, from_man_exp(125N, -7, 0, round_down))
  assert_eq(e3, 10)
}

///|
test "panic mpf_frexp non-finite" {
  ignore(mpf_frexp(finf))
}

///|
test "mpf hash basic compatibility" {
  assert_eq(mpf_hash(from_int(0)), 0)
  assert_eq(mpf_hash(from_int(7)), mpf_hash(from_str("7.0")))
  assert_eq(mpf_hash(from_int(-1)), -2)
  assert_eq(mpf_hash(finf), 314159)
  assert_eq(mpf_hash(fninf), -314159)
  assert_eq(mpf_hash(fnan), 0)
  assert_not_eq(mpf_hash(from_str("1e1000")), mpf_hash(from_str("1e10000")))
}

///|
test "mpf perturb rounding subset from mpmath" {
  let a = fone
  let b = from_man_exp((1N << 53) - 1N, -53, 0, round_down)
  let c = from_man_exp((1N << 52) + 1N, -52, 0, round_down)
  assert_eq(mpf_perturb(a, 0, 53, round_nearest), a)
  assert_eq(mpf_perturb(a, 1, 53, round_nearest), a)
  assert_eq(mpf_perturb(a, 0, 53, round_up), c)
  assert_eq(mpf_perturb(a, 0, 53, round_ceiling), c)
  assert_eq(mpf_perturb(a, 0, 53, round_down), a)
  assert_eq(mpf_perturb(a, 0, 53, round_floor), a)
  assert_eq(mpf_perturb(a, 1, 53, round_up), a)
  assert_eq(mpf_perturb(a, 1, 53, round_ceiling), a)
  assert_eq(mpf_perturb(a, 1, 53, round_down), b)
  assert_eq(mpf_perturb(a, 1, 53, round_floor), b)
  let a_neg = mpf_neg(a, 0, round_down)
  let b_neg = mpf_neg(b, 0, round_down)
  let c_neg = mpf_neg(c, 0, round_down)
  assert_eq(mpf_perturb(a_neg, 0, 53, round_nearest), a_neg)
  assert_eq(mpf_perturb(a_neg, 1, 53, round_nearest), a_neg)
  assert_eq(mpf_perturb(a_neg, 0, 53, round_up), a_neg)
  assert_eq(mpf_perturb(a_neg, 0, 53, round_floor), a_neg)
  assert_eq(mpf_perturb(a_neg, 0, 53, round_down), b_neg)
  assert_eq(mpf_perturb(a_neg, 0, 53, round_ceiling), b_neg)
  assert_eq(mpf_perturb(a_neg, 1, 53, round_up), c_neg)
  assert_eq(mpf_perturb(a_neg, 1, 53, round_floor), c_neg)
  assert_eq(mpf_perturb(a_neg, 1, 53, round_down), a_neg)
  assert_eq(mpf_perturb(a_neg, 1, 53, round_ceiling), a_neg)
}

///|
test "mpf div negative regression points from mpmath test_division" {
  let d1 = mpf_div(
    from_int(-3),
    from_str("0.1531879017645047"),
    180,
    round_nearest,
  )
  let expected1 = from_str("-19.583791966887116")
  let err1 = mpf_abs(
    mpf_sub(d1, expected1, 220, round_nearest),
    220,
    round_nearest,
  )
  assert_true(mpf_lt(err1, from_str("1e-12")))
  let d2 = mpf_div(
    from_str("-2.6342475750861301"),
    from_str("0.35126216427941814"),
    180,
    round_nearest,
  )
  let expected2 = from_str("-7.4993775104985909")
  let err2 = mpf_abs(
    mpf_sub(d2, expected2, 220, round_nearest),
    220,
    round_nearest,
  )
  assert_true(mpf_lt(err2, from_str("1e-12")))
}

///|
test "mpf rand range and precision" {
  assert_eq(mpf_rand(0), fzero)
  for prec in [1, 7, 53, 127] {
    for _i in 0..<8 {
      let x = mpf_rand(prec)
      assert_true(mpf_ge(x, fzero))
      assert_true(mpf_lt(x, fone))
      assert_true(is_zero(x) || x.bc <= prec)
    }
  }
}
