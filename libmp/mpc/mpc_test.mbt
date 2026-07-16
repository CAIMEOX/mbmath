///|
fn assert_parts(
  z : RawMpc,
  real : @mpf.RawMpf,
  imag : @mpf.RawMpf,
) -> Unit raise {
  @debug.assert_eq(z.real, real)
  @debug.assert_eq(z.imag, imag)
}

///|
fn mpc_dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn mpc_mantissa_digit_count(expected_text : String) -> Int {
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
fn assert_mpf_close_with_dps(
  x : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = mpc_dps_to_prec(dps)
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = x.sub(expected, prec, Nearest).abs(prec, Nearest)
  let digits = mpc_mantissa_digit_count(expected_text)
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
fn mpf_to_fixed_signed_for_test(x : @mpf.RawMpf, prec : Int) -> BigInt {
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  let offset = x.exp + prec
  if offset >= 0 {
    signed_man << offset
  } else {
    signed_man >> -offset
  }
}

///|
test "mpc add/sub/mul" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(2))
  let w = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(-4))
  assert_parts(
    z.add(w, 30, Nearest),
    @mpf.RawMpf::from_int(4),
    @mpf.RawMpf::from_int(-2),
  )
  assert_parts(
    z.sub(w, 30, Nearest),
    @mpf.RawMpf::from_int(-2),
    @mpf.RawMpf::from_int(6),
  )
  assert_parts(
    z.mul(w, 30, Nearest),
    @mpf.RawMpf::from_int(11),
    @mpf.RawMpf::from_int(2),
  )
}

///|
test "mpc div basic exact case" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(3))
  let w = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1))
  assert_parts(
    z.div(w, 40, Nearest),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(1),
  )
}

///|
test "mpc div denominator inf finite numerator returns zero" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::from_int(-2))
  let w = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero())
  @debug.assert_eq(z.div(w, 40, Nearest), RawMpc::zero())
}

///|
test "mpc predicates and unary helpers" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(-3), @mpf.RawMpf::from_int(4))
  assert_true(z.is_nonzero())
  assert_false(RawMpc::zero().is_nonzero())
  assert_true(
    RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::from_int(1)).is_infinite(),
  )
  assert_true(
    RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::nan()).is_non_finite(),
  )
  assert_parts(
    z.rounded(30, Nearest),
    @mpf.RawMpf::from_int(-3),
    @mpf.RawMpf::from_int(4),
  )
  assert_parts(
    z.negated(30, Nearest),
    @mpf.RawMpf::from_int(3),
    @mpf.RawMpf::from_int(-4),
  )
  assert_parts(
    z.conjugate(30, Nearest),
    @mpf.RawMpf::from_int(-3),
    @mpf.RawMpf::from_int(-4),
  )
}

///|
test "mpc real-mixed helpers" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(3))
  assert_parts(
    z.add_real(@mpf.RawMpf::from_int(4), 40, Nearest),
    @mpf.RawMpf::from_int(6),
    @mpf.RawMpf::from_int(3),
  )
  assert_parts(
    z.sub_real(@mpf.RawMpf::from_int(4), 40, Nearest),
    @mpf.RawMpf::from_int(-2),
    @mpf.RawMpf::from_int(3),
  )
  assert_parts(
    z.subtracted_from_real(@mpf.RawMpf::from_int(4), 40, Nearest),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(-3),
  )
  assert_parts(
    z.mul_real(@mpf.RawMpf::from_int(4), 40, Nearest),
    @mpf.RawMpf::from_int(8),
    @mpf.RawMpf::from_int(12),
  )
  assert_parts(
    z.div_real(@mpf.RawMpf::from_int(2), 40, Nearest),
    @mpf.RawMpf::from_int(1),
    @mpf.RawMpf::from_mantissa_exponent(3N, -1, 0, Down),
  )
}

///|
test "mpc reciprocal and mpf_div" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1))
  assert_parts(
    z.reciprocal(50, Nearest),
    @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down),
    @mpf.RawMpf::from_mantissa_exponent(-1N, -1, 0, Down),
  )
  assert_parts(
    z.real_divided_by(@mpf.RawMpf::from_int(2), 50, Nearest),
    @mpf.RawMpf::from_int(1),
    @mpf.RawMpf::from_int(-1),
  )
  @debug.assert_eq(
    RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero()).real_divided_by(
      @mpf.RawMpf::from_int(2),
      30,
      Nearest,
    ),
    RawMpc::zero(),
  )
}

///|
test "mpc shift mul_int floor ceil nint frac" {
  let z = RawMpc::new(@mpf.RawMpf::parse("1.5"), @mpf.RawMpf::parse("-2.25"))
  assert_parts(
    z.scale_pow2(1),
    @mpf.RawMpf::from_int(3),
    @mpf.RawMpf::parse("-4.5"),
  )
  assert_parts(
    z.mul_int(-2, 50, Nearest),
    @mpf.RawMpf::from_int(-3),
    @mpf.RawMpf::parse("4.5"),
  )
  assert_parts(
    z.floor(0, Nearest),
    @mpf.RawMpf::from_int(1),
    @mpf.RawMpf::from_int(-3),
  )
  assert_parts(
    z.ceil(0, Nearest),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(-2),
  )
  assert_parts(
    z.nearest_integer(0, Nearest),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(-2),
  )
  assert_parts(
    z.fractional_part(50, Nearest),
    @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down),
    @mpf.RawMpf::from_mantissa_exponent(3N, -2, 0, Down),
  )
}

///|
test "mpc abs arg sqrt" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4))
  @debug.assert_eq(z.abs(60, Nearest), @mpf.RawMpf::from_int(5))
  let arg = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1)).arg(
    80,
    Nearest,
  )
  assert_mpf_close_with_dps(arg, "0.78539816339", 12)
  assert_parts(
    RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4)).sqrt(
      80,
      Nearest,
    ),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::from_int(1),
  )
  assert_parts(
    RawMpc::new(@mpf.RawMpf::from_int(-4), @mpf.RawMpf::zero()).sqrt(
      80,
      Nearest,
    ),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::from_int(2),
  )
}

///|
test "mpc pow_int basic cases" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1))
  assert_parts(
    z.pow_int(2, 50, Nearest),
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::from_int(2),
  )
  assert_parts(
    z.pow_int(3, 50, Nearest),
    @mpf.RawMpf::from_int(-2),
    @mpf.RawMpf::from_int(2),
  )
  assert_parts(
    z.pow_int(-1, 50, Nearest),
    @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down),
    @mpf.RawMpf::from_mantissa_exponent(-1N, -1, 0, Down),
  )
  assert_parts(
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).pow_int(
      -3,
      50,
      Nearest,
    ),
    @mpf.RawMpf::from_mantissa_exponent(1N, -3, 0, Down),
    @mpf.RawMpf::zero(),
  )
  assert_parts(
    RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::from_int(2)).pow_int(
      2,
      50,
      Nearest,
    ),
    @mpf.RawMpf::from_int(-4),
    @mpf.RawMpf::zero(),
  )
}

///|
test "mpc exp/log/pow and trig-hyperbolic subset" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(2))
  let e = z.exp(140, Nearest)
  assert_mpf_close_with_dps(e.real, "-1.131204383756", 14)
  assert_mpf_close_with_dps(e.imag, "2.471726672004", 14)
  let l = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4)).log(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(l.real, "1.609437912434", 14)
  assert_mpf_close_with_dps(l.imag, "0.927295218001", 14)
  let s = z.sin(140, Nearest)
  assert_mpf_close_with_dps(s.real, "3.165778513216", 14)
  assert_mpf_close_with_dps(s.imag, "1.959601041421", 14)
  let c = z.cos(140, Nearest)
  assert_mpf_close_with_dps(c.real, "2.032723007019", 14)
  assert_mpf_close_with_dps(c.imag, "-3.051897799151", 14)
  let t = z.tan(140, Nearest)
  assert_mpf_close_with_dps(t.real, "0.033812826079", 14)
  assert_mpf_close_with_dps(t.imag, "1.014793616146", 14)
  let sh = z.sinh(140, Nearest)
  assert_mpf_close_with_dps(sh.real, "-0.489056259041", 14)
  assert_mpf_close_with_dps(sh.imag, "1.403119250622", 14)
  let ch = z.cosh(140, Nearest)
  assert_mpf_close_with_dps(ch.real, "-0.642148124715", 14)
  assert_mpf_close_with_dps(ch.imag, "1.068607421382", 14)
  let th = z.tanh(140, Nearest)
  assert_mpf_close_with_dps(th.real, "1.166736257240", 14)
  assert_mpf_close_with_dps(th.imag, "-0.243458201185", 14)
  let p1 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).pow(
    RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::one()),
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(p1.real, "0.769238901363", 14)
  assert_mpf_close_with_dps(p1.imag, "0.638961276313", 14)
  let p2 = z.pow_real(@mpf.RawMpf::parse("0.5"), 140, Nearest)
  assert_mpf_close_with_dps(p2.real, "1.272019649514", 14)
  assert_mpf_close_with_dps(p2.imag, "0.786151377757", 14)
  let sq = z.square(80, Nearest)
  assert_parts(sq, @mpf.RawMpf::from_int(-3), @mpf.RawMpf::from_int(4))
}

///|
test "mpc_pow_int zero negative exponent raises PoleError" {
  try RawMpc::zero().pow_int(-1, 20, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected PoleError for a negative power of zero")
  }
}

///|
test "mpc_div by zero raises PoleError" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1))
  try z.div(RawMpc::zero(), 20, Nearest) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected PoleError for complex division by zero")
  }
}

///|
test "panic mpc_log zero" {
  ignore(RawMpc::zero().log(20, Nearest))
}

///|
test "mpc to_str to_complex hash and ln alias" {
  let z = RawMpc::new(@mpf.RawMpf::parse("1.25"), @mpf.RawMpf::parse("-2.5"))
  @debug.assert_eq(z.format(dps=10), "1.25 - 2.5j")
  let (re_s, im_s) = z.format_components(dps=10)
  @debug.assert_eq(re_s, "1.25")
  @debug.assert_eq(im_s, "-2.5")
  let h_expect = z.real.stable_hash() + 1000003 * z.imag.stable_hash()
  let h = if h_expect == -1 { -2 } else { h_expect }
  @debug.assert_eq(z.stable_hash(), h)
  let l = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4)).ln(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(l.real, "1.609437912434", 14)
  assert_mpf_close_with_dps(l.imag, "0.927295218001", 14)
}

///|
test "mpc pi-family and expj subset" {
  let cp = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::zero()).cos_pi(
    120,
    Nearest,
  )
  assert_mpf_close_with_dps(cp.real, "0.0", 10)
  let sp = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()).sin_pi(
    120,
    Nearest,
  )
  assert_mpf_close_with_dps(sp.real, "0.7071067", 10)
  let z = RawMpc::new(@mpf.RawMpf::parse("0.75"), @mpf.RawMpf::parse("0.0"))
  let (cz, sz) = z.cos_sin(120, Nearest)
  @debug.assert_eq(cz.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(sz.imag, @mpf.RawMpf::zero())
  let (czp, szp) = z.cos_sin_pi(120, Nearest)
  @debug.assert_eq(czp.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(szp.imag, @mpf.RawMpf::zero())
  let ej = RawMpc::new(@libelefun.pi(140, Nearest), @mpf.RawMpf::zero()).exp_i(
    120,
    Nearest,
  )
  assert_mpf_close_with_dps(ej.real, "-1.0", 10)
  let ejp = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).exp_i_pi(
    120,
    Nearest,
  )
  assert_mpf_close_with_dps(ejp.real, "-1.0", 10)
}

///|
test "mpc inverse trig-hyperbolic and roots subset" {
  let a = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).atan(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(a.real, "0.785398163397", 14)
  let asn = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::zero()).asin(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(asn.real, "0.523598775598", 14)
  let acs = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::zero()).acos(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(acs.real, "1.047197551196", 14)
  let ash = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).asinh(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ash.real, "0.881373587019", 14)
  let ach = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).acosh(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ach.real, "1.316957896924", 14)
  let ath = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::zero()).atanh(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ath.real, "0.549306144334", 14)
  let nr = RawMpc::new(@mpf.RawMpf::from_int(8), @mpf.RawMpf::zero()).nthroot(
    3,
    120,
    Nearest,
  )
  @debug.assert_eq(
    nr,
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()),
  )
  let cr = RawMpc::new(@mpf.RawMpf::from_int(8), @mpf.RawMpf::zero()).cbrt(
    120,
    Nearest,
  )
  @debug.assert_eq(
    cr,
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()),
  )
}

///|
test "mpc agm fibonacci and real-special wrappers" {
  let fib = RawMpc::new(@mpf.RawMpf::from_int(10), @mpf.RawMpf::zero()).fibonacci(
    120,
    Nearest,
  )
  @debug.assert_eq(
    fib,
    RawMpc::new(@mpf.RawMpf::from_int(55), @mpf.RawMpf::zero()),
  )
  let agm = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).agm(
    RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()),
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(agm.real, "0.560757145071", 14)
  let agm1 = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()).agm_with_one(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(agm1.real, "0.560757145071", 14)
  @debug.assert_eq(
    RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::zero()).gamma(
      120,
      Nearest,
    ),
    RawMpc::new(@mpf.RawMpf::from_int(24), @mpf.RawMpf::zero()),
  )
  let rg = RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::zero()).rgamma(
    120,
    Nearest,
  )
  assert_mpf_close_with_dps(rg.real, "0.041666666666", 14)
  let lg = RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::zero()).loggamma(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(lg.real, "3.178053830347", 14)
  let fac = RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::zero()).factorial(
    120,
    Nearest,
  )
  @debug.assert_eq(
    fac,
    RawMpc::new(@mpf.RawMpf::from_int(120), @mpf.RawMpf::zero()),
  )
  let har = RawMpc::new(@mpf.RawMpf::from_int(5), @mpf.RawMpf::zero()).harmonic(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(har.real, "2.283333333333", 14)
  let p0 = RawMpc::new(@mpf.RawMpf::from_int(4), @mpf.RawMpf::zero()).digamma(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(p0.real, "1.256117668431", 14)
  let p1 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).polygamma(
    1,
    140,
    Nearest,
  )
  assert_true(p1.real.is_finite())
  let ei = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::zero()).ei(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ei.real, "0.454219904863", 14)
  let e1 = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).e1(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(e1.real, "0.219383934395", 14)
  let si = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).si(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(si.real, "0.946083070367", 14)
  let ci = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).ci(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ci.real, "0.337403922900", 14)
  let j0 = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::zero()).bessel_j(
    0,
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(j0.real, "0.765197686557", 14)
  let ek = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()).ellipk(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ek.real, "1.685750354812", 14)
  let ee = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()).ellipe(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(ee.real, "1.467462209339", 14)
}

///|
test "mpc zeta family subset" {
  let z2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).zeta(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(z2.real, "1.644934066848", 14)
  let a2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).eta(
    140,
    Nearest,
  )
  assert_mpf_close_with_dps(a2.real, "0.822467033424", 14)
  let s10 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).zeta_sum(
    140,
    Nearest,
    start=1,
    terms=10,
  )
  assert_mpf_close_with_dps(s10.real, "1.549767731166", 14)
  let zc = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::parse("0.25")).zeta(
    100,
    Nearest,
  )
  assert_true(zc.real.is_finite())
  assert_true(zc.imag.is_finite())
}

///|
test "mpc complex special functions subset" {
  let z = RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::parse("0.25"))
  let ei = z.ei(140, Nearest)
  assert_mpf_close_with_dps(ei.real, "0.5438975", 10)
  assert_mpf_close_with_dps(ei.imag, "0.7867419", 10)
  let e1 = z.e1(140, Nearest)
  assert_mpf_close_with_dps(e1.real, "0.4594499", 10)
  assert_mpf_close_with_dps(e1.imag, "-0.2675113", 10)
  let ci = z.ci(140, Nearest)
  assert_mpf_close_with_dps(ci.real, "-0.0515129", 10)
  assert_mpf_close_with_dps(ci.imag, "0.4021216", 10)
  let si = z.si(140, Nearest)
  assert_mpf_close_with_dps(si.real, "0.4982025", 10)
  assert_mpf_close_with_dps(si.imag, "0.2405181", 10)
  let j1 = z.bessel_j(1, 140, Nearest)
  assert_mpf_close_with_dps(j1.real, "0.2479511", 10)
  assert_mpf_close_with_dps(j1.imag, "0.1143621", 10)
  let m = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::parse("0.1"))
  let ek = m.ellipk(140, Nearest)
  assert_mpf_close_with_dps(ek.real, "1.6817722", 10)
  assert_mpf_close_with_dps(ek.imag, "0.0538075", 10)
  let ee = m.ellipe(140, Nearest)
  assert_mpf_close_with_dps(ee.real, "1.4685096", 10)
  assert_mpf_close_with_dps(ee.imag, "-0.0436005", 10)
  let w = RawMpc::new(@mpf.RawMpf::parse("2.5"), @mpf.RawMpf::parse("0.5"))
  let g = w.gamma(140, Nearest)
  assert_mpf_close_with_dps(g.real, "1.1723958", 10)
  assert_mpf_close_with_dps(g.imag, "0.4365070", 10)
  let rg = w.rgamma(140, Nearest)
  assert_mpf_close_with_dps(rg.real, "0.7491105", 10)
  assert_mpf_close_with_dps(rg.imag, "-0.2789092", 10)
  let lg = w.loggamma(140, Nearest)
  assert_mpf_close_with_dps(lg.real, "0.2239590", 10)
  assert_mpf_close_with_dps(lg.imag, "0.3564195", 10)
  let h = w.harmonic(140, Nearest)
  assert_mpf_close_with_dps(h.real, "1.6937236", 10)
  assert_mpf_close_with_dps(h.imag, "0.1637364", 10)
  let p0 = w.digamma(140, Nearest)
  assert_mpf_close_with_dps(p0.real, "0.7318926", 10)
  assert_mpf_close_with_dps(p0.imag, "0.2406595", 10)
  let p1 = w.polygamma(1, 140, Nearest)
  assert_mpf_close_with_dps(p1.real, "0.463802495540", 14)
  assert_mpf_close_with_dps(p1.imag, "-0.111892198603", 14)
  let fac = w.factorial(140, Nearest)
  assert_true(fac.real.is_finite())
  assert_true(fac.imag.is_finite())
}

///|
test "mpc_ci_si_taylor subset" {
  let re = @mpf.RawMpf::parse("0.5")
  let im = @mpf.RawMpf::parse("0.25")
  let ci_core = RawMpc::ci_si_taylor(re, im, 180, which=0)
  assert_mpf_close_with_dps(ci_core.real, "-0.047153243510", 14)
  assert_mpf_close_with_dps(ci_core.imag, "-0.061525939930", 14)
  let si = RawMpc::ci_si_taylor(re, im, 180, which=1)
  assert_mpf_close_with_dps(si.real, "0.498202520036", 14)
  assert_mpf_close_with_dps(si.imag, "0.240518169433", 14)
}

///|
test "mpc_ci_si_taylor out-of-range fallback subset" {
  let p = 220
  let z_big = RawMpc::new(@mpf.RawMpf::parse("20"), @mpf.RawMpf::parse("5"))
  let ci_series_big = RawMpc::ci_si_taylor(z_big.real, z_big.imag, p, which=0)
  let si_series_big = RawMpc::ci_si_taylor(z_big.real, z_big.imag, p, which=1)
  let ci_big_rebuilt = RawMpc::new(
      @gammazeta.euler(p, Nearest),
      @mpf.RawMpf::zero(),
    )
    .add(z_big.ln(p, Nearest), p, Nearest)
    .add(ci_series_big, p, Nearest)
  let ci_big = z_big.ci(p, Nearest)
  let si_big = z_big.si(p, Nearest)
  let err_ci_big = ci_big_rebuilt.sub(ci_big, p, Nearest).abs(p, Nearest)
  let err_si_big = si_series_big.sub(si_big, p, Nearest).abs(p, Nearest)
  assert_true(err_ci_big.is_finite())
  assert_true(err_si_big.is_finite())
  let z_tiny = RawMpc::new(
    @mpf.RawMpf::parse("1e-80"),
    @mpf.RawMpf::parse("-2e-80"),
  )
  let ci_series_tiny = RawMpc::ci_si_taylor(
    z_tiny.real,
    z_tiny.imag,
    p,
    which=0,
  )
  let si_series_tiny = RawMpc::ci_si_taylor(
    z_tiny.real,
    z_tiny.imag,
    p,
    which=1,
  )
  let ci_tiny_abs = ci_series_tiny.abs(p, Nearest)
  let si_tiny_err = si_series_tiny.sub(z_tiny, p, Nearest).abs(p, Nearest)
  assert_true(ci_tiny_abs < @mpf.RawMpf::parse("1e-60"))
  assert_true(si_tiny_err < @mpf.RawMpf::parse("1e-60"))
}

///|
test "mpc ci/si tiny and asymptotic fallback subset" {
  let z_tiny = RawMpc::new(
    @mpf.RawMpf::parse("1e-30"),
    @mpf.RawMpf::parse("2e-30"),
  )
  let p = 220
  let ci_tiny = z_tiny.ci(p, Nearest)
  let si_tiny = z_tiny.si(p, Nearest)
  let target_ci = RawMpc::new(@gammazeta.euler(p, Nearest), @mpf.RawMpf::zero()).add(
    z_tiny.ln(p, Nearest),
    p,
    Nearest,
  )
  let ci_err = ci_tiny.sub(target_ci, p, Nearest).abs(p, Nearest)
  let si_err = si_tiny.sub(z_tiny, p, Nearest).abs(p, Nearest)
  assert_true(ci_err < @mpf.RawMpf::parse("1e-25"))
  assert_true(si_err < @mpf.RawMpf::parse("1e-25"))
  let z_big = RawMpc::new(@mpf.RawMpf::parse("5"), @mpf.RawMpf::parse("3"))
  let ci_big = z_big.ci(180, Nearest)
  let si_big = z_big.si(180, Nearest)
  assert_true(ci_big.real.is_finite())
  assert_true(ci_big.imag.is_finite())
  assert_true(si_big.real.is_finite())
  assert_true(si_big.imag.is_finite())
}

///|
test "mpc_nthroot_fixed subset" {
  let prec = 80
  let re = @mpf.RawMpf::parse("0.5")
  let im = @mpf.RawMpf::parse("0.25")
  let a = mpf_to_fixed_signed_for_test(re, prec)
  let b = mpf_to_fixed_signed_for_test(im, prec)
  let (re_fix, im_fix) = RawMpc::nthroot_fixed(a, b, 5, prec)
  let re_v = @mpf.RawMpf::from_mantissa_exponent(
    re_fix,
    -(prec + 10),
    180,
    Nearest,
  )
  let im_v = @mpf.RawMpf::from_mantissa_exponent(
    im_fix,
    -(prec + 10),
    180,
    Nearest,
  )
  assert_mpf_close_with_dps(re_v, "0.886370150250", 14)
  assert_mpf_close_with_dps(im_v, "0.082429078456", 14)
  let root = RawMpc::new(re, im).nthroot(5, 180, Nearest)
  assert_mpf_close_with_dps(root.real, "0.886370150250", 14)
  assert_mpf_close_with_dps(root.imag, "0.082429078456", 14)
}
