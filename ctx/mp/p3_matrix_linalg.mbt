///|
pub struct MpfMatrix {
  rows : Int
  cols : Int
  data : Array[@mpf.RawMpf]
} derive(Show, Eq)

///|
fn p3_idx(cols : Int, r : Int, c : Int) -> Int {
  r * cols + c
}

///|
fn p3_copy_vec(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn p3_check_dims(rows : Int, cols : Int, name : String) -> Unit raise MPError {
  if rows < 0 || cols < 0 {
    raise MPError::ValueError("\{name}: dimensions must be non-negative")
  }
}

///|
fn p3_matrix_data_with_fill(
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
fn p3_swap_rows(
  data : Array[@mpf.RawMpf],
  cols : Int,
  r0 : Int,
  r1 : Int,
) -> Unit {
  if r0 == r1 {
    return
  }
  for j in 0..<cols {
    let i0 = p3_idx(cols, r0, j)
    let i1 = p3_idx(cols, r1, j)
    let tmp = data[i0]
    data[i0] = data[i1]
    data[i1] = tmp
  }
}

///|
fn p3_swap_cols(
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
    let i0 = p3_idx(cols, i, c0)
    let i1 = p3_idx(cols, i, c1)
    let tmp = data[i0]
    data[i0] = data[i1]
    data[i1] = tmp
  }
}

///|
fn p3_check_index(
  mat : MpfMatrix,
  r : Int,
  c : Int,
  name : String,
) -> Int raise MPError {
  if r < 0 || r >= mat.rows || c < 0 || c >= mat.cols {
    raise MPError::ValueError("\{name}: index out of range")
  }
  p3_idx(mat.cols, r, c)
}

///|
pub fn MPContext::matrix(
  self : MPContext,
  rows : Int,
  cols : Int,
  fill? : @mpf.RawMpf = @mpf.fzero,
) -> MpfMatrix raise MPError {
  p3_check_dims(rows, cols, "matrix")
  let v = @mpf.mpf_pos(fill, self.precision(), self.round_mode())
  { rows, cols, data: p3_matrix_data_with_fill(rows, cols, v) }
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
      raise MPError::ValueError("matrix_from_rows: ragged rows")
    }
    for x in row {
      data.push(@mpf.mpf_pos(x, self.precision(), self.round_mode()))
    }
  }
  { rows, cols, data }
}

///|
pub fn MPContext::eye(self : MPContext, n : Int) -> MpfMatrix raise MPError {
  p3_check_dims(n, n, "eye")
  let out = self.matrix(n, n)
  for i in 0..<n {
    out.data[p3_idx(n, i, i)] = @mpf.fone
  }
  out
}

///|
pub fn MpfMatrix::get(
  self : MpfMatrix,
  r : Int,
  c : Int,
) -> @mpf.RawMpf raise MPError {
  self.data[p3_check_index(self, r, c, "matrix.get")]
}

///|
pub fn MpfMatrix::set(
  self : MpfMatrix,
  r : Int,
  c : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  self.data[p3_check_index(self, r, c, "matrix.set")] = v
}

///|
pub fn MPContext::matrix_transpose(
  self : MPContext,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  let out = self.matrix(a.cols, a.rows)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      out.data[p3_idx(out.cols, j, i)] = a.data[p3_idx(a.cols, i, j)]
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
    raise MPError::ValueError("matrix_add: incompatible dimensions")
  }
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_add(a.data[i], b.data[i], p, @mpf.round_nearest)
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
    raise MPError::ValueError("matrix_sub: incompatible dimensions")
  }
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_sub(a.data[i], b.data[i], p, @mpf.round_nearest)
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
    raise MPError::ValueError("matrix_mul: incompatible dimensions")
  }
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, b.cols)
  for i in 0..<a.rows {
    for j in 0..<b.cols {
      let mut s = @mpf.fzero
      for k in 0..<a.cols {
        s = @mpf.mpf_add(
          s,
          @mpf.mpf_mul(
            a.data[p3_idx(a.cols, i, k)],
            b.data[p3_idx(b.cols, k, j)],
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
      out.data[p3_idx(out.cols, i, j)] = @mpf.mpf_pos(
        s,
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
    raise MPError::ValueError("matrix_vec_mul: incompatible dimensions")
  }
  let p = self.p2_work_prec()
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<a.rows {
    let mut s = @mpf.fzero
    for j in 0..<a.cols {
      s = @mpf.mpf_add(
        s,
        @mpf.mpf_mul(a.data[p3_idx(a.cols, i, j)], x[j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    out.push(@mpf.mpf_pos(s, self.precision(), self.round_mode()))
  }
  out
}

///|
pub fn MPContext::matrix_norm_inf(
  self : MPContext,
  a : MpfMatrix,
) -> @mpf.RawMpf {
  let p = self.p2_work_prec()
  let mut best = @mpf.fzero
  for i in 0..<a.rows {
    let mut row_sum = @mpf.fzero
    for j in 0..<a.cols {
      row_sum = @mpf.mpf_add(
        row_sum,
        @mpf.mpf_abs(a.data[p3_idx(a.cols, i, j)], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    if @mpf.mpf_gt(row_sum, best) {
      best = row_sum
    }
  }
  @mpf.mpf_pos(best, self.precision(), self.round_mode())
}

///|
pub fn MPContext::lu_solve(
  self : MPContext,
  a : MpfMatrix,
  b : ArrayView[@mpf.RawMpf],
) -> Array[@mpf.RawMpf] raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("lu_solve: matrix must be square")
  }
  let n = a.rows
  if b.length() != n {
    raise MPError::ValueError("lu_solve: incompatible rhs dimension")
  }
  if n == 0 {
    return []
  }
  let p = self.p2_work_prec()
  let data = p3_copy_vec(a.data)
  let rhs = p3_copy_vec(b)
  for k in 0..<n {
    let mut pivot = k
    let mut pivot_abs = @mpf.mpf_abs(
      data[p3_idx(n, k, k)],
      p,
      @mpf.round_nearest,
    )
    for i in (k + 1)..<n {
      let cur = @mpf.mpf_abs(data[p3_idx(n, i, k)], p, @mpf.round_nearest)
      if @mpf.mpf_gt(cur, pivot_abs) {
        pivot = i
        pivot_abs = cur
      }
    }
    if @mpf.is_zero(data[p3_idx(n, pivot, k)]) {
      raise MPError::DomainError("lu_solve: singular matrix")
    }
    if pivot != k {
      p3_swap_rows(data, n, pivot, k)
      let t = rhs[pivot]
      rhs[pivot] = rhs[k]
      rhs[k] = t
    }
    let akk = data[p3_idx(n, k, k)]
    for i in (k + 1)..<n {
      let aik = data[p3_idx(n, i, k)]
      if @mpf.is_zero(aik) {
        continue
      }
      let factor = p2_mpf_div(aik, akk, p, @mpf.round_nearest)
      for j in k..<n {
        data[p3_idx(n, i, j)] = @mpf.mpf_sub(
          data[p3_idx(n, i, j)],
          @mpf.mpf_mul(factor, data[p3_idx(n, k, j)], p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
      rhs[i] = @mpf.mpf_sub(
        rhs[i],
        @mpf.mpf_mul(factor, rhs[k], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
  }
  let x = p3_matrix_data_with_fill(1, n, @mpf.fzero)
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = rhs[i]
    for j in (i + 1)..<n {
      s = @mpf.mpf_sub(
        s,
        @mpf.mpf_mul(data[p3_idx(n, i, j)], x[j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let aii = data[p3_idx(n, i, i)]
    if @mpf.is_zero(aii) {
      raise MPError::DomainError("lu_solve: singular matrix")
    }
    x[i] = @mpf.mpf_pos(
      p2_mpf_div(s, aii, p, @mpf.round_nearest),
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
    raise MPError::ValueError("det: matrix must be square")
  }
  let n = a.rows
  if n == 0 {
    return @mpf.fone
  }
  let p = self.p2_work_prec()
  let data = p3_copy_vec(a.data)
  let mut sign = 1
  for k in 0..<n {
    let mut pivot = k
    let mut pivot_abs = @mpf.mpf_abs(
      data[p3_idx(n, k, k)],
      p,
      @mpf.round_nearest,
    )
    for i in (k + 1)..<n {
      let cur = @mpf.mpf_abs(data[p3_idx(n, i, k)], p, @mpf.round_nearest)
      if @mpf.mpf_gt(cur, pivot_abs) {
        pivot = i
        pivot_abs = cur
      }
    }
    if @mpf.is_zero(data[p3_idx(n, pivot, k)]) {
      return @mpf.fzero
    }
    if pivot != k {
      p3_swap_rows(data, n, pivot, k)
      sign = -sign
    }
    let akk = data[p3_idx(n, k, k)]
    for i in (k + 1)..<n {
      let aik = data[p3_idx(n, i, k)]
      if @mpf.is_zero(aik) {
        continue
      }
      let factor = p2_mpf_div(aik, akk, p, @mpf.round_nearest)
      for j in (k + 1)..<n {
        data[p3_idx(n, i, j)] = @mpf.mpf_sub(
          data[p3_idx(n, i, j)],
          @mpf.mpf_mul(factor, data[p3_idx(n, k, j)], p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
      data[p3_idx(n, i, k)] = @mpf.fzero
    }
  }
  let mut d = @mpf.fone
  for i in 0..<n {
    d = @mpf.mpf_mul(d, data[p3_idx(n, i, i)], p, @mpf.round_nearest)
  }
  if sign < 0 {
    d = @mpf.mpf_neg(d, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(d, self.precision(), self.round_mode())
}

///|
pub fn MPContext::inverse(
  self : MPContext,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("inverse: matrix must be square")
  }
  let n = a.rows
  let inv = self.matrix(n, n)
  for j in 0..<n {
    let e = p3_matrix_data_with_fill(1, n, @mpf.fzero)
    e[j] = @mpf.fone
    let col = self.lu_solve(a, e)
    for i in 0..<n {
      inv.data[p3_idx(n, i, j)] = col[i]
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
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => {
      let s = if self.precision() > 0 { -(self.precision() / 2) } else { -40 }
      @mpf.from_man_exp(1N, s, 0, @mpf.round_down)
    }
  }
  let data = p3_copy_vec(a.data)
  let mut row = 0
  for col in 0..<n {
    if row >= m {
      break
    }
    let mut pivot = row
    let mut pivot_abs = @mpf.fzero
    for i in row..<m {
      let cur = @mpf.mpf_abs(data[p3_idx(n, i, col)], p, @mpf.round_nearest)
      if @mpf.mpf_gt(cur, pivot_abs) {
        pivot = i
        pivot_abs = cur
      }
    }
    if @mpf.mpf_le(pivot_abs, tol_abs) {
      continue
    }
    if pivot != row {
      p3_swap_rows(data, n, pivot, row)
    }
    let pivot_val = data[p3_idx(n, row, col)]
    for i in (row + 1)..<m {
      let aic = data[p3_idx(n, i, col)]
      if @mpf.mpf_le(@mpf.mpf_abs(aic, p, @mpf.round_nearest), tol_abs) {
        continue
      }
      let factor = p2_mpf_div(aic, pivot_val, p, @mpf.round_nearest)
      for j in col..<n {
        data[p3_idx(n, i, j)] = @mpf.mpf_sub(
          data[p3_idx(n, i, j)],
          @mpf.mpf_mul(factor, data[p3_idx(n, row, j)], p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
    }
    row += 1
  }
  row
}
