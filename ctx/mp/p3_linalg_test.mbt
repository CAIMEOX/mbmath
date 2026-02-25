///|
test "p3 linalg lu_solve/inverse/det/rank subset from mpmath test_linalg" {
  let ctx = new(260, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [ctx.make_int(3), ctx.make_int(1), ctx.make_int(6)],
    [ctx.make_int(2), ctx.make_int(1), ctx.make_int(3)],
    [ctx.make_int(1), ctx.make_int(1), ctx.make_int(1)],
  ])
  let b : Array[@mpf.RawMpf] = [
    ctx.make_int(2),
    ctx.make_int(7),
    ctx.make_int(4),
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
  assert_true(@mpf.mpf_lt(err, @mpf.from_str("1e-12")))

  let a11 = ctx.matrix_from_rows([
    [ctx.make_int(4), ctx.make_int(0), ctx.make_int(-2)],
    [ctx.make_int(2), ctx.make_int(0), ctx.make_int(-4)],
    [ctx.make_int(2), ctx.make_int(0), ctx.make_float("5.5")],
  ])
  assert_eq(ctx.rank(a11), 2)
}

///|
test "p3 matrix ops and linalg error subset" {
  let ctx = new(220, @mpf.round_nearest)
  let m = ctx.matrix_from_rows([
    [ctx.make_int(1), ctx.make_int(2)],
    [ctx.make_int(3), ctx.make_int(4)],
  ])
  let v = ctx.matrix_vec_mul(m, [ctx.make_int(1), ctx.make_int(-1)])
  assert_eq(v.length(), 2)
  assert_close_mpf_str(v[0], "-1", "1e-14")
  assert_close_mpf_str(v[1], "-1", "1e-14")

  let a_rect = ctx.matrix_from_rows([
    [ctx.make_int(1), ctx.make_int(2), ctx.make_int(3)],
    [ctx.make_int(4), ctx.make_int(5), ctx.make_int(6)],
  ])
  let bad : Result[Array[@mpf.RawMpf], MPError] = try? ctx.lu_solve(a_rect, [
    ctx.make_int(1),
    ctx.make_int(1),
  ])
  match bad {
    Ok(_) => fail("expected ValueError for non-square lu_solve")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}
