///|
test "linalg lu_solve/inverse/det/rank subset from mpmath test_linalg" {
  let ctx = MPContext::new(260, Nearest)
  let a = ctx.matrix_from_rows([
    [ctx.from_int(3), ctx.from_int(1), ctx.from_int(6)],
    [ctx.from_int(2), ctx.from_int(1), ctx.from_int(3)],
    [ctx.from_int(1), ctx.from_int(1), ctx.from_int(1)],
  ])
  let b : Array[@mpf.RawMpf] = [
    ctx.from_int(2),
    ctx.from_int(7),
    ctx.from_int(4),
  ]
  let x = ctx.lu_solve(a, b)
  assert_close_mpf_str(x[0], "19", "1e-16")
  assert_close_mpf_str(x[1], "-7", "1e-16")
  assert_close_mpf_str(x[2], "-8", "1e-16")

  let d = ctx.det(a)
  assert_close_mpf_str(d, "1", "1e-16")

  let inv = ctx.inverse(a)
  let prod = ctx.matrix_mul(a, inv)
  let eye = ctx.eye(3)
  let err = ctx.matrix_norm_inf(ctx.matrix_sub(prod, eye))
  assert_true(err < @mpf.RawMpf::parse("1e-12"))

  let a11 = ctx.matrix_from_rows([
    [ctx.from_int(4), ctx.from_int(0), ctx.from_int(-2)],
    [ctx.from_int(2), ctx.from_int(0), ctx.from_int(-4)],
    [ctx.from_int(2), ctx.from_int(0), ctx.parse("5.5")],
  ])
  @debug.assert_eq(ctx.rank(a11), 2)
}

///|
test "matrix ops and linalg error subset" {
  let ctx = MPContext::new(220, Nearest)
  let m = ctx.matrix_from_rows([
    [ctx.from_int(1), ctx.from_int(2)],
    [ctx.from_int(3), ctx.from_int(4)],
  ])
  let v = ctx.matrix_vec_mul(m, [ctx.from_int(1), ctx.from_int(-1)])
  @debug.assert_eq(v.length(), 2)
  assert_close_mpf_str(v[0], "-1", "1e-14")
  assert_close_mpf_str(v[1], "-1", "1e-14")

  let a_rect = ctx.matrix_from_rows([
    [ctx.from_int(1), ctx.from_int(2), ctx.from_int(3)],
    [ctx.from_int(4), ctx.from_int(5), ctx.from_int(6)],
  ])
  try ctx.lu_solve(a_rect, [ctx.from_int(1), ctx.from_int(1)]) catch {
    ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for non-square lu_solve")
  }
}
