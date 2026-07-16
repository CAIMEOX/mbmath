///|
test "real zeta derivatives support arbitrary nonnegative orders" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.hurwitz_zeta_derivative(@mpf.RawMpf::zero(), ctx.parse("0.5"), 1),
    "-0.3465735902799726547086160607290882840377500671801276270603400047466968109848473578029316634982093437710007405102853428668427601178790652785163353758175379809653637854141857175951535193119458",
    "2e-143",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.zeta_derivative(ctx.from_int(2), 20),
    "2432902008176640000.000241561699403501917987564009732827423474573285726824728737017367751043088467698241713076099607053425125491079362374564991636260671921144275649869956511500850486675822264",
    "2e-123",
    comparison_precision=560,
  )
}

///|
test "complex Hurwitz zeta derivatives cover complex and reflected arguments" {
  let ctx = MPContext::new(500, Nearest)
  let general = ctx.complex_hurwitz_zeta_derivative(
    ctx.complex(ctx.from_int(3), ctx.from_int(4)),
    ctx.complex(ctx.parse("5.5"), ctx.from_int(2)),
    4,
  )
  assert_close_mpf_str(
    general.real,
    "-0.1400755489477971306810749783860603983404614524406641674334355433242932794185093863674708136034735385433075095181101684209571199146261327148441199236514174380742259363216744408787180036975719",
    "2e-140",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    general.imag,
    "-0.3109263360275413251313634299912163574789460000517503732717012102544408048431217159572656986155878126742089973539576279564591754944144530254938060457934343092410962906709147795150237909689127",
    "2e-140",
    comparison_precision=560,
  )
  let reflected = ctx.complex_hurwitz_zeta_derivative(
    ctx.complex(ctx.parse("-7.25"), ctx.parse("3.5")),
    ctx.complex(ctx.parse("0.75"), @mpf.RawMpf::zero()),
    3,
  )
  assert_close_mpf_str(
    reflected.real,
    "-0.03982471064618710633366090679483824738738908232929612749303430820625352313393970954236799334423377952813297799240533858448308908008891794369511877780145346276748578427204287713982634187757018",
    "2e-139",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    reflected.imag,
    "0.3642734992104649370018848665137640311927606297850429791633579558193025815562307368972182534512379853074349034990514360114974206125657169235545287708406872831863589838461056962494903848547768",
    "2e-139",
    comparison_precision=560,
  )
}

///|
test "zeta derivatives preserve principal branches and high-imaginary accuracy" {
  let ctx = MPContext::new(500, Nearest)
  let negative_parameter = ctx.complex_hurwitz_zeta_derivative(
    ctx.complex(ctx.parse("0.5"), @mpf.RawMpf::zero()),
    ctx.complex(ctx.parse("-2.5"), @mpf.RawMpf::zero()),
    2,
  )
  assert_close_mpf_str(
    negative_parameter.real,
    "-15.75138561273180379245100468222333060573324536410475173114076656465860274789764978041444526545946786354071697619440265659356078938868705404058355274847789414412165025287427100773385165405957",
    "2e-138",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    negative_parameter.imag,
    "26.91361322739991862814725422177420334420610924909660552234158517835038199195667738529165320852136697017396643588941890832786722737223822045808237983483973093610725688046925446740747312087458",
    "2e-138",
    comparison_precision=560,
  )
  let high_imaginary = ctx.complex_zeta_derivative(
    ctx.complex(ctx.parse("0.5"), ctx.from_int(100)),
    4,
  )
  assert_close_mpf_str(
    high_imaginary.real,
    "67.98884097934281790488293757423856603201588691881703483698176894037966727367686068296770433227441147349987428970895040685105947513094869727080621964954844117903175825900982433483007375613629",
    "2e-138",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    high_imaginary.imag,
    "2.696734368615109044391442341892866785615668754022840180248266304073994875240138740187522610642993864452455099732218861832383547692835151640957315112816374309228080025833325666312095002867032",
    "2e-138",
    comparison_precision=560,
  )
}

///|
test "zeta derivative errors and order-zero identity are explicit" {
  let ctx = MPContext::new(320, Nearest)
  let s = ctx.parse("2.75")
  @debug.assert_eq(ctx.zeta_derivative(s, 0), ctx.zeta(s))
  let epsilon = ctx.parse("1e-60")
  let delta = ctx.complex(@mpf.RawMpf::zero(), epsilon)
  let near_pole = ctx.complex_zeta_derivative(
    ctx.complex(@mpf.RawMpf::one(), epsilon),
    3,
  )
  let normalized_pole = near_pole
    .mul(delta.pow_int(4, 380, Nearest), 380, Nearest)
    .div_real(ctx.from_int(-6), 380, Nearest)
  assert_close_mpf_str(
    normalized_pole.real,
    "1",
    "2e-88",
    comparison_precision=380,
  )
  assert_close_mpf_str(
    normalized_pole.imag,
    "0",
    "2e-88",
    comparison_precision=380,
  )
  @debug.assert_eq(
    ctx.complex_zeta_derivative(
      ctx.complex(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero()),
      2,
    ),
    @mpc.RawMpc::zero(),
  )
  let nan_value = ctx.complex_zeta_derivative(
    ctx.complex(@mpf.RawMpf::nan(), @mpf.RawMpf::zero()),
    2,
  )
  assert_true(nan_value.real.is_nan() && nan_value.imag.is_nan())
  @debug.assert_eq(
    ctx.complex_zeta_derivative(
      ctx.complex(@mpf.RawMpf::one(), @mpf.RawMpf::zero()),
      2,
    ),
    ctx.complex(@mpf.RawMpf::infinity(), @mpf.RawMpf::zero()),
  )
  try ctx.zeta_derivative(s, -1) catch {
    DomainError(_) => ()
    _ => fail("unexpected negative zeta derivative error")
  } noraise {
    _ => fail("expected negative zeta derivative order error")
  }
  try
    ctx.hurwitz_zeta_derivative(ctx.parse("0.5"), ctx.parse("-2.5"), 2)
  catch {
    ComplexResult(_) => ()
    _ => fail("unexpected real Hurwitz derivative branch error")
  } noraise {
    _ => fail("expected complex Hurwitz derivative principal value")
  }
  try ctx.hurwitz_zeta_derivative(ctx.from_int(2), ctx.from_int(-3), 1) catch {
    DomainError(_) => ()
    _ => fail("unexpected Hurwitz derivative parameter error")
  } noraise {
    _ => fail("expected negative-integer Hurwitz derivative parameter error")
  }
  try
    ctx.hurwitz_zeta_derivative(ctx.from_int(-2), @mpf.RawMpf::zero(), 1)
  catch {
    DomainError(_) => ()
    _ => fail("unexpected zero Hurwitz parameter error")
  } noraise {
    _ => fail("expected zero Hurwitz parameter derivative error")
  }
}
