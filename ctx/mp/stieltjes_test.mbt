///|
test "Stieltjes constants match high-precision mpmath values" {
  let ctx = MPContext::new(500, Nearest)
  @debug.assert_eq(ctx.stieltjes_constant(0), ctx.euler_mascheroni_constant())
  assert_close_mpf_str(
    ctx.stieltjes_constant(1),
    "-0.072815845483676724860586375874901319137736338334337952599006559741401433571511484878086928244844014604077207278886744759464680212189579259343578895129428052223495152795496",
    "2e-143",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.stieltjes_constant(2),
    "-0.009690363192872318484530386035212529359065806101340749880701365451850755382280414171978197381374537319286223858587946823125346497950962571972526493648255902282233425225376",
    "2e-143",
    comparison_precision=560,
  )
}

///|
test "Stieltjes constants support high derivative orders" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.stieltjes_constant(20),
    "0.00046634356151155944940059482443355052511314347392568899767072662809854458213003290070106347817434830376762767768939786647884903760980610081135914417972563368235122671579593",
    "2e-143",
    comparison_precision=560,
  )
}

///|
test "generalized Stieltjes constants obey the parameter shift identity" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.stieltjes_constant(3, parameter=ctx.parse("2.5")),
    "-0.045814473739178964874818426209171145854561330747525305980307179940604602903559679983552737337099660555838625421884019575800030857359576805233255122121153715822796169557763",
    "2e-142",
    comparison_precision=560,
  )
  let a = ctx.parse("2.5")
  let order = 7
  let shifted = ctx.stieltjes_constant(
    order,
    parameter=a.add(ctx.from_int(1), 0, Down),
  )
  let correction = ctx.ln(a).pow_int(order, 560, Nearest).div(a, 560, Nearest)
  assert_close_mpf_str(
    shifted
    .add(correction, 560, Nearest)
    .sub(ctx.stieltjes_constant(order, parameter=a), 560, Nearest),
    "0",
    "2e-142",
    comparison_precision=560,
  )
}

///|
test "complex Stieltjes branches and errors are explicit" {
  let ctx = MPContext::new(430, Nearest)
  let complex_value = ctx.complex_stieltjes_constant(
    2,
    parameter=ctx.complex(ctx.from_int(2), ctx.from_int(3)),
  )
  assert_close_mpf_str(
    complex_value.real,
    "0.8865180118533927851513897518195548383395197070939661264455228135547585871348347192291982275828290261568542149794178183626905082604",
    "2e-120",
    comparison_precision=480,
  )
  assert_close_mpf_str(
    complex_value.imag,
    "-1.174620488998043289422202779101485399359987896356956984127385299297185487650597270179800222441964817469786059821009055348776081859",
    "2e-120",
    comparison_precision=480,
  )
  let parameter = ctx.complex(ctx.from_int(2), ctx.from_int(3))
  let zeroth = ctx.complex_stieltjes_constant(0, parameter~)
  let digamma = ctx.complex_digamma(parameter)
  assert_close_mpf_str(
    zeroth.real.add(digamma.real, 480, Nearest),
    "0",
    "2e-120",
    comparison_precision=480,
  )
  assert_close_mpf_str(
    zeroth.imag.add(digamma.imag, 480, Nearest),
    "0",
    "2e-120",
    comparison_precision=480,
  )
  let negative_parameter = ctx.complex_stieltjes_constant(
    1,
    parameter=ctx.complex(ctx.parse("-2.5"), @mpf.RawMpf::zero()),
  )
  assert_close_mpf_str(
    negative_parameter.real,
    "-0.6039916845068225129329758879451484537349867905874705556258205695029735523143103945069100415208663014419336713435108583181693466185",
    "2e-120",
    comparison_precision=480,
  )
  assert_close_mpf_str(
    negative_parameter.imag,
    "-9.634217471008699264618773042057142178204652824750324517656496749743970312611040929125973464382492341811920798640732407051087790136",
    "2e-120",
    comparison_precision=480,
  )
  try ctx.stieltjes_constant(-1) catch {
    DomainError(_) => ()
    _ => fail("unexpected negative Stieltjes order error")
  } noraise {
    _ => fail("expected negative Stieltjes order error")
  }
  try ctx.stieltjes_constant(1, parameter=@mpf.RawMpf::zero()) catch {
    DomainError(_) => ()
    _ => fail("unexpected singular Stieltjes parameter error")
  } noraise {
    _ => fail("expected singular Stieltjes parameter error")
  }
  try ctx.stieltjes_constant(1, parameter=ctx.parse("-2.5")) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected real Stieltjes branch error")
  } noraise {
    _ => fail("expected complex Stieltjes principal value")
  }
}
