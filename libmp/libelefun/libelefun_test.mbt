///|
test "mpf_atan2 basic quadrants" {
  let q1 = mpf_atan2(@mpf.from_int(1), @mpf.from_int(1), 80, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(q1, dps=12).has_prefix("0.78539816339"))
  let q2 = mpf_atan2(
    @mpf.from_int(1),
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(q2, dps=12).has_prefix("2.35619449019"))
  let q3 = mpf_atan2(
    @mpf.from_int(-1),
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(q3, dps=12).has_prefix("-2.35619449019"))
}

///|
test "mpf_pi baseline" {
  let pi = mpf_pi(80, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(pi, dps=15).has_prefix("3.14159265358979"))
}

///|
test "mpf_atan baseline" {
  let a = mpf_atan(@mpf.from_int(1), 100, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(a, dps=16).has_prefix("0.7853981633974483"))
  let b = mpf_atan(@mpf.from_int(-1), 100, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(b, dps=16).has_prefix("-0.7853981633974483"))
}

///|
test "mpf_exp baseline" {
  assert_eq(mpf_exp(@mpf.fzero, 80, @mpf.round_nearest), @mpf.fone)
  let e = mpf_exp(@mpf.fone, 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e, dps=16).has_prefix("2.718281828459045"))
  let inv_e = mpf_exp(@mpf.from_int(-1), 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(inv_e, dps=16).has_prefix("0.3678794411714423"))
}

///|
test "mpf_ln baseline" {
  assert_eq(mpf_ln(@mpf.fone, 80, @mpf.round_nearest), @mpf.fzero)
  assert_eq(mpf_ln(@mpf.fzero, 80, @mpf.round_nearest), @mpf.fninf)
  let ln2 = mpf_ln(@mpf.from_int(2), 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ln2, dps=16).has_prefix("0.6931471805599453"))
  let e = mpf_exp(@mpf.fone, 120, @mpf.round_nearest)
  let back = mpf_ln(e, 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(back, dps=12).has_prefix("1.0"))
}

///|
test "mpf_log1p and constant helpers subset" {
  let l_small = mpf_log1p(@mpf.from_str("1e-10"), 180, @mpf.round_nearest)
  assert_true(
    @mpf.to_str_opts(l_small, dps=18).has_prefix("9.999999999500000"),
  )
  assert_eq(mpf_log1p(@mpf.from_int(-1), 120, @mpf.round_nearest), @mpf.fninf)
  let sp = mpf_sqrtpi(160, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(sp, dps=16).has_prefix("1.772453850905516"))
  let lsp = mpf_ln_sqrt2pi(160, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(lsp, dps=16).has_prefix("0.918938533204672"))
}

///|
test "panic mpf_ln non-positive" {
  ignore(mpf_ln(@mpf.from_int(-1), 80, @mpf.round_nearest))
}

///|
test "panic mpf_log1p below -1" {
  ignore(mpf_log1p(@mpf.from_str("-1.25"), 80, @mpf.round_nearest))
}

///|
test "mpmath diff subset for libelefun" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_true(
    @mpf.to_str_opts(
      mpf_atan(@mpf.from_str("0.1"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("0.099668652491"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_atan2(@mpf.from_int(-2), @mpf.from_int(3), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("-0.588002603547"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_pi(140, @mpf.round_nearest), dps=16).has_prefix(
      "3.141592653589793",
    ),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_exp(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.648721270700"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_ln(@mpf.from_int(3), 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.098612288668",
    ),
  )
}

///|
test "mpf trig and hyperbolic subset" {
  let x = @mpf.from_str("0.5")
  assert_true(
    @mpf.to_str_opts(mpf_sin(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.479425538604",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_cos(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.877582561890",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_tan(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.546302489843",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_sinh(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.521095305493",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_cosh(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.127625965206",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_tanh(x, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.462117157260",
    ),
  )
}

///|
test "mpf inverse subset" {
  let half = @mpf.from_str("0.5")
  assert_true(
    @mpf.to_str_opts(mpf_asin(half, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.523598775598",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_acos(half, 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.047197551196",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_asinh(@mpf.fone, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.881373587019",
    ),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_acosh(@mpf.from_int(2), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.316957896924"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_atanh(half, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.549306144334",
    ),
  )
}

///|
test "mpf pow and constants subset" {
  assert_true(
    @mpf.to_str_opts(
      mpf_pow(@mpf.from_int(2), @mpf.from_str("0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.414213562373"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_nthroot(@mpf.from_int(2), 5, 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.148698354997"),
  )
  assert_eq(
    mpf_nthroot(@mpf.from_int(-8), 3, 120, @mpf.round_nearest),
    @mpf.from_int(-2),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_cbrt(@mpf.from_int(2), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.259921049894"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_e(140, @mpf.round_nearest), dps=14).has_prefix(
      "2.718281828459",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_ln2(140, @mpf.round_nearest), dps=14).has_prefix(
      "0.693147180559",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_ln10(140, @mpf.round_nearest), dps=14).has_prefix(
      "2.302585092994",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_phi(140, @mpf.round_nearest), dps=14).has_prefix(
      "1.618033988749",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_degree(140, @mpf.round_nearest), dps=14).has_prefix(
      "0.017453292519",
    ),
  )
}

///|
test "panic inverse domain" {
  ignore(mpf_asin(@mpf.from_int(2), 80, @mpf.round_nearest))
}
