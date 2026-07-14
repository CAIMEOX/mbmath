///|
fn assert_parts(
  z : RawMpc,
  real : @mpf.RawMpf,
  imag : @mpf.RawMpf,
) -> Unit raise {
  assert_eq(z.real, real)
  assert_eq(z.imag, imag)
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
  let expected = @mpf.from_str(expected_text, prec~, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, expected, prec, @mpf.round_nearest),
    prec,
    @mpf.round_nearest,
  )
  let digits = mpc_mantissa_digit_count(expected_text)
  let sig_digits = if digits <= 1 { 0 } else { digits - 1 }
  let rel_tol = if sig_digits == 0 {
    @mpf.fone
  } else {
    @mpf.from_str("1e-\{sig_digits}", prec~, rnd=@mpf.round_nearest)
  }
  let mut scale = @mpf.mpf_abs(expected, prec, @mpf.round_nearest)
  if @mpf.mpf_lt(scale, @mpf.fone) {
    scale = @mpf.fone
  }
  let tol = @mpf.mpf_mul(scale, rel_tol, prec, @mpf.round_nearest)
  assert_true(@mpf.mpf_le(err, tol))
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
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(2))
  let w = from_parts(@mpf.from_int(3), @mpf.from_int(-4))
  assert_parts(
    mpc_add(z, w, 30, @mpf.round_nearest),
    @mpf.from_int(4),
    @mpf.from_int(-2),
  )
  assert_parts(
    mpc_sub(z, w, 30, @mpf.round_nearest),
    @mpf.from_int(-2),
    @mpf.from_int(6),
  )
  assert_parts(
    mpc_mul(z, w, 30, @mpf.round_nearest),
    @mpf.from_int(11),
    @mpf.from_int(2),
  )
}

///|
test "mpc div basic exact case" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(3))
  let w = from_parts(@mpf.from_int(1), @mpf.from_int(1))
  assert_parts(
    mpc_div(z, w, 40, @mpf.round_nearest),
    @mpf.from_int(2),
    @mpf.from_int(1),
  )
}

///|
test "mpc div denominator inf finite numerator returns zero" {
  let z = from_parts(@mpf.from_int(5), @mpf.from_int(-2))
  let w = from_parts(@mpf.finf, @mpf.fzero)
  assert_eq(mpc_div(z, w, 40, @mpf.round_nearest), zero())
}

///|
test "mpc predicates and unary helpers" {
  let z = from_parts(@mpf.from_int(-3), @mpf.from_int(4))
  assert_true(mpc_is_nonzero(z))
  assert_false(mpc_is_nonzero(zero()))
  assert_true(mpc_is_inf(from_parts(@mpf.finf, @mpf.from_int(1))))
  assert_true(mpc_is_infnan(from_parts(@mpf.fzero, @mpf.fnan)))
  assert_parts(
    mpc_pos(z, 30, @mpf.round_nearest),
    @mpf.from_int(-3),
    @mpf.from_int(4),
  )
  assert_parts(
    mpc_neg(z, 30, @mpf.round_nearest),
    @mpf.from_int(3),
    @mpf.from_int(-4),
  )
  assert_parts(
    mpc_conjugate(z, 30, @mpf.round_nearest),
    @mpf.from_int(-3),
    @mpf.from_int(-4),
  )
}

///|
test "mpc real-mixed helpers" {
  let z = from_parts(@mpf.from_int(2), @mpf.from_int(3))
  assert_parts(
    mpc_add_mpf(z, @mpf.from_int(4), 40, @mpf.round_nearest),
    @mpf.from_int(6),
    @mpf.from_int(3),
  )
  assert_parts(
    mpc_sub_mpf(z, @mpf.from_int(4), 40, @mpf.round_nearest),
    @mpf.from_int(-2),
    @mpf.from_int(3),
  )
  assert_parts(
    mpc_mpf_sub(@mpf.from_int(4), z, 40, @mpf.round_nearest),
    @mpf.from_int(2),
    @mpf.from_int(-3),
  )
  assert_parts(
    mpc_mul_mpf(z, @mpf.from_int(4), 40, @mpf.round_nearest),
    @mpf.from_int(8),
    @mpf.from_int(12),
  )
  assert_parts(
    mpc_div_mpf(z, @mpf.from_int(2), 40, @mpf.round_nearest),
    @mpf.from_int(1),
    @mpf.from_man_exp(3N, -1, 0, @mpf.round_down),
  )
}

///|
test "mpc reciprocal and mpf_div" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(1))
  assert_parts(
    mpc_reciprocal(z, 50, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    @mpf.from_man_exp(-1N, -1, 0, @mpf.round_down),
  )
  assert_parts(
    mpc_mpf_div(@mpf.from_int(2), z, 50, @mpf.round_nearest),
    @mpf.from_int(1),
    @mpf.from_int(-1),
  )
  assert_eq(
    mpc_mpf_div(
      @mpf.from_int(2),
      from_parts(@mpf.finf, @mpf.fzero),
      30,
      @mpf.round_nearest,
    ),
    zero(),
  )
}

///|
test "mpc shift mul_int floor ceil nint frac" {
  let z = from_parts(@mpf.from_str("1.5"), @mpf.from_str("-2.25"))
  assert_parts(mpc_shift(z, 1), @mpf.from_int(3), @mpf.from_str("-4.5"))
  assert_parts(
    mpc_mul_int(z, -2, 50, @mpf.round_nearest),
    @mpf.from_int(-3),
    @mpf.from_str("4.5"),
  )
  assert_parts(
    mpc_floor(z, 0, @mpf.round_nearest),
    @mpf.from_int(1),
    @mpf.from_int(-3),
  )
  assert_parts(
    mpc_ceil(z, 0, @mpf.round_nearest),
    @mpf.from_int(2),
    @mpf.from_int(-2),
  )
  assert_parts(
    mpc_nint(z, 0, @mpf.round_nearest),
    @mpf.from_int(2),
    @mpf.from_int(-2),
  )
  assert_parts(
    mpc_frac(z, 50, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    @mpf.from_man_exp(3N, -2, 0, @mpf.round_down),
  )
}

///|
test "mpc abs arg sqrt" {
  let z = from_parts(@mpf.from_int(3), @mpf.from_int(4))
  assert_eq(mpc_abs(z, 60, @mpf.round_nearest), @mpf.from_int(5))
  let arg = mpc_arg(
    from_parts(@mpf.from_int(1), @mpf.from_int(1)),
    80,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(arg, "0.78539816339", 12)
  assert_parts(
    mpc_sqrt(
      from_parts(@mpf.from_int(3), @mpf.from_int(4)),
      80,
      @mpf.round_nearest,
    ),
    @mpf.from_int(2),
    @mpf.from_int(1),
  )
  assert_parts(
    mpc_sqrt(from_parts(@mpf.from_int(-4), @mpf.fzero), 80, @mpf.round_nearest),
    @mpf.fzero,
    @mpf.from_int(2),
  )
}

///|
test "mpc pow_int basic cases" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(1))
  assert_parts(
    mpc_pow_int(z, 2, 50, @mpf.round_nearest),
    @mpf.fzero,
    @mpf.from_int(2),
  )
  assert_parts(
    mpc_pow_int(z, 3, 50, @mpf.round_nearest),
    @mpf.from_int(-2),
    @mpf.from_int(2),
  )
  assert_parts(
    mpc_pow_int(z, -1, 50, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    @mpf.from_man_exp(-1N, -1, 0, @mpf.round_down),
  )
  assert_parts(
    mpc_pow_int(
      from_parts(@mpf.from_int(2), @mpf.fzero),
      -3,
      50,
      @mpf.round_nearest,
    ),
    @mpf.from_man_exp(1N, -3, 0, @mpf.round_down),
    @mpf.fzero,
  )
  assert_parts(
    mpc_pow_int(
      from_parts(@mpf.fzero, @mpf.from_int(2)),
      2,
      50,
      @mpf.round_nearest,
    ),
    @mpf.from_int(-4),
    @mpf.fzero,
  )
}

///|
test "mpc exp/log/pow and trig-hyperbolic subset" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(2))
  let e = mpc_exp(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(e.real, "-1.131204383756", 14)
  assert_mpf_close_with_dps(e.imag, "2.471726672004", 14)
  let l = mpc_log(
    from_parts(@mpf.from_int(3), @mpf.from_int(4)),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(l.real, "1.609437912434", 14)
  assert_mpf_close_with_dps(l.imag, "0.927295218001", 14)
  let s = mpc_sin(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(s.real, "3.165778513216", 14)
  assert_mpf_close_with_dps(s.imag, "1.959601041421", 14)
  let c = mpc_cos(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(c.real, "2.032723007019", 14)
  assert_mpf_close_with_dps(c.imag, "-3.051897799151", 14)
  let t = mpc_tan(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(t.real, "0.033812826079", 14)
  assert_mpf_close_with_dps(t.imag, "1.014793616146", 14)
  let sh = mpc_sinh(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(sh.real, "-0.489056259041", 14)
  assert_mpf_close_with_dps(sh.imag, "1.403119250622", 14)
  let ch = mpc_cosh(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(ch.real, "-0.642148124715", 14)
  assert_mpf_close_with_dps(ch.imag, "1.068607421382", 14)
  let th = mpc_tanh(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(th.real, "1.166736257240", 14)
  assert_mpf_close_with_dps(th.imag, "-0.243458201185", 14)
  let p1 = mpc_pow(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    from_parts(@mpf.fzero, @mpf.fone),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(p1.real, "0.769238901363", 14)
  assert_mpf_close_with_dps(p1.imag, "0.638961276313", 14)
  let p2 = mpc_pow_mpf(z, @mpf.from_str("0.5"), 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(p2.real, "1.272019649514", 14)
  assert_mpf_close_with_dps(p2.imag, "0.786151377757", 14)
  let sq = mpc_square(z, 80, @mpf.round_nearest)
  assert_parts(sq, @mpf.from_int(-3), @mpf.from_int(4))
}

///|
test "mpc_pow_int zero negative exponent returns nan" {
  let value = mpc_pow_int(zero(), -1, 20, @mpf.round_nearest)
  assert_true(mpc_is_infnan(value))
}

///|
test "mpc_div by zero returns nan" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(1))
  let value = mpc_div(z, zero(), 20, @mpf.round_nearest)
  assert_true(@mpf.is_nan(value.real))
  assert_true(@mpf.is_nan(value.imag))
}

///|
test "panic mpc_log zero" {
  ignore(mpc_log(zero(), 20, @mpf.round_nearest))
}

///|
test "mpc to_str to_complex hash and ln alias" {
  let z = from_parts(@mpf.from_str("1.25"), @mpf.from_str("-2.5"))
  assert_eq(mpc_to_str(z, dps=10), "1.25 - 2.5j")
  let (re_s, im_s) = mpc_to_complex(z, dps=10)
  assert_eq(re_s, "1.25")
  assert_eq(im_s, "-2.5")
  let h_expect = @mpf.mpf_hash(z.real) + 1000003 * @mpf.mpf_hash(z.imag)
  let h = if h_expect == -1 { -2 } else { h_expect }
  assert_eq(mpc_hash(z), h)
  let l = mpc_ln(
    from_parts(@mpf.from_int(3), @mpf.from_int(4)),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(l.real, "1.609437912434", 14)
  assert_mpf_close_with_dps(l.imag, "0.927295218001", 14)
}

///|
test "mpc pi-family and expj subset" {
  let cp = mpc_cos_pi(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(cp.real, "0.0", 10)
  let sp = mpc_sin_pi(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(sp.real, "0.7071067", 10)
  let z = from_parts(@mpf.from_str("0.75"), @mpf.from_str("0.0"))
  let (cz, sz) = mpc_cos_sin(z, 120, @mpf.round_nearest)
  assert_eq(cz.imag, @mpf.fzero)
  assert_eq(sz.imag, @mpf.fzero)
  let (czp, szp) = mpc_cos_sin_pi(z, 120, @mpf.round_nearest)
  assert_eq(czp.imag, @mpf.fzero)
  assert_eq(szp.imag, @mpf.fzero)
  let ej = mpc_expj(
    from_parts(@libelefun.mpf_pi(140, @mpf.round_nearest), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ej.real, "-1.0", 10)
  let ejp = mpc_expjpi(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ejp.real, "-1.0", 10)
}

///|
test "mpc inverse trig-hyperbolic and roots subset" {
  let a = mpc_atan(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(a.real, "0.785398163397", 14)
  let asn = mpc_asin(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(asn.real, "0.523598775598", 14)
  let acs = mpc_acos(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(acs.real, "1.047197551196", 14)
  let ash = mpc_asinh(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ash.real, "0.881373587019", 14)
  let ach = mpc_acosh(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ach.real, "1.316957896924", 14)
  let ath = mpc_atanh(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ath.real, "0.549306144334", 14)
  let nr = mpc_nthroot(
    from_parts(@mpf.from_int(8), @mpf.fzero),
    3,
    120,
    @mpf.round_nearest,
  )
  assert_eq(nr, from_parts(@mpf.from_int(2), @mpf.fzero))
  let cr = mpc_cbrt(
    from_parts(@mpf.from_int(8), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_eq(cr, from_parts(@mpf.from_int(2), @mpf.fzero))
}

///|
test "mpc agm fibonacci and real-special wrappers" {
  let fib = mpc_fibonacci(
    from_parts(@mpf.from_int(10), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_eq(fib, from_parts(@mpf.from_int(55), @mpf.fzero))
  let agm = mpc_agm(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(agm.real, "0.560757145071", 14)
  let agm1 = mpc_agm1(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(agm1.real, "0.560757145071", 14)
  assert_eq(
    mpc_gamma(from_parts(@mpf.from_int(5), @mpf.fzero), 120, @mpf.round_nearest),
    from_parts(@mpf.from_int(24), @mpf.fzero),
  )
  let rg = mpc_rgamma(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(rg.real, "0.041666666666", 14)
  let lg = mpc_loggamma(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(lg.real, "3.178053830347", 14)
  let fac = mpc_factorial(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_eq(fac, from_parts(@mpf.from_int(120), @mpf.fzero))
  let har = mpc_harmonic(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(har.real, "2.283333333333", 14)
  let p0 = mpc_psi0(
    from_parts(@mpf.from_int(4), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(p0.real, "1.256117668431", 14)
  let p1 = mpc_psi(
    1,
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(p1.real))
  let ei = mpc_ei(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ei.real, "0.454219904863", 14)
  let e1 = mpc_e1(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(e1.real, "0.219383934395", 14)
  let si = mpc_si(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(si.real, "0.946083070367", 14)
  let ci = mpc_ci(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ci.real, "0.337403922900", 14)
  let j0 = mpc_besseljn(
    0,
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(j0.real, "0.765197686557", 14)
  let ek = mpc_ellipk(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ek.real, "1.685750354812", 14)
  let ee = mpc_ellipe(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(ee.real, "1.467462209339", 14)
}

///|
test "mpc zeta family subset" {
  let z2 = mpc_zeta(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(z2.real, "1.644934066848", 14)
  let a2 = mpc_altzeta(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_mpf_close_with_dps(a2.real, "0.822467033424", 14)
  let s10 = mpc_zetasum(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
    start=1,
    terms=10,
  )
  assert_mpf_close_with_dps(s10.real, "1.549767731166", 14)
  let zc = mpc_zeta(
    from_parts(@mpf.from_str("0.5"), @mpf.from_str("0.25")),
    100,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(zc.real))
  assert_true(@mpf.is_finite(zc.imag))
}

///|
test "mpc complex special functions subset" {
  let z = from_parts(@mpf.from_str("0.5"), @mpf.from_str("0.25"))
  let ei = mpc_ei(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(ei.real, "0.5438975", 10)
  assert_mpf_close_with_dps(ei.imag, "0.7867419", 10)
  let e1 = mpc_e1(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(e1.real, "0.4594499", 10)
  assert_mpf_close_with_dps(e1.imag, "-0.2675113", 10)
  let ci = mpc_ci(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(ci.real, "-0.0515129", 10)
  assert_mpf_close_with_dps(ci.imag, "0.4021216", 10)
  let si = mpc_si(z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(si.real, "0.4982025", 10)
  assert_mpf_close_with_dps(si.imag, "0.2405181", 10)
  let j1 = mpc_besseljn(1, z, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(j1.real, "0.2479511", 10)
  assert_mpf_close_with_dps(j1.imag, "0.1143621", 10)
  let m = from_parts(@mpf.from_str("0.25"), @mpf.from_str("0.1"))
  let ek = mpc_ellipk(m, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(ek.real, "1.6817722", 10)
  assert_mpf_close_with_dps(ek.imag, "0.0538075", 10)
  let ee = mpc_ellipe(m, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(ee.real, "1.4685096", 10)
  assert_mpf_close_with_dps(ee.imag, "-0.0436005", 10)
  let w = from_parts(@mpf.from_str("2.5"), @mpf.from_str("0.5"))
  let g = mpc_gamma(w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(g.real, "1.1723958", 10)
  assert_mpf_close_with_dps(g.imag, "0.4365070", 10)
  let rg = mpc_rgamma(w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(rg.real, "0.7491105", 10)
  assert_mpf_close_with_dps(rg.imag, "-0.2789092", 10)
  let lg = mpc_loggamma(w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(lg.real, "0.2239590", 10)
  assert_mpf_close_with_dps(lg.imag, "0.3564195", 10)
  let h = mpc_harmonic(w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(h.real, "1.6937236", 10)
  assert_mpf_close_with_dps(h.imag, "0.1637364", 10)
  let p0 = mpc_psi0(w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(p0.real, "0.7318926", 10)
  assert_mpf_close_with_dps(p0.imag, "0.2406595", 10)
  let p1 = mpc_psi(1, w, 140, @mpf.round_nearest)
  assert_mpf_close_with_dps(p1.real, "0.463802495540", 14)
  assert_mpf_close_with_dps(p1.imag, "-0.111892198603", 14)
  let fac = mpc_factorial(w, 140, @mpf.round_nearest)
  assert_true(@mpf.is_finite(fac.real))
  assert_true(@mpf.is_finite(fac.imag))
}

///|
test "mpc_ci_si_taylor subset" {
  let re = @mpf.from_str("0.5")
  let im = @mpf.from_str("0.25")
  let ci_core = mpc_ci_si_taylor(re, im, 180, which=0)
  assert_mpf_close_with_dps(ci_core.real, "-0.047153243510", 14)
  assert_mpf_close_with_dps(ci_core.imag, "-0.061525939930", 14)
  let si = mpc_ci_si_taylor(re, im, 180, which=1)
  assert_mpf_close_with_dps(si.real, "0.498202520036", 14)
  assert_mpf_close_with_dps(si.imag, "0.240518169433", 14)
}

///|
test "mpc_ci_si_taylor out-of-range fallback subset" {
  let p = 220
  let z_big = from_parts(@mpf.from_str("20"), @mpf.from_str("5"))
  let ci_series_big = mpc_ci_si_taylor(z_big.real, z_big.imag, p, which=0)
  let si_series_big = mpc_ci_si_taylor(z_big.real, z_big.imag, p, which=1)
  let ci_big_rebuilt = mpc_add(
    mpc_add(
      from_parts(@gammazeta.mpf_euler(p, @mpf.round_nearest), @mpf.fzero),
      mpc_ln(z_big, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    ci_series_big,
    p,
    @mpf.round_nearest,
  )
  let ci_big = mpc_ci(z_big, p, @mpf.round_nearest)
  let si_big = mpc_si(z_big, p, @mpf.round_nearest)
  let err_ci_big = mpc_abs(
    mpc_sub(ci_big_rebuilt, ci_big, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let err_si_big = mpc_abs(
    mpc_sub(si_series_big, si_big, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(err_ci_big))
  assert_true(@mpf.is_finite(err_si_big))
  let z_tiny = from_parts(@mpf.from_str("1e-80"), @mpf.from_str("-2e-80"))
  let ci_series_tiny = mpc_ci_si_taylor(z_tiny.real, z_tiny.imag, p, which=0)
  let si_series_tiny = mpc_ci_si_taylor(z_tiny.real, z_tiny.imag, p, which=1)
  let ci_tiny_abs = mpc_abs(ci_series_tiny, p, @mpf.round_nearest)
  let si_tiny_err = mpc_abs(
    mpc_sub(si_series_tiny, z_tiny, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(ci_tiny_abs, @mpf.from_str("1e-60")))
  assert_true(@mpf.mpf_lt(si_tiny_err, @mpf.from_str("1e-60")))
}

///|
test "mpc ci/si tiny and asymptotic fallback subset" {
  let z_tiny = from_parts(@mpf.from_str("1e-30"), @mpf.from_str("2e-30"))
  let p = 220
  let ci_tiny = mpc_ci(z_tiny, p, @mpf.round_nearest)
  let si_tiny = mpc_si(z_tiny, p, @mpf.round_nearest)
  let target_ci = mpc_add(
    from_parts(@gammazeta.mpf_euler(p, @mpf.round_nearest), @mpf.fzero),
    mpc_ln(z_tiny, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let ci_err = mpc_abs(
    mpc_sub(ci_tiny, target_ci, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  let si_err = mpc_abs(
    mpc_sub(si_tiny, z_tiny, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(ci_err, @mpf.from_str("1e-25")))
  assert_true(@mpf.mpf_lt(si_err, @mpf.from_str("1e-25")))
  let z_big = from_parts(@mpf.from_str("5"), @mpf.from_str("3"))
  let ci_big = mpc_ci(z_big, 180, @mpf.round_nearest)
  let si_big = mpc_si(z_big, 180, @mpf.round_nearest)
  assert_true(@mpf.is_finite(ci_big.real))
  assert_true(@mpf.is_finite(ci_big.imag))
  assert_true(@mpf.is_finite(si_big.real))
  assert_true(@mpf.is_finite(si_big.imag))
}

///|
test "mpc_nthroot_fixed subset" {
  let prec = 80
  let re = @mpf.from_str("0.5")
  let im = @mpf.from_str("0.25")
  let a = mpf_to_fixed_signed_for_test(re, prec)
  let b = mpf_to_fixed_signed_for_test(im, prec)
  let (re_fix, im_fix) = mpc_nthroot_fixed(a, b, 5, prec)
  let re_v = @mpf.from_man_exp(re_fix, -(prec + 10), 180, @mpf.round_nearest)
  let im_v = @mpf.from_man_exp(im_fix, -(prec + 10), 180, @mpf.round_nearest)
  assert_mpf_close_with_dps(re_v, "0.886370150250", 14)
  assert_mpf_close_with_dps(im_v, "0.082429078456", 14)
  let root = mpc_nthroot(from_parts(re, im), 5, 180, @mpf.round_nearest)
  assert_mpf_close_with_dps(root.real, "0.886370150250", 14)
  assert_mpf_close_with_dps(root.imag, "0.082429078456", 14)
}
