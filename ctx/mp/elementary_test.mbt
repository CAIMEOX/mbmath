///|
test "context mathematical constants match mpmath" {
  let ctx = MPContext::new(300, Nearest)
  assert_close_mpf_str(
    ctx.pi(),
    "3.1415926535897932384626433832795028841971693993751058209749445923",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.e(),
    "2.7182818284590452353602874713526624977572470936999595749669676277",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.ln2(),
    "0.69314718055994530941723212145817656807550013436025525412068000949",
    "2e-65",
  )
  assert_close_mpf_str(
    ctx.ln10(),
    "2.302585092994045684017991454684364207601101488628772976033327901",
    "2e-63",
  )
  assert_close_mpf_str(
    ctx.sqrt_pi(),
    "1.7724538509055160272981674833411451827975494561223871282138077899",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.ln_sqrt_2pi(),
    "0.91893853320467274178032973640561763986139747363778341281715154048",
    "2e-65",
  )
  assert_close_mpf_str(
    ctx.golden_ratio(),
    "1.6180339887498948482045868343656381177203091798057628621354486227",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.degree(),
    "0.017453292519943295769236907684886127134428718885417254560971914402",
    "2e-66",
  )
}

///|
test "context logarithm family preserves small increments" {
  let ctx = MPContext::new(400, Nearest)
  assert_close_mpf_str(
    ctx.log(ctx.parse("2.5")),
    "0.9162907318741550651835272117680110714501012199082624677919678819807853657379630490242705510967609232579648220011448771660384849935665456426",
    "2e-63",
  )
  assert_close_mpf_str(
    ctx.log(ctx.from_int(1000), base=ctx.from_int(10)),
    "3",
    "1e-90",
  )
  assert_close_mpf_str(
    ctx.log1p(ctx.parse("1e-40")),
    "9.999999999999999999999999999999999999999500000000000000000000000000000000000000033333333333333333333333333333333333e-41",
    "2e-153",
  )
  @debug.assert_eq(
    ctx.log1p(ctx.from_int(-1)),
    @mpf.RawMpf::negative_infinity(),
  )
  try ctx.log(ctx.from_int(2), base=ctx.from_int(1)) catch {
    PoleError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected logarithm base-one pole")
  }
  try ctx.log1p(ctx.parse("-1.0001")) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected log1p domain error")
  }
}

///|
test "context atan and atan2 preserve quadrants and infinities" {
  let ctx = MPContext::new(320, Nearest)
  assert_close_mpf_str(
    ctx.atan(ctx.from_int(2)),
    "1.1071487177940905030170654601785370400700476454014326466765392074",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.atan2(ctx.from_int(-3), ctx.from_int(-4)),
    "-2.4980915447965088516598341545621802461556588082597934381093384736",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.atan(@mpf.RawMpf::infinity()),
    ctx.pi().scale_pow2(-1).format(dps=80),
    "2e-79",
  )
  assert_close_mpf_str(
    ctx.atan(@mpf.RawMpf::negative_infinity()),
    ctx.pi().scale_pow2(-1).negated(320, Nearest).format(dps=80),
    "2e-79",
  )
}

///|
test "context hyperbolic functions match mpmath and special values" {
  let ctx = MPContext::new(300, Nearest)
  let x = ctx.parse("1.25")
  assert_close_mpf_str(
    ctx.sinh(x),
    "1.6019190803008256379028303015122139399292918032170502877056572636",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.cosh(x),
    "1.8884238771610157382277157281600515427224425955453013347940394748",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.tanh(x),
    "0.84828363995751289761338764670750445373857592067843152232734528304",
    "2e-65",
  )
  @debug.assert_eq(
    ctx.sinh(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    ctx.cosh(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(ctx.tanh(@mpf.RawMpf::infinity()), @mpf.RawMpf::one())
  @debug.assert_eq(
    ctx.tanh(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::negative_one(),
  )
}

///|
test "context inverse elementary functions match real-domain mpmath values" {
  let ctx = MPContext::new(300, Nearest)
  let x = ctx.parse("0.75")
  assert_close_mpf_str(
    ctx.asin(x),
    "0.84806207898148100805294433899841808007336621326311264286071816357",
    "2e-65",
  )
  assert_close_mpf_str(
    ctx.acos(x),
    "0.72273424781341561117837735264133336202521848642444026762675413258",
    "2e-65",
  )
  assert_close_mpf_str(
    ctx.asinh(ctx.parse("-3.5")),
    "-1.9657204716496515212387563486700693022836993884072531003123027424",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.acosh(ctx.parse("3.5")),
    "1.9248473002384137899910356536974736925407373375426420786440726754",
    "2e-64",
  )
  assert_close_mpf_str(
    ctx.atanh(x),
    "0.97295507452765665255267637172158986481854236479093059422969507497",
    "2e-65",
  )
  @debug.assert_eq(ctx.atanh(@mpf.RawMpf::one()), @mpf.RawMpf::infinity())
  @debug.assert_eq(
    ctx.atanh(@mpf.RawMpf::negative_one()),
    @mpf.RawMpf::negative_infinity(),
  )
  try ctx.asin(ctx.parse("1.0001")) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected asin real-domain error")
  }
  try ctx.acosh(ctx.parse("0.9999")) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected acosh real-domain error")
  }
  try ctx.atanh(ctx.parse("1.0001")) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected atanh real-domain error")
  }
}

///|
test "context real powers and roots have explicit branch semantics" {
  let ctx = MPContext::new(420, Nearest)
  assert_close_mpf_str(
    ctx.pow(ctx.parse("2.5"), ctx.parse("3.25")),
    "19.64739733879586575496508601029465372306200568773259529276958363777780631688253788016306097316707207527092190707652",
    "2e-113",
  )
  @debug.assert_eq(ctx.nthroot(ctx.from_int(-32), 5), ctx.from_int(-2))
  assert_close_mpf_str(
    ctx.cbrt(ctx.from_int(-7)),
    "-1.912931182772389101199116839548760282862439050345875766210647640447234276179230756007525441477285709904541913958791",
    "2e-113",
  )
  try ctx.pow(ctx.from_int(-2), ctx.parse("0.5")) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected real power branch error")
  }
  try ctx.nthroot(ctx.from_int(-2), 4) catch {
    DomainError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected even-root domain error")
  }
  try ctx.nthroot(ctx.from_int(2), 0) catch {
    ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected zero-root-index error")
  }
}

///|
test "context pi-scaled pairs and hypot helpers share one rounding context" {
  let ctx = MPContext::new(300, Nearest)
  let x = ctx.parse("0.125")
  let (c, s) = ctx.cos_sin_pi(x)
  assert_close_mpf_str(
    s, "0.38268343236508977172845998403039886676134456248562704143380063563", "2e-65",
  )
  assert_close_mpf_str(
    c, "0.92387953251128675612818318939678828682241662586364248611509773128", "2e-65",
  )
  @debug.assert_eq(ctx.sin_pi(ctx.from_int(7)), @mpf.RawMpf::zero())
  @debug.assert_eq(ctx.cos_pi(ctx.from_int(7)), @mpf.RawMpf::negative_one())
  let (c0, s0) = ctx.cos_sin(ctx.from_int(0))
  @debug.assert_eq(c0, @mpf.RawMpf::one())
  @debug.assert_eq(s0, @mpf.RawMpf::zero())
  let (ch, sh) = ctx.cosh_sinh(ctx.parse("1.25"))
  @debug.assert_eq(ch, ctx.cosh(ctx.parse("1.25")))
  @debug.assert_eq(sh, ctx.sinh(ctx.parse("1.25")))
  @debug.assert_eq(ctx.hypot(ctx.from_int(3), ctx.from_int(4)), ctx.from_int(5))
  assert_close_mpf_str(
    ctx.log_hypot(ctx.from_int(3), ctx.from_int(4)),
    "1.6094379124341003746007593332261876395256013542685177219126478915",
    "2e-64",
  )
}
