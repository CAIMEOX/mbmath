///|
fn diagonal_matrix_for_test(
  ctx : MPContext,
  xs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  let n = xs.length()
  let out = ctx.matrix(n, n)
  for i in 0..<n {
    out.set(i, i, xs[i])
  }
  out
}

///|
fn column_matrix_for_test(
  ctx : MPContext,
  v : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  let out = ctx.matrix(v.length(), 1)
  for i in 0..<v.length() {
    out.set(i, 0, v[i])
  }
  out
}

///|
fn extract_test_column(
  a : MpfMatrix,
  col : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<a.rows {
    out.push(a.get(i, col))
  }
  out
}

///|
test "qr and qr_solve subset from mpmath test_linalg" {
  let ctx = MPContext::new(280, Nearest)
  let a = ctx.matrix_from_rows([
    [ctx.from_int(1), ctx.parse("-0.5")],
    [ctx.from_int(2), ctx.from_int(1)],
    [ctx.from_int(-2), ctx.from_int(6)],
  ])
  let (q, r) = ctx.qr(a)
  let rec = ctx.matrix_mul(q, r)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec))
  assert_true(rec_err < @mpf.RawMpf::parse("1e-9"))

  let qt = ctx.matrix_transpose(q)
  let qtq = ctx.matrix_mul(qt, q)
  let eye2 = ctx.eye(2)
  let ortho_err = ctx.matrix_norm_inf(ctx.matrix_sub(qtq, eye2))
  assert_true(ortho_err < @mpf.RawMpf::parse("1e-8"))

  let a1 = ctx.matrix_from_rows([
    [ctx.from_int(3), ctx.from_int(1), ctx.from_int(6)],
    [ctx.from_int(2), ctx.from_int(1), ctx.from_int(3)],
    [ctx.from_int(1), ctx.from_int(1), ctx.from_int(1)],
  ])
  let b1 : Array[@mpf.RawMpf] = [
    ctx.from_int(2),
    ctx.from_int(7),
    ctx.from_int(4),
  ]
  let (x_qr, rnorm) = ctx.qr_solve(a1, b1)
  assert_close_mpf_str(x_qr[0], "19", "1e-8")
  assert_close_mpf_str(x_qr[1], "-7", "1e-8")
  assert_close_mpf_str(x_qr[2], "-8", "1e-8")
  assert_true(rnorm < @mpf.RawMpf::parse("1e-10"))
}

///|
test "cholesky and cond subset from mpmath test_linalg" {
  let ctx = MPContext::new(300, Nearest)
  let a9 = ctx.matrix_from_rows([
    [ctx.from_int(4), ctx.from_int(2), ctx.from_int(-2)],
    [ctx.from_int(2), ctx.from_int(5), ctx.from_int(-4)],
    [ctx.from_int(-2), ctx.from_int(-4), ctx.parse("5.5")],
  ])
  let l = ctx.cholesky(a9)
  let lt = ctx.matrix_transpose(l)
  let rec = ctx.matrix_mul(l, lt)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a9, rec))
  assert_true(rec_err < @mpf.RawMpf::parse("1e-8"))

  let b9 : Array[@mpf.RawMpf] = [
    ctx.from_int(10),
    ctx.from_int(16),
    ctx.parse("-15.5"),
  ]
  let x = ctx.cholesky_solve(a9, b9)
  let ax = ctx.matrix_vec_mul(a9, x)
  let mut res_inf = @mpf.RawMpf::zero()
  for i in 0..<b9.length() {
    let e = ax[i].sub(b9[i], 320, Nearest).abs(320, Nearest)
    if e > res_inf {
      res_inf = e
    }
  }
  assert_true(res_inf < @mpf.RawMpf::parse("1e-8"))

  let acond = ctx.matrix_from_rows([
    [ctx.parse("1.2969"), ctx.parse("0.8648")],
    [ctx.parse("0.2161"), ctx.parse("0.1441")],
  ])
  let c1 = ctx.cond(acond, norm="1")
  let cinf = ctx.cond(acond, norm="inf")
  let cf = ctx.cond(acond, norm="fro")
  assert_close_mpf_str(c1, "327065209.73817754", "1e2")
  assert_close_mpf_str(cinf, "327065209.73817754", "1e2")
  assert_close_mpf_str(cf, "249729266.80008656", "1e2")
}

///|
test "hessenberg and schur subset from mpmath test_eigen" {
  let ctx = MPContext::new(280, Nearest)
  let a = ctx.matrix_from_rows([
    [ctx.from_int(2), ctx.from_int(3), ctx.from_int(4), ctx.from_int(1)],
    [ctx.from_int(5), ctx.from_int(6), ctx.from_int(7), ctx.from_int(2)],
    [ctx.from_int(8), ctx.from_int(9), ctx.from_int(1), ctx.from_int(3)],
    [ctx.from_int(4), ctx.from_int(2), ctx.from_int(5), ctx.from_int(6)],
  ])
  let (q, h) = ctx.hessenberg(a)
  let rec_h = ctx.matrix_mul(ctx.matrix_mul(q, h), ctx.matrix_transpose(q))
  let rec_h_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_h))
  assert_true(rec_h_err < @mpf.RawMpf::parse("5e-7"))
  for i in 0..<h.rows {
    for j in 0..<h.cols {
      if i > j + 1 {
        assert_true(h.get(i, j).abs(320, Nearest) < @mpf.RawMpf::parse("2e-8"))
      }
    }
  }

  let (qs, t) = ctx.schur(a, max_steps=2200)
  let rec_s = ctx.matrix_mul(ctx.matrix_mul(qs, t), ctx.matrix_transpose(qs))
  let rec_s_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_s))
  assert_true(rec_s_err < @mpf.RawMpf::parse("2e-6"))
}

///|
test "eig/eighe/svd subset from mpmath test_eigen and test_linalg" {
  let ctx = MPContext::new(300, Nearest)
  let a2 = ctx.matrix_from_rows([
    [ctx.from_int(1), ctx.from_int(2)],
    [ctx.from_int(3), ctx.from_int(4)],
  ])
  let (vals, vecs) = ctx.eig(a2, max_steps=1800)
  @debug.assert_eq(vals.length(), 2)
  let lam_a = vals[0]
  let lam_b = vals[1]
  let v0 = column_matrix_for_test(ctx, extract_test_column(vecs, 0))
  let v1 = column_matrix_for_test(ctx, extract_test_column(vecs, 1))
  let av0 = ctx.matrix_mul(a2, v0)
  let av1 = ctx.matrix_mul(a2, v1)
  let lv0 = ctx.matrix(v0.rows, 1)
  let lv1 = ctx.matrix(v1.rows, 1)
  for i in 0..<v0.rows {
    lv0.set(i, 0, lam_a.mul(v0.get(i, 0), 320, Nearest))
    lv1.set(i, 0, lam_b.mul(v1.get(i, 0), 320, Nearest))
  }
  let r0 = ctx.matrix_norm_inf(ctx.matrix_sub(av0, lv0))
  let r1 = ctx.matrix_norm_inf(ctx.matrix_sub(av1, lv1))
  assert_true(r0 < @mpf.RawMpf::parse("2e-5"))
  assert_true(r1 < @mpf.RawMpf::parse("2e-5"))

  let sym = ctx.matrix_from_rows([
    [ctx.from_int(2), ctx.from_int(3)],
    [ctx.from_int(3), ctx.from_int(5)],
  ])
  let (d, q) = ctx.eighe(sym)
  let dmat = diagonal_matrix_for_test(ctx, d)
  let rec = ctx.matrix_mul(ctx.matrix_mul(q, dmat), ctx.matrix_transpose(q))
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(sym, rec))
  assert_true(rec_err < @mpf.RawMpf::parse("1e-8"))

  let a = ctx.matrix_from_rows([
    [ctx.from_int(1), ctx.parse("-0.5")],
    [ctx.from_int(2), ctx.from_int(1)],
    [ctx.from_int(-2), ctx.from_int(6)],
  ])
  let (u, s, v) = ctx.svd(a)
  @debug.assert_eq(s.length(), 2)
  assert_true(s[0] >= s[1])
  assert_true(s[1] >= @mpf.RawMpf::zero())
  let smat = diagonal_matrix_for_test(ctx, s)
  let rec_svd = ctx.matrix_mul(ctx.matrix_mul(u, smat), v)
  let rec_svd_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_svd))
  assert_true(rec_svd_err < @mpf.RawMpf::parse("2e-6"))
}
