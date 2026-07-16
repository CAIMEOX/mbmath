///|
pub struct RawMpiMatrix {
  rows : Int
  cols : Int
  data : Array[RawMpi]
} derive(Debug, Eq)

///|
pub struct RawMpciMatrix {
  rows : Int
  cols : Int
  data : Array[RawMpci]
} derive(Debug, Eq)

///|
fn mpi_matrix_idx(cols : Int, r : Int, c : Int) -> Int {
  r * cols + c
}

///|
fn mpi_matrix_check_dims(
  rows : Int,
  cols : Int,
  name : StringView,
) -> Unit raise MpiError {
  if rows < 0 || cols < 0 {
    raise ValueError("\{name}: dimensions must be non-negative")
  }
}

///|
fn mpi_matrix_copy_data(xs : ArrayView[RawMpi]) -> Array[RawMpi] {
  let out : Array[RawMpi] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn mpci_matrix_copy_data(xs : ArrayView[RawMpci]) -> Array[RawMpci] {
  let out : Array[RawMpci] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn mpi_matrix_filled(rows : Int, cols : Int, fill : RawMpi) -> Array[RawMpi] {
  let out : Array[RawMpi] = []
  for _ in 0..<(rows * cols) {
    out.push(fill)
  }
  out
}

///|
fn mpci_matrix_filled(rows : Int, cols : Int, fill : RawMpci) -> Array[RawMpci] {
  let out : Array[RawMpci] = []
  for _ in 0..<(rows * cols) {
    out.push(fill)
  }
  out
}

///|
fn mpi_matrix_norm_index(
  idx : Int,
  n : Int,
  name : StringView,
) -> Int raise MpiError {
  if idx < 0 || idx >= n {
    raise ValueError("\{name}: index out of range")
  }
  idx
}

///|
pub fn RawMpiMatrix::new(
  rows : Int,
  cols? : Int = -1,
  fill? : RawMpi = RawMpi::zero(),
) -> RawMpiMatrix raise MpiError {
  let c = if cols < 0 { rows } else { cols }
  mpi_matrix_check_dims(rows, c, "RawMpiMatrix::new")
  { rows, cols: c, data: mpi_matrix_filled(rows, c, fill) }
}

///|
pub fn RawMpciMatrix::new(
  rows : Int,
  cols? : Int = -1,
  fill? : RawMpci = RawMpci::zero(),
) -> RawMpciMatrix raise MpiError {
  let c = if cols < 0 { rows } else { cols }
  mpi_matrix_check_dims(rows, c, "RawMpciMatrix::new")
  { rows, cols: c, data: mpci_matrix_filled(rows, c, fill) }
}

///|
pub fn RawMpiMatrix::zeros(
  rows : Int,
  cols? : Int = -1,
) -> RawMpiMatrix raise MpiError {
  RawMpiMatrix::new(rows, cols~)
}

///|
pub fn RawMpiMatrix::ones(
  rows : Int,
  cols? : Int = -1,
) -> RawMpiMatrix raise MpiError {
  RawMpiMatrix::new(rows, cols~, fill=RawMpi::one())
}

///|
pub fn RawMpiMatrix::identity(n : Int) -> RawMpiMatrix raise MpiError {
  mpi_matrix_check_dims(n, n, "RawMpiMatrix::identity")
  let out = RawMpiMatrix::new(n, cols=n)
  for i in 0..<n {
    out.data[mpi_matrix_idx(n, i, i)] = RawMpi::one()
  }
  out
}

///|
pub fn RawMpiMatrix::from_rows(
  rows_data : ArrayView[Array[RawMpi]],
) -> RawMpiMatrix raise MpiError {
  if rows_data.length() == 0 {
    return { rows: 0, cols: 0, data: [] }
  }
  let rows = rows_data.length()
  let cols = rows_data[0].length()
  let data : Array[RawMpi] = []
  for i in 0..<rows {
    let row = rows_data[i]
    if row.length() != cols {
      raise ValueError("RawMpiMatrix::from_rows: ragged rows")
    }
    for x in row {
      data.push(x)
    }
  }
  { rows, cols, data }
}

///|
pub fn RawMpiMatrix::from_real_rows(
  rows_data : ArrayView[Array[@mpf.RawMpf]],
) -> RawMpiMatrix raise MpiError {
  if rows_data.length() == 0 {
    return { rows: 0, cols: 0, data: [] }
  }
  let rows = rows_data.length()
  let cols = rows_data[0].length()
  let data : Array[RawMpi] = []
  for i in 0..<rows {
    let row = rows_data[i]
    if row.length() != cols {
      raise ValueError("RawMpiMatrix::from_real_rows: ragged rows")
    }
    for x in row {
      data.push(RawMpi::point(x))
    }
  }
  { rows, cols, data }
}

///|
pub fn RawMpiMatrix::from_scalar(x : RawMpi) -> RawMpiMatrix {
  { rows: 1, cols: 1, data: [x] }
}

///|
pub fn RawMpiMatrix::copy(a : RawMpiMatrix) -> RawMpiMatrix {
  { rows: a.rows, cols: a.cols, data: mpi_matrix_copy_data(a.data) }
}

///|
pub fn RawMpiMatrix::to_rows(self : RawMpiMatrix) -> Array[Array[RawMpi]] {
  let out : Array[Array[RawMpi]] = []
  for i in 0..<self.rows {
    let row : Array[RawMpi] = []
    for j in 0..<self.cols {
      row.push(self.data[mpi_matrix_idx(self.cols, i, j)])
    }
    out.push(row)
  }
  out
}

///|
pub fn RawMpiMatrix::get(
  self : RawMpiMatrix,
  r : Int,
  c : Int,
) -> RawMpi raise MpiError {
  let rr = mpi_matrix_norm_index(r, self.rows, "RawMpiMatrix::get")
  let cc = mpi_matrix_norm_index(c, self.cols, "RawMpiMatrix::get")
  self.data[mpi_matrix_idx(self.cols, rr, cc)]
}

///|
pub fn RawMpiMatrix::set(
  self : RawMpiMatrix,
  r : Int,
  c : Int,
  v : RawMpi,
) -> Unit raise MpiError {
  let rr = mpi_matrix_norm_index(r, self.rows, "RawMpiMatrix::set")
  let cc = mpi_matrix_norm_index(c, self.cols, "RawMpiMatrix::set")
  self.data[mpi_matrix_idx(self.cols, rr, cc)] = v
}

///|
pub fn RawMpiMatrix::add(
  a : RawMpiMatrix,
  b : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  if a.rows != b.rows || a.cols != b.cols {
    raise ValueError("RawMpiMatrix::add: incompatible dimensions")
  }
  let out = RawMpiMatrix::new(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].add(b.data[i], prec~)
  }
  out
}

///|
pub fn RawMpiMatrix::add_interval(
  a : RawMpiMatrix,
  s : RawMpi,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  let out = RawMpiMatrix::new(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].add(s, prec~)
  }
  out
}

///|
pub fn RawMpiMatrix::scale(
  a : RawMpiMatrix,
  s : RawMpi,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  let wp = if prec > 0 { prec } else { 0 }
  let out = RawMpiMatrix::new(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].mul(s, prec=wp)
  }
  out
}

///|
pub fn RawMpiMatrix::mul(
  a : RawMpiMatrix,
  b : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  if a.cols != b.rows {
    raise ValueError("RawMpiMatrix::mul: incompatible dimensions")
  }
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let out_p = if prec > 0 { prec } else { wp }
  let out = RawMpiMatrix::new(a.rows, cols=b.cols)
  for i in 0..<a.rows {
    for j in 0..<b.cols {
      let mut acc = RawMpi::zero()
      for k in 0..<a.cols {
        let t = a.data[mpi_matrix_idx(a.cols, i, k)].mul(
          b.data[mpi_matrix_idx(b.cols, k, j)],
          prec=wp,
        )
        acc = acc.add(t, prec=wp)
      }
      out.data[mpi_matrix_idx(out.cols, i, j)] = acc.rounded(out_p)
    }
  }
  out
}

///|
pub fn RawMpci::point(z : @mpc.RawMpc) -> RawMpci {
  { real: RawMpi::point(z.real), imag: RawMpi::point(z.imag) }
}

///|
fn mpci_from_mpi_scalar(x : RawMpi) -> RawMpci {
  { real: x, imag: RawMpi::zero() }
}

///|
pub fn RawMpciMatrix::from_scalar(z : RawMpci) -> RawMpciMatrix {
  { rows: 1, cols: 1, data: [z] }
}

///|
pub fn RawMpciMatrix::from_complex_scalar(z : @mpc.RawMpc) -> RawMpciMatrix {
  RawMpciMatrix::from_scalar(RawMpci::point(z))
}

///|
pub fn RawMpciMatrix::from_real_matrix(a : RawMpiMatrix) -> RawMpciMatrix {
  let data : Array[RawMpci] = []
  for x in a.data {
    data.push(mpci_from_mpi_scalar(x))
  }
  { rows: a.rows, cols: a.cols, data }
}

///|
pub fn RawMpciMatrix::copy(a : RawMpciMatrix) -> RawMpciMatrix {
  { rows: a.rows, cols: a.cols, data: mpci_matrix_copy_data(a.data) }
}

///|
pub fn RawMpciMatrix::get(
  self : RawMpciMatrix,
  r : Int,
  c : Int,
) -> RawMpci raise MpiError {
  let rr = mpi_matrix_norm_index(r, self.rows, "RawMpciMatrix::get")
  let cc = mpi_matrix_norm_index(c, self.cols, "RawMpciMatrix::get")
  self.data[mpi_matrix_idx(self.cols, rr, cc)]
}

///|
pub fn RawMpciMatrix::scale(
  a : RawMpciMatrix,
  s : RawMpci,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  let wp = if prec > 0 { prec } else { 80 }
  let out = RawMpciMatrix::new(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].mul(s, wp)
  }
  out
}

///|
pub fn RawMpiMatrix::scale_complex_interval(
  a : RawMpiMatrix,
  s : RawMpci,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  RawMpciMatrix::from_real_matrix(a).scale(s, prec~)
}

///|
pub fn RawMpiMatrix::scale_complex(
  a : RawMpiMatrix,
  s : @mpc.RawMpc,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  a.scale_complex_interval(RawMpci::point(s), prec~)
}

///|
pub fn RawMpiMatrix::scale_real(
  a : RawMpiMatrix,
  s : @mpf.RawMpf,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  a.scale(RawMpi::point(s), prec~)
}
