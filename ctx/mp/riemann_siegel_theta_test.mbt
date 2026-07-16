///|
test "Riemann-Siegel theta matches high-precision real values" {
  let ctx = MPContext::new(500, Nearest)
  @debug.assert_eq(
    ctx.riemann_siegel_theta(@mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  assert_close_mpf_str(
    ctx.riemann_siegel_theta(ctx.from_int(1)),
    "-1.767547952812290388302216499264387042319483863143786329254287984173409030865514633119277392346657817486287564971123114162572353506262744133345922734512722489900382006972947411",
    "2e-143",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.riemann_siegel_theta(ctx.parse("1e6")),
    "5488816.353078403444882823154365663184115542003316646602974217636210026731292966216811334313948062753637786821666018035214089142110353150495877036651532139877152623722153655844",
    "2e-136",
    comparison_precision=560,
  )
}

///|
test "Riemann-Siegel theta supports complex arguments" {
  let ctx = MPContext::new(500, Nearest)
  let value = ctx.complex_riemann_siegel_theta(
    ctx.complex(ctx.from_int(10), ctx.parse("0.25")),
  )
  assert_close_mpf_str(
    value.real,
    "-3.068638039426838572528866684233254394473505156256732764849388483215984856638716991848021087487345091964304148436300386052843157743482756683376459819952278161293547952904191093",
    "2e-142",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    value.imag,
    "0.05804937947429712998395176702237162413131474179236894888097684207030792885728774781320422301023183545946713191100345888756345486410005004642205577513917230762674881659434829566",
    "2e-143",
    comparison_precision=560,
  )
}

///|
test "Riemann-Siegel theta derivatives are analytic at arbitrary order" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.riemann_siegel_theta(ctx.from_int(1234), order=2),
    "0.0004051864079114053109473741186281262044593268803100748078912381907785995451168122642499240693253396458748066995643736981181673631808626188395800143591589529601524502364971262742",
    "2e-146",
    comparison_precision=560,
  )
  let derivative = ctx.complex_riemann_siegel_theta(
    ctx.complex(ctx.parse("3.25"), ctx.parse("1.5")),
    order=10,
  )
  assert_close_mpf_str(
    derivative.real,
    "-0.1294706026037282184206929720913939914846671468294831702204381803996475710318490818090918245398685006714329504946397521995458117791087820127051228587400044834114140159327063669",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    derivative.imag,
    "1.900071440131496064239366634976062120863862599396866229189512112140138782517043386653285463790891772516867697791104477367256328789591624088503636631544637368765820567167011117",
    "2e-140",
    comparison_precision=560,
  )
}

///|
test "Riemann-Siegel theta parity and special values are explicit" {
  let ctx = MPContext::new(320, Nearest)
  let t = ctx.parse("17.25")
  for order in 0..<=8 {
    let positive = ctx.riemann_siegel_theta(t, order~)
    let negative = ctx.riemann_siegel_theta(t.negated(0, Down), order~)
    let expected = if (order & 1) == 0 {
      positive.negated(320, Nearest)
    } else {
      positive
    }
    assert_close_mpf_str(
      negative.sub(expected, 380, Nearest),
      "0",
      "2e-88",
      comparison_precision=380,
    )
  }
  @debug.assert_eq(
    ctx.riemann_siegel_theta(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.riemann_siegel_theta(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    ctx.riemann_siegel_theta(@mpf.RawMpf::negative_infinity(), order=1),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.riemann_siegel_theta(@mpf.RawMpf::infinity(), order=2),
    @mpf.RawMpf::zero(),
  )
  assert_true(ctx.riemann_siegel_theta(@mpf.RawMpf::nan()).is_nan())
  try ctx.riemann_siegel_theta(t, order=-1) catch {
    DomainError(_) => ()
    _ => fail("unexpected negative theta derivative error")
  } noraise {
    _ => fail("expected negative theta derivative error")
  }
}
