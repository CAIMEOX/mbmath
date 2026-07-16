///|
fn m_i(n : Int) -> @mpf.RawMpf {
  @mpf.RawMpf::from_int(n)
}

///|
fn m_interval(a : Int, b : Int) -> RawMpi {
  RawMpi::new(m_i(a), m_i(b))
}

///|
fn m_assert_mpi_matrix_eq(a : RawMpiMatrix, b : RawMpiMatrix) -> Unit raise {
  @debug.assert_eq(a.rows, b.rows)
  @debug.assert_eq(a.cols, b.cols)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      assert_true(a.get(i, j) == b.get(i, j))
    }
  }
}

///|
fn m_mpf_eye_rows(n : Int) -> Array[Array[@mpf.RawMpf]] {
  let rows : Array[Array[@mpf.RawMpf]] = []
  for i in 0..<n {
    let row : Array[@mpf.RawMpf] = []
    for j in 0..<n {
      row.push(if i == j { @mpf.RawMpf::one() } else { @mpf.RawMpf::zero() })
    }
    rows.push(row)
  }
  rows
}

///|
test "mpi_matrix scalar multiplication subset from mpmath test_matrices" {
  let m = RawMpiMatrix::ones(1)

  let a = m_interval(-1, 1)
  @debug.assert_eq(m.scale(a), RawMpiMatrix::from_scalar(a))
  @debug.assert_eq(m.scale(a), RawMpiMatrix::from_scalar(a))

  let c = @mpf.RawMpf::from_int(42)
  @debug.assert_eq(m.scale_real(c), RawMpiMatrix::from_scalar(RawMpi::point(c)))
  @debug.assert_eq(m.scale_real(c), RawMpiMatrix::from_scalar(RawMpi::point(c)))

  let x = @mpf.RawMpf::parse("1.234")
  @debug.assert_eq(m.scale_real(x), RawMpiMatrix::from_scalar(RawMpi::point(x)))
  @debug.assert_eq(m.scale_real(x), RawMpiMatrix::from_scalar(RawMpi::point(x)))

  let b = RawMpci::new(m_interval(-1, 1), m_interval(-2, 2))
  @debug.assert_eq(
    m.scale_complex_interval(b, prec=140),
    RawMpciMatrix::from_scalar(b),
  )
  @debug.assert_eq(
    m.scale_complex_interval(b, prec=140),
    RawMpciMatrix::from_scalar(b),
  )

  let d = @mpc.RawMpc::new(@mpf.RawMpf::from_int(42), @mpf.RawMpf::from_int(84))
  @debug.assert_eq(
    m.scale_complex(d, prec=140),
    RawMpciMatrix::from_complex_scalar(d),
  )
  @debug.assert_eq(
    m.scale_complex(d, prec=140),
    RawMpciMatrix::from_complex_scalar(d),
  )

  let g = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("1.234"),
    @mpf.RawMpf::parse("3.702"),
  )
  @debug.assert_eq(
    m.scale_complex(g, prec=160),
    RawMpciMatrix::from_complex_scalar(g),
  )
  @debug.assert_eq(
    m.scale_complex(g, prec=160),
    RawMpciMatrix::from_complex_scalar(g),
  )
}

///|
test "mpi_matrix conversion subset from mpmath test_matrices" {
  let a = RawMpiMatrix::from_real_rows(m_mpf_eye_rows(3))
  let b = RawMpiMatrix::identity(3)
  m_assert_mpi_matrix_eq(a, b)

  let c = RawMpiMatrix::from_rows(b.to_rows())
  m_assert_mpi_matrix_eq(c, b)

  let d = b.copy()
  m_assert_mpi_matrix_eq(d, b)
}

///|
test "mpi_matrix multiplication bug regression subset from mpmath test_matrices" {
  let x = @mpf.RawMpf::parse("1.00000000000001")
  let a = RawMpiMatrix::from_real_rows([[x]])
  let b = a.copy()
  let c = RawMpiMatrix::from_rows([[RawMpi::point(x)]])
  @debug.assert_eq(b, c)

  let b2 = b.mul(b, prec=53)
  let c2 = c.mul(c, prec=53)
  @debug.assert_eq(b2, c2)

  let b00 = b2.get(0, 0)
  let c00 = c2.get(0, 0)
  let b_delta = b00.width(220)
  let c_delta = c00.width(220)
  assert_true(b_delta > @mpf.RawMpf::parse("1e-16"))
  assert_true(b_delta < @mpf.RawMpf::parse("3e-16"))
  assert_true(c_delta > @mpf.RawMpf::parse("1e-16"))
  assert_true(c_delta < @mpf.RawMpf::parse("3e-16"))

  let exact = @mpf.RawMpf::parse(
    "1.00000000000001998401444325291756783368705994138804689654",
  )
  assert_true(b00.lo <= exact)
  assert_true(b00.hi >= exact)
  assert_true(c00.lo <= exact)
  assert_true(c00.hi >= exact)

  let rhs = RawMpiMatrix::ones(2).add_interval(m_interval(1, 2))
  let prod = RawMpiMatrix::identity(2).mul(rhs, prec=160)
  m_assert_mpi_matrix_eq(
    prod,
    RawMpiMatrix::from_rows([
      [m_interval(2, 3), m_interval(2, 3)],
      [m_interval(2, 3), m_interval(2, 3)],
    ]),
  )
}
