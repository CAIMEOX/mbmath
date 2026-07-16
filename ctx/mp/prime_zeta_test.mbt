///|
test "real prime zeta matches high-precision mpmath" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.prime_zeta(ctx.from_int(4)),
    "0.0769931397642468449426192959331578701620410597148431902649380088592165704875642065103331067853962895420291064188287288728654003973024769057459215026566097256010641406105884328411023",
    "2e-145",
    comparison_precision=560,
  )
}

///|
test "complex prime zeta continues real arguments below one" {
  let ctx = MPContext::new(320, Nearest)
  let value = ctx.complex_prime_zeta(
    ctx.complex(ctx.parse("0.9"), @mpf.RawMpf::zero()),
  )
  assert_close_mpf_str(
    value.real,
    "1.83883161544468796560849030774519650233784477705974845691001453066371742563551217100308276044636319452585628614303643435105069577314916648749572136081814551764325692288356423424677",
    "2e-90",
    comparison_precision=380,
  )
  assert_close_mpf_str(
    value.imag,
    "3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110556",
    "2e-90",
    comparison_precision=380,
  )
  try ctx.prime_zeta(ctx.parse("0.9")) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected real prime-zeta continuation error")
  } noraise {
    _ => fail("expected complex prime-zeta continuation")
  }
}

///|
test "complex prime zeta matches mpmath away from the real axis" {
  let ctx = MPContext::new(500, Nearest)
  let value = ctx.complex_prime_zeta(
    ctx.complex(ctx.parse("2.5"), ctx.from_int(4)),
  )
  assert_close_mpf_str(
    value.real,
    "-0.169224582434380333847374426608052091370786887248265611018498390601816806191573598371710399657305841896398236986571839464550937500548747455730018460151869496777002348140329772152474",
    "2e-143",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    value.imag,
    "-0.010847965298387727811391518340267052806944954246610158582489366115700972745691621721121000233822592491836068352182364989798965310184143274413238557520173717144953471785377761869533",
    "2e-143",
    comparison_precision=560,
  )
}

///|
test "prime zeta special values and domain errors are structured" {
  let ctx = MPContext::new(400, Nearest)
  let half = @mpf.RawMpf::half()
  let at_half = ctx.complex_prime_zeta(ctx.complex(half, @mpf.RawMpf::zero()))
  @debug.assert_eq(at_half.real, @mpf.RawMpf::negative_infinity())
  assert_close_mpf_str(at_half.imag, ctx.pi().format(dps=125), "2e-115")
  @debug.assert_eq(ctx.prime_zeta(@mpf.RawMpf::one()), @mpf.RawMpf::infinity())
  @debug.assert_eq(ctx.prime_zeta(@mpf.RawMpf::infinity()), @mpf.RawMpf::zero())
  assert_true(ctx.prime_zeta(@mpf.RawMpf::nan()).is_nan())
  try ctx.prime_zeta(ctx.from_int(0)) catch {
    DomainError(_) => ()
    _ => fail("unexpected prime-zeta domain error")
  } noraise {
    _ => fail("expected prime-zeta domain error")
  }
}
