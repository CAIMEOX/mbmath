///|
fn p3_diag_matrix(
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
fn p3_col_as_matrix(
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
fn p3_test_extract_col(
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
test "p3 qr and qr_solve subset from mpmath test_linalg" {
  let ctx = new(280, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [ctx.make_int(1), ctx.make_float("-0.5")],
    [ctx.make_int(2), ctx.make_int(1)],
    [ctx.make_int(-2), ctx.make_int(6)],
  ])
  let (q, r) = ctx.qr(a)
  let rec = ctx.matrix_mul(q, r)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec))
  assert_true(@mpf.mpf_lt(rec_err, @mpf.from_str("1e-9")))

  let qt = ctx.matrix_transpose(q)
  let qtq = ctx.matrix_mul(qt, q)
  let eye2 = ctx.eye(2)
  let ortho_err = ctx.matrix_norm_inf(ctx.matrix_sub(qtq, eye2))
  assert_true(@mpf.mpf_lt(ortho_err, @mpf.from_str("1e-8")))

  let a1 = ctx.matrix_from_rows([
    [ctx.make_int(3), ctx.make_int(1), ctx.make_int(6)],
    [ctx.make_int(2), ctx.make_int(1), ctx.make_int(3)],
    [ctx.make_int(1), ctx.make_int(1), ctx.make_int(1)],
  ])
  let b1 : Array[@mpf.RawMpf] = [
    ctx.make_int(2),
    ctx.make_int(7),
    ctx.make_int(4),
  ]
  let (x_qr, rnorm) = ctx.qr_solve(a1, b1)
  assert_close_mpf_str(x_qr[0], "19", "1e-8")
  assert_close_mpf_str(x_qr[1], "-7", "1e-8")
  assert_close_mpf_str(x_qr[2], "-8", "1e-8")
  assert_true(@mpf.mpf_lt(rnorm, @mpf.from_str("1e-10")))
}

///|
test "p3 cholesky and cond subset from mpmath test_linalg" {
  let ctx = new(300, @mpf.round_nearest)
  let a9 = ctx.matrix_from_rows([
    [ctx.make_int(4), ctx.make_int(2), ctx.make_int(-2)],
    [ctx.make_int(2), ctx.make_int(5), ctx.make_int(-4)],
    [ctx.make_int(-2), ctx.make_int(-4), ctx.make_float("5.5")],
  ])
  let l = ctx.cholesky(a9)
  let lt = ctx.matrix_transpose(l)
  let rec = ctx.matrix_mul(l, lt)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a9, rec))
  assert_true(@mpf.mpf_lt(rec_err, @mpf.from_str("1e-8")))

  let b9 : Array[@mpf.RawMpf] = [
    ctx.make_int(10),
    ctx.make_int(16),
    ctx.make_float("-15.5"),
  ]
  let x = ctx.cholesky_solve(a9, b9)
  let ax = ctx.matrix_vec_mul(a9, x)
  let mut res_inf = @mpf.fzero
  for i in 0..<b9.length() {
    let e = @mpf.mpf_abs(
      @mpf.mpf_sub(ax[i], b9[i], 320, @mpf.round_nearest),
      320,
      @mpf.round_nearest,
    )
    if @mpf.mpf_gt(e, res_inf) {
      res_inf = e
    }
  }
  assert_true(@mpf.mpf_lt(res_inf, @mpf.from_str("1e-8")))

  let acond = ctx.matrix_from_rows([
    [ctx.make_float("1.2969"), ctx.make_float("0.8648")],
    [ctx.make_float("0.2161"), ctx.make_float("0.1441")],
  ])
  let c1 = ctx.cond(acond, norm="1")
  let cinf = ctx.cond(acond, norm="inf")
  let cf = ctx.cond(acond, norm="fro")
  assert_close_mpf_str(c1, "327065209.73817754", "1e2")
  assert_close_mpf_str(cinf, "327065209.73817754", "1e2")
  assert_close_mpf_str(cf, "249729266.80008656", "1e2")
}

///|
test "p3 hessenberg and schur subset from mpmath test_eigen" {
  let ctx = new(280, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [ctx.make_int(2), ctx.make_int(3), ctx.make_int(4), ctx.make_int(1)],
    [ctx.make_int(5), ctx.make_int(6), ctx.make_int(7), ctx.make_int(2)],
    [ctx.make_int(8), ctx.make_int(9), ctx.make_int(1), ctx.make_int(3)],
    [ctx.make_int(4), ctx.make_int(2), ctx.make_int(5), ctx.make_int(6)],
  ])
  let (q, h) = ctx.hessenberg(a)
  let rec_h = ctx.matrix_mul(ctx.matrix_mul(q, h), ctx.matrix_transpose(q))
  let rec_h_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_h))
  assert_true(@mpf.mpf_lt(rec_h_err, @mpf.from_str("5e-7")))
  for i in 0..<h.rows {
    for j in 0..<h.cols {
      if i > j + 1 {
        assert_true(
          @mpf.mpf_lt(
            @mpf.mpf_abs(h.get(i, j), 320, @mpf.round_nearest),
            @mpf.from_str("2e-8"),
          ),
        )
      }
    }
  }

  let (qs, t) = ctx.schur(a, max_steps=2200)
  let rec_s = ctx.matrix_mul(ctx.matrix_mul(qs, t), ctx.matrix_transpose(qs))
  let rec_s_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_s))
  assert_true(@mpf.mpf_lt(rec_s_err, @mpf.from_str("2e-6")))
}

///|
test "p3 eig/eighe/svd subset from mpmath test_eigen and test_linalg" {
  let ctx = new(300, @mpf.round_nearest)
  let a2 = ctx.matrix_from_rows([
    [ctx.make_int(1), ctx.make_int(2)],
    [ctx.make_int(3), ctx.make_int(4)],
  ])
  let (vals, vecs) = ctx.eig(a2, max_steps=1800)
  assert_eq(vals.length(), 2)
  let lam_a = vals[0]
  let lam_b = vals[1]
  let v0 = p3_col_as_matrix(ctx, p3_test_extract_col(vecs, 0))
  let v1 = p3_col_as_matrix(ctx, p3_test_extract_col(vecs, 1))
  let av0 = ctx.matrix_mul(a2, v0)
  let av1 = ctx.matrix_mul(a2, v1)
  let lv0 = ctx.matrix(v0.rows, 1)
  let lv1 = ctx.matrix(v1.rows, 1)
  for i in 0..<v0.rows {
    lv0.set(i, 0, @mpf.mpf_mul(lam_a, v0.get(i, 0), 320, @mpf.round_nearest))
    lv1.set(i, 0, @mpf.mpf_mul(lam_b, v1.get(i, 0), 320, @mpf.round_nearest))
  }
  let r0 = ctx.matrix_norm_inf(ctx.matrix_sub(av0, lv0))
  let r1 = ctx.matrix_norm_inf(ctx.matrix_sub(av1, lv1))
  assert_true(@mpf.mpf_lt(r0, @mpf.from_str("2e-5")))
  assert_true(@mpf.mpf_lt(r1, @mpf.from_str("2e-5")))

  let sym = ctx.matrix_from_rows([
    [ctx.make_int(2), ctx.make_int(3)],
    [ctx.make_int(3), ctx.make_int(5)],
  ])
  let (d, q) = ctx.eighe(sym)
  let dmat = p3_diag_matrix(ctx, d)
  let rec = ctx.matrix_mul(ctx.matrix_mul(q, dmat), ctx.matrix_transpose(q))
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(sym, rec))
  assert_true(@mpf.mpf_lt(rec_err, @mpf.from_str("1e-8")))

  let a = ctx.matrix_from_rows([
    [ctx.make_int(1), ctx.make_float("-0.5")],
    [ctx.make_int(2), ctx.make_int(1)],
    [ctx.make_int(-2), ctx.make_int(6)],
  ])
  let (u, s, v) = ctx.svd(a)
  assert_eq(s.length(), 2)
  assert_true(@mpf.mpf_ge(s[0], s[1]))
  assert_true(@mpf.mpf_ge(s[1], @mpf.fzero))
  let smat = p3_diag_matrix(ctx, s)
  let rec_svd = ctx.matrix_mul(ctx.matrix_mul(u, smat), v)
  let rec_svd_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, rec_svd))
  assert_true(@mpf.mpf_lt(rec_svd_err, @mpf.from_str("2e-6")))
}
