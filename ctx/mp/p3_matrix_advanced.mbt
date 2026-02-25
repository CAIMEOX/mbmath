///|
fn p3_min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn MPContext::p3_lin_tol(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 220 { -70 } else if prec > 140 { -56 } else { -44 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
fn p3_vec_dot(
  xs : ArrayView[@mpf.RawMpf],
  ys : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> @mpf.RawMpf {
  let mut s = @mpf.fzero
  for i in 0..<xs.length() {
    s = @mpf.mpf_add(
      s,
      @mpf.mpf_mul(xs[i], ys[i], prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
  }
  s
}

///|
fn p3_vec_norm2(
  xs : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let s = p3_vec_dot(xs, xs, prec)
  if @mpf.mpf_sign(s) < 0 {
    raise MPError::DomainError("linear algebra: negative norm square")
  }
  @mpf.mpf_sqrt(s, prec, @mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn p3_extract_col(a : MpfMatrix, col : Int) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<a.rows {
    out.push(a.data[p3_idx(a.cols, i, col)])
  }
  out
}

///|
fn p3_set_col(a : MpfMatrix, col : Int, v : ArrayView[@mpf.RawMpf]) -> Unit {
  for i in 0..<a.rows {
    a.data[p3_idx(a.cols, i, col)] = v[i]
  }
}

///|
fn p3_eye_vec(n : Int, idx : Int) -> Array[@mpf.RawMpf] {
  let v : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    v.push(if i == idx { @mpf.fone } else { @mpf.fzero })
  }
  v
}

///|
fn p3_vec_scale(
  v : ArrayView[@mpf.RawMpf],
  s : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in v {
    out.push(@mpf.mpf_mul(s, x, prec, @mpf.round_nearest))
  }
  out
}

///|
fn p3_vec_sub_scaled(
  v : Array[@mpf.RawMpf],
  q : ArrayView[@mpf.RawMpf],
  c : @mpf.RawMpf,
  prec : Int,
) -> Unit {
  for i in 0..<v.length() {
    v[i] = @mpf.mpf_sub(
      v[i],
      @mpf.mpf_mul(c, q[i], prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
  }
}

///|
fn p3_vec_normalize(
  v : Array[@mpf.RawMpf],
  tol : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, Array[@mpf.RawMpf]) raise MPError {
  let nrm = p3_vec_norm2(v, prec)
  if @mpf.mpf_le(nrm, tol) {
    let z : Array[@mpf.RawMpf] = []
    for _ in 0..<v.length() {
      z.push(@mpf.fzero)
    }
    return (nrm, z)
  }
  let inv = p2_mpf_div(@mpf.fone, nrm, prec, @mpf.round_nearest)
  (nrm, p3_vec_scale(v, inv, prec))
}

///|
pub fn MPContext::matrix_norm_1(self : MPContext, a : MpfMatrix) -> @mpf.RawMpf {
  let p = self.p2_work_prec()
  let mut best = @mpf.fzero
  for j in 0..<a.cols {
    let mut col_sum = @mpf.fzero
    for i in 0..<a.rows {
      col_sum = @mpf.mpf_add(
        col_sum,
        @mpf.mpf_abs(a.data[p3_idx(a.cols, i, j)], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    if @mpf.mpf_gt(col_sum, best) {
      best = col_sum
    }
  }
  @mpf.mpf_pos(best, self.precision(), self.round_mode())
}

///|
pub fn MPContext::matrix_norm_fro(
  self : MPContext,
  a : MpfMatrix,
) -> @mpf.RawMpf raise MPError {
  let p = self.p2_work_prec()
  let mut ss = @mpf.fzero
  for x in a.data {
    ss = @mpf.mpf_add(
      ss,
      @mpf.mpf_mul(x, x, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let nrm = @mpf.mpf_sqrt(ss, p, @mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
  @mpf.mpf_pos(nrm, self.precision(), self.round_mode())
}

///|
pub fn MPContext::qr(
  self : MPContext,
  a : MpfMatrix,
  full? : Bool = false,
  tol? : @mpf.RawMpf,
) -> (MpfMatrix, MpfMatrix) raise MPError {
  let m = a.rows
  let n = a.cols
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let k = p3_min(m, n)
  if k == 0 {
    return if full {
      (self.eye(m), self.matrix(m, n))
    } else {
      (self.matrix(m, 0), self.matrix(0, n))
    }
  }
  let qcols : Array[Array[@mpf.RawMpf]] = []
  let r = self.matrix(k, n)
  for j in 0..<n {
    let v = p3_extract_col(a, j)
    let upto = p3_min(j, k)
    for i in 0..<upto {
      let rij = p3_vec_dot(qcols[i], v, p)
      r.data[p3_idx(r.cols, i, j)] = rij
      p3_vec_sub_scaled(v, qcols[i], rij, p)
    }
    if j < k {
      let (nrm, qj) = p3_vec_normalize(v, tol_abs, p)
      r.data[p3_idx(r.cols, j, j)] = nrm
      qcols.push(qj)
    }
  }
  let q_thin = self.matrix(m, k)
  for j in 0..<k {
    p3_set_col(q_thin, j, qcols[j])
  }
  if !full {
    return (q_thin, r)
  }

  let qfull_cols : Array[Array[@mpf.RawMpf]] = []
  for q in qcols {
    qfull_cols.push(q)
  }
  for extra in qfull_cols.length()..<m {
    let v = p3_eye_vec(m, extra)
    for qi in qfull_cols {
      let c = p3_vec_dot(qi, v, p)
      p3_vec_sub_scaled(v, qi, c, p)
    }
    let (_, qn0) = p3_vec_normalize(v, tol_abs, p)
    let mut qn = qn0
    if @mpf.mpf_le(p3_vec_norm2(qn, p), tol_abs) {
      let mut picked = false
      for probe in 0..<m {
        let cand = p3_eye_vec(m, probe)
        for qi in qfull_cols {
          let c = p3_vec_dot(qi, cand, p)
          p3_vec_sub_scaled(cand, qi, c, p)
        }
        let (_, qp) = p3_vec_normalize(cand, tol_abs, p)
        if @mpf.mpf_gt(p3_vec_norm2(qp, p), tol_abs) {
          qn = qp
          picked = true
          break
        }
      }
      if !picked {
        qn = p3_eye_vec(m, extra)
      }
    }
    qfull_cols.push(qn)
  }
  let q_full = self.matrix(m, m)
  for j in 0..<m {
    p3_set_col(q_full, j, qfull_cols[j])
  }
  let r_full = self.matrix(m, n)
  for i in 0..<k {
    for j in 0..<n {
      r_full.data[p3_idx(r_full.cols, i, j)] = r.data[p3_idx(r.cols, i, j)]
    }
  }
  (q_full, r_full)
}

///|
pub fn MPContext::qr_solve(
  self : MPContext,
  a : MpfMatrix,
  b : ArrayView[@mpf.RawMpf],
  tol? : @mpf.RawMpf,
) -> (Array[@mpf.RawMpf], @mpf.RawMpf) raise MPError {
  let m = a.rows
  let n = a.cols
  if b.length() != m {
    raise MPError::ValueError("qr_solve: incompatible rhs dimension")
  }
  if m < n {
    raise MPError::ValueError("qr_solve: underdetermined systems not supported")
  }
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let (q, r) = self.qr(a, tol=tol_abs)
  let y = p3_matrix_data_with_fill(1, n, @mpf.fzero)
  for i in 0..<n {
    let qi = p3_extract_col(q, i)
    y[i] = p3_vec_dot(qi, b, p)
  }
  let x = p3_matrix_data_with_fill(1, n, @mpf.fzero)
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = y[i]
    for j in (i + 1)..<n {
      s = @mpf.mpf_sub(
        s,
        @mpf.mpf_mul(r.data[p3_idx(r.cols, i, j)], x[j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let rii = r.data[p3_idx(r.cols, i, i)]
    if @mpf.mpf_le(@mpf.mpf_abs(rii, p, @mpf.round_nearest), tol_abs) {
      raise MPError::DomainError("qr_solve: rank-deficient matrix")
    }
    x[i] = @mpf.mpf_pos(
      p2_mpf_div(s, rii, p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  let ax = self.matrix_vec_mul(a, x)
  let mut ss = @mpf.fzero
  for i in 0..<m {
    let ri = @mpf.mpf_sub(ax[i], b[i], p, @mpf.round_nearest)
    ss = @mpf.mpf_add(
      ss,
      @mpf.mpf_mul(ri, ri, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let rn = @mpf.mpf_sqrt(ss, p, @mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
  (x, @mpf.mpf_pos(rn, self.precision(), self.round_mode()))
}

///|
pub fn MPContext::cholesky(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("cholesky: matrix must be square")
  }
  let n = a.rows
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let l = self.matrix(n, n)
  for i in 0..<n {
    for j in 0..<=i {
      let mut s = a.data[p3_idx(a.cols, i, j)]
      for k in 0..<j {
        s = @mpf.mpf_sub(
          s,
          @mpf.mpf_mul(
            l.data[p3_idx(l.cols, i, k)],
            l.data[p3_idx(l.cols, j, k)],
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
      if i == j {
        if @mpf.mpf_lt(s, @mpf.fzero) &&
          @mpf.mpf_gt(@mpf.mpf_abs(s, p, @mpf.round_nearest), tol_abs) {
          raise MPError::DomainError(
            "cholesky: matrix is not positive definite",
          )
        }
        if @mpf.mpf_lt(s, @mpf.fzero) {
          s = @mpf.fzero
        }
        l.data[p3_idx(l.cols, i, j)] = @mpf.mpf_sqrt(s, p, @mpf.round_nearest) catch {
          err => raise from_mpf_error(err)
        }
      } else {
        let ljj = l.data[p3_idx(l.cols, j, j)]
        if @mpf.mpf_le(@mpf.mpf_abs(ljj, p, @mpf.round_nearest), tol_abs) {
          raise MPError::DomainError("cholesky: matrix is singular")
        }
        l.data[p3_idx(l.cols, i, j)] = p2_mpf_div(s, ljj, p, @mpf.round_nearest)
      }
    }
  }
  for i in 0..<n {
    for j in (i + 1)..<n {
      l.data[p3_idx(l.cols, i, j)] = @mpf.fzero
    }
  }
  l
}

///|
pub fn MPContext::cholesky_solve(
  self : MPContext,
  a : MpfMatrix,
  b : ArrayView[@mpf.RawMpf],
  tol? : @mpf.RawMpf,
) -> Array[@mpf.RawMpf] raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("cholesky_solve: matrix must be square")
  }
  let n = a.rows
  if b.length() != n {
    raise MPError::ValueError("cholesky_solve: incompatible rhs dimension")
  }
  let p = self.p2_work_prec()
  let l = match tol {
    Some(t) => self.cholesky(a, tol=t)
    None => self.cholesky(a)
  }
  let y = p3_matrix_data_with_fill(1, n, @mpf.fzero)
  for i in 0..<n {
    let mut s = b[i]
    for j in 0..<i {
      s = @mpf.mpf_sub(
        s,
        @mpf.mpf_mul(l.data[p3_idx(l.cols, i, j)], y[j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let lii = l.data[p3_idx(l.cols, i, i)]
    y[i] = p2_mpf_div(s, lii, p, @mpf.round_nearest)
  }
  let x = p3_matrix_data_with_fill(1, n, @mpf.fzero)
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = y[i]
    for j in (i + 1)..<n {
      s = @mpf.mpf_sub(
        s,
        @mpf.mpf_mul(l.data[p3_idx(l.cols, j, i)], x[j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    x[i] = @mpf.mpf_pos(
      p2_mpf_div(s, l.data[p3_idx(l.cols, i, i)], p, @mpf.round_nearest),
      self.precision(),
      self.round_mode(),
    )
  }
  x
}

///|
pub fn MPContext::hessenberg(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
) -> (MpfMatrix, MpfMatrix) raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("hessenberg: matrix must be square")
  }
  let n = a.rows
  if n <= 2 {
    return (self.eye(n), a)
  }
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let h = p3_copy_vec(a.data)
  let q0 = self.eye(n)
  let q = p3_copy_vec(q0.data)
  for k in 0..<(n - 2) {
    let m = n - k - 1
    let x : Array[@mpf.RawMpf] = []
    for i in 0..<m {
      x.push(h[p3_idx(n, k + 1 + i, k)])
    }
    let normx = p3_vec_norm2(x, p)
    if @mpf.mpf_le(normx, tol_abs) {
      continue
    }
    let alpha = if @mpf.mpf_sign(x[0]) >= 0 {
      @mpf.mpf_neg(normx, p, @mpf.round_nearest)
    } else {
      normx
    }
    let u = p3_copy_vec(x)
    u[0] = @mpf.mpf_sub(u[0], alpha, p, @mpf.round_nearest)
    let (_, u_norm) = p3_vec_normalize(u, tol_abs, p)
    if @mpf.mpf_le(p3_vec_norm2(u_norm, p), tol_abs) {
      continue
    }
    for j in k..<n {
      let mut dot = @mpf.fzero
      for i in 0..<m {
        dot = @mpf.mpf_add(
          dot,
          @mpf.mpf_mul(
            u_norm[i],
            h[p3_idx(n, k + 1 + i, j)],
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
      for i in 0..<m {
        let idx = p3_idx(n, k + 1 + i, j)
        h[idx] = @mpf.mpf_sub(
          h[idx],
          @mpf.mpf_mul_int(
            @mpf.mpf_mul(u_norm[i], dot, p, @mpf.round_nearest),
            2,
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
    }
    for i in 0..<n {
      let mut dot = @mpf.fzero
      for t in 0..<m {
        dot = @mpf.mpf_add(
          dot,
          @mpf.mpf_mul(
            h[p3_idx(n, i, k + 1 + t)],
            u_norm[t],
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
      for t in 0..<m {
        let idx = p3_idx(n, i, k + 1 + t)
        h[idx] = @mpf.mpf_sub(
          h[idx],
          @mpf.mpf_mul_int(
            @mpf.mpf_mul(dot, u_norm[t], p, @mpf.round_nearest),
            2,
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
    }
    for i in 0..<n {
      let mut dot = @mpf.fzero
      for t in 0..<m {
        dot = @mpf.mpf_add(
          dot,
          @mpf.mpf_mul(
            q[p3_idx(n, i, k + 1 + t)],
            u_norm[t],
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
      for t in 0..<m {
        let idx = p3_idx(n, i, k + 1 + t)
        q[idx] = @mpf.mpf_sub(
          q[idx],
          @mpf.mpf_mul_int(
            @mpf.mpf_mul(dot, u_norm[t], p, @mpf.round_nearest),
            2,
            p,
            @mpf.round_nearest,
          ),
          p,
          @mpf.round_nearest,
        )
      }
    }
    for i in (k + 2)..<n {
      h[p3_idx(n, i, k)] = @mpf.fzero
    }
  }
  let q_out = self.matrix(n, n)
  let h_out = self.matrix(n, n)
  for i in 0..<(n * n) {
    q_out.data[i] = @mpf.mpf_pos(q[i], self.precision(), self.round_mode())
    h_out.data[i] = @mpf.mpf_pos(h[i], self.precision(), self.round_mode())
  }
  (q_out, h_out)
}

///|
pub fn MPContext::schur(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 0,
) -> (MpfMatrix, MpfMatrix) raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("schur: matrix must be square")
  }
  let n = a.rows
  if n <= 1 {
    return (self.eye(n), a)
  }
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let (q0, h0) = self.hessenberg(a, tol=tol_abs)
  let mut qtot = q0
  let mut t = h0
  let steps = if max_steps > 0 { max_steps } else { n * n * 96 }
  for _ in 0..<steps {
    let (qk, rk) = self.qr(t, full=true, tol=tol_abs)
    t = self.matrix_mul(rk, qk)
    qtot = self.matrix_mul(qtot, qk)
    let mut off = @mpf.fzero
    for i in 1..<n {
      for j in 0..<i {
        let v = @mpf.mpf_abs(t.data[p3_idx(n, i, j)], p, @mpf.round_nearest)
        if @mpf.mpf_gt(v, off) {
          off = v
        }
      }
    }
    if @mpf.mpf_le(off, tol_abs) {
      return (qtot, t)
    }
  }
  raise MPError::ConvergenceError("schur: QR iteration did not converge")
}

///|
fn MPContext::p3_eigvec_inverse_iteration(
  self : MPContext,
  a : MpfMatrix,
  lambda : @mpf.RawMpf,
  tol : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  let n = a.rows
  let x : Array[@mpf.RawMpf] = []
  for _ in 0..<n {
    x.push(@mpf.fone)
  }
  let (_, x0) = p3_vec_normalize(x, tol, prec)
  let mut cur = x0
  let mut mu = tol
  for _ in 0..<48 {
    let b = self.matrix(n, n)
    for i in 0..<n {
      for j in 0..<n {
        b.data[p3_idx(n, i, j)] = a.data[p3_idx(a.cols, i, j)]
      }
      b.data[p3_idx(n, i, i)] = @mpf.mpf_sub(
        @mpf.mpf_add(b.data[p3_idx(n, i, i)], mu, prec, @mpf.round_nearest),
        lambda,
        prec,
        @mpf.round_nearest,
      )
    }
    let y_try : Result[Array[@mpf.RawMpf], MPError] = try? self.lu_solve(b, cur)
    match y_try {
      Err(_) => mu = @mpf.mpf_mul_int(mu, 10, prec, @mpf.round_nearest)
      Ok(y) => {
        let (_, next) = p3_vec_normalize(y, tol, prec)
        let mut diff = @mpf.fzero
        for i in 0..<n {
          let d = @mpf.mpf_abs(
            @mpf.mpf_sub(next[i], cur[i], prec, @mpf.round_nearest),
            prec,
            @mpf.round_nearest,
          )
          if @mpf.mpf_gt(d, diff) {
            diff = d
          }
        }
        cur = next
        if @mpf.mpf_le(diff, tol) {
          return cur
        }
      }
    }
  }
  cur
}

///|
pub fn MPContext::eig(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 0,
) -> (Array[@mpf.RawMpf], MpfMatrix) raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("eig: matrix must be square")
  }
  let n = a.rows
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let (_q, t) = self.schur(a, tol=tol_abs, max_steps~)
  for i in 1..<n {
    let sub = @mpf.mpf_abs(t.data[p3_idx(n, i, i - 1)], p, @mpf.round_nearest)
    if @mpf.mpf_gt(sub, @mpf.mpf_mul_int(tol_abs, 8, p, @mpf.round_nearest)) {
      raise MPError::ComplexResult("eig: complex eigenvalues not supported")
    }
  }
  let vals : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    vals.push(
      @mpf.mpf_pos(t.data[p3_idx(n, i, i)], self.precision(), self.round_mode()),
    )
  }
  let vecs = self.matrix(n, n)
  for i in 0..<n {
    let v = self.p3_eigvec_inverse_iteration(a, vals[i], tol_abs, p)
    p3_set_col(vecs, i, v)
  }
  (vals, vecs)
}

///|
pub fn MPContext::eighe(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 0,
) -> (Array[@mpf.RawMpf], MpfMatrix) raise MPError {
  match tol {
    Some(t) => self.eigsy(a, tol=t, max_steps~)
    None => self.eigsy(a, max_steps~)
  }
}

///|
pub fn MPContext::svd(
  self : MPContext,
  a : MpfMatrix,
  full? : Bool = false,
  tol? : @mpf.RawMpf,
) -> (MpfMatrix, Array[@mpf.RawMpf], MpfMatrix) raise MPError {
  ignore(full)
  let m = a.rows
  let n = a.cols
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p3_lin_tol(p)
  }
  let k = p3_min(m, n)
  if k == 0 {
    return (self.matrix(m, 0), [], self.matrix(0, n))
  }
  if m >= n {
    let at = self.matrix_transpose(a)
    let ata = self.matrix_mul(at, a)
    let (evals, evecs) = self.eigsy(ata, tol=tol_abs)
    let u = self.matrix(m, k)
    let v = self.matrix(k, n)
    let sigmas : Array[@mpf.RawMpf] = []
    for t in 0..<k {
      let idx = k - 1 - t
      let mut lam = evals[idx]
      if @mpf.mpf_lt(lam, @mpf.fzero) {
        if @mpf.mpf_gt(@mpf.mpf_abs(lam, p, @mpf.round_nearest), tol_abs) {
          raise MPError::DomainError("svd: negative eigenvalue in A^T A")
        }
        lam = @mpf.fzero
      }
      let sigma = @mpf.mpf_sqrt(lam, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      }
      sigmas.push(@mpf.mpf_pos(sigma, self.precision(), self.round_mode()))
      let vi = p3_extract_col(evecs, idx)
      for j in 0..<n {
        v.data[p3_idx(v.cols, t, j)] = vi[j]
      }
      if @mpf.mpf_le(sigma, tol_abs) {
        continue
      }
      let avi = self.matrix_vec_mul(a, vi)
      let inv = p2_mpf_div(@mpf.fone, sigma, p, @mpf.round_nearest)
      let ui = p3_vec_scale(avi, inv, p)
      p3_set_col(u, t, ui)
    }
    return (u, sigmas, v)
  } else {
    let at = self.matrix_transpose(a)
    let aat = self.matrix_mul(a, at)
    let (evals, uvecs) = self.eigsy(aat, tol=tol_abs)
    let u = self.matrix(m, k)
    let v = self.matrix(k, n)
    let sigmas : Array[@mpf.RawMpf] = []
    for t in 0..<k {
      let idx = k - 1 - t
      let mut lam = evals[idx]
      if @mpf.mpf_lt(lam, @mpf.fzero) {
        if @mpf.mpf_gt(@mpf.mpf_abs(lam, p, @mpf.round_nearest), tol_abs) {
          raise MPError::DomainError("svd: negative eigenvalue in A A^T")
        }
        lam = @mpf.fzero
      }
      let sigma = @mpf.mpf_sqrt(lam, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      }
      sigmas.push(@mpf.mpf_pos(sigma, self.precision(), self.round_mode()))
      let ui = p3_extract_col(uvecs, idx)
      p3_set_col(u, t, ui)
      if @mpf.mpf_le(sigma, tol_abs) {
        continue
      }
      let atui = self.matrix_vec_mul(at, ui)
      let inv = p2_mpf_div(@mpf.fone, sigma, p, @mpf.round_nearest)
      let vi = p3_vec_scale(atui, inv, p)
      for j in 0..<n {
        v.data[p3_idx(v.cols, t, j)] = vi[j]
      }
    }
    (u, sigmas, v)
  }
}

///|
pub fn MPContext::cond(
  self : MPContext,
  a : MpfMatrix,
  norm? : String = "inf",
) -> @mpf.RawMpf raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("cond: matrix must be square")
  }
  let key = norm.to_lower()
  let an = match key {
    "inf" => self.matrix_norm_inf(a)
    "1" => self.matrix_norm_1(a)
    "f" => self.matrix_norm_fro(a)
    "fro" => self.matrix_norm_fro(a)
    _ => raise MPError::ValueError("cond: unknown norm '\{norm}'")
  }
  let ainv = self.inverse(a)
  let bn = match key {
    "inf" => self.matrix_norm_inf(ainv)
    "1" => self.matrix_norm_1(ainv)
    "f" => self.matrix_norm_fro(ainv)
    "fro" => self.matrix_norm_fro(ainv)
    _ => raise MPError::ValueError("cond: unknown norm '\{norm}'")
  }
  @mpf.mpf_mul(an, bn, self.p2_work_prec(), @mpf.round_nearest)
}
