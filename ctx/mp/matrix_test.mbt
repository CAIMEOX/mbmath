///|
fn assert_matrix_equal(a : MpfMatrix, b : MpfMatrix) -> Unit raise {
  @debug.assert_eq(a.rows, b.rows)
  @debug.assert_eq(a.cols, b.cols)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      assert_true(@mpf.mpf_eq(a.get(i, j), b.get(i, j)))
    }
  }
}

///|
fn assert_matrix_close(
  ctx : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
  tol : String,
) -> Unit raise {
  let err = ctx.matrix_norm_inf(ctx.matrix_sub(a, b))
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}

///|
fn matrix_integer(ctx : MPContext, n : Int) -> @mpf.RawMpf {
  ctx.make_int(n)
}

///|
test "matrices basic + matmul subset from mpmath test_matrices" {
  let ctx = new(260, @mpf.round_nearest)

  let a1 = ctx.matrix(3, 3)
  for i in 0..<3 {
    a1.set(i, i, matrix_integer(ctx, 1))
  }
  assert_matrix_equal(a1, ctx.eye(3))
  assert_matrix_equal(a1, ctx.matrix_copy(a1))

  let a2 = ctx.matrix(3, 2)
  @debug.assert_eq(a2.rows, 3)
  @debug.assert_eq(a2.cols, 2)

  let a3 = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2), matrix_integer(ctx, 3)],
    [matrix_integer(ctx, 4), matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
    [matrix_integer(ctx, 7), matrix_integer(ctx, 8), matrix_integer(ctx, 9)],
  ])
  let flat = a3.flat()
  for i in 0..<9 {
    assert_true(@mpf.mpf_eq(flat[i], matrix_integer(ctx, i + 1)))
  }

  a3.set(1, 1, @mpf.fzero)
  assert_true(@mpf.mpf_eq(a3.get(1, 1), @mpf.fzero))

  let a4 = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2), matrix_integer(ctx, 3)],
    [matrix_integer(ctx, 4), matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
  ])
  let a5 = ctx.matrix_from_rows([
    [matrix_integer(ctx, 6), matrix_integer(ctx, -1)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 0), matrix_integer(ctx, -3)],
  ])
  assert_matrix_equal(
    ctx.matrix_mul(a4, a5),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 12), matrix_integer(ctx, -6)],
      [matrix_integer(ctx, 39), matrix_integer(ctx, -12)],
    ]),
  )

  try ctx.matrix_mul(a2, a2) catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected incompatible matrix_mul dimensions")
  }

  let l = [
    [matrix_integer(ctx, 10), matrix_integer(ctx, 20), matrix_integer(ctx, 30)],
    [matrix_integer(ctx, 40), matrix_integer(ctx, 0), matrix_integer(ctx, 60)],
    [matrix_integer(ctx, 70), matrix_integer(ctx, 80), matrix_integer(ctx, 90)],
  ]
  let a6 = ctx.matrix_from_rows(l)
  @debug.assert_eq(a6.tolist(), l)
  assert_matrix_equal(ctx.matrix_scale(a3, matrix_integer(ctx, 10)), a6)

  let a7 = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
    [matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
    [matrix_integer(ctx, 7), matrix_integer(ctx, 8)],
  ])
  let x = ctx.matrix_from_vector([
    matrix_integer(ctx, 10),
    matrix_integer(ctx, -10),
  ])
  assert_matrix_equal(
    ctx.matrix_mul(a7, x),
    ctx.matrix_from_vector([
      matrix_integer(ctx, -10),
      matrix_integer(ctx, -10),
      matrix_integer(ctx, -10),
      matrix_integer(ctx, -10),
    ]),
  )

  let a8 = ctx.ones(5)
  let lhs = ctx.matrix_sub(
    ctx.matrix_add_scalar(a8, matrix_integer(ctx, 1)),
    ctx.matrix_rsub_scalar(matrix_integer(ctx, 2), ctx.zeros(5)),
  )
  assert_true(@mpf.mpf_eq(ctx.matrix_sum(lhs), @mpf.fzero))

  assert_matrix_equal(
    ctx.matrix_sub(
      ctx.matrix_div_scalar(
        ctx.matrix_add_scalar(ctx.ones(4), matrix_integer(ctx, 1)),
        matrix_integer(ctx, 2),
      ),
      ctx.ones(4),
    ),
    ctx.zeros(4),
  )

  assert_matrix_equal(ctx.matrix_pow(ctx.eye(3), 10), ctx.eye(3))
  try ctx.matrix_pow(a7, 2) catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected non-square matrix_pow failure")
  }

  let r1 = ctx.randmatrix(3)
  let r2 = ctx.matrix_copy(r1)
  r1.set(0, 0, matrix_integer(ctx, -100))
  assert_true(r1 != r2)

  let ix = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
    [matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
  ])
  assert_true(@mpf.mpf_eq(ix.get_at(0, -1), matrix_integer(ctx, 2)))
  assert_true(@mpf.mpf_eq(ix.get_at(-1, -1), matrix_integer(ctx, 6)))
  assert_true(@mpf.mpf_eq(ix.get_at(1, -2), matrix_integer(ctx, 3)))
  assert_true(@mpf.mpf_eq(ix.get_at(-3, -2), matrix_integer(ctx, 1)))
  ix.set_at(0, -1, matrix_integer(ctx, 3))
  ix.set_at(-1, -1, matrix_integer(ctx, 4))
  ix.set_at(1, -2, matrix_integer(ctx, 5))
  ix.set_at(-3, -2, matrix_integer(ctx, 1))
  assert_true(@mpf.mpf_eq(ix.get_at(0, -1), matrix_integer(ctx, 3)))
  assert_true(@mpf.mpf_eq(ix.get_at(-1, -1), matrix_integer(ctx, 4)))
  assert_true(@mpf.mpf_eq(ix.get_at(1, -2), matrix_integer(ctx, 5)))
  assert_true(@mpf.mpf_eq(ix.get_at(-3, -2), matrix_integer(ctx, 1)))

  try ctx.zeros(-2) catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected negative matrix dimension failure")
  }
}

///|
test "matrices slice subset from mpmath test_matrices::test_matrix_slices" {
  let ctx = new(260, @mpf.round_nearest)
  let a = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2), matrix_integer(ctx, 3)],
    [matrix_integer(ctx, 4), matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
    [matrix_integer(ctx, 7), matrix_integer(ctx, 8), matrix_integer(ctx, 9)],
  ])
  let v = ctx.matrix_from_vector([
    matrix_integer(ctx, 1),
    matrix_integer(ctx, 2),
    matrix_integer(ctx, 3),
    matrix_integer(ctx, 4),
    matrix_integer(ctx, 5),
  ])

  assert_matrix_equal(ctx.matrix_slice(a), a)
  assert_matrix_equal(
    ctx.matrix_slice(a, col_start=1, col_end=2),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 2)],
      [matrix_integer(ctx, 5)],
      [matrix_integer(ctx, 8)],
    ]),
  )
  assert_matrix_equal(
    ctx.matrix_slice(a, row_start=2, row_end=3),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 7), matrix_integer(ctx, 8), matrix_integer(ctx, 9)],
    ]),
  )
  assert_matrix_equal(
    ctx.matrix_slice(a, row_start=1, row_end=3, col_start=1, col_end=3),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
      [matrix_integer(ctx, 8), matrix_integer(ctx, 9)],
    ]),
  )
  assert_matrix_equal(
    ctx.matrix_slice(a, row_end=2, col_end=2),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
      [matrix_integer(ctx, 4), matrix_integer(ctx, 5)],
    ]),
  )
  assert_matrix_equal(
    ctx.matrix_slice(v, row_start=2, row_end=4),
    ctx.matrix_from_vector([matrix_integer(ctx, 3), matrix_integer(ctx, 4)]),
  )

  try ctx.matrix_slice(a, col_start=1, col_end=6) catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected out-of-range slice end")
  }

  let a1 = ctx.matrix(3, 3)
  ctx.matrix_set_slice(a1, a)
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([
      [
        matrix_integer(ctx, 10),
        matrix_integer(ctx, 11),
        matrix_integer(ctx, 12),
      ],
    ]),
    row_end=1,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 13)],
      [matrix_integer(ctx, 14)],
      [matrix_integer(ctx, 15)],
    ]),
    col_start=2,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a1,
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 16), matrix_integer(ctx, 17)],
      [matrix_integer(ctx, 18), matrix_integer(ctx, 19)],
    ]),
    row_end=2,
    col_end=2,
  )
  assert_matrix_equal(
    a1,
    ctx.matrix_from_rows([
      [
        matrix_integer(ctx, 16),
        matrix_integer(ctx, 17),
        matrix_integer(ctx, 13),
      ],
      [
        matrix_integer(ctx, 18),
        matrix_integer(ctx, 19),
        matrix_integer(ctx, 14),
      ],
      [matrix_integer(ctx, 7), matrix_integer(ctx, 8), matrix_integer(ctx, 15)],
    ]),
  )

  ctx.matrix_set_slice_scalar(
    v,
    matrix_integer(ctx, 10),
    row_start=1,
    row_end=3,
  )
  assert_matrix_equal(
    v,
    ctx.matrix_from_vector([
      matrix_integer(ctx, 1),
      matrix_integer(ctx, 10),
      matrix_integer(ctx, 10),
      matrix_integer(ctx, 4),
      matrix_integer(ctx, 5),
    ]),
  )

  try
    ctx.matrix_set_slice(
      a1,
      ctx.matrix_slice(a, col_start=1, col_end=2),
      row_start=2,
      row_end=3,
      col_end=3,
    )
  catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected shape mismatch in matrix_set_slice")
  }

  try
    ctx.matrix_set_slice(
      a1,
      ctx.matrix_slice(a),
      row_start=2,
      row_end=3,
      col_start=1,
      col_end=20,
    )
  catch {
    ValueError(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected out-of-range assignment slice")
  }

  let a2 = ctx.matrix(3, 3)
  ctx.matrix_set_slice(a2, a)
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([
      [
        matrix_integer(ctx, 10),
        matrix_integer(ctx, 11),
        matrix_integer(ctx, 12),
      ],
    ]),
    row_start=-3,
    row_end=-2,
  )
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 13)],
      [matrix_integer(ctx, 14)],
      [matrix_integer(ctx, 15)],
    ]),
    col_start=-1,
    col_end=3,
  )
  ctx.matrix_set_slice(
    a2,
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 16), matrix_integer(ctx, 17)],
      [matrix_integer(ctx, 18), matrix_integer(ctx, 19)],
    ]),
    row_end=-1,
    col_end=-1,
  )
  assert_matrix_equal(
    a2,
    ctx.matrix_from_rows([
      [
        matrix_integer(ctx, 16),
        matrix_integer(ctx, 17),
        matrix_integer(ctx, 13),
      ],
      [
        matrix_integer(ctx, 18),
        matrix_integer(ctx, 19),
        matrix_integer(ctx, 14),
      ],
      [matrix_integer(ctx, 7), matrix_integer(ctx, 8), matrix_integer(ctx, 15)],
    ]),
  )
}

///|
test "matrices power/transform/creation/norm/vector/copy subset" {
  let ctx = new(280, @mpf.round_nearest)

  let a = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
  ])
  assert_matrix_equal(ctx.matrix_pow(a, 2), ctx.matrix_mul(a, a))
  assert_matrix_equal(
    ctx.matrix_pow(a, 3),
    ctx.matrix_mul(ctx.matrix_mul(a, a), a),
  )
  assert_matrix_close(ctx, ctx.matrix_pow(a, -1), ctx.inverse(a), "1e-22")

  let t = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
    [matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
  ])
  assert_matrix_equal(
    ctx.matrix_transpose(t),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 1), matrix_integer(ctx, 3), matrix_integer(ctx, 5)],
      [matrix_integer(ctx, 2), matrix_integer(ctx, 4), matrix_integer(ctx, 6)],
    ]),
  )
  ctx.swap_row(t, 1, 2)
  assert_matrix_equal(
    t,
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
      [matrix_integer(ctx, 5), matrix_integer(ctx, 6)],
      [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
    ]),
  )

  assert_matrix_equal(
    ctx.augment(ctx.eye(3), [
      matrix_integer(ctx, 1),
      matrix_integer(ctx, 2),
      matrix_integer(ctx, 3),
    ]),
    ctx.matrix_from_rows([
      [
        matrix_integer(ctx, 1),
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 1),
      ],
      [
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 1),
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 2),
      ],
      [
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 0),
        matrix_integer(ctx, 1),
        matrix_integer(ctx, 3),
      ],
    ]),
  )

  assert_matrix_equal(
    ctx.diag([
      matrix_integer(ctx, 1),
      matrix_integer(ctx, 2),
      matrix_integer(ctx, 3),
    ]),
    ctx.matrix_from_rows([
      [matrix_integer(ctx, 1), matrix_integer(ctx, 0), matrix_integer(ctx, 0)],
      [matrix_integer(ctx, 0), matrix_integer(ctx, 2), matrix_integer(ctx, 0)],
      [matrix_integer(ctx, 0), matrix_integer(ctx, 0), matrix_integer(ctx, 3)],
    ]),
  )

  let h = ctx.hilbert(3)
  assert_close_mpf_str(h.get(0, 0), "1", "1e-20")
  assert_close_mpf_str(h.get(0, 1), "0.5", "1e-20")
  assert_close_mpf_str(h.get(2, 2), "0.2", "1e-20")

  let nmat = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, -2)],
    [matrix_integer(ctx, -3), matrix_integer(ctx, -1)],
    [matrix_integer(ctx, 2), matrix_integer(ctx, 1)],
  ])
  assert_true(@mpf.mpf_eq(ctx.mnorm(nmat, kind="1"), matrix_integer(ctx, 6)))
  assert_true(@mpf.mpf_eq(ctx.mnorm(nmat, kind="inf"), matrix_integer(ctx, 4)))
  assert_close_mpf_str(ctx.mnorm(nmat, kind="F"), "4.472135954999579", "1e-14")

  assert_true(
    @mpf.mpf_eq(ctx.scalar_abs(matrix_integer(ctx, -3)), matrix_integer(ctx, 3)),
  )
  let xv = [
    matrix_integer(ctx, 1),
    matrix_integer(ctx, -2),
    matrix_integer(ctx, 7),
    matrix_integer(ctx, -12),
  ]
  assert_true(@mpf.mpf_eq(ctx.vector_norm(xv, p=1), matrix_integer(ctx, 22)))
  assert_close_mpf_str(ctx.vector_norm(xv, p=2), "14.071247279470288", "1e-12")
  assert_close_mpf_str(ctx.vector_norm(xv, p=10), "12.005463372729799", "1e-10")
  assert_true(
    @mpf.mpf_eq(ctx.vector_norm(xv, inf=true), matrix_integer(ctx, 12)),
  )

  let v = ctx.matrix_from_vector([
    matrix_integer(ctx, 0),
    matrix_integer(ctx, 1),
    matrix_integer(ctx, 2),
    matrix_integer(ctx, 3),
    matrix_integer(ctx, 4),
  ])
  assert_true(@mpf.mpf_eq(v.vget(3), matrix_integer(ctx, 3)))
  v.vset(0, matrix_integer(ctx, -10))
  v.vset(4, matrix_integer(ctx, 0))
  @debug.assert_eq(v.len(), 5)
  assert_matrix_equal(
    ctx.matrix_mul(ctx.matrix_transpose(v), v),
    ctx.matrix_from_rows([[matrix_integer(ctx, 114)]]),
  )

  let base = ctx.ones(6)
  let b = ctx.matrix_copy(base)
  let c = ctx.matrix_pos(base)
  assert_matrix_equal(base, b)
  assert_matrix_equal(base, c)
  b.set(0, 0, @mpf.fzero)
  c.set(0, 0, matrix_integer(ctx, 42))
  assert_true(base != b)
  assert_true(base != c)
}

///|
test "matrix conjugate subset from mpmath test_matrices::test_matrix_conjugate" {
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

  @debug.assert_eq(c00, @mpc.from_parts(i, @mpf.from_int(-1)))
  @debug.assert_eq(c01, @mpc.zero())
  @debug.assert_eq(c10, @mpc.from_parts(@mpf.from_int(2), @mpf.fzero))
  @debug.assert_eq(c11, @mpc.from_parts(@mpf.fzero, @mpf.from_int(-1)))

  // Hermitian transpose layout check.
  @debug.assert_eq(c00, @mpc.from_parts(i, @mpf.from_int(-1)))
  @debug.assert_eq(c10, @mpc.from_parts(@mpf.from_int(2), @mpf.fzero))
  @debug.assert_eq(c01, @mpc.zero())
  @debug.assert_eq(c11, @mpc.from_parts(@mpf.fzero, @mpf.from_int(-1)))
}
