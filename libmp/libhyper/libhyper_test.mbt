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
  let expected = @mpf.RawMpf::parse(expected_text, prec=cmp_prec, rnd=Nearest)
  let tol = @mpf.RawMpf::parse(
    "1e" + (exp10 - frac_digits).to_string(),
    prec=cmp_prec,
    rnd=Nearest,
  )
  let err = got.sub(expected, cmp_prec, Nearest).abs(cmp_prec, Nearest)
  if !(err <= tol) {
    fail(
      "assert_mpf_close_to_text failed, expected=" +
      expected_text +
      ", got=" +
      got.format(dps=dps + 4) +
      ", err=" +
      err.format(dps=8) +
      ", tol=" +
      tol.format(dps=8),
    )
  }
}

///|
test "agm basic properties" {
  @debug.assert_eq(
    agm(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(1), 80, Nearest),
    @mpf.RawMpf::from_int(1),
  )
  let g1 = agm(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(4), 80, Nearest)
  let g2 = agm(@mpf.RawMpf::from_int(4), @mpf.RawMpf::from_int(1), 80, Nearest)
  assert_true(g1 == g2)
  assert_true(g1 > @mpf.RawMpf::from_int(1))
  assert_true(g1 < @mpf.RawMpf::from_int(4))
}

///|
test "mpf_si_ci_ei subset" {
  let si1 = si(@mpf.RawMpf::from_int(1), 140, Nearest)
  assert_mpf_close_to_text(si1, "0.946083070367183", 16)
  let ci1 = ci(@mpf.RawMpf::from_int(1), 140, Nearest)
  assert_mpf_close_to_text(ci1, "0.3374039229009681", 16)
  let ei1 = ei(@mpf.RawMpf::from_int(1), 140, Nearest)
  assert_mpf_close_to_text(ei1, "1.895117816355937", 16)
}

///|
test "ci_si_taylor subset" {
  let ci_core = ci_si_taylor(@mpf.RawMpf::from_int(1), 180, which=0)
  assert_mpf_close_to_text(ci_core, "-0.239811742000564", 16)
  let si_core = ci_si_taylor(@mpf.RawMpf::from_int(1), 180, which=1)
  assert_mpf_close_to_text(si_core, "0.946083070367183", 16)
}

///|
test "ellipk subset" {
  let k0 = ellipk(@mpf.RawMpf::zero(), 120, Nearest)
  assert_mpf_close_to_text(k0, "1.570796326794897", 16)
  let k05 = ellipk(@mpf.RawMpf::parse("0.5"), 120, Nearest)
  assert_mpf_close_to_text(k05, "1.854074677301372", 16)
}

///|
test "ellipe subset" {
  let e0 = ellipe(@mpf.RawMpf::zero(), 120, Nearest)
  assert_mpf_close_to_text(e0, "1.570796326794897", 16)
  let e025 = ellipe(@mpf.RawMpf::parse("0.25"), 120, Nearest)
  assert_mpf_close_to_text(e025, "1.467462209339", 14)
  let e05 = ellipe(@mpf.RawMpf::parse("0.5"), 120, Nearest)
  assert_mpf_close_to_text(e05, "1.350643881047", 14)
}

///|
test "mpf special semantics parity (ci/ei/e1/ellip*)" {
  let ci0 = ci(@mpf.RawMpf::zero(), 80, Nearest)
  assert_true(ci0.is_infinite() && ci0.sign == 1)
  try ci(@mpf.RawMpf::from_int(-1), 80, Nearest) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected error type for ci(-1)")
  } noraise {
    _ => fail("expected ComplexResult for ci(-1)")
  }
  let ei0 = ei(@mpf.RawMpf::zero(), 80, Nearest)
  assert_true(ei0.is_infinite() && ei0.sign == 1)
  try e1(@mpf.RawMpf::from_int(-1), 80, Nearest) catch {
    ComplexResult(msg) => assert_true(msg.contains("E1(x) for x < 0"))
    _ => fail("unexpected error type for e1(-1)")
  } noraise {
    _ => fail("expected ComplexResult for e1(-1)")
  }
  let k1 = ellipk(@mpf.RawMpf::one(), 80, Nearest)
  assert_true(k1.is_infinite() && k1.sign == 0)
  let e1 = ellipe(@mpf.RawMpf::one(), 80, Nearest)
  assert_true(e1 == @mpf.RawMpf::one())
}

///|
test "expint negative-real principal subset from mpmath" {
  let en1 = exponential_integral(1, @mpf.RawMpf::from_int(-1), 180, Nearest)
  assert_mpf_close_to_text(en1, "-1.89511781635593", 18)
  let en2 = exponential_integral(2, @mpf.RawMpf::from_int(-1), 180, Nearest)
  assert_mpf_close_to_text(en2, "0.82316401210310848", 18)
  let en3 = exponential_integral(3, @mpf.RawMpf::from_int(-1), 180, Nearest)
  assert_mpf_close_to_text(en3, "1.77072292028107", 18)
  let em1 = exponential_integral(1, @mpf.RawMpf::parse("-3.5"), 180, Nearest)
  assert_mpf_close_to_text(em1, "-13.92535399515", 16)
  let em2 = exponential_integral(2, @mpf.RawMpf::parse("-3.5"), 180, Nearest)
  assert_mpf_close_to_text(em2, "-15.62328702434", 16)
  let em3 = exponential_integral(3, @mpf.RawMpf::parse("-3.5"), 180, Nearest)
  assert_mpf_close_to_text(em3, "-10.78302631325", 16)
}

///|
test "expint special and gamma-mode subset from mpmath" {
  assert_true(
    exponential_integral(1, @mpf.RawMpf::zero(), 80, Nearest).is_infinite(),
  )
  assert_true(
    exponential_integral(2, @mpf.RawMpf::zero(), 80, Nearest) ==
    @mpf.RawMpf::one(),
  )
  assert_true(
    exponential_integral(3, @mpf.RawMpf::zero(), 80, Nearest) ==
    @mpf.RawMpf::one().scale_pow2(-1),
  )
  let g1 = exponential_integral(
    1,
    @mpf.RawMpf::from_int(-1),
    180,
    Nearest,
    gamma=true,
  )
  assert_mpf_close_to_text(g1, "2.718281828459045", 18)
  assert_true(
    exponential_integral(2, @mpf.RawMpf::from_int(-1), 80, Nearest, gamma=true) ==
    @mpf.RawMpf::zero(),
  )
  let g3 = exponential_integral(
    3,
    @mpf.RawMpf::from_int(-1),
    180,
    Nearest,
    gamma=true,
  )
  assert_mpf_close_to_text(g3, "2.71828182845904", 18)
  assert_true(
    exponential_integral(3, @mpf.RawMpf::infinity(), 80, Nearest) ==
    @mpf.RawMpf::zero(),
  )
  assert_true(
    exponential_integral(3, @mpf.RawMpf::negative_infinity(), 80, Nearest).is_nan(),
  )
  assert_true(
    exponential_integral(3, @mpf.RawMpf::infinity(), 80, Nearest, gamma=true) ==
    @mpf.RawMpf::zero(),
  )
  assert_true(
    exponential_integral(
      3,
      @mpf.RawMpf::negative_infinity(),
      80,
      Nearest,
      gamma=true,
    ).is_nan(),
  )
}

///|
test "mpf si/ci extended numeric subset from mpmath test_functions2" {
  let tiny = @mpf.RawMpf::parse("1e-6")
  let si_tiny = si(tiny, 220, Nearest)
  let si_tiny_scaled = si_tiny.mul(@mpf.RawMpf::from_int(1000000), 220, Nearest)
  assert_mpf_close_to_text(si_tiny_scaled, "0.99999999999", 18)
  let ci_tiny = ci(tiny, 220, Nearest)
  assert_mpf_close_to_text(ci_tiny, "-13.23829489306", 14)
  let huge = @mpf.RawMpf::parse("1e10")
  let si_huge = si(huge, 220, Nearest)
  assert_mpf_close_to_text(si_huge, "1.5707963", 16)
  let ci_huge = ci(huge, 220, Nearest)
  assert_true(ci_huge.abs(220, Nearest) < @mpf.RawMpf::parse("1e-8"))
  let ci50 = ci(@mpf.RawMpf::from_int(50), 220, Nearest)
  assert_mpf_close_to_text(ci50, "-0.005628386324116", 16)
  assert_true(ci(@mpf.RawMpf::infinity(), 120, Nearest) == @mpf.RawMpf::zero())
  assert_mpf_close_to_text(
    si(@mpf.RawMpf::infinity(), 120, Nearest),
    "1.570796326794",
    14,
  )
  assert_mpf_close_to_text(
    si(@mpf.RawMpf::negative_infinity(), 120, Nearest),
    "-1.570796326794",
    14,
  )
}

///|
test "panic agm negative input" {
  ignore(agm(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::from_int(2), 80, Nearest))
}

///|
test "panic ci negative input" {
  ignore(ci(@mpf.RawMpf::from_int(-1), 80, Nearest))
}

///|
test "panic ellipk invalid m" {
  ignore(ellipk(@mpf.RawMpf::from_int(2), 80, Nearest))
}

///|
test "mpmath diff subset for libhyper" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_mpf_close_to_text(
    ei(@mpf.RawMpf::parse("0.5"), 140, Nearest),
    "0.454219904863",
    14,
  )
  assert_mpf_close_to_text(
    si(@mpf.RawMpf::from_int(2), 140, Nearest),
    "1.605412976802",
    14,
  )
  assert_mpf_close_to_text(
    ci(@mpf.RawMpf::from_int(2), 140, Nearest),
    "0.422980828774",
    14,
  )
  assert_mpf_close_to_text(
    ellipk(@mpf.RawMpf::parse("0.25"), 140, Nearest),
    "1.685750354812",
    14,
  )
}
