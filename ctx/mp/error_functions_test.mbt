///|
fn assert_error_complex_close(
  z : @mpc.RawMpc,
  expected_real : String,
  expected_imag : String,
  tolerance : String,
) -> Unit raise {
  assert_close_mpf_str(z.real, expected_real, tolerance)
  assert_close_mpf_str(z.imag, expected_imag, tolerance)
}

///|
test "real error functions match high-precision mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.parse("1.25")
  let value = ctx.error_function(x)
  let complement = ctx.complementary_error_function(x)
  assert_close_mpf_str(
    value, "0.9229001282564582301365234811972811404236014387022283297936684875922200565312010874754980022358767231517113184563043",
    "2e-107",
  )
  assert_close_mpf_str(
    complement, "0.0770998717435417698634765188027188595763985612977716702063315124077799434687989125245019977641232768482886815436957",
    "2e-107",
  )
  assert_close_mpf_str(value.add(complement, 400, Nearest), "1", "2e-107")
}

///|
test "complementary error function preserves exponentially small tails" {
  let ctx = MPContext::new(360, Nearest)
  assert_close_mpf_str(
    ctx.complementary_error_function(ctx.from_int(10)),
    "2.088487583762544757000786294957788611560818119321163727012213713938174695833440290610766384285723553981525939236524e-45",
    "2e-150",
  )
  assert_close_mpf_str(
    ctx.complementary_error_function(ctx.from_int(50)),
    "2.070920778841656048448447875165788792932250920995399683766235533759898169425138823932117129971001442897950762593296e-1088",
    "2e-1193",
  )
  @debug.assert_eq(
    ctx.complementary_error_function(ctx.from_int(10000)),
    @mpf.RawMpf::from_mantissa_exponent(
      2041187850835801574549624595709547792115444600375685101606231807289607740015928765151997411143370117883842407N,
      -144269878,
      0,
      Down,
    ),
  )
  @debug.assert_eq(
    ctx.complementary_error_function(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.complementary_error_function(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::two(),
  )
}

///|
test "complex error function power-series region matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(3), ctx.from_int(4))
  assert_error_complex_close(
    ctx.complex_error_function(z),
    "-120.1869913950794440981449593575874867137497025048443203042891956515810123359078443709414420304206593757782517479014",
    "-27.75033729362390249813368160608139592833027636970527147367763605904342309669483698826378807314671685775689633362349",
    "2e-103",
  )
}

///|
test "complex error function survives severe cancellation" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(8), ctx.from_int(9))
  assert_error_complex_close(
    ctx.complex_error_function(z),
    "-1072004.252506205115798369340946410386717948576569894315304749796697616459128933277907860209237930761803927372440707",
    "364149.9195431025542308993623809169260587849858032911319035690340055949967542613428294765601138421786058148461616161",
    "2e-96",
  )
}

///|
test "complex complementary error asymptotic region matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.from_int(100), ctx.from_int(100))
  assert_error_complex_close(
    ctx.complex_complementary_error_function(z),
    "0.0006523436637685769869806097434306819977630054469939969780155607244219017971042113932290901006231201756364196564828574",
    "-0.003935726362921411843732434425093783015716715816945416892272061219438583204832995202525494076958735547662051340866817",
    "2e-108",
  )
  let imaginary_axis = ctx.complex(@mpf.RawMpf::zero(), ctx.from_int(50))
  let imaginary_tail = ctx.complex_complementary_error_function(imaginary_axis)
  @debug.assert_eq(imaginary_tail.real, @mpf.RawMpf::one())
  assert_close_mpf_str(
    imaginary_tail.imag,
    "-6.148182066605307873650573389667403148553872525953362890375206613034894009022638534280453484516210564937689429871783e+1083",
    "2e978",
  )
}

///|
test "imaginary error function and symmetry semantics match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.div(ctx.from_int(1), ctx.pi())
  assert_close_mpf_str(
    ctx.imaginary_error_function(x),
    "0.371682698493894314084054008084387758979614377410858951848868983473904184223818952645771241246657261984711239220861",
    "2e-107",
  )
  let z = ctx.complex(ctx.parse("0.2"), ctx.parse("0.5"))
  let erf_z = ctx.complex_error_function(z)
  let erfc_z = ctx.complex_complementary_error_function(z)
  assert_error_complex_close(
    erf_z.add(erfc_z, 400, Nearest),
    "1",
    "0",
    "2e-107",
  )
  @debug.assert_eq(
    ctx.error_function(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::one(),
  )
  @debug.assert_eq(
    ctx.error_function(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::negative_one(),
  )
}
