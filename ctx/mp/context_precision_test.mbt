///|
fn assert_context_text_close(
  actual_text : String,
  expected_text : String,
  tol : String,
) -> Unit raise {
  let actual = @mpf.from_str(actual_text, prec=460, rnd=@mpf.round_nearest)
  let expected = @mpf.from_str(expected_text, prec=460, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(actual, expected, 420, @mpf.round_nearest),
    420,
    @mpf.round_nearest,
  )
  let tol_v = @mpf.from_str(tol, prec=420, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_lt(err, tol_v))
}

///|
fn assert_close_to_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let y = @mpf.from_str(expected, prec=460, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, y, 420, @mpf.round_nearest),
    420,
    @mpf.round_nearest,
  )
  let tol_v = @mpf.from_str(tol, prec=420, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_lt(err, tol_v))
}

///|
test "module context metadata and isolation subset" {
  let low = new(80, @mpf.round_down)
  let high = new(260, @mpf.round_nearest)
  @debug.assert_eq(low.precision(), 80)
  @debug.assert_eq(high.precision(), 260)
  @debug.assert_eq(low.round_mode(), @mpf.round_down)
  @debug.assert_eq(high.round_mode(), @mpf.round_nearest)
  let sqrt2_low = low.sqrt(low.make_int(2))
  let sqrt2_high = high.sqrt(high.make_int(2))
  assert_context_text_close(
    low.to_string(sqrt2_low, dps=8),
    "1.4142136",
    "1e-7",
  )
  assert_context_text_close(
    high.to_string(sqrt2_high, dps=20),
    "1.4142135623730950488",
    "1e-18",
  )
}

///|
test "hp expression a=sqrt(3)+pi/2 from mpmath test_hp" {
  let ctx = new(320, @mpf.round_nearest)
  let sqrt3 = ctx.sqrt(ctx.make_int(3))
  let pi = @libelefun.mpf_pi(ctx.precision(), ctx.round_mode())
  let half_pi = @mpf.mpf_div(
    pi,
    @mpf.from_int(2),
    ctx.precision(),
    ctx.round_mode(),
  )
  let a = ctx.add(sqrt3, half_pi)
  assert_context_text_close(
    ctx.to_string(a, dps=24),
    "3.30284713436377391275877",
    "1e-22",
  )
}

///|
test "hp log/exp of a subset from mpmath test_hp" {
  let ctx = new(360, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let log_a = ctx.ln(a)
  let exp_a = ctx.exp(a)
  assert_context_text_close(
    ctx.to_string(log_a, dps=22),
    "1.194784864491089550288",
    "1e-20",
  )
  assert_context_text_close(
    ctx.to_string(exp_a, dps=22),
    "27.18994224087168661137",
    "1e-19",
  )
}

///|
test "hp sin/cos of a subset from mpmath test_hp" {
  let ctx = new(360, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let sin_a = ctx.sin(a)
  let cos_a = ctx.cos(a)
  assert_context_text_close(
    ctx.to_string(sin_a, dps=22),
    "-0.1605565385746906274027",
    "1e-21",
  )
  assert_context_text_close(
    ctx.to_string(cos_a, dps=22),
    "-0.9870266449903537839933",
    "1e-21",
  )
}

///|
test "hp complex sqrt subset from mpmath test_hp" {
  let ctx = new(420, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let b = ctx.make_float("5.719681166601007617111261398629939965")
  let z = ctx.make_complex(a, b)
  let root = ctx.complex_sqrt(z)
  assert_context_text_close(
    @mpf.to_str_opts(root.real, dps=22),
    "2.225720098415113027729",
    "1e-20",
  )
  assert_context_text_close(
    @mpf.to_str_opts(root.imag, dps=22),
    "1.284905763908469090237",
    "1e-20",
  )
}

///|
test "hp complex pow subset from mpmath test_hp" {
  let ctx = new(420, @mpf.round_nearest)
  let a = ctx.make_float("3.302847134363773912758768033145623809")
  let b = ctx.make_float("5.719681166601007617111261398629939965")
  let z = ctx.make_complex(a, b)
  let p = ctx.complex_pow(z, z)
  assert_context_text_close(
    @mpf.to_str_opts(p.real, dps=20),
    "-0.15171310677859590091",
    "1e-19",
  )
  assert_context_text_close(
    @mpf.to_str_opts(p.imag, dps=20),
    "1.2697592504953448937",
    "1e-18",
  )
}

///|
test "mpmath-style wrapper consistency subset" {
  let ctx = new(260, @mpf.round_nearest)
  let x = ctx.make_float("2.5")
  let y = ctx.make_float("3.5")
  let sum = ctx.add(x, y)
  let manual = @mpf.mpf_add(x, y, 260, @mpf.round_nearest)
  @debug.assert_eq(sum, manual)
  let cg = ctx.complex_gamma(
    ctx.make_complex(ctx.make_float("0.5"), @mpf.fzero),
  )
  assert_context_text_close(
    @mpf.to_str_opts(cg.real, dps=16),
    "1.772453850905516",
    "1e-14",
  )
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(cg.imag, 260, @mpf.round_nearest),
      @mpf.from_str("1e-18"),
    ),
  )
}

///|
test "mpmath-style e1 branch behavior subset" {
  let ctx = new(260, @mpf.round_nearest)
  let pos = ctx.e1(ctx.make_float("2"))
  let neg = ctx.e1(ctx.make_float("-2"))
  assert_context_text_close(
    @mpf.to_str_opts(pos.real, dps=16),
    "0.04890051070806112",
    "1e-16",
  )
  assert_context_text_close(@mpf.to_str_opts(pos.imag, dps=8), "0", "1e-7")
  assert_context_text_close(
    @mpf.to_str_opts(neg.real, dps=16),
    "-4.95423435600189",
    "1e-13",
  )
  assert_context_text_close(
    @mpf.to_str_opts(neg.imag, dps=16),
    "-3.14159265358979",
    "1e-13",
  )
}

///|
test "hp large-argument trig subset from mpmath test_hp" {
  let ctx = new(460, @mpf.round_nearest)
  let a = ctx.make_float(
    "3.30284713436377391275876803314562380904138995349793353854327927560584122005190453639516359942830710966670018467204785635351686739977424359467433521615861420725323528325327484262075464241255915238845599752675",
  )
  let a1000 = @mpf.mpf_mul_int(a, 1000, ctx.precision(), ctx.round_mode())
  let sin_a1000 = ctx.sin(a1000)
  let cos_a1000 = ctx.cos(a1000)
  assert_close_to_str(
    sin_a1000, "-0.8589704057744383377635810680377758966432299779412615347706079580109151695416961724733492511852267067",
    "5e-12",
  )
  assert_close_to_str(
    cos_a1000, "-0.5120252357098200185619569646066397109969226134282754042613621553352686662667660613179619804463250687",
    "5e-12",
  )
}

///|
test "hp complex tan subset from mpmath test_hp" {
  let ctx = new(460, @mpf.round_nearest)
  let a = ctx.make_float(
    "3.30284713436377391275876803314562380904138995349793353854327927560584122005190453639516359942830710966670018467204785635351686739977424359467433521615861420725323528325327484262075464241255915238845599752675",
  )
  let b = ctx.make_float(
    "5.71968116660100761711126139862993996586087395735332073427571622004575031474116300529519620938123730851145473473708966080207482581266469342214824842256999042984813905047895479210702109260221361437411947323431",
  )
  let z = ctx.make_complex(a, b)
  let tan_z = @mpc.mpc_tan(z, ctx.precision(), ctx.round_mode())
  assert_close_to_str(
    tan_z.real,
    "6.8226966159475384888265861863101625999748271395644339126019184429111026830824380070400102213741875804368044342309515353631134074491271890467615882710035471686578162073677173148647065131872116479947620e-6",
    "5e-12",
  )
  assert_close_to_str(
    tan_z.imag,
    "0.9999795833048243692245661011298447587046967777739649018690797625964167144641997885223596086284160808141316960103823007312948287483205335757162702259309150715669026865777947502665936317953101462202542168",
    "5e-12",
  )
}
