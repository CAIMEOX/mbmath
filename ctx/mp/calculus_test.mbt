///|
fn calculus_integer(ctx : MPContext, n : Int) -> @mpf.RawMpf {
  ctx.from_int(n)
}

///|
fn assert_real_close(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  tol : String,
) -> Unit raise {
  let p = 320
  let err = x.sub(y, p, Nearest).abs(p, Nearest)
  assert_true(err < @mpf.RawMpf::parse(tol))
}

///|
fn assert_complex_close(
  z : @mpc.RawMpc,
  w : @mpc.RawMpc,
  tol : String,
) -> Unit raise {
  assert_real_close(z.real, w.real, tol)
  assert_real_close(z.imag, w.imag, tol)
}

///|
fn assert_calculus_matrix_close(
  ctx : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
  tol : String,
) -> Unit raise {
  let d = ctx.matrix_sub(a, b)
  let n = ctx.matrix_norm_inf(d)
  assert_true(n < @mpf.RawMpf::parse(tol))
}

///|
fn take_mpf_prefix(xs : ArrayView[@mpf.RawMpf], n : Int) -> Array[@mpf.RawMpf] {
  let m = if n < xs.length() { n } else { xs.length() }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<m {
    out.push(xs[i])
  }
  out
}

///|
fn legendre_polynomial_coefficients(
  ctx : MPContext,
) -> Array[@mpf.RawMpf] raise MPError {
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
    out.push(ctx.parse(s))
  }
  out
}

///|
test "calculus approximation (chebyfit/polyval) from mpmath test_calculus" {
  let ctx = MPContext::new(240, Nearest)
  let f = (x : @mpf.RawMpf) => {
    ctx
    .cos(calculus_integer(ctx, 2).sub(x.mul_int(2, 260, Nearest), 260, Nearest))
    .div(x, 260, Nearest)
  }
  let (p, err) = ctx.chebyfit(
    f,
    (calculus_integer(ctx, 2), calculus_integer(ctx, 4)),
    8,
  )
  assert_true(err < @mpf.RawMpf::parse("1e-5"))
  for i in 0..<10 {
    let x = calculus_integer(ctx, 2).add(
      @mpf.RawMpf::from_int(i).div(@mpf.RawMpf::from_int(5), 260, Nearest),
      260,
      Nearest,
    )
    let py = ctx.polyval(p, x)
    let dy = py.sub(f(x), 260, Nearest).abs(260, Nearest)
    assert_true(dy < err)
  }
  let (p_desc, err_desc) = ctx.chebyfit(
    f,
    (calculus_integer(ctx, 2), calculus_integer(ctx, 4)),
    8,
    asc=false,
  )
  assert_true(err_desc < @mpf.RawMpf::parse("1e-5"))
  let p_desc_rev : Array[@mpf.RawMpf] = []
  let mut j = p_desc.length() - 1
  while j >= 0 {
    p_desc_rev.push(p_desc[j])
    j -= 1
  }
  for i in 0..<10 {
    let x = calculus_integer(ctx, 2).add(
      @mpf.RawMpf::from_int(i).div(@mpf.RawMpf::from_int(5), 260, Nearest),
      260,
      Nearest,
    )
    let py = ctx.polyval(p_desc_rev, x)
    let dy = py.sub(f(x), 260, Nearest).abs(260, Nearest)
    assert_true(dy < err_desc)
  }
}

///|
test "calculus limits subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)
  let lim0 = ctx.limit(
    (x : @mpf.RawMpf) => {
      let x3 = x.pow_int(3, 260, Nearest)
      x.sub(ctx.sin(x), 260, Nearest).div(x3, 260, Nearest)
    },
    @mpf.RawMpf::zero(),
  )
  assert_real_close(
    lim0,
    calculus_integer(ctx, 1).div(calculus_integer(ctx, 6), 260, Nearest),
    "1e-8",
  )
  let lim_inf = ctx.limit(
    (n : @mpf.RawMpf) => {
      @libelefun.pow(
        @mpf.RawMpf::one().add(
          @mpf.RawMpf::one().div(n, 260, Nearest),
          260,
          Nearest,
        ),
        n,
        260,
        Nearest,
      )
    },
    @mpf.RawMpf::infinity(),
  )
  assert_real_close(lim_inf, @libelefun.e(260, Nearest), "2e-6")
}

///|
test "calculus polyval subset from mpmath test_calculus" {
  let ctx = MPContext::new(220, Nearest)
  assert_true(ctx.polyval([], calculus_integer(ctx, 3)) == @mpf.RawMpf::zero())
  assert_true(
    ctx.polyval([@mpf.RawMpf::zero()], calculus_integer(ctx, 3)) ==
    @mpf.RawMpf::zero(),
  )
  assert_true(
    ctx.polyval([calculus_integer(ctx, 5)], calculus_integer(ctx, 3)) ==
    calculus_integer(ctx, 5),
  )
  let p = [
    calculus_integer(ctx, 5),
    calculus_integer(ctx, -2),
    @mpf.RawMpf::zero(),
    calculus_integer(ctx, 4),
  ]
  assert_true(
    ctx.polyval(p, calculus_integer(ctx, 4)) == calculus_integer(ctx, 253),
  )
  let (y, dy) = ctx.polyval_with_derivative(p, calculus_integer(ctx, 4))
  assert_true(y == calculus_integer(ctx, 253))
  assert_true(dy == calculus_integer(ctx, 190))
  assert_true(
    ctx.polyval(
      [
        calculus_integer(ctx, 1),
        calculus_integer(ctx, 2),
        calculus_integer(ctx, 3),
      ],
      calculus_integer(ctx, 2),
      asc=false,
    ) ==
    calculus_integer(ctx, 11),
  )
}

///|
test "calculus polyroots basic subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)
  let r0 = ctx.polyroots([calculus_integer(ctx, -4), calculus_integer(ctx, 1)])
  @debug.assert_eq(r0.length(), 1)
  assert_real_close(r0[0].real, calculus_integer(ctx, 4), "1e-12")
  assert_real_close(r0[0].imag, @mpf.RawMpf::zero(), "1e-12")

  let r2 = ctx.polyroots([
    calculus_integer(ctx, 3),
    calculus_integer(ctx, 2),
    calculus_integer(ctx, 1),
  ])
  @debug.assert_eq(r2.length(), 2)
  let target0 = @mpc.RawMpc::new(
    calculus_integer(ctx, -1),
    ctx.sqrt(calculus_integer(ctx, 2)).negated(260, Nearest),
  )
  let target1 = @mpc.RawMpc::new(
    calculus_integer(ctx, -1),
    ctx.sqrt(calculus_integer(ctx, 2)),
  )
  assert_complex_close(r2[0], target0, "2e-8")
  assert_complex_close(r2[1], target1, "2e-8")

  let rc = ctx.polyroots([calculus_integer(ctx, 1)])
  @debug.assert_eq(rc.length(), 0)
  try ctx.polyroots([@mpf.RawMpf::zero()]) catch {
    ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for zero polynomial")
  }

  let r2_desc = ctx.polyroots(
    [
      calculus_integer(ctx, 1),
      calculus_integer(ctx, 2),
      calculus_integer(ctx, 3),
    ],
    asc=false,
  )
  assert_complex_close(r2_desc[0], target0, "2e-8")
  assert_complex_close(r2_desc[1], target1, "2e-8")
}

///|
test "calculus polyroots legendre subset from mpmath test_calculus" {
  let low = MPContext::new(40, Nearest)
  let hi = MPContext::new(220, Nearest)
  let coeffs = legendre_polynomial_coefficients(low)
  try low.polyroots(coeffs, max_steps=5, cleanup=true, extraprec=160) catch {
    ConvergenceError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected convergence error for low-step legendre run")
  }
  let roots = hi.polyroots(coeffs, max_steps=90, cleanup=true, extraprec=220)
  @debug.assert_eq(roots.length(), 64)
  let mut prev = hi.from_int(-2)
  for r in roots {
    assert_true(r.imag.abs(260, Nearest) < @mpf.RawMpf::parse("1e-5"))
    assert_true(r.real > hi.parse("-1.05"))
    assert_true(r.real < hi.parse("1.05"))
    assert_true(r.real >= prev)
    prev = r.real
  }
}

///|
test "calculus polyroots init subset from mpmath test_calculus" {
  let ctx = MPContext::new(220, Nearest)
  let coeffs = legendre_polynomial_coefficients(ctx)
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
    init_vals.push(ctx.parse(s))
  }
  let roots_exact = ctx.polyroots(
    coeffs,
    max_steps=90,
    cleanup=true,
    extraprec=220,
  )
  try ctx.polyroots(coeffs, max_steps=5, cleanup=true, extraprec=120) catch {
    ConvergenceError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected convergence error")
  }
  let (roots, err) = ctx.polyroots_with_init_error(
    coeffs,
    init_vals,
    max_steps=12,
    cleanup=true,
    extraprec=120,
  )
  let mut maxd = @mpf.RawMpf::zero()
  for i in 0..<roots.length() {
    let d = roots_exact[i].sub(roots[i], 260, Nearest).abs(260, Nearest)
    if d > maxd {
      maxd = d
    }
  }
  assert_true(maxd < err.mul_int(4, 260, Nearest))

  let init60 = take_mpf_prefix(init_vals, 60)
  let (roots1, err1) = ctx.polyroots_with_init_error(
    coeffs,
    init60,
    max_steps=25,
    cleanup=true,
    extraprec=120,
  )
  let mut maxd1 = @mpf.RawMpf::zero()
  for i in 0..<roots1.length() {
    let d = roots_exact[i].sub(roots1[i], 260, Nearest).abs(260, Nearest)
    if d > maxd1 {
      maxd1 = d
    }
  }
  assert_true(maxd1 < err1.mul_int(4, 260, Nearest))
}

///|
test "calculus pade subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)
  let one = @mpf.RawMpf::one()
  let n = 10
  let a : Array[@mpf.RawMpf] = [one]
  let mut k = 1
  for i in 1..<=n {
    k *= i
    a.push(one.div(@mpf.RawMpf::from_int(k), 260, Nearest))
  }
  let (p, q) = ctx.pade(a, n / 2, n / 2)
  for i in 0..<10 {
    let x = @mpf.RawMpf::from_int(i).div(
      @mpf.RawMpf::from_int(10),
      260,
      Nearest,
    )
    let px = ctx.polyval(p, x)
    let qx = ctx.polyval(q, x)
    let r = px.div(qx, 260, Nearest)
    assert_real_close(r, ctx.exp(x), "2e-8")
  }
}

///|
test "calculus fourier subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)
  let f = (x : @mpf.RawMpf) => x.add(@mpf.RawMpf::one(), 260, Nearest)
  let (c, s) = ctx.fourier(f, (ctx.from_int(-1), ctx.from_int(2)), 2)
  let pi = @libelefun.pi(260, Nearest)
  let sqrt3 = ctx.sqrt(ctx.from_int(3))
  assert_real_close(c[0], ctx.parse("1.5"), "1e-8")
  assert_real_close(
    c[1],
    sqrt3
    .mul_int(3, 260, Nearest)
    .negated(260, Nearest)
    .div(pi.mul_int(2, 260, Nearest), 260, Nearest),
    "3e-7",
  )
  assert_real_close(
    c[2],
    sqrt3
    .mul_int(3, 260, Nearest)
    .div(pi.mul_int(4, 260, Nearest), 260, Nearest),
    "3e-7",
  )
  assert_true(s[0] == @mpf.RawMpf::zero())
  assert_real_close(
    s[1],
    calculus_integer(ctx, 3).div(pi.mul_int(2, 260, Nearest), 260, Nearest),
    "3e-7",
  )
  assert_real_close(
    s[2],
    calculus_integer(ctx, 3).div(pi.mul_int(4, 260, Nearest), 260, Nearest),
    "3e-7",
  )
  let v = ctx.fourierval(
    (c, s),
    (ctx.from_int(-1), ctx.from_int(2)),
    ctx.from_int(1),
  )
  assert_real_close(v, ctx.parse("1.9134966715663442"), "6e-7")
}

///|
test "calculus differint subset from mpmath test_calculus" {
  let ctx = MPContext::new(280, Nearest)
  let y = ctx.differint(
    (t : @mpf.RawMpf) => t,
    ctx.from_int(2),
    ctx.parse("-0.5"),
  )
  let pi = @libelefun.pi(280, Nearest)
  let target = ctx
    .sqrt(ctx.from_int(2).div(pi, 280, Nearest))
    .mul_int(8, 280, Nearest)
    .div(ctx.from_int(3), 280, Nearest)
  assert_real_close(y, target, "6e-4")

  let d1 = ctx.differint(
    (t : @mpf.RawMpf) => t.pow_int(2, 300, Nearest),
    ctx.from_int(2),
    ctx.from_int(1),
  )
  assert_real_close(d1, ctx.from_int(4), "2e-6")

  let d2 = ctx.differint(
    (t : @mpf.RawMpf) => t.pow_int(3, 300, Nearest),
    ctx.from_int(2),
    ctx.from_int(2),
  )
  assert_real_close(d2, ctx.from_int(12), "2e-4")

  try
    ctx.differint((t : @mpf.RawMpf) => t, ctx.from_int(2), ctx.parse("0.5"))
  catch {
    MPError::ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for positive non-integer order")
  }
}

///|
test "calculus invertlaplace subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)
  let methods = ["talbot", "stehfest", "dehoog", "cohen"]

  let fp1 = (p : @mpf.RawMpf) => {
    let d = p.add(@mpf.RawMpf::one(), 300, Nearest).pow_int(2, 300, Nearest)
    @mpf.RawMpf::one().div(d, 300, Nearest)
  }
  let ft1 = (t : @mpf.RawMpf) => {
    t.mul(@libelefun.exp(t.negated(300, Nearest), 300, Nearest), 300, Nearest)
  }
  for ts in ["0.01", "1.0"] {
    let t = ctx.parse(ts)
    let target = ft1(t)
    for m in methods {
      let y = ctx.invertlaplace(fp1, t, algo=m)
      assert_real_close(y, target, "4e-4")
    }
  }

  let fp2 = (p : @mpf.RawMpf) => ctx.ln(p).div(p, 300, Nearest)
  let euler = @gammazeta.euler(300, Nearest)
  let ft2 = (t : @mpf.RawMpf) => {
    euler.negated(300, Nearest).sub(ctx.ln(t), 300, Nearest)
  }
  for ts in ["0.01", "1.0"] {
    let t = ctx.parse(ts)
    let target = ft2(t)
    for m in methods {
      let y = ctx.invertlaplace(fp2, t, algo=m)
      assert_real_close(y, target, "1e-3")
    }
  }
}

///|
test "calculus expm/cosm/sinm subset from mpmath test_calculus" {
  let ctx = MPContext::new(260, Nearest)

  let a1 = ctx.matrix_from_rows([
    [ctx.from_int(2), @mpf.RawMpf::zero()],
    [@mpf.RawMpf::zero(), ctx.from_int(1)],
  ])
  let e1 = ctx.expm(a1)
  let b1 = ctx.matrix_from_rows([
    [ctx.exp(ctx.from_int(2)), @mpf.RawMpf::zero()],
    [@mpf.RawMpf::zero(), ctx.exp(ctx.from_int(1))],
  ])
  assert_calculus_matrix_close(ctx, e1, b1, "2e-8")

  let pi = @libelefun.pi(260, Nearest)
  let a2 = ctx.matrix_from_rows([
    [@mpf.RawMpf::zero(), pi.negated(260, Nearest)],
    [pi, @mpf.RawMpf::zero()],
  ])
  let e2 = ctx.expm(a2)
  let b2 = ctx.matrix_from_rows([
    [ctx.from_int(-1), @mpf.RawMpf::zero()],
    [@mpf.RawMpf::zero(), ctx.from_int(-1)],
  ])
  assert_calculus_matrix_close(ctx, e2, b2, "2e-7")

  let c = ctx.cosm(
    ctx.matrix_from_rows([
      [pi.negated(260, Nearest), @mpf.RawMpf::zero()],
      [@mpf.RawMpf::zero(), pi],
    ]),
  )
  let s = ctx.sinm(
    ctx.matrix_from_rows([
      [pi.negated(260, Nearest), @mpf.RawMpf::zero()],
      [@mpf.RawMpf::zero(), pi],
    ]),
  )
  let c_exact = ctx.matrix_from_rows([
    [ctx.cos(pi.negated(260, Nearest)), @mpf.RawMpf::zero()],
    [@mpf.RawMpf::zero(), ctx.cos(pi)],
  ])
  let s_exact = ctx.zeros(2)
  assert_calculus_matrix_close(ctx, c, c_exact, "2e-8")
  assert_calculus_matrix_close(ctx, s, s_exact, "2e-8")

  let nonsquare = ctx.matrix(3, 2)
  try ctx.expm(nonsquare) catch {
    ValueError(_) => ()
    _ => fail("unexpected expm error")
  } noraise {
    _ => fail("expected expm shape error")
  }
  try ctx.cosm(nonsquare) catch {
    ValueError(_) => ()
    _ => fail("unexpected cosm error")
  } noraise {
    _ => fail("expected cosm shape error")
  }
  try ctx.sinm(nonsquare) catch {
    ValueError(_) => ()
    _ => fail("unexpected sinm error")
  } noraise {
    _ => fail("expected sinm shape error")
  }
}
