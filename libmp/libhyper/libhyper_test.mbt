///|
fn assert_mpf_close_to_text(
  got : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let mut frac_digits = 0
  let mut seen_dot = false
  let mut in_exp = false
  let mut exp_sign = 1
  let mut exp_value = 0
  let mut exp_has_digits = false
  for c in expected_text {
    if in_exp {
      if !exp_has_digits && c == '+' {
        exp_sign = 1
      } else if !exp_has_digits && c == '-' {
        exp_sign = -1
      } else if c >= '0' && c <= '9' {
        exp_value = exp_value * 10 + (c.to_int() - '0'.to_int())
        exp_has_digits = true
      }
    } else if c == 'e' || c == 'E' {
      in_exp = true
    } else if c == '.' {
      seen_dot = true
    } else if seen_dot && c >= '0' && c <= '9' {
      frac_digits += 1
    }
  }
  let exp10 = if exp_has_digits { exp_sign * exp_value } else { 0 }
  let cmp_digits = if dps > frac_digits + 2 { dps } else { frac_digits + 2 }
  let cmp_prec = cmp_digits * 4 + 80
  let expected = @mpf.from_str(
    expected_text,
    prec=cmp_prec,
    rnd=@mpf.round_nearest,
  )
  let tol = @mpf.from_str(
    "1e" + (exp10 - frac_digits).to_string(),
    prec=cmp_prec,
    rnd=@mpf.round_nearest,
  )
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(got, expected, cmp_prec, @mpf.round_nearest),
    cmp_prec,
    @mpf.round_nearest,
  )
  if !@mpf.mpf_le(err, tol) {
    fail(
      "assert_mpf_close_to_text failed, expected=" +
      expected_text +
      ", got=" +
      @mpf.to_str_opts(got, dps=dps + 4) +
      ", err=" +
      @mpf.to_str_opts(err, dps=8) +
      ", tol=" +
      @mpf.to_str_opts(tol, dps=8),
    )
  }
}

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
  assert_mpf_close_to_text(si1, "0.946083070367183", 16)
  let ci1 = mpf_ci(@mpf.from_int(1), 140, @mpf.round_nearest)
  assert_mpf_close_to_text(ci1, "0.3374039229009681", 16)
  let ei1 = mpf_ei(@mpf.from_int(1), 140, @mpf.round_nearest)
  assert_mpf_close_to_text(ei1, "1.895117816355937", 16)
}

///|
test "mpf_ci_si_taylor subset" {
  let ci_core = mpf_ci_si_taylor(@mpf.from_int(1), 180, which=0)
  assert_mpf_close_to_text(ci_core, "-0.239811742000564", 16)
  let si_core = mpf_ci_si_taylor(@mpf.from_int(1), 180, which=1)
  assert_mpf_close_to_text(si_core, "0.946083070367183", 16)
}

///|
test "mpf_ellipk subset" {
  let k0 = mpf_ellipk(@mpf.fzero, 120, @mpf.round_nearest)
  assert_mpf_close_to_text(k0, "1.570796326794897", 16)
  let k05 = mpf_ellipk(@mpf.from_str("0.5"), 120, @mpf.round_nearest)
  assert_mpf_close_to_text(k05, "1.854074677301372", 16)
}

///|
test "mpf_ellipe subset" {
  let e0 = mpf_ellipe(@mpf.fzero, 120, @mpf.round_nearest)
  assert_mpf_close_to_text(e0, "1.570796326794897", 16)
  let e025 = mpf_ellipe(@mpf.from_str("0.25"), 120, @mpf.round_nearest)
  assert_mpf_close_to_text(e025, "1.467462209339", 14)
  let e05 = mpf_ellipe(@mpf.from_str("0.5"), 120, @mpf.round_nearest)
  assert_mpf_close_to_text(e05, "1.350643881047", 14)
}

///|
test "mpf special semantics parity (ci/ei/e1/ellip*)" {
  let ci0 = mpf_ci(@mpf.fzero, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(ci0) && ci0.sign == 1)
  try mpf_ci(@mpf.from_int(-1), 80, @mpf.round_nearest) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected error type for mpf_ci(-1)")
  } noraise {
    _ => fail("expected ComplexResult for mpf_ci(-1)")
  }
  let ei0 = mpf_ei(@mpf.fzero, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(ei0) && ei0.sign == 1)
  try mpf_e1(@mpf.from_int(-1), 80, @mpf.round_nearest) catch {
    ComplexResult(msg) => assert_true(msg.contains("E1(x) for x < 0"))
    _ => fail("unexpected error type for mpf_e1(-1)")
  } noraise {
    _ => fail("expected ComplexResult for mpf_e1(-1)")
  }
  let k1 = mpf_ellipk(@mpf.fone, 80, @mpf.round_nearest)
  assert_true(@mpf.is_inf(k1) && k1.sign == 0)
  let e1 = mpf_ellipe(@mpf.fone, 80, @mpf.round_nearest)
  assert_true(@mpf.mpf_eq(e1, @mpf.fone))
}

///|
test "mpf_expint negative-real principal subset from mpmath" {
  let en1 = mpf_expint(1, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(en1, "-1.89511781635593", 18)
  let en2 = mpf_expint(2, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(en2, "0.82316401210310848", 18)
  let en3 = mpf_expint(3, @mpf.from_int(-1), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(en3, "1.77072292028107", 18)
  let em1 = mpf_expint(1, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(em1, "-13.92535399515", 16)
  let em2 = mpf_expint(2, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(em2, "-15.62328702434", 16)
  let em3 = mpf_expint(3, @mpf.from_str("-3.5"), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(em3, "-10.78302631325", 16)
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
  assert_mpf_close_to_text(g1, "2.718281828459045", 18)
  assert_true(
    @mpf.mpf_eq(
      mpf_expint(2, @mpf.from_int(-1), 80, @mpf.round_nearest, gamma=true),
      @mpf.fzero,
    ),
  )
  let g3 = mpf_expint(3, @mpf.from_int(-1), 180, @mpf.round_nearest, gamma=true)
  assert_mpf_close_to_text(g3, "2.71828182845904", 18)
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
  assert_mpf_close_to_text(si_tiny_scaled, "0.99999999999", 18)
  let ci_tiny = mpf_ci(tiny, 220, @mpf.round_nearest)
  assert_mpf_close_to_text(ci_tiny, "-13.23829489306", 14)
  let huge = @mpf.from_str("1e10")
  let si_huge = mpf_si(huge, 220, @mpf.round_nearest)
  assert_mpf_close_to_text(si_huge, "1.5707963", 16)
  let ci_huge = mpf_ci(huge, 220, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(ci_huge, 220, @mpf.round_nearest),
      @mpf.from_str("1e-8"),
    ),
  )
  let ci50 = mpf_ci(@mpf.from_int(50), 220, @mpf.round_nearest)
  assert_mpf_close_to_text(ci50, "-0.005628386324116", 16)
  assert_true(
    @mpf.mpf_eq(mpf_ci(@mpf.finf, 120, @mpf.round_nearest), @mpf.fzero),
  )
  assert_mpf_close_to_text(
    mpf_si(@mpf.finf, 120, @mpf.round_nearest),
    "1.570796326794",
    14,
  )
  assert_mpf_close_to_text(
    mpf_si(@mpf.fninf, 120, @mpf.round_nearest),
    "-1.570796326794",
    14,
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
  assert_mpf_close_to_text(
    mpf_ei(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
    "0.454219904863",
    14,
  )
  assert_mpf_close_to_text(
    mpf_si(@mpf.from_int(2), 140, @mpf.round_nearest),
    "1.605412976802",
    14,
  )
  assert_mpf_close_to_text(
    mpf_ci(@mpf.from_int(2), 140, @mpf.round_nearest),
    "0.422980828774",
    14,
  )
  assert_mpf_close_to_text(
    mpf_ellipk(@mpf.from_str("0.25"), 140, @mpf.round_nearest),
    "1.685750354812",
    14,
  )
}
