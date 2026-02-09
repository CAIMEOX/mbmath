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
fn mpf_to_fixed_signed_for_test(x : @mpf.RawMpf, prec : Int) -> BigInt {
  let signed_man = if x.sign == 1 { -x.man } else { x.man }
  let offset = x.exp + prec
  if offset >= 0 {
    signed_man << offset
  } else {
    signed_man >> (-offset)
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
  assert_true(@mpf.to_str_opts(arg, dps=12).has_prefix("0.78539816339"))
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
  assert_true(@mpf.to_str_opts(e.real, dps=14).has_prefix("-1.131204383756"))
  assert_true(@mpf.to_str_opts(e.imag, dps=14).has_prefix("2.471726672004"))
  let l = mpc_log(
    from_parts(@mpf.from_int(3), @mpf.from_int(4)),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(l.real, dps=14).has_prefix("1.609437912434"))
  assert_true(@mpf.to_str_opts(l.imag, dps=14).has_prefix("0.927295218001"))
  let s = mpc_sin(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(s.real, dps=14).has_prefix("3.165778513216"))
  assert_true(@mpf.to_str_opts(s.imag, dps=14).has_prefix("1.959601041421"))
  let c = mpc_cos(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(c.real, dps=14).has_prefix("2.032723007019"))
  assert_true(@mpf.to_str_opts(c.imag, dps=14).has_prefix("-3.051897799151"))
  let t = mpc_tan(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(t.real, dps=14).has_prefix("0.033812826079"))
  assert_true(@mpf.to_str_opts(t.imag, dps=14).has_prefix("1.014793616146"))
  let sh = mpc_sinh(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(sh.real, dps=14).has_prefix("-0.489056259041"))
  assert_true(@mpf.to_str_opts(sh.imag, dps=14).has_prefix("1.403119250622"))
  let ch = mpc_cosh(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ch.real, dps=14).has_prefix("-0.642148124715"))
  assert_true(@mpf.to_str_opts(ch.imag, dps=14).has_prefix("1.068607421382"))
  let th = mpc_tanh(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(th.real, dps=14).has_prefix("1.166736257240"))
  assert_true(@mpf.to_str_opts(th.imag, dps=14).has_prefix("-0.243458201185"))
  let p1 = mpc_pow(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    from_parts(@mpf.fzero, @mpf.fone),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(p1.real, dps=14).has_prefix("0.769238901363"))
  assert_true(@mpf.to_str_opts(p1.imag, dps=14).has_prefix("0.638961276313"))
  let p2 = mpc_pow_mpf(z, @mpf.from_str("0.5"), 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(p2.real, dps=14).has_prefix("1.272019649514"))
  assert_true(@mpf.to_str_opts(p2.imag, dps=14).has_prefix("0.786151377757"))
  let sq = mpc_square(z, 80, @mpf.round_nearest)
  assert_parts(sq, @mpf.from_int(-3), @mpf.from_int(4))
}

///|
test "panic mpc_pow_int zero negative exponent" {
  ignore(mpc_pow_int(zero(), -1, 20, @mpf.round_nearest))
}

///|
test "panic mpc_div by zero" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(1))
  ignore(mpc_div(z, zero(), 20, @mpf.round_nearest))
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
  assert_true(@mpf.to_str_opts(l.real, dps=14).has_prefix("1.609437912434"))
  assert_true(@mpf.to_str_opts(l.imag, dps=14).has_prefix("0.927295218001"))
}

///|
test "mpc pi-family and expj subset" {
  let cp = mpc_cos_pi(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(cp.real, dps=10).has_prefix("0.0"))
  let sp = mpc_sin_pi(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(sp.real, dps=10).has_prefix("0.7071067"))
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
  assert_true(@mpf.to_str_opts(ej.real, dps=10).has_prefix("-1.0"))
  let ejp = mpc_expjpi(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ejp.real, dps=10).has_prefix("-1.0"))
}

///|
test "mpc inverse trig-hyperbolic and roots subset" {
  let a = mpc_atan(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(a.real, dps=14).has_prefix("0.785398163397"))
  let asn = mpc_asin(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(asn.real, dps=14).has_prefix("0.523598775598"))
  let acs = mpc_acos(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(acs.real, dps=14).has_prefix("1.047197551196"))
  let ash = mpc_asinh(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ash.real, dps=14).has_prefix("0.881373587019"))
  let ach = mpc_acosh(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ach.real, dps=14).has_prefix("1.316957896924"))
  let ath = mpc_atanh(
    from_parts(@mpf.from_str("0.5"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ath.real, dps=14).has_prefix("0.549306144334"))
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
  assert_true(@mpf.to_str_opts(agm.real, dps=14).has_prefix("0.560757145071"))
  let agm1 = mpc_agm1(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(agm1.real, dps=14).has_prefix("0.560757145071"))
  assert_eq(
    mpc_gamma(from_parts(@mpf.from_int(5), @mpf.fzero), 120, @mpf.round_nearest),
    from_parts(@mpf.from_int(24), @mpf.fzero),
  )
  let rg = mpc_rgamma(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(rg.real, dps=14).has_prefix("0.041666666666"))
  let lg = mpc_loggamma(
    from_parts(@mpf.from_int(5), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(lg.real, dps=14).has_prefix("3.178053830347"))
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
  assert_true(@mpf.to_str_opts(har.real, dps=14).has_prefix("2.283333333333"))
  let p0 = mpc_psi0(
    from_parts(@mpf.from_int(4), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(p0.real, dps=14).has_prefix("1.256117668431"))
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
  assert_true(@mpf.to_str_opts(ei.real, dps=14).has_prefix("0.454219904863"))
  let e1 = mpc_e1(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(e1.real, dps=14).has_prefix("0.219383934395"))
  let si = mpc_si(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(si.real, dps=14).has_prefix("0.946083070367"))
  let ci = mpc_ci(
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ci.real, dps=14).has_prefix("0.337403922900"))
  let j0 = mpc_besseljn(
    0,
    from_parts(@mpf.from_int(1), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(j0.real, dps=14).has_prefix("0.765197686557"))
  let ek = mpc_ellipk(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ek.real, dps=14).has_prefix("1.685750354812"))
  let ee = mpc_ellipe(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ee.real, dps=14).has_prefix("1.467462209339"))
}

///|
test "mpc zeta family subset" {
  let z2 = mpc_zeta(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(z2.real, dps=14).has_prefix("1.644934066848"))
  let a2 = mpc_altzeta(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(a2.real, dps=14).has_prefix("0.822467033424"))
  let s10 = mpc_zetasum(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    140,
    @mpf.round_nearest,
    start=1,
    terms=10,
  )
  assert_true(@mpf.to_str_opts(s10.real, dps=14).has_prefix("1.549767731166"))
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
  assert_true(@mpf.to_str_opts(ei.real, dps=10).has_prefix("0.5438975"))
  assert_true(@mpf.to_str_opts(ei.imag, dps=10).has_prefix("0.7867419"))
  let e1 = mpc_e1(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e1.real, dps=10).has_prefix("0.4594499"))
  assert_true(@mpf.to_str_opts(e1.imag, dps=10).has_prefix("-0.2675113"))
  let ci = mpc_ci(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ci.real, dps=10).has_prefix("-0.0515129"))
  assert_true(@mpf.to_str_opts(ci.imag, dps=10).has_prefix("0.4021216"))
  let si = mpc_si(z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(si.real, dps=10).has_prefix("0.4982025"))
  assert_true(@mpf.to_str_opts(si.imag, dps=10).has_prefix("0.2405181"))
  let j1 = mpc_besseljn(1, z, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(j1.real, dps=10).has_prefix("0.2479511"))
  assert_true(@mpf.to_str_opts(j1.imag, dps=10).has_prefix("0.1143621"))
  let m = from_parts(@mpf.from_str("0.25"), @mpf.from_str("0.1"))
  let ek = mpc_ellipk(m, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ek.real, dps=10).has_prefix("1.6817722"))
  assert_true(@mpf.to_str_opts(ek.imag, dps=10).has_prefix("0.0538075"))
  let ee = mpc_ellipe(m, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ee.real, dps=10).has_prefix("1.4685096"))
  assert_true(@mpf.to_str_opts(ee.imag, dps=10).has_prefix("-0.0436005"))
  let w = from_parts(@mpf.from_str("2.5"), @mpf.from_str("0.5"))
  let g = mpc_gamma(w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(g.real, dps=10).has_prefix("1.1723958"))
  assert_true(@mpf.to_str_opts(g.imag, dps=10).has_prefix("0.4365070"))
  let rg = mpc_rgamma(w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(rg.real, dps=10).has_prefix("0.7491105"))
  assert_true(@mpf.to_str_opts(rg.imag, dps=10).has_prefix("-0.2789092"))
  let lg = mpc_loggamma(w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(lg.real, dps=10).has_prefix("0.2239590"))
  assert_true(@mpf.to_str_opts(lg.imag, dps=10).has_prefix("0.3564195"))
  let h = mpc_harmonic(w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(h.real, dps=10).has_prefix("1.6937236"))
  assert_true(@mpf.to_str_opts(h.imag, dps=10).has_prefix("0.1637364"))
  let p0 = mpc_psi0(w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(p0.real, dps=10).has_prefix("0.7318926"))
  assert_true(@mpf.to_str_opts(p0.imag, dps=10).has_prefix("0.2406595"))
  let p1 = mpc_psi(1, w, 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(p1.real, dps=14).has_prefix("0.463802495540"))
  assert_true(@mpf.to_str_opts(p1.imag, dps=14).has_prefix("-0.111892198603"))
  let fac = mpc_factorial(w, 140, @mpf.round_nearest)
  assert_true(@mpf.is_finite(fac.real))
  assert_true(@mpf.is_finite(fac.imag))
}

///|
test "mpc_ci_si_taylor subset" {
  let re = @mpf.from_str("0.5")
  let im = @mpf.from_str("0.25")
  let ci_core = mpc_ci_si_taylor(re, im, 180, which=0)
  assert_true(@mpf.to_str_opts(ci_core.real, dps=14).has_prefix("-0.047153243510"))
  assert_true(@mpf.to_str_opts(ci_core.imag, dps=14).has_prefix("-0.061525939930"))
  let si = mpc_ci_si_taylor(re, im, 180, which=1)
  assert_true(@mpf.to_str_opts(si.real, dps=14).has_prefix("0.498202520036"))
  assert_true(@mpf.to_str_opts(si.imag, dps=14).has_prefix("0.240518169433"))
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
  assert_true(@mpf.to_str_opts(re_v, dps=14).has_prefix("0.886370150250"))
  assert_true(@mpf.to_str_opts(im_v, dps=14).has_prefix("0.082429078456"))
  let root = mpc_nthroot(from_parts(re, im), 5, 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(root.real, dps=14).has_prefix("0.886370150250"))
  assert_true(@mpf.to_str_opts(root.imag, dps=14).has_prefix("0.082429078456"))
}
