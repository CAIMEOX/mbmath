///|
fn MPContext::validate_ode_dimension(
  self : MPContext,
  name : StringView,
  y : ArrayView[@mpf.RawMpf],
  n : Int,
) -> Unit raise MPError {
  ignore(self)
  if y.length() != n {
    raise ValueError("\{name}: derivative dimension mismatch")
  }
}

///|
fn MPContext::shift_ode_state(
  self : MPContext,
  y : ArrayView[@mpf.RawMpf],
  k : ArrayView[@mpf.RawMpf],
  scale : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<y.length() {
    out.push(y[i].add(scale.mul(k[i], prec, Nearest), prec, Nearest))
  }
  ignore(self)
  out
}

///|
fn MPContext::combine_rk4_stages(
  self : MPContext,
  y : ArrayView[@mpf.RawMpf],
  k1 : ArrayView[@mpf.RawMpf],
  k2 : ArrayView[@mpf.RawMpf],
  k3 : ArrayView[@mpf.RawMpf],
  k4 : ArrayView[@mpf.RawMpf],
  h : @mpf.RawMpf,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  let h6 = checked_mpf_div_int(h, 6, prec, Nearest)
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<y.length() {
    let combo = k1[i]
      .add(k2[i].mul_int(2, prec, Nearest), prec, Nearest)
      .add(
        k3[i].mul_int(2, prec, Nearest).add(k4[i], prec, Nearest),
        prec,
        Nearest,
      )
    let next = y[i].add(h6.mul(combo, prec, Nearest), prec, Nearest)
    out.push(next.rounded(self.precision(), self.round_mode()))
  }
  out
}

///|
pub fn MPContext::ode_step_rk4(
  self : MPContext,
  f : (@mpf.RawMpf, ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] raise?,
  t : @mpf.RawMpf,
  y : ArrayView[@mpf.RawMpf],
  h : @mpf.RawMpf,
) -> Array[@mpf.RawMpf] raise {
  let n = y.length()
  let p = self.working_precision()
  let h2 = checked_mpf_div_int(h, 2, p, Nearest)
  let t2 = t.add(h2, p, Nearest)
  let t4 = t.add(h, p, Nearest)

  let k1 = f(t, y)
  self.validate_ode_dimension("ode_step_rk4", k1, n)
  let y2 = self.shift_ode_state(y, k1, h2, p)

  let k2 = f(t2, y2)
  self.validate_ode_dimension("ode_step_rk4", k2, n)
  let y3 = self.shift_ode_state(y, k2, h2, p)

  let k3 = f(t2, y3)
  self.validate_ode_dimension("ode_step_rk4", k3, n)
  let y4 = self.shift_ode_state(y, k3, h, p)

  let k4 = f(t4, y4)
  self.validate_ode_dimension("ode_step_rk4", k4, n)

  self.combine_rk4_stages(y, k1, k2, k3, k4, h, p)
}

///|
pub fn MPContext::ode_solve(
  self : MPContext,
  f : (@mpf.RawMpf, ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] raise?,
  t0 : @mpf.RawMpf,
  y0 : ArrayView[@mpf.RawMpf],
  t1 : @mpf.RawMpf,
  steps? : Int = 200,
) -> Array[@mpf.RawMpf] raise {
  if steps < 1 {
    raise ValueError("ode_solve: steps must be positive")
  }
  let p = self.working_precision()
  let h = checked_mpf_div(
    t1.sub(t0, p, Nearest),
    @mpf.RawMpf::from_int(steps),
    p,
    Nearest,
  )
  let mut t = t0
  let mut y = copy_mpf_vector(y0)
  for _ in 0..<steps {
    y = self.ode_step_rk4(f, t, y, h)
    t = t.add(h, p, Nearest)
  }
  y
}

///|
pub fn MPContext::ode_solve_grid(
  self : MPContext,
  f : (@mpf.RawMpf, ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] raise?,
  t0 : @mpf.RawMpf,
  y0 : ArrayView[@mpf.RawMpf],
  ts : ArrayView[@mpf.RawMpf],
  steps_per_interval? : Int = 128,
) -> Array[Array[@mpf.RawMpf]] raise {
  if steps_per_interval < 1 {
    raise ValueError("ode_solve_grid: steps_per_interval must be positive")
  }
  if ts.length() == 0 {
    return []
  }
  if !(ts[0] == t0) {
    raise ValueError("ode_solve_grid: ts[0] must equal t0")
  }
  let out : Array[Array[@mpf.RawMpf]] = []
  let mut t = t0
  let mut y = copy_mpf_vector(y0)
  out.push(copy_mpf_vector(y))
  for i in 1..<ts.length() {
    let t_next = ts[i]
    y = self.ode_solve(f, t, y, t_next, steps=steps_per_interval)
    t = t_next
    out.push(copy_mpf_vector(y))
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
    raise ValueError("eigsy: matrix must be square")
  }
  let n = a.rows
  if n == 0 {
    return ([], { rows: 0, cols: 0, data: [] })
  }
  if n == 1 {
    return (
      [a.data[0].rounded(self.precision(), self.round_mode())],
      self.eye(1),
    )
  }
  for i in 0..<n {
    for j in (i + 1)..<n {
      if !(a.data[matrix_offset(n, i, j)] == a.data[matrix_offset(n, j, i)]) {
        raise ValueError("eigsy: matrix must be symmetric")
      }
    }
  }
  let p = self.working_precision() + 24
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => {
      let s = if self.precision() > 0 { -(self.precision() / 2) } else { -40 }
      @mpf.RawMpf::from_mantissa_exponent(1N, s, 0, Down)
    }
  }
  let steps = if max_steps > 0 { max_steps } else { n * n * 32 }
  let work = copy_mpf_vector(a.data)
  let q0 = self.eye(n)
  let q = copy_mpf_vector(q0.data)
  let mut done = false
  for _ in 0..<steps {
    let mut p_idx = 0
    let mut q_idx = 1
    let mut max_off = @mpf.RawMpf::zero()
    for i in 0..<n {
      for j in (i + 1)..<n {
        let v = work[matrix_offset(n, i, j)].abs(p, Nearest)
        if v > max_off {
          max_off = v
          p_idx = i
          q_idx = j
        }
      }
    }
    if max_off <= tol_abs {
      done = true
      break
    }
    let app = work[matrix_offset(n, p_idx, p_idx)]
    let aqq = work[matrix_offset(n, q_idx, q_idx)]
    let apq = work[matrix_offset(n, p_idx, q_idx)]
    if apq.is_zero() {
      continue
    }
    let tau = checked_mpf_div(
      aqq.sub(app, p, Nearest),
      apq.mul_int(2, p, Nearest),
      p,
      Nearest,
    )
    let tau_abs = tau.abs(p, Nearest)
    let root = @mpf.RawMpf::one()
      .add(tau.mul(tau, p, Nearest), p, Nearest)
      .sqrt(p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    let denom = tau_abs.add(root, p, Nearest)
    let mut t = if denom.is_zero() {
      @mpf.RawMpf::one()
    } else {
      checked_mpf_div(@mpf.RawMpf::one(), denom, p, Nearest)
    }
    if tau.sign == 1 {
      t = t.negated(p, Nearest)
    }
    let c = checked_mpf_div(
      @mpf.RawMpf::one(),
      @mpf.RawMpf::one().add(t.mul(t, p, Nearest), p, Nearest).sqrt(p, Nearest) catch {
        err => raise from_mpf_error(err)
      },
      p,
      Nearest,
    )
    let s = t.mul(c, p, Nearest)
    let c2 = c.mul(c, p, Nearest)
    let s2 = s.mul(s, p, Nearest)
    let sc2 = s.mul(c, p, Nearest).mul_int(2, p, Nearest)
    for k in 0..<n {
      if k == p_idx || k == q_idx {
        continue
      }
      let aik = work[matrix_offset(n, k, p_idx)]
      let akq = work[matrix_offset(n, k, q_idx)]
      let new_aik = c
        .mul(aik, p, Nearest)
        .sub(s.mul(akq, p, Nearest), p, Nearest)
      let new_akq = s
        .mul(aik, p, Nearest)
        .add(c.mul(akq, p, Nearest), p, Nearest)
      work[matrix_offset(n, k, p_idx)] = new_aik
      work[matrix_offset(n, p_idx, k)] = new_aik
      work[matrix_offset(n, k, q_idx)] = new_akq
      work[matrix_offset(n, q_idx, k)] = new_akq
    }
    work[matrix_offset(n, p_idx, p_idx)] = c2
      .mul(app, p, Nearest)
      .sub(sc2.mul(apq, p, Nearest), p, Nearest)
      .add(s2.mul(aqq, p, Nearest), p, Nearest)
    work[matrix_offset(n, q_idx, q_idx)] = s2
      .mul(app, p, Nearest)
      .add(sc2.mul(apq, p, Nearest), p, Nearest)
      .add(c2.mul(aqq, p, Nearest), p, Nearest)
    work[matrix_offset(n, p_idx, q_idx)] = @mpf.RawMpf::zero()
    work[matrix_offset(n, q_idx, p_idx)] = @mpf.RawMpf::zero()

    for k in 0..<n {
      let vip = q[matrix_offset(n, k, p_idx)]
      let viq = q[matrix_offset(n, k, q_idx)]
      q[matrix_offset(n, k, p_idx)] = c
        .mul(vip, p, Nearest)
        .sub(s.mul(viq, p, Nearest), p, Nearest)
      q[matrix_offset(n, k, q_idx)] = s
        .mul(vip, p, Nearest)
        .add(c.mul(viq, p, Nearest), p, Nearest)
    }
  }
  if !done {
    raise ConvergenceError("eigsy: Jacobi iteration did not converge")
  }
  let vals : Array[@mpf.RawMpf] = []
  for i in 0..<n {
    vals.push(work[matrix_offset(n, i, i)])
  }
  for i in 0..<n {
    let mut best = i
    for j in (i + 1)..<n {
      if vals[j] < vals[best] {
        best = j
      }
    }
    if best != i {
      let t = vals[i]
      vals[i] = vals[best]
      vals[best] = t
      swap_matrix_columns(q, n, n, i, best)
    }
  }
  let out_vals : Array[@mpf.RawMpf] = []
  for v in vals {
    out_vals.push(v.rounded(self.precision(), self.round_mode()))
  }
  let q_out : Array[@mpf.RawMpf] = []
  for x in q {
    q_out.push(x.rounded(self.precision(), self.round_mode()))
  }
  (out_vals, { rows: n, cols: n, data: q_out })
}
