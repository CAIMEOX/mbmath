///|
test "real Hurwitz zeta matches high-precision mpmath" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.hurwitz_zeta(ctx.parse("2.75"), ctx.parse("1.25")),
    "0.74377746747640716366326645817989070746566437494109025057240590686908397976708304880127147978182509928093338399469842582545424103314962017738527316035276057525069415932661",
    "2e-143",
    comparison_precision=560,
  )
  @debug.assert_eq(
    ctx.hurwitz_zeta(@mpf.RawMpf::zero(), ctx.parse("1.25")),
    ctx.parse("-0.75"),
  )
}

///|
test "complex Hurwitz zeta matches mpmath for shifted sums" {
  let ctx = MPContext::new(500, Nearest)
  let value = ctx.complex_hurwitz_zeta(
    ctx.complex(ctx.from_int(-2), ctx.from_int(3)),
    ctx.complex(ctx.from_int(5), @mpf.RawMpf::zero()),
  )
  assert_close_mpf_str(
    value.real,
    "18.384866151867576926870490714701632581761438995622674005849939973014181168490047183328172516162861356322478392243349600191581504003181000178885314343089150874249595618613",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    value.imag,
    "-11.377015110597711008687768388566825663665992756380775480915274106553878246463596068085413460186953046212715839466608904933043307693938913396100604255457855133212418676135",
    "2e-141",
    comparison_precision=560,
  )
}

///|
test "complex Hurwitz zeta supports complex and negative-real parameters" {
  let ctx = MPContext::new(500, Nearest)
  let complex_value = ctx.complex_hurwitz_zeta(
    ctx.complex(ctx.parse("0.25"), ctx.from_int(3)),
    ctx.complex(ctx.parse("1.5"), ctx.parse("0.5")),
  )
  assert_close_mpf_str(
    complex_value.real,
    "-0.69634841671305420162088198321942401313329742272730202464231703130969212218018750267309811605297442047978159196369014586301313601311953005763152629495312744356361348845679",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    complex_value.imag,
    "-1.5208967678310923325797837482444523044026858020236235300742175464365372593409047750869697368905178444668224513937041852798697827643353536175690439602533959562143733945952",
    "2e-141",
    comparison_precision=560,
  )
  let negative_parameter = ctx.complex_hurwitz_zeta(
    ctx.complex(ctx.parse("0.5"), @mpf.RawMpf::zero()),
    ctx.complex(ctx.parse("-2.5"), @mpf.RawMpf::zero()),
  )
  assert_close_mpf_str(
    negative_parameter.real,
    "-0.60489864342163037024726591423595549975976254513024738037854664808218725349506035732740395691834955438303372041033582405310982522329916350483489701320500006173907273296787",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    negative_parameter.imag,
    "-2.8631656753344969479338954579982055826355653967942148146924115642995714920090596919658569670383817100453481701370183710962542290818874323294574867335190594630251779132059",
    "2e-141",
    comparison_precision=560,
  )
}

///|
test "Hurwitz zeta branch and parameter errors are explicit" {
  let ctx = MPContext::new(320, Nearest)
  assert_close_mpf_str(
    ctx.hurwitz_zeta(ctx.from_int(2), ctx.parse("-2.5")),
    "9.5392466449891237538616899443825200121012941480648397576511191325544668556540470659453311463037205603564574013314560164833306185054594678082497532834370432749396443725477",
    "2e-88",
    comparison_precision=380,
  )
  try ctx.hurwitz_zeta(ctx.parse("0.5"), ctx.parse("-2.5")) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected Hurwitz complex-result error")
  } noraise {
    _ => fail("expected complex Hurwitz principal value")
  }
  try ctx.hurwitz_zeta(ctx.from_int(2), ctx.from_int(-3)) catch {
    DomainError(_) => ()
    _ => fail("unexpected Hurwitz parameter error")
  } noraise {
    _ => fail("expected negative-integer Hurwitz parameter error")
  }
}
