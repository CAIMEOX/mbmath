///|
test "p2 diff subset from mpmath test_diff" {
  let ctx = new(260, @mpf.round_nearest)
  let d0 = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.make_int(2), n=0)
  assert_close_mpf_str(
    @mpf.mpf_sub(d0, ctx.cos(ctx.make_int(2)), 260, @mpf.round_nearest),
    "0",
    "1e-30",
  )
  let dcos = ctx.diff((x : @mpf.RawMpf) => ctx.cos(x), ctx.make_int(1))
  let neg_sin = ctx.neg(ctx.sin(ctx.make_int(1)))
  assert_true(
    @mpf.mpf_lt(
      @mpf.mpf_abs(
        @mpf.mpf_sub(dcos, neg_sin, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.from_str("2e-8"),
    ),
  )
  let dabs0 = ctx.diff((x : @mpf.RawMpf) => ctx.abs(x), @mpf.fzero)
  assert_eq(dabs0, @mpf.fzero)
  let dabs_pos = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.fzero,
    direction=1,
  )
  let dabs_neg = ctx.diff(
    (x : @mpf.RawMpf) => ctx.abs(x),
    @mpf.fzero,
    direction=-1,
  )
  assert_close_mpf_str(dabs_pos, "1", "1e-8")
  assert_close_mpf_str(dabs_neg, "-1", "1e-8")
  let dexp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.make_int(1))
  assert_close_mpf_str(dexp, "2.718281828459045235360287", "1e-8")
  let d2poly = ctx.diff(
    (x : @mpf.RawMpf) => {
      let x2 = @mpf.mpf_mul(x, x, 260, @mpf.round_nearest)
      let x4 = @mpf.mpf_mul(x2, x2, 260, @mpf.round_nearest)
      let x5 = @mpf.mpf_mul(x4, x, 260, @mpf.round_nearest)
      @mpf.mpf_add(@mpf.from_int(3), x5, 260, @mpf.round_nearest)
    },
    ctx.make_int(3),
    n=2,
  )
  assert_close_mpf_str(d2poly, "540", "2e-4")

  let d5exp = ctx.diff((x : @mpf.RawMpf) => ctx.exp(x), ctx.make_int(1), n=5)
  assert_close_mpf_str(d5exp, "2.718281828459045235360287", "2e-5")

  let d5sin0 = ctx.diff((x : @mpf.RawMpf) => ctx.sin(x), @mpf.fzero, n=5)
  assert_close_mpf_str(d5sin0, "1", "5e-6")

  let d_quad = ctx.diff(
    (x : @mpf.RawMpf) => @mpf.mpf_mul(x, x, 260, @mpf.round_nearest),
    ctx.make_int(3),
    algo="quad",
  )
  assert_close_mpf_str(d_quad, "6", "2e-6")

  let bad_method : Result[@mpf.RawMpf, MPError] = try? ctx.diff(
    (x : @mpf.RawMpf) => x,
    ctx.make_int(2),
    algo="bad",
  )
  match bad_method {
    Ok(_) => fail("expected ValueError for unknown diff method")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let bad : Result[@mpf.RawMpf, MPError] = try? ctx.diff(
    (x : @mpf.RawMpf) => x,
    ctx.make_int(2),
    n=3,
    direction=1,
  )
  match bad {
    Ok(_) => fail("expected ValueError for direction with n>1")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}

///|
test "p2 diffs/diffun subset from mpmath test_diff" {
  let ctx = new(280, @mpf.round_nearest)
  let d1 = ctx.diffs((x : @mpf.RawMpf) => ctx.sin(x), @mpf.fzero, n=1)
  assert_eq(d1.length(), 2)
  assert_close_mpf_str(d1[0], "0", "2e-8")
  assert_close_mpf_str(d1[1], "1", "2e-6")

  let d1_quad = ctx.diffs(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.fzero,
    n=1,
    algo="quad",
  )
  assert_eq(d1_quad.length(), 2)
  assert_close_mpf_str(d1_quad[0], "0", "2e-8")
  assert_close_mpf_str(d1_quad[1], "1", "2e-6")

  let d2 = ctx.diffs((x : @mpf.RawMpf) => ctx.sin(x), @mpf.fzero, n=2)
  assert_eq(d2.length(), 3)
  assert_close_mpf_str(d2[0], "0", "2e-8")
  assert_close_mpf_str(d2[1], "1", "2e-6")
  assert_close_mpf_str(d2[2], "0", "2e-5")

  let d2_quad = ctx.diffs(
    (x : @mpf.RawMpf) => ctx.sin(x),
    @mpf.fzero,
    n=2,
    algo="quad",
  )
  assert_eq(d2_quad.length(), 3)
  assert_close_mpf_str(d2_quad[0], "0", "2e-8")
  assert_close_mpf_str(d2_quad[1], "1", "2e-6")
  assert_close_mpf_str(d2_quad[2], "0", "3e-5")

  let d_sin = ctx.diffun((x : @mpf.RawMpf) => ctx.sin(x))
  let d2_sin = ctx.diffun((x : @mpf.RawMpf) => ctx.sin(x), n=2)
  assert_close_mpf_str(
    d_sin(ctx.make_int(2)),
    "-0.416146836547142386997568",
    "3e-6",
  )
  assert_close_mpf_str(
    d2_sin(ctx.make_int(2)),
    "-0.909297426825681695396019",
    "3e-5",
  )
}

///|
test "p2 taylor subset from mpmath test_diff" {
  let ctx = new(300, @mpf.round_nearest)
  let coeffs = ctx.taylor(
    (x : @mpf.RawMpf) => {
      @mpf.mpf_sqrt(x, 340, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    ctx.make_int(1),
    4,
  )
  assert_eq(coeffs.length(), 5)
  assert_close_mpf_str(coeffs[0], "1", "2e-8")
  assert_close_mpf_str(coeffs[1], "0.5", "2e-5")
  assert_close_mpf_str(coeffs[2], "-0.125", "3e-4")
  assert_close_mpf_str(coeffs[3], "0.0625", "2e-3")
  assert_close_mpf_str(coeffs[4], "-0.0390625", "1.5e-2")
}

///|
fn p2_diff_partial_expected(i : Int, j : Int, k : Int) -> Int {
  let px = [12, 12, 6]
  let py = [125, 75, 30]
  let pz = [16807, 12005, 6860]
  px[i] * py[j] * pz[k]
}

///|
test "p2 diff_partial3 subset from mpmath test_diff_partial" {
  let ctx = new(320, @mpf.round_nearest)
  let x = ctx.make_int(2)
  let y = ctx.make_int(3)
  let z = ctx.make_int(7)
  let f = (x0 : @mpf.RawMpf, y0 : @mpf.RawMpf, z0 : @mpf.RawMpf) => {
    let x2 = @mpf.mpf_mul(x0, x0, 340, @mpf.round_nearest)
    let y2 = @mpf.mpf_add(y0, ctx.make_int(2), 340, @mpf.round_nearest)
    let y3 = @mpf.mpf_mul(
      @mpf.mpf_mul(y2, y2, 340, @mpf.round_nearest),
      y2,
      340,
      @mpf.round_nearest,
    )
    let z5 = @mpf.mpf_pow_int(z0, 5, 340, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    @mpf.mpf_mul(
      @mpf.mpf_mul(
        @mpf.mpf_mul_int(x2, 3, 340, @mpf.round_nearest),
        y3,
        340,
        @mpf.round_nearest,
      ),
      z5,
      340,
      @mpf.round_nearest,
    )
  }
  for i in 0..<=2 {
    for j in 0..<=2 {
      for k in 0..<=2 {
        let got = ctx.diff_partial3(f, (x, y, z), (i, j, k))
        let want = ctx.make_int(p2_diff_partial_expected(i, j, k))
        let err = @mpf.mpf_abs(
          @mpf.mpf_sub(got, want, 340, @mpf.round_nearest),
          340,
          @mpf.round_nearest,
        )
        let tol = @mpf.mpf_add(
          @mpf.mpf_mul(
            @mpf.mpf_abs(want, 340, @mpf.round_nearest),
            ctx.make_float("2e-2"),
            340,
            @mpf.round_nearest,
          ),
          ctx.make_float("10"),
          340,
          @mpf.round_nearest,
        )
        if !@mpf.mpf_lt(err, tol) {
          let gs = @mpf.to_str_opts(got, dps=20) catch { _ => "nan" }
          let ws = @mpf.to_str_opts(want, dps=20) catch { _ => "nan" }
          let es = @mpf.to_str_opts(err, dps=20) catch { _ => "nan" }
          let ts = @mpf.to_str_opts(tol, dps=20) catch { _ => "nan" }
          fail(
            "diff_partial3 mismatch at (\{i},\{j},\{k}): got=\{gs} want=\{ws} err=\{es} tol=\{ts}",
          )
        }
      }
    }
  }
}
