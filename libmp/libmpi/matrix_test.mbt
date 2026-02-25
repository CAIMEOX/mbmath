///|
fn m_i(n : Int) -> @mpf.RawMpf {
  @mpf.from_int(n)
}

///|
fn m_interval(a : Int, b : Int) -> RawMpi {
  mpi_make(m_i(a), m_i(b))
}

///|
fn m_assert_mpi_matrix_eq(a : RawMpiMatrix, b : RawMpiMatrix) -> Unit raise {
  assert_eq(a.rows, b.rows)
  assert_eq(a.cols, b.cols)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      assert_true(mpi_eq(a.get(i, j), b.get(i, j)))
    }
  }
}

///|
fn m_mpf_eye_rows(n : Int) -> Array[Array[@mpf.RawMpf]] {
  let rows : Array[Array[@mpf.RawMpf]] = []
  for i in 0..<n {
    let row : Array[@mpf.RawMpf] = []
    for j in 0..<n {
      row.push(if i == j { @mpf.fone } else { @mpf.fzero })
    }
    rows.push(row)
  }
  rows
}

///|
test "mpi_matrix scalar multiplication subset from mpmath test_matrices" {
  let m = mpi_ones(1)

  let a = m_interval(-1, 1)
  assert_eq(mpi_scalar_mul_matrix(a, m), mpi_matrix_from_scalar(a))
  assert_eq(mpi_matrix_mul_scalar(m, a), mpi_matrix_from_scalar(a))

  let c = @mpf.from_int(42)
  assert_eq(
    mpf_scalar_mul_mpi_matrix(c, m),
    mpi_matrix_from_scalar(mpi_from_mpf(c)),
  )
  assert_eq(
    mpi_matrix_mul_mpf_scalar(m, c),
    mpi_matrix_from_scalar(mpi_from_mpf(c)),
  )

  let x = @mpf.from_str("1.234")
  assert_eq(
    mpf_scalar_mul_mpi_matrix(x, m),
    mpi_matrix_from_scalar(mpi_from_mpf(x)),
  )
  assert_eq(
    mpi_matrix_mul_mpf_scalar(m, x),
    mpi_matrix_from_scalar(mpi_from_mpf(x)),
  )

  let b = mpci_make(m_interval(-1, 1), m_interval(-2, 2))
  assert_eq(
    mpci_scalar_mul_mpi_matrix(b, m, prec=140),
    mpci_matrix_from_scalar(b),
  )
  assert_eq(
    mpi_matrix_mul_mpci_scalar(m, b, prec=140),
    mpci_matrix_from_scalar(b),
  )

  let d = @mpc.from_parts(@mpf.from_int(42), @mpf.from_int(84))
  assert_eq(
    mpc_scalar_mul_mpi_matrix(d, m, prec=140),
    mpci_matrix_from_mpc_scalar(d),
  )
  assert_eq(
    mpi_matrix_mul_mpc_scalar(m, d, prec=140),
    mpci_matrix_from_mpc_scalar(d),
  )

  let g = @mpc.from_parts(@mpf.from_str("1.234"), @mpf.from_str("3.702"))
  assert_eq(
    mpc_scalar_mul_mpi_matrix(g, m, prec=160),
    mpci_matrix_from_mpc_scalar(g),
  )
  assert_eq(
    mpi_matrix_mul_mpc_scalar(m, g, prec=160),
    mpci_matrix_from_mpc_scalar(g),
  )
}

///|
test "mpi_matrix conversion subset from mpmath test_matrices" {
  let a = mpi_matrix_from_mpf_rows(m_mpf_eye_rows(3))
  let b = mpi_eye(3)
  m_assert_mpi_matrix_eq(a, b)

  let c = mpi_matrix_from_rows(b.tolist())
  m_assert_mpi_matrix_eq(c, b)

  let d = mpi_matrix_copy(b)
  m_assert_mpi_matrix_eq(d, b)
}

///|
test "mpi_matrix multiplication bug regression subset from mpmath test_matrices" {
  let x = @mpf.from_str("1.00000000000001")
  let a = mpi_matrix_from_mpf_rows([[x]])
  let b = mpi_matrix_copy(a)
  let c = mpi_matrix_from_rows([[mpi_from_mpf(x)]])
  assert_eq(b, c)

  let b2 = mpi_matrix_mul(b, b, prec=53)
  let c2 = mpi_matrix_mul(c, c, prec=53)
  assert_eq(b2, c2)

  let b00 = b2.get(0, 0)
  let c00 = c2.get(0, 0)
  let b_delta = mpi_delta(b00, 220)
  let c_delta = mpi_delta(c00, 220)
  assert_true(@mpf.mpf_gt(b_delta, @mpf.from_str("1e-16")))
  assert_true(@mpf.mpf_lt(b_delta, @mpf.from_str("3e-16")))
  assert_true(@mpf.mpf_gt(c_delta, @mpf.from_str("1e-16")))
  assert_true(@mpf.mpf_lt(c_delta, @mpf.from_str("3e-16")))

  let exact = @mpf.from_str(
    "1.00000000000001998401444325291756783368705994138804689654",
  )
  assert_true(@mpf.mpf_le(b00.lo, exact))
  assert_true(@mpf.mpf_ge(b00.hi, exact))
  assert_true(@mpf.mpf_le(c00.lo, exact))
  assert_true(@mpf.mpf_ge(c00.hi, exact))

  let rhs = mpi_matrix_add_scalar(mpi_ones(2), m_interval(1, 2))
  let prod = mpi_matrix_mul(mpi_eye(2), rhs, prec=160)
  m_assert_mpi_matrix_eq(
    prod,
    mpi_matrix_from_rows([
      [m_interval(2, 3), m_interval(2, 3)],
      [m_interval(2, 3), m_interval(2, 3)],
    ]),
  )
}
