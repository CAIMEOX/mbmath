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
  assert_true(err <= tol)
}

///|
test "atan2 basic quadrants" {
  let q1 = atan2(
    @mpf.RawMpf::from_int(1),
    @mpf.RawMpf::from_int(1),
    80,
    Nearest,
  )
  assert_mpf_close_to_text(q1, "0.78539816339", 12)
  let q2 = atan2(
    @mpf.RawMpf::from_int(1),
    @mpf.RawMpf::from_int(-1),
    80,
    Nearest,
  )
  assert_mpf_close_to_text(q2, "2.35619449019", 12)
  let q3 = atan2(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::from_int(-1),
    80,
    Nearest,
  )
  assert_mpf_close_to_text(q3, "-2.35619449019", 12)
}

///|
test "pi baseline" {
  let pi = pi(80, Nearest)
  assert_mpf_close_to_text(pi, "3.14159265358979", 15)
}

///|
test "atan baseline" {
  let a = atan(@mpf.RawMpf::from_int(1), 100, Nearest)
  assert_mpf_close_to_text(a, "0.7853981633974483", 16)
  let b = atan(@mpf.RawMpf::from_int(-1), 100, Nearest)
  assert_mpf_close_to_text(b, "-0.7853981633974483", 16)
}

///|
test "exp baseline" {
  @debug.assert_eq(exp(@mpf.RawMpf::zero(), 80, Nearest), @mpf.RawMpf::one())
  let e = exp(@mpf.RawMpf::one(), 120, Nearest)
  assert_mpf_close_to_text(e, "2.718281828459045", 16)
  let inv_e = exp(@mpf.RawMpf::from_int(-1), 120, Nearest)
  assert_mpf_close_to_text(inv_e, "0.3678794411714423", 16)
}

///|
test "ln baseline" {
  @debug.assert_eq(ln(@mpf.RawMpf::one(), 80, Nearest), @mpf.RawMpf::zero())
  @debug.assert_eq(
    ln(@mpf.RawMpf::zero(), 80, Nearest),
    @mpf.RawMpf::negative_infinity(),
  )
  let ln2 = ln(@mpf.RawMpf::from_int(2), 120, Nearest)
  assert_mpf_close_to_text(ln2, "0.6931471805599453", 16)
  let e = exp(@mpf.RawMpf::one(), 120, Nearest)
  let back = ln(e, 120, Nearest)
  assert_mpf_close_to_text(back, "1.0", 12)
}

///|
test "log1p and constant helpers subset" {
  let l_small = log1p(@mpf.RawMpf::parse("1e-10"), 180, Nearest)
  assert_mpf_close_to_text(l_small, "9.999999999500000e-11", 18)
  @debug.assert_eq(
    log1p(@mpf.RawMpf::from_int(-1), 120, Nearest),
    @mpf.RawMpf::negative_infinity(),
  )
  let sp = sqrt_pi(160, Nearest)
  assert_mpf_close_to_text(sp, "1.772453850905516", 16)
  let lsp = ln_sqrt_2pi(160, Nearest)
  assert_mpf_close_to_text(lsp, "0.918938533204672", 16)
}

///|
test "panic ln non-positive" {
  ignore(ln(@mpf.RawMpf::from_int(-1), 80, Nearest))
}

///|
test "panic log1p below -1" {
  ignore(log1p(@mpf.RawMpf::parse("-1.25"), 80, Nearest))
}

///|
test "mpmath diff subset for libelefun" {
  // Expected values are generated from mpmath with mp.dps=80.
  assert_mpf_close_to_text(
    atan(@mpf.RawMpf::parse("0.1"), 140, Nearest),
    "0.099668652491",
    14,
  )
  assert_mpf_close_to_text(
    atan2(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(3), 140, Nearest),
    "-0.588002603547",
    14,
  )
  assert_mpf_close_to_text(pi(140, Nearest), "3.141592653589793", 16)
  assert_mpf_close_to_text(
    exp(@mpf.RawMpf::parse("0.5"), 140, Nearest),
    "1.648721270700",
    14,
  )
  assert_mpf_close_to_text(
    ln(@mpf.RawMpf::from_int(3), 140, Nearest),
    "1.098612288668",
    14,
  )
}

///|
test "mpf trig and hyperbolic subset" {
  let x = @mpf.RawMpf::parse("0.5")
  assert_mpf_close_to_text(sin(x, 140, Nearest), "0.479425538604", 14)
  assert_mpf_close_to_text(cos(x, 140, Nearest), "0.877582561890", 14)
  assert_mpf_close_to_text(tan(x, 140, Nearest), "0.546302489843", 14)
  assert_mpf_close_to_text(sinh(x, 140, Nearest), "0.521095305493", 14)
  assert_mpf_close_to_text(cosh(x, 140, Nearest), "1.127625965206", 14)
  assert_mpf_close_to_text(tanh(x, 140, Nearest), "0.462117157260", 14)
}

///|
test "mpf inverse subset" {
  let half = @mpf.RawMpf::parse("0.5")
  assert_mpf_close_to_text(asin(half, 140, Nearest), "0.523598775598", 14)
  assert_mpf_close_to_text(acos(half, 140, Nearest), "1.047197551196", 14)
  assert_mpf_close_to_text(
    asinh(@mpf.RawMpf::one(), 140, Nearest),
    "0.881373587019",
    14,
  )
  assert_mpf_close_to_text(
    acosh(@mpf.RawMpf::from_int(2), 140, Nearest),
    "1.316957896924",
    14,
  )
  assert_mpf_close_to_text(atanh(half, 140, Nearest), "0.549306144334", 14)
}

///|
test "mpf pow and constants subset" {
  assert_mpf_close_to_text(
    pow(@mpf.RawMpf::from_int(2), @mpf.RawMpf::parse("0.5"), 140, Nearest),
    "1.414213562373",
    14,
  )
  assert_mpf_close_to_text(
    nthroot(@mpf.RawMpf::from_int(2), 5, 140, Nearest),
    "1.148698354997",
    14,
  )
  @debug.assert_eq(
    nthroot(@mpf.RawMpf::from_int(-8), 3, 120, Nearest),
    @mpf.RawMpf::from_int(-2),
  )
  assert_mpf_close_to_text(
    cbrt(@mpf.RawMpf::from_int(2), 140, Nearest),
    "1.259921049894",
    14,
  )
  assert_mpf_close_to_text(e(140, Nearest), "2.718281828459", 14)
  assert_mpf_close_to_text(ln2(140, Nearest), "0.693147180559", 14)
  assert_mpf_close_to_text(ln10(140, Nearest), "2.302585092994", 14)
  assert_mpf_close_to_text(phi(140, Nearest), "1.618033988749", 14)
  assert_mpf_close_to_text(degree(140, Nearest), "0.017453292519", 14)
}

///|
test "panic inverse domain" {
  ignore(asin(@mpf.RawMpf::from_int(2), 80, Nearest))
}
