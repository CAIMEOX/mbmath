///|
fn p3_assert_matrix_eq(a : MpfMatrix, b : MpfMatrix) -> Unit raise {
  assert_eq(a.rows, b.rows)
  assert_eq(a.cols, b.cols)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      assert_true(@mpf.mpf_eq(a.get(i, j), b.get(i, j)))
    }
  }
}

///|
fn p3_assert_matrix_close(
  ctx : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
  tol : String,
) -> Unit raise {
  let err = ctx.matrix_norm_inf(ctx.matrix_sub(a, b))
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
fn p3_i(ctx : MPContext, n : Int) -> @mpf.RawMpf {
  ctx.make_int(n)
}

///|
test "p3 matrices basic + matmul subset from mpmath test_matrices" {
  let ctx = new(260, @mpf.round_nearest)

  let a1 = ctx.matrix(3, 3)
  for i in 0..<3 {
    a1.set(i, i, p3_i(ctx, 1))
  }
  p3_assert_matrix_eq(a1, ctx.eye(3))
  p3_assert_matrix_eq(a1, ctx.matrix_copy(a1))

  let a2 = ctx.matrix(3, 2)
  assert_eq(a2.rows, 3)
  assert_eq(a2.cols, 2)

  let a3 = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2), p3_i(ctx, 3)],
    [p3_i(ctx, 4), p3_i(ctx, 5), p3_i(ctx, 6)],
    [p3_i(ctx, 7), p3_i(ctx, 8), p3_i(ctx, 9)],
  ])
  let flat = a3.flat()
  for i in 0..<9 {
    assert_true(@mpf.mpf_eq(flat[i], p3_i(ctx, i + 1)))
  }

  a3.set(1, 1, @mpf.fzero)
  assert_true(@mpf.mpf_eq(a3.get(1, 1), @mpf.fzero))

  let a4 = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2), p3_i(ctx, 3)],
    [p3_i(ctx, 4), p3_i(ctx, 5), p3_i(ctx, 6)],
  ])
  let a5 = ctx.matrix_from_rows([
    [p3_i(ctx, 6), p3_i(ctx, -1)],
    [p3_i(ctx, 3), p3_i(ctx, 2)],
    [p3_i(ctx, 0), p3_i(ctx, -3)],
  ])
  p3_assert_matrix_eq(
    ctx.matrix_mul(a4, a5),
    ctx.matrix_from_rows([
      [p3_i(ctx, 12), p3_i(ctx, -6)],
      [p3_i(ctx, 39), p3_i(ctx, -12)],
    ]),
  )

  let bad_mul : Result[MpfMatrix, MPError] = try? ctx.matrix_mul(a2, a2)
  match bad_mul {
    Ok(_) => fail("expected incompatible matrix_mul dimensions")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }

  let l = [
    [p3_i(ctx, 10), p3_i(ctx, 20), p3_i(ctx, 30)],
    [p3_i(ctx, 40), p3_i(ctx, 0), p3_i(ctx, 60)],
    [p3_i(ctx, 70), p3_i(ctx, 80), p3_i(ctx, 90)],
  ]
  let a6 = ctx.matrix_from_rows(l)
  assert_eq(a6.tolist(), l)
  p3_assert_matrix_eq(ctx.matrix_scale(a3, p3_i(ctx, 10)), a6)

  let a7 = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2)],
    [p3_i(ctx, 3), p3_i(ctx, 4)],
    [p3_i(ctx, 5), p3_i(ctx, 6)],
    [p3_i(ctx, 7), p3_i(ctx, 8)],
  ])
  let x = ctx.matrix_from_vector([p3_i(ctx, 10), p3_i(ctx, -10)])
  p3_assert_matrix_eq(
    ctx.matrix_mul(a7, x),
    ctx.matrix_from_vector([
      p3_i(ctx, -10),
      p3_i(ctx, -10),
      p3_i(ctx, -10),
      p3_i(ctx, -10),
    ]),
  )

  let a8 = ctx.ones(5)
  let lhs = ctx.matrix_sub(
    ctx.matrix_add_scalar(a8, p3_i(ctx, 1)),
    ctx.matrix_rsub_scalar(p3_i(ctx, 2), ctx.zeros(5)),
  )
  assert_true(@mpf.mpf_eq(ctx.matrix_sum(lhs), @mpf.fzero))

  p3_assert_matrix_eq(
    ctx.matrix_sub(
      ctx.matrix_div_scalar(
        ctx.matrix_add_scalar(ctx.ones(4), p3_i(ctx, 1)),
        p3_i(ctx, 2),
      ),
      ctx.ones(4),
    ),
    ctx.zeros(4),
  )

  p3_assert_matrix_eq(ctx.matrix_pow(ctx.eye(3), 10), ctx.eye(3))
  let bad_pow : Result[MpfMatrix, MPError] = try? ctx.matrix_pow(a7, 2)
  match bad_pow {
    Ok(_) => fail("expected non-square matrix_pow failure")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }

  let r1 = ctx.randmatrix(3)
  let r2 = ctx.matrix_copy(r1)
  r1.set(0, 0, p3_i(ctx, -100))
  assert_true(r1 != r2)

  let ix = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2)],
    [p3_i(ctx, 3), p3_i(ctx, 4)],
    [p3_i(ctx, 5), p3_i(ctx, 6)],
  ])
  assert_true(@mpf.mpf_eq(ix.get_at(0, -1), p3_i(ctx, 2)))
  assert_true(@mpf.mpf_eq(ix.get_at(-1, -1), p3_i(ctx, 6)))
  assert_true(@mpf.mpf_eq(ix.get_at(1, -2), p3_i(ctx, 3)))
  assert_true(@mpf.mpf_eq(ix.get_at(-3, -2), p3_i(ctx, 1)))
  ix.set_at(0, -1, p3_i(ctx, 3))
  ix.set_at(-1, -1, p3_i(ctx, 4))
  ix.set_at(1, -2, p3_i(ctx, 5))
  ix.set_at(-3, -2, p3_i(ctx, 1))
  assert_true(@mpf.mpf_eq(ix.get_at(0, -1), p3_i(ctx, 3)))
  assert_true(@mpf.mpf_eq(ix.get_at(-1, -1), p3_i(ctx, 4)))
  assert_true(@mpf.mpf_eq(ix.get_at(1, -2), p3_i(ctx, 5)))
  assert_true(@mpf.mpf_eq(ix.get_at(-3, -2), p3_i(ctx, 1)))

  let bad_dims1 : Result[MpfMatrix, MPError] = try? ctx.zeros(-2)
  match bad_dims1 {
    Ok(_) => fail("expected negative matrix dimension failure")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }
}

///|
test "p3 matrices slice subset from mpmath test_matrices::test_matrix_slices" {
  let ctx = new(260, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2), p3_i(ctx, 3)],
    [p3_i(ctx, 4), p3_i(ctx, 5), p3_i(ctx, 6)],
    [p3_i(ctx, 7), p3_i(ctx, 8), p3_i(ctx, 9)],
  ])
  let v = ctx.matrix_from_vector([
    p3_i(ctx, 1),
    p3_i(ctx, 2),
    p3_i(ctx, 3),
    p3_i(ctx, 4),
    p3_i(ctx, 5),
  ])

  p3_assert_matrix_eq(ctx.matrix_slice(a), a)
  p3_assert_matrix_eq(
    ctx.matrix_slice(a, col_start=1, col_end=2),
    ctx.matrix_from_rows([[p3_i(ctx, 2)], [p3_i(ctx, 5)], [p3_i(ctx, 8)]]),
  )
  p3_assert_matrix_eq(
    ctx.matrix_slice(a, row_start=2, row_end=3),
    ctx.matrix_from_rows([[p3_i(ctx, 7), p3_i(ctx, 8), p3_i(ctx, 9)]]),
  )
  p3_assert_matrix_eq(
    ctx.matrix_slice(a, row_start=1, row_end=3, col_start=1, col_end=3),
    ctx.matrix_from_rows([
      [p3_i(ctx, 5), p3_i(ctx, 6)],
      [p3_i(ctx, 8), p3_i(ctx, 9)],
    ]),
  )
  p3_assert_matrix_eq(
    ctx.matrix_slice(a, row_end=2, col_end=2),
    ctx.matrix_from_rows([
      [p3_i(ctx, 1), p3_i(ctx, 2)],
      [p3_i(ctx, 4), p3_i(ctx, 5)],
    ]),
  )
  p3_assert_matrix_eq(
    ctx.matrix_slice(v, row_start=2, row_end=4),
    ctx.matrix_from_vector([p3_i(ctx, 3), p3_i(ctx, 4)]),
  )

  let bad3 : Result[MpfMatrix, MPError] = try? ctx.matrix_slice(
    a,
    col_start=1,
    col_end=6,
  )
  match bad3 {
    Ok(_) => fail("expected out-of-range slice end")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }

  let a1 = ctx.matrix(3, 3)
  ctx.matrix_set_slice(a1, a)
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([[p3_i(ctx, 10), p3_i(ctx, 11), p3_i(ctx, 12)]]),
    row_end=1,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([[p3_i(ctx, 13)], [p3_i(ctx, 14)], [p3_i(ctx, 15)]]),
    col_start=2,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([
      [p3_i(ctx, 16), p3_i(ctx, 17)],
      [p3_i(ctx, 18), p3_i(ctx, 19)],
    ]),
    row_end=2,
    col_end=2,
  )
  p3_assert_matrix_eq(
    a1,
    ctx.matrix_from_rows([
      [p3_i(ctx, 16), p3_i(ctx, 17), p3_i(ctx, 13)],
      [p3_i(ctx, 18), p3_i(ctx, 19), p3_i(ctx, 14)],
      [p3_i(ctx, 7), p3_i(ctx, 8), p3_i(ctx, 15)],
    ]),
  )

  ctx.matrix_set_slice_scalar(v, p3_i(ctx, 10), row_start=1, row_end=3)
  p3_assert_matrix_eq(
    v,
    ctx.matrix_from_vector([
      p3_i(ctx, 1),
      p3_i(ctx, 10),
      p3_i(ctx, 10),
      p3_i(ctx, 4),
      p3_i(ctx, 5),
    ]),
  )

  let mismatch : Result[Unit, MPError] = try? ctx.matrix_set_slice(
    a1,
    ctx.matrix_slice(a, col_start=1, col_end=2),
    row_start=2,
    row_end=3,
    col_end=3,
  )
  match mismatch {
    Ok(_) => fail("expected shape mismatch in matrix_set_slice")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }

  let bad_assign : Result[Unit, MPError] = try? ctx.matrix_set_slice(
    a1,
    ctx.matrix_slice(a),
    row_start=2,
    row_end=3,
    col_start=1,
    col_end=20,
  )
  match bad_assign {
    Ok(_) => fail("expected out-of-range assignment slice")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error")
  }

  let a2 = ctx.matrix(3, 3)
  ctx.matrix_set_slice(a2, a)
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([[p3_i(ctx, 10), p3_i(ctx, 11), p3_i(ctx, 12)]]),
    row_start=-3,
    row_end=-2,
  )
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([[p3_i(ctx, 13)], [p3_i(ctx, 14)], [p3_i(ctx, 15)]]),
    col_start=-1,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([
      [p3_i(ctx, 16), p3_i(ctx, 17)],
      [p3_i(ctx, 18), p3_i(ctx, 19)],
    ]),
    row_end=-1,
    col_end=-1,
  )
  p3_assert_matrix_eq(
    a2,
    ctx.matrix_from_rows([
      [p3_i(ctx, 16), p3_i(ctx, 17), p3_i(ctx, 13)],
      [p3_i(ctx, 18), p3_i(ctx, 19), p3_i(ctx, 14)],
      [p3_i(ctx, 7), p3_i(ctx, 8), p3_i(ctx, 15)],
    ]),
  )
}

///|
test "p3 matrices power/transform/creation/norm/vector/copy subset" {
  let ctx = new(280, @mpf.round_nearest)

  let a = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2)],
    [p3_i(ctx, 3), p3_i(ctx, 4)],
  ])
  p3_assert_matrix_eq(ctx.matrix_pow(a, 2), ctx.matrix_mul(a, a))
  p3_assert_matrix_eq(
    ctx.matrix_pow(a, 3),
    ctx.matrix_mul(ctx.matrix_mul(a, a), a),
  )
  p3_assert_matrix_close(ctx, ctx.matrix_pow(a, -1), ctx.inverse(a), "1e-22")

  let t = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, 2)],
    [p3_i(ctx, 3), p3_i(ctx, 4)],
    [p3_i(ctx, 5), p3_i(ctx, 6)],
  ])
  p3_assert_matrix_eq(
    ctx.matrix_transpose(t),
    ctx.matrix_from_rows([
      [p3_i(ctx, 1), p3_i(ctx, 3), p3_i(ctx, 5)],
      [p3_i(ctx, 2), p3_i(ctx, 4), p3_i(ctx, 6)],
    ]),
  )
  ctx.swap_row(t, 1, 2)
  p3_assert_matrix_eq(
    t,
    ctx.matrix_from_rows([
      [p3_i(ctx, 1), p3_i(ctx, 2)],
      [p3_i(ctx, 5), p3_i(ctx, 6)],
      [p3_i(ctx, 3), p3_i(ctx, 4)],
    ]),
  )

  p3_assert_matrix_eq(
    ctx.extend(ctx.eye(3), [p3_i(ctx, 1), p3_i(ctx, 2), p3_i(ctx, 3)]),
    ctx.matrix_from_rows([
      [p3_i(ctx, 1), p3_i(ctx, 0), p3_i(ctx, 0), p3_i(ctx, 1)],
      [p3_i(ctx, 0), p3_i(ctx, 1), p3_i(ctx, 0), p3_i(ctx, 2)],
      [p3_i(ctx, 0), p3_i(ctx, 0), p3_i(ctx, 1), p3_i(ctx, 3)],
    ]),
  )

  p3_assert_matrix_eq(
    ctx.diag([p3_i(ctx, 1), p3_i(ctx, 2), p3_i(ctx, 3)]),
    ctx.matrix_from_rows([
      [p3_i(ctx, 1), p3_i(ctx, 0), p3_i(ctx, 0)],
      [p3_i(ctx, 0), p3_i(ctx, 2), p3_i(ctx, 0)],
      [p3_i(ctx, 0), p3_i(ctx, 0), p3_i(ctx, 3)],
    ]),
  )

  let h = ctx.hilbert(3)
  assert_close_mpf_str(h.get(0, 0), "1", "1e-20")
  assert_close_mpf_str(h.get(0, 1), "0.5", "1e-20")
  assert_close_mpf_str(h.get(2, 2), "0.2", "1e-20")

  let nmat = ctx.matrix_from_rows([
    [p3_i(ctx, 1), p3_i(ctx, -2)],
    [p3_i(ctx, -3), p3_i(ctx, -1)],
    [p3_i(ctx, 2), p3_i(ctx, 1)],
  ])
  assert_true(@mpf.mpf_eq(ctx.mnorm(nmat, kind="1"), p3_i(ctx, 6)))
  assert_true(@mpf.mpf_eq(ctx.mnorm(nmat, kind="inf"), p3_i(ctx, 4)))
  assert_close_mpf_str(ctx.mnorm(nmat, kind="F"), "4.472135954999579", "1e-14")

  assert_true(@mpf.mpf_eq(ctx.scalar_abs(p3_i(ctx, -3)), p3_i(ctx, 3)))
  let xv = [p3_i(ctx, 1), p3_i(ctx, -2), p3_i(ctx, 7), p3_i(ctx, -12)]
  assert_true(@mpf.mpf_eq(ctx.vector_norm(xv, p=1), p3_i(ctx, 22)))
  assert_close_mpf_str(ctx.vector_norm(xv, p=2), "14.071247279470288", "1e-12")
  assert_close_mpf_str(ctx.vector_norm(xv, p=10), "12.005463372729799", "1e-10")
  assert_true(@mpf.mpf_eq(ctx.vector_norm(xv, inf=true), p3_i(ctx, 12)))

  let v = ctx.matrix_from_vector([
    p3_i(ctx, 0),
    p3_i(ctx, 1),
    p3_i(ctx, 2),
    p3_i(ctx, 3),
    p3_i(ctx, 4),
  ])
  assert_true(@mpf.mpf_eq(v.vget(3), p3_i(ctx, 3)))
  v.vset(0, p3_i(ctx, -10))
  v.vset(4, p3_i(ctx, 0))
  assert_eq(v.len(), 5)
  p3_assert_matrix_eq(
    ctx.matrix_mul(ctx.matrix_transpose(v), v),
    ctx.matrix_from_rows([[p3_i(ctx, 114)]]),
  )

  let base = ctx.ones(6)
  let b = ctx.matrix_copy(base)
  let c = ctx.matrix_pos(base)
  p3_assert_matrix_eq(base, b)
  p3_assert_matrix_eq(base, c)
  b.set(0, 0, @mpf.fzero)
  c.set(0, 0, p3_i(ctx, 42))
  assert_true(base != b)
  assert_true(base != c)
}

///|
test "p3 matrix conjugate subset from mpmath test_matrices::test_matrix_conjugate" {
  let p = 220
  let i = @mpf.from_int(1)
  let z00 = @mpc.from_parts(i, i)
  let z01 = @mpc.zero()
  let z10 = @mpc.from_parts(@mpf.from_int(2), @mpf.fzero)
  let z11 = @mpc.from_parts(@mpf.fzero, i)

  let c00 = @mpc.mpc_conjugate(z00, p, @mpf.round_nearest)
  let c01 = @mpc.mpc_conjugate(z01, p, @mpf.round_nearest)
  let c10 = @mpc.mpc_conjugate(z10, p, @mpf.round_nearest)
  let c11 = @mpc.mpc_conjugate(z11, p, @mpf.round_nearest)

  assert_eq(c00, @mpc.from_parts(i, @mpf.from_int(-1)))
  assert_eq(c01, @mpc.zero())
  assert_eq(c10, @mpc.from_parts(@mpf.from_int(2), @mpf.fzero))
  assert_eq(c11, @mpc.from_parts(@mpf.fzero, @mpf.from_int(-1)))

  // Hermitian transpose layout check.
  assert_eq(c00, @mpc.from_parts(i, @mpf.from_int(-1)))
  assert_eq(c10, @mpc.from_parts(@mpf.from_int(2), @mpf.fzero))
  assert_eq(c01, @mpc.zero())
  assert_eq(c11, @mpc.from_parts(@mpf.fzero, @mpf.from_int(-1)))
}
