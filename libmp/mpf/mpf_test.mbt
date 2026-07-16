///|
test "normalize exact strips trailing zeros" {
  let x = RawMpf::from_raw_parts(0, 12N, 0, 4, 0, Down)
  @debug.assert_eq(x.sign, 0)
  @debug.assert_eq(x.man, 3N)
  @debug.assert_eq(x.exp, 2)
  @debug.assert_eq(x.bc, 2)
}

///|
test "normalize precision rounding directions" {
  let pos_floor = RawMpf::from_raw_parts(0, 13N, 0, 4, 3, Floor)
  @debug.assert_eq(pos_floor.sign, 0)
  @debug.assert_eq(pos_floor.man, 3N)
  @debug.assert_eq(pos_floor.exp, 2)
  let pos_up = RawMpf::from_raw_parts(0, 13N, 0, 4, 3, Up)
  @debug.assert_eq(pos_up.sign, 0)
  @debug.assert_eq(pos_up.man, 7N)
  @debug.assert_eq(pos_up.exp, 1)
  let neg_floor = RawMpf::from_raw_parts(1, 13N, 0, 4, 3, Floor)
  @debug.assert_eq(neg_floor.sign, 1)
  @debug.assert_eq(neg_floor.man, 7N)
  @debug.assert_eq(neg_floor.exp, 1)
  let neg_ceiling = RawMpf::from_raw_parts(1, 13N, 0, 4, 3, Ceiling)
  @debug.assert_eq(neg_ceiling.sign, 1)
  @debug.assert_eq(neg_ceiling.man, 3N)
  @debug.assert_eq(neg_ceiling.exp, 2)
}

///|
test "mpf add/sub/mul" {
  let a = RawMpf::from_int(3)
  let b = RawMpf::from_mantissa_exponent(5N, -1, 0, Down)
  let sum = a.add(b, 20, Nearest)
  @debug.assert_eq(sum.sign, 0)
  @debug.assert_eq(sum.man, 11N)
  @debug.assert_eq(sum.exp, -1)
  let diff = a.sub(b, 20, Nearest)
  @debug.assert_eq(diff.sign, 0)
  @debug.assert_eq(diff.man, 1N)
  @debug.assert_eq(diff.exp, -1)
  let prod = a.mul(b, 20, Nearest)
  @debug.assert_eq(prod.sign, 0)
  @debug.assert_eq(prod.man, 15N)
  @debug.assert_eq(prod.exp, -1)
}

///|
test "mpf div 1 over 3 rounding" {
  let one = RawMpf::from_int(1)
  let neg_one = RawMpf::from_int(-1)
  let three = RawMpf::from_int(3)
  let d_floor = one.div(three, 7, Floor)
  @debug.assert_eq(d_floor.sign, 0)
  @debug.assert_eq(d_floor.man, 85N)
  @debug.assert_eq(d_floor.exp, -8)
  let d_ceiling = one.div(three, 7, Ceiling)
  @debug.assert_eq(d_ceiling.sign, 0)
  @debug.assert_eq(d_ceiling.man, 43N)
  @debug.assert_eq(d_ceiling.exp, -7)
  let d_neg_floor = neg_one.div(three, 7, Floor)
  @debug.assert_eq(d_neg_floor.sign, 1)
  @debug.assert_eq(d_neg_floor.man, 43N)
  @debug.assert_eq(d_neg_floor.exp, -7)
}

///|
test "mpf_rdiv_int 1 over 3 rounding from mpmath test_division" {
  let three = RawMpf::from_int(3)
  @debug.assert_eq(
    three.int_divided_by(1, 7, Floor),
    RawMpf::parse("0b0.01010101"),
  )
  @debug.assert_eq(
    three.int_divided_by(1, 7, Ceiling),
    RawMpf::parse("0b0.01010110"),
  )
  @debug.assert_eq(
    three.int_divided_by(1, 7, Down),
    RawMpf::parse("0b0.01010101"),
  )
  @debug.assert_eq(
    three.int_divided_by(1, 7, Up),
    RawMpf::parse("0b0.01010110"),
  )
  @debug.assert_eq(
    three.int_divided_by(1, 7, Nearest),
    RawMpf::parse("0b0.01010101"),
  )
  @debug.assert_eq(
    three.int_divided_by(-1, 7, Floor),
    RawMpf::parse("-0b0.01010110"),
  )
  @debug.assert_eq(
    three.int_divided_by(-1, 7, Ceiling),
    RawMpf::parse("-0b0.01010101"),
  )
  @debug.assert_eq(
    three.int_divided_by(-1, 7, Down),
    RawMpf::parse("-0b0.01010101"),
  )
  @debug.assert_eq(
    three.int_divided_by(-1, 7, Up),
    RawMpf::parse("-0b0.01010110"),
  )
  @debug.assert_eq(
    three.int_divided_by(-1, 7, Nearest),
    RawMpf::parse("-0b0.01010101"),
  )
}

///|
test "mpf div half-integer tie-even from mpmath test_division" {
  let q = RawMpf::from_int(1000000)
  let a = RawMpf::from_int(300499999)
  let b = RawMpf::from_int(300500000)
  let c = RawMpf::from_int(300500001)
  @debug.assert_eq(a.div(q, 9, Down), RawMpf::from_int(300))
  @debug.assert_eq(b.div(q, 9, Down), RawMpf::from_int(300))
  @debug.assert_eq(c.div(q, 9, Down), RawMpf::from_int(300))
  @debug.assert_eq(a.div(q, 9, Up), RawMpf::from_int(301))
  @debug.assert_eq(b.div(q, 9, Up), RawMpf::from_int(301))
  @debug.assert_eq(c.div(q, 9, Up), RawMpf::from_int(301))
  @debug.assert_eq(a.div(q, 9, Nearest), RawMpf::from_int(300))
  @debug.assert_eq(b.div(q, 9, Nearest), RawMpf::from_int(300))
  @debug.assert_eq(c.div(q, 9, Nearest), RawMpf::from_int(301))
  let a2 = RawMpf::from_int(301499999)
  let b2 = RawMpf::from_int(301500000)
  let c2 = RawMpf::from_int(301500001)
  @debug.assert_eq(a2.div(q, 9, Nearest), RawMpf::from_int(301))
  @debug.assert_eq(b2.div(q, 9, Nearest), RawMpf::from_int(302))
  @debug.assert_eq(c2.div(q, 9, Nearest), RawMpf::from_int(302))
}

///|
test "mpf arithmetic special values" {
  assert_true(RawMpf::nan().add(RawMpf::infinity(), 20, Nearest).is_nan())
  @debug.assert_eq(
    RawMpf::infinity().add(RawMpf::from_int(1), 20, Nearest),
    RawMpf::infinity(),
  )
  @debug.assert_eq(
    RawMpf::infinity().sub(RawMpf::negative_infinity(), 20, Nearest),
    RawMpf::infinity(),
  )
  assert_true(
    RawMpf::infinity().add(RawMpf::negative_infinity(), 20, Nearest).is_nan(),
  )
  assert_true(RawMpf::infinity().sub(RawMpf::infinity(), 20, Nearest).is_nan())
  @debug.assert_eq(
    RawMpf::infinity().mul(RawMpf::from_int(-3), 20, Nearest),
    RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    RawMpf::negative_infinity().mul(RawMpf::from_int(-3), 20, Nearest),
    RawMpf::infinity(),
  )
  assert_true(RawMpf::infinity().mul(RawMpf::zero(), 20, Nearest).is_nan())
  assert_true(RawMpf::nan().mul(RawMpf::from_int(2), 20, Nearest).is_nan())
  @debug.assert_eq(
    RawMpf::infinity().div(RawMpf::from_int(-2), 20, Nearest),
    RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    RawMpf::from_int(2).div(RawMpf::infinity(), 20, Nearest),
    RawMpf::zero(),
  )
  @debug.assert_eq(
    RawMpf::zero().div(RawMpf::infinity(), 20, Nearest),
    RawMpf::zero(),
  )
  assert_true(RawMpf::infinity().div(RawMpf::infinity(), 20, Nearest).is_nan())
  assert_true(RawMpf::from_int(2).div(RawMpf::nan(), 20, Nearest).is_nan())
  assert_true(RawMpf::zero().div(RawMpf::nan(), 20, Nearest).is_nan())
}

///|
test "mpf unary and compare helpers" {
  let x = RawMpf::from_mantissa_exponent(5N, -1, 0, Down)
  let y = RawMpf::from_int(-3)
  @debug.assert_eq(x.rounded(10, Nearest), x)
  @debug.assert_eq(
    x.negated(0, Nearest),
    RawMpf::from_mantissa_exponent(-5N, -1, 0, Down),
  )
  @debug.assert_eq(y.abs(0, Nearest), RawMpf::from_int(3))
  @debug.assert_eq(
    RawMpf::infinity().negated(20, Nearest),
    RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    RawMpf::negative_infinity().abs(20, Nearest),
    RawMpf::infinity(),
  )
  @debug.assert_eq(RawMpf::nan().signum(), 0)
  @debug.assert_eq(RawMpf::zero().signum(), 0)
  @debug.assert_eq(RawMpf::infinity().signum(), 1)
  @debug.assert_eq(RawMpf::negative_infinity().signum(), -1)
  assert_true(RawMpf::from_int(7) == RawMpf::parse("7.0"))
  assert_false(RawMpf::nan() == RawMpf::nan())
  @debug.assert_eq(RawMpf::from_int(-2).compare(RawMpf::from_int(3)), -1)
  @debug.assert_eq(RawMpf::from_int(3).compare(RawMpf::from_int(3)), 0)
  @debug.assert_eq(RawMpf::nan().compare(RawMpf::from_int(0)), -1)
  @debug.assert_eq(RawMpf::from_int(0).compare(RawMpf::nan()), 1)
  assert_true(RawMpf::from_int(-1) < RawMpf::from_int(0))
  assert_true(RawMpf::from_int(-1) <= RawMpf::from_int(-1))
  assert_true(RawMpf::from_int(2) > RawMpf::from_int(1))
  assert_true(RawMpf::from_int(2) >= RawMpf::from_int(2))
  assert_false(RawMpf::nan() < RawMpf::from_int(0))
}

///|
test "mpf integer helpers" {
  @debug.assert_eq(RawMpf::from_int(3).scale_pow2(5), RawMpf::from_int(96))
  @debug.assert_eq(
    RawMpf::parse("1.5").mul_int(4, 40, Nearest),
    RawMpf::from_int(6),
  )
  @debug.assert_eq(
    RawMpf::from_int(5).mul_int(-2, 40, Nearest),
    RawMpf::from_int(-10),
  )
  @debug.assert_eq(
    RawMpf::from_int(8).int_divided_by(3, 40, Nearest),
    RawMpf::from_mantissa_exponent(3N, -3, 0, Down),
  )
  assert_true(RawMpf::infinity().mul_int(0, 40, Nearest).is_nan())
  @debug.assert_eq(RawMpf::infinity().scale_pow2(100), RawMpf::infinity())
}

///|
test "mpf floor ceil nint frac" {
  let x = RawMpf::parse("3.75")
  let y = RawMpf::parse("-3.25")
  @debug.assert_eq(x.floor(0, Nearest), RawMpf::from_int(3))
  @debug.assert_eq(x.ceil(0, Nearest), RawMpf::from_int(4))
  @debug.assert_eq(x.nearest_integer(0, Nearest), RawMpf::from_int(4))
  @debug.assert_eq(
    x.fractional_part(40, Nearest),
    RawMpf::from_mantissa_exponent(3N, -2, 0, Down),
  )
  @debug.assert_eq(y.floor(0, Nearest), RawMpf::from_int(-4))
  @debug.assert_eq(y.ceil(0, Nearest), RawMpf::from_int(-3))
  @debug.assert_eq(y.nearest_integer(0, Nearest), RawMpf::from_int(-3))
  @debug.assert_eq(
    RawMpf::parse("2.5").nearest_integer(0, Nearest),
    RawMpf::from_int(2),
  )
  @debug.assert_eq(
    RawMpf::parse("-2.5").nearest_integer(0, Nearest),
    RawMpf::from_int(-2),
  )
  @debug.assert_eq(RawMpf::infinity().floor(0, Nearest), RawMpf::infinity())
  assert_true(RawMpf::infinity().fractional_part(20, Nearest).is_nan())
}

///|
test "mpf_round_int and mpf_min_max" {
  @debug.assert_eq(
    RawMpf::parse("3.75").round_to_integer(Floor),
    RawMpf::from_int(3),
  )
  @debug.assert_eq(
    RawMpf::parse("3.75").round_to_integer(Ceiling),
    RawMpf::from_int(4),
  )
  @debug.assert_eq(
    RawMpf::parse("2.5").round_to_integer(Nearest),
    RawMpf::from_int(2),
  )
  @debug.assert_eq(
    RawMpf::parse("-2.5").round_to_integer(Nearest),
    RawMpf::from_int(-2),
  )
  let xs : Array[RawMpf] = [
    RawMpf::parse("3.5"),
    RawMpf::parse("-8.25"),
    RawMpf::parse("2.0"),
  ]
  let (mn, mx) = RawMpf::min_max(xs)
  @debug.assert_eq(mn, RawMpf::parse("-8.25"))
  @debug.assert_eq(mx, RawMpf::parse("3.5"))
}

///|
test "mpf mod and sum helpers" {
  @debug.assert_eq(
    RawMpf::parse("5.5").modulo(RawMpf::from_int(2), 40, Nearest),
    RawMpf::parse("1.5"),
  )
  @debug.assert_eq(
    RawMpf::parse("-5.5").modulo(RawMpf::from_int(2), 40, Nearest),
    RawMpf::parse("0.5"),
  )
  @debug.assert_eq(
    RawMpf::parse("1.5").modulo(RawMpf::infinity(), 40, Nearest),
    RawMpf::parse("1.5"),
  )
  assert_true(
    RawMpf::infinity().modulo(RawMpf::from_int(2), 40, Nearest).is_nan(),
  )
  let xs : Array[RawMpf] = [
    RawMpf::from_int(1),
    RawMpf::from_int(2),
    RawMpf::from_int(3),
  ]
  @debug.assert_eq(RawMpf::sum(xs, 40, Nearest), RawMpf::from_int(6))
  let ys : Array[RawMpf] = [
    RawMpf::from_int(-2),
    RawMpf::from_int(3),
    RawMpf::from_int(-4),
  ]
  @debug.assert_eq(
    RawMpf::sum(ys, 40, Nearest, absolute=true),
    RawMpf::from_int(9),
  )
}

///|
test "mpf mod signed semantics from mpmath test_division" {
  @debug.assert_eq(
    RawMpf::from_int(234).modulo(RawMpf::from_int(1), 20, Nearest),
    RawMpf::zero(),
  )
  @debug.assert_eq(
    RawMpf::from_int(-3).modulo(RawMpf::from_int(256), 20, Nearest),
    RawMpf::from_int(253),
  )
  @debug.assert_eq(
    RawMpf::parse("0.25").modulo(RawMpf::parse("23490.5"), 80, Nearest),
    RawMpf::parse("0.25"),
  )
  @debug.assert_eq(
    RawMpf::parse("0.25").modulo(RawMpf::parse("-23490.5"), 80, Nearest),
    RawMpf::parse("-23490.25"),
  )
  @debug.assert_eq(
    RawMpf::parse("-0.25").modulo(RawMpf::parse("23490.5"), 80, Nearest),
    RawMpf::parse("23490.25"),
  )
  @debug.assert_eq(
    RawMpf::parse("-0.25").modulo(RawMpf::parse("-23490.5"), 80, Nearest),
    RawMpf::parse("-0.25"),
  )
  @debug.assert_eq(
    RawMpf::from_int(3).modulo(RawMpf::parse("1.75"), 80, Nearest),
    RawMpf::parse("1.25"),
  )
}

///|
test "mpf_hypot basic" {
  @debug.assert_eq(
    RawMpf::from_int(3).hypot(RawMpf::from_int(4), 50, Nearest),
    RawMpf::from_int(5),
  )
  @debug.assert_eq(
    RawMpf::zero().hypot(RawMpf::from_int(-2), 50, Nearest),
    RawMpf::from_int(2),
  )
}

///|
test "panic mpf_mod by zero" {
  ignore(RawMpf::from_int(1).modulo(RawMpf::zero(), 20, Nearest))
}

///|
test "mpf pow_int basic and special values" {
  @debug.assert_eq(
    RawMpf::from_int(2).pow_int(10, 20, Nearest),
    RawMpf::from_int(1024),
  )
  @debug.assert_eq(
    RawMpf::from_int(2).pow_int(-3, 20, Nearest),
    RawMpf::from_mantissa_exponent(1N, -3, 0, Down),
  )
  @debug.assert_eq(
    RawMpf::from_int(-2).pow_int(3, 20, Nearest),
    RawMpf::from_int(-8),
  )
  @debug.assert_eq(
    RawMpf::infinity().pow_int(2, 20, Nearest),
    RawMpf::infinity(),
  )
  @debug.assert_eq(
    RawMpf::negative_infinity().pow_int(3, 20, Nearest),
    RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    RawMpf::negative_infinity().pow_int(2, 20, Nearest),
    RawMpf::infinity(),
  )
  @debug.assert_eq(RawMpf::infinity().pow_int(-1, 20, Nearest), RawMpf::zero())
  @debug.assert_eq(RawMpf::nan().pow_int(0, 20, Nearest), RawMpf::one())
  assert_true(RawMpf::nan().pow_int(2, 20, Nearest).is_nan())
}

///|
test "mpf sqrt basic and special values" {
  @debug.assert_eq(RawMpf::from_int(4).sqrt(20, Nearest), RawMpf::from_int(2))
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(1N, -4, 0, Down).sqrt(20, Nearest),
    RawMpf::from_mantissa_exponent(1N, -2, 0, Down),
  )
  @debug.assert_eq(RawMpf::infinity().sqrt(20, Nearest), RawMpf::infinity())
  assert_true(RawMpf::nan().sqrt(20, Nearest).is_nan())
}

///|
test "panic mpf_pow_int zero negative exponent" {
  ignore(RawMpf::zero().pow_int(-1, 20, Nearest))
}

///|
test "panic mpf_sqrt negative finite" {
  ignore(RawMpf::from_int(-1).sqrt(20, Nearest))
}

///|
test "panic mpf_sqrt negative inf" {
  ignore(RawMpf::negative_infinity().sqrt(20, Nearest))
}

///|
test "panic mpf_div by zero" {
  ignore(RawMpf::from_int(1).div(RawMpf::zero(), 10, Down))
}

///|
test "panic mpf_div inf by zero" {
  ignore(RawMpf::infinity().div(RawMpf::zero(), 10, Down))
}

///|
test "mpf frexp basic" {
  let (m0, e0) = RawMpf::from_int(0).frexp()
  @debug.assert_eq(m0, RawMpf::zero())
  @debug.assert_eq(e0, 0)
  let (m1, e1) = RawMpf::from_int(9).frexp()
  @debug.assert_eq(m1, RawMpf::from_mantissa_exponent(9N, -4, 0, Down))
  @debug.assert_eq(e1, 4)
  let (m2, e2) = RawMpf::from_int(1).frexp()
  @debug.assert_eq(m2, RawMpf::from_mantissa_exponent(1N, -1, 0, Down))
  @debug.assert_eq(e2, 1)
  let (m3, e3) = RawMpf::from_int(1000).frexp()
  @debug.assert_eq(m3, RawMpf::from_mantissa_exponent(125N, -7, 0, Down))
  @debug.assert_eq(e3, 10)
}

///|
test "panic mpf_frexp non-finite" {
  ignore(RawMpf::infinity().frexp())
}

///|
test "mpf hash basic compatibility" {
  @debug.assert_eq(RawMpf::from_int(0).stable_hash(), 0)
  @debug.assert_eq(
    RawMpf::from_int(7).stable_hash(),
    RawMpf::parse("7.0").stable_hash(),
  )
  @debug.assert_eq(RawMpf::from_int(-1).stable_hash(), -2)
  @debug.assert_eq(RawMpf::infinity().stable_hash(), 314159)
  @debug.assert_eq(RawMpf::negative_infinity().stable_hash(), -314159)
  @debug.assert_eq(RawMpf::nan().stable_hash(), 0)
  assert_not_eq(
    RawMpf::parse("1e1000").stable_hash(),
    RawMpf::parse("1e10000").stable_hash(),
  )
}

///|
test "mpf perturb rounding subset from mpmath" {
  let a = RawMpf::one()
  let b = RawMpf::from_mantissa_exponent((1N << 53) - 1N, -53, 0, Down)
  let c = RawMpf::from_mantissa_exponent((1N << 52) + 1N, -52, 0, Down)
  @debug.assert_eq(a.perturb(0, 53, Nearest), a)
  @debug.assert_eq(a.perturb(1, 53, Nearest), a)
  @debug.assert_eq(a.perturb(0, 53, Up), c)
  @debug.assert_eq(a.perturb(0, 53, Ceiling), c)
  @debug.assert_eq(a.perturb(0, 53, Down), a)
  @debug.assert_eq(a.perturb(0, 53, Floor), a)
  @debug.assert_eq(a.perturb(1, 53, Up), a)
  @debug.assert_eq(a.perturb(1, 53, Ceiling), a)
  @debug.assert_eq(a.perturb(1, 53, Down), b)
  @debug.assert_eq(a.perturb(1, 53, Floor), b)
  let a_neg = a.negated(0, Down)
  let b_neg = b.negated(0, Down)
  let c_neg = c.negated(0, Down)
  @debug.assert_eq(a_neg.perturb(0, 53, Nearest), a_neg)
  @debug.assert_eq(a_neg.perturb(1, 53, Nearest), a_neg)
  @debug.assert_eq(a_neg.perturb(0, 53, Up), a_neg)
  @debug.assert_eq(a_neg.perturb(0, 53, Floor), a_neg)
  @debug.assert_eq(a_neg.perturb(0, 53, Down), b_neg)
  @debug.assert_eq(a_neg.perturb(0, 53, Ceiling), b_neg)
  @debug.assert_eq(a_neg.perturb(1, 53, Up), c_neg)
  @debug.assert_eq(a_neg.perturb(1, 53, Floor), c_neg)
  @debug.assert_eq(a_neg.perturb(1, 53, Down), a_neg)
  @debug.assert_eq(a_neg.perturb(1, 53, Ceiling), a_neg)
}

///|
test "mpf div negative regression points from mpmath test_division" {
  let d1 = RawMpf::from_int(-3).div(
    RawMpf::parse("0.1531879017645047"),
    180,
    Nearest,
  )
  let expected1 = RawMpf::parse("-19.583791966887116")
  let err1 = d1.sub(expected1, 220, Nearest).abs(220, Nearest)
  assert_true(err1 < RawMpf::parse("1e-12"))
  let d2 = RawMpf::parse("-2.6342475750861301").div(
    RawMpf::parse("0.35126216427941814"),
    180,
    Nearest,
  )
  let expected2 = RawMpf::parse("-7.4993775104985909")
  let err2 = d2.sub(expected2, 220, Nearest).abs(220, Nearest)
  assert_true(err2 < RawMpf::parse("1e-12"))
}

///|
test "mpf rand range and precision" {
  @debug.assert_eq(RawMpf::random(0), RawMpf::zero())
  for prec in [1, 7, 53, 127] {
    for _i in 0..<8 {
      let x = RawMpf::random(prec)
      assert_true(x >= RawMpf::zero())
      assert_true(x < RawMpf::one())
      assert_true(x.is_zero() || x.bc <= prec)
    }
  }
}
