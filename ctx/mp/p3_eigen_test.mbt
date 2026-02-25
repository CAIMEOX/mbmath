///|
test "p3 eigsy subset from mpmath test_eigen_symmetric" {
  let ctx = new(280, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [ctx.make_int(2), ctx.make_int(11), ctx.make_int(7)],
    [ctx.make_int(11), ctx.make_int(3), ctx.make_int(13)],
    [ctx.make_int(7), ctx.make_int(13), ctx.make_int(5)],
  ])
  let (d, q) = ctx.eigsy(a)
  assert_eq(d.length(), 3)
  assert_true(@mpf.mpf_le(d[0], d[1]))
  assert_true(@mpf.mpf_le(d[1], d[2]))

  let dmat = ctx.matrix(3, 3)
  for i in 0..<3 {
    dmat.set(i, i, d[i])
  }
  let qt = ctx.matrix_transpose(q)
  let recon = ctx.matrix_mul(ctx.matrix_mul(q, dmat), qt)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, recon))
  assert_true(@mpf.mpf_lt(rec_err, @mpf.from_str("3e-8")))

  let ortho = ctx.matrix_mul(qt, q)
  let eye = ctx.eye(3)
  let ortho_err = ctx.matrix_norm_inf(ctx.matrix_sub(ortho, eye))
  assert_true(@mpf.mpf_lt(ortho_err, @mpf.from_str("3e-8")))
}
