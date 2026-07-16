///|
test "diff subset from mpmath test_diff" {
  let ctx = MPContext::new(260, Nearest)
  let d0 = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.from_int(2), n=0)
  assert_close_mpf_str(
    d0.sub(ctx.cos(ctx.from_int(2)), 260, Nearest),
    "0",
    "1e-30",
  )
  let dcos = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.from_int(1))
  let neg_sin = ctx.neg(ctx.sin(ctx.from_int(1)))
  assert_true(
    dcos.sub(neg_sin, 260, Nearest).abs(260, Nearest) <
    @mpf.RawMpf::parse("2e-8"),
  )
  let dabs0 = ctx.diff((x : @mpf.RawMpf) => ctx.abs(x), @mpf.RawMpf::zero())
  @debug.assert_eq(dabs0, @mpf.RawMpf::zero())
  let dabs_pos = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.RawMpf::zero(),
    direction=1,
  )
  let dabs_neg = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.RawMpf::zero(),
    direction=-1,
  )
  assert_close_mpf_str(dabs_pos, "1", "1e-8")
  assert_close_mpf_str(dabs_neg, "-1", "1e-8")
  let dexp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.from_int(1))
  assert_close_mpf_str(dexp, "2.718281828459045235360287", "1e-8")
  let d2poly = ctx.diff(
    (x : @mpf.RawMpf) => {
      let x2 = x.mul(x, 260, Nearest)
      let x4 = x2.mul(x2, 260, Nearest)
      let x5 = x4.mul(x, 260, Nearest)
      @mpf.RawMpf::from_int(3).add(x5, 260, Nearest)
    },
    ctx.from_int(3),
    n=2,
  )
  assert_close_mpf_str(d2poly, "540", "2e-4")

  let d5exp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.from_int(1), n=5)
  assert_close_mpf_str(d5exp, "2.718281828459045235360287", "2e-5")

  let d5sin0 = ctx.diff(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.RawMpf::zero(),
    n=5,
  )
  assert_close_mpf_str(d5sin0, "1", "5e-6")

  let d_quad = ctx.diff(
    (x : @mpf.RawMpf) => x.mul(x, 260, Nearest),
    ctx.from_int(3),
    algo="quad",
  )
  assert_close_mpf_str(d_quad, "6", "2e-6")

  try ctx.diff((x : @mpf.RawMpf) => x, ctx.from_int(2), algo="bad") catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for unknown diff method")
  }

  try
    ctx.diff((x : @mpf.RawMpf) => x, ctx.from_int(2), n=3, direction=1)
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for direction with n>1")
  }
}

///|
test "diffs/diffun subset from mpmath test_diff" {
  let ctx = MPContext::new(280, Nearest)
  let d1 = ctx.diffs((x : @mpf.RawMpf) => ctx.sin(x), @mpf.RawMpf::zero(), n=1)
  @debug.assert_eq(d1.length(), 2)
  assert_close_mpf_str(d1[0], "0", "2e-8")
  assert_close_mpf_str(d1[1], "1", "2e-6")

  let d1_quad = ctx.diffs(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.RawMpf::zero(),
    n=1,
    algo="quad",
  )
  @debug.assert_eq(d1_quad.length(), 2)
  assert_close_mpf_str(d1_quad[0], "0", "2e-8")
  assert_close_mpf_str(d1_quad[1], "1", "2e-6")

  let d2 = ctx.diffs((x : @mpf.RawMpf) => ctx.sin(x), @mpf.RawMpf::zero(), n=2)
  @debug.assert_eq(d2.length(), 3)
  assert_close_mpf_str(d2[0], "0", "2e-8")
  assert_close_mpf_str(d2[1], "1", "2e-6")
  assert_close_mpf_str(d2[2], "0", "2e-5")

  let d2_quad = ctx.diffs(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.RawMpf::zero(),
    n=2,
    algo="quad",
  )
  @debug.assert_eq(d2_quad.length(), 3)
  assert_close_mpf_str(d2_quad[0], "0", "2e-8")
  assert_close_mpf_str(d2_quad[1], "1", "2e-6")
  assert_close_mpf_str(d2_quad[2], "0", "3e-5")

  let d_sin = ctx.diffun((x : @mpf.RawMpf) => ctx.sin(x))
  let d2_sin = ctx.diffun((x : @mpf.RawMpf) => ctx.sin(x), n=2)
  assert_close_mpf_str(
    d_sin(ctx.from_int(2)),
    "-0.416146836547142386997568",
    "3e-6",
  )
  assert_close_mpf_str(
    d2_sin(ctx.from_int(2)),
    "-0.909297426825681695396019",
    "3e-5",
  )
}

///|
test "taylor subset from mpmath test_diff" {
  let ctx = MPContext::new(300, Nearest)
  let coeffs = ctx.taylor(
    (x : @mpf.RawMpf) => x.sqrt(340, Nearest),
    ctx.from_int(1),
    4,
  )
  @debug.assert_eq(coeffs.length(), 5)
  assert_close_mpf_str(coeffs[0], "1", "2e-8")
  assert_close_mpf_str(coeffs[1], "0.5", "2e-5")
  assert_close_mpf_str(coeffs[2], "-0.125", "3e-4")
  assert_close_mpf_str(coeffs[3], "0.0625", "2e-3")
  assert_close_mpf_str(coeffs[4], "-0.0390625", "1.5e-2")
}

///|
fn expected_partial_derivative(i : Int, j : Int, k : Int) -> Int {
  let px = [12, 12, 6]
  let py = [125, 75, 30]
  let pz = [16807, 12005, 6860]
  px[i] * py[j] * pz[k]
}

///|
test "diff_partial3 subset from mpmath test_diff_partial" {
  let ctx = MPContext::new(320, Nearest)
  let x = ctx.from_int(2)
  let y = ctx.from_int(3)
  let z = ctx.from_int(7)
  let f = (x0 : @mpf.RawMpf, y0 : @mpf.RawMpf, z0 : @mpf.RawMpf) => {
    let x2 = x0.mul(x0, 340, Nearest)
    let y2 = y0.add(ctx.from_int(2), 340, Nearest)
    let y3 = y2.mul(y2, 340, Nearest).mul(y2, 340, Nearest)
    let z5 = z0.pow_int(5, 340, Nearest)
    x2.mul_int(3, 340, Nearest).mul(y3, 340, Nearest).mul(z5, 340, Nearest)
  }
  for i in 0..<=2 {
    for j in 0..<=2 {
      for k in 0..<=2 {
        let got = ctx.diff_partial3(f, (x, y, z), (i, j, k))
        let want = ctx.from_int(expected_partial_derivative(i, j, k))
        let err = got.sub(want, 340, Nearest).abs(340, Nearest)
        let tol = want
          .abs(340, Nearest)
          .mul(ctx.parse("2e-2"), 340, Nearest)
          .add(ctx.parse("10"), 340, Nearest)
        if !(err < tol) {
          let gs = got.format(dps=20)
          let ws = want.format(dps=20)
          let es = err.format(dps=20)
          let ts = tol.format(dps=20)
          fail(
            "diff_partial3 mismatch at (\{i},\{j},\{k}): got=\{gs} want=\{ws} err=\{es} tol=\{ts}",
          )
        }
      }
    }
  }
}
