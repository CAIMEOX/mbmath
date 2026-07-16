///|
fn assert_gamma_ratio_complex_close(
  z : @mpc.RawMpc,
  expected_real : String,
  expected_imag : String,
  tolerance : String,
) -> Unit raise {
  assert_close_mpf_str(z.real, expected_real, tolerance)
  assert_close_mpf_str(z.imag, expected_imag, tolerance)
}

///|
test "gamma product cancels nonpositive-integer poles" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.gamma_product([ctx.from_int(-1)], [ctx.from_int(-3), ctx.from_int(-4)]),
    @mpf.RawMpf::zero(),
  )
  assert_true(
    ctx
    .gamma_product([ctx.from_int(-1), ctx.from_int(0)], [ctx.from_int(-5)])
    .is_infinite(),
  )
  @debug.assert_eq(
    ctx.gamma_product([ctx.from_int(-1)], [ctx.from_int(-2)]),
    ctx.from_int(-2),
  )
  assert_close_mpf_str(
    ctx.gamma_product([ctx.from_int(-4), ctx.from_int(-3)], [
      ctx.from_int(-2),
      ctx.from_int(0),
    ]),
    "-0.0138888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888889",
    "2e-108",
  )
}

///|
test "real beta function pole and high-precision semantics match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.beta_function(ctx.parse("1.5"), ctx.parse("2.5")),
    "0.19634954084936207740391521145496893026232308746094411381093403701923852539288806241425217658388231674888425540708014416544337",
    "2e-107",
  )
  assert_close_mpf_str(
    ctx.beta_function(ctx.from_int(-3), ctx.from_int(3)),
    "-0.333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
    "2e-108",
  )
  assert_close_mpf_str(
    ctx.beta_function(
      ctx.parse("-255.5815971722918"),
      ctx.parse("-0.5119253100282322"),
    ),
    "1.815733056270501592674128868687211585312747670862502610312282137646261140408960989952000176349408040050963363866531e+1",
    "2e-104",
  )
}

///|
test "real binomial coefficient continuation matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.binomial_coefficient(ctx.from_int(-2), ctx.from_int(-4)),
    ctx.from_int(3),
  )
  @debug.assert_eq(
    ctx.binomial_coefficient(ctx.from_int(1100), ctx.from_int(2)),
    ctx.from_int(604450),
  )
  @debug.assert_eq(
    ctx.binomial_coefficient(ctx.parse("4.5"), ctx.parse("1.5")),
    ctx.parse("6.5625"),
  )
  @debug.assert_eq(
    ctx.binomial_coefficient(ctx.from_int(0), ctx.from_int(-1)),
    @mpf.RawMpf::zero(),
  )
}

///|
test "real rising and falling factorial continuations match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.rising_factorial(ctx.from_int(-5), ctx.from_int(2)),
    ctx.from_int(20),
  )
  @debug.assert_eq(
    ctx.falling_factorial(ctx.from_int(4), ctx.from_int(3)),
    ctx.from_int(24),
  )
  @debug.assert_eq(
    ctx.falling_factorial(ctx.from_int(3), ctx.from_int(4)),
    @mpf.RawMpf::zero(),
  )
  assert_close_mpf_str(
    ctx.rising_factorial(
      ctx.parse("-255.5815971722918"),
      ctx.parse("-0.5119253100282322"),
    ),
    "-1.952720278805589081605068045186050908490812888971934071063809238006690823066296284320664305514517504340665288117033e-1",
    "2e-106",
  )
}

///|
test "real double factorial exact sequence and continuation match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let expected = [1, 1, 2, 3, 8, 15, 48, 105, 384, 945]
  for i, value in expected {
    @debug.assert_eq(ctx.double_factorial(ctx.from_int(i)), ctx.from_int(value))
  }
  assert_close_mpf_str(
    ctx.double_factorial(ctx.from_int(-5)),
    "0.333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333",
    "2e-108",
  )
  assert_close_mpf_str(
    ctx.double_factorial(ctx.from_int(-11)),
    "-0.0010582010582010582010582010582010582010582010582010582010582010582010582010582010582010582010582010582010582010582",
    "2e-110",
  )
}

///|
test "complex beta and binomial continuations match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.complex(ctx.from_int(1), ctx.from_int(2))
  let y = ctx.complex(ctx.from_int(-1), ctx.parse("-0.5"))
  assert_gamma_ratio_complex_close(
    ctx.complex_beta_function(x, y),
    "1.163965424510699430864681275874404968526468001894027429069973473670314976679241492192365873337469186361377137332699",
    "8.511695947832914640450357170579713452428483212456166432994666887791545659749051752278669591088400511332777743166881e-2",
    "2e-105",
  )
  let k = ctx.complex(ctx.parse("0.5"), ctx.from_int(-1))
  let n = ctx.complex(ctx.from_int(2), ctx.from_int(3))
  assert_gamma_ratio_complex_close(
    ctx.complex_binomial_coefficient(n, k),
    "6.75944978874906423963773349218677676299474245579660081345052766809621279018258745366831612970384832502222240373197",
    "-6.643782976086997482135491143975726981389701582816658742518010890729618998098117911849686711789220422689511370506957",
    "2e-104",
  )
}

///|
test "complex rising falling and double factorials match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.complex(ctx.from_int(1), ctx.from_int(2))
  let n = ctx.complex(ctx.parse("0.5"), ctx.from_int(-1))
  assert_gamma_ratio_complex_close(
    ctx.complex_rising_factorial(x, n),
    "3.798502428505536786057307176501202733283196284896987478231612162689858772123564927336251118795226416577433749011649",
    "8.546050087452606108850817917103892310006484833129316739495226922910060953084181954440503732304258696015536815463587e-2",
    "2e-104",
  )
  assert_gamma_ratio_complex_close(
    ctx.complex_falling_factorial(x, n),
    "4.439550504666006306192397166284531789730200233839493378506892937180115864573050159447207927705025184902612160671973",
    "-2.303788994434413883414672404414275607504730486489593482321382264282516424537480268572174785277925825780535892066278",
    "2e-104",
  )
  let z = ctx.complex(ctx.parse("0.5"), ctx.parse("0.75"))
  assert_gamma_ratio_complex_close(
    ctx.complex_double_factorial(z),
    "8.154676939468806917631583808290528118617578700396179986077786156519361415029422322047693108957802999631474416585702e-1",
    "-3.490101608557326688886030151716608695444647399056400056409095517796608381817867625584528931603386243040740266596881e-1",
    "2e-105",
  )
}
