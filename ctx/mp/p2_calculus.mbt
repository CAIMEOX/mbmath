///|
fn p2_copy_mpf_array(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn p2_reverse_mpf(xs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  let out : Array[@mpf.RawMpf] = []
  let mut i = xs.length() - 1
  while i >= 0 {
    out.push(xs[i])
    i -= 1
  }
  out
}

///|
fn p2_to_asc_coeffs(
  coeffs : ArrayView[@mpf.RawMpf],
  asc : Bool,
) -> Array[@mpf.RawMpf] {
  if asc {
    p2_copy_mpf_array(coeffs)
  } else {
    p2_reverse_mpf(coeffs)
  }
}

///|
fn p2_trim_poly_asc(coeffs : ArrayView[@mpf.RawMpf]) -> Array[@mpf.RawMpf] {
  if coeffs.length() == 0 {
    return []
  }
  let mut last = coeffs.length() - 1
  while last > 0 && @mpf.is_zero(coeffs[last]) {
    last -= 1
  }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<=last {
    out.push(coeffs[i])
  }
  out
}

///|
fn p2_poly_eval_horner_asc(
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf {
  if coeffs.length() == 0 {
    return @mpf.fzero
  }
  let mut y = coeffs[coeffs.length() - 1]
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    y = @mpf.mpf_add(
      @mpf.mpf_mul(y, x, prec, @mpf.round_nearest),
      coeffs[i],
      prec,
      @mpf.round_nearest,
    )
  }
  y
}

///|
fn p2_poly_eval_horner_with_deriv_asc(
  coeffs : ArrayView[@mpf.RawMpf],
  x : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) {
  if coeffs.length() == 0 {
    return (@mpf.fzero, @mpf.fzero)
  }
  let mut y = coeffs[coeffs.length() - 1]
  let mut dy = @mpf.fzero
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    dy = @mpf.mpf_add(
      @mpf.mpf_mul(dy, x, prec, @mpf.round_nearest),
      y,
      prec,
      @mpf.round_nearest,
    )
    y = @mpf.mpf_add(
      @mpf.mpf_mul(y, x, prec, @mpf.round_nearest),
      coeffs[i],
      prec,
      @mpf.round_nearest,
    )
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
  let p = self.p2_work_prec()
  let c = p2_to_asc_coeffs(coeffs, asc)
  @mpf.mpf_pos(
    p2_poly_eval_horner_asc(c, x, p),
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
  let p = self.p2_work_prec()
  let c = p2_to_asc_coeffs(coeffs, asc)
  let (y, dy) = p2_poly_eval_horner_with_deriv_asc(c, x, p)
  (
    @mpf.mpf_pos(y, self.precision(), self.round_mode()),
    @mpf.mpf_pos(dy, self.precision(), self.round_mode()),
  )
}

///|
fn p2_aitken(
  x0 : @mpf.RawMpf,
  x1 : @mpf.RawMpf,
  x2 : @mpf.RawMpf,
  prec : Int,
) -> (@mpf.RawMpf, Bool) {
  let d1 = @mpf.mpf_sub(x1, x0, prec, @mpf.round_nearest)
  let d2 = @mpf.mpf_sub(x2, x1, prec, @mpf.round_nearest)
  let den = @mpf.mpf_sub(d2, d1, prec, @mpf.round_nearest)
  if @mpf.is_zero(den) {
    return (x2, false)
  }
  let num = @mpf.mpf_mul(d2, d2, prec, @mpf.round_nearest)
  let corr = @mpf.mpf_div(num, den, prec, @mpf.round_nearest) catch {
    _ => return (x2, false)
  }
  (@mpf.mpf_sub(x2, corr, prec, @mpf.round_nearest), true)
}

///|
fn MPContext::p2_limit_tol(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -56 } else if prec > 120 { -44 } else { -36 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
fn MPContext::p2_limit_at_finite(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  direction : Int,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let tol = self.p2_limit_tol(prec)
  let mut h = self.p2_diff_step(x, 1, prec)
  if @mpf.is_zero(h) {
    h = @mpf.from_man_exp(1N, -12, 0, @mpf.round_down)
  }
  let seq : Array[@mpf.RawMpf] = []
  for _ in 0..<max_steps {
    let y = if direction > 0 {
      f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
    } else if direction < 0 {
      f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
    } else {
      let yp = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
      let ym = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
      @mpf.mpf_mul(
        @mpf.mpf_add(yp, ym, prec, @mpf.round_nearest),
        @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
        prec,
        @mpf.round_nearest,
      )
    }
    p2_assert_finite("limit", y)
    seq.push(y)
    if seq.length() >= 3 {
      let n = seq.length()
      let (acc, ok) = p2_aitken(seq[n - 3], seq[n - 2], seq[n - 1], prec)
      if ok {
        let err = @mpf.mpf_abs(
          @mpf.mpf_sub(acc, seq[n - 1], prec, @mpf.round_nearest),
          prec,
          @mpf.round_nearest,
        )
        if @mpf.mpf_le(err, tol) {
          return @mpf.mpf_pos(acc, self.precision(), self.round_mode())
        }
      } else {
        let err = @mpf.mpf_abs(
          @mpf.mpf_sub(seq[n - 1], seq[n - 2], prec, @mpf.round_nearest),
          prec,
          @mpf.round_nearest,
        )
        if @mpf.mpf_le(err, tol) {
          return @mpf.mpf_pos(seq[n - 1], self.precision(), self.round_mode())
        }
      }
    }
    h = @mpf.mpf_mul(
      h,
      @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
      prec,
      @mpf.round_nearest,
    )
  }
  if seq.length() > 0 {
    return @mpf.mpf_pos(
      seq[seq.length() - 1],
      self.precision(),
      self.round_mode(),
    )
  }
  raise MPError::ConvergenceError("limit: sequence did not converge")
}

///|
/// Numerical limit for real-valued unary functions.
///
/// Supports finite points and `x = +/-inf`.
pub fn MPContext::limit(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  direction? : Int = 0,
  max_steps? : Int = 32,
) -> @mpf.RawMpf raise MPError {
  let p = self.p2_work_prec()
  if !@mpf.is_inf(x) {
    return self.p2_limit_at_finite(f, x, direction, max_steps, p)
  }
  let dir = if x.sign == 0 { 1 } else { -1 }
  let g = (u : @mpf.RawMpf) => {
    let inv = @mpf.mpf_div(@mpf.fone, u, p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    let arg = if dir > 0 {
      inv
    } else {
      @mpf.mpf_neg(inv, p, @mpf.round_nearest)
    }
    f(arg)
  }
  self.p2_limit_at_finite(g, @mpf.fzero, 1, max_steps, p)
}

///|
/// Polynomial least-error fit on `[a,b]` using Chebyshev nodes.
///
/// Returns `(coeffs, estimated_max_error)` with coefficient order controlled by
/// `asc`.
pub fn MPContext::chebyfit(
  self : MPContext,
  f : UnaryMpfFn,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  n : Int,
  asc? : Bool = true,
) -> (Array[@mpf.RawMpf], @mpf.RawMpf) raise MPError {
  if n < 1 {
    raise MPError::ValueError("chebyfit: n must be positive")
  }
  let p = self.p2_work_prec() + 32
  let (a, b) = interval
  let mid = @mpf.mpf_mul(
    @mpf.mpf_add(a, b, p, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    p,
    @mpf.round_nearest,
  )
  let half = @mpf.mpf_mul(
    @mpf.mpf_sub(b, a, p, @mpf.round_nearest),
    @mpf.from_man_exp(1N, -1, 0, @mpf.round_down),
    p,
    @mpf.round_nearest,
  )
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let xs : Array[@mpf.RawMpf] = []
  let ys : Array[@mpf.RawMpf] = []
  for k in 0..<n {
    let theta = @mpf.mpf_div(
      @mpf.mpf_mul(pi, @mpf.from_int(2 * k + 1), p, @mpf.round_nearest),
      @mpf.from_int(2 * n),
      p,
      @mpf.round_nearest,
    ) catch {
      err => raise from_mpf_error(err)
    }
    let t = @libelefun.mpf_cos(theta, p, @mpf.round_nearest)
    let xk = @mpf.mpf_add(
      mid,
      @mpf.mpf_mul(half, t, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    xs.push(xk)
    ys.push(f(xk))
  }
  let v = self.matrix(n, n)
  for i in 0..<n {
    let mut pow = @mpf.fone
    for j in 0..<n {
      v.set(i, j, pow)
      pow = @mpf.mpf_mul(pow, xs[i], p, @mpf.round_nearest)
    }
  }
  let coeffs_asc = self.lu_solve(v, ys)
  let mut err = @mpf.fzero
  let m = 8 * n + 1
  for i in 0..<m {
    let xi = @mpf.mpf_add(
      a,
      @mpf.mpf_div(
        @mpf.mpf_mul(
          @mpf.mpf_sub(b, a, p, @mpf.round_nearest),
          @mpf.from_int(i),
          p,
          @mpf.round_nearest,
        ),
        @mpf.from_int(m - 1),
        p,
        @mpf.round_nearest,
      ) catch {
        err2 => raise from_mpf_error(err2)
      },
      p,
      @mpf.round_nearest,
    )
    let py = p2_poly_eval_horner_asc(coeffs_asc, xi, p)
    let fy = f(xi)
    let d = @mpf.mpf_abs(
      @mpf.mpf_sub(py, fy, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    if @mpf.mpf_gt(d, err) {
      err = d
    }
  }
  let coeffs = if asc { coeffs_asc } else { p2_reverse_mpf(coeffs_asc) }
  (coeffs, @mpf.mpf_pos(err, self.precision(), self.round_mode()))
}

///|
fn p2_poly_eval_mpc_asc(
  coeffs : ArrayView[@mpf.RawMpf],
  z : @mpc.RawMpc,
  prec : Int,
) -> @mpc.RawMpc {
  if coeffs.length() == 0 {
    return @mpc.zero()
  }
  let mut y = @mpc.from_parts(coeffs[coeffs.length() - 1], @mpf.fzero)
  let mut i = coeffs.length() - 1
  while i > 0 {
    i -= 1
    y = @mpc.mpc_add_mpf(
      @mpc.mpc_mul(y, z, prec, @mpf.round_nearest),
      coeffs[i],
      prec,
      @mpf.round_nearest,
    )
  }
  y
}

///|
fn p2_polyroot_sort(roots : Array[@mpc.RawMpc], prec : Int) -> Unit {
  let n = roots.length()
  if n < 2 {
    return
  }
  for i in 0..<n {
    for j in 0..<(n - 1 - i) {
      let r0 = roots[j]
      let r1 = roots[j + 1]
      let swap = if @mpf.mpf_lt(r1.real, r0.real) {
        true
      } else if @mpf.mpf_eq(r0.real, r1.real) && @mpf.mpf_lt(r1.imag, r0.imag) {
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
fn p2_polyroots_tol(prec : Int) -> @mpf.RawMpf {
  let shift = if prec > 200 { -56 } else if prec > 120 { -44 } else { -34 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
fn p2_poly_legendre_like(c : ArrayView[@mpf.RawMpf]) -> Bool {
  let n = c.length() - 1
  if n < 8 || (n & 1) == 1 {
    return false
  }
  let mut i = 1
  while i < c.length() {
    if !@mpf.is_zero(c[i]) {
      return false
    }
    i += 2
  }
  true
}

///|
fn MPContext::p2_polyroots_legendre_like(
  self : MPContext,
  c : ArrayView[@mpf.RawMpf],
  p : Int,
) -> Array[@mpc.RawMpc] raise MPError {
  ignore(self)
  let n = c.length() - 1
  let d : Array[@mpf.RawMpf] = []
  for i in 1..<=n {
    d.push(@mpf.mpf_mul_int(c[i], i, p, @mpf.round_nearest))
  }
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let tol = p2_polyroots_tol(p)
  let roots : Array[@mpf.RawMpf] = []
  for k in 1..<=n {
    let theta = @mpf.mpf_div(
      @mpf.mpf_mul_int(pi, 4 * k - 1, p, @mpf.round_nearest),
      @mpf.from_int(4 * n + 2),
      p,
      @mpf.round_nearest,
    ) catch {
      err => raise from_mpf_error(err)
    }
    let mut x = @libelefun.mpf_cos(theta, p, @mpf.round_nearest)
    for _ in 0..<48 {
      let px = p2_poly_eval_horner_asc(c, x, p)
      let dpx = p2_poly_eval_horner_asc(d, x, p)
      if @mpf.is_zero(dpx) {
        break
      }
      let dx = @mpf.mpf_div(px, dpx, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      }
      x = @mpf.mpf_sub(x, dx, p, @mpf.round_nearest)
      if @mpf.mpf_le(@mpf.mpf_abs(dx, p, @mpf.round_nearest), tol) {
        break
      }
    }
    if @mpf.mpf_lt(x, @mpf.fnone) {
      x = @mpf.mpf_add(
        @mpf.fnone,
        @mpf.from_man_exp(1N, -20, 0, @mpf.round_down),
        p,
        @mpf.round_nearest,
      )
    } else if @mpf.mpf_gt(x, @mpf.fone) {
      x = @mpf.mpf_sub(
        @mpf.fone,
        @mpf.from_man_exp(1N, -20, 0, @mpf.round_down),
        p,
        @mpf.round_nearest,
      )
    }
    roots.push(x)
  }
  let m = roots.length()
  for i in 0..<m {
    for j in 0..<(m - 1 - i) {
      if @mpf.mpf_gt(roots[j], roots[j + 1]) {
        let t = roots[j]
        roots[j] = roots[j + 1]
        roots[j + 1] = t
      }
    }
  }
  let out : Array[@mpc.RawMpc] = []
  for r in roots {
    out.push(@mpc.from_parts(r, @mpf.fzero))
  }
  out
}

///|
fn MPContext::p2_polyroots_companion_real(
  self : MPContext,
  c : ArrayView[@mpf.RawMpf],
  lead : @mpf.RawMpf,
  p : Int,
) -> Array[@mpc.RawMpc] raise MPError {
  let n = c.length() - 1
  let comp = self.matrix(n, n)
  for j in 0..<n {
    let bj = @mpf.mpf_div(c[n - 1 - j], lead, p, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    comp.set(0, j, @mpf.mpf_neg(bj, p, @mpf.round_nearest))
  }
  for i in 1..<n {
    comp.set(i, i - 1, @mpf.fone)
  }
  let (vals, _) = self.eig(comp, max_steps=1600)
  let rs : Array[@mpf.RawMpf] = []
  for v in vals {
    rs.push(v)
  }
  let m = rs.length()
  for i in 0..<m {
    for j in 0..<(m - 1 - i) {
      if @mpf.mpf_gt(rs[j], rs[j + 1]) {
        let t = rs[j]
        rs[j] = rs[j + 1]
        rs[j + 1] = t
      }
    }
  }
  let out : Array[@mpc.RawMpc] = []
  for r in rs {
    out.push(@mpc.from_parts(r, @mpf.fzero))
  }
  out
}

///|
fn MPContext::p2_polyroots_core(
  self : MPContext,
  coeffs : ArrayView[@mpf.RawMpf],
  asc : Bool,
  max_steps : Int,
  cleanup : Bool,
  extraprec : Int,
  roots_init : ArrayView[@mpf.RawMpf],
  use_init : Bool,
) -> (Array[@mpc.RawMpc], @mpf.RawMpf) raise MPError {
  let c0 = p2_to_asc_coeffs(coeffs, asc)
  let c = p2_trim_poly_asc(c0)
  if c.length() == 0 {
    raise MPError::ValueError("polyroots: empty coefficient list")
  }
  if c.length() == 1 {
    if @mpf.is_zero(c[0]) {
      raise MPError::ValueError("polyroots: zero polynomial")
    }
    return ([], @mpf.fzero)
  }
  let n = c.length() - 1
  let p0 = self.p2_work_prec() + extraprec
  let p = if p0 > 512 { 512 } else { p0 }
  let lead = c[n]
  if @mpf.is_zero(lead) {
    raise MPError::ValueError("polyroots: leading coefficient must be non-zero")
  }
  if n == 1 {
    let r = @mpf.mpf_div(
      @mpf.mpf_neg(c[0], p, @mpf.round_nearest),
      c[1],
      p,
      @mpf.round_nearest,
    ) catch {
      err => raise from_mpf_error(err)
    }
    return (
      [
        @mpc.from_parts(
          @mpf.mpf_pos(r, self.precision(), self.round_mode()),
          @mpf.fzero,
        ),
      ],
      @mpf.fzero,
    )
  }
  if n == 2 {
    let a0 = c[0]
    let a1 = c[1]
    let a2 = c[2]
    let two = @mpf.from_int(2)
    let four = @mpf.from_int(4)
    let disc = @mpf.mpf_sub(
      @mpf.mpf_mul(a1, a1, p, @mpf.round_nearest),
      @mpf.mpf_mul(
        @mpf.mpf_mul(four, a2, p, @mpf.round_nearest),
        a0,
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
    let den = @mpf.mpf_mul(two, a2, p, @mpf.round_nearest)
    let roots2 : Array[@mpc.RawMpc] = []
    if @mpf.mpf_ge(disc, @mpf.fzero) {
      let s = @mpf.mpf_sqrt(disc, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      }
      let r0 = @mpf.mpf_div(
        @mpf.mpf_sub(
          @mpf.mpf_neg(a1, p, @mpf.round_nearest),
          s,
          p,
          @mpf.round_nearest,
        ),
        den,
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      let r1 = @mpf.mpf_div(
        @mpf.mpf_add(
          @mpf.mpf_neg(a1, p, @mpf.round_nearest),
          s,
          p,
          @mpf.round_nearest,
        ),
        den,
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      roots2.push(@mpc.from_parts(r0, @mpf.fzero))
      roots2.push(@mpc.from_parts(r1, @mpf.fzero))
    } else {
      let s = @mpf.mpf_sqrt(
        @mpf.mpf_neg(disc, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      let re = @mpf.mpf_div(
        @mpf.mpf_neg(a1, p, @mpf.round_nearest),
        den,
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      let im = @mpf.mpf_div(s, den, p, @mpf.round_nearest) catch {
        err => raise from_mpf_error(err)
      }
      roots2.push(@mpc.from_parts(re, @mpf.mpf_neg(im, p, @mpf.round_nearest)))
      roots2.push(@mpc.from_parts(re, im))
    }
    let out2 : Array[@mpc.RawMpc] = []
    for r in roots2 {
      out2.push(@mpc.mpc_pos(r, self.precision(), self.round_mode()))
    }
    return (out2, @mpf.fzero)
  }

  let roots : Array[@mpc.RawMpc] = []
  if use_init && roots_init.length() > 0 {
    let m = if roots_init.length() < n { roots_init.length() } else { n }
    for i in 0..<m {
      roots.push(@mpc.from_parts(roots_init[i], @mpf.fzero))
    }
  }
  if roots.length() < n {
    let mut radius = @mpf.fone
    for i in 0..<n {
      let qi = @mpf.mpf_div(
        @mpf.mpf_abs(c[i], p, @mpf.round_nearest),
        @mpf.mpf_abs(lead, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      if @mpf.mpf_gt(qi, radius) {
        radius = qi
      }
    }
    radius = @mpf.mpf_add(radius, @mpf.fone, p, @mpf.round_nearest)
    let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
    for i in roots.length()..<n {
      let theta = @mpf.mpf_div(
        @mpf.mpf_mul_int(pi, 2 * i, p, @mpf.round_nearest),
        @mpf.from_int(n),
        p,
        @mpf.round_nearest,
      ) catch {
        err => raise from_mpf_error(err)
      }
      let re = @mpf.mpf_mul(
        radius,
        @libelefun.mpf_cos(theta, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      let im = @mpf.mpf_mul(
        radius,
        @libelefun.mpf_sin(theta, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
      roots.push(@mpc.from_parts(re, im))
    }
  }

  let tol = p2_polyroots_tol(p)
  let sep_tol = @mpf.from_man_exp(1N, -20, 0, @mpf.round_down)
  let mut max_update = @mpf.finf
  for _ in 0..<max_steps {
    max_update = @mpf.fzero
    for i in 0..<n {
      let zi = roots[i]
      let pz = p2_poly_eval_mpc_asc(c, zi, p)
      let mut den = @mpc.one()
      for j in 0..<n {
        if i == j {
          continue
        }
        den = @mpc.mpc_mul(
          den,
          @mpc.mpc_sub(zi, roots[j], p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
      let den_abs = @mpc.mpc_abs(den, p, @mpf.round_nearest)
      if @mpf.mpf_le(den_abs, sep_tol) {
        continue
      }
      let delta = @mpc.mpc_div(pz, den, p, @mpf.round_nearest)
      roots[i] = @mpc.mpc_sub(zi, delta, p, @mpf.round_nearest)
      let du = @mpc.mpc_abs(delta, p, @mpf.round_nearest)
      if @mpf.mpf_gt(du, max_update) {
        max_update = du
      }
    }
    if @mpf.mpf_le(max_update, tol) {
      break
    }
  }
  if @mpf.mpf_gt(max_update, tol) {
    if max_steps >= 10 {
      let fallback = if p2_poly_legendre_like(c) {
        self.p2_polyroots_legendre_like(c, p)
      } else {
        self.p2_polyroots_companion_real(c, lead, p)
      }
      let mut err_fb = @mpf.fzero
      for r in fallback {
        let rz = p2_poly_eval_mpc_asc(c, r, p)
        let re = @mpc.mpc_abs(rz, p, @mpf.round_nearest)
        if @mpf.mpf_gt(re, err_fb) {
          err_fb = re
        }
      }
      let out_fb : Array[@mpc.RawMpc] = []
      for r in fallback {
        out_fb.push(@mpc.mpc_pos(r, self.precision(), self.round_mode()))
      }
      return (out_fb, @mpf.mpf_pos(err_fb, self.precision(), self.round_mode()))
    }
    raise MPError::ConvergenceError("polyroots: Durand-Kerner did not converge")
  }

  let clean_tol = @mpf.from_man_exp(1N, -24, 0, @mpf.round_down)
  if cleanup {
    for i in 0..<n {
      if @mpf.mpf_le(
          @mpf.mpf_abs(roots[i].imag, p, @mpf.round_nearest),
          clean_tol,
        ) {
        roots[i] = @mpc.from_parts(roots[i].real, @mpf.fzero)
      }
    }
  }
  p2_polyroot_sort(roots, p)

  let mut err = @mpf.fzero
  for r in roots {
    let rz = p2_poly_eval_mpc_asc(c, r, p)
    let re = @mpc.mpc_abs(rz, p, @mpf.round_nearest)
    if @mpf.mpf_gt(re, err) {
      err = re
    }
  }

  let out : Array[@mpc.RawMpc] = []
  for r in roots {
    out.push(@mpc.mpc_pos(r, self.precision(), self.round_mode()))
  }
  (out, @mpf.mpf_pos(err, self.precision(), self.round_mode()))
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
  let (r, _) = self.p2_polyroots_core(
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
  self.p2_polyroots_core(
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
  self.p2_polyroots_core(coeffs, asc, max_steps, cleanup, extraprec, [], false)
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
    raise MPError::ValueError("pade: m and n must be non-negative")
  }
  if a.length() < m + n + 1 {
    raise MPError::ValueError("pade: insufficient series coefficients")
  }
  let p = self.p2_work_prec() + 16
  let q : Array[@mpf.RawMpf] = []
  q.push(@mpf.fone)
  if n > 0 {
    let mat = self.matrix(n, n)
    let rhs : Array[@mpf.RawMpf] = []
    for row in 0..<n {
      let k = m + 1 + row
      for col in 0..<n {
        mat.set(row, col, a[k - 1 - col])
      }
      rhs.push(@mpf.mpf_neg(a[k], p, @mpf.round_nearest))
    }
    let tail = self.lu_solve(mat, rhs)
    for t in tail {
      q.push(t)
    }
  }
  let pcoef : Array[@mpf.RawMpf] = []
  for i in 0..<=m {
    let mut s = @mpf.fzero
    let jmax = if i < n { i } else { n }
    for j in 0..<=jmax {
      s = @mpf.mpf_add(
        s,
        @mpf.mpf_mul(q[j], a[i - j], p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    pcoef.push(@mpf.mpf_pos(s, self.precision(), self.round_mode()))
  }
  let qout : Array[@mpf.RawMpf] = []
  for x in q {
    qout.push(@mpf.mpf_pos(x, self.precision(), self.round_mode()))
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
  f : UnaryMpfFn,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  n : Int,
) -> (Array[@mpf.RawMpf], Array[@mpf.RawMpf]) raise MPError {
  if n < 0 {
    raise MPError::ValueError("fourier: n must be non-negative")
  }
  let p = self.p2_work_prec()
  let (a, b) = interval
  let l = @mpf.mpf_sub(b, a, p, @mpf.round_nearest)
  if @mpf.is_zero(l) {
    raise MPError::ValueError("fourier: interval length must be non-zero")
  }
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let w = @mpf.mpf_div(
    @mpf.mpf_mul_int(pi, 2, p, @mpf.round_nearest),
    l,
    p,
    @mpf.round_nearest,
  ) catch {
    err => raise from_mpf_error(err)
  }
  let c : Array[@mpf.RawMpf] = []
  let s : Array[@mpf.RawMpf] = []
  let mean = self.quadts(f, a, b, max_steps=14)
  c.push(
    @mpf.mpf_div(mean, l, self.precision(), self.round_mode()) catch {
      err => raise from_mpf_error(err)
    },
  )
  s.push(@mpf.fzero)
  for k in 1..<=n {
    let kk = @mpf.from_int(k)
    let cosk = (x : @mpf.RawMpf) => {
      let arg = @mpf.mpf_mul(
        @mpf.mpf_mul(w, kk, p, @mpf.round_nearest),
        x,
        p,
        @mpf.round_nearest,
      )
      @mpf.mpf_mul(
        f(x),
        @libelefun.mpf_cos(arg, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let sink = (x : @mpf.RawMpf) => {
      let arg = @mpf.mpf_mul(
        @mpf.mpf_mul(w, kk, p, @mpf.round_nearest),
        x,
        p,
        @mpf.round_nearest,
      )
      @mpf.mpf_mul(
        f(x),
        @libelefun.mpf_sin(arg, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    let ic = self.quadts(cosk, a, b, max_steps=14)
    let is0 = self.quadts(sink, a, b, max_steps=14)
    let scale = @mpf.mpf_div(@mpf.from_int(2), l, p, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    c.push(@mpf.mpf_mul(ic, scale, self.precision(), self.round_mode()))
    s.push(@mpf.mpf_mul(is0, scale, self.precision(), self.round_mode()))
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
  let p = self.p2_work_prec()
  let (c, s) = coeffs
  if c.length() == 0 {
    return @mpf.fzero
  }
  let (a, b) = interval
  let l = @mpf.mpf_sub(b, a, p, @mpf.round_nearest)
  if @mpf.is_zero(l) {
    raise MPError::ValueError("fourierval: interval length must be non-zero")
  }
  let n = if c.length() < s.length() { c.length() - 1 } else { s.length() - 1 }
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let w = @mpf.mpf_div(
    @mpf.mpf_mul_int(pi, 2, p, @mpf.round_nearest),
    l,
    p,
    @mpf.round_nearest,
  ) catch {
    err => raise from_mpf_error(err)
  }
  let mut y = c[0]
  for k in 1..<=n {
    let arg = @mpf.mpf_mul(
      @mpf.mpf_mul_int(w, k, p, @mpf.round_nearest),
      x,
      p,
      @mpf.round_nearest,
    )
    y = @mpf.mpf_add(
      y,
      @mpf.mpf_add(
        @mpf.mpf_mul(
          c[k],
          @libelefun.mpf_cos(arg, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        @mpf.mpf_mul(
          s[k],
          @libelefun.mpf_sin(arg, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        ),
        p,
        @mpf.round_nearest,
      ),
      p,
      @mpf.round_nearest,
    )
  }
  @mpf.mpf_pos(y, self.precision(), self.round_mode())
}

///|
/// Fractional differintegral subset.
///
/// Currently supports `a <= 0` (fractional integrals) for finite positive `x`.
pub fn MPContext::differint(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  a : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  let p = self.p2_work_prec() + 24
  if @mpf.is_nan(a) || @mpf.is_nan(x) {
    raise MPError::ValueError("differint: nan input")
  }
  if @mpf.is_zero(a) {
    return f(x)
  }
  if @mpf.mpf_gt(a, @mpf.fzero) {
    raise MPError::ValueError("differint: positive order not implemented")
  }
  if !@mpf.is_finite(x) || @mpf.mpf_lt(x, @mpf.fzero) {
    raise MPError::DomainError("differint: require finite non-negative x")
  }
  let beta = @mpf.mpf_neg(a, p, @mpf.round_nearest)
  let gamma_beta = @gammazeta.mpf_gamma(beta, p, @mpf.round_nearest) catch {
    err => raise from_gammazeta_error(err)
  }
  let g = (u : @mpf.RawMpf) => {
    if @mpf.is_zero(u) {
      return f(x)
    }
    let u2 = @mpf.mpf_mul(u, u, p, @mpf.round_nearest)
    let one_minus_u2 = @mpf.mpf_sub(@mpf.fone, u2, p, @mpf.round_nearest)
    let t = @mpf.mpf_mul(x, one_minus_u2, p, @mpf.round_nearest)
    let xm_t = @mpf.mpf_sub(x, t, p, @mpf.round_nearest)
    let kernel = @libelefun.mpf_pow(
      xm_t,
      @mpf.mpf_sub(beta, @mpf.fone, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    }
    let jac = @mpf.mpf_mul_int(
      @mpf.mpf_mul(x, u, p, @mpf.round_nearest),
      2,
      p,
      @mpf.round_nearest,
    )
    @mpf.mpf_mul(
      @mpf.mpf_mul(kernel, f(t), p, @mpf.round_nearest),
      jac,
      p,
      @mpf.round_nearest,
    )
  }
  let integ = self.quadts(g, @mpf.fzero, @mpf.fone, max_steps=10)
  @mpf.mpf_div(integ, gamma_beta, self.precision(), self.round_mode()) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn p2_stehfest_coeff(n : Int, k : Int, prec : Int) -> @mpf.RawMpf raise MPError {
  let nh = n / 2
  let jmin = (k + 1) / 2
  let jmax = if k < nh { k } else { nh }
  let mut vk = @mpf.fzero
  for j in jmin..<=jmax {
    let jp = @mpf.from_int(j)
    let mut term = @libelefun.mpf_pow(
      jp,
      @mpf.from_int(nh),
      prec,
      @mpf.round_nearest,
    ) catch {
      _ =>
        raise MPError::ValueError("invertlaplace: invalid Stehfest coefficient")
    }
    let f2j = @gammazeta.mpf_factorial(2 * j, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    term = @mpf.mpf_mul(term, f2j, prec, @mpf.round_nearest)
    let d0 = @gammazeta.mpf_factorial(nh - j, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d1 = @gammazeta.mpf_factorial(j, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d2 = @gammazeta.mpf_factorial(j - 1, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d3 = @gammazeta.mpf_factorial(k - j, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let d4 = @gammazeta.mpf_factorial(2 * j - k, prec, @mpf.round_nearest) catch {
      err => raise from_gammazeta_error(err)
    }
    let den = @mpf.mpf_mul(
      @mpf.mpf_mul(d0, d1, prec, @mpf.round_nearest),
      @mpf.mpf_mul(
        d2,
        @mpf.mpf_mul(d3, d4, prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      ),
      prec,
      @mpf.round_nearest,
    )
    term = @mpf.mpf_div(term, den, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    vk = @mpf.mpf_add(vk, term, prec, @mpf.round_nearest)
  }
  if ((k + nh) & 1) == 1 {
    @mpf.mpf_neg(vk, prec, @mpf.round_nearest)
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
  fp : UnaryMpfFn,
  t : @mpf.RawMpf,
  algo? : String = "talbot",
) -> @mpf.RawMpf raise MPError {
  if !@mpf.is_finite(t) || @mpf.mpf_le(t, @mpf.fzero) {
    raise MPError::DomainError("invertlaplace: require finite positive t")
  }
  let key = algo.to_lower()
  match key {
    "talbot" => ()
    "stehfest" => ()
    "dehoog" => ()
    "cohen" => ()
    _ => raise MPError::ValueError("invertlaplace: unknown method '\{algo}'")
  }
  let p = self.p2_work_prec() + 32
  let n = 14
  let ln2 = @libelefun.mpf_ln2(p, @mpf.round_nearest)
  let scale = @mpf.mpf_div(ln2, t, p, @mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
  let mut s = @mpf.fzero
  for k in 1..<=n {
    let vk = p2_stehfest_coeff(n, k, p)
    let arg = @mpf.mpf_mul_int(scale, k, p, @mpf.round_nearest)
    s = @mpf.mpf_add(
      s,
      @mpf.mpf_mul(vk, fp(arg), p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  @mpf.mpf_mul(scale, s, self.precision(), self.round_mode())
}

///|
fn p2_matrix_is_square(a : MpfMatrix, name : String) -> Unit raise MPError {
  if a.rows != a.cols {
    raise MPError::ValueError("\{name}: matrix must be square")
  }
}

///|
fn MPContext::p2_matrix_series_tol(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -64 } else if prec > 120 { -52 } else { -40 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
/// Matrix exponential via power series.
pub fn MPContext::expm(
  self : MPContext,
  a : MpfMatrix,
  max_terms? : Int = 180,
) -> MpfMatrix raise MPError {
  p2_matrix_is_square(a, "expm")
  let p = self.p2_work_prec() + 24
  let tol = self.p2_matrix_series_tol(p)
  let mut sum = self.eye(a.rows)
  let mut term = self.eye(a.rows)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a)
    term = self.matrix_div_scalar(term, @mpf.from_int(k))
    sum = self.matrix_add(sum, term)
    if @mpf.mpf_le(self.matrix_norm_inf(term), tol) {
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
  p2_matrix_is_square(a, "cosm")
  let p = self.p2_work_prec() + 24
  let tol = self.p2_matrix_series_tol(p)
  let a2 = self.matrix_mul(a, a)
  let mut sum = self.eye(a.rows)
  let mut term = self.eye(a.rows)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a2)
    term = self.matrix_div_scalar(term, @mpf.from_int((2 * k - 1) * (2 * k)))
    term = self.matrix_scale(term, @mpf.fnone)
    sum = self.matrix_add(sum, term)
    if @mpf.mpf_le(self.matrix_norm_inf(term), tol) {
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
  p2_matrix_is_square(a, "sinm")
  let p = self.p2_work_prec() + 24
  let tol = self.p2_matrix_series_tol(p)
  let a2 = self.matrix_mul(a, a)
  let mut sum = self.matrix_copy(a)
  let mut term = self.matrix_copy(a)
  for k in 1..<=max_terms {
    term = self.matrix_mul(term, a2)
    term = self.matrix_div_scalar(term, @mpf.from_int(2 * k * (2 * k + 1)))
    term = self.matrix_scale(term, @mpf.fnone)
    sum = self.matrix_add(sum, term)
    if @mpf.mpf_le(self.matrix_norm_inf(term), tol) {
      break
    }
  }
  sum
}
