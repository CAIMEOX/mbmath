///|
fn assert_raw(x : RawMpf, sign : Int, man : BigInt, exp : Int) -> Unit raise {
  @debug.assert_eq(x.sign, sign)
  @debug.assert_eq(x.man, man)
  @debug.assert_eq(x.exp, exp)
}

///|
test "bitwise Down matrix from mpmath" {
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(0N, -4, 4, Down),
    RawMpf::zero(),
  )
  assert_raw(RawMpf::from_mantissa_exponent(240N, -4, 4, Down), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(241N, -4, 4, Down), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(255N, -4, 4, Down), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-240N, -4, 4, Down), 1, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-241N, -4, 4, Down), 1, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-255N, -4, 4, Down), 1, 15N, 0)
}

///|
test "bitwise Up matrix from mpmath" {
  @debug.assert_eq(
    RawMpf::from_mantissa_exponent(0N, -4, 4, Up),
    RawMpf::zero(),
  )
  assert_raw(RawMpf::from_mantissa_exponent(240N, -4, 4, Up), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(241N, -4, 4, Up), 0, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(255N, -4, 4, Up), 0, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(-240N, -4, 4, Up), 1, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-241N, -4, 4, Up), 1, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(-255N, -4, 4, Up), 1, 1N, 4)
}

///|
test "bitwise floor and ceiling matrix from mpmath" {
  assert_raw(RawMpf::from_mantissa_exponent(241N, -4, 4, Floor), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-241N, -4, 4, Floor), 1, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(241N, -4, 4, Ceiling), 0, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(-241N, -4, 4, Ceiling), 1, 15N, 0)
}

///|
test "bitwise nearest tie-even subset from mpmath" {
  assert_raw(RawMpf::from_mantissa_exponent(247N, -4, 4, Nearest), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(248N, -4, 4, Nearest), 0, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(249N, -4, 4, Nearest), 0, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(232N, -4, 4, Nearest), 0, 7N, 1)
  assert_raw(RawMpf::from_mantissa_exponent(233N, -4, 4, Nearest), 0, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-247N, -4, 4, Nearest), 1, 15N, 0)
  assert_raw(RawMpf::from_mantissa_exponent(-248N, -4, 4, Nearest), 1, 1N, 4)
  assert_raw(RawMpf::from_mantissa_exponent(-249N, -4, 4, Nearest), 1, 1N, 4)
}

///|
test "bitwise historical rounding bugs subset" {
  assert_raw(RawMpf::from_mantissa_exponent(31N, 0, 4, Up), 0, 1N, 5)
  assert_raw(RawMpf::from_mantissa_exponent(-31N, 0, 4, Floor), 1, 1N, 5)
  assert_raw(RawMpf::from_mantissa_exponent(255N, 0, 7, Up), 0, 1N, 8)
  assert_raw(RawMpf::from_mantissa_exponent(-255N, 0, 7, Floor), 1, 1N, 8)
}

///|
test "exact add cancellation subset from mpmath" {
  let tiny = RawMpf::from_mantissa_exponent(1N, -332, 0, Down)
  @debug.assert_eq(
    RawMpf::one().add(tiny, 0, Nearest).sub(RawMpf::one(), 0, Nearest),
    tiny,
  )
  @debug.assert_eq(
    tiny.add(RawMpf::one(), 0, Nearest).sub(RawMpf::one(), 0, Nearest),
    tiny,
  )
  let tiny_neg = tiny.negated(0, Down)
  @debug.assert_eq(
    RawMpf::one().add(tiny_neg, 0, Nearest).sub(RawMpf::one(), 0, Nearest),
    tiny_neg,
  )
  @debug.assert_eq(RawMpf::one().add(RawMpf::zero(), 0, Nearest), RawMpf::one())
  @debug.assert_eq(RawMpf::zero().add(RawMpf::one(), 0, Nearest), RawMpf::one())
  @debug.assert_eq(
    RawMpf::zero().add(RawMpf::zero(), 0, Nearest),
    RawMpf::zero(),
  )
}

///|
test "tight integer division exactness subset from mpmath" {
  let pairs : Array[(Int, Int, Int)] = [
    (17, 13, 4),
    (-17, 13, 4),
    (1025, -257, 9),
    (-4097, -65, 7),
  ]
  for item in pairs {
    let (a, b, w) = item
    let p = a * b
    let pa = RawMpf::from_int(p)
    let aa = RawMpf::from_int(a)
    let bb = RawMpf::from_int(b)
    @debug.assert_eq(pa.div(aa, w, Floor), bb)
    @debug.assert_eq(pa.div(aa, w, Ceiling), bb)
    @debug.assert_eq(pa.div(aa, w, Down), bb)
    @debug.assert_eq(pa.div(aa, w, Up), bb)
    @debug.assert_eq(pa.div(aa, w, Nearest), bb)
  }
}

///|
test "epsilon division rounding subset from mpmath" {
  let a = RawMpf::parse(
    "0b0.101000000000000000000000000000000000000000000000001",
  )
  let b = RawMpf::parse("0b1.10101")
  let c = a.mul(b, 260, Floor)
  @debug.assert_eq(c.div(b, 2, Down), RawMpf::parse("0b0.10"))
  @debug.assert_eq(c.div(b, 3, Down), RawMpf::parse("0b0.101"))
  @debug.assert_eq(c.div(b, 2, Up), RawMpf::parse("0b0.11"))
  @debug.assert_eq(c.div(b, 3, Up), RawMpf::parse("0b0.110"))
  @debug.assert_eq(c.div(b, 2, Floor), RawMpf::parse("0b0.10"))
  @debug.assert_eq(c.div(b, 3, Floor), RawMpf::parse("0b0.101"))
  @debug.assert_eq(c.div(b, 2, Ceiling), RawMpf::parse("0b0.11"))
  @debug.assert_eq(c.div(b, 3, Ceiling), RawMpf::parse("0b0.110"))
}

///|
test "epsilon division negative rounding subset from mpmath" {
  let a = RawMpf::parse(
    "-0b0.101000000000000000000000000000000000000000000000001",
  )
  let b = RawMpf::parse("0b1.10101")
  let c = a.mul(b, 260, Floor)
  @debug.assert_eq(c.div(b, 2, Down), RawMpf::parse("-0b0.10"))
  @debug.assert_eq(c.div(b, 3, Up), RawMpf::parse("-0b0.110"))
  @debug.assert_eq(c.div(b, 2, Floor), RawMpf::parse("-0b0.11"))
  @debug.assert_eq(c.div(b, 3, Floor), RawMpf::parse("-0b0.110"))
  @debug.assert_eq(c.div(b, 2, Ceiling), RawMpf::parse("-0b0.10"))
  @debug.assert_eq(c.div(b, 3, Ceiling), RawMpf::parse("-0b0.101"))
}

///|
test "basic ops mod/floor-div style subset from mpmath" {
  let a = RawMpf::parse("30.21")
  let b = RawMpf::parse("2.53")
  let q = a.div(b, 120, Nearest).floor(0, Nearest)
  let r = a.modulo(b, 120, Nearest)
  @debug.assert_eq(q, RawMpf::from_int(11))
  @debug.assert_eq(r, RawMpf::parse("2.380000000000003"))
}
