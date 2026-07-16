///|
test "eigsy subset from mpmath test_eigen_symmetric" {
  let ctx = MPContext::new(280, Nearest)
  let a = ctx.matrix_from_rows([
    [ctx.from_int(2), ctx.from_int(11), ctx.from_int(7)],
    [ctx.from_int(11), ctx.from_int(3), ctx.from_int(13)],
    [ctx.from_int(7), ctx.from_int(13), ctx.from_int(5)],
  ])
  let (d, q) = ctx.eigsy(a)
  @debug.assert_eq(d.length(), 3)
  assert_true(d[0] <= d[1])
  assert_true(d[1] <= d[2])

  let dmat = ctx.matrix(3, 3)
  for i in 0..<3 {
    dmat.set(i, i, d[i])
  }
  let qt = ctx.matrix_transpose(q)
  let recon = ctx.matrix_mul(ctx.matrix_mul(q, dmat), qt)
  let rec_err = ctx.matrix_norm_inf(ctx.matrix_sub(a, recon))
  assert_true(rec_err < @mpf.RawMpf::parse("3e-8"))

  let ortho = ctx.matrix_mul(qt, q)
  let eye = ctx.eye(3)
  let ortho_err = ctx.matrix_norm_inf(ctx.matrix_sub(ortho, eye))
  assert_true(ortho_err < @mpf.RawMpf::parse("3e-8"))
}
