///|
fn assert_elliptic_complex_close(
  z : @mpc.RawMpc,
  expected_real : String,
  expected_imag : String,
  tolerance : String,
) -> Unit raise {
  assert_close_mpf_str(z.real, expected_real, tolerance)
  assert_close_mpf_str(z.imag, expected_imag, tolerance)
}

///|
test "real complete elliptic integrals match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let m = ctx.div(ctx.from_int(1), ctx.pi())
  assert_close_mpf_str(
    ctx.complete_elliptic_first_kind(m),
    "1.724756270009501831744438120951614673874904182624739672909675996853689862655355046397233373480772282550828754974269",
    "2e-106",
  )
  assert_close_mpf_str(
    ctx.complete_elliptic_second_kind(m),
    "1.437129808135123030101542922290970050337425479058225712247998030447628282396488474910489925814751677096259714642224",
    "2e-106",
  )
}

///|
test "real complete elliptic negative parameter matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let m = ctx.mul(ctx.from_int(-10), ctx.pi())
  assert_close_mpf_str(
    ctx.complete_elliptic_first_kind(m),
    "5.519067523886233967683646782286965823151896970015484511591709038100787517482641570595772105096052064755245273588824e-1",
    "2e-107",
  )
  assert_close_mpf_str(
    ctx.complete_elliptic_second_kind(m),
    "5.926192483740483797854383268707108012328213431657645509013041185186570386511417869807955668927951395431868456810181",
    "2e-105",
  )
}

///|
test "complete elliptic first kind near singular parameter retains precision" {
  let ctx = MPContext::new(360, Nearest)
  let delta = @mpf.RawMpf::one().scale_pow2(-300)
  let m = ctx.sub(ctx.from_int(1), delta)
  assert_close_mpf_str(
    ctx.complete_elliptic_first_kind(m),
    "105.3583714451116870314192824616428383474760204227587986263433614429958305393935967720912257162632654891419913",
    "2e-103",
  )
}

///|
test "complete elliptic second kind near singular parameter retains precision" {
  let ctx = MPContext::new(360, Nearest)
  let delta = @mpf.RawMpf::one().scale_pow2(-300)
  let m = ctx.sub(ctx.from_int(1), delta)
  let got = ctx.complete_elliptic_second_kind(m)
  assert_close_mpf_str(
    got, "1.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025737977302147975524732743585864732214714",
    "2e-106",
  )
}

///|
test "complex complete elliptic direct AGM formula matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let m = ctx.complex(ctx.from_int(3), ctx.from_int(4))
  assert_elliptic_complex_close(
    ctx.complex_complete_elliptic_first_kind(m),
    "9.11195563804965008656217106438034242086746218078151518088600858911590577351055818902370691878019662871602756446879e-1",
    "6.313342832413452438845091364251403783581307709797725980700519492244511789010494106497763506804683753722663550670376e-1",
    "2e-106",
  )
  assert_elliptic_complex_close(
    ctx.complex_complete_elliptic_second_kind(m),
    "1.499553520933346954333612224252001055362668975773325405943030331608423074942402650704011235060582976058764242083105",
    "-1.577879007912758274533308928953187534217237563684149724247961404630361895201675605319567498252062850329897474789927",
    "2e-105",
  )
}

///|
test "complex complete elliptic branch at m=2 matches mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let m = ctx.complex(ctx.from_int(2), @mpf.RawMpf::zero())
  assert_elliptic_complex_close(
    ctx.complex_complete_elliptic_first_kind(m),
    "1.311028777146059905232419794945559706841377475715811581408410851900395293535207125115147766480714546723067876335892",
    "-1.311028777146059905232419794945559706841377475715811581408410851900395293535207125115147766480714546723067876335892",
    "2e-105",
  )
  assert_elliptic_complex_close(
    ctx.complex_complete_elliptic_second_kind(m),
    "5.990701173677961037199612461401619391136063316078257791318374764732026070719578354179427782448966946879536125486219e-1",
    "5.990701173677961037199612461401619391136063316078257791318374764732026070719578354179427782448966946879536125486219e-1",
    "2e-106",
  )
}

///|
test "complete elliptic special values and real domain are structured" {
  let ctx = MPContext::new(240, Nearest)
  @debug.assert_eq(
    ctx.complete_elliptic_first_kind(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.complete_elliptic_second_kind(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.complete_elliptic_second_kind(@mpf.RawMpf::one()),
    @mpf.RawMpf::one(),
  )
  assert_true(
    ctx.complete_elliptic_first_kind(@mpf.RawMpf::one()).is_infinite(),
  )
  try ctx.complete_elliptic_first_kind(ctx.from_int(2)) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected complete elliptic real-domain error")
  } noraise {
    _ => fail("expected complex result for real m > 1")
  }
}
