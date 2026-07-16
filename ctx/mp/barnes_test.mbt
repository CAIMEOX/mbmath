///|
fn assert_barnes_complex_close(
  z : @mpc.RawMpc,
  expected_real : String,
  expected_imag : String,
  tolerance : String,
) -> Unit raise {
  assert_close_mpf_str(z.real, expected_real, tolerance)
  assert_close_mpf_str(z.imag, expected_imag, tolerance)
}

///|
test "Barnes G special values are exact" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(ctx.barnes_g_function(ctx.from_int(0)), @mpf.RawMpf::zero())
  @debug.assert_eq(ctx.barnes_g_function(ctx.from_int(-1)), @mpf.RawMpf::zero())
  @debug.assert_eq(ctx.barnes_g_function(ctx.from_int(1)), @mpf.RawMpf::one())
  @debug.assert_eq(ctx.barnes_g_function(ctx.from_int(2)), @mpf.RawMpf::one())
  @debug.assert_eq(
    ctx.barnes_g_function(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  assert_true(ctx.barnes_g_function(@mpf.RawMpf::nan()).is_nan())
}

///|
test "real Barnes G continuation matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.barnes_g_function(ctx.parse("0.7")),
    "8.06872273014147209042389534708777364443521134923661123087892031498445029682711104929355873201932299733210716854655881421e-1",
    "2e-106",
  )
  assert_close_mpf_str(
    ctx.barnes_g_function(ctx.parse("-0.5")),
    "-1.70172069896561519165011910835339321595436344345435875065658171931480516779548448202993610477561525582204467263006261822e-1",
    "2e-106",
  )
  assert_close_mpf_str(
    ctx.barnes_g_function(ctx.from_int(100)),
    "3.10361006263698308478794026681017694022806118824924812043389034142517391098463197341176406216517538009963855217484708613e+6626",
    "2e6521",
  )
}

///|
test "complex Barnes G principal continuation matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(2), ctx.from_int(3))
  assert_barnes_complex_close(
    ctx.complex_barnes_g_function(z),
    "-1.78102138640821696064189039568597003121062793548170604128768935354481127198206536700652866082745883849667462654874522837e-1",
    "4.50454271544783790912058152329862576331491171050253791243988740873744496032824898732442294186429483708801228983223088102e-2",
    "2e-105",
  )
}

///|
test "Barnes G functional equation holds at high precision" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.parse("1.25"), ctx.parse("-0.75"))
  let lhs = ctx.complex_barnes_g_function(
    z.add_real(@mpf.RawMpf::one(), 400, Nearest),
  )
  let rhs = ctx
    .complex_gamma(z)
    .mul(ctx.complex_barnes_g_function(z), 400, Nearest)
  assert_barnes_complex_close(lhs.sub(rhs, 400, Nearest), "0", "0", "2e-104")
}

///|
test "superfactorial exact integer sequence matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let expected = [
    "1", "1", "2", "12", "288", "34560", "24883200", "125411328000",
  ]
  for i, value in expected {
    @debug.assert_eq(ctx.superfactorial(ctx.from_int(i)), ctx.parse(value))
  }
  @debug.assert_eq(
    ctx.superfactorial(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
}

///|
test "complex superfactorial matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.parse("0.5"), ctx.from_int(1))
  assert_barnes_complex_close(
    ctx.complex_superfactorial(z),
    "7.43798312514264120347513904956333862351706943865466832548033053791007480812908411736618046571139390941672966650418516141e-1",
    "-9.53167849394723869314495881160107114847885664289853900490719529766518297806419454047763119279093187609219427119319992724e-2",
    "2e-105",
  )
}

///|
test "Barnes G reflection handles a large negative real argument" {
  let ctx = MPContext::new(400, Nearest)
  let value = ctx.barnes_g_function(ctx.parse("-10000.5"))
  assert_true(value.sign == 1)
  assert_close_mpf_str(
    ctx.ln(ctx.abs(value)),
    "385637924.8809024625311343226058475553695070325236869228411912452664808255991443807582326784260752946754501017295693",
    "2e-106",
  )
}

///|
test "Barnes G reflection is branch-consistent in the far left plane" {
  let ctx = MPContext::new(400, Nearest)
  let value = ctx.complex_barnes_g_function(
    ctx.complex(ctx.from_int(-1000), ctx.from_int(1000)),
  )
  assert_close_mpf_str(
    ctx.ln(value.abs(440, Nearest)),
    "2363888.013337613332190381600213785919665423311322098048083724954147148693650301446289639259509083892569349566581974",
    "2e-105",
  )
  assert_close_mpf_str(
    value.arg(440, Nearest),
    "0.7463912778378030980717574250940050004622350994325328344405524458809276061120320203310294573497326462841810893986063",
    "2e-111",
  )
}
