///|
pub struct MpfMatrix {
  rows : Int
  cols : Int
  data : Array[@mpf.RawMpf]
} derive(Debug, Eq)

///|
fn matrix_offset(cols : Int, r : Int, c : Int) -> Int {
  r * cols + c
}

///|
fn copy_mpf_vector(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn validate_matrix_dimensions(
  rows : Int,
  cols : Int,
  name : StringView,
) -> Unit raise MPError {
  if rows < 0 || cols < 0 {
    raise ValueError("\{name}: dimensions must be non-negative")
  }
}

///|
fn make_filled_matrix_data(
  rows : Int,
  cols : Int,
  fill : @mpf.RawMpf,
) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for _ in 0..<(rows * cols) {
    out.push(fill)
  }
  out
}

///|
fn swap_matrix_rows(
  data : Array[@mpf.RawMpf],
  cols : Int,
  r0 : Int,
  r1 : Int,
) -> Unit {
  if r0 == r1 {
    return
  }
  for j in 0..<cols {
    let i0 = matrix_offset(cols, r0, j)
    let i1 = matrix_offset(cols, r1, j)
    let tmp = data[i0]
    data[i0] = data[i1]
    data[i1] = tmp
  }
}

///|
fn swap_matrix_columns(
  data : Array[@mpf.RawMpf],
  rows : Int,
  cols : Int,
  c0 : Int,
  c1 : Int,
) -> Unit {
  if c0 == c1 {
    return
  }
  for i in 0..<rows {
    let i0 = matrix_offset(cols, i, c0)
    let i1 = matrix_offset(cols, i, c1)
    let tmp = data[i0]
    data[i0] = data[i1]
    data[i1] = tmp
  }
}

///|
fn validate_matrix_index(
  mat : MpfMatrix,
  r : Int,
  c : Int,
  name : StringView,
) -> Int raise MPError {
  if r < 0 || r >= mat.rows || c < 0 || c >= mat.cols {
    raise ValueError("\{name}: index out of range")
  }
  matrix_offset(mat.cols, r, c)
}

///|
pub fn MPContext::matrix(
  self : MPContext,
  rows : Int,
  cols : Int,
  fill? : @mpf.RawMpf = @mpf.RawMpf::zero(),
) -> MpfMatrix raise MPError {
  validate_matrix_dimensions(rows, cols, "matrix")
  let v = fill.rounded(self.precision(), self.round_mode())
  { rows, cols, data: make_filled_matrix_data(rows, cols, v) }
}

///|
pub fn MPContext::matrix_from_rows(
  self : MPContext,
  rows_data : ArrayView[Array[@mpf.RawMpf]],
) -> MpfMatrix raise MPError {
  ignore(self)
  if rows_data.length() == 0 {
    return { rows: 0, cols: 0, data: [] }
  }
  let rows = rows_data.length()
  let cols = rows_data[0].length()
  let data : Array[@mpf.RawMpf] = []
  for i in 0..<rows {
    let row = rows_data[i]
    if row.length() != cols {
      raise ValueError("matrix_from_rows: ragged rows")
    }
    for x in row {
      data.push(x.rounded(self.precision(), self.round_mode()))
    }
  }
  { rows, cols, data }
}

///|
pub fn MPContext::eye(self : MPContext, n : Int) -> MpfMatrix raise MPError {
  validate_matrix_dimensions(n, n, "eye")
  let out = self.matrix(n, n)
  for i in 0..<n {
    out.data[matrix_offset(n, i, i)] = @mpf.RawMpf::one()
  }
  out
}

///|
pub fn MpfMatrix::get(
  self : MpfMatrix,
  r : Int,
  c : Int,
) -> @mpf.RawMpf raise MPError {
  self.data[validate_matrix_index(self, r, c, "matrix.get")]
}

///|
pub fn MpfMatrix::set(
  self : MpfMatrix,
  r : Int,
  c : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  self.data[validate_matrix_index(self, r, c, "matrix.set")] = v
}

///|
pub fn MPContext::matrix_transpose(
  self : MPContext,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  let out = self.matrix(a.cols, a.rows)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      out.data[matrix_offset(out.cols, j, i)] = a.data[matrix_offset(
          a.cols,
          i,
          j,
        )]
    }
  }
  out
}

///|
pub fn MPContext::matrix_add(
  self : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
) -> MpfMatrix raise MPError {
  if a.rows != b.rows || a.cols != b.cols {
    raise ValueError("matrix_add: incompatible dimensions")
  }
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].add(b.data[i], p, Nearest)
  }
  out
}

///|
pub fn MPContext::matrix_sub(
  self : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
) -> MpfMatrix raise MPError {
  if a.rows != b.rows || a.cols != b.cols {
    raise ValueError("matrix_sub: incompatible dimensions")
  }
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i].sub(b.data[i], p, Nearest)
  }
  out
}

///|
pub fn MPContext::matrix_mul(
  self : MPContext,
  a : MpfMatrix,
  b : MpfMatrix,
) -> MpfMatrix raise MPError {
  if a.cols != b.rows {
    raise ValueError("matrix_mul: incompatible dimensions")
  }
  let p = self.working_precision()
  let out = self.matrix(a.rows, b.cols)
  for i in 0..<a.rows {
    for j in 0..<b.cols {
      let mut s = @mpf.RawMpf::zero()
      for k in 0..<a.cols {
        s = s.add(
          a.data[matrix_offset(a.cols, i, k)].mul(
            b.data[matrix_offset(b.cols, k, j)],
            p,
            Nearest,
          ),
          p,
          Nearest,
        )
      }
      out.data[matrix_offset(out.cols, i, j)] = s.rounded(
        self.precision(),
        self.round_mode(),
      )
    }
  }
  out
}

///|
pub fn MPContext::matrix_vec_mul(
  self : MPContext,
  a : MpfMatrix,
  x : ArrayView[@mpf.RawMpf],
) -> Array[@mpf.RawMpf] raise MPError {
  if x.length() != a.cols {
    raise ValueError("matrix_vec_mul: incompatible dimensions")
  }
  let p = self.working_precision()
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<a.rows {
    let mut s = @mpf.RawMpf::zero()
    for j in 0..<a.cols {
      s = s.add(
        a.data[matrix_offset(a.cols, i, j)].mul(x[j], p, Nearest),
        p,
        Nearest,
      )
    }
    out.push(s.rounded(self.precision(), self.round_mode()))
  }
  out
}

///|
pub fn MPContext::matrix_norm_inf(
  self : MPContext,
  a : MpfMatrix,
) -> @mpf.RawMpf {
  let p = self.working_precision()
  let mut best = @mpf.RawMpf::zero()
  for i in 0..<a.rows {
    let mut row_sum = @mpf.RawMpf::zero()
    for j in 0..<a.cols {
      row_sum = row_sum.add(
        a.data[matrix_offset(a.cols, i, j)].abs(p, Nearest),
        p,
        Nearest,
      )
    }
    if row_sum > best {
      best = row_sum
    }
  }
  best.rounded(self.precision(), self.round_mode())
}

///|
pub fn MPContext::lu_solve(
  self : MPContext,
  a : MpfMatrix,
  b : ArrayView[@mpf.RawMpf],
) -> Array[@mpf.RawMpf] raise MPError {
  if a.rows != a.cols {
    raise ValueError("lu_solve: matrix must be square")
  }
  let n = a.rows
  if b.length() != n {
    raise ValueError("lu_solve: incompatible rhs dimension")
  }
  if n == 0 {
    return []
  }
  let p = self.working_precision()
  let data = copy_mpf_vector(a.data)
  let rhs = copy_mpf_vector(b)
  for k in 0..<n {
    let mut pivot = k
    let mut pivot_abs = data[matrix_offset(n, k, k)].abs(p, Nearest)
    for i in (k + 1)..<n {
      let cur = data[matrix_offset(n, i, k)].abs(p, Nearest)
      if cur > pivot_abs {
        pivot = i
        pivot_abs = cur
      }
    }
    if data[matrix_offset(n, pivot, k)].is_zero() {
      raise DomainError("lu_solve: singular matrix")
    }
    if pivot != k {
      swap_matrix_rows(data, n, pivot, k)
      let t = rhs[pivot]
      rhs[pivot] = rhs[k]
      rhs[k] = t
    }
    let akk = data[matrix_offset(n, k, k)]
    for i in (k + 1)..<n {
      let aik = data[matrix_offset(n, i, k)]
      if aik.is_zero() {
        continue
      }
      let factor = checked_mpf_div(aik, akk, p, Nearest)
      for j in k..<n {
        data[matrix_offset(n, i, j)] = data[matrix_offset(n, i, j)].sub(
          factor.mul(data[matrix_offset(n, k, j)], p, Nearest),
          p,
          Nearest,
        )
      }
      rhs[i] = rhs[i].sub(factor.mul(rhs[k], p, Nearest), p, Nearest)
    }
  }
  let x = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = rhs[i]
    for j in (i + 1)..<n {
      s = s.sub(data[matrix_offset(n, i, j)].mul(x[j], p, Nearest), p, Nearest)
    }
    let aii = data[matrix_offset(n, i, i)]
    if aii.is_zero() {
      raise DomainError("lu_solve: singular matrix")
    }
    x[i] = checked_mpf_div(s, aii, p, Nearest).rounded(
      self.precision(),
      self.round_mode(),
    )
  }
  x
}

///|
pub fn MPContext::det(
  self : MPContext,
  a : MpfMatrix,
) -> @mpf.RawMpf raise MPError {
  if a.rows != a.cols {
    raise ValueError("det: matrix must be square")
  }
  let n = a.rows
  if n == 0 {
    return @mpf.RawMpf::one()
  }
  let p = self.working_precision()
  let data = copy_mpf_vector(a.data)
  let mut sign = 1
  for k in 0..<n {
    let mut pivot = k
    let mut pivot_abs = data[matrix_offset(n, k, k)].abs(p, Nearest)
    for i in (k + 1)..<n {
      let cur = data[matrix_offset(n, i, k)].abs(p, Nearest)
      if cur > pivot_abs {
        pivot = i
        pivot_abs = cur
      }
    }
    if data[matrix_offset(n, pivot, k)].is_zero() {
      return @mpf.RawMpf::zero()
    }
    if pivot != k {
      swap_matrix_rows(data, n, pivot, k)
      sign = -sign
    }
    let akk = data[matrix_offset(n, k, k)]
    for i in (k + 1)..<n {
      let aik = data[matrix_offset(n, i, k)]
      if aik.is_zero() {
        continue
      }
      let factor = checked_mpf_div(aik, akk, p, Nearest)
      for j in (k + 1)..<n {
        data[matrix_offset(n, i, j)] = data[matrix_offset(n, i, j)].sub(
          factor.mul(data[matrix_offset(n, k, j)], p, Nearest),
          p,
          Nearest,
        )
      }
      data[matrix_offset(n, i, k)] = @mpf.RawMpf::zero()
    }
  }
  let mut d = @mpf.RawMpf::one()
  for i in 0..<n {
    d = d.mul(data[matrix_offset(n, i, i)], p, Nearest)
  }
  if sign < 0 {
    d = d.negated(p, Nearest)
  }
  d.rounded(self.precision(), self.round_mode())
}

///|
pub fn MPContext::inverse(
  self : MPContext,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise ValueError("inverse: matrix must be square")
  }
  let n = a.rows
  let inv = self.matrix(n, n)
  for j in 0..<n {
    let e = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
    e[j] = @mpf.RawMpf::one()
    let col = self.lu_solve(a, e)
    for i in 0..<n {
      inv.data[matrix_offset(n, i, j)] = col[i]
    }
  }
  inv
}

///|
pub fn MPContext::rank(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
) -> Int raise MPError {
  let m = a.rows
  let n = a.cols
  if m == 0 || n == 0 {
    return 0
  }
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => {
      let s = if self.precision() > 0 { -(self.precision() / 2) } else { -40 }
      @mpf.RawMpf::from_mantissa_exponent(1N, s, 0, Down)
    }
  }
  let data = copy_mpf_vector(a.data)
  let mut row = 0
  for col in 0..<n {
    if row >= m {
      break
    }
    let mut pivot = row
    let mut pivot_abs = @mpf.RawMpf::zero()
    for i in row..<m {
      let cur = data[matrix_offset(n, i, col)].abs(p, Nearest)
      if cur > pivot_abs {
        pivot = i
        pivot_abs = cur
      }
    }
    if pivot_abs <= tol_abs {
      continue
    }
    if pivot != row {
      swap_matrix_rows(data, n, pivot, row)
    }
    let pivot_val = data[matrix_offset(n, row, col)]
    for i in (row + 1)..<m {
      let aic = data[matrix_offset(n, i, col)]
      if aic.abs(p, Nearest) <= tol_abs {
        continue
      }
      let factor = checked_mpf_div(aic, pivot_val, p, Nearest)
      for j in col..<n {
        data[matrix_offset(n, i, j)] = data[matrix_offset(n, i, j)].sub(
          factor.mul(data[matrix_offset(n, row, j)], p, Nearest),
          p,
          Nearest,
        )
      }
    }
    row += 1
  }
  row
}
