///|
fn assert_close(v : @mpf.RawMpf, expected : String, tol : String) -> Unit raise {
  let e = @mpf.RawMpf::parse(expected)
  let err = v.sub(e, 280, Nearest).abs(280, Nearest)
  assert_true(err < @mpf.RawMpf::parse(tol))
}

///|
test "power fractional exact subset from mpmath test_power" {
  @debug.assert_eq(
    pow(@mpf.RawMpf::from_int(16), @mpf.RawMpf::parse("2.5"), 220, Nearest),
    @mpf.RawMpf::from_int(1024),
  )
  @debug.assert_eq(
    pow(@mpf.RawMpf::from_int(64), @mpf.RawMpf::parse("0.5"), 220, Nearest),
    @mpf.RawMpf::from_int(8),
  )
  @debug.assert_eq(
    pow(@mpf.RawMpf::from_int(64), @mpf.RawMpf::parse("-0.5"), 220, Nearest),
    @mpf.RawMpf::parse("0.125"),
  )
  @debug.assert_eq(
    pow(@mpf.RawMpf::from_int(16), @mpf.RawMpf::parse("-2.5"), 220, Nearest),
    @mpf.RawMpf::parse("0.0009765625"),
  )
}

///|
test "power fractional decimal subset from mpmath test_power" {
  assert_close(
    pow(@mpf.RawMpf::from_int(10), @mpf.RawMpf::parse("0.5"), 240, Nearest),
    "3.1622776601683791",
    "1e-12",
  )
  assert_close(
    pow(@mpf.RawMpf::from_int(10), @mpf.RawMpf::parse("2.5"), 240, Nearest),
    "316.2277660168379",
    "1e-10",
  )
  assert_close(
    pow(@mpf.RawMpf::from_int(10), @mpf.RawMpf::parse("-0.3"), 240, Nearest),
    "0.50118723362727224",
    "1e-12",
  )
}

///|
test "pow_int directed rounding subset from mpmath test_power" {
  let eps = @mpf.RawMpf::from_mantissa_exponent(1N, -115, 0, Down)
  let pos10001 = @mpf.RawMpf::one().add(eps, 0, Nearest)
  let pos09999 = @mpf.RawMpf::one().sub(eps, 0, Nearest)
  let neg10001 = pos10001.negated(0, Down)
  let neg09999 = pos09999.negated(0, Down)
  let up_a = pos10001.pow_int(5, 40, Up)
  let up_b = pos09999.pow_int(5, 40, Up)
  assert_true(up_a > @mpf.RawMpf::one())
  @debug.assert_eq(up_b, @mpf.RawMpf::one())
  let dn_a = pos10001.pow_int(5, 40, Down)
  let dn_b = pos09999.pow_int(5, 40, Down)
  @debug.assert_eq(dn_a, @mpf.RawMpf::one())
  assert_true(dn_b < @mpf.RawMpf::one())
  let up_neg = neg10001.pow_int(5, 40, Up)
  let dn_neg = neg10001.pow_int(5, 40, Down)
  assert_true(up_neg < @mpf.RawMpf::negative_one())
  @debug.assert_eq(dn_neg, @mpf.RawMpf::negative_one())
  let up_neg_small = neg09999.pow_int(5, 40, Up)
  let dn_neg_small = neg09999.pow_int(5, 40, Down)
  @debug.assert_eq(up_neg_small, @mpf.RawMpf::negative_one())
  assert_true(dn_neg_small > @mpf.RawMpf::negative_one())
}

///|
test "trig near zero subset from mpmath test_trig" {
  let a = @mpf.RawMpf::parse("1e-100")
  let b = @mpf.RawMpf::parse("-1e-100")
  let s_a = sin(a, 260, Nearest)
  let c_a = cos(a, 260, Nearest)
  let t_a = tan(a, 260, Nearest)
  let s_b = sin(b, 260, Nearest)
  assert_true(
    s_a.sub(a, 280, Nearest).abs(280, Nearest) < @mpf.RawMpf::parse("1e-130"),
  )
  assert_true(
    c_a.sub(@mpf.RawMpf::one(), 280, Nearest).abs(280, Nearest) <
    @mpf.RawMpf::parse("1e-130"),
  )
  assert_true(
    t_a.sub(a, 280, Nearest).abs(280, Nearest) < @mpf.RawMpf::parse("1e-130"),
  )
  assert_true(
    s_b.sub(b, 280, Nearest).abs(280, Nearest) < @mpf.RawMpf::parse("1e-130"),
  )
}

///|
test "trig directed rounding ordering near zero from mpmath test_trig" {
  let a = @mpf.RawMpf::parse("1e-100")
  let b = @mpf.RawMpf::parse("-1e-100")
  let sn = sin(a, 260, Nearest)
  let sd = sin(a, 260, Down)
  let su = sin(a, 260, Up)
  assert_true(sd <= sn && sn <= su)
  let sdn = sin(b, 260, Down)
  let sun = sin(b, 260, Up)
  assert_true(sdn <= sun)
  let cd = cos(a, 260, Down)
  let cu = cos(a, 260, Up)
  assert_true(cd <= cu)
}

///|
test "atan infinities subset from mpmath test_special" {
  let p2 = pi(220, Nearest).div(@mpf.RawMpf::from_int(2), 220, Nearest)
  let a = atan(@mpf.RawMpf::infinity(), 220, Nearest)
  let b = atan(@mpf.RawMpf::negative_infinity(), 220, Nearest)
  assert_true(
    a.sub(p2, 260, Nearest).abs(260, Nearest) < @mpf.RawMpf::parse("1e-16"),
  )
  assert_true(
    b.sub(p2.negated(0, Down), 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("1e-16"),
  )
}

///|
test "trig around n*pi subset from mpmath test_trig" {
  let p = pi(260, Nearest)
  for n in [1, 2, 6, 11, 100, 1001] {
    let x = p.mul(@mpf.RawMpf::from_int(n), 260, Nearest)
    let s = sin(x, 260, Nearest)
    let c = cos(x, 260, Nearest)
    assert_true(s.abs(260, Nearest) < @mpf.RawMpf::parse("1e-10"))
    let expected = if n % 2 == 0 {
      @mpf.RawMpf::one()
    } else {
      @mpf.RawMpf::negative_one()
    }
    assert_true(
      c.sub(expected, 260, Nearest).abs(260, Nearest) <
      @mpf.RawMpf::parse("1e-10"),
    )
  }
}

///|
test "special function special-values subset from mpmath test_special" {
  @debug.assert_eq(
    exp(@mpf.RawMpf::infinity(), 120, Nearest),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    exp(@mpf.RawMpf::negative_infinity(), 120, Nearest),
    @mpf.RawMpf::zero(),
  )
  assert_true(exp(@mpf.RawMpf::nan(), 120, Nearest).is_nan())
  @debug.assert_eq(
    ln(@mpf.RawMpf::infinity(), 120, Nearest),
    @mpf.RawMpf::infinity(),
  )
  assert_true(ln(@mpf.RawMpf::nan(), 120, Nearest).is_nan())
  assert_true(sin(@mpf.RawMpf::infinity(), 120, Nearest).is_nan())
  assert_true(sin(@mpf.RawMpf::nan(), 120, Nearest).is_nan())
}
