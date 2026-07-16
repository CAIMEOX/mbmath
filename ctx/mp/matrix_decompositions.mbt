///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn MPContext::linear_algebra_tolerance(
  self : MPContext,
  prec : Int,
) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 220 { -70 } else if prec > 140 { -56 } else { -44 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
fn vector_dot_product(
  xs : ArrayView[@mpf.RawMpf],
  ys : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> @mpf.RawMpf {
  let mut s = @mpf.RawMpf::zero()
  for i in 0..<xs.length() {
    s = s.add(xs[i].mul(ys[i], prec, Nearest), prec, Nearest)
  }
  s
}

///|
fn vector_norm(
  xs : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let s = vector_dot_product(xs, xs, prec)
  if s.signum() < 0 {
    raise DomainError("linear algebra: negative norm square")
  }
  s.sqrt(prec, Nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn extract_matrix_column(a : MpfMatrix, col : Int) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<a.rows {
    out.push(a.data[matrix_offset(a.cols, i, col)])
  }
  out
}

///|
fn set_matrix_column(
  a : MpfMatrix,
  col : Int,
  v : ArrayView[@mpf.RawMpf],
) -> Unit {
  for i in 0..<a.rows {
    a.data[matrix_offset(a.cols, i, col)] = v[i]
  }
}

///|
fn basis_vector(n : Int, idx : Int) -> Array[@mpf.RawMpf] {
  let v : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    v.push(if i == idx { @mpf.RawMpf::one() } else { @mpf.RawMpf::zero() })
  }
  v
}

///|
fn scale_vector(
  v : ArrayView[@mpf.RawMpf],
  s : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in v {
    out.push(s.mul(x, prec, Nearest))
  }
  out
}

///|
fn subtract_scaled_vector(
  v : Array[@mpf.RawMpf],
  q : ArrayView[@mpf.RawMpf],
  c : @mpf.RawMpf,
  prec : Int,
) -> Unit {
  for i in 0..<v.length() {
    v[i] = v[i].sub(c.mul(q[i], prec, Nearest), prec, Nearest)
  }
}

///|
fn normalize_vector(
  v : Array[@mpf.RawMpf],
  tol : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, Array[@mpf.RawMpf]) raise MPError {
  let nrm = vector_norm(v, prec)
  if nrm <= tol {
    let z : Array[@mpf.RawMpf] = []
    for _ in 0..<v.length() {
      z.push(@mpf.RawMpf::zero())
    }
    return (nrm, z)
  }
  let inv = checked_mpf_div(@mpf.RawMpf::one(), nrm, prec, Nearest)
  (nrm, scale_vector(v, inv, prec))
}

///|
pub fn MPContext::matrix_norm_1(self : MPContext, a : MpfMatrix) -> @mpf.RawMpf {
  let p = self.working_precision()
  let mut best = @mpf.RawMpf::zero()
  for j in 0..<a.cols {
    let mut col_sum = @mpf.RawMpf::zero()
    for i in 0..<a.rows {
      col_sum = col_sum.add(
        a.data[matrix_offset(a.cols, i, j)].abs(p, Nearest),
        p,
        Nearest,
      )
    }
    if col_sum > best {
      best = col_sum
    }
  }
  best.rounded(self.precision(), self.round_mode())
}

///|
pub fn MPContext::matrix_norm_fro(
  self : MPContext,
  a : MpfMatrix,
) -> @mpf.RawMpf raise MPError {
  let p = self.working_precision()
  let mut ss = @mpf.RawMpf::zero()
  for x in a.data {
    ss = ss.add(x.mul(x, p, Nearest), p, Nearest)
  }
  let nrm = ss.sqrt(p, Nearest) catch { err => raise from_mpf_error(err) }
  nrm.rounded(self.precision(), self.round_mode())
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
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let k = min_int(m, n)
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
    let v = extract_matrix_column(a, j)
    let upto = min_int(j, k)
    for i in 0..<upto {
      let rij = vector_dot_product(qcols[i], v, p)
      r.data[matrix_offset(r.cols, i, j)] = rij
      subtract_scaled_vector(v, qcols[i], rij, p)
    }
    if j < k {
      let (nrm, qj) = normalize_vector(v, tol_abs, p)
      r.data[matrix_offset(r.cols, j, j)] = nrm
      qcols.push(qj)
    }
  }
  let q_thin = self.matrix(m, k)
  for j in 0..<k {
    set_matrix_column(q_thin, j, qcols[j])
  }
  if !full {
    return (q_thin, r)
  }

  let qfull_cols : Array[Array[@mpf.RawMpf]] = []
  for q in qcols {
    qfull_cols.push(q)
  }
  for extra in qfull_cols.length()..<m {
    let v = basis_vector(m, extra)
    for qi in qfull_cols {
      let c = vector_dot_product(qi, v, p)
      subtract_scaled_vector(v, qi, c, p)
    }
    let (_, qn0) = normalize_vector(v, tol_abs, p)
    let mut qn = qn0
    if vector_norm(qn, p) <= tol_abs {
      let mut picked = false
      for probe in 0..<m {
        let cand = basis_vector(m, probe)
        for qi in qfull_cols {
          let c = vector_dot_product(qi, cand, p)
          subtract_scaled_vector(cand, qi, c, p)
        }
        let (_, qp) = normalize_vector(cand, tol_abs, p)
        if vector_norm(qp, p) > tol_abs {
          qn = qp
          picked = true
          break
        }
      }
      if !picked {
        qn = basis_vector(m, extra)
      }
    }
    qfull_cols.push(qn)
  }
  let q_full = self.matrix(m, m)
  for j in 0..<m {
    set_matrix_column(q_full, j, qfull_cols[j])
  }
  let r_full = self.matrix(m, n)
  for i in 0..<k {
    for j in 0..<n {
      r_full.data[matrix_offset(r_full.cols, i, j)] = r.data[matrix_offset(
          r.cols,
          i,
          j,
        )]
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
    raise ValueError("qr_solve: incompatible rhs dimension")
  }
  if m < n {
    raise ValueError("qr_solve: underdetermined systems not supported")
  }
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let (q, r) = self.qr(a, tol=tol_abs)
  let y = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
  for i in 0..<n {
    let qi = extract_matrix_column(q, i)
    y[i] = vector_dot_product(qi, b, p)
  }
  let x = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = y[i]
    for j in (i + 1)..<n {
      s = s.sub(
        r.data[matrix_offset(r.cols, i, j)].mul(x[j], p, Nearest),
        p,
        Nearest,
      )
    }
    let rii = r.data[matrix_offset(r.cols, i, i)]
    if rii.abs(p, Nearest) <= tol_abs {
      raise DomainError("qr_solve: rank-deficient matrix")
    }
    x[i] = checked_mpf_div(s, rii, p, Nearest).rounded(
      self.precision(),
      self.round_mode(),
    )
  }
  let ax = self.matrix_vec_mul(a, x)
  let mut ss = @mpf.RawMpf::zero()
  for i in 0..<m {
    let ri = ax[i].sub(b[i], p, Nearest)
    ss = ss.add(ri.mul(ri, p, Nearest), p, Nearest)
  }
  let rn = ss.sqrt(p, Nearest) catch { err => raise from_mpf_error(err) }
  (x, rn.rounded(self.precision(), self.round_mode()))
}

///|
pub fn MPContext::cholesky(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
) -> MpfMatrix raise MPError {
  if a.rows != a.cols {
    raise ValueError("cholesky: matrix must be square")
  }
  let n = a.rows
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let l = self.matrix(n, n)
  for i in 0..<n {
    for j in 0..<=i {
      let mut s = a.data[matrix_offset(a.cols, i, j)]
      for k in 0..<j {
        s = s.sub(
          l.data[matrix_offset(l.cols, i, k)].mul(
            l.data[matrix_offset(l.cols, j, k)],
            p,
            Nearest,
          ),
          p,
          Nearest,
        )
      }
      if i == j {
        if s < @mpf.RawMpf::zero() && s.abs(p, Nearest) > tol_abs {
          raise DomainError("cholesky: matrix is not positive definite")
        }
        if s < @mpf.RawMpf::zero() {
          s = @mpf.RawMpf::zero()
        }
        l.data[matrix_offset(l.cols, i, j)] = s.sqrt(p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      } else {
        let ljj = l.data[matrix_offset(l.cols, j, j)]
        if ljj.abs(p, Nearest) <= tol_abs {
          raise DomainError("cholesky: matrix is singular")
        }
        l.data[matrix_offset(l.cols, i, j)] = checked_mpf_div(
          s,
          ljj,
          p,
          Nearest,
        )
      }
    }
  }
  for i in 0..<n {
    for j in (i + 1)..<n {
      l.data[matrix_offset(l.cols, i, j)] = @mpf.RawMpf::zero()
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
    raise ValueError("cholesky_solve: matrix must be square")
  }
  let n = a.rows
  if b.length() != n {
    raise ValueError("cholesky_solve: incompatible rhs dimension")
  }
  let p = self.working_precision()
  let l = match tol {
    Some(t) => self.cholesky(a, tol=t)
    None => self.cholesky(a)
  }
  let y = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
  for i in 0..<n {
    let mut s = b[i]
    for j in 0..<i {
      s = s.sub(
        l.data[matrix_offset(l.cols, i, j)].mul(y[j], p, Nearest),
        p,
        Nearest,
      )
    }
    let lii = l.data[matrix_offset(l.cols, i, i)]
    y[i] = checked_mpf_div(s, lii, p, Nearest)
  }
  let x = make_filled_matrix_data(1, n, @mpf.RawMpf::zero())
  for t in 0..<n {
    let i = n - 1 - t
    let mut s = y[i]
    for j in (i + 1)..<n {
      s = s.sub(
        l.data[matrix_offset(l.cols, j, i)].mul(x[j], p, Nearest),
        p,
        Nearest,
      )
    }
    x[i] = checked_mpf_div(s, l.data[matrix_offset(l.cols, i, i)], p, Nearest).rounded(
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
    raise ValueError("hessenberg: matrix must be square")
  }
  let n = a.rows
  if n <= 2 {
    return (self.eye(n), a)
  }
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let h = copy_mpf_vector(a.data)
  let q0 = self.eye(n)
  let q = copy_mpf_vector(q0.data)
  for k in 0..<(n - 2) {
    let m = n - k - 1
    let x : Array[@mpf.RawMpf] = []
    for i in 0..<m {
      x.push(h[matrix_offset(n, k + 1 + i, k)])
    }
    let normx = vector_norm(x, p)
    if normx <= tol_abs {
      continue
    }
    let alpha = if x[0].signum() >= 0 {
      normx.negated(p, Nearest)
    } else {
      normx
    }
    let u = copy_mpf_vector(x)
    u[0] = u[0].sub(alpha, p, Nearest)
    let (_, u_norm) = normalize_vector(u, tol_abs, p)
    if vector_norm(u_norm, p) <= tol_abs {
      continue
    }
    for j in k..<n {
      let mut dot = @mpf.RawMpf::zero()
      for i in 0..<m {
        dot = dot.add(
          u_norm[i].mul(h[matrix_offset(n, k + 1 + i, j)], p, Nearest),
          p,
          Nearest,
        )
      }
      for i in 0..<m {
        let idx = matrix_offset(n, k + 1 + i, j)
        h[idx] = h[idx].sub(
          u_norm[i].mul(dot, p, Nearest).mul_int(2, p, Nearest),
          p,
          Nearest,
        )
      }
    }
    for i in 0..<n {
      let mut dot = @mpf.RawMpf::zero()
      for t in 0..<m {
        dot = dot.add(
          h[matrix_offset(n, i, k + 1 + t)].mul(u_norm[t], p, Nearest),
          p,
          Nearest,
        )
      }
      for t in 0..<m {
        let idx = matrix_offset(n, i, k + 1 + t)
        h[idx] = h[idx].sub(
          dot.mul(u_norm[t], p, Nearest).mul_int(2, p, Nearest),
          p,
          Nearest,
        )
      }
    }
    for i in 0..<n {
      let mut dot = @mpf.RawMpf::zero()
      for t in 0..<m {
        dot = dot.add(
          q[matrix_offset(n, i, k + 1 + t)].mul(u_norm[t], p, Nearest),
          p,
          Nearest,
        )
      }
      for t in 0..<m {
        let idx = matrix_offset(n, i, k + 1 + t)
        q[idx] = q[idx].sub(
          dot.mul(u_norm[t], p, Nearest).mul_int(2, p, Nearest),
          p,
          Nearest,
        )
      }
    }
    for i in (k + 2)..<n {
      h[matrix_offset(n, i, k)] = @mpf.RawMpf::zero()
    }
  }
  let q_out = self.matrix(n, n)
  let h_out = self.matrix(n, n)
  for i in 0..<(n * n) {
    q_out.data[i] = q[i].rounded(self.precision(), self.round_mode())
    h_out.data[i] = h[i].rounded(self.precision(), self.round_mode())
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
    raise ValueError("schur: matrix must be square")
  }
  let n = a.rows
  if n <= 1 {
    return (self.eye(n), a)
  }
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let (q0, h0) = self.hessenberg(a, tol=tol_abs)
  let mut qtot = q0
  let mut t = h0
  let steps = if max_steps > 0 { max_steps } else { n * n * 96 }
  for _ in 0..<steps {
    let (qk, rk) = self.qr(t, full=true, tol=tol_abs)
    t = self.matrix_mul(rk, qk)
    qtot = self.matrix_mul(qtot, qk)
    let mut off = @mpf.RawMpf::zero()
    for i in 1..<n {
      for j in 0..<i {
        let v = t.data[matrix_offset(n, i, j)].abs(p, Nearest)
        if v > off {
          off = v
        }
      }
    }
    if off <= tol_abs {
      return (qtot, t)
    }
  }
  raise ConvergenceError("schur: QR iteration did not converge")
}

///|
fn MPContext::inverse_iteration_eigenvector(
  self : MPContext,
  a : MpfMatrix,
  lambda : @mpf.RawMpf,
  tol : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  let n = a.rows
  let x : Array[@mpf.RawMpf] = []
  for _ in 0..<n {
    x.push(@mpf.RawMpf::one())
  }
  let (_, x0) = normalize_vector(x, tol, prec)
  let mut cur = x0
  let mut mu = tol
  for _ in 0..<48 {
    let b = self.matrix(n, n)
    for i in 0..<n {
      for j in 0..<n {
        b.data[matrix_offset(n, i, j)] = a.data[matrix_offset(a.cols, i, j)]
      }
      b.data[matrix_offset(n, i, i)] = b.data[matrix_offset(n, i, i)]
        .add(mu, prec, Nearest)
        .sub(lambda, prec, Nearest)
    }
    try self.lu_solve(b, cur) catch {
      _ => mu = mu.mul_int(10, prec, Nearest)
    } noraise {
      y => {
        let (_, next) = normalize_vector(y, tol, prec)
        let mut diff = @mpf.RawMpf::zero()
        for i in 0..<n {
          let d = next[i].sub(cur[i], prec, Nearest).abs(prec, Nearest)
          if d > diff {
            diff = d
          }
        }
        cur = next
        if diff <= tol {
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
    raise ValueError("eig: matrix must be square")
  }
  let n = a.rows
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let (_q, t) = self.schur(a, tol=tol_abs, max_steps~)
  for i in 1..<n {
    let sub = t.data[matrix_offset(n, i, i - 1)].abs(p, Nearest)
    if sub > tol_abs.mul_int(8, p, Nearest) {
      raise ComplexResult("eig: complex eigenvalues not supported")
    }
  }
  let vals : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    vals.push(
      t.data[matrix_offset(n, i, i)].rounded(
        self.precision(),
        self.round_mode(),
      ),
    )
  }
  let vecs = self.matrix(n, n)
  for i in 0..<n {
    let v = self.inverse_iteration_eigenvector(a, vals[i], tol_abs, p)
    set_matrix_column(vecs, i, v)
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
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.linear_algebra_tolerance(p)
  }
  let k = min_int(m, n)
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
      if lam < @mpf.RawMpf::zero() {
        if lam.abs(p, Nearest) > tol_abs {
          raise DomainError("svd: negative eigenvalue in A^T A")
        }
        lam = @mpf.RawMpf::zero()
      }
      let sigma = lam.sqrt(p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
      sigmas.push(sigma.rounded(self.precision(), self.round_mode()))
      let vi = extract_matrix_column(evecs, idx)
      for j in 0..<n {
        v.data[matrix_offset(v.cols, t, j)] = vi[j]
      }
      if sigma <= tol_abs {
        continue
      }
      let avi = self.matrix_vec_mul(a, vi)
      let inv = checked_mpf_div(@mpf.RawMpf::one(), sigma, p, Nearest)
      let ui = scale_vector(avi, inv, p)
      set_matrix_column(u, t, ui)
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
      if lam < @mpf.RawMpf::zero() {
        if lam.abs(p, Nearest) > tol_abs {
          raise DomainError("svd: negative eigenvalue in A A^T")
        }
        lam = @mpf.RawMpf::zero()
      }
      let sigma = lam.sqrt(p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
      sigmas.push(sigma.rounded(self.precision(), self.round_mode()))
      let ui = extract_matrix_column(uvecs, idx)
      set_matrix_column(u, t, ui)
      if sigma <= tol_abs {
        continue
      }
      let atui = self.matrix_vec_mul(at, ui)
      let inv = checked_mpf_div(@mpf.RawMpf::one(), sigma, p, Nearest)
      let vi = scale_vector(atui, inv, p)
      for j in 0..<n {
        v.data[matrix_offset(v.cols, t, j)] = vi[j]
      }
    }
    (u, sigmas, v)
  }
}

///|
pub fn MPContext::cond(
  self : MPContext,
  a : MpfMatrix,
  norm? : StringView = "inf",
) -> @mpf.RawMpf raise MPError {
  if a.rows != a.cols {
    raise ValueError("cond: matrix must be square")
  }
  let key = norm.to_lower()
  let an = match key {
    "inf" => self.matrix_norm_inf(a)
    "1" => self.matrix_norm_1(a)
    "f" => self.matrix_norm_fro(a)
    "fro" => self.matrix_norm_fro(a)
    _ => raise ValueError("cond: unknown norm '\{norm}'")
  }
  let ainv = self.inverse(a)
  let bn = match key {
    "inf" => self.matrix_norm_inf(ainv)
    "1" => self.matrix_norm_1(ainv)
    "f" => self.matrix_norm_fro(ainv)
    "fro" => self.matrix_norm_fro(ainv)
    _ => raise ValueError("cond: unknown norm '\{norm}'")
  }
  an.mul(bn, self.working_precision(), Nearest)
}
