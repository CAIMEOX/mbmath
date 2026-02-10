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
  assert_true(@mpf.to_str_opts(ci_core, dps=16).has_prefix("-0.239811742000564"))
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
test "panic mpf_agm negative input" {
  ignore(mpf_agm(@mpf.from_int(-1), @mpf.from_int(2), 80, @mpf.round_nearest))
}

///|
test "panic mpf_ci non-positive" {
  ignore(mpf_ci(@mpf.fzero, 80, @mpf.round_nearest))
}

///|
test "panic mpf_ei zero" {
  ignore(mpf_ei(@mpf.fzero, 80, @mpf.round_nearest))
}

///|
test "panic mpf_ellipk invalid m" {
  ignore(mpf_ellipk(@mpf.fone, 80, @mpf.round_nearest))
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
