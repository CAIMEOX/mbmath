///|
test "reciprocal trigonometric and hyperbolic functions match mpmath" {
  let ctx = MPContext::new(420, Nearest)
  let x = ctx.parse("0.7")
  assert_close_mpf_str(
    ctx.cot(x),
    "1.18724183212667935367236269369115744209994867903860637492860163613361404397154893601097931851876245712072013605484596326",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.sec(x),
    "1.30745925973359386987467283530531145422836345495872768451212435562075787978030020923520362723104215499716460905539529095",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.csc(x),
    "1.55227032695710391198997364095492783063640855362863882287916237274990074051953835661919443695228098707430225787066697325",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.coth(x),
    "1.6546216358026294047132242808054947293541308324495193407865859457442982267353353803732869492963045171875078062609703725",
    "2e-117",
  )
  assert_close_mpf_str(
    ctx.sech(x),
    "0.796705459992875025211302049182191828842447276362673492310171949208109508172647791035496759468324195662352622256687493892",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.csch(x),
    "1.31824609146629719165164762154575013838024351483228046186417479587436540309703454730697432216178622609348991311363906946",
    "2e-118",
  )
  let singular_functions : Array[(@mpf.RawMpf) -> @mpf.RawMpf raise MPError] = [
    fn(x) raise MPError { ctx.cot(x) },
    fn(x) raise MPError { ctx.csc(x) },
    fn(x) raise MPError { ctx.coth(x) },
    fn(x) raise MPError { ctx.csch(x) },
  ]
  for f in singular_functions {
    try f(@mpf.RawMpf::zero()) catch {
      PoleError(_) => ()
      _ => fail("unexpected reciprocal-function error")
    } noraise {
      _ => fail("expected reciprocal-function pole at zero")
    }
  }
  @debug.assert_eq(ctx.sech(@mpf.RawMpf::infinity()), @mpf.RawMpf::zero())
}

///|
test "inverse reciprocal functions match mpmath real branches" {
  let ctx = MPContext::new(420, Nearest)
  assert_close_mpf_str(
    ctx.acot(ctx.parse("2.5")),
    "0.380506377112364886303587916810433104497405713658100837576305622324200457829003102358863446095872935178034857326425678949",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.asec(ctx.parse("2.5")),
    "1.15927948072740859984658379402241583724288356456052705870352551545381295224783049686589109641899733865431475358572809317",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.acsc(ctx.parse("2.5")),
    "0.411516846067488019384737897617335604855701135127025851783946780700095250895274002448126316252061195336759289670913060153",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.acoth(ctx.parse("2.5")),
    "0.423648930193601806855053753260327012494797085879555868362347908150042784766730150457021371887069719102545832569946637585",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.asech(ctx.parse("0.4")),
    "1.56679923697241107866405686258048349386208235109265886393294599801221481346939226962799684996222011410510391840509363111",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.acsch(ctx.parse("-2.5")),
    "-0.390035319770715276080163379883629644959704738108560111608874252499157095697117008723617343404810375904881626122325601739",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.acot(@mpf.RawMpf::zero()),
    ctx.pi().scale_pow2(-1).format(dps=130),
    "2e-125",
  )
  @debug.assert_eq(ctx.acot(@mpf.RawMpf::infinity()), @mpf.RawMpf::zero())
  try ctx.asec(ctx.parse("0.5")) catch {
    DomainError(_) => ()
    _ => fail("unexpected asec error")
  } noraise {
    _ => fail("expected real asec domain error")
  }
  try ctx.acoth(ctx.parse("0.5")) catch {
    DomainError(_) => ()
    _ => fail("unexpected acoth error")
  } noraise {
    _ => fail("expected real acoth domain error")
  }
  try ctx.acsch(@mpf.RawMpf::zero()) catch {
    PoleError(_) => ()
    _ => fail("unexpected acsch error")
  } noraise {
    _ => fail("expected acsch pole at zero")
  }
}

///|
test "sign argument and arithmetic-geometric mean semantics" {
  let ctx = MPContext::new(420, Nearest)
  @debug.assert_eq(ctx.sign(ctx.from_int(5)), @mpf.RawMpf::one())
  @debug.assert_eq(ctx.sign(ctx.from_int(-5)), @mpf.RawMpf::negative_one())
  @debug.assert_eq(ctx.sign(@mpf.RawMpf::zero()), @mpf.RawMpf::zero())
  assert_true(ctx.sign(@mpf.RawMpf::nan()).is_nan())
  @debug.assert_eq(ctx.arg(ctx.from_int(5)), @mpf.RawMpf::zero())
  assert_close_mpf_str(
    ctx.arg(ctx.from_int(-5)),
    ctx.pi().format(dps=130),
    "2e-125",
  )
  assert_close_mpf_str(
    ctx.agm(ctx.from_int(1), b=ctx.from_int(2)),
    "1.45679103104690686918643238326508197497386394322130559079417238326792645458025090025747371281844844432818940181603679994",
    "2e-118",
  )
  @debug.assert_eq(ctx.agm(ctx.from_int(7), b=ctx.from_int(7)), ctx.from_int(7))
}

///|
test "sinc and sinc_pi preserve removable singularities" {
  let ctx = MPContext::new(420, Nearest)
  let x = ctx.parse("0.7")
  assert_close_mpf_str(
    ctx.sinc(x),
    "0.920310981768130076675163359141028832951162635105270921062804411562614250642393806735180988812511007654718899114667983399",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.sinc_pi(x),
    "0.367883010571774189290903643981725638965883684046724747460118404478826492364985542875098854969229805208710648743039437041",
    "2e-119",
  )
  @debug.assert_eq(ctx.sinc(@mpf.RawMpf::zero()), @mpf.RawMpf::one())
  @debug.assert_eq(ctx.sinc_pi(@mpf.RawMpf::zero()), @mpf.RawMpf::one())
  @debug.assert_eq(ctx.sinc(@mpf.RawMpf::infinity()), @mpf.RawMpf::zero())
  @debug.assert_eq(ctx.sinc_pi(ctx.from_int(3)), @mpf.RawMpf::zero())
}

///|
test "expm1 and pow_minus_one retain cancellation-sensitive bits" {
  let ctx = MPContext::new(440, Nearest)
  assert_close_mpf_str(
    ctx.expm1(ctx.parse("1e-40")),
    "1.0000000000000000000000000000000000000000500000000000000000000000000000000000000016666666666666666666666666666666666666667083333333330399016556737747984457e-40",
    "2e-168",
  )
  let x = ctx.parse("1.000000000000000000000000000001")
  let exponent = ctx.pi()
  let stable = ctx.pow_minus_one(x, exponent)
  assert_close_mpf_str(
    stable, "3.1415926535897932384626433832828668900709191820652917447832441965415053731786078240522263664373141053890262727828845042495045445971364491411534246621424525e-30",
    "2e-160",
  )
  let expected = @mpf.RawMpf::parse(
    "3.1415926535897932384626433832828668900709191820652917447832441965415053731786078240522263664373141053890262727828845042495045445971364491411534246621424525e-30",
    prec=640,
    rnd=Nearest,
  )
  let naive = ctx.pow(x, exponent).sub(@mpf.RawMpf::one(), 440, Nearest)
  let stable_error = stable.sub(expected, 640, Nearest).abs(640, Nearest)
  let naive_error = naive.sub(expected, 640, Nearest).abs(640, Nearest)
  assert_true(stable_error < naive_error)
  @debug.assert_eq(
    ctx.pow_minus_one(ctx.from_int(7), @mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.pow_minus_one(@mpf.RawMpf::one(), ctx.parse("123.5")),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.pow_minus_one(ctx.from_int(-1), ctx.from_int(3)),
    ctx.from_int(-2),
  )
}

///|
test "fixed-base logarithms exponentials and angle conversion match mpmath" {
  let ctx = MPContext::new(420, Nearest)
  assert_close_mpf_str(
    ctx.log10(ctx.from_int(7)),
    "0.845098040014256830712216258592636193483572396323965406503634953718253439902079166066111527847488573341424310075354345586",
    "2e-119",
  )
  assert_close_mpf_str(
    ctx.log2(ctx.from_int(7)),
    "2.80735492205760410744196931723183080864102662596614078367729172407032084886219298649786099917021078510736050188932557305",
    "2e-118",
  )
  assert_close_mpf_str(
    ctx.exp2(ctx.parse("0.7")),
    "1.62450479271247104521941876555056330257040994886431888506498742610844148687002977124947225963205765490671067155184647231",
    "2e-118",
  )
  let pi_over_seven = ctx.div(ctx.pi(), ctx.from_int(7))
  assert_close_mpf_str(
    ctx.to_degrees(pi_over_seven),
    "25.7142857142857142857142857142857142857142857142857142857142857142857142857142857142857142857142857142857142857142857143",
    "2e-117",
  )
  assert_close_mpf_str(
    ctx.to_radians(ctx.parse("180.5")),
    "3.15031929984976488634726183712194594776438375881781444825543054950867145185922624584644603319028961539320960897581920194",
    "2e-118",
  )
}

///|
test "context modulo follows divisor-sign floor semantics" {
  let ctx = MPContext::new(240, Nearest)
  @debug.assert_eq(
    ctx.modulo(ctx.parse("-5.5"), ctx.from_int(2)),
    ctx.parse("0.5"),
  )
  @debug.assert_eq(
    ctx.modulo(ctx.parse("5.5"), ctx.from_int(-2)),
    ctx.parse("-0.5"),
  )
  try ctx.modulo(ctx.from_int(1), @mpf.RawMpf::zero()) catch {
    PoleError(_) => ()
    _ => fail("unexpected modulo error")
  } noraise {
    _ => fail("expected modulo-by-zero pole")
  }
}
