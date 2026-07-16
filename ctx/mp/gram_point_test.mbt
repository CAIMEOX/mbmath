///|
test "Gram points match high-precision real reference values" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.gram_point(ctx.from_int(-1)),
    "9.666908056130192141261535523102232213031142486442142986903453044334597207232690144470235675455258496963133749706154888219152253172746631190087441160990115936251048938301896445",
    "2e-142",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.gram_point(@mpf.RawMpf::zero()),
    "17.84559954041086081682633841251909703569328743369645239211811485948168700920160952117513404084882086763814962712287891926362941825911666107468922469097018531048997123196689559",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.gram_point(ctx.parse("0.5")),
    "20.65404496936791945292401584920517381065830425373430367259526823645915758744652514191060592126020221951933329490669781287753264930651036072922371343911148274308118152494797598",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.gram_point(ctx.from_int(3)),
    "31.71797995476405317955148690451646446415214307558673494959346121323725405695908241363218945211011029515261174513396225578442001606451203373803920488293847996026353181336393966",
    "2e-141",
    comparison_precision=560,
  )
}

///|
test "Gram points remain accurate for huge indices" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.gram_point(ctx.parse("1e10")),
    "3293531632.728335454561152680080330634320132998027068997741513110171269350960227721843838821380916438367346682310714566803131251394588332123149100399510194267386309069875803753",
    "2e-132",
    comparison_precision=560,
  )
}

///|
test "negative Gram indices preserve complex principal roots" {
  let ctx = MPContext::new(500, Nearest)
  let value = ctx.complex_gram_point(
    ctx.complex(ctx.from_int(-2), @mpf.RawMpf::zero()),
  )
  assert_close_mpf_str(
    value.real,
    "4.510594140699146544847834180429654096956353735067324002220078314947074096641620785302528184478129128016770885514955591662599808579754627942923751532263257347066959255394788735",
    "2e-142",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    value.imag,
    "8.490914533614919806499375521697686597182143524695285063678199456625416003531118540462064959484684503355618042611466222291136913404841998651941925750508923089498197892030929622",
    "2e-142",
    comparison_precision=560,
  )
  try ctx.gram_point(ctx.from_int(-2)) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected real Gram-point branch error")
  } noraise {
    _ => fail("expected a complex Gram point")
  }
}

///|
test "Gram points satisfy their defining equation and special semantics" {
  let ctx = MPContext::new(420, Nearest)
  let index = ctx.parse("123.75")
  let point = ctx.gram_point(index)
  let residual = ctx
    .riemann_siegel_theta(point)
    .sub(ctx.pi().mul(index, 480, Nearest), 480, Nearest)
  assert_close_mpf_str(residual, "0", "2e-117", comparison_precision=480)
  @debug.assert_eq(
    ctx.gram_point(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  assert_true(ctx.gram_point(@mpf.RawMpf::nan()).is_nan())
  let complex_nan = ctx.complex_gram_point(
    ctx.complex(@mpf.RawMpf::zero(), @mpf.RawMpf::infinity()),
  )
  assert_true(complex_nan.real.is_nan() && complex_nan.imag.is_nan())
}
