///|
fn assert_real_prefix(z : RawMpc, prefix : String, dps : Int) -> Unit raise {
  assert_true(@mpf.to_str_opts(z.real, dps~).has_prefix(prefix))
}

///|
fn assert_imag_prefix(z : RawMpc, prefix : String, dps : Int) -> Unit raise {
  assert_true(@mpf.to_str_opts(z.imag, dps~).has_prefix(prefix))
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let y = @mpf.from_str(expected, prec=420, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, y, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
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
  assert_true(@mpf.is_inf(x))
  assert_eq(x.sign, 0)
}

///|
fn assert_neg_inf(x : @mpf.RawMpf) -> Unit raise {
  assert_true(@mpf.is_inf(x))
  assert_eq(x.sign, 1)
}

///|
fn pos_zero() -> @mpf.RawMpf {
  @mpf.fzero
}

///|
fn assert_zero(x : @mpf.RawMpf) -> Unit raise {
  assert_true(@mpf.is_zero(x))
}

///|
test "p1 fp gamma complex subset from mpmath test_fp" {
  let z1 = mpc_gamma(
    from_parts(@mpf.from_int(3), @mpf.from_int(4)),
    260,
    @mpf.round_nearest,
  )
  assert_close_to_str(z1.real, "0.0052255384713692141947", "5e-12")
  assert_close_to_str(z1.imag, "-0.17254707929430018772", "5e-12")
  let z2 = mpc_gamma(
    from_parts(@mpf.from_int(-3), @mpf.from_int(-4)),
    300,
    @mpf.round_nearest,
  )
  assert_close_to_str(z2.real, "0.00001460997305874775607", "5e-12")
  assert_close_to_str(z2.imag, "-0.000020760733311509070396", "5e-12")
}

///|
test "p1 fp loggamma branch-consistent subset from mpmath test_fp" {
  let z = from_parts(@mpf.from_int(3), @mpf.from_int(4))
  let lg = mpc_loggamma(z, 300, @mpf.round_nearest)
  let g = mpc_gamma(z, 300, @mpf.round_nearest)
  let exp_lg = mpc_exp(lg, 300, @mpf.round_nearest)
  let err = mpc_abs(
    mpc_sub(exp_lg, g, 300, @mpf.round_nearest),
    300,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-8")))
}

///|
test "p1 fp zeta real-axis consistency subset from mpmath test_fp" {
  let z2 = mpc_zeta(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    260,
    @mpf.round_nearest,
  )
  assert_real_prefix(z2, "1.644934066848", 13)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(z2.imag, 260, @mpf.round_nearest),
      @mpf.from_str("1e-16"),
    ),
  )
}

///|
test "p1 fp zeta complex plane diff subset from mpmath" {
  let z1 = mpc_zeta(
    from_parts(@mpf.from_int(-2), @mpf.from_int(3)),
    240,
    @mpf.round_nearest,
  )
  assert_mpc_close_to_str(
    z1, "0.132971155879298648273047416644", "0.123053300404587764939407830125", "5e-9",
  )
  let z2 = mpc_zeta(
    from_parts(@mpf.from_str("-3.5"), @mpf.from_str("2.25")),
    260,
    @mpf.round_nearest,
  )
  assert_mpc_close_to_str(
    z2, "-0.009111496879787013707237292310", "0.054838955454081673868911130970",
    "5e-8",
  )
  let z3 = mpc_zeta(
    from_parts(@mpf.from_str("0.25"), @mpf.from_int(30)),
    260,
    @mpf.round_nearest,
  )
  assert_mpc_close_to_str(
    z3, "-0.586482788839217946562584852344", "-0.611149631076442807825222296031",
    "2e-7",
  )
  let z4 = mpc_zeta(
    from_parts(@mpf.from_str("1.2"), @mpf.from_int(40)),
    260,
    @mpf.round_nearest,
  )
  assert_mpc_close_to_str(
    z4, "0.862291000319372365115413460585", "-0.374827763862895619905398744575",
    "2e-7",
  )
}

///|
test "p1 fp altzeta complex subset from mpmath test_fp" {
  let z = mpc_altzeta(
    from_parts(@mpf.fone, @mpf.fzero),
    220,
    @mpf.round_nearest,
  )
  assert_real_prefix(z, "0.693147180559945", 16)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(z.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-18"),
    ),
  )
}

///|
test "p1 fp altzeta complex plane diff and consistency subset" {
  let s = from_parts(@mpf.from_str("-4.2"), @mpf.from_str("7.5"))
  let a = mpc_altzeta(s, 260, @mpf.round_nearest)
  assert_mpc_close_to_str(
    a, "111.022494591321360378961636379388", "0.593823202500014959011928568381",
    "2e-6",
  )
  let z = mpc_zeta(s, 260, @mpf.round_nearest)
  let factor = mpc_sub(
    one(),
    try! mpc_pow(
      from_parts(@mpf.from_int(2), @mpf.fzero),
      mpc_sub(one(), s, 320, @mpf.round_nearest),
      320,
      @mpf.round_nearest,
    ),
    320,
    @mpf.round_nearest,
  )
  let rhs = mpc_mul(z, factor, 320, @mpf.round_nearest)
  let err = mpc_abs(
    mpc_sub(a, rhs, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-10")))
}

///|
test "p1 fp sinpi/cospi real subset from mpmath test_fp" {
  let s_quarter = mpc_sin_pi(
    from_parts(@mpf.from_str("0.25"), @mpf.fzero),
    220,
    @mpf.round_nearest,
  )
  let s_three_half = mpc_sin_pi(
    from_parts(@mpf.from_str("1.5"), @mpf.fzero),
    220,
    @mpf.round_nearest,
  )
  let c_three_quarter = mpc_cos_pi(
    from_parts(@mpf.from_str("0.75"), @mpf.fzero),
    220,
    @mpf.round_nearest,
  )
  assert_real_prefix(s_quarter, "0.707106781186547", 16)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(s_quarter.imag, 220, @mpf.round_nearest),
      @mpf.from_str("1e-18"),
    ),
  )
  assert_real_prefix(s_three_half, "-1", 8)
  assert_real_prefix(c_three_quarter, "-0.707106781186547", 16)
}

///|
test "p1 fp sinpi/cospi complex subset from mpmath test_fp" {
  let z = from_parts(@mpf.fzero, @mpf.from_int(3))
  let s = mpc_sin_pi(z, 260, @mpf.round_nearest)
  let c = mpc_cos_pi(z, 260, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(s.real, 260, @mpf.round_nearest),
      @mpf.from_str("1e-12"),
    ),
  )
  assert_close_to_str(s.imag, "6195.8238636085899556", "5e-7")
  assert_close_to_str(c.real, "6195.8239443081075259", "5e-7")
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(c.imag, 260, @mpf.round_nearest),
      @mpf.from_str("1e-12"),
    ),
  )
}

///|
test "p1 fp expj/expjpi subset from mpmath test_fp" {
  let e1 = mpc_expj(from_parts(@mpf.fone, @mpf.fzero), 220, @mpf.round_nearest)
  assert_real_prefix(e1, "0.540302305868139", 16)
  assert_imag_prefix(e1, "0.841470984807896", 16)
  let epi = mpc_expjpi(
    from_parts(@mpf.from_str("0.75"), @mpf.fzero),
    220,
    @mpf.round_nearest,
  )
  assert_real_prefix(epi, "-0.707106781186547", 16)
  assert_imag_prefix(epi, "0.707106781186547", 16)
}

///|
test "p1 fp isfinite semantics subset" {
  assert_true(mpc_is_inf(from_parts(@mpf.finf, @mpf.fzero)))
  assert_true(mpc_is_infnan(from_parts(@mpf.fnan, @mpf.fzero)))
  assert_false(mpc_is_infnan(from_parts(@mpf.from_int(1), @mpf.from_int(2))))
}

///|
test "p1 fp tanh/tan finite sanity subset" {
  let z = from_parts(@mpf.from_int(1), @mpf.from_int(2))
  let t = mpc_tan(z, 220, @mpf.round_nearest)
  let th = mpc_tanh(z, 220, @mpf.round_nearest)
  assert_close_to_str(t.real, "0.033812826079896690284", "2e-12")
  assert_close_to_str(t.imag, "1.0147936161466335681", "2e-12")
  assert_close_to_str(th.real, "1.1667362572409198818", "2e-12")
  assert_close_to_str(th.imag, "-0.2434582011857252527", "2e-12")
}

///|
test "p1 fp tanh special inf/nan subset from mpmath test_fp" {
  let pp = mpc_tanh(from_parts(@mpf.finf, @mpf.finf), 120, @mpf.round_nearest)
  let pn = mpc_tanh(from_parts(@mpf.finf, @mpf.fninf), 120, @mpf.round_nearest)
  let np = mpc_tanh(from_parts(@mpf.fninf, @mpf.finf), 120, @mpf.round_nearest)
  let nn = mpc_tanh(from_parts(@mpf.fninf, @mpf.fninf), 120, @mpf.round_nearest)
  assert_eq(pp.real, @mpf.fone)
  assert_eq(pn.real, @mpf.fone)
  assert_eq(np.real, @mpf.from_int(-1))
  assert_eq(nn.real, @mpf.from_int(-1))
  assert_eq(pp.imag, @mpf.fzero)
  assert_eq(pn.imag, @mpf.fzero)
  assert_eq(np.imag, @mpf.fzero)
  assert_eq(nn.imag, @mpf.fzero)
  let p2 = mpc_tanh(
    from_parts(@mpf.finf, @mpf.from_int(2)),
    120,
    @mpf.round_nearest,
  )
  let n2 = mpc_tanh(
    from_parts(@mpf.fninf, @mpf.from_int(2)),
    120,
    @mpf.round_nearest,
  )
  assert_eq(p2.real, @mpf.fone)
  assert_eq(n2.real, @mpf.from_int(-1))
  assert_eq(p2.imag, @mpf.fzero)
  assert_eq(n2.imag, @mpf.fzero)
  let zminf = mpc_tanh(
    from_parts(@mpf.fzero, @mpf.fninf),
    120,
    @mpf.round_nearest,
  )
  assert_eq(zminf.real, @mpf.fzero)
  assert_true(@mpf.is_nan(zminf.imag))
  let fminf = mpc_tanh(
    from_parts(@mpf.from_int(2), @mpf.fninf),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(fminf.real))
  assert_true(@mpf.is_nan(fminf.imag))
  let pnan = mpc_tanh(from_parts(@mpf.finf, @mpf.fnan), 120, @mpf.round_nearest)
  let nnan = mpc_tanh(
    from_parts(@mpf.fninf, @mpf.fnan),
    120,
    @mpf.round_nearest,
  )
  assert_eq(pnan.real, @mpf.fone)
  assert_eq(nnan.real, @mpf.from_int(-1))
  assert_eq(pnan.imag, @mpf.fzero)
  assert_eq(nnan.imag, @mpf.fzero)
}

///|
test "p1 fp tan special inf/nan subset from mpmath test_fp" {
  let pp = mpc_tan(from_parts(@mpf.finf, @mpf.finf), 120, @mpf.round_nearest)
  let pn = mpc_tan(from_parts(@mpf.finf, @mpf.fninf), 120, @mpf.round_nearest)
  let np = mpc_tan(from_parts(@mpf.fninf, @mpf.finf), 120, @mpf.round_nearest)
  let nn = mpc_tan(from_parts(@mpf.fninf, @mpf.fninf), 120, @mpf.round_nearest)
  assert_eq(pp.real, @mpf.fzero)
  assert_eq(pn.real, @mpf.fzero)
  assert_eq(np.real, @mpf.fzero)
  assert_eq(nn.real, @mpf.fzero)
  assert_eq(pp.imag, @mpf.fone)
  assert_eq(np.imag, @mpf.fone)
  assert_eq(pn.imag, @mpf.from_int(-1))
  assert_eq(nn.imag, @mpf.from_int(-1))
  let p = mpc_tan(
    from_parts(@mpf.from_int(2), @mpf.finf),
    120,
    @mpf.round_nearest,
  )
  let n = mpc_tan(
    from_parts(@mpf.from_int(2), @mpf.fninf),
    120,
    @mpf.round_nearest,
  )
  assert_eq(p.real, @mpf.fzero)
  assert_eq(n.real, @mpf.fzero)
  assert_eq(p.imag, @mpf.fone)
  assert_eq(n.imag, @mpf.from_int(-1))
  let inf0 = mpc_tan(
    from_parts(@mpf.fninf, @mpf.fzero),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(inf0.real))
  assert_eq(inf0.imag, @mpf.fzero)
  let inf2 = mpc_tan(
    from_parts(@mpf.fninf, @mpf.from_int(2)),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(inf2.real))
  assert_true(@mpf.is_nan(inf2.imag))
  let nanp = mpc_tan(from_parts(@mpf.fnan, @mpf.finf), 120, @mpf.round_nearest)
  let nann = mpc_tan(from_parts(@mpf.fnan, @mpf.fninf), 120, @mpf.round_nearest)
  assert_eq(nanp.real, @mpf.fzero)
  assert_eq(nann.real, @mpf.fzero)
  assert_eq(nanp.imag, @mpf.fone)
  assert_eq(nann.imag, @mpf.from_int(-1))
}

///|
test "p1 fp asin special inf/nan subset from mpmath test_fp" {
  let app = mpc_asin(from_parts(@mpf.finf, @mpf.finf), 200, @mpf.round_nearest)
  let apn = mpc_asin(from_parts(@mpf.finf, @mpf.fninf), 200, @mpf.round_nearest)
  let anp = mpc_asin(from_parts(@mpf.fninf, @mpf.finf), 200, @mpf.round_nearest)
  let ann = mpc_asin(
    from_parts(@mpf.fninf, @mpf.fninf),
    200,
    @mpf.round_nearest,
  )
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
  let api = mpc_asin(from_parts(@mpf.finf, @mpf.fone), 200, @mpf.round_nearest)
  let ani = mpc_asin(
    from_parts(@mpf.fninf, @mpf.from_int(-1)),
    200,
    @mpf.round_nearest,
  )
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
  let inf_nan_p = mpc_asin(
    from_parts(@mpf.finf, @mpf.fnan),
    120,
    @mpf.round_nearest,
  )
  let inf_nan_n = mpc_asin(
    from_parts(@mpf.fninf, @mpf.fnan),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(inf_nan_p.real))
  assert_true(@mpf.is_nan(inf_nan_n.real))
  assert_neg_inf(inf_nan_p.imag)
  assert_neg_inf(inf_nan_n.imag)
  let nan_inf_p = mpc_asin(
    from_parts(@mpf.fnan, @mpf.finf),
    120,
    @mpf.round_nearest,
  )
  let nan_inf_n = mpc_asin(
    from_parts(@mpf.fnan, @mpf.fninf),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(nan_inf_p.real))
  assert_true(@mpf.is_nan(nan_inf_n.real))
  assert_pos_inf(nan_inf_p.imag)
  assert_neg_inf(nan_inf_n.imag)
}

///|
test "p1 fp acos special inf/nan subset from mpmath test_fp" {
  let app = mpc_acos(from_parts(@mpf.finf, @mpf.finf), 200, @mpf.round_nearest)
  let apn = mpc_acos(from_parts(@mpf.finf, @mpf.fninf), 200, @mpf.round_nearest)
  let anp = mpc_acos(from_parts(@mpf.fninf, @mpf.finf), 200, @mpf.round_nearest)
  let ann = mpc_acos(
    from_parts(@mpf.fninf, @mpf.fninf),
    200,
    @mpf.round_nearest,
  )
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
  let api = mpc_acos(from_parts(@mpf.finf, @mpf.fone), 200, @mpf.round_nearest)
  let ani = mpc_acos(from_parts(@mpf.fninf, @mpf.fone), 200, @mpf.round_nearest)
  assert_close_to_str(api.real, "0.0", "1e-30")
  assert_close_to_str(
    ani.real,
    "3.141592653589793238462643383279502884",
    "1e-24",
  )
  assert_neg_inf(api.imag)
  assert_neg_inf(ani.imag)
  let inf_nan_p = mpc_acos(
    from_parts(@mpf.finf, @mpf.fnan),
    120,
    @mpf.round_nearest,
  )
  let inf_nan_n = mpc_acos(
    from_parts(@mpf.fninf, @mpf.fnan),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(inf_nan_p.real))
  assert_true(@mpf.is_nan(inf_nan_n.real))
  assert_pos_inf(inf_nan_p.imag)
  assert_pos_inf(inf_nan_n.imag)
  let nan_inf_p = mpc_acos(
    from_parts(@mpf.fnan, @mpf.finf),
    120,
    @mpf.round_nearest,
  )
  let nan_inf_n = mpc_acos(
    from_parts(@mpf.fnan, @mpf.fninf),
    120,
    @mpf.round_nearest,
  )
  assert_true(@mpf.is_nan(nan_inf_p.real))
  assert_true(@mpf.is_nan(nan_inf_n.real))
  assert_neg_inf(nan_inf_p.imag)
  assert_pos_inf(nan_inf_n.imag)
}

///|
test "p1 fp asin/acos branch-point finite subset from mpmath test_fp" {
  let asin_p2 = mpc_asin(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    260,
    @mpf.round_nearest,
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
  let asin_n2 = mpc_asin(
    from_parts(@mpf.from_int(-2), @mpf.fzero),
    260,
    @mpf.round_nearest,
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
  let acos_p2 = mpc_acos(
    from_parts(@mpf.from_int(2), @mpf.fzero),
    260,
    @mpf.round_nearest,
  )
  assert_close_to_str(acos_p2.real, "0.0", "1e-28")
  assert_close_to_str(
    acos_p2.imag,
    "1.316957896924816708625046347307968444",
    "2e-22",
  )
  let acos_n2 = mpc_acos(
    from_parts(@mpf.from_int(-2), @mpf.fzero),
    260,
    @mpf.round_nearest,
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
test "p1 fp zeta critical-line and near-pole consistency subset" {
  let z1 = mpc_zeta(
    from_parts(@mpf.from_str("0.5"), @mpf.from_str("14.134725141734693")),
    280,
    @mpf.round_nearest,
  )
  let z1_abs = mpc_abs(z1, 280, @mpf.round_nearest)
  assert_true(@mpf.mpf_lt(z1_abs, @mpf.from_str("1e-9")))
  let z2 = mpc_zeta(
    from_parts(@mpf.from_str("0.5"), @mpf.from_str("25.010857580145688")),
    280,
    @mpf.round_nearest,
  )
  let z2_abs = mpc_abs(z2, 280, @mpf.round_nearest)
  assert_true(@mpf.mpf_lt(z2_abs, @mpf.from_str("1e-9")))
  let pole_near = mpc_zeta(
    from_parts(@mpf.fone, @mpf.from_str("1e-9")),
    320,
    @mpf.round_nearest,
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
  let s = from_parts(@mpf.from_str("0.7"), @mpf.from_int(13))
  let zp = mpc_zeta(s, 280, @mpf.round_nearest)
  let zn = mpc_zeta(
    from_parts(@mpf.from_str("0.7"), @mpf.from_int(-13)),
    280,
    @mpf.round_nearest,
  )
  assert_close_to_str(zp.real, "0.504699905800000617729278196529", "5e-10")
  assert_close_to_str(zp.imag, "-0.551738748792295209420865616191", "5e-10")
  assert_close_to_str(zn.real, "0.504699905800000617729278196529", "5e-10")
  assert_close_to_str(zn.imag, "0.551738748792295209420865616191", "5e-10")
  let diff_re = @mpf.mpf_abs(
    @mpf.mpf_sub(zp.real, zn.real, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  let sum_im = @mpf.mpf_abs(
    @mpf.mpf_add(zp.imag, zn.imag, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(diff_re, @mpf.from_str("2e-12")))
  assert_true(@mpf.mpf_lt(sum_im, @mpf.from_str("2e-12")))
}

///|
test "p1 fp asin remaining +/-inf +/-0 combinations from mpmath test_fp" {
  // NOTE: libmp/mpf canonicalizes -0 to +0, so mpmath's -0 input cases are
  // exercised as equivalent zero inputs here.
  let p = 220
  let m0 = pos_zero()
  let inf_p0 = mpc_asin(
    from_parts(@mpf.finf, pos_zero()),
    p,
    @mpf.round_nearest,
  )
  let inf_n0 = mpc_asin(from_parts(@mpf.finf, m0), p, @mpf.round_nearest)
  let ninf_p0 = mpc_asin(
    from_parts(@mpf.fninf, pos_zero()),
    p,
    @mpf.round_nearest,
  )
  let ninf_n0 = mpc_asin(from_parts(@mpf.fninf, m0), p, @mpf.round_nearest)
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
  let one_pinf = mpc_asin(
    from_parts(@mpf.fone, @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let none_pinf = mpc_asin(
    from_parts(@mpf.from_int(-1), @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let p0_pinf = mpc_asin(
    from_parts(pos_zero(), @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let n0_pinf = mpc_asin(from_parts(m0, @mpf.finf), p, @mpf.round_nearest)
  let one_ninf = mpc_asin(
    from_parts(@mpf.fone, @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let none_ninf = mpc_asin(
    from_parts(@mpf.from_int(-1), @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let p0_ninf = mpc_asin(
    from_parts(pos_zero(), @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let n0_ninf = mpc_asin(from_parts(m0, @mpf.fninf), p, @mpf.round_nearest)
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
  let inf_p1 = mpc_asin(from_parts(@mpf.finf, @mpf.fone), p, @mpf.round_nearest)
  let inf_n1 = mpc_asin(
    from_parts(@mpf.finf, @mpf.from_int(-1)),
    p,
    @mpf.round_nearest,
  )
  let ninf_p1 = mpc_asin(
    from_parts(@mpf.fninf, @mpf.fone),
    p,
    @mpf.round_nearest,
  )
  let ninf_n1 = mpc_asin(
    from_parts(@mpf.fninf, @mpf.from_int(-1)),
    p,
    @mpf.round_nearest,
  )
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
test "p1 fp acos remaining +/-inf +/-0 combinations from mpmath test_fp" {
  // NOTE: libmp/mpf canonicalizes -0 to +0, so mpmath's -0 input cases are
  // exercised as equivalent zero inputs here.
  let p = 220
  let m0 = pos_zero()
  let inf_p0 = mpc_acos(
    from_parts(@mpf.finf, pos_zero()),
    p,
    @mpf.round_nearest,
  )
  let inf_n0 = mpc_acos(from_parts(@mpf.finf, m0), p, @mpf.round_nearest)
  let ninf_p0 = mpc_acos(
    from_parts(@mpf.fninf, pos_zero()),
    p,
    @mpf.round_nearest,
  )
  let ninf_n0 = mpc_acos(from_parts(@mpf.fninf, m0), p, @mpf.round_nearest)
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
  let one_pinf = mpc_acos(
    from_parts(@mpf.fone, @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let none_pinf = mpc_acos(
    from_parts(@mpf.from_int(-1), @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let p0_pinf = mpc_acos(
    from_parts(pos_zero(), @mpf.finf),
    p,
    @mpf.round_nearest,
  )
  let n0_pinf = mpc_acos(from_parts(m0, @mpf.finf), p, @mpf.round_nearest)
  let one_ninf = mpc_acos(
    from_parts(@mpf.fone, @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let none_ninf = mpc_acos(
    from_parts(@mpf.from_int(-1), @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let p0_ninf = mpc_acos(
    from_parts(pos_zero(), @mpf.fninf),
    p,
    @mpf.round_nearest,
  )
  let n0_ninf = mpc_acos(from_parts(m0, @mpf.fninf), p, @mpf.round_nearest)
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
  let inf_p1 = mpc_acos(from_parts(@mpf.finf, @mpf.fone), p, @mpf.round_nearest)
  let inf_n1 = mpc_acos(
    from_parts(@mpf.finf, @mpf.from_int(-1)),
    p,
    @mpf.round_nearest,
  )
  let ninf_p1 = mpc_acos(
    from_parts(@mpf.fninf, @mpf.fone),
    p,
    @mpf.round_nearest,
  )
  let ninf_n1 = mpc_acos(
    from_parts(@mpf.fninf, @mpf.from_int(-1)),
    p,
    @mpf.round_nearest,
  )
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
test "p1 fp zeta extra deep-plane relation subset" {
  let p = 320
  let s = from_parts(@mpf.from_str("-7.25"), @mpf.from_str("19.5"))
  let z = mpc_zeta(s, p, @mpf.round_nearest)
  let eta = mpc_altzeta(s, p, @mpf.round_nearest)
  let factor = mpc_sub(
    one(),
    mpc_pow(
      from_parts(@mpf.from_int(2), @mpf.fzero),
      mpc_sub(one(), s, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ),
    p,
    @mpf.round_nearest,
  )
  let rhs = mpc_mul(z, factor, p, @mpf.round_nearest)
  let rel_err = mpc_abs(
    mpc_sub(eta, rhs, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(rel_err, @mpf.from_str("5e-9")))

  let sc = mpc_conjugate(s, p, @mpf.round_nearest)
  let zc = mpc_zeta(sc, p, @mpf.round_nearest)
  let z_conj = mpc_conjugate(z, p, @mpf.round_nearest)
  let conj_err = mpc_abs(
    mpc_sub(zc, z_conj, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(conj_err, @mpf.from_str("5e-9")))
}
