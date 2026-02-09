///|
test "mpf_factorial basic" {
  assert_eq(mpf_factorial(0, 80, @mpf.round_nearest), @mpf.fone)
  assert_eq(mpf_factorial(1, 80, @mpf.round_nearest), @mpf.fone)
  assert_eq(mpf_factorial(5, 80, @mpf.round_nearest), @mpf.from_int(120))
  assert_eq(mpf_factorial(10, 80, @mpf.round_nearest), @mpf.from_int(3628800))
}

///|
test "mpf_bernoulli small values" {
  assert_eq(mpf_bernoulli(0, 120, @mpf.round_nearest), @mpf.from_int(1))
  assert_eq(
    mpf_bernoulli(1, 120, @mpf.round_nearest),
    @mpf.from_man_exp(-1N, -1, 0, @mpf.round_down),
  )
  assert_true(
    @mpf.to_str_opts(mpf_bernoulli(2, 120, @mpf.round_nearest), dps=16).has_prefix(
      "0.166666666666666",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_bernoulli(4, 120, @mpf.round_nearest), dps=16).has_prefix(
      "-0.033333333333333",
    ),
  )
  assert_eq(mpf_bernoulli(3, 120, @mpf.round_nearest), @mpf.fzero)
}

///|
test "mpf_zeta_int subset" {
  let z2 = mpf_zeta_int(2, 120, @mpf.round_nearest)
  let z3 = mpf_zeta_int(3, 120, @mpf.round_nearest)
  assert_true(@mpf.to_str_opts(z2, dps=16).has_prefix("1.644934066848226"))
  assert_true(@mpf.to_str_opts(z3, dps=16).has_prefix("1.202056903159594"))
}

///|
test "mpf_gamma subset" {
  assert_eq(
    mpf_gamma(@mpf.from_int(6), 120, @mpf.round_nearest),
    @mpf.from_int(120),
  )
  let ghalf = mpf_gamma(
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.to_str_opts(ghalf, dps=16).has_prefix("1.772453850905516"))
}

///|
test "mpmath diff subset for gammazeta" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_true(
    @mpf.to_str_opts(
      mpf_gamma(
        @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
        140,
        @mpf.round_nearest,
      ),
      dps=14,
    ).has_prefix("1.772453850905"),
  )
  assert_true(
    @mpf.to_str_opts(mpf_zeta_int(2, 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.644934066848",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_zeta_int(3, 140, @mpf.round_nearest), dps=14).has_prefix(
      "1.202056903159",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_bernoulli(10, 140, @mpf.round_nearest), dps=14).has_prefix(
      "0.075757575757",
    ),
  )
}

///|
test "mpf rgamma/loggamma/gamma_int subset" {
  assert_true(
    @mpf.to_str_opts(
      mpf_rgamma(
        @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
        140,
        @mpf.round_nearest,
      ),
      dps=14,
    ).has_prefix("0.564189583547"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_loggamma(@mpf.from_str("3.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.200973602347"),
  )
  assert_eq(mpf_gamma_int(6, 120, @mpf.round_nearest), @mpf.from_int(120))
}

///|
test "mpf psi harmonic fibonacci zeta subset" {
  assert_true(
    @mpf.to_str_opts(
      mpf_psi0(@mpf.from_str("3.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.1031566404"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_harmonic(@mpf.from_int(10), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("2.928968253968"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_harmonic(@mpf.from_str("2.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.6803723053"),
  )
  assert_eq(
    mpf_fibonacci(@mpf.from_int(10), 120, @mpf.round_nearest),
    @mpf.from_int(55),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_fibonacci(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("0.568864481005"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_str("2.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.34148725"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_str("2.5"), 140, @mpf.round_nearest, alt=true),
      dps=14,
    ).has_prefix("0.86719988"),
  )
}

///|
test "mpf gamma/zeta negative real subset" {
  assert_true(
    @mpf.to_str_opts(
      mpf_gamma(@mpf.from_str("-0.5"), 160, @mpf.round_nearest),
      dps=15,
    ).has_prefix("-3.54490770181103"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_gamma(@mpf.from_str("-2.5"), 160, @mpf.round_nearest),
      dps=15,
    ).has_prefix("-0.94530872048294"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(0), 160, @mpf.round_nearest),
      dps=16,
    ).has_prefix("-0.5"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(-1), 160, @mpf.round_nearest),
      dps=16,
    ).has_prefix("-0.083333333333333"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(-3), 160, @mpf.round_nearest),
      dps=16,
    ).has_prefix("0.008333333333333"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_str("-0.5"), 160, @mpf.round_nearest),
      dps=12,
    ).has_prefix("-0.20788622"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(0), 160, @mpf.round_nearest, alt=true),
      dps=16,
    ).has_prefix("0.5"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(-1), 160, @mpf.round_nearest, alt=true),
      dps=16,
    ).has_prefix("0.25"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_int(-3), 160, @mpf.round_nearest, alt=true),
      dps=16,
    ).has_prefix("-0.125"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_zeta(@mpf.from_str("-0.5"), 160, @mpf.round_nearest, alt=true),
      dps=12,
    ).has_prefix("0.38010481"),
  )
}

///|
test "panic mpf_factorial negative" {
  ignore(mpf_factorial(-1, 80, @mpf.round_nearest))
}

///|
test "panic mpf_zeta_int pole" {
  ignore(mpf_zeta_int(1, 80, @mpf.round_nearest))
}

///|
test "panic mpf_gamma pole" {
  ignore(mpf_gamma(@mpf.from_int(0), 80, @mpf.round_nearest))
}

///|
test "panic unsupported branches in gammazeta subset" {
  ignore(mpf_psi0(@mpf.from_int(0), 80, @mpf.round_nearest))
}
