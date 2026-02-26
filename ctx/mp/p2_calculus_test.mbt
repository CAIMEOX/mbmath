///|
fn p2_calc_i(ctx : MPContext, n : Int) -> @mpf.RawMpf {
  ctx.make_int(n)
}

///|
fn p2_calc_close(x : @mpf.RawMpf, y : @mpf.RawMpf, tol : String) -> Unit raise {
  let p = 320
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, y, p, @mpf.round_nearest),
    p,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
fn p2_calc_cclose(z : @mpc.RawMpc, w : @mpc.RawMpc, tol : String) -> Unit raise {
  p2_calc_close(z.real, w.real, tol)
  p2_calc_close(z.imag, w.imag, tol)
}

///|
fn p2_calc_matrix_close(
  ctx : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
  tol : String,
) -> Unit raise {
  let d = ctx.matrix_sub(a, b)
  let n = ctx.matrix_norm_inf(d)
  assert_true(@mpf.mpf_lt(n, @mpf.from_str(tol)))
}

///|
fn p2_calc_take(xs : ArrayView[@mpf.RawMpf], n : Int) -> Array[@mpf.RawMpf] {
  let m = if n < xs.length() { n } else { xs.length() }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<m {
    out.push(xs[i])
  }
  out
}

///|
fn p2_calc_legendre_coeffs(ctx : MPContext) -> Array[@mpf.RawMpf] raise MPError {
  let out : Array[@mpf.RawMpf] = []
  for
    s in [
      "916312070471295267", "0", "-1905929106580294155360", "0", "659769125727878493447120",
      "0", "-91048139350447232095702560", "0", "6695289961520387531608984680", "0",
      "-304114948474392713657972548576", "0", "9330799555464321896324157740400",
      "0", "-205277590220215081719131470288800", "0", "3378527005707706553294038781836500",
      "0", "-42927166660756742088912492757452000", "0", "431305058712550634988073414073557200",
      "0", "-3491517141958743235617737161547844000", "0", "23112325428835593809686977515028663000",
      "0", "-126584428502545713788439446082310831200", "0", "579006552594977616773047095969088431600",
      "0", "-2228176940331017311443863996901733412640", "0", "7255051932731034189479516844750603752850",
      "0", "-20071017111583894941305187420771723751200", "0", "47310254620162038075933656063247634556400",
      "0", "-95158890516229191805647495979277603503200", "0", "163356095386193445933028201431093219347160",
      "0", "-239057700565161140389797367947941296605600", "0", "297432255354328395601259515935229287637200",
      "0", "-313237834141273382807123548182995095192800", "0", "277415422258095841688223780704620656114900",
      "0", "-204721258548015217049921875719981284186016", "0", "124284021969194758465450309166353645376880",
      "0", "-60969520211303089058522793175947071316960", "0", "23556405536185284408974715545252277554280",
      "0", "-6897338342113537600691931230430793911840", "0", "1437919688271127330313741595496589239248",
      "0", "-190100434726484311252477736051902332000", "0", "11975573020964041433067793888190275875",
    ] {
    out.push(ctx.make_float(s))
  }
  out
}

///|
test "p2 calculus approximation (chebyfit/polyval) from mpmath test_calculus" {
  let ctx = new(240, @mpf.round_nearest)
  let f = (x : @mpf.RawMpf) => {
    @mpf.mpf_div(
      ctx.cos(
        @mpf.mpf_sub(
          p2_calc_i(ctx, 2),
          @mpf.mpf_mul_int(x, 2, 260, @mpf.round_nearest),
          260,
          @mpf.round_nearest,
        ),
      ),
      x,
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    }
  }
  let (p, err) = ctx.chebyfit(f, (p2_calc_i(ctx, 2), p2_calc_i(ctx, 4)), 8)
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-5")))
  for i in 0..<10 {
    let x = @mpf.mpf_add(
      p2_calc_i(ctx, 2),
      @mpf.mpf_div(@mpf.from_int(i), @mpf.from_int(5), 260, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      },
      260,
      @mpf.round_nearest,
    )
    let py = ctx.polyval(p, x)
    let dy = @mpf.mpf_abs(
      @mpf.mpf_sub(py, f(x), 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    )
    assert_true(@mpf.mpf_lt(dy, err))
  }
  let (p_desc, err_desc) = ctx.chebyfit(
    f,
    (p2_calc_i(ctx, 2), p2_calc_i(ctx, 4)),
    8,
    asc=false,
  )
  assert_true(@mpf.mpf_lt(err_desc, @mpf.from_str("1e-5")))
  let p_desc_rev : Array[@mpf.RawMpf] = []
  let mut j = p_desc.length() - 1
  while j >= 0 {
    p_desc_rev.push(p_desc[j])
    j -= 1
  }
  for i in 0..<10 {
    let x = @mpf.mpf_add(
      p2_calc_i(ctx, 2),
      @mpf.mpf_div(@mpf.from_int(i), @mpf.from_int(5), 260, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      },
      260,
      @mpf.round_nearest,
    )
    let py = ctx.polyval(p_desc_rev, x)
    let dy = @mpf.mpf_abs(
      @mpf.mpf_sub(py, f(x), 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    )
    assert_true(@mpf.mpf_lt(dy, err_desc))
  }
}

///|
test "p2 calculus limits subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)
  let lim0 = ctx.limit(
    (x : @mpf.RawMpf) => {
      let x3 = @mpf.mpf_pow_int(x, 3, 260, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
      @mpf.mpf_div(
        @mpf.mpf_sub(x, ctx.sin(x), 260, @mpf.round_nearest),
        x3,
        260,
        @mpf.round_nearest,
      ) catch {
        _ => @mpf.fnan
      }
    },
    @mpf.fzero,
  )
  p2_calc_close(
    lim0,
    @mpf.mpf_div(p2_calc_i(ctx, 1), p2_calc_i(ctx, 6), 260, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    },
    "1e-8",
  )
  let lim_inf = ctx.limit(
    (n : @mpf.RawMpf) => {
      @libelefun.mpf_pow(
        @mpf.mpf_add(
          @mpf.fone,
          @mpf.mpf_div(@mpf.fone, n, 260, @mpf.round_nearest) catch {
            _ => @mpf.fnan
          },
          260,
          @mpf.round_nearest,
        ),
        n,
        260,
        @mpf.round_nearest,
      ) catch {
        _ => @mpf.fnan
      }
    },
    @mpf.finf,
  )
  p2_calc_close(lim_inf, @libelefun.mpf_e(260, @mpf.round_nearest), "2e-6")
}

///|
test "p2 calculus polyval subset from mpmath test_calculus" {
  let ctx = new(220, @mpf.round_nearest)
  assert_true(@mpf.mpf_eq(ctx.polyval([], p2_calc_i(ctx, 3)), @mpf.fzero))
  assert_true(
    @mpf.mpf_eq(ctx.polyval([@mpf.fzero], p2_calc_i(ctx, 3)), @mpf.fzero),
  )
  assert_true(
    @mpf.mpf_eq(
      ctx.polyval([p2_calc_i(ctx, 5)], p2_calc_i(ctx, 3)),
      p2_calc_i(ctx, 5),
    ),
  )
  let p = [p2_calc_i(ctx, 5), p2_calc_i(ctx, -2), @mpf.fzero, p2_calc_i(ctx, 4)]
  assert_true(
    @mpf.mpf_eq(ctx.polyval(p, p2_calc_i(ctx, 4)), p2_calc_i(ctx, 253)),
  )
  let (y, dy) = ctx.polyval_with_derivative(p, p2_calc_i(ctx, 4))
  assert_true(@mpf.mpf_eq(y, p2_calc_i(ctx, 253)))
  assert_true(@mpf.mpf_eq(dy, p2_calc_i(ctx, 190)))
  assert_true(
    @mpf.mpf_eq(
      ctx.polyval(
        [p2_calc_i(ctx, 1), p2_calc_i(ctx, 2), p2_calc_i(ctx, 3)],
        p2_calc_i(ctx, 2),
        asc=false,
      ),
      p2_calc_i(ctx, 11),
    ),
  )
}

///|
test "p2 calculus polyroots basic subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)
  let r0 = ctx.polyroots([p2_calc_i(ctx, -4), p2_calc_i(ctx, 1)])
  assert_eq(r0.length(), 1)
  p2_calc_close(r0[0].real, p2_calc_i(ctx, 4), "1e-12")
  p2_calc_close(r0[0].imag, @mpf.fzero, "1e-12")

  let r2 = ctx.polyroots([
    p2_calc_i(ctx, 3),
    p2_calc_i(ctx, 2),
    p2_calc_i(ctx, 1),
  ])
  assert_eq(r2.length(), 2)
  let target0 = @mpc.from_parts(
    p2_calc_i(ctx, -1),
    @mpf.mpf_neg(ctx.sqrt(p2_calc_i(ctx, 2)), 260, @mpf.round_nearest),
  )
  let target1 = @mpc.from_parts(p2_calc_i(ctx, -1), ctx.sqrt(p2_calc_i(ctx, 2)))
  p2_calc_cclose(r2[0], target0, "2e-8")
  p2_calc_cclose(r2[1], target1, "2e-8")

  let rc = ctx.polyroots([p2_calc_i(ctx, 1)])
  assert_eq(rc.length(), 0)
  let bad : Result[Array[@mpc.RawMpc], MPError] = try? ctx.polyroots([
    @mpf.fzero,
  ])
  match bad {
    Ok(_) => fail("expected ValueError for zero polynomial")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }

  let r2_desc = ctx.polyroots(
    [p2_calc_i(ctx, 1), p2_calc_i(ctx, 2), p2_calc_i(ctx, 3)],
    asc=false,
  )
  p2_calc_cclose(r2_desc[0], target0, "2e-8")
  p2_calc_cclose(r2_desc[1], target1, "2e-8")
}

///|
test "p2 calculus polyroots legendre subset from mpmath test_calculus" {
  let low = new(40, @mpf.round_nearest)
  let hi = new(220, @mpf.round_nearest)
  let coeffs = p2_calc_legendre_coeffs(low)
  let nc : Result[Array[@mpc.RawMpc], MPError] = try? low.polyroots(
    coeffs,
    max_steps=5,
    cleanup=true,
    extraprec=160,
  )
  match nc {
    Ok(_) => fail("expected convergence error for low-step legendre run")
    Err(MPError::ConvergenceError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
  let roots = hi.polyroots(coeffs, max_steps=90, cleanup=true, extraprec=220)
  assert_eq(roots.length(), 64)
  let mut prev = hi.make_int(-2)
  for r in roots {
    assert_true(
      @mpf.mpf_lt(
        @mpf.mpf_abs(r.imag, 260, @mpf.round_nearest),
        @mpf.from_str("1e-5"),
      ),
    )
    assert_true(@mpf.mpf_gt(r.real, hi.make_float("-1.05")))
    assert_true(@mpf.mpf_lt(r.real, hi.make_float("1.05")))
    assert_true(@mpf.mpf_ge(r.real, prev))
    prev = r.real
  }
}

///|
test "p2 calculus polyroots init subset from mpmath test_calculus" {
  let ctx = new(220, @mpf.round_nearest)
  let coeffs = p2_calc_legendre_coeffs(ctx)
  let init_vals : Array[@mpf.RawMpf] = []
  for
    s in [
      "-0.999", "-0.996", "-0.991", "-0.983", "-0.973", "-0.961", "-0.946", "-0.93",
      "-0.911", "-0.889", "-0.866", "-0.841", "-0.813", "-0.784", "-0.753", "-0.72",
      "-0.685", "-0.649", "-0.611", "-0.572", "-0.531", "-0.489", "-0.446", "-0.402",
      "-0.357", "-0.311", "-0.265", "-0.217", "-0.17", "-0.121", "-0.073", "-0.0243",
      "0.0243", "0.073", "0.121", "0.17", "0.217", "0.265", "0.311", "0.357", "0.402",
      "0.446", "0.489", "0.531", "0.572", "0.611", "0.649", "0.685", "0.72", "0.753",
      "0.784", "0.813", "0.841", "0.866", "0.889", "0.911", "0.93", "0.946", "0.961",
      "0.973", "0.983", "0.991", "0.996", "0.999", "1.0",
    ] {
    init_vals.push(ctx.make_float(s))
  }
  let roots_exact = ctx.polyroots(
    coeffs,
    max_steps=90,
    cleanup=true,
    extraprec=220,
  )
  let nc : Result[Array[@mpc.RawMpc], MPError] = try? ctx.polyroots(
    coeffs,
    max_steps=5,
    cleanup=true,
    extraprec=120,
  )
  match nc {
    Ok(_) => fail("expected convergence error")
    Err(MPError::ConvergenceError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
  let (roots, err) = ctx.polyroots_with_init_error(
    coeffs,
    init_vals,
    max_steps=12,
    cleanup=true,
    extraprec=120,
  )
  let mut maxd = @mpf.fzero
  for i in 0..<roots.length() {
    let d = @mpc.mpc_abs(
      @mpc.mpc_sub(roots_exact[i], roots[i], 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    )
    if @mpf.mpf_gt(d, maxd) {
      maxd = d
    }
  }
  assert_true(
    @mpf.mpf_lt(maxd, @mpf.mpf_mul_int(err, 4, 260, @mpf.round_nearest)),
  )

  let init60 = p2_calc_take(init_vals, 60)
  let (roots1, err1) = ctx.polyroots_with_init_error(
    coeffs,
    init60,
    max_steps=25,
    cleanup=true,
    extraprec=120,
  )
  let mut maxd1 = @mpf.fzero
  for i in 0..<roots1.length() {
    let d = @mpc.mpc_abs(
      @mpc.mpc_sub(roots_exact[i], roots1[i], 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    )
    if @mpf.mpf_gt(d, maxd1) {
      maxd1 = d
    }
  }
  assert_true(
    @mpf.mpf_lt(maxd1, @mpf.mpf_mul_int(err1, 4, 260, @mpf.round_nearest)),
  )
}

///|
test "p2 calculus pade subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)
  let one = @mpf.fone
  let n = 10
  let a : Array[@mpf.RawMpf] = [one]
  let mut k = 1
  for i in 1..<=n {
    k *= i
    a.push(
      @mpf.mpf_div(one, @mpf.from_int(k), 260, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      },
    )
  }
  let (p, q) = ctx.pade(a, n / 2, n / 2)
  for i in 0..<10 {
    let x = @mpf.mpf_div(
      @mpf.from_int(i),
      @mpf.from_int(10),
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    }
    let px = ctx.polyval(p, x)
    let qx = ctx.polyval(q, x)
    let r = @mpf.mpf_div(px, qx, 260, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    p2_calc_close(r, ctx.exp(x), "2e-8")
  }
}

///|
test "p2 calculus fourier subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)
  let f = (x : @mpf.RawMpf) => {
    @mpf.mpf_add(x, @mpf.fone, 260, @mpf.round_nearest)
  }
  let (c, s) = ctx.fourier(f, (ctx.make_int(-1), ctx.make_int(2)), 2)
  let pi = @libelefun.mpf_pi(260, @mpf.round_nearest)
  let sqrt3 = ctx.sqrt(ctx.make_int(3))
  p2_calc_close(c[0], ctx.make_float("1.5"), "1e-8")
  p2_calc_close(
    c[1],
    @mpf.mpf_div(
      @mpf.mpf_neg(
        @mpf.mpf_mul_int(sqrt3, 3, 260, @mpf.round_nearest),
        260,
        @mpf.round_nearest,
      ),
      @mpf.mpf_mul_int(pi, 2, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    },
    "3e-7",
  )
  p2_calc_close(
    c[2],
    @mpf.mpf_div(
      @mpf.mpf_mul_int(sqrt3, 3, 260, @mpf.round_nearest),
      @mpf.mpf_mul_int(pi, 4, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    },
    "3e-7",
  )
  assert_true(@mpf.mpf_eq(s[0], @mpf.fzero))
  p2_calc_close(
    s[1],
    @mpf.mpf_div(
      p2_calc_i(ctx, 3),
      @mpf.mpf_mul_int(pi, 2, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    },
    "3e-7",
  )
  p2_calc_close(
    s[2],
    @mpf.mpf_div(
      p2_calc_i(ctx, 3),
      @mpf.mpf_mul_int(pi, 4, 260, @mpf.round_nearest),
      260,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    },
    "3e-7",
  )
  let v = ctx.fourierval(
    (c, s),
    (ctx.make_int(-1), ctx.make_int(2)),
    ctx.make_int(1),
  )
  p2_calc_close(v, ctx.make_float("1.9134966715663442"), "6e-7")
}

///|
test "p2 calculus differint subset from mpmath test_calculus" {
  let ctx = new(280, @mpf.round_nearest)
  let y = ctx.differint(
    (t : @mpf.RawMpf) => t,
    ctx.make_int(2),
    ctx.make_float("-0.5"),
  )
  let pi = @libelefun.mpf_pi(280, @mpf.round_nearest)
  let target = @mpf.mpf_div(
    @mpf.mpf_mul_int(
      ctx.sqrt(
        @mpf.mpf_div(ctx.make_int(2), pi, 280, @mpf.round_nearest) catch {
          _ => @mpf.fnan
        },
      ),
      8,
      280,
      @mpf.round_nearest,
    ),
    ctx.make_int(3),
    280,
    @mpf.round_nearest,
  ) catch {
    _ => @mpf.fnan
  }
  p2_calc_close(y, target, "6e-4")

  let d1 = ctx.differint(
    (t : @mpf.RawMpf) => {
      @mpf.mpf_pow_int(t, 2, 300, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    ctx.make_int(2),
    ctx.make_int(1),
  )
  p2_calc_close(d1, ctx.make_int(4), "2e-6")

  let d2 = ctx.differint(
    (t : @mpf.RawMpf) => {
      @mpf.mpf_pow_int(t, 3, 300, @mpf.round_nearest) catch {
        _ => @mpf.fnan
      }
    },
    ctx.make_int(2),
    ctx.make_int(2),
  )
  p2_calc_close(d2, ctx.make_int(12), "2e-4")

  let bad_order : Result[@mpf.RawMpf, MPError] = try? ctx.differint(
    (t : @mpf.RawMpf) => t,
    ctx.make_int(2),
    ctx.make_float("0.5"),
  )
  match bad_order {
    Ok(_) => fail("expected ValueError for positive non-integer order")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}

///|
test "p2 calculus invertlaplace subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)
  let methods = ["talbot", "stehfest", "dehoog", "cohen"]

  let fp1 = (p : @mpf.RawMpf) => {
    let d = @mpf.mpf_pow_int(
      @mpf.mpf_add(p, @mpf.fone, 300, @mpf.round_nearest),
      2,
      300,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    }
    @mpf.mpf_div(@mpf.fone, d, 300, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
  }
  let ft1 = (t : @mpf.RawMpf) => {
    @mpf.mpf_mul(
      t,
      @libelefun.mpf_exp(
        @mpf.mpf_neg(t, 300, @mpf.round_nearest),
        300,
        @mpf.round_nearest,
      ),
      300,
      @mpf.round_nearest,
    )
  }
  for ts in ["0.01", "1.0"] {
    let t = ctx.make_float(ts)
    let target = ft1(t)
    for m in methods {
      let y = ctx.invertlaplace(fp1, t, algo=m)
      p2_calc_close(y, target, "4e-4")
    }
  }

  let fp2 = (p : @mpf.RawMpf) => {
    @mpf.mpf_div(ctx.ln(p), p, 300, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
  }
  let euler = @gammazeta.mpf_euler(300, @mpf.round_nearest)
  let ft2 = (t : @mpf.RawMpf) => {
    @mpf.mpf_sub(
      @mpf.mpf_neg(euler, 300, @mpf.round_nearest),
      ctx.ln(t),
      300,
      @mpf.round_nearest,
    )
  }
  for ts in ["0.01", "1.0"] {
    let t = ctx.make_float(ts)
    let target = ft2(t)
    for m in methods {
      let y = ctx.invertlaplace(fp2, t, algo=m)
      p2_calc_close(y, target, "1e-3")
    }
  }
}

///|
test "p2 calculus expm/cosm/sinm subset from mpmath test_calculus" {
  let ctx = new(260, @mpf.round_nearest)

  let a1 = ctx.matrix_from_rows([
    [ctx.make_int(2), @mpf.fzero],
    [@mpf.fzero, ctx.make_int(1)],
  ])
  let e1 = ctx.expm(a1)
  let b1 = ctx.matrix_from_rows([
    [ctx.exp(ctx.make_int(2)), @mpf.fzero],
    [@mpf.fzero, ctx.exp(ctx.make_int(1))],
  ])
  p2_calc_matrix_close(ctx, e1, b1, "2e-8")

  let pi = @libelefun.mpf_pi(260, @mpf.round_nearest)
  let a2 = ctx.matrix_from_rows([
    [@mpf.fzero, @mpf.mpf_neg(pi, 260, @mpf.round_nearest)],
    [pi, @mpf.fzero],
  ])
  let e2 = ctx.expm(a2)
  let b2 = ctx.matrix_from_rows([
    [ctx.make_int(-1), @mpf.fzero],
    [@mpf.fzero, ctx.make_int(-1)],
  ])
  p2_calc_matrix_close(ctx, e2, b2, "2e-7")

  let c = ctx.cosm(
    ctx.matrix_from_rows([
      [@mpf.mpf_neg(pi, 260, @mpf.round_nearest), @mpf.fzero],
      [@mpf.fzero, pi],
    ]),
  )
  let s = ctx.sinm(
    ctx.matrix_from_rows([
      [@mpf.mpf_neg(pi, 260, @mpf.round_nearest), @mpf.fzero],
      [@mpf.fzero, pi],
    ]),
  )
  let c_exact = ctx.matrix_from_rows([
    [ctx.cos(@mpf.mpf_neg(pi, 260, @mpf.round_nearest)), @mpf.fzero],
    [@mpf.fzero, ctx.cos(pi)],
  ])
  let s_exact = ctx.zeros(2)
  p2_calc_matrix_close(ctx, c, c_exact, "2e-8")
  p2_calc_matrix_close(ctx, s, s_exact, "2e-8")

  let nonsquare = ctx.matrix(3, 2)
  let ex_bad : Result[MpfMatrix, MPError] = try? ctx.expm(nonsquare)
  let co_bad : Result[MpfMatrix, MPError] = try? ctx.cosm(nonsquare)
  let si_bad : Result[MpfMatrix, MPError] = try? ctx.sinm(nonsquare)
  match ex_bad {
    Ok(_) => fail("expected expm shape error")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected expm error")
  }
  match co_bad {
    Ok(_) => fail("expected cosm shape error")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected cosm error")
  }
  match si_bad {
    Ok(_) => fail("expected sinm shape error")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected sinm error")
  }
}
