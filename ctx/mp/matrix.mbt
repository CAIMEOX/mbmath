///|
fn normalize_matrix_index(
  idx : Int,
  n : Int,
  name : StringView,
) -> Int raise MPError {
  let k0 = if idx < 0 { idx + n } else { idx }
  if k0 < 0 || k0 >= n {
    raise ValueError("\{name}: index out of range")
  }
  k0
}

///|
fn normalize_matrix_slice_bound(
  idx : Int?,
  n : Int,
  is_end : Bool,
  name : StringView,
) -> Int raise MPError {
  let v = match idx {
    Some(x) => if x < 0 { x + n } else { x }
    None => if is_end { n } else { 0 }
  }
  if v < 0 || v > n {
    raise ValueError("\{name}: slice out of range")
  }
  v
}

///|
fn normalize_matrix_slice(
  start : Int?,
  end : Int?,
  n : Int,
  name : StringView,
) -> (Int, Int) raise MPError {
  let s = normalize_matrix_slice_bound(start, n, false, name)
  let e = normalize_matrix_slice_bound(end, n, true, name)
  if s > e {
    raise ValueError("\{name}: invalid slice")
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
  self.matrix(rows, c, fill=@mpf.RawMpf::one())
}

///|
pub fn MPContext::matrix_from_vector(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  let out = self.matrix(xs.length(), 1)
  for i in 0..<xs.length() {
    out.data[matrix_offset(1, i, 0)] = xs[i].rounded(
      self.precision(),
      self.round_mode(),
    )
  }
  out
}

///|
pub fn MPContext::matrix_copy(self : MPContext, a : MpfMatrix) -> MpfMatrix {
  ignore(self)
  { rows: a.rows, cols: a.cols, data: copy_mpf_vector(a.data) }
}

///|
pub fn MPContext::matrix_pos(self : MPContext, a : MpfMatrix) -> MpfMatrix {
  self.matrix_copy(a)
}

///|
pub fn MpfMatrix::to_rows(self : MpfMatrix) -> Array[Array[@mpf.RawMpf]] {
  let out : Array[Array[@mpf.RawMpf]] = []
  for i in 0..<self.rows {
    let row : Array[@mpf.RawMpf] = []
    for j in 0..<self.cols {
      row.push(self.data[matrix_offset(self.cols, i, j)])
    }
    out.push(row)
  }
  out
}

///|
pub fn MpfMatrix::flat(self : MpfMatrix) -> Array[@mpf.RawMpf] {
  copy_mpf_vector(self.data)
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
fn is_vector_matrix(a : MpfMatrix) -> Bool {
  a.cols == 1 || a.rows == 1
}

///|
pub fn MpfMatrix::vget(
  self : MpfMatrix,
  idx : Int,
) -> @mpf.RawMpf raise MPError {
  if !is_vector_matrix(self) {
    raise ValueError("matrix.vget: matrix is not a vector")
  }
  let n = self.len()
  let k = normalize_matrix_index(idx, n, "matrix.vget")
  if self.cols == 1 {
    self.data[matrix_offset(self.cols, k, 0)]
  } else {
    self.data[matrix_offset(self.cols, 0, k)]
  }
}

///|
pub fn MpfMatrix::vset(
  self : MpfMatrix,
  idx : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  if !is_vector_matrix(self) {
    raise ValueError("matrix.vset: matrix is not a vector")
  }
  let n = self.len()
  let k = normalize_matrix_index(idx, n, "matrix.vset")
  if self.cols == 1 {
    self.data[matrix_offset(self.cols, k, 0)] = v
  } else {
    self.data[matrix_offset(self.cols, 0, k)] = v
  }
}

///|
pub fn MpfMatrix::get_at(
  self : MpfMatrix,
  r : Int,
  c : Int,
) -> @mpf.RawMpf raise MPError {
  let rr = normalize_matrix_index(r, self.rows, "matrix.get_at")
  let cc = normalize_matrix_index(c, self.cols, "matrix.get_at")
  self.data[matrix_offset(self.cols, rr, cc)]
}

///|
pub fn MpfMatrix::set_at(
  self : MpfMatrix,
  r : Int,
  c : Int,
  v : @mpf.RawMpf,
) -> Unit raise MPError {
  let rr = normalize_matrix_index(r, self.rows, "matrix.set_at")
  let cc = normalize_matrix_index(c, self.cols, "matrix.set_at")
  self.data[matrix_offset(self.cols, rr, cc)] = v
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
  let (rs, re) = normalize_matrix_slice(
    row_start,
    row_end,
    a.rows,
    "matrix_slice",
  )
  let (cs, ce) = normalize_matrix_slice(
    col_start,
    col_end,
    a.cols,
    "matrix_slice",
  )
  let out = self.matrix(re - rs, ce - cs)
  for i in 0..<(re - rs) {
    for j in 0..<(ce - cs) {
      out.data[matrix_offset(out.cols, i, j)] = a.data[matrix_offset(
          a.cols,
          rs + i,
          cs + j,
        )]
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
  let (rs, re) = normalize_matrix_slice(
    row_start,
    row_end,
    a.rows,
    "matrix_set_slice",
  )
  let (cs, ce) = normalize_matrix_slice(
    col_start,
    col_end,
    a.cols,
    "matrix_set_slice",
  )
  if src.rows != re - rs || src.cols != ce - cs {
    raise ValueError("matrix_set_slice: shape mismatch")
  }
  for i in 0..<src.rows {
    for j in 0..<src.cols {
      a.data[matrix_offset(a.cols, rs + i, cs + j)] = src.data[matrix_offset(
          src.cols,
          i,
          j,
        )]
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
  let (rs, re) = normalize_matrix_slice(
    row_start,
    row_end,
    a.rows,
    "matrix_set_slice_scalar",
  )
  let (cs, ce) = normalize_matrix_slice(
    col_start,
    col_end,
    a.cols,
    "matrix_set_slice_scalar",
  )
  let vv = value.rounded(self.precision(), self.round_mode())
  for i in rs..<re {
    for j in cs..<ce {
      a.data[matrix_offset(a.cols, i, j)] = vv
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
    out.data[matrix_offset(n, i, i)] = xs[i].rounded(
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
  let rr0 = normalize_matrix_index(r0, a.rows, "swap_row")
  let rr1 = normalize_matrix_index(r1, a.rows, "swap_row")
  swap_matrix_rows(a.data, a.cols, rr0, rr1)
}

///|
#alias(extend, deprecated)
pub fn MPContext::augment(
  self : MPContext,
  a : MpfMatrix,
  rhs : ArrayView[@mpf.RawMpf],
) -> MpfMatrix raise MPError {
  if rhs.length() != a.rows {
    raise ValueError("augment: incompatible rhs length")
  }
  let out = self.matrix(a.rows, a.cols + 1)
  for i in 0..<a.rows {
    for j in 0..<a.cols {
      out.data[matrix_offset(out.cols, i, j)] = a.data[matrix_offset(
          a.cols,
          i,
          j,
        )]
    }
    out.data[matrix_offset(out.cols, i, a.cols)] = rhs[i].rounded(
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
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i]
      .mul(c, p, Nearest)
      .rounded(self.precision(), self.round_mode())
  }
  out
}

///|
pub fn MPContext::matrix_add_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i]
      .add(c, p, Nearest)
      .rounded(self.precision(), self.round_mode())
  }
  out
}

///|
pub fn MPContext::matrix_sub_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = a.data[i]
      .sub(c, p, Nearest)
      .rounded(self.precision(), self.round_mode())
  }
  out
}

///|
pub fn MPContext::matrix_rsub_scalar(
  self : MPContext,
  c : @mpf.RawMpf,
  a : MpfMatrix,
) -> MpfMatrix raise MPError {
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = c
      .sub(a.data[i], p, Nearest)
      .rounded(self.precision(), self.round_mode())
  }
  out
}

///|
pub fn MPContext::matrix_div_scalar(
  self : MPContext,
  a : MpfMatrix,
  c : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  let p = self.working_precision()
  let out = self.matrix(a.rows, a.cols)
  for i in 0..<(a.rows * a.cols) {
    out.data[i] = (a.data[i].div(c, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }).rounded(self.precision(), self.round_mode())
  }
  out
}

///|
pub fn MPContext::matrix_sum(self : MPContext, a : MpfMatrix) -> @mpf.RawMpf {
  let p = self.working_precision()
  let mut s = @mpf.RawMpf::zero()
  for x in a.data {
    s = s.add(x, p, Nearest)
  }
  s.rounded(self.precision(), self.round_mode())
}

///|
pub fn MPContext::matrix_pow(
  self : MPContext,
  a : MpfMatrix,
  n : Int,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise ValueError("matrix_pow: matrix must be square")
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
  validate_matrix_dimensions(n, n, "hilbert")
  let p = self.working_precision()
  let out = self.matrix(n, n)
  for i in 0..<n {
    for j in 0..<n {
      let denom = @mpf.RawMpf::from_int(i + j + 1)
      out.data[matrix_offset(n, i, j)] = (@mpf.RawMpf::one().div(
        denom,
        p,
        Nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }).rounded(self.precision(), self.round_mode())
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
  validate_matrix_dimensions(rows, c, "randmatrix")
  let out = self.matrix(rows, c)
  for i in 0..<(rows * c) {
    out.data[i] = @mpf.RawMpf::random(self.precision()).rounded(
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
  kind? : StringView = "inf",
) -> @mpf.RawMpf raise MPError {
  let k = kind.to_lower()
  match k {
    "1" => self.matrix_norm_1(a)
    "inf" => self.matrix_norm_inf(a)
    "f" => self.matrix_norm_fro(a)
    "fro" => self.matrix_norm_fro(a)
    _ => raise ValueError("mnorm: unsupported norm '\{kind}'")
  }
}

///|
pub fn MPContext::scalar_abs(self : MPContext, x : @mpf.RawMpf) -> @mpf.RawMpf {
  x.abs(self.precision(), self.round_mode())
}

///|
pub fn MPContext::vector_norm(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
  p? : Int = 2,
  inf? : Bool = false,
) -> @mpf.RawMpf raise MPError {
  let wp = self.working_precision()
  if xs.length() == 0 {
    return @mpf.RawMpf::zero()
  }
  if inf {
    let mut best = @mpf.RawMpf::zero()
    for x in xs {
      let a = x.abs(wp, Nearest)
      if a > best {
        best = a
      }
    }
    return best.rounded(self.precision(), self.round_mode())
  }
  if p <= 0 {
    raise ValueError("vector_norm: p must be positive")
  }
  if p == 1 {
    let mut s = @mpf.RawMpf::zero()
    for x in xs {
      s = s.add(x.abs(wp, Nearest), wp, Nearest)
    }
    return s.rounded(self.precision(), self.round_mode())
  }
  if p == 2 {
    let mut s = @mpf.RawMpf::zero()
    for x in xs {
      let a = x.abs(wp, Nearest)
      s = s.add(a.mul(a, wp, Nearest), wp, Nearest)
    }
    return s.sqrt(self.precision(), self.round_mode()) catch {
      err => raise from_mpf_error(err)
    }
  }
  fn pow_nonneg(x : @mpf.RawMpf, n : Int, prec : Int) -> @mpf.RawMpf {
    let mut out = @mpf.RawMpf::one()
    for _ in 0..<n {
      out = out.mul(x, prec, Nearest)
    }
    out
  }
  let mut s = @mpf.RawMpf::zero()
  for x in xs {
    let a = x.abs(wp, Nearest)
    s = s.add(pow_nonneg(a, p, wp), wp, Nearest)
  }
  let out = @libelefun.nthroot(s, p, wp, Nearest) catch {
    err => raise from_libelefun_error(err)
  }
  out.rounded(self.precision(), self.round_mode())
}
