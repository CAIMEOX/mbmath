///|
fn assert_close(v : @mpf.RawMpf, expected : String, tol : String) -> Unit raise {
  let e = @mpf.from_str(expected)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(v, e, 280, @mpf.round_nearest),
    280,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
test "p0 power fractional exact subset from mpmath test_power" {
  assert_eq(
    mpf_pow(@mpf.from_int(16), @mpf.from_str("2.5"), 220, @mpf.round_nearest),
    @mpf.from_int(1024),
  )
  assert_eq(
    mpf_pow(@mpf.from_int(64), @mpf.from_str("0.5"), 220, @mpf.round_nearest),
    @mpf.from_int(8),
  )
  assert_eq(
    mpf_pow(@mpf.from_int(64), @mpf.from_str("-0.5"), 220, @mpf.round_nearest),
    @mpf.from_str("0.125"),
  )
  assert_eq(
    mpf_pow(@mpf.from_int(16), @mpf.from_str("-2.5"), 220, @mpf.round_nearest),
    @mpf.from_str("0.0009765625"),
  )
}

///|
test "p0 power fractional decimal subset from mpmath test_power" {
  assert_close(
    mpf_pow(@mpf.from_int(10), @mpf.from_str("0.5"), 240, @mpf.round_nearest),
    "3.1622776601683791",
    "1e-12",
  )
  assert_close(
    mpf_pow(@mpf.from_int(10), @mpf.from_str("2.5"), 240, @mpf.round_nearest),
    "316.2277660168379",
    "1e-10",
  )
  assert_close(
    mpf_pow(@mpf.from_int(10), @mpf.from_str("-0.3"), 240, @mpf.round_nearest),
    "0.50118723362727224",
    "1e-12",
  )
}

///|
test "p0 pow_int directed rounding subset from mpmath test_power" {
  let eps = @mpf.from_man_exp(1N, -115, 0, @mpf.round_down)
  let pos10001 = @mpf.mpf_add(@mpf.fone, eps, 0, @mpf.round_nearest)
  let pos09999 = @mpf.mpf_sub(@mpf.fone, eps, 0, @mpf.round_nearest)
  let neg10001 = @mpf.mpf_neg(pos10001, 0, @mpf.round_down)
  let neg09999 = @mpf.mpf_neg(pos09999, 0, @mpf.round_down)
  let up_a = @mpf.mpf_pow_int(pos10001, 5, 40, @mpf.round_up)
  let up_b = @mpf.mpf_pow_int(pos09999, 5, 40, @mpf.round_up)
  assert_true(@mpf.mpf_gt(up_a, @mpf.fone))
  assert_eq(up_b, @mpf.fone)
  let dn_a = @mpf.mpf_pow_int(pos10001, 5, 40, @mpf.round_down)
  let dn_b = @mpf.mpf_pow_int(pos09999, 5, 40, @mpf.round_down)
  assert_eq(dn_a, @mpf.fone)
  assert_true(@mpf.mpf_lt(dn_b, @mpf.fone))
  let up_neg = @mpf.mpf_pow_int(neg10001, 5, 40, @mpf.round_up)
  let dn_neg = @mpf.mpf_pow_int(neg10001, 5, 40, @mpf.round_down)
  assert_true(@mpf.mpf_lt(up_neg, @mpf.fnone))
  assert_eq(dn_neg, @mpf.fnone)
}

///|
test "p0 trig near zero subset from mpmath test_trig" {
  let a = @mpf.from_str("1e-100")
  let b = @mpf.from_str("-1e-100")
  let s_a = mpf_sin(a, 260, @mpf.round_nearest)
  let c_a = mpf_cos(a, 260, @mpf.round_nearest)
  let t_a = mpf_tan(a, 260, @mpf.round_nearest)
  let s_b = mpf_sin(b, 260, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(s_a, a, 280, @mpf.round_nearest),
        280,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-130"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(c_a, @mpf.fone, 280, @mpf.round_nearest),
        280,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-130"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(t_a, a, 280, @mpf.round_nearest),
        280,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-130"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(s_b, b, 280, @mpf.round_nearest),
        280,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-130"),
    ),
  )
}

///|
test "p0 trig directed rounding ordering near zero from mpmath test_trig" {
  let a = @mpf.from_str("1e-100")
  let b = @mpf.from_str("-1e-100")
  let sn = mpf_sin(a, 260, @mpf.round_nearest)
  let sd = mpf_sin(a, 260, @mpf.round_down)
  let su = mpf_sin(a, 260, @mpf.round_up)
  assert_true(@mpf.mpf_le(sd, sn) && @mpf.mpf_le(sn, su))
  let sdn = mpf_sin(b, 260, @mpf.round_down)
  let sun = mpf_sin(b, 260, @mpf.round_up)
  assert_true(@mpf.mpf_le(sdn, sun))
  let cd = mpf_cos(a, 260, @mpf.round_down)
  let cu = mpf_cos(a, 260, @mpf.round_up)
  assert_true(@mpf.mpf_le(cd, cu))
}

///|
test "p0 atan infinities subset from mpmath test_special" {
  let p2 = @mpf.mpf_div(
    mpf_pi(220, @mpf.round_nearest),
    @mpf.from_int(2),
    220,
    @mpf.round_nearest,
  )
  let a = mpf_atan(@mpf.finf, 220, @mpf.round_nearest)
  let b = mpf_atan(@mpf.fninf, 220, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(a, p2, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-16"),
    ),
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(
          b,
          @mpf.mpf_neg(p2, 0, @mpf.round_down),
          260,
          @mpf.round_nearest,
        ),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("1e-16"),
    ),
  )
}

///|
test "p0 trig around n*pi subset from mpmath test_trig" {
  let p = mpf_pi(260, @mpf.round_nearest)
  for n in [1, 2, 6, 11, 100, 1001] {
    let x = @mpf.mpf_mul(p, @mpf.from_int(n), 260, @mpf.round_nearest)
    let s = mpf_sin(x, 260, @mpf.round_nearest)
    let c = mpf_cos(x, 260, @mpf.round_nearest)
    assert_true(
      @mpf.mpf_lt(
        @mpf.mpf_abs(s, 260, @mpf.round_nearest),
        @mpf.from_str("1e-10"),
      ),
    )
    let expected = if n % 2 == 0 { @mpf.fone } else { @mpf.fnone }
    assert_true(
      @mpf.mpf_lt(
        @mpf.mpf_abs(
          @mpf.mpf_sub(c, expected, 260, @mpf.round_nearest),
          260,
          @mpf.round_nearest,
        ),
        @mpf.from_str("1e-10"),
      ),
    )
  }
}

///|
test "p0 special function special-values subset from mpmath test_special" {
  assert_eq(mpf_exp(@mpf.finf, 120, @mpf.round_nearest), @mpf.finf)
  assert_eq(mpf_exp(@mpf.fninf, 120, @mpf.round_nearest), @mpf.fzero)
  assert_true(@mpf.is_nan(mpf_exp(@mpf.fnan, 120, @mpf.round_nearest)))
  assert_eq(mpf_ln(@mpf.finf, 120, @mpf.round_nearest), @mpf.finf)
  assert_true(@mpf.is_nan(mpf_ln(@mpf.fnan, 120, @mpf.round_nearest)))
  assert_true(@mpf.is_nan(mpf_sin(@mpf.finf, 120, @mpf.round_nearest)))
  assert_true(@mpf.is_nan(mpf_sin(@mpf.fnan, 120, @mpf.round_nearest)))
}
