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
test "mpf_bernoulli_huge subset" {
  let b100 = mpf_bernoulli_huge(100, 220, @mpf.round_nearest)
  assert_true(
    @mpf.to_str_opts(b100, dps=24).has_prefix("-2.83822495706937069592642e+78"),
  )
  let b100_auto = mpf_bernoulli(100, 220, @mpf.round_nearest)
  assert_true(
    @mpf.to_str_opts(b100_auto, dps=24).has_prefix(
      "-2.83822495706937069592642e+78",
    ),
  )
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
  assert_true(
    @mpf.to_str_opts(
      mpf_psi0(@mpf.from_str("-0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("0.0364899738"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_harmonic(@mpf.from_str("-0.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("-1.3862943612"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_harmonic(@mpf.from_str("-2.5"), 140, @mpf.round_nearest),
      dps=14,
    ).has_prefix("1.2803723053"),
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
  assert_true(
    @mpf.to_str_opts(
      mpf_psi(1, @mpf.from_str("-0.5"), 180, @mpf.round_nearest),
      dps=14,
    ).has_prefix("8.934802200544"),
  )
  assert_true(
    @mpf.to_str_opts(
      mpf_psi(2, @mpf.from_str("-0.5"), 180, @mpf.round_nearest),
      dps=14,
    ).has_prefix("-0.828796644234"),
  )
  assert_eq(mpf_psi(1, @mpf.finf, 120, @mpf.round_nearest), @mpf.fzero)
}

///|
test "mpf psi0 harmonic infinity semantics and large-negative stability" {
  assert_true(@mpf.is_nan(mpf_psi0(@mpf.fninf, 140, @mpf.round_nearest)))
  assert_eq(mpf_psi0(@mpf.finf, 140, @mpf.round_nearest), @mpf.finf)
  assert_true(@mpf.is_nan(mpf_harmonic(@mpf.fninf, 140, @mpf.round_nearest)))
  assert_eq(mpf_harmonic(@mpf.finf, 140, @mpf.round_nearest), @mpf.finf)
  let psi1_large_neg = mpf_psi(
    1,
    @mpf.from_str("-1e80"),
    180,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(psi1_large_neg))
  let psi2_large_neg = mpf_psi(
    2,
    @mpf.from_str("-1e80"),
    180,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_finite(psi2_large_neg))
}

///|
test "mpf zeta higher precision subset" {
  assert_true(
    @mpf.to_str_opts(mpf_zeta_int(3, 260, @mpf.round_nearest), dps=30).has_prefix(
      "1.2020569031595942853997381615",
    ),
  )
  assert_true(
    @mpf.to_str_opts(mpf_zeta_int(5, 260, @mpf.round_nearest), dps=30).has_prefix(
      "1.0369277551433699263313654864",
    ),
  )
  let s_near_1 = @mpf.from_str("1.0001", prec=360, rnd=@mpf.round_nearest)
  let z_near_1 = @mpf.to_str_opts(
    mpf_zeta(s_near_1, 260, @mpf.round_nearest),
    dps=25,
  )
  assert_true(z_near_1.has_prefix("10000.5772229464376290700"))
  let s_near_1_minus = @mpf.from_str("0.999", prec=360, rnd=@mpf.round_nearest)
  let eta_near_1 = @mpf.to_str_opts(
    mpf_altzeta(s_near_1_minus, 260, @mpf.round_nearest),
    dps=24,
  )
  assert_true(eta_near_1.has_prefix("0.69298727896833835736749"))
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
