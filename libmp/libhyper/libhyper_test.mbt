///|
test "mpf_agm basic properties" {
  assert_eq(
    mpf_agm(@mpf.from_int(1), @mpf.from_int(1), 80, @mpf.round_nearest),
    @mpf.from_int(1),
  )
  let g1 = mpf_agm(@mpf.from_int(1), @mpf.from_int(4), 80, @mpf.round_nearest)
  let g2 = mpf_agm(@mpf.from_int(4), @mpf.from_int(1), 80, @mpf.round_nearest)
  assert_true(@mpf.mpf_eq(g1, g2))
  assert_true(@mpf.mpf_gt(g1, @mpf.from_int(1)))
  assert_true(@mpf.mpf_lt(g1, @mpf.from_int(4)))
}

///|
test "mpf_si_ci_ei subset" {
  let si1 = mpf_si(@mpf.from_int(1), 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(si1, dps=16).has_prefix("0.946083070367183"))
  let ci1 = mpf_ci(@mpf.from_int(1), 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ci1, dps=16).has_prefix("0.3374039229009681"))
  let ei1 = mpf_ei(@mpf.from_int(1), 140, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ei1, dps=16).has_prefix("1.895117816355937"))
}

///|
test "mpf_ci_si_taylor subset" {
  let ci_core = mpf_ci_si_taylor(@mpf.from_int(1), 180, which=0)
  assert_true(
    @mpf.to_str_opts(ci_core, dps=16).has_prefix("-0.239811742000564"),
  )
  let si_core = mpf_ci_si_taylor(@mpf.from_int(1), 180, which=1)
  assert_true(@mpf.to_str_opts(si_core, dps=16).has_prefix("0.946083070367183"))
}

///|
test "mpf_ellipk subset" {
  let k0 = mpf_ellipk(@mpf.fzero, 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(k0, dps=16).has_prefix("1.570796326794897"))
  let k05 = mpf_ellipk(@mpf.from_str("0.5"), 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(k05, dps=16).has_prefix("1.854074677301372"))
}

///|
test "mpf_ellipe subset" {
  let e0 = mpf_ellipe(@mpf.fzero, 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e0, dps=16).has_prefix("1.570796326794897"))
  let e025 = mpf_ellipe(@mpf.from_str("0.25"), 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e025, dps=14).has_prefix("1.467462209339"))
  let e05 = mpf_ellipe(@mpf.from_str("0.5"), 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(e05, dps=14).has_prefix("1.350643881047"))
}

///|
test "mpf special semantics parity (ci/ei/e1/ellip*)" {
  let ci0 = mpf_ci(@mpf.fzero, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(ci0) && ci0.sign == 1)
  let ci_neg : Result[@mpf.RawMpf, LibHyperError] = try? mpf_ci(
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  guard ci_neg is Err(LibHyperError::ComplexResult(_)) else {
    fail("expected ComplexResult for mpf_ci(-1)")
  }
  let ei0 = mpf_ei(@mpf.fzero, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(ei0) && ei0.sign == 1)
  let e1_neg : Result[@mpf.RawMpf, LibHyperError] = try? mpf_e1(
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  guard e1_neg is Err(LibHyperError::ComplexResult(msg)) &&
    msg.contains("E1(x) for x < 0") else {
    fail("expected ComplexResult for mpf_e1(-1)")
  }
  let k1 = mpf_ellipk(@mpf.fone, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(k1) && k1.sign == 0)
  let e1 = mpf_ellipe(@mpf.fone, 80, @mpf.round_nearest)
  assert_true(@mpf.mpf_eq(e1, @mpf.fone))
}

///|
test "mpf_expint negative-real principal subset from mpmath" {
  let en1 = mpf_expint(1, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(en1, dps=18).has_prefix("-1.89511781635593"))
  let en2 = mpf_expint(2, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(en2, dps=18).has_prefix("0.82316401210310848"))
  let en3 = mpf_expint(3, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(en3, dps=18).has_prefix("1.77072292028107"))
  let em1 = mpf_expint(1, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(em1, dps=16).has_prefix("-13.92535399515"))
  let em2 = mpf_expint(2, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(em2, dps=16).has_prefix("-15.62328702434"))
  let em3 = mpf_expint(3, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(em3, dps=16).has_prefix("-10.78302631325"))
}

///|
test "mpf_expint special and gamma-mode subset from mpmath" {
  assert_true(@mpf.is_inf(mpf_expint(1, @mpf.fzero, 80, @mpf.round_nearest)))
  assert_true(
    @mpf.mpf_eq(mpf_expint(2, @mpf.fzero, 80, @mpf.round_nearest), @mpf.fone),
  )
  assert_true(
    @mpf.mpf_eq(
      mpf_expint(3, @mpf.fzero, 80, @mpf.round_nearest),
      @mpf.mpf_shift(@mpf.fone, -1),
    ),
  )
  let g1 = mpf_expint(1, @mpf.from_int(-1), 180, @mpf.round_nearest, gamma=true)
  assert_true(@mpf.to_str_opts(g1, dps=18).has_prefix("2.718281828459045"))
  assert_true(
    @mpf.mpf_eq(
      mpf_expint(2, @mpf.from_int(-1), 80, @mpf.round_nearest, gamma=true),
      @mpf.fzero,
    ),
  )
  let g3 = mpf_expint(3, @mpf.from_int(-1), 180, @mpf.round_nearest, gamma=true)
  assert_true(@mpf.to_str_opts(g3, dps=18).has_prefix("2.71828182845904"))
  assert_true(
    @mpf.mpf_eq(mpf_expint(3, @mpf.finf, 80, @mpf.round_nearest), @mpf.fzero),
  )
  assert_true(@mpf.is_nan(mpf_expint(3, @mpf.fninf, 80, @mpf.round_nearest)))
  assert_true(
    @mpf.mpf_eq(
      mpf_expint(3, @mpf.finf, 80, @mpf.round_nearest, gamma=true),
      @mpf.fzero,
    ),
  )
  assert_true(
    @mpf.is_nan(mpf_expint(3, @mpf.fninf, 80, @mpf.round_nearest, gamma=true)),
  )
}

///|
test "mpf si/ci extended numeric subset from mpmath test_functions2" {
  let tiny = @mpf.from_str("1e-6")
  let si_tiny = mpf_si(tiny, 220, @mpf.round_nearest)
  let si_tiny_scaled = @mpf.mpf_mul(
    si_tiny,
    @mpf.from_int(1000000),
    220,
    @mpf.round_nearest,
  )
  assert_true(
    @mpf.to_str_opts(si_tiny_scaled, dps=18).has_prefix("0.99999999999"),
  )
  let ci_tiny = mpf_ci(tiny, 220, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ci_tiny, dps=14).has_prefix("-13.23829489306"))
  let huge = @mpf.from_str("1e10")
  let si_huge = mpf_si(huge, 220, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(si_huge, dps=16).has_prefix("1.5707963"))
  let ci_huge = mpf_ci(huge, 220, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(ci_huge, 220, @mpf.round_nearest),
      @mpf.from_str("1e-8"),
    ),
  )
  let ci50 = mpf_ci(@mpf.from_int(50), 220, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(ci50, dps=16).has_prefix("-0.005628386324116"))
  assert_true(
    @mpf.mpf_eq(mpf_ci(@mpf.finf, 120, @mpf.round_nearest), @mpf.fzero),
  )
  assert_true(
    @mpf.to_str_opts(mpf_si(@mpf.finf, 120, @mpf.round_nearest), dps=14).has_prefix(
      "1.570796326794",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_si(@mpf.fninf, 120, @mpf.round_nearest), dps=14).has_prefix(
      "-1.570796326794",
    ),
  )
}

///|
test "panic mpf_agm negative input" {
  ignore(mpf_agm(@mpf.from_int(-1), @mpf.from_int(2), 80, @mpf.round_nearest))
}

///|
test "panic mpf_ci negative input" {
  ignore(mpf_ci(@mpf.from_int(-1), 80, @mpf.round_nearest))
}

///|
test "panic mpf_ellipk invalid m" {
  ignore(mpf_ellipk(@mpf.from_int(2), 80, @mpf.round_nearest))
}

///|
test "mpmath diff subset for libhyper" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_true(
    @mpf.to_str_opts(
      mpf_ei(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("0.454219904863"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_si(@mpf.from_int(2), 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.605412976802",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_ci(@mpf.from_int(2), 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.422980828774",
    ),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_ellipk(@mpf.from_str("0.25"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.685750354812"),
  )
}
