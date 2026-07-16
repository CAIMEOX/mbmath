///|
fn assert_bessel_complex_close(
  z : @mpc.RawMpc,
  expected_real : String,
  expected_imag : String,
  tolerance : String,
) -> Unit raise {
  assert_close_mpf_str(z.real, expected_real, tolerance)
  assert_close_mpf_str(z.imag, expected_imag, tolerance)
}

///|
test "integer-order Bessel first kind small arguments match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.integer_order_bessel_first_kind(5, ctx.from_int(1)),
    "2.497577302112344313750655409880451981583677769800707267489257130594368698272722468253975102394374085407028303111833e-4",
    "2e-111",
  )
  assert_close_mpf_str(
    ctx.integer_order_bessel_first_kind(5, ctx.pi()),
    "5.214118436711847474046012609310219695582172343731313338590597755489178382906934615215664360744748257935300021591242e-2",
    "2e-108",
  )
}

///|
test "integer-order Bessel first kind real asymptotic matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.integer_order_bessel_first_kind(5, ctx.from_int(1000)),
    "5.025406945233186074238836606277190569754680379558718866096462030995823998022458139780673268259673059841690007633759e-3",
    "2e-109",
  )
  assert_close_mpf_str(
    ctx.integer_order_bessel_first_kind(3, ctx.parse("1e10")),
    "7.676508174813920402273118971505631246693050123807000111276518636569348471690871192399319982341709938562317652864516e-6",
    "2e-112",
  )
}

///|
test "integer-order Bessel parity and recurrence semantics hold" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.from_int(2)
  assert_close_mpf_str(
    ctx.integer_order_bessel_first_kind(-3, x),
    "-1.289432494744020510987933329692398352699937252824602338644396087423792007535907749187765195994815601603326901748613e-1",
    "2e-107",
  )
  @debug.assert_eq(
    ctx.integer_order_bessel_first_kind(4, ctx.neg(x)),
    ctx.integer_order_bessel_first_kind(4, x),
  )
  @debug.assert_eq(
    ctx.integer_order_bessel_first_kind(3, ctx.neg(x)),
    ctx.neg(ctx.integer_order_bessel_first_kind(3, x)),
  )
  let j2 = ctx.integer_order_bessel_first_kind(2, x)
  let j3 = ctx.integer_order_bessel_first_kind(3, x)
  let j4 = ctx.integer_order_bessel_first_kind(4, x)
  assert_close_mpf_str(
    ctx.sub(ctx.add(j2, j4), ctx.mul(ctx.from_int(3), j3)),
    "0",
    "2e-107",
  )
}

///|
test "complex integer-order Bessel power-series region matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(3), ctx.from_int(2))
  assert_bessel_complex_close(
    ctx.complex_integer_order_bessel_first_kind(3, z),
    "4.247187949296395959419960081795394834115095024834025044294245094729407480883282193180312886221141691071660999481311e-1",
    "6.256653277457858048121318860733184549589213908372754259387560464366816330034332903454208361203131863423824584605352e-1",
    "2e-106",
  )
}

///|
test "complex integer-order Bessel asymptotic region matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(1000), ctx.from_int(100))
  assert_bessel_complex_close(
    ctx.complex_integer_order_bessel_first_kind(4, z),
    "3.278614872184410060690242392605634160671413724227374167032448457469957188762217627704296783832689833331158966971488e+41",
    "-8.224113580822531097216726679665607356923341663907419338442895593252849223365262049383606617515382298739257785922742e+40",
    "2e-64",
  )
}

///|
test "integer-order Bessel special values are exact" {
  let ctx = MPContext::new(240, Nearest)
  @debug.assert_eq(
    ctx.integer_order_bessel_first_kind(0, @mpf.RawMpf::zero()),
    @mpf.RawMpf::one(),
  )
  @debug.assert_eq(
    ctx.integer_order_bessel_first_kind(5, @mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.integer_order_bessel_first_kind(5, @mpf.RawMpf::infinity()),
    @mpf.RawMpf::zero(),
  )
  assert_true(
    ctx.integer_order_bessel_first_kind(5, @mpf.RawMpf::nan()).is_nan(),
  )
}
