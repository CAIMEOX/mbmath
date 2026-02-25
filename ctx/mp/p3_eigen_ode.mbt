///|
type OdeSystemFn = (@mpf.RawMpf, ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf]

///|
fn MPContext::p3_ode_expect_dim(
  self : MPContext,
  name : String,
  y : ArrayView[@mpf.RawMpf],
  n : Int,
) -> Unit raise MPError {
  ignore(self)
  if y.length() != n {
    raise MPError::ValueError("\{name}: derivative dimension mismatch")
  }
}

///|
fn MPContext::p3_ode_shift(
  self : MPContext,
  y : ArrayView[@mpf.RawMpf],
  k : ArrayView[@mpf.RawMpf],
  scale : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<y.length() {
    out.push(
      @mpf.mpf_add(
        y[i],
        @mpf.mpf_mul(scale, k[i], prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      ),
    )
  }
  ignore(self)
  out
}

///|
fn MPContext::p3_ode_finalize(
  self : MPContext,
  y : ArrayView[@mpf.RawMpf],
  k1 : ArrayView[@mpf.RawMpf],
  k2 : ArrayView[@mpf.RawMpf],
  k3 : ArrayView[@mpf.RawMpf],
  k4 : ArrayView[@mpf.RawMpf],
  h : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  let h6 = p2_mpf_div_int(h, 6, prec, @mpf.round_nearest)
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<y.length() {
    let combo = @mpf.mpf_add(
      @mpf.mpf_add(
        k1[i],
        @mpf.mpf_mul_int(k2[i], 2, prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      ),
      @mpf.mpf_add(
        @mpf.mpf_mul_int(k3[i], 2, prec, @mpf.round_nearest),
        k4[i],
        prec,
        @mpf.round_nearest,
      ),
      prec,
      @mpf.round_nearest,
    )
    let next = @mpf.mpf_add(
      y[i],
      @mpf.mpf_mul(h6, combo, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    out.push(@mpf.mpf_pos(next, self.precision(), self.round_mode()))
  }
  out
}

///|
pub fn MPContext::ode_step_rk4(
  self : MPContext,
  f : OdeSystemFn,
  t : @mpf.RawMpf,
  y : ArrayView[@mpf.RawMpf],
  h : @mpf.RawMpf,
) -> Array[@mpf.RawMpf] raise MPError {
  let n = y.length()
  let p = self.p2_work_prec()
  let h2 = p2_mpf_div_int(h, 2, p, @mpf.round_nearest)
  let t2 = @mpf.mpf_add(t, h2, p, @mpf.round_nearest)
  let t4 = @mpf.mpf_add(t, h, p, @mpf.round_nearest)

  let k1 = f(t, y)
  self.p3_ode_expect_dim("ode_step_rk4", k1, n)
  let y2 = self.p3_ode_shift(y, k1, h2, p)

  let k2 = f(t2, y2)
  self.p3_ode_expect_dim("ode_step_rk4", k2, n)
  let y3 = self.p3_ode_shift(y, k2, h2, p)

  let k3 = f(t2, y3)
  self.p3_ode_expect_dim("ode_step_rk4", k3, n)
  let y4 = self.p3_ode_shift(y, k3, h, p)

  let k4 = f(t4, y4)
  self.p3_ode_expect_dim("ode_step_rk4", k4, n)

  self.p3_ode_finalize(y, k1, k2, k3, k4, h, p)
}

///|
pub fn MPContext::ode_solve(
  self : MPContext,
  f : OdeSystemFn,
  t0 : @mpf.RawMpf,
  y0 : ArrayView[@mpf.RawMpf],
  t1 : @mpf.RawMpf,
  steps? : Int = 200,
) -> Array[@mpf.RawMpf] raise MPError {
  if steps < 1 {
    raise MPError::ValueError("ode_solve: steps must be positive")
  }
  let p = self.p2_work_prec()
  let h = p2_mpf_div(
    @mpf.mpf_sub(t1, t0, p, @mpf.round_nearest),
    @mpf.from_int(steps),
    p,
    @mpf.round_nearest,
  )
  let mut t = t0
  let mut y = p3_copy_vec(y0)
  for _ in 0..<steps {
    y = self.ode_step_rk4(f, t, y, h)
    t = @mpf.mpf_add(t, h, p, @mpf.round_nearest)
  }
  y
}

///|
pub fn MPContext::ode_solve_grid(
  self : MPContext,
  f : OdeSystemFn,
  t0 : @mpf.RawMpf,
  y0 : ArrayView[@mpf.RawMpf],
  ts : ArrayView[@mpf.RawMpf],
  steps_per_interval? : Int = 128,
) -> Array[Array[@mpf.RawMpf]] raise MPError {
  if steps_per_interval < 1 {
    raise MPError::ValueError(
      "ode_solve_grid: steps_per_interval must be positive",
    )
  }
  if ts.length() == 0 {
    return []
  }
  if !@mpf.mpf_eq(ts[0], t0) {
    raise MPError::ValueError("ode_solve_grid: ts[0] must equal t0")
  }
  let out : Array[Array[@mpf.RawMpf]] = []
  let mut t = t0
  let mut y = p3_copy_vec(y0)
  out.push(p3_copy_vec(y))
  for i in 1..<ts.length() {
    let t_next = ts[i]
    y = self.ode_solve(f, t, y, t_next, steps=steps_per_interval)
    t = t_next
    out.push(p3_copy_vec(y))
  }
  out
}

///|
pub fn MPContext::eigsy(
  self : MPContext,
  a : MpfMatrix,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 0,
) -> (Array[@mpf.RawMpf], MpfMatrix) raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("eigsy: matrix must be square")
  }
  let n = a.rows
  if n == 0 {
    return ([], { rows: 0, cols: 0, data: [] })
  }
  if n == 1 {
    return (
      [@mpf.mpf_pos(a.data[0], self.precision(), self.round_mode())],
      self.eye(1),
    )
  }
  for i in 0..<n {
    for j in (i + 1)..<n {
      if !@mpf.mpf_eq(a.data[p3_idx(n, i, j)], a.data[p3_idx(n, j, i)]) {
        raise MPError::ValueError("eigsy: matrix must be symmetric")
      }
    }
  }
  let p = self.p2_work_prec() + 24
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => {
      let s = if self.precision() > 0 { -(self.precision() / 2) } else { -40 }
      @mpf.from_man_exp(1N, s, 0, @mpf.round_down)
    }
  }
  let steps = if max_steps > 0 { max_steps } else { n * n * 32 }
  let work = p3_copy_vec(a.data)
  let q0 = self.eye(n)
  let q = p3_copy_vec(q0.data)
  let mut done = false
  for _ in 0..<steps {
    let mut p_idx = 0
    let mut q_idx = 1
    let mut max_off = @mpf.fzero
    for i in 0..<n {
      for j in (i + 1)..<n {
        let v = @mpf.mpf_abs(work[p3_idx(n, i, j)], p, @mpf.round_nearest)
        if @mpf.mpf_gt(v, max_off) {
          max_off = v
          p_idx = i
          q_idx = j
        }
      }
    }
    if @mpf.mpf_le(max_off, tol_abs) {
      done = true
      break
    }
    let app = work[p3_idx(n, p_idx, p_idx)]
    let aqq = work[p3_idx(n, q_idx, q_idx)]
    let apq = work[p3_idx(n, p_idx, q_idx)]
    if @mpf.is_zero(apq) {
      continue
    }
    let tau = p2_mpf_div(
      @mpf.mpf_sub(aqq, app, p, @mpf.round_nearest),
      @mpf.mpf_mul_int(apq, 2, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    let tau_abs = @mpf.mpf_abs(tau, p, @mpf.round_nearest)
    let root = @mpf.mpf_sqrt(
      @mpf.mpf_add(
        @mpf.fone,
        @mpf.mpf_mul(tau, tau, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    ) catch {
      err => raise from_mpf_error(err)
    }
    let denom = @mpf.mpf_add(tau_abs, root, p, @mpf.round_nearest)
    let mut t = if @mpf.is_zero(denom) {
      @mpf.fone
    } else {
      p2_mpf_div(@mpf.fone, denom, p, @mpf.round_nearest)
    }
    if tau.sign == 1 {
      t = @mpf.mpf_neg(t, p, @mpf.round_nearest)
    }
    let c = p2_mpf_div(
      @mpf.fone,
      @mpf.mpf_sqrt(
        @mpf.mpf_add(
          @mpf.fone,
          @mpf.mpf_mul(t, t, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      },
      p,
      @mpf.round_nearest,
    )
    let s = @mpf.mpf_mul(t, c, p, @mpf.round_nearest)
    let c2 = @mpf.mpf_mul(c, c, p, @mpf.round_nearest)
    let s2 = @mpf.mpf_mul(s, s, p, @mpf.round_nearest)
    let sc2 = @mpf.mpf_mul_int(
      @mpf.mpf_mul(s, c, p, @mpf.round_nearest),
      2,
      p,
      @mpf.round_nearest,
    )
    for k in 0..<n {
      if k == p_idx || k == q_idx {
        continue
      }
      let aik = work[p3_idx(n, k, p_idx)]
      let akq = work[p3_idx(n, k, q_idx)]
      let new_aik = @mpf.mpf_sub(
        @mpf.mpf_mul(c, aik, p, @mpf.round_nearest),
        @mpf.mpf_mul(s, akq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      let new_akq = @mpf.mpf_add(
        @mpf.mpf_mul(s, aik, p, @mpf.round_nearest),
        @mpf.mpf_mul(c, akq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      work[p3_idx(n, k, p_idx)] = new_aik
      work[p3_idx(n, p_idx, k)] = new_aik
      work[p3_idx(n, k, q_idx)] = new_akq
      work[p3_idx(n, q_idx, k)] = new_akq
    }
    work[p3_idx(n, p_idx, p_idx)] = @mpf.mpf_add(
      @mpf.mpf_sub(
        @mpf.mpf_mul(c2, app, p, @mpf.round_nearest),
        @mpf.mpf_mul(sc2, apq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      @mpf.mpf_mul(s2, aqq, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    work[p3_idx(n, q_idx, q_idx)] = @mpf.mpf_add(
      @mpf.mpf_add(
        @mpf.mpf_mul(s2, app, p, @mpf.round_nearest),
        @mpf.mpf_mul(sc2, apq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      @mpf.mpf_mul(c2, aqq, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    work[p3_idx(n, p_idx, q_idx)] = @mpf.fzero
    work[p3_idx(n, q_idx, p_idx)] = @mpf.fzero

    for k in 0..<n {
      let vip = q[p3_idx(n, k, p_idx)]
      let viq = q[p3_idx(n, k, q_idx)]
      q[p3_idx(n, k, p_idx)] = @mpf.mpf_sub(
        @mpf.mpf_mul(c, vip, p, @mpf.round_nearest),
        @mpf.mpf_mul(s, viq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      q[p3_idx(n, k, q_idx)] = @mpf.mpf_add(
        @mpf.mpf_mul(s, vip, p, @mpf.round_nearest),
        @mpf.mpf_mul(c, viq, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
  }
  if !done {
    raise MPError::ConvergenceError("eigsy: Jacobi iteration did not converge")
  }
  let vals : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    vals.push(work[p3_idx(n, i, i)])
  }
  for i in 0..<n {
    let mut best = i
    for j in (i + 1)..<n {
      if @mpf.mpf_lt(vals[j], vals[best]) {
        best = j
      }
    }
    if best != i {
      let t = vals[i]
      vals[i] = vals[best]
      vals[best] = t
      p3_swap_cols(q, n, n, i, best)
    }
  }
  let out_vals : Array[@mpf.RawMpf] = []
  for v in vals {
    out_vals.push(@mpf.mpf_pos(v, self.precision(), self.round_mode()))
  }
  let q_out : Array[@mpf.RawMpf] = []
  for x in q {
    q_out.push(@mpf.mpf_pos(x, self.precision(), self.round_mode()))
  }
  (out_vals, { rows: n, cols: n, data: q_out })
}
