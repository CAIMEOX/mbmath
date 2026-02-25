///|
pub struct RawMpiMatrix {
  rows : Int
  cols : Int
  data : Array[RawMpi]
} derive(Show, Eq)

///|
pub struct RawMpciMatrix {
  rows : Int
  cols : Int
  data : Array[RawMpci]
} derive(Show, Eq)

///|
fn mpi_matrix_idx(cols : Int, r : Int, c : Int) -> Int {
  r * cols + c
}

///|
fn mpi_matrix_check_dims(
  rows : Int,
  cols : Int,
  name : String,
) -> Unit raise MpiError {
  if rows < 0 || cols < 0 {
    raise MpiError::ValueError("\{name}: dimensions must be non-negative")
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
  name : String,
) -> Int raise MpiError {
  if idx < 0 || idx >= n {
    raise MpiError::ValueError("\{name}: index out of range")
  }
  idx
}

///|
pub fn mpi_matrix(
  rows : Int,
  cols? : Int = -1,
  fill? : RawMpi = mpi_zero,
) -> RawMpiMatrix raise MpiError {
  let c = if cols < 0 { rows } else { cols }
  mpi_matrix_check_dims(rows, c, "mpi_matrix")
  { rows, cols: c, data: mpi_matrix_filled(rows, c, fill) }
}

///|
pub fn mpci_matrix(
  rows : Int,
  cols? : Int = -1,
  fill? : RawMpci = mpci_zero,
) -> RawMpciMatrix raise MpiError {
  let c = if cols < 0 { rows } else { cols }
  mpi_matrix_check_dims(rows, c, "mpci_matrix")
  { rows, cols: c, data: mpci_matrix_filled(rows, c, fill) }
}

///|
pub fn mpi_zeros(rows : Int, cols? : Int = -1) -> RawMpiMatrix raise MpiError {
  mpi_matrix(rows, cols~)
}

///|
pub fn mpi_ones(rows : Int, cols? : Int = -1) -> RawMpiMatrix raise MpiError {
  mpi_matrix(rows, cols~, fill=mpi_one)
}

///|
pub fn mpi_eye(n : Int) -> RawMpiMatrix raise MpiError {
  mpi_matrix_check_dims(n, n, "mpi_eye")
  let out = mpi_matrix(n, cols=n)
  for i in 0..<n {
    out.data[mpi_matrix_idx(n, i, i)] = mpi_one
  }
  out
}

///|
pub fn mpi_matrix_from_rows(
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
      raise MpiError::ValueError("mpi_matrix_from_rows: ragged rows")
    }
    for x in row {
      data.push(x)
    }
  }
  { rows, cols, data }
}

///|
pub fn mpi_matrix_from_mpf_rows(
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
      raise MpiError::ValueError("mpi_matrix_from_mpf_rows: ragged rows")
    }
    for x in row {
      data.push(mpi_from_mpf(x))
    }
  }
  { rows, cols, data }
}

///|
pub fn mpi_matrix_from_scalar(x : RawMpi) -> RawMpiMatrix {
  { rows: 1, cols: 1, data: [x] }
}

///|
pub fn mpi_matrix_copy(a : RawMpiMatrix) -> RawMpiMatrix {
  { rows: a.rows, cols: a.cols, data: mpi_matrix_copy_data(a.data) }
}

///|
pub fn RawMpiMatrix::tolist(self : RawMpiMatrix) -> Array[Array[RawMpi]] {
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
pub fn mpi_matrix_add(
  a : RawMpiMatrix,
  b : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  if a.rows != b.rows || a.cols != b.cols {
    raise MpiError::ValueError("mpi_matrix_add: incompatible dimensions")
  }
  let out = mpi_matrix(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = mpi_add(a.data[i], b.data[i], prec~)
  }
  out
}

///|
pub fn mpi_matrix_add_scalar(
  a : RawMpiMatrix,
  s : RawMpi,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  let out = mpi_matrix(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = mpi_add(a.data[i], s, prec~)
  }
  out
}

///|
pub fn mpi_matrix_mul_scalar(
  a : RawMpiMatrix,
  s : RawMpi,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  let wp = if prec > 0 { prec } else { 0 }
  let out = mpi_matrix(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = mpi_mul(a.data[i], s, prec=wp)
  }
  out
}

///|
pub fn mpi_scalar_mul_matrix(
  s : RawMpi,
  a : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  mpi_matrix_mul_scalar(a, s, prec~)
}

///|
pub fn mpi_matrix_mul(
  a : RawMpiMatrix,
  b : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  if a.cols != b.rows {
    raise MpiError::ValueError("mpi_matrix_mul: incompatible dimensions")
  }
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let out_p = if prec > 0 { prec } else { wp }
  let out = mpi_matrix(a.rows, cols=b.cols)
  for i in 0..<a.rows {
    for j in 0..<b.cols {
      let mut acc = mpi_zero
      for k in 0..<a.cols {
        let t = mpi_mul(
          a.data[mpi_matrix_idx(a.cols, i, k)],
          b.data[mpi_matrix_idx(b.cols, k, j)],
          prec=wp,
        )
        acc = mpi_add(acc, t, prec=wp)
      }
      out.data[mpi_matrix_idx(out.cols, i, j)] = mpi_pos(acc, out_p)
    }
  }
  out
}

///|
pub fn mpci_from_mpc(z : @mpc.RawMpc) -> RawMpci {
  { real: mpi_from_mpf(z.real), imag: mpi_from_mpf(z.imag) }
}

///|
fn mpci_from_mpi_scalar(x : RawMpi) -> RawMpci {
  { real: x, imag: mpi_zero }
}

///|
pub fn mpci_matrix_from_scalar(z : RawMpci) -> RawMpciMatrix {
  { rows: 1, cols: 1, data: [z] }
}

///|
pub fn mpci_matrix_from_mpc_scalar(z : @mpc.RawMpc) -> RawMpciMatrix {
  mpci_matrix_from_scalar(mpci_from_mpc(z))
}

///|
pub fn mpci_matrix_from_mpi_matrix(a : RawMpiMatrix) -> RawMpciMatrix {
  let data : Array[RawMpci] = []
  for x in a.data {
    data.push(mpci_from_mpi_scalar(x))
  }
  { rows: a.rows, cols: a.cols, data }
}

///|
pub fn mpci_matrix_copy(a : RawMpciMatrix) -> RawMpciMatrix {
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
pub fn mpci_matrix_mul_scalar(
  a : RawMpciMatrix,
  s : RawMpci,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  let wp = if prec > 0 { prec } else { 80 }
  let out = mpci_matrix(a.rows, cols=a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = mpci_mul(a.data[i], s, wp)
  }
  out
}

///|
pub fn mpci_scalar_mul_matrix(
  s : RawMpci,
  a : RawMpciMatrix,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  mpci_matrix_mul_scalar(a, s, prec~)
}

///|
pub fn mpi_matrix_mul_mpci_scalar(
  a : RawMpiMatrix,
  s : RawMpci,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  mpci_matrix_mul_scalar(mpci_matrix_from_mpi_matrix(a), s, prec~)
}

///|
pub fn mpci_scalar_mul_mpi_matrix(
  s : RawMpci,
  a : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  mpci_scalar_mul_matrix(s, mpci_matrix_from_mpi_matrix(a), prec~)
}

///|
pub fn mpi_matrix_mul_mpc_scalar(
  a : RawMpiMatrix,
  s : @mpc.RawMpc,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  mpi_matrix_mul_mpci_scalar(a, mpci_from_mpc(s), prec~)
}

///|
pub fn mpc_scalar_mul_mpi_matrix(
  s : @mpc.RawMpc,
  a : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpciMatrix raise MpiError {
  mpci_scalar_mul_mpi_matrix(mpci_from_mpc(s), a, prec~)
}

///|
pub fn mpi_matrix_mul_mpf_scalar(
  a : RawMpiMatrix,
  s : @mpf.RawMpf,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  mpi_matrix_mul_scalar(a, mpi_from_mpf(s), prec~)
}

///|
pub fn mpf_scalar_mul_mpi_matrix(
  s : @mpf.RawMpf,
  a : RawMpiMatrix,
  prec? : Int = 0,
) -> RawMpiMatrix raise MpiError {
  mpi_scalar_mul_matrix(mpi_from_mpf(s), a, prec~)
}
