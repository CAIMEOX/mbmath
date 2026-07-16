///|
fn copy_mpf_array(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn reverse_mpf_array(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  let mut i = xs.length() - 1
  while i >= 0 {
    out.push(xs[i])
    i -= 1
  }
  out
}

///|
fn ascending_coefficients(
  coeffs : ArrayView[@mpf.RawMpf],
  asc : Bool,
) -> Array[@mpf.RawMpf] {
  if asc {
    copy_mpf_array(coeffs)
  } else {
    reverse_mpf_array(coeffs)
  }
}

///|
fn trim_ascending_polynomial(
  coeffs : ArrayView[@mpf.RawMpf],
) -> Array[@mpf.RawMpf] {
  if coeffs.length() == 0 {
    return []
  }
  let mut last = coeffs.length() - 1
  while last > 0 && coeffs[last].is_zero() {
    last -= 1
  }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<=last {
    out.push(coeffs[i])
  }
  out
}

///|
fn evaluate_polynomial_ascending(
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf {
  if coeffs.length() == 0 {
    return @mpf.RawMpf::zero()
  }
  let mut y = coeffs[coeffs.length() - 1]
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    y = y.mul(x, prec, Nearest).add(coeffs[i], prec, Nearest)
  }
  y
}

///|
fn evaluate_polynomial_and_derivative_ascending(
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  if coeffs.length() == 0 {
    return (@mpf.RawMpf::zero(), @mpf.RawMpf::zero())
  }
  let mut y = coeffs[coeffs.length() - 1]
  let mut dy = @mpf.RawMpf::zero()
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    dy = dy.mul(x, prec, Nearest).add(y, prec, Nearest)
    y = y.mul(x, prec, Nearest).add(coeffs[i], prec, Nearest)
  }
  (y, dy)
}

///|
/// Polynomial evaluation helper aligned with mpmath `polyval`.
///
/// - `asc=true`: coefficients are `[a0, a1, ...]`.
/// - `asc=false`: coefficients are `[an, ..., a0]`.
pub fn MPContext::polyval(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  asc? : Bool = true,
) -> @mpf.RawMpf {
  let p = self.working_precision()
  let c = ascending_coefficients(coeffs, asc)
  evaluate_polynomial_ascending(c, x, p).rounded(
    self.precision(),
    self.round_mode(),
  )
}

///|
/// Polynomial evaluation with derivative (`f(x)`, `f'(x)`).
pub fn MPContext::polyval_with_derivative(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  asc? : Bool = true,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  let p = self.working_precision()
  let c = ascending_coefficients(coeffs, asc)
  let (y, dy) = evaluate_polynomial_and_derivative_ascending(c, x, p)
  (
    y.rounded(self.precision(), self.round_mode()),
    dy.rounded(self.precision(), self.round_mode()),
  )
}

///|
fn aitken_delta_squared(
  x0 : @mpf.RawMpf,
  x1 : @mpf.RawMpf,
  x2 : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, Bool) raise MPError {
  let d1 = x1.sub(x0, prec, Nearest)
  let d2 = x2.sub(x1, prec, Nearest)
  let den = d2.sub(d1, prec, Nearest)
  if den.is_zero() {
    return (x2, false)
  }
  let num = d2.mul(d2, prec, Nearest)
  let corr = num.div(den, prec, Nearest) catch {
    err => raise from_mpf_error(err)
  }
  (x2.sub(corr, prec, Nearest), true)
}

///|
fn MPContext::limit_tolerance(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -56 } else if prec > 120 { -44 } else { -36 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
fn MPContext::evaluate_finite_limit(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  direction : Int,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let tol = self.limit_tolerance(prec)
  let mut h = self.differentiation_step(x, 1, prec)
  if h.is_zero() {
    h = @mpf.RawMpf::from_mantissa_exponent(1N, -12, 0, Down)
  }
  let seq : Array[@mpf.RawMpf] = []
  for _ in 0..<max_steps {
    let y = if direction > 0 {
      f(x.add(h, prec, Nearest))
    } else if direction < 0 {
      f(x.sub(h, prec, Nearest))
    } else {
      let yp = f(x.add(h, prec, Nearest))
      let ym = f(x.sub(h, prec, Nearest))
      yp
      .add(ym, prec, Nearest)
      .mul(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), prec, Nearest)
    }
    require_finite_value("limit", y)
    seq.push(y)
    if seq.length() >= 3 {
      let n = seq.length()
      let (acc, ok) = aitken_delta_squared(
        seq[n - 3],
        seq[n - 2],
        seq[n - 1],
        prec,
      )
      if ok {
        let err = acc.sub(seq[n - 1], prec, Nearest).abs(prec, Nearest)
        if err <= tol {
          return acc.rounded(self.precision(), self.round_mode())
        }
      } else {
        let err = seq[n - 1].sub(seq[n - 2], prec, Nearest).abs(prec, Nearest)
        if err <= tol {
          return seq[n - 1].rounded(self.precision(), self.round_mode())
        }
      }
    }
    h = h.mul(
      @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down),
      prec,
      Nearest,
    )
  }
  if seq.length() > 0 {
    return seq[seq.length() - 1].rounded(self.precision(), self.round_mode())
  }
  raise ConvergenceError("limit: sequence did not converge")
}

///|
/// Numerical limit for real-valued unary functions.
///
/// Supports finite points and `x = +/-inf`.
pub fn MPContext::limit(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  direction? : Int = 0,
  max_steps? : Int = 32,
) -> @mpf.RawMpf raise {
  let p = self.working_precision()
  if !x.is_infinite() {
    return self.evaluate_finite_limit(f, x, direction, max_steps, p)
  }
  let dir = if x.sign == 0 { 1 } else { -1 }
  let g = (u : @mpf.RawMpf) => {
    let inv = @mpf.RawMpf::one().div(u, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    let arg = if dir > 0 { inv } else { inv.negated(p, Nearest) }
    f(arg)
  }
  self.evaluate_finite_limit(g, @mpf.RawMpf::zero(), 1, max_steps, p)
}

///|
/// Polynomial least-error fit on `[a,b]` using Chebyshev nodes.
///
/// Returns `(coeffs, estimated_max_error)` with coefficient order controlled by
/// `asc`.
pub fn MPContext::chebyfit(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  n : Int,
  asc? : Bool = true,
) -> (Array[@mpf.RawMpf], @mpf.RawMpf) raise {
  if n < 1 {
    raise ValueError("chebyfit: n must be positive")
  }
  let p = self.working_precision() + 32
  let (a, b) = interval
  let mid = a
    .add(b, p, Nearest)
    .mul(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), p, Nearest)
  let half = b
    .sub(a, p, Nearest)
    .mul(@mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down), p, Nearest)
  let pi = checked_mpf_pi(p, Nearest)
  let xs : Array[@mpf.RawMpf] = []
  let ys : Array[@mpf.RawMpf] = []
  for k in 0..<n {
    let theta = pi
      .mul(@mpf.RawMpf::from_int(2 * k + 1), p, Nearest)
      .div(@mpf.RawMpf::from_int(2 * n), p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    let t = checked_mpf_cos(theta, p, Nearest)
    let xk = mid.add(half.mul(t, p, Nearest), p, Nearest)
    xs.push(xk)
    ys.push(f(xk))
  }
  let v = self.matrix(n, n)
  for i in 0..<n {
    let mut pow = @mpf.RawMpf::one()
    for j in 0..<n {
      v.set(i, j, pow)
      pow = pow.mul(xs[i], p, Nearest)
    }
  }
  let coeffs_asc = self.lu_solve(v, ys)
  let mut err = @mpf.RawMpf::zero()
  let m = 8 * n + 1
  for i in 0..<m {
    let xi = a.add(
      b
      .sub(a, p, Nearest)
      .mul(@mpf.RawMpf::from_int(i), p, Nearest)
      .div(@mpf.RawMpf::from_int(m - 1), p, Nearest) catch {
        err2 => raise from_mpf_error(err2)
      },
      p,
      Nearest,
    )
    let py = evaluate_polynomial_ascending(coeffs_asc, xi, p)
    let fy = f(xi)
    let d = py.sub(fy, p, Nearest).abs(p, Nearest)
    if d > err {
      err = d
    }
  }
  let coeffs = if asc { coeffs_asc } else { reverse_mpf_array(coeffs_asc) }
  (coeffs, err.rounded(self.precision(), self.round_mode()))
}

///|
fn evaluate_complex_polynomial_ascending(
  coeffs : ArrayView[@mpf.RawMpf],
  z : @mpc.RawMpc,
  prec : Int,
) -> @mpc.RawMpc {
  if coeffs.length() == 0 {
    return @mpc.RawMpc::zero()
  }
  let mut y = @mpc.RawMpc::new(coeffs[coeffs.length() - 1], @mpf.RawMpf::zero())
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    y = y.mul(z, prec, Nearest).add_real(coeffs[i], prec, Nearest)
  }
  y
}

///|
fn sort_polynomial_roots(roots : Array[@mpc.RawMpc], prec : Int) -> Unit {
  let n = roots.length()
  if n < 2 {
    return
  }
  for i in 0..<n {
    for j in 0..<(n - 1 - i) {
      let r0 = roots[j]
      let r1 = roots[j + 1]
      let swap = if r1.real < r0.real {
        true
      } else if r0.real == r1.real && r1.imag < r0.imag {
        true
      } else {
        false
      }
      if swap {
        let t = roots[j]
        roots[j] = roots[j + 1]
        roots[j + 1] = t
      }
    }
  }
  ignore(prec)
}

///|
fn polynomial_root_tolerance(prec : Int) -> @mpf.RawMpf {
  let shift = if prec > 200 { -56 } else if prec > 120 { -44 } else { -34 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
fn is_legendre_polynomial(c : ArrayView[@mpf.RawMpf]) -> Bool {
  let n = c.length() - 1
  if n < 8 || (n & 1) == 1 {
    return false
  }
  let mut i = 1
  while i < c.length() {
    if !c[i].is_zero() {
      return false
    }
    i += 2
  }
  true
}

///|
fn MPContext::solve_legendre_polynomial_roots(
  self : MPContext,
  c : ArrayView[@mpf.RawMpf],
  p : Int,
) -> Array[@mpc.RawMpc] raise MPError {
  ignore(self)
  let n = c.length() - 1
  let d : Array[@mpf.RawMpf] = []
  for i in 1..<=n {
    d.push(c[i].mul_int(i, p, Nearest))
  }
  let pi = checked_mpf_pi(p, Nearest)
  let tol = polynomial_root_tolerance(p)
  let roots : Array[@mpf.RawMpf] = []
  for k in 1..<=n {
    let theta = pi
      .mul_int(4 * k - 1, p, Nearest)
      .div(@mpf.RawMpf::from_int(4 * n + 2), p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    let mut x = checked_mpf_cos(theta, p, Nearest)
    for _ in 0..<48 {
      let px = evaluate_polynomial_ascending(c, x, p)
      let dpx = evaluate_polynomial_ascending(d, x, p)
      if dpx.is_zero() {
        break
      }
      let dx = px.div(dpx, p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
      x = x.sub(dx, p, Nearest)
      if dx.abs(p, Nearest) <= tol {
        break
      }
    }
    if x < @mpf.RawMpf::negative_one() {
      x = @mpf.RawMpf::negative_one().add(
        @mpf.RawMpf::from_mantissa_exponent(1N, -20, 0, Down),
        p,
        Nearest,
      )
    } else if x > @mpf.RawMpf::one() {
      x = @mpf.RawMpf::one().sub(
        @mpf.RawMpf::from_mantissa_exponent(1N, -20, 0, Down),
        p,
        Nearest,
      )
    }
    roots.push(x)
  }
  let m = roots.length()
  for i in 0..<m {
    for j in 0..<(m - 1 - i) {
      if roots[j] > roots[j + 1] {
        let t = roots[j]
        roots[j] = roots[j + 1]
        roots[j + 1] = t
      }
    }
  }
  let out : Array[@mpc.RawMpc] = []
  for r in roots {
    out.push(@mpc.RawMpc::new(r, @mpf.RawMpf::zero()))
  }
  out
}

///|
fn MPContext::solve_companion_matrix_roots(
  self : MPContext,
  c : ArrayView[@mpf.RawMpf],
  lead : @mpf.RawMpf,
  p : Int,
) -> Array[@mpc.RawMpc] raise MPError {
  let n = c.length() - 1
  let comp = self.matrix(n, n)
  for j in 0..<n {
    let bj = c[n - 1 - j].div(lead, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    comp.set(0, j, bj.negated(p, Nearest))
  }
  for i in 1..<n {
    comp.set(i, i - 1, @mpf.RawMpf::one())
  }
  let (vals, _) = self.eig(comp, max_steps=1600)
  let rs : Array[@mpf.RawMpf] = []
  for v in vals {
    rs.push(v)
  }
  let m = rs.length()
  for i in 0..<m {
    for j in 0..<(m - 1 - i) {
      if rs[j] > rs[j + 1] {
        let t = rs[j]
        rs[j] = rs[j + 1]
        rs[j + 1] = t
      }
    }
  }
  let out : Array[@mpc.RawMpc] = []
  for r in rs {
    out.push(@mpc.RawMpc::new(r, @mpf.RawMpf::zero()))
  }
  out
}

///|
fn MPContext::solve_polynomial_roots(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  asc : Bool,
  max_steps : Int,
  cleanup : Bool,
  extraprec : Int,
  roots_init : ArrayView[@mpf.RawMpf],
  use_init : Bool,
) -> (Array[@mpc.RawMpc], @mpf.RawMpf) raise MPError {
  let c0 = ascending_coefficients(coeffs, asc)
  let c = trim_ascending_polynomial(c0)
  if c.length() == 0 {
    raise ValueError("polyroots: empty coefficient list")
  }
  if c.length() == 1 {
    if c[0].is_zero() {
      raise ValueError("polyroots: zero polynomial")
    }
    return ([], @mpf.RawMpf::zero())
  }
  let n = c.length() - 1
  let p0 = self.working_precision() + extraprec
  let p = if p0 > 512 { 512 } else { p0 }
  let lead = c[n]
  if lead.is_zero() {
    raise ValueError("polyroots: leading coefficient must be non-zero")
  }
  if n == 1 {
    let r = c[0].negated(p, Nearest).div(c[1], p, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    return (
      [
        @mpc.RawMpc::new(
          r.rounded(self.precision(), self.round_mode()),
          @mpf.RawMpf::zero(),
        ),
      ],
      @mpf.RawMpf::zero(),
    )
  }
  if n == 2 {
    let a0 = c[0]
    let a1 = c[1]
    let a2 = c[2]
    let two = @mpf.RawMpf::from_int(2)
    let four = @mpf.RawMpf::from_int(4)
    let disc = a1
      .mul(a1, p, Nearest)
      .sub(four.mul(a2, p, Nearest).mul(a0, p, Nearest), p, Nearest)
    let den = two.mul(a2, p, Nearest)
    let roots2 : Array[@mpc.RawMpc] = []
    if disc >= @mpf.RawMpf::zero() {
      let s = disc.sqrt(p, Nearest) catch { err => raise from_mpf_error(err) }
      let r0 = a1.negated(p, Nearest).sub(s, p, Nearest).div(den, p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      let r1 = a1.negated(p, Nearest).add(s, p, Nearest).div(den, p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      roots2.push(@mpc.RawMpc::new(r0, @mpf.RawMpf::zero()))
      roots2.push(@mpc.RawMpc::new(r1, @mpf.RawMpf::zero()))
    } else {
      let s = disc.negated(p, Nearest).sqrt(p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      let re = a1.negated(p, Nearest).div(den, p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      let im = s.div(den, p, Nearest) catch { err => raise from_mpf_error(err) }
      roots2.push(@mpc.RawMpc::new(re, im.negated(p, Nearest)))
      roots2.push(@mpc.RawMpc::new(re, im))
    }
    let out2 : Array[@mpc.RawMpc] = []
    for r in roots2 {
      out2.push(r.rounded(self.precision(), self.round_mode()))
    }
    return (out2, @mpf.RawMpf::zero())
  }

  let roots : Array[@mpc.RawMpc] = []
  if use_init && roots_init.length() > 0 {
    let m = if roots_init.length() < n { roots_init.length() } else { n }
    for i in 0..<m {
      roots.push(@mpc.RawMpc::new(roots_init[i], @mpf.RawMpf::zero()))
    }
  }
  if roots.length() < n {
    let mut radius = @mpf.RawMpf::one()
    for i in 0..<n {
      let qi = c[i].abs(p, Nearest).div(lead.abs(p, Nearest), p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      if qi > radius {
        radius = qi
      }
    }
    radius = radius.add(@mpf.RawMpf::one(), p, Nearest)
    let pi = checked_mpf_pi(p, Nearest)
    for i in roots.length()..<n {
      let theta = pi
        .mul_int(2 * i, p, Nearest)
        .div(@mpf.RawMpf::from_int(n), p, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      let re = radius.mul(checked_mpf_cos(theta, p, Nearest), p, Nearest)
      let im = radius.mul(checked_mpf_sin(theta, p, Nearest), p, Nearest)
      roots.push(@mpc.RawMpc::new(re, im))
    }
  }

  let tol = polynomial_root_tolerance(p)
  let sep_tol = @mpf.RawMpf::from_mantissa_exponent(1N, -20, 0, Down)
  let mut max_update = @mpf.RawMpf::infinity()
  for _ in 0..<max_steps {
    max_update = @mpf.RawMpf::zero()
    for i in 0..<n {
      let zi = roots[i]
      let pz = evaluate_complex_polynomial_ascending(c, zi, p)
      let mut den = @mpc.RawMpc::one()
      for j in 0..<n {
        if i == j {
          continue
        }
        den = den.mul(zi.sub(roots[j], p, Nearest), p, Nearest)
      }
      let den_abs = checked_mpc_abs(den, p, Nearest)
      if den_abs <= sep_tol {
        continue
      }
      let delta = checked_mpc_div(pz, den, p, Nearest)
      roots[i] = zi.sub(delta, p, Nearest)
      let du = checked_mpc_abs(delta, p, Nearest)
      if du > max_update {
        max_update = du
      }
    }
    if max_update <= tol {
      break
    }
  }
  if max_update > tol {
    if max_steps >= 10 {
      let fallback = if is_legendre_polynomial(c) {
        self.solve_legendre_polynomial_roots(c, p)
      } else {
        self.solve_companion_matrix_roots(c, lead, p)
      }
      let mut err_fb = @mpf.RawMpf::zero()
      for r in fallback {
        let rz = evaluate_complex_polynomial_ascending(c, r, p)
        let re = checked_mpc_abs(rz, p, Nearest)
        if re > err_fb {
          err_fb = re
        }
      }
      let out_fb : Array[@mpc.RawMpc] = []
      for r in fallback {
        out_fb.push(r.rounded(self.precision(), self.round_mode()))
      }
      return (out_fb, err_fb.rounded(self.precision(), self.round_mode()))
    }
    raise ConvergenceError("polyroots: Durand-Kerner did not converge")
  }

  let clean_tol = @mpf.RawMpf::from_mantissa_exponent(1N, -24, 0, Down)
  if cleanup {
    for i in 0..<n {
      if roots[i].imag.abs(p, Nearest) <= clean_tol {
        roots[i] = @mpc.RawMpc::new(roots[i].real, @mpf.RawMpf::zero())
      }
    }
  }
  sort_polynomial_roots(roots, p)

  let mut err = @mpf.RawMpf::zero()
  for r in roots {
    let rz = evaluate_complex_polynomial_ascending(c, r, p)
    let re = checked_mpc_abs(rz, p, Nearest)
    if re > err {
      err = re
    }
  }

  let out : Array[@mpc.RawMpc] = []
  for r in roots {
    out.push(r.rounded(self.precision(), self.round_mode()))
  }
  (out, err.rounded(self.precision(), self.round_mode()))
}

///|
/// Polynomial roots for real coefficients.
pub fn MPContext::polyroots(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  asc? : Bool = true,
  max_steps? : Int = 60,
  cleanup? : Bool = true,
  extraprec? : Int = 0,
) -> Array[@mpc.RawMpc] raise MPError {
  let (r, _) = self.solve_polynomial_roots(
    coeffs,
    asc,
    max_steps,
    cleanup,
    extraprec,
    [],
    false,
  )
  r
}

///|
/// Polynomial roots with explicit initial guesses and error estimate.
pub fn MPContext::polyroots_with_init_error(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  roots_init : ArrayView[@mpf.RawMpf],
  asc? : Bool = true,
  max_steps? : Int = 60,
  cleanup? : Bool = true,
  extraprec? : Int = 0,
) -> (Array[@mpc.RawMpc], @mpf.RawMpf) raise MPError {
  self.solve_polynomial_roots(
    coeffs, asc, max_steps, cleanup, extraprec, roots_init, true,
  )
}

///|
pub fn MPContext::polyroots_error(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  asc? : Bool = true,
  max_steps? : Int = 60,
  cleanup? : Bool = true,
  extraprec? : Int = 0,
) -> (Array[@mpc.RawMpc], @mpf.RawMpf) raise MPError {
  self.solve_polynomial_roots(
    coeffs,
    asc,
    max_steps,
    cleanup,
    extraprec,
    [],
    false,
  )
}

///|
/// Pade approximation from a power-series prefix `a`.
///
/// Returns numerator/denominator coefficient arrays `(p, q)` in ascending
/// order.
pub fn MPContext::pade(
  self : MPContext,
  a : ArrayView[@mpf.RawMpf],
  m : Int,
  n : Int,
) -> (Array[@mpf.RawMpf], Array[@mpf.RawMpf]) raise MPError {
  if m < 0 || n < 0 {
    raise ValueError("pade: m and n must be non-negative")
  }
  if a.length() < m + n + 1 {
    raise ValueError("pade: insufficient series coefficients")
  }
  let p = self.working_precision() + 16
  let q : Array[@mpf.RawMpf] = []
  q.push(@mpf.RawMpf::one())
  if n > 0 {
    let mat = self.matrix(n, n)
    let rhs : Array[@mpf.RawMpf] = []
    for row in 0..<n {
      let k = m + 1 + row
      for col in 0..<n {
        mat.set(row, col, a[k - 1 - col])
      }
      rhs.push(a[k].negated(p, Nearest))
    }
    let tail = self.lu_solve(mat, rhs)
    for t in tail {
      q.push(t)
    }
  }
  let pcoef : Array[@mpf.RawMpf] = []
  for i in 0..<=m {
    let mut s = @mpf.RawMpf::zero()
    let jmax = if i < n { i } else { n }
    for j in 0..<=jmax {
      s = s.add(q[j].mul(a[i - j], p, Nearest), p, Nearest)
    }
    pcoef.push(s.rounded(self.precision(), self.round_mode()))
  }
  let qout : Array[@mpf.RawMpf] = []
  for x in q {
    qout.push(x.rounded(self.precision(), self.round_mode()))
  }
  (pcoef, qout)
}

///|
/// Fourier coefficients on interval `[a,b]` up to order `n`.
///
/// Returns `(c, s)` where
/// `f(x) ~ c0 + sum_{k>=1}(c[k] cos(k*w*(x-a)) + s[k] sin(k*w*(x-a)))`.
pub fn MPContext::fourier(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  n : Int,
) -> (Array[@mpf.RawMpf], Array[@mpf.RawMpf]) raise {
  if n < 0 {
    raise ValueError("fourier: n must be non-negative")
  }
  let p = self.working_precision()
  let (a, b) = interval
  let l = b.sub(a, p, Nearest)
  if l.is_zero() {
    raise ValueError("fourier: interval length must be non-zero")
  }
  let pi = checked_mpf_pi(p, Nearest)
  let w = pi.mul_int(2, p, Nearest).div(l, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
  let c : Array[@mpf.RawMpf] = []
  let s : Array[@mpf.RawMpf] = []
  let mean = self.quadts(f, a, b, max_steps=14)
  c.push(
    mean.div(l, self.precision(), self.round_mode()) catch {
      err => raise from_mpf_error(err)
    },
  )
  s.push(@mpf.RawMpf::zero())
  for k in 1..<=n {
    let kk = @mpf.RawMpf::from_int(k)
    let cosk = (x : @mpf.RawMpf) => {
      let arg = w.mul(kk, p, Nearest).mul(x, p, Nearest)
      f(x).mul(checked_mpf_cos(arg, p, Nearest), p, Nearest)
    }
    let sink = (x : @mpf.RawMpf) => {
      let arg = w.mul(kk, p, Nearest).mul(x, p, Nearest)
      f(x).mul(checked_mpf_sin(arg, p, Nearest), p, Nearest)
    }
    let ic = self.quadts(cosk, a, b, max_steps=14)
    let is0 = self.quadts(sink, a, b, max_steps=14)
    let scale = @mpf.RawMpf::from_int(2).div(l, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    c.push(ic.mul(scale, self.precision(), self.round_mode()))
    s.push(is0.mul(scale, self.precision(), self.round_mode()))
  }
  (c, s)
}

///|
/// Evaluate a Fourier series from `(c, s)` coefficient arrays.
pub fn MPContext::fourierval(
  self : MPContext,
  coeffs : (Array[@mpf.RawMpf], Array[@mpf.RawMpf]),
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  x : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let p = self.working_precision()
  let (c, s) = coeffs
  if c.length() == 0 {
    return @mpf.RawMpf::zero()
  }
  let (a, b) = interval
  let l = b.sub(a, p, Nearest)
  if l.is_zero() {
    raise ValueError("fourierval: interval length must be non-zero")
  }
  let n = if c.length() < s.length() { c.length() - 1 } else { s.length() - 1 }
  let pi = checked_mpf_pi(p, Nearest)
  let w = pi.mul_int(2, p, Nearest).div(l, p, Nearest) catch {
      err => raise from_mpf_error(err)
    }
  let mut y = c[0]
  for k in 1..<=n {
    let arg = w.mul_int(k, p, Nearest).mul(x, p, Nearest)
    y = y.add(
      c[k]
      .mul(checked_mpf_cos(arg, p, Nearest), p, Nearest)
      .add(s[k].mul(checked_mpf_sin(arg, p, Nearest), p, Nearest), p, Nearest),
      p,
      Nearest,
    )
  }
  y.rounded(self.precision(), self.round_mode())
}

///|
fn exact_integer_value(x : @mpf.RawMpf) -> Int? {
  if !x.is_finite() {
    return None
  }
  if x.is_zero() {
    return Some(0)
  }
  if x.exp < 0 {
    return None
  }
  let v = x.man << x.exp
  if v.bit_length() > 60 {
    return None
  }
  let n = v.to_int()
  let signed_n = if x.sign == 1 { -n } else { n }
  if x == @mpf.RawMpf::from_int(signed_n) {
    Some(signed_n)
  } else {
    None
  }
}

///|
/// Fractional differintegral subset.
///
/// Currently supports `a <= 0` (fractional integrals) for finite positive `x`.
pub fn MPContext::differint(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  a : @mpf.RawMpf,
) -> @mpf.RawMpf raise {
  let p = self.working_precision() + 24
  if a.is_nan() || x.is_nan() {
    raise ValueError("differint: nan input")
  }
  if a.is_zero() {
    return f(x)
  }
  if a > @mpf.RawMpf::zero() {
    match exact_integer_value(a) {
      Some(n) =>
        if n < 0 {
          raise ValueError("differint: order must be finite real")
        } else {
          return self.diff(f, x, n~)
        }
      None =>
        raise ValueError("differint: positive non-integer order not supported")
    }
  }
  if !x.is_finite() || x < @mpf.RawMpf::zero() {
    raise DomainError("differint: require finite non-negative x")
  }
  let beta = a.negated(p, Nearest)
  let gamma_beta = @gammazeta.gamma(beta, p, Nearest) catch {
    err => raise from_gammazeta_error(err)
  }
  let g = (u : @mpf.RawMpf) => {
    if u.is_zero() {
      return f(x)
    }
    let u2 = u.mul(u, p, Nearest)
    let one_minus_u2 = @mpf.RawMpf::one().sub(u2, p, Nearest)
    let t = x.mul(one_minus_u2, p, Nearest)
    let xm_t = x.sub(t, p, Nearest)
    let kernel = @libelefun.pow(
      xm_t,
      beta.sub(@mpf.RawMpf::one(), p, Nearest),
      p,
      Nearest,
    ) catch {
      err => raise from_libelefun_error(err)
    }
    let jac = x.mul(u, p, Nearest).mul_int(2, p, Nearest)
    kernel.mul(f(t), p, Nearest).mul(jac, p, Nearest)
  }
  let integ = self.quadts(
    g,
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::one(),
    max_steps=10,
  )
  integ.div(gamma_beta, self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn stehfest_coefficient(
  n : Int,
  k : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let nh = n / 2
  let jmin = (k + 1) / 2
  let jmax = if k < nh { k } else { nh }
  let mut vk = @mpf.RawMpf::zero()
  for j in jmin..<=jmax {
    let jp = @mpf.RawMpf::from_int(j)
    let mut term = @libelefun.pow(jp, @mpf.RawMpf::from_int(nh), prec, Nearest) catch {
      err => raise from_libelefun_error(err)
    }
    let f2j = @gammazeta.factorial(2 * j, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    term = term.mul(f2j, prec, Nearest)
    let d0 = @gammazeta.factorial(nh - j, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d1 = @gammazeta.factorial(j, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d2 = @gammazeta.factorial(j - 1, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d3 = @gammazeta.factorial(k - j, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d4 = @gammazeta.factorial(2 * j - k, prec, Nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let den = d0
      .mul(d1, prec, Nearest)
      .mul(d2.mul(d3.mul(d4, prec, Nearest), prec, Nearest), prec, Nearest)
    term = term.div(den, prec, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    vk = vk.add(term, prec, Nearest)
  }
  if ((k + nh) & 1) == 1 {
    vk.negated(prec, Nearest)
  } else {
    vk
  }
}

///|
/// Inverse Laplace transform subset with method-compatible interface.
///
/// Implemented using a Stehfest core for positive real `t`; accepted methods:
/// `talbot`, `stehfest`, `dehoog`, `cohen`.
pub fn MPContext::invertlaplace(
  self : MPContext,
  fp : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  t : @mpf.RawMpf,
  algo? : StringView = "talbot",
) -> @mpf.RawMpf raise {
  if !t.is_finite() || t <= @mpf.RawMpf::zero() {
    raise DomainError("invertlaplace: require finite positive t")
  }
  let key = algo.to_lower()
  match key {
    "talbot" => ()
    "stehfest" => ()
    "dehoog" => ()
    "cohen" => ()
    _ => raise ValueError("invertlaplace: unknown method '\{algo}'")
  }
  let p = self.working_precision() + 32
  let n = 14
  let ln2 = checked_mpf_ln2(p, Nearest)
  let scale = ln2.div(t, p, Nearest) catch { err => raise from_mpf_error(err) }
  let mut s = @mpf.RawMpf::zero()
  for k in 1..<=n {
    let vk = stehfest_coefficient(n, k, p)
    let arg = scale.mul_int(k, p, Nearest)
    s = s.add(vk.mul(fp(arg), p, Nearest), p, Nearest)
  }
  scale.mul(s, self.precision(), self.round_mode())
}

///|
fn require_square_matrix(
  a : MpfMatrix,
  name : StringView,
) -> Unit raise MPError {
  if a.rows != a.cols {
    raise ValueError("\{name}: matrix must be square")
  }
}

///|
fn MPContext::matrix_series_tolerance(
  self : MPContext,
  prec : Int,
) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -64 } else if prec > 120 { -52 } else { -40 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
/// Matrix exponential via power series.
pub fn MPContext::expm(
  self : MPContext,
  a : MpfMatrix,
  max_terms? : Int = 180,
) -> MpfMatrix raise MPError {
  require_square_matrix(a, "expm")
  let p = self.working_precision() + 24
  let tol = self.matrix_series_tolerance(p)
  let mut sum = self.eye(a.rows)
  let mut term = self.eye(a.rows)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a)
    term = self.matrix_div_scalar(term, @mpf.RawMpf::from_int(k))
    sum = self.matrix_add(sum, term)
    if self.matrix_norm_inf(term) <= tol {
      break
    }
  }
  sum
}

///|
/// Matrix cosine via power series.
pub fn MPContext::cosm(
  self : MPContext,
  a : MpfMatrix,
  max_terms? : Int = 180,
) -> MpfMatrix raise MPError {
  require_square_matrix(a, "cosm")
  let p = self.working_precision() + 24
  let tol = self.matrix_series_tolerance(p)
  let a2 = self.matrix_mul(a, a)
  let mut sum = self.eye(a.rows)
  let mut term = self.eye(a.rows)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a2)
    term = self.matrix_div_scalar(
      term,
      @mpf.RawMpf::from_int((2 * k - 1) * (2 * k)),
    )
    term = self.matrix_scale(term, @mpf.RawMpf::negative_one())
    sum = self.matrix_add(sum, term)
    if self.matrix_norm_inf(term) <= tol {
      break
    }
  }
  sum
}

///|
/// Matrix sine via power series.
pub fn MPContext::sinm(
  self : MPContext,
  a : MpfMatrix,
  max_terms? : Int = 180,
) -> MpfMatrix raise MPError {
  require_square_matrix(a, "sinm")
  let p = self.working_precision() + 24
  let tol = self.matrix_series_tolerance(p)
  let a2 = self.matrix_mul(a, a)
  let mut sum = self.matrix_copy(a)
  let mut term = self.matrix_copy(a)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a2)
    term = self.matrix_div_scalar(
      term,
      @mpf.RawMpf::from_int(2 * k * (2 * k + 1)),
    )
    term = self.matrix_scale(term, @mpf.RawMpf::negative_one())
    sum = self.matrix_add(sum, term)
    if self.matrix_norm_inf(term) <= tol {
      break
    }
  }
  sum
}
