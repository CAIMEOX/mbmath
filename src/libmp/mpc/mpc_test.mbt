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
