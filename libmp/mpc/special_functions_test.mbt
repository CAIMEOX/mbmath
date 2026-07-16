///|
fn assert_real_close(
  z : RawMpc,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  assert_close_with_dps(z.real, expected_text, dps)
}

///|
fn assert_imag_close(
  z : RawMpc,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  assert_close_with_dps(z.imag, expected_text, dps)
}

///|
fn special_dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn special_mantissa_digit_count(expected_text : String) -> Int {
  let mut digits = 0
  for c in expected_text {
    if c == 'e' || c == 'E' {
      break
    }
    if c >= '0' && c <= '9' {
      digits += 1
    }
  }
  digits
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let y = @mpf.RawMpf::parse(expected, prec=420, rnd=Nearest)
  let err = x.sub(y, 320, Nearest).abs(320, Nearest)
  let tol_v = @mpf.RawMpf::parse(tol, prec=320, rnd=Nearest)
  assert_true(err < tol_v)
}

///|
fn assert_close_with_dps(
  x : @mpf.RawMpf,
  expected_text : String,
  dps : Int,
) -> Unit raise {
  let prec = special_dps_to_prec(dps)
  let expected = @mpf.RawMpf::parse(expected_text, prec~, rnd=Nearest)
  let err = x.sub(expected, prec, Nearest).abs(prec, Nearest)
  let digits = special_mantissa_digit_count(expected_text)
  let sig_digits = if digits <= 1 { 0 } else { digits - 1 }
  let rel_tol = if sig_digits == 0 {
    @mpf.RawMpf::one()
  } else {
    @mpf.RawMpf::parse("1e-\{sig_digits}", prec~, rnd=Nearest)
  }
  let mut scale = expected.abs(prec, Nearest)
  if scale < @mpf.RawMpf::one() {
    scale = @mpf.RawMpf::one()
  }
  let tol = scale.mul(rel_tol, prec, Nearest)
  assert_true(err <= tol)
}

///|
fn assert_mpc_close_to_str(
  z : RawMpc,
  re_expected : String,
  im_expected : String,
  tol : String,
) -> Unit raise {
  assert_close_to_str(z.real, re_expected, tol)
  assert_close_to_str(z.imag, im_expected, tol)
}

///|
fn assert_pos_inf(x : @mpf.RawMpf) -> Unit raise {
  assert_true(x.is_infinite())
  @debug.assert_eq(x.sign, 0)
}

///|
fn assert_neg_inf(x : @mpf.RawMpf) -> Unit raise {
  assert_true(x.is_infinite())
  @debug.assert_eq(x.sign, 1)
}

///|
fn pos_zero() -> @mpf.RawMpf {
  @mpf.RawMpf::zero()
}

///|
fn assert_zero(x : @mpf.RawMpf) -> Unit raise {
  assert_true(x.is_zero())
}

///|
test "fp gamma complex subset from mpmath test_fp" {
  let z1 = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4)).gamma(
    260,
    Nearest,
  )
  assert_close_to_str(z1.real, "0.0052255384713692141947", "5e-12")
  assert_close_to_str(z1.imag, "-0.17254707929430018772", "5e-12")
  let z2 = RawMpc::new(@mpf.RawMpf::from_int(-3), @mpf.RawMpf::from_int(-4)).gamma(
    300,
    Nearest,
  )
  assert_close_to_str(z2.real, "0.00001460997305874775607", "5e-12")
  assert_close_to_str(z2.imag, "-0.000020760733311509070396", "5e-12")
}

///|
test "fp loggamma branch-consistent subset from mpmath test_fp" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4))
  let lg = z.loggamma(300, Nearest)
  let g = z.gamma(300, Nearest)
  let exp_lg = lg.exp(300, Nearest)
  let err = exp_lg.sub(g, 300, Nearest).abs(300, Nearest)
  assert_true(err < @mpf.RawMpf::parse("1e-8"))
}

///|
test "fp zeta real-axis consistency subset from mpmath test_fp" {
  let z2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).zeta(
    260,
    Nearest,
  )
  assert_real_close(z2, "1.644934066848", 13)
  assert_true(z2.imag.abs(260, Nearest) < @mpf.RawMpf::parse("1e-16"))
}

///|
test "fp zeta complex plane diff subset from mpmath" {
  let z1 = RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(3)).zeta(
    240,
    Nearest,
  )
  assert_mpc_close_to_str(
    z1, "0.132971155879298648273047416644", "0.123053300404587764939407830125", "5e-9",
  )
  let z2 = RawMpc::new(@mpf.RawMpf::parse("-3.5"), @mpf.RawMpf::parse("2.25")).zeta(
    260,
    Nearest,
  )
  assert_mpc_close_to_str(
    z2, "-0.009111496879787013707237292310", "0.054838955454081673868911130970",
    "5e-8",
  )
  let z3 = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::from_int(30)).zeta(
    260,
    Nearest,
  )
  assert_mpc_close_to_str(
    z3, "-0.586482788839217946562584852344", "-0.611149631076442807825222296031",
    "2e-7",
  )
  let z4 = RawMpc::new(@mpf.RawMpf::parse("1.2"), @mpf.RawMpf::from_int(40)).zeta(
    260,
    Nearest,
  )
  assert_mpc_close_to_str(
    z4, "0.862291000319372365115413460585", "-0.374827763862895619905398744575",
    "2e-7",
  )
}

///|
test "fp altzeta complex subset from mpmath test_fp" {
  let z = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::zero()).eta(220, Nearest)
  assert_real_close(z, "0.693147180559945", 16)
  assert_true(z.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-18"))
}

///|
test "fp altzeta complex plane diff and consistency subset" {
  let s = RawMpc::new(@mpf.RawMpf::parse("-4.2"), @mpf.RawMpf::parse("7.5"))
  let a = s.eta(260, Nearest)
  assert_mpc_close_to_str(
    a, "111.022494591321360378961636379388", "0.593823202500014959011928568381",
    "2e-6",
  )
  let z = s.zeta(260, Nearest)
  let factor = RawMpc::one().sub(
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).pow(
      RawMpc::one().sub(s, 320, Nearest),
      320,
      Nearest,
    ),
    320,
    Nearest,
  )
  let rhs = z.mul(factor, 320, Nearest)
  let err = a.sub(rhs, 320, Nearest).abs(320, Nearest)
  assert_true(err < @mpf.RawMpf::parse("1e-10"))
}

///|
test "fp sinpi/cospi real subset from mpmath test_fp" {
  let s_quarter = RawMpc::new(@mpf.RawMpf::parse("0.25"), @mpf.RawMpf::zero()).sin_pi(
    220,
    Nearest,
  )
  let s_three_half = RawMpc::new(@mpf.RawMpf::parse("1.5"), @mpf.RawMpf::zero()).sin_pi(
    220,
    Nearest,
  )
  let c_three_quarter = RawMpc::new(
    @mpf.RawMpf::parse("0.75"),
    @mpf.RawMpf::zero(),
  ).cos_pi(220, Nearest)
  assert_real_close(s_quarter, "0.707106781186547", 16)
  assert_true(s_quarter.imag.abs(220, Nearest) < @mpf.RawMpf::parse("1e-18"))
  assert_real_close(s_three_half, "-1", 8)
  assert_real_close(c_three_quarter, "-0.707106781186547", 16)
}

///|
test "fp sinpi/cospi complex subset from mpmath test_fp" {
  let z = RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::from_int(3))
  let s = z.sin_pi(260, Nearest)
  let c = z.cos_pi(260, Nearest)
  assert_true(s.real.abs(260, Nearest) < @mpf.RawMpf::parse("1e-12"))
  assert_close_to_str(s.imag, "6195.8238636085899556", "5e-7")
  assert_close_to_str(c.real, "6195.8239443081075259", "5e-7")
  assert_true(c.imag.abs(260, Nearest) < @mpf.RawMpf::parse("1e-12"))
}

///|
test "fp expj/expjpi subset from mpmath test_fp" {
  let e1 = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::zero()).exp_i(
    220,
    Nearest,
  )
  assert_real_close(e1, "0.540302305868139", 16)
  assert_imag_close(e1, "0.841470984807896", 16)
  let epi = RawMpc::new(@mpf.RawMpf::parse("0.75"), @mpf.RawMpf::zero()).exp_i_pi(
    220,
    Nearest,
  )
  assert_real_close(epi, "-0.707106781186547", 16)
  assert_imag_close(epi, "0.707106781186547", 16)
}

///|
test "fp isfinite semantics subset" {
  assert_true(
    RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero()).is_infinite(),
  )
  assert_true(
    RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::zero()).is_non_finite(),
  )
  assert_false(
    RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(2)).is_non_finite(),
  )
}

///|
test "fp tanh/tan finite sanity subset" {
  let z = RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(2))
  let t = z.tan(220, Nearest)
  let th = z.tanh(220, Nearest)
  assert_close_to_str(t.real, "0.033812826079896690284", "2e-12")
  assert_close_to_str(t.imag, "1.0147936161466335681", "2e-12")
  assert_close_to_str(th.real, "1.1667362572409198818", "2e-12")
  assert_close_to_str(th.imag, "-0.2434582011857252527", "2e-12")
}

///|
test "fp tanh special inf/nan subset from mpmath test_fp" {
  let pp = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).tanh(
    120,
    Nearest,
  )
  let pn = RawMpc::new(
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).tanh(120, Nearest)
  let np = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  ).tanh(120, Nearest)
  let nn = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).tanh(120, Nearest)
  @debug.assert_eq(pp.real, @mpf.RawMpf::one())
  @debug.assert_eq(pn.real, @mpf.RawMpf::one())
  @debug.assert_eq(np.real, @mpf.RawMpf::from_int(-1))
  @debug.assert_eq(nn.real, @mpf.RawMpf::from_int(-1))
  @debug.assert_eq(pp.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(pn.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(np.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(nn.imag, @mpf.RawMpf::zero())
  let p2 = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::from_int(2)).tanh(
    120,
    Nearest,
  )
  let n2 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::from_int(2),
  ).tanh(120, Nearest)
  @debug.assert_eq(p2.real, @mpf.RawMpf::one())
  @debug.assert_eq(n2.real, @mpf.RawMpf::from_int(-1))
  @debug.assert_eq(p2.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(n2.imag, @mpf.RawMpf::zero())
  let zminf = RawMpc::new(@mpf.RawMpf::zero(), @mpf.RawMpf::negative_infinity()).tanh(
    120,
    Nearest,
  )
  @debug.assert_eq(zminf.real, @mpf.RawMpf::zero())
  assert_true(zminf.imag.is_nan())
  let fminf = RawMpc::new(
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::negative_infinity(),
  ).tanh(120, Nearest)
  assert_true(fminf.real.is_nan())
  assert_true(fminf.imag.is_nan())
  let pnan = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::nan()).tanh(
    120,
    Nearest,
  )
  let nnan = RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::nan()).tanh(
    120,
    Nearest,
  )
  @debug.assert_eq(pnan.real, @mpf.RawMpf::one())
  @debug.assert_eq(nnan.real, @mpf.RawMpf::from_int(-1))
  @debug.assert_eq(pnan.imag, @mpf.RawMpf::zero())
  @debug.assert_eq(nnan.imag, @mpf.RawMpf::zero())
}

///|
test "fp tan special inf/nan subset from mpmath test_fp" {
  let pp = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).tan(
    120,
    Nearest,
  )
  let pn = RawMpc::new(
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).tan(120, Nearest)
  let np = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  ).tan(120, Nearest)
  let nn = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).tan(120, Nearest)
  @debug.assert_eq(pp.real, @mpf.RawMpf::zero())
  @debug.assert_eq(pn.real, @mpf.RawMpf::zero())
  @debug.assert_eq(np.real, @mpf.RawMpf::zero())
  @debug.assert_eq(nn.real, @mpf.RawMpf::zero())
  @debug.assert_eq(pp.imag, @mpf.RawMpf::one())
  @debug.assert_eq(np.imag, @mpf.RawMpf::one())
  @debug.assert_eq(pn.imag, @mpf.RawMpf::from_int(-1))
  @debug.assert_eq(nn.imag, @mpf.RawMpf::from_int(-1))
  let p = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::infinity()).tan(
    120,
    Nearest,
  )
  let n = RawMpc::new(
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::negative_infinity(),
  ).tan(120, Nearest)
  @debug.assert_eq(p.real, @mpf.RawMpf::zero())
  @debug.assert_eq(n.real, @mpf.RawMpf::zero())
  @debug.assert_eq(p.imag, @mpf.RawMpf::one())
  @debug.assert_eq(n.imag, @mpf.RawMpf::from_int(-1))
  let inf0 = RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::zero()).tan(
    120,
    Nearest,
  )
  assert_true(inf0.real.is_nan())
  @debug.assert_eq(inf0.imag, @mpf.RawMpf::zero())
  let inf2 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::from_int(2),
  ).tan(120, Nearest)
  assert_true(inf2.real.is_nan())
  assert_true(inf2.imag.is_nan())
  let nanp = RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::infinity()).tan(
    120,
    Nearest,
  )
  let nann = RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::negative_infinity()).tan(
    120,
    Nearest,
  )
  @debug.assert_eq(nanp.real, @mpf.RawMpf::zero())
  @debug.assert_eq(nann.real, @mpf.RawMpf::zero())
  @debug.assert_eq(nanp.imag, @mpf.RawMpf::one())
  @debug.assert_eq(nann.imag, @mpf.RawMpf::from_int(-1))
}

///|
test "fp asin special inf/nan subset from mpmath test_fp" {
  let app = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).asin(
    200,
    Nearest,
  )
  let apn = RawMpc::new(
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).asin(200, Nearest)
  let anp = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  ).asin(200, Nearest)
  let ann = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).asin(200, Nearest)
  assert_close_to_str(
    app.real,
    "0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_close_to_str(
    apn.real,
    "0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_close_to_str(
    anp.real,
    "-0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_close_to_str(
    ann.real,
    "-0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_pos_inf(app.imag)
  assert_neg_inf(apn.imag)
  assert_pos_inf(anp.imag)
  assert_neg_inf(ann.imag)
  let api = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::one()).asin(
    200,
    Nearest,
  )
  let ani = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::from_int(-1),
  ).asin(200, Nearest)
  assert_close_to_str(
    api.real,
    "1.570796326794896619231321691639751442",
    "1e-25",
  )
  assert_close_to_str(
    ani.real,
    "-1.570796326794896619231321691639751442",
    "1e-25",
  )
  assert_pos_inf(api.imag)
  assert_neg_inf(ani.imag)
  let inf_nan_p = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::nan()).asin(
    120,
    Nearest,
  )
  let inf_nan_n = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::nan(),
  ).asin(120, Nearest)
  assert_true(inf_nan_p.real.is_nan())
  assert_true(inf_nan_n.real.is_nan())
  assert_neg_inf(inf_nan_p.imag)
  assert_neg_inf(inf_nan_n.imag)
  let nan_inf_p = RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::infinity()).asin(
    120,
    Nearest,
  )
  let nan_inf_n = RawMpc::new(
    @mpf.RawMpf::nan(),
    @mpf.RawMpf::negative_infinity(),
  ).asin(120, Nearest)
  assert_true(nan_inf_p.real.is_nan())
  assert_true(nan_inf_n.real.is_nan())
  assert_pos_inf(nan_inf_p.imag)
  assert_neg_inf(nan_inf_n.imag)
}

///|
test "fp acos special inf/nan subset from mpmath test_fp" {
  let app = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::infinity()).acos(
    200,
    Nearest,
  )
  let apn = RawMpc::new(
    @mpf.RawMpf::infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).acos(200, Nearest)
  let anp = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::infinity(),
  ).acos(200, Nearest)
  let ann = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::negative_infinity(),
  ).acos(200, Nearest)
  assert_close_to_str(
    app.real,
    "0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_close_to_str(
    apn.real,
    "0.785398163397448309615660845819875721",
    "1e-25",
  )
  assert_close_to_str(
    anp.real,
    "2.35619449019234492884698253745962716",
    "1e-24",
  )
  assert_close_to_str(
    ann.real,
    "2.35619449019234492884698253745962716",
    "1e-24",
  )
  assert_neg_inf(app.imag)
  assert_pos_inf(apn.imag)
  assert_neg_inf(anp.imag)
  assert_pos_inf(ann.imag)
  let api = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::one()).acos(
    200,
    Nearest,
  )
  let ani = RawMpc::new(@mpf.RawMpf::negative_infinity(), @mpf.RawMpf::one()).acos(
    200,
    Nearest,
  )
  assert_close_to_str(api.real, "0.0", "1e-30")
  assert_close_to_str(
    ani.real,
    "3.141592653589793238462643383279502884",
    "1e-24",
  )
  assert_neg_inf(api.imag)
  assert_neg_inf(ani.imag)
  let inf_nan_p = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::nan()).acos(
    120,
    Nearest,
  )
  let inf_nan_n = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::nan(),
  ).acos(120, Nearest)
  assert_true(inf_nan_p.real.is_nan())
  assert_true(inf_nan_n.real.is_nan())
  assert_pos_inf(inf_nan_p.imag)
  assert_pos_inf(inf_nan_n.imag)
  let nan_inf_p = RawMpc::new(@mpf.RawMpf::nan(), @mpf.RawMpf::infinity()).acos(
    120,
    Nearest,
  )
  let nan_inf_n = RawMpc::new(
    @mpf.RawMpf::nan(),
    @mpf.RawMpf::negative_infinity(),
  ).acos(120, Nearest)
  assert_true(nan_inf_p.real.is_nan())
  assert_true(nan_inf_n.real.is_nan())
  assert_neg_inf(nan_inf_p.imag)
  assert_pos_inf(nan_inf_n.imag)
}

///|
test "fp asin/acos branch-point finite subset from mpmath test_fp" {
  let asin_p2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).asin(
    260,
    Nearest,
  )
  assert_close_to_str(
    asin_p2.real,
    "1.570796326794896619231321691639751442",
    "2e-24",
  )
  assert_close_to_str(
    asin_p2.imag,
    "-1.316957896924816708625046347307968444",
    "2e-22",
  )
  let asin_n2 = RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::zero()).asin(
    260,
    Nearest,
  )
  assert_close_to_str(
    asin_n2.real,
    "-1.570796326794896619231321691639751442",
    "2e-24",
  )
  assert_close_to_str(
    asin_n2.imag,
    "1.316957896924816708625046347307968444",
    "2e-22",
  )
  let acos_p2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).acos(
    260,
    Nearest,
  )
  assert_close_to_str(acos_p2.real, "0.0", "1e-28")
  assert_close_to_str(
    acos_p2.imag,
    "1.316957896924816708625046347307968444",
    "2e-22",
  )
  let acos_n2 = RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::zero()).acos(
    260,
    Nearest,
  )
  assert_close_to_str(
    acos_n2.real,
    "3.141592653589793238462643383279502884",
    "2e-24",
  )
  assert_close_to_str(
    acos_n2.imag,
    "-1.316957896924816708625046347307968444",
    "2e-22",
  )
}

///|
test "fp zeta critical-line and near-pole consistency subset" {
  let z1 = RawMpc::new(
    @mpf.RawMpf::parse("0.5"),
    @mpf.RawMpf::parse("14.134725141734693"),
  ).zeta(280, Nearest)
  let z1_abs = z1.abs(280, Nearest)
  assert_true(z1_abs < @mpf.RawMpf::parse("1e-9"))
  let z2 = RawMpc::new(
    @mpf.RawMpf::parse("0.5"),
    @mpf.RawMpf::parse("25.010857580145688"),
  ).zeta(280, Nearest)
  let z2_abs = z2.abs(280, Nearest)
  assert_true(z2_abs < @mpf.RawMpf::parse("1e-9"))
  let pole_near = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::parse("1e-9")).zeta(
    320,
    Nearest,
  )
  assert_close_to_str(
    pole_near.real,
    "0.577215664901532860611357271678838591",
    "2e-14",
  )
  assert_close_to_str(
    pole_near.imag,
    "-999999999.999999937645592696736470731",
    "2e-4",
  )
  let s = RawMpc::new(@mpf.RawMpf::parse("0.7"), @mpf.RawMpf::from_int(13))
  let zp = s.zeta(280, Nearest)
  let zn = RawMpc::new(@mpf.RawMpf::parse("0.7"), @mpf.RawMpf::from_int(-13)).zeta(
    280,
    Nearest,
  )
  assert_close_to_str(zp.real, "0.504699905800000617729278196529", "5e-10")
  assert_close_to_str(zp.imag, "-0.551738748792295209420865616191", "5e-10")
  assert_close_to_str(zn.real, "0.504699905800000617729278196529", "5e-10")
  assert_close_to_str(zn.imag, "0.551738748792295209420865616191", "5e-10")
  let diff_re = zp.real.sub(zn.real, 320, Nearest).abs(320, Nearest)
  let sum_im = zp.imag.add(zn.imag, 320, Nearest).abs(320, Nearest)
  assert_true(diff_re < @mpf.RawMpf::parse("2e-12"))
  assert_true(sum_im < @mpf.RawMpf::parse("2e-12"))
}

///|
test "fp asin remaining +/-inf +/-0 combinations from mpmath test_fp" {
  // NOTE: libmp/mpf canonicalizes -0 to +0, so mpmath's -0 input cases are
  // exercised as equivalent zero inputs here.
  let p = 220
  let m0 = pos_zero()
  let inf_p0 = RawMpc::new(@mpf.RawMpf::infinity(), pos_zero()).asin(p, Nearest)
  let inf_n0 = RawMpc::new(@mpf.RawMpf::infinity(), m0).asin(p, Nearest)
  let ninf_p0 = RawMpc::new(@mpf.RawMpf::negative_infinity(), pos_zero()).asin(
    p,
    Nearest,
  )
  let ninf_n0 = RawMpc::new(@mpf.RawMpf::negative_infinity(), m0).asin(
    p,
    Nearest,
  )
  assert_close_to_str(
    inf_p0.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    inf_n0.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    ninf_p0.real,
    "-1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    ninf_n0.real,
    "-1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_pos_inf(inf_p0.imag)
  assert_pos_inf(inf_n0.imag)
  assert_pos_inf(ninf_p0.imag)
  assert_pos_inf(ninf_n0.imag)
  let one_pinf = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::infinity()).asin(
    p,
    Nearest,
  )
  let none_pinf = RawMpc::new(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::infinity(),
  ).asin(p, Nearest)
  let p0_pinf = RawMpc::new(pos_zero(), @mpf.RawMpf::infinity()).asin(
    p,
    Nearest,
  )
  let n0_pinf = RawMpc::new(m0, @mpf.RawMpf::infinity()).asin(p, Nearest)
  let one_ninf = RawMpc::new(
    @mpf.RawMpf::one(),
    @mpf.RawMpf::negative_infinity(),
  ).asin(p, Nearest)
  let none_ninf = RawMpc::new(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::negative_infinity(),
  ).asin(p, Nearest)
  let p0_ninf = RawMpc::new(pos_zero(), @mpf.RawMpf::negative_infinity()).asin(
    p,
    Nearest,
  )
  let n0_ninf = RawMpc::new(m0, @mpf.RawMpf::negative_infinity()).asin(
    p,
    Nearest,
  )
  assert_zero(one_pinf.real)
  assert_zero(none_pinf.real)
  assert_zero(p0_pinf.real)
  assert_zero(n0_pinf.real)
  assert_zero(one_ninf.real)
  assert_zero(none_ninf.real)
  assert_zero(p0_ninf.real)
  assert_zero(n0_ninf.real)
  assert_pos_inf(one_pinf.imag)
  assert_pos_inf(none_pinf.imag)
  assert_pos_inf(p0_pinf.imag)
  assert_pos_inf(n0_pinf.imag)
  assert_neg_inf(one_ninf.imag)
  assert_neg_inf(none_ninf.imag)
  assert_neg_inf(p0_ninf.imag)
  assert_neg_inf(n0_ninf.imag)
  let inf_p1 = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::one()).asin(
    p,
    Nearest,
  )
  let inf_n1 = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::from_int(-1)).asin(
    p,
    Nearest,
  )
  let ninf_p1 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::one(),
  ).asin(p, Nearest)
  let ninf_n1 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::from_int(-1),
  ).asin(p, Nearest)
  assert_close_to_str(
    inf_p1.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    inf_n1.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    ninf_p1.real,
    "-1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    ninf_n1.real,
    "-1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_pos_inf(inf_p1.imag)
  assert_neg_inf(inf_n1.imag)
  assert_pos_inf(ninf_p1.imag)
  assert_neg_inf(ninf_n1.imag)
}

///|
test "fp acos remaining +/-inf +/-0 combinations from mpmath test_fp" {
  // NOTE: libmp/mpf canonicalizes -0 to +0, so mpmath's -0 input cases are
  // exercised as equivalent zero inputs here.
  let p = 220
  let m0 = pos_zero()
  let inf_p0 = RawMpc::new(@mpf.RawMpf::infinity(), pos_zero()).acos(p, Nearest)
  let inf_n0 = RawMpc::new(@mpf.RawMpf::infinity(), m0).acos(p, Nearest)
  let ninf_p0 = RawMpc::new(@mpf.RawMpf::negative_infinity(), pos_zero()).acos(
    p,
    Nearest,
  )
  let ninf_n0 = RawMpc::new(@mpf.RawMpf::negative_infinity(), m0).acos(
    p,
    Nearest,
  )
  assert_zero(inf_p0.real)
  assert_zero(inf_n0.real)
  assert_close_to_str(
    ninf_p0.real,
    "3.141592653589793238462643383279502884",
    "1e-18",
  )
  assert_close_to_str(
    ninf_n0.real,
    "3.141592653589793238462643383279502884",
    "1e-18",
  )
  assert_neg_inf(inf_p0.imag)
  assert_neg_inf(inf_n0.imag)
  assert_neg_inf(ninf_p0.imag)
  assert_neg_inf(ninf_n0.imag)
  let one_pinf = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::infinity()).acos(
    p,
    Nearest,
  )
  let none_pinf = RawMpc::new(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::infinity(),
  ).acos(p, Nearest)
  let p0_pinf = RawMpc::new(pos_zero(), @mpf.RawMpf::infinity()).acos(
    p,
    Nearest,
  )
  let n0_pinf = RawMpc::new(m0, @mpf.RawMpf::infinity()).acos(p, Nearest)
  let one_ninf = RawMpc::new(
    @mpf.RawMpf::one(),
    @mpf.RawMpf::negative_infinity(),
  ).acos(p, Nearest)
  let none_ninf = RawMpc::new(
    @mpf.RawMpf::from_int(-1),
    @mpf.RawMpf::negative_infinity(),
  ).acos(p, Nearest)
  let p0_ninf = RawMpc::new(pos_zero(), @mpf.RawMpf::negative_infinity()).acos(
    p,
    Nearest,
  )
  let n0_ninf = RawMpc::new(m0, @mpf.RawMpf::negative_infinity()).acos(
    p,
    Nearest,
  )
  assert_close_to_str(
    one_pinf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    none_pinf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    p0_pinf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    n0_pinf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    one_ninf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    none_ninf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    p0_ninf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_close_to_str(
    n0_ninf.real,
    "1.570796326794896619231321691639751442",
    "1e-18",
  )
  assert_neg_inf(one_pinf.imag)
  assert_neg_inf(none_pinf.imag)
  assert_neg_inf(p0_pinf.imag)
  assert_neg_inf(n0_pinf.imag)
  assert_pos_inf(one_ninf.imag)
  assert_pos_inf(none_ninf.imag)
  assert_pos_inf(p0_ninf.imag)
  assert_pos_inf(n0_ninf.imag)
  let inf_p1 = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::one()).acos(
    p,
    Nearest,
  )
  let inf_n1 = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::from_int(-1)).acos(
    p,
    Nearest,
  )
  let ninf_p1 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::one(),
  ).acos(p, Nearest)
  let ninf_n1 = RawMpc::new(
    @mpf.RawMpf::negative_infinity(),
    @mpf.RawMpf::from_int(-1),
  ).acos(p, Nearest)
  assert_zero(inf_p1.real)
  assert_zero(inf_n1.real)
  assert_close_to_str(
    ninf_p1.real,
    "3.141592653589793238462643383279502884",
    "1e-18",
  )
  assert_close_to_str(
    ninf_n1.real,
    "3.141592653589793238462643383279502884",
    "1e-18",
  )
  assert_neg_inf(inf_p1.imag)
  assert_pos_inf(inf_n1.imag)
  assert_neg_inf(ninf_p1.imag)
  assert_pos_inf(ninf_n1.imag)
}

///|
test "fp zeta extra deep-plane relation subset" {
  let p = 320
  let s = RawMpc::new(@mpf.RawMpf::parse("-7.25"), @mpf.RawMpf::parse("19.5"))
  let z = s.zeta(p, Nearest)
  let eta = s.eta(p, Nearest)
  let factor = RawMpc::one().sub(
    RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::zero()).pow(
      RawMpc::one().sub(s, p, Nearest),
      p,
      Nearest,
    ),
    p,
    Nearest,
  )
  let rhs = z.mul(factor, p, Nearest)
  let rel_err = eta.sub(rhs, p, Nearest).abs(p, Nearest)
  assert_true(rel_err < @mpf.RawMpf::parse("5e-9"))

  let sc = s.conjugate(p, Nearest)
  let zc = sc.zeta(p, Nearest)
  let z_conj = z.conjugate(p, Nearest)
  let conj_err = zc.sub(z_conj, p, Nearest).abs(p, Nearest)
  assert_true(conj_err < @mpf.RawMpf::parse("5e-9"))
}
