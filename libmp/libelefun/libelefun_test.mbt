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
  assert_true(@mpf.mpf_le(err, tol))
}

///|
test "mpf_atan2 basic quadrants" {
  let q1 = mpf_atan2(@mpf.from_int(1), @mpf.from_int(1), 80, @mpf.round_nearest)
  assert_mpf_close_to_text(q1, "0.78539816339", 12)
  let q2 = mpf_atan2(
    @mpf.from_int(1),
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  assert_mpf_close_to_text(q2, "2.35619449019", 12)
  let q3 = mpf_atan2(
    @mpf.from_int(-1),
    @mpf.from_int(-1),
    80,
    @mpf.round_nearest,
  )
  assert_mpf_close_to_text(q3, "-2.35619449019", 12)
}

///|
test "mpf_pi baseline" {
  let pi = mpf_pi(80, @mpf.round_nearest)
  assert_mpf_close_to_text(pi, "3.14159265358979", 15)
}

///|
test "mpf_atan baseline" {
  let a = mpf_atan(@mpf.from_int(1), 100, @mpf.round_nearest)
  assert_mpf_close_to_text(a, "0.7853981633974483", 16)
  let b = mpf_atan(@mpf.from_int(-1), 100, @mpf.round_nearest)
  assert_mpf_close_to_text(b, "-0.7853981633974483", 16)
}

///|
test "mpf_exp baseline" {
  assert_eq(mpf_exp(@mpf.fzero, 80, @mpf.round_nearest), @mpf.fone)
  let e = mpf_exp(@mpf.fone, 120, @mpf.round_nearest)
  assert_mpf_close_to_text(e, "2.718281828459045", 16)
  let inv_e = mpf_exp(@mpf.from_int(-1), 120, @mpf.round_nearest)
  assert_mpf_close_to_text(inv_e, "0.3678794411714423", 16)
}

///|
test "mpf_ln baseline" {
  assert_eq(mpf_ln(@mpf.fone, 80, @mpf.round_nearest), @mpf.fzero)
  assert_eq(mpf_ln(@mpf.fzero, 80, @mpf.round_nearest), @mpf.fninf)
  let ln2 = mpf_ln(@mpf.from_int(2), 120, @mpf.round_nearest)
  assert_mpf_close_to_text(ln2, "0.6931471805599453", 16)
  let e = mpf_exp(@mpf.fone, 120, @mpf.round_nearest)
  let back = mpf_ln(e, 120, @mpf.round_nearest)
  assert_mpf_close_to_text(back, "1.0", 12)
}

///|
test "mpf_log1p and constant helpers subset" {
  let l_small = mpf_log1p(@mpf.from_str("1e-10"), 180, @mpf.round_nearest)
  assert_mpf_close_to_text(l_small, "9.999999999500000e-11", 18)
  assert_eq(mpf_log1p(@mpf.from_int(-1), 120, @mpf.round_nearest), @mpf.fninf)
  let sp = mpf_sqrtpi(160, @mpf.round_nearest)
  assert_mpf_close_to_text(sp, "1.772453850905516", 16)
  let lsp = mpf_ln_sqrt2pi(160, @mpf.round_nearest)
  assert_mpf_close_to_text(lsp, "0.918938533204672", 16)
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
  assert_mpf_close_to_text(
    mpf_atan(@mpf.from_str("0.1"), 140, @mpf.round_nearest),
    "0.099668652491",
    14,
  )
  assert_mpf_close_to_text(
    mpf_atan2(@mpf.from_int(-2), @mpf.from_int(3), 140, @mpf.round_nearest),
    "-0.588002603547",
    14,
  )
  assert_mpf_close_to_text(
    mpf_pi(140, @mpf.round_nearest),
    "3.141592653589793",
    16,
  )
  assert_mpf_close_to_text(
    mpf_exp(@mpf.from_str("0.5"), 140, @mpf.round_nearest),
    "1.648721270700",
    14,
  )
  assert_mpf_close_to_text(
    mpf_ln(@mpf.from_int(3), 140, @mpf.round_nearest),
    "1.098612288668",
    14,
  )
}

///|
test "mpf trig and hyperbolic subset" {
  let x = @mpf.from_str("0.5")
  assert_mpf_close_to_text(
    mpf_sin(x, 140, @mpf.round_nearest),
    "0.479425538604",
    14,
  )
  assert_mpf_close_to_text(
    mpf_cos(x, 140, @mpf.round_nearest),
    "0.877582561890",
    14,
  )
  assert_mpf_close_to_text(
    mpf_tan(x, 140, @mpf.round_nearest),
    "0.546302489843",
    14,
  )
  assert_mpf_close_to_text(
    mpf_sinh(x, 140, @mpf.round_nearest),
    "0.521095305493",
    14,
  )
  assert_mpf_close_to_text(
    mpf_cosh(x, 140, @mpf.round_nearest),
    "1.127625965206",
    14,
  )
  assert_mpf_close_to_text(
    mpf_tanh(x, 140, @mpf.round_nearest),
    "0.462117157260",
    14,
  )
}

///|
test "mpf inverse subset" {
  let half = @mpf.from_str("0.5")
  assert_mpf_close_to_text(
    mpf_asin(half, 140, @mpf.round_nearest),
    "0.523598775598",
    14,
  )
  assert_mpf_close_to_text(
    mpf_acos(half, 140, @mpf.round_nearest),
    "1.047197551196",
    14,
  )
  assert_mpf_close_to_text(
    mpf_asinh(@mpf.fone, 140, @mpf.round_nearest),
    "0.881373587019",
    14,
  )
  assert_mpf_close_to_text(
    mpf_acosh(@mpf.from_int(2), 140, @mpf.round_nearest),
    "1.316957896924",
    14,
  )
  assert_mpf_close_to_text(
    mpf_atanh(half, 140, @mpf.round_nearest),
    "0.549306144334",
    14,
  )
}

///|
test "mpf pow and constants subset" {
  assert_mpf_close_to_text(
    mpf_pow(@mpf.from_int(2), @mpf.from_str("0.5"), 140, @mpf.round_nearest),
    "1.414213562373",
    14,
  )
  assert_mpf_close_to_text(
    mpf_nthroot(@mpf.from_int(2), 5, 140, @mpf.round_nearest),
    "1.148698354997",
    14,
  )
  assert_eq(
    mpf_nthroot(@mpf.from_int(-8), 3, 120, @mpf.round_nearest),
    @mpf.from_int(-2),
  )
  assert_mpf_close_to_text(
    mpf_cbrt(@mpf.from_int(2), 140, @mpf.round_nearest),
    "1.259921049894",
    14,
  )
  assert_mpf_close_to_text(mpf_e(140, @mpf.round_nearest), "2.718281828459", 14)
  assert_mpf_close_to_text(
    mpf_ln2(140, @mpf.round_nearest),
    "0.693147180559",
    14,
  )
  assert_mpf_close_to_text(
    mpf_ln10(140, @mpf.round_nearest),
    "2.302585092994",
    14,
  )
  assert_mpf_close_to_text(
    mpf_phi(140, @mpf.round_nearest),
    "1.618033988749",
    14,
  )
  assert_mpf_close_to_text(
    mpf_degree(140, @mpf.round_nearest),
    "0.017453292519",
    14,
  )
}

///|
test "panic inverse domain" {
  ignore(mpf_asin(@mpf.from_int(2), 80, @mpf.round_nearest))
}
