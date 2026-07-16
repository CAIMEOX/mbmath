///|
test "hyperfactorial exact integer continuations match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let positive = ["1", "1", "4", "108", "27648", "86400000", "4031078400000"]
  let negative = ["1", "1", "-1", "-4", "108", "27648", "-86400000"]
  for i, expected in positive {
    @debug.assert_eq(ctx.hyperfactorial(ctx.from_int(i)), ctx.parse(expected))
  }
  for i, expected in negative {
    @debug.assert_eq(ctx.hyperfactorial(ctx.from_int(-i)), ctx.parse(expected))
  }
  @debug.assert_eq(
    ctx.hyperfactorial(ctx.from_int(-100)),
    ctx.hyperfactorial(ctx.from_int(99)),
  )
  @debug.assert_eq(
    ctx.hyperfactorial(ctx.from_int(-102)),
    ctx.hyperfactorial(ctx.from_int(101)).negated(360, Nearest),
  )
}

///|
test "hyperfactorial special values follow mpmath" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.hyperfactorial(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  assert_true(ctx.hyperfactorial(@mpf.RawMpf::negative_infinity()).is_nan())
  assert_true(ctx.hyperfactorial(@mpf.RawMpf::nan()).is_nan())
}

///|
test "real hyperfactorial continuation matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.hyperfactorial(ctx.parse("0.5")),
    "0.880449235173423393279243584189658184660740530867665991255211617811351301126631448186068952466089680564135837019313948514",
    "2e-105",
  )
  assert_close_mpf_str(
    ctx.hyperfactorial(ctx.pi()),
    "205.211134637461803275999657196666535068524692451522172009076586894233910383689464938566249342382019303483772007577466989",
    "2e-103",
  )
}

///|
test "complex hyperfactorial continuation matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let value = ctx.complex_hyperfactorial(
    ctx.complex(ctx.parse("0.5"), @mpf.RawMpf::one()),
  )
  assert_barnes_complex_close(
    value, "0.499852109524165836752626703072790721944070229738596690795740941914280461262401492092764459542298171705924250809603508583",
    "-0.0938285479099708386059252119109965162948894058764873870004916021476286387434853181538386802396045307408311710319896051013",
    "2e-105",
  )
}

///|
test "real hyperfactorial rejects genuinely complex principal values" {
  let ctx = MPContext::new(360, Nearest)
  try ctx.hyperfactorial(ctx.parse("-1.5")) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected hyperfactorial real-domain error")
  } noraise {
    _ => fail("expected a complex hyperfactorial principal value")
  }
  let value = ctx.complex_hyperfactorial(
    ctx.complex(ctx.parse("-1.5"), @mpf.RawMpf::zero()),
  )
  assert_barnes_complex_close(
    value, "0", "0.880449235173423393279243584189658184660740530867665991255211617811351301126631448186068952466089680564135837019313948514",
    "2e-105",
  )
}

///|
test "real hyperfactorial retains removable real branch values" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.hyperfactorial(ctx.parse("-2.5")),
    "1.617488527948946062817035460231792759011605096464772908818546713291186141793317912937174351778145452429193283065234491",
    "2e-104",
  )
  @debug.assert_eq(
    ctx.complex_hyperfactorial(
      ctx.complex(ctx.from_int(-3), @mpf.RawMpf::zero()),
    ),
    ctx.complex(ctx.from_int(-4), @mpf.RawMpf::zero()),
  )
}

///|
test "complex hyperfactorial satisfies its principal recurrence" {
  let ctx = MPContext::new(360, Nearest)
  let p = 420
  let z = ctx.complex(ctx.parse("1.25"), ctx.parse("-0.75"))
  let lhs = ctx.complex_hyperfactorial(z)
  let rhs = z
    .pow(z, p, Nearest)
    .mul(
      ctx.complex_hyperfactorial(z.sub_real(@mpf.RawMpf::one(), p, Nearest)),
      p,
      Nearest,
    )
  assert_barnes_complex_close(lhs.sub(rhs, p, Nearest), "0", "0", "2e-104")
}

///|
test "large hyperfactorial keeps full requested precision" {
  let ctx = MPContext::new(400, Nearest)
  let value = ctx.hyperfactorial(ctx.from_int(1000))
  assert_close_mpf_str(
    ctx.ln(value),
    "3207332.34153131126573738819724911253938195809866321890202048823900477903233628129882158630977422336668831278670004784197",
    "2e-108",
  )
}
