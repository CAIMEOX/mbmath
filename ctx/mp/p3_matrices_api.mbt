///|
fn p3_norm_index(idx : Int, n : Int, name : String) -> Int raise MPError {
  let k0 = if idx < 0 { idx + n } else { idx }
  if k0 < 0 || k0 >= n {
    raise MPError::ValueError("\{name}: index out of range")
  }
  k0
}

///|
fn p3_norm_slice_bound(
  idx : Int?,
  n : Int,
  is_end : Bool,
  name : String,
) -> Int raise MPError {
  let v = match idx {
    Some(x) => if x < 0 { x + n } else { x }
    None => if is_end { n } else { 0 }
  }
  if v < 0 || v > n {
    raise MPError::ValueError("\{name}: slice out of range")
  }
  v
}

///|
fn p3_norm_slice(
  start : Int?,
  end : Int?,
  n : Int,
  name : String,
) -> (Int, Int) raise MPError {
  let s = p3_norm_slice_bound(start, n, false, name)
  let e = p3_norm_slice_bound(end, n, true, name)
  if s > e {
    raise MPError::ValueError("\{name}: invalid slice")
  }
  (s, e)
}

///|
pub fn MPContext::zeros(
  self : MPContext,
  rows : Int,
  cols? : Int = -1,
) -> MpfMatrix raise MPError {
  let c = if cols < 0 { rows } else { cols }
  self.matrix(rows, c)
}

///|
pub fn MPContext::ones(
  self : MPContext,
  rows : Int,
  cols? : Int = -1,
) -> MpfMatrix raise MPError {
  let c = if cols < 0 { rows } else { cols }
  self.matrix(rows, c, fill=@mpf.fone)
}

///|
pub fn MPContext::matrix_from_vector(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  let out = self.matrix(xs.length(), 1)
  for i in 0..<xs.length() {
    out.data[p3_idx(1, i, 0)] = @mpf.mpf_pos(
      xs[i],
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_copy(self : MPContext, a : MpfMatrix) -> MpfMatrix {
  ignore(self)
  { rows: a.rows, cols: a.cols, data: p3_copy_vec(a.data) }
}

///|
pub fn MPContext::matrix_pos(self : MPContext, a : MpfMatrix) -> MpfMatrix {
  self.matrix_copy(a)
}

///|
pub fn MpfMatrix::tolist(self : MpfMatrix) -> Array[Array[@mpf.RawMpf]] {
  let out : Array[Array[@mpf.RawMpf]] = []
  for i in 0..<self.rows {
    let row : Array[@mpf.RawMpf] = []
    for j in 0..<self.cols {
      row.push(self.data[p3_idx(self.cols, i, j)])
    }
    out.push(row)
  }
  out
}

///|
pub fn MpfMatrix::flat(self : MpfMatrix) -> Array[@mpf.RawMpf] {
  p3_copy_vec(self.data)
}

///|
pub fn MpfMatrix::len(self : MpfMatrix) -> Int {
  if self.cols == 1 {
    self.rows
  } else if self.rows == 1 {
    self.cols
  } else {
    self.rows * self.cols
  }
}

///|
fn p3_is_vector(a : MpfMatrix) -> Bool {
  a.cols == 1 || a.rows == 1
}

///|
pub fn MpfMatrix::vget(
  self : MpfMatrix,
  idx : Int,
) -> @mpf.RawMpf raise MPError {
  if !p3_is_vector(self) {
    raise MPError::ValueError("matrix.vget: matrix is not a vector")
  }
  let n = self.len()
  let k = p3_norm_index(idx, n, "matrix.vget")
  if self.cols == 1 {
    self.data[p3_idx(self.cols, k, 0)]
  } else {
    self.data[p3_idx(self.cols, 0, k)]
  }
}

///|
pub fn MpfMatrix::vset(
  self : MpfMatrix,
  idx : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  if !p3_is_vector(self) {
    raise MPError::ValueError("matrix.vset: matrix is not a vector")
  }
  let n = self.len()
  let k = p3_norm_index(idx, n, "matrix.vset")
  if self.cols == 1 {
    self.data[p3_idx(self.cols, k, 0)] = v
  } else {
    self.data[p3_idx(self.cols, 0, k)] = v
  }
}

///|
pub fn MpfMatrix::get_at(
  self : MpfMatrix,
  r : Int,
  c : Int,
) -> @mpf.RawMpf raise MPError {
  let rr = p3_norm_index(r, self.rows, "matrix.get_at")
  let cc = p3_norm_index(c, self.cols, "matrix.get_at")
  self.data[p3_idx(self.cols, rr, cc)]
}

///|
pub fn MpfMatrix::set_at(
  self : MpfMatrix,
  r : Int,
  c : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  let rr = p3_norm_index(r, self.rows, "matrix.set_at")
  let cc = p3_norm_index(c, self.cols, "matrix.set_at")
  self.data[p3_idx(self.cols, rr, cc)] = v
}

///|
pub fn MPContext::matrix_slice(
  self : MPContext,
  a : MpfMatrix,
  row_start? : Int,
  row_end? : Int,
  col_start? : Int,
  col_end? : Int,
) -> MpfMatrix raise MPError {
  ignore(self)
  let (rs, re) = p3_norm_slice(row_start, row_end, a.rows, "matrix_slice")
  let (cs, ce) = p3_norm_slice(col_start, col_end, a.cols, "matrix_slice")
  let out = self.matrix(re - rs, ce - cs)
  for i in 0..<(re - rs) {
    for j in 0..<(ce - cs) {
      out.data[p3_idx(out.cols, i, j)] = a.data[p3_idx(a.cols, rs + i, cs + j)]
    }
  }
  out
}

///|
pub fn MPContext::matrix_set_slice(
  self : MPContext,
  a : MpfMatrix,
  src : MpfMatrix,
  row_start? : Int,
  row_end? : Int,
  col_start? : Int,
  col_end? : Int,
) -> Unit raise MPError {
  ignore(self)
  let (rs, re) = p3_norm_slice(row_start, row_end, a.rows, "matrix_set_slice")
  let (cs, ce) = p3_norm_slice(col_start, col_end, a.cols, "matrix_set_slice")
  if src.rows != re - rs || src.cols != ce - cs {
    raise MPError::ValueError("matrix_set_slice: shape mismatch")
  }
  for i in 0..<src.rows {
    for j in 0..<src.cols {
      a.data[p3_idx(a.cols, rs + i, cs + j)] = src.data[p3_idx(src.cols, i, j)]
    }
  }
}

///|
pub fn MPContext::matrix_set_slice_scalar(
  self : MPContext,
  a : MpfMatrix,
  value : @mpf.RawMpf,
  row_start? : Int,
  row_end? : Int,
  col_start? : Int,
  col_end? : Int,
) -> Unit raise MPError {
  ignore(self)
  let (rs, re) = p3_norm_slice(
    row_start,
    row_end,
    a.rows,
    "matrix_set_slice_scalar",
  )
  let (cs, ce) = p3_norm_slice(
    col_start,
    col_end,
    a.cols,
    "matrix_set_slice_scalar",
  )
  let vv = @mpf.mpf_pos(value, self.precision(), self.round_mode())
  for i in rs..<re {
    for j in cs..<ce {
      a.data[p3_idx(a.cols, i, j)] = vv
    }
  }
}

///|
pub fn MPContext::diag(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  let n = xs.length()
  let out = self.matrix(n, n)
  for i in 0..<n {
    out.data[p3_idx(n, i, i)] = @mpf.mpf_pos(
      xs[i],
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::swap_row(
  self : MPContext,
  a : MpfMatrix,
  r0 : Int,
  r1 : Int,
) -> Unit raise MPError {
  ignore(self)
  let rr0 = p3_norm_index(r0, a.rows, "swap_row")
  let rr1 = p3_norm_index(r1, a.rows, "swap_row")
  p3_swap_rows(a.data, a.cols, rr0, rr1)
}

///|
pub fn MPContext::extend(
  self : MPContext,
  a : MpfMatrix,
  rhs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  if rhs.length() != a.rows {
    raise MPError::ValueError("extend: incompatible rhs length")
  }
  let out = self.matrix(a.rows, a.cols + 1)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      out.data[p3_idx(out.cols, i, j)] = a.data[p3_idx(a.cols, i, j)]
    }
    out.data[p3_idx(out.cols, i, a.cols)] = @mpf.mpf_pos(
      rhs[i],
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_scale(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_mul(a.data[i], c, p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_add_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_add(a.data[i], c, p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_sub_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_sub(a.data[i], c, p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_rsub_scalar(
  self : MPContext,
  c : @mpf.RawMpf,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_sub(c, a.data[i], p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_div_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.p2_work_prec()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_div(a.data[i], c, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      },
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_sum(self : MPContext, a : MpfMatrix) -> @mpf.RawMpf {
  let p = self.p2_work_prec()
  let mut s = @mpf.fzero
  for x in a.data {
    s = @mpf.mpf_add(s, x, p, @mpf.round_nearest)
  }
  @mpf.mpf_pos(s, self.precision(), self.round_mode())
}

///|
pub fn MPContext::matrix_pow(
  self : MPContext,
  a : MpfMatrix,
  n : Int,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("matrix_pow: matrix must be square")
  }
  if n == 0 {
    return self.eye(a.rows)
  }
  if n == 1 {
    return self.matrix_copy(a)
  }
  let mut exp = n
  let mut base = self.matrix_copy(a)
  if n < 0 {
    exp = -n
    base = self.inverse(a)
  }
  let mut acc = self.eye(a.rows)
  while exp > 0 {
    if exp % 2 == 1 {
      acc = self.matrix_mul(acc, base)
    }
    exp = exp / 2
    if exp > 0 {
      base = self.matrix_mul(base, base)
    }
  }
  acc
}

///|
pub fn MPContext::hilbert(self : MPContext, n : Int) -> MpfMatrix raise MPError {
  p3_check_dims(n, n, "hilbert")
  let p = self.p2_work_prec()
  let out = self.matrix(n, n)
  for i in 0..<n {
    for j in 0..<n {
      let denom = @mpf.from_int(i + j + 1)
      out.data[p3_idx(n, i, j)] = @mpf.mpf_pos(
        @mpf.mpf_div(@mpf.fone, denom, p, @mpf.round_nearest) catch {
          err => raise from_mpf_error(err)
        },
        self.precision(),
        self.round_mode(),
      )
    }
  }
  out
}

///|
pub fn MPContext::randmatrix(
  self : MPContext,
  rows : Int,
  cols? : Int = -1,
) -> MpfMatrix raise MPError {
  let c = if cols < 0 { rows } else { cols }
  p3_check_dims(rows, c, "randmatrix")
  let out = self.matrix(rows, c)
  for i in 0..<(rows * c) {
    out.data[i] = @mpf.mpf_pos(
      @mpf.mpf_rand(self.precision()),
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::mnorm(
  self : MPContext,
  a : MpfMatrix,
  kind? : String = "inf",
) -> @mpf.RawMpf raise MPError {
  let k = kind.to_lower()
  match k {
    "1" => self.matrix_norm_1(a)
    "inf" => self.matrix_norm_inf(a)
    "f" => self.matrix_norm_fro(a)
    "fro" => self.matrix_norm_fro(a)
    _ => raise MPError::ValueError("mnorm: unsupported norm '\{kind}'")
  }
}

///|
pub fn MPContext::scalar_abs(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  @mpf.mpf_abs(x, self.precision(), self.round_mode())
}

///|
pub fn MPContext::vector_norm(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
  p? : Int = 2,
  inf? : Bool = false,
) -> @mpf.RawMpf raise MPError {
  let wp = self.p2_work_prec()
  if xs.length() == 0 {
    return @mpf.fzero
  }
  if inf {
    let mut best = @mpf.fzero
    for x in xs {
      let a = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
      if @mpf.mpf_gt(a, best) {
        best = a
      }
    }
    return @mpf.mpf_pos(best, self.precision(), self.round_mode())
  }
  if p <= 0 {
    raise MPError::ValueError("vector_norm: p must be positive")
  }
  if p == 1 {
    let mut s = @mpf.fzero
    for x in xs {
      s = @mpf.mpf_add(
        s,
        @mpf.mpf_abs(x, wp, @mpf.round_nearest),
        wp,
        @mpf.round_nearest,
      )
    }
    return @mpf.mpf_pos(s, self.precision(), self.round_mode())
  }
  if p == 2 {
    let mut s = @mpf.fzero
    for x in xs {
      let a = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
      s = @mpf.mpf_add(
        s,
        @mpf.mpf_mul(a, a, wp, @mpf.round_nearest),
        wp,
        @mpf.round_nearest,
      )
    }
    return @mpf.mpf_sqrt(s, self.precision(), self.round_mode()) catch {
      err => raise from_mpf_error(err)
    }
  }
  fn pow_nonneg(x : @mpf.RawMpf, n : Int, prec : Int) -> @mpf.RawMpf {
    let mut out = @mpf.fone
    for _ in 0..<n {
      out = @mpf.mpf_mul(out, x, prec, @mpf.round_nearest)
    }
    out
  }
  let mut s = @mpf.fzero
  for x in xs {
    let a = @mpf.mpf_abs(x, wp, @mpf.round_nearest)
    s = @mpf.mpf_add(s, pow_nonneg(a, p, wp), wp, @mpf.round_nearest)
  }
  let out = @libelefun.mpf_nthroot(s, p, wp, @mpf.round_nearest) catch {
    _ => raise MPError::DomainError("vector_norm: failed to compute p-th root")
  }
  @mpf.mpf_pos(out, self.precision(), self.round_mode())
}
