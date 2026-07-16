///|
fn MPContext::working_precision(self : MPContext) -> Int {
  if self.precision() > 0 {
    self.precision() + 32
  } else {
    96
  }
}

///|
fn MPContext::default_numerical_tolerance(self : MPContext) -> @mpf.RawMpf {
  let p = if self.precision() > 0 { self.precision() } else { 80 }
  @mpf.RawMpf::from_mantissa_exponent(1N, -(p - 8), 0, Down)
}

///|
fn checked_mpf_div(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  x.div(y, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn checked_mpf_div_int(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  checked_mpf_div(x, @mpf.RawMpf::from_int(n), prec, rnd)
}

///|
fn checked_mpf_pow_int(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  x.pow_int(n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn within_tolerance(x : @mpf.RawMpf, tol : @mpf.RawMpf, prec : Int) -> Bool {
  x.abs(prec, Nearest) <= tol
}

///|
fn require_finite_value(
  name : StringView,
  x : @mpf.RawMpf,
) -> Unit raise MPError {
  if !x.is_finite() {
    raise DomainError("\{name}: non-finite value")
  }
}

///|
fn max_absolute_pair(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf {
  let ax = x.abs(prec, Nearest)
  let ay = y.abs(prec, Nearest)
  if ax > ay {
    ax
  } else {
    ay
  }
}

///|
fn binomial_coefficient(n : Int, k : Int) -> Int {
  if k < 0 || k > n {
    return 0
  }
  if k == 0 || k == n {
    return 1
  }
  let mut kk = k
  if kk > n - kk {
    kk = n - kk
  }
  let mut c = 1
  for i in 1..<=kk {
    c = c * (n - kk + i) / i
  }
  c
}

///|
fn trailing_window(
  xs : ArrayView[@mpf.RawMpf],
  count : Int,
) -> Array[@mpf.RawMpf] {
  let n = xs.length()
  if n == 0 {
    return []
  }
  let m = if count < n { count } else { n }
  let start = n - m
  let out : Array[@mpf.RawMpf] = []
  for i in start..<n {
    out.push(xs[i])
  }
  out
}

///|
fn has_alternating_terms(terms : ArrayView[@mpf.RawMpf]) -> Bool {
  if terms.length() < 2 {
    return false
  }
  let mut seen = 0
  let mut prev_sign = 0
  for t in terms {
    let s = t.signum()
    if s == 0 {
      continue
    }
    if seen > 0 && s == prev_sign {
      return false
    }
    prev_sign = s
    seen += 1
  }
  seen >= 2
}

///|
fn MPContext::series_tolerance(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 220 { -36 } else if prec > 140 { -30 } else { -24 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
fn MPContext::terms_from_partial_sums(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> Array[@mpf.RawMpf] {
  ignore(self)
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<partials.length() {
    if i == 0 {
      out.push(partials[i])
    } else {
      out.push(partials[i].sub(partials[i - 1], prec, Nearest))
    }
  }
  out
}

///|
fn MPContext::richardson_series_limit(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  terms : ArrayView[@mpf.RawMpf],
  start : Int,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  ignore(self)
  if partials.length() == 0 {
    raise ValueError("series: empty sequence")
  }
  let s = partials[partials.length() - 1]
  if terms.length() < 2 {
    return (s, @mpf.RawMpf::infinity())
  }
  let t0 = terms[terms.length() - 2]
  let t1 = terms[terms.length() - 1]
  let at0 = t0.abs(prec, Nearest)
  let at1 = t1.abs(prec, Nearest)
  if at1.is_zero() {
    return (s, @mpf.RawMpf::zero())
  }
  if at0.is_zero() {
    return (s, at1)
  }
  let ratio = checked_mpf_div(at1, at0, prec, Nearest)
  let mut tail = @mpf.RawMpf::zero()
  let ratio_cut = checked_mpf_div_int(
    @mpf.RawMpf::from_int(3),
    5,
    prec,
    Nearest,
  )
  if ratio < ratio_cut {
    let one_minus_ratio = @mpf.RawMpf::one().sub(ratio, prec, Nearest)
    if !one_minus_ratio.is_zero() && one_minus_ratio > @mpf.RawMpf::zero() {
      tail = checked_mpf_div(
        t1.mul(ratio, prec, Nearest),
        one_minus_ratio,
        prec,
        Nearest,
      )
    } else {
      tail = t1
    }
  } else {
    let k = start + partials.length() - 1
    if k <= 1 {
      tail = t1
    } else {
      let q = checked_mpf_div(
        @mpf.RawMpf::from_int(k),
        @mpf.RawMpf::from_int(k - 1),
        prec,
        Nearest,
      )
      let inv_ratio = checked_mpf_div(at0, at1, prec, Nearest)
      let ln_q = @libelefun.ln(q, prec, Nearest) catch {
        err => raise from_libelefun_error(err)
      }
      let ln_r = @libelefun.ln(inv_ratio, prec, Nearest) catch {
        err => raise from_libelefun_error(err)
      }
      if ln_q.is_zero() {
        tail = t1
      } else {
        let p_est = checked_mpf_div(ln_r, ln_q, prec, Nearest)
        let denom = p_est.sub(@mpf.RawMpf::one(), prec, Nearest)
        if denom.is_zero() || denom <= @mpf.RawMpf::zero() {
          tail = t1
        } else {
          tail = t1.mul(
            checked_mpf_div(@mpf.RawMpf::from_int(k), denom, prec, Nearest),
            prec,
            Nearest,
          )
        }
      }
    }
  }
  let est = s.add(tail, prec, Nearest)
  (est, tail.abs(prec, Nearest))
}

///|
fn MPContext::wynn_epsilon_limit(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  ignore(self)
  let n = partials.length()
  if n < 3 {
    raise ValueError("levin: need at least 3 partial sums")
  }
  let mut prev2 : Array[@mpf.RawMpf] = []
  for _ in 0..<=n {
    prev2.push(@mpf.RawMpf::zero())
  }
  let mut prev1 : Array[@mpf.RawMpf] = []
  for s in partials {
    prev1.push(s)
  }
  let mut best = partials[n - 1]
  let mut prev_even = best
  let mut err = @mpf.RawMpf::infinity()
  let mut have_even = false
  for k in 0..<(n - 1) {
    let len = prev1.length()
    if len < 2 {
      break
    }
    let cur : Array[@mpf.RawMpf] = []
    for i in 0..<(len - 1) {
      let diff = prev1[i + 1].sub(prev1[i], prec, Nearest)
      if diff.is_zero() || !diff.is_finite() {
        cur.push(@mpf.RawMpf::nan())
      } else {
        let inv = checked_mpf_div(@mpf.RawMpf::one(), diff, prec, Nearest)
        cur.push(prev2[i + 1].add(inv, prec, Nearest))
      }
    }
    let order = k + 1
    if (order & 1) == 0 && cur.length() > 0 {
      let cand = cur[0]
      if cand.is_finite() {
        err = cand.sub(prev_even, prec, Nearest).abs(prec, Nearest)
        best = cand
        prev_even = cand
        have_even = true
      }
    }
    prev2 = prev1
    prev1 = cur
  }
  if !have_even {
    err = best.sub(partials[n - 1], prec, Nearest).abs(prec, Nearest)
  }
  (best, err)
}

///|
fn MPContext::estimate_series_limit(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  terms : ArrayView[@mpf.RawMpf],
  start : Int,
  algo : StringView,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  let key = algo.to_lower()
  match key {
    "r" => self.richardson_series_limit(partials, terms, start, prec)
    "richardson" => self.richardson_series_limit(partials, terms, start, prec)
    "levin" => self.wynn_epsilon_limit(partials, prec)
    "l" => self.wynn_epsilon_limit(partials, prec)
    "shanks" => self.wynn_epsilon_limit(partials, prec)
    "e" => self.wynn_epsilon_limit(partials, prec)
    "euler" => self.wynn_epsilon_limit(partials, prec)
    "sidi" => self.wynn_epsilon_limit(partials, prec)
    "u" => self.wynn_epsilon_limit(partials, prec)
    "v" => self.wynn_epsilon_limit(partials, prec)
    "t" => self.wynn_epsilon_limit(partials, prec)
    "auto" =>
      if has_alternating_terms(terms) {
        self.wynn_epsilon_limit(partials, prec)
      } else {
        self.richardson_series_limit(partials, terms, start, prec)
      }
    _ => raise ValueError("series: unknown method '\{algo}'")
  }
}

///|
fn MPContext::differentiation_step(
  self : MPContext,
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf {
  ignore(self)
  let denom = n + 3
  let shift = -(prec / denom + 2)
  let mut h = @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
  let ax = x.abs(prec, Nearest)
  if ax > @mpf.RawMpf::one() {
    h = h.mul(ax, prec, Nearest)
  }
  if h.is_zero() {
    @mpf.RawMpf::from_mantissa_exponent(1N, -8, 0, Down)
  } else {
    h
  }
}

///|
fn MPContext::first_derivative(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  direction : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let h = self.differentiation_step(x, 1, prec)
  if direction > 0 {
    let y0 = f(x)
    let y1 = f(x.add(h, prec, Nearest))
    require_finite_value("diff", y0)
    require_finite_value("diff", y1)
    return checked_mpf_div(
      y1.sub(y0, prec, Nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  if direction < 0 {
    let y0 = f(x)
    let y1 = f(x.sub(h, prec, Nearest))
    require_finite_value("diff", y0)
    require_finite_value("diff", y1)
    return checked_mpf_div(
      y0.sub(y1, prec, Nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  let yp = f(x.add(h, prec, Nearest))
  let ym = f(x.sub(h, prec, Nearest))
  require_finite_value("diff", yp)
  require_finite_value("diff", ym)
  checked_mpf_div(
    yp.sub(ym, prec, Nearest),
    h.mul_int(2, prec, Nearest),
    prec,
    self.round_mode(),
  )
}

///|
fn MPContext::second_derivative(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise {
  let h = self.differentiation_step(x, 2, prec)
  let y0 = f(x)
  let yp = f(x.add(h, prec, Nearest))
  let ym = f(x.sub(h, prec, Nearest))
  require_finite_value("diff", y0)
  require_finite_value("diff", yp)
  require_finite_value("diff", ym)
  let num = yp
    .sub(y0.mul_int(2, prec, Nearest), prec, Nearest)
    .add(ym, prec, Nearest)
  checked_mpf_div(num, h.mul(h, prec, Nearest), prec, self.round_mode())
}

///|
fn MPContext::central_difference_at_step(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  n : Int,
  h : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise {
  let half_h = checked_mpf_div_int(h, 2, prec, Nearest)
  let mut sum = @mpf.RawMpf::zero()
  for k in 0..<=n {
    let coeff_i = binomial_coefficient(n, k)
    let coeff = if (k & 1) == 0 { coeff_i } else { -coeff_i }
    let offset = n - 2 * k
    let xk = x.add(half_h.mul_int(offset, prec, Nearest), prec, Nearest)
    let yk = f(xk)
    require_finite_value("diff", yk)
    let term = yk.mul_int(coeff, prec, Nearest)
    sum = sum.add(term, prec, Nearest)
  }
  let hpow = checked_mpf_pow_int(h, n, prec, Nearest)
  checked_mpf_div(sum, hpow, prec, self.round_mode())
}

///|
fn MPContext::central_difference_derivative(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let h = self.differentiation_step(x, n, prec)
  let d1 = self.central_difference_at_step(f, x, n, h, prec)
  let h2 = checked_mpf_div_int(h, 2, prec, Nearest)
  if h2.is_zero() {
    return d1
  }
  let d2 = self.central_difference_at_step(f, x, n, h2, prec)
  let correction = checked_mpf_div_int(
    d2.sub(d1, prec, Nearest),
    3,
    prec,
    Nearest,
  )
  d2.add(correction, prec, self.round_mode())
}

///|
/// High-precision compensated summation helper.
///
/// Mirrors mpmath `fsum` subset:
/// - `absolute=true`: sum of absolute values.
/// - `squared=true`: sum of squares (optionally after absolute).
/// Uses extra working precision to reduce cancellation error.
pub fn MPContext::fsum(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
  absolute? : Bool = false,
  squared? : Bool = false,
) -> @mpf.RawMpf {
  let p = self.working_precision()
  if !squared {
    @mpf.RawMpf::sum(xs, p, self.round_mode(), absolute~)
  } else {
    let ys : Array[@mpf.RawMpf] = []
    for x0 in xs {
      let x = if absolute { x0.abs(p, Nearest) } else { x0 }
      ys.push(x.mul(x, p, Nearest))
    }
    @mpf.RawMpf::sum(ys, p, self.round_mode())
  }
}

///|
/// Product of an array of `mpf` values with context-aware rounding.
///
/// Mirrors mpmath `fprod` behavior for real inputs.
pub fn MPContext::fprod(
  self : MPContext,
  xs : ArrayView[@mpf.RawMpf],
) -> @mpf.RawMpf {
  let p = self.working_precision()
  let mut acc = @mpf.RawMpf::one()
  for x in xs {
    acc = acc.mul(x, p, self.round_mode())
  }
  acc
}

///|
/// Sequence acceleration entrypoint used by `nsum/nprod`.
///
/// Accepts a sequence of partial sums and returns `(estimate, error)`.
/// Supported methods: `auto`, `levin`, `l`, `shanks`, `euler`, `sidi`,
/// `u/v/t` (aliases), and `richardson` / `r`.
pub fn MPContext::levin(
  self : MPContext,
  partial_sums : ArrayView[@mpf.RawMpf],
  algo? : StringView = "levin",
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  if partial_sums.length() < 3 {
    raise ValueError("levin: need at least 3 partial sums")
  }
  let p = self.working_precision()
  let terms = self.terms_from_partial_sums(partial_sums, p)
  let (est, err) = self.estimate_series_limit(partial_sums, terms, 1, algo, p)
  (
    est.rounded(self.precision(), self.round_mode()),
    err.rounded(self.precision(), self.round_mode()),
  )
}

///|
/// Finite integer-index summation `sum(f(k), k=start..stop, step)`.
pub fn MPContext::summation(
  self : MPContext,
  f : (Int) -> @mpf.RawMpf raise?,
  start : Int,
  stop : Int,
  step? : Int = 1,
) -> @mpf.RawMpf raise {
  if step == 0 {
    raise ValueError("summation: step must be non-zero")
  }
  let p = self.working_precision()
  if (step > 0 && start > stop) || (step < 0 && start < stop) {
    return @mpf.RawMpf::zero()
  }
  let mut k = start
  let mut s = @mpf.RawMpf::zero()
  while (step > 0 && k <= stop) || (step < 0 && k >= stop) {
    s = s.add(f(k), p, Nearest)
    k += step
  }
  s.rounded(self.precision(), self.round_mode())
}

///|
/// Integer-indexed numerical summation with optional convergence acceleration.
///
/// - `stop=Some(b)`: finite summation over `[start, b]`.
/// - `stop=None`: infinite tail, accelerated by `method`.
pub fn MPContext::nsum(
  self : MPContext,
  f : (Int) -> @mpf.RawMpf raise?,
  start : Int,
  stop? : Int,
  algo? : StringView = "auto",
  tol? : @mpf.RawMpf,
  max_terms? : Int = 800,
) -> @mpf.RawMpf raise {
  match stop {
    Some(b) => self.summation(f, start, b)
    None => {
      if max_terms < 1 {
        raise ValueError("nsum: max_terms must be positive")
      }
      let p = self.working_precision()
      let tol_abs = match tol {
        Some(v) => v.abs(p, Nearest)
        None => self.series_tolerance(p)
      }
      let tight = tol_abs.mul_int(8, p, Nearest)
      let loose = tol_abs.mul_int(24, p, Nearest)
      let tail_gate = @mpf.RawMpf::from_mantissa_exponent(1N, -6, 0, Down)
      let mut s = @mpf.RawMpf::zero()
      let partials : Array[@mpf.RawMpf] = []
      let terms : Array[@mpf.RawMpf] = []
      let mut last_abs_term = @mpf.RawMpf::infinity()
      let window = 18
      for i in 0..<max_terms {
        let k = start + i
        let term = f(k)
        s = s.add(term, p, Nearest)
        partials.push(s)
        terms.push(term)
        let abs_term = term.abs(p, Nearest)
        last_abs_term = abs_term
        if partials.length() >= 3 {
          let ps = trailing_window(partials, window)
          let ts = trailing_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.estimate_series_limit(
            ps, ts, start_idx, algo, p,
          )
          let delta = est.sub(s, p, Nearest).abs(p, Nearest)
          if err.is_finite() && err <= tight && delta <= loose {
            return est.rounded(self.precision(), self.round_mode())
          }
          if abs_term <= tol_abs && delta <= loose {
            return est.rounded(self.precision(), self.round_mode())
          }
        } else if term.is_zero() {
          return s.rounded(self.precision(), self.round_mode())
        }
      }
      if partials.length() >= 3 {
        let ps = trailing_window(partials, 18)
        let ts = trailing_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.estimate_series_limit(ps, ts, start_idx, algo, p)
        let delta = est.sub(s, p, Nearest).abs(p, Nearest)
        if err.is_finite() && err <= loose && delta <= loose {
          return est.rounded(self.precision(), self.round_mode())
        }
        if est.is_finite() && last_abs_term <= tail_gate {
          return est.rounded(self.precision(), self.round_mode())
        }
      }
      if s.is_finite() && last_abs_term <= tail_gate {
        return s.rounded(self.precision(), self.round_mode())
      }
      raise ConvergenceError("nsum: series did not converge")
    }
  }
}

///|
/// Integer-indexed numerical products with optional acceleration.
///
/// Infinite products are evaluated through accelerated summation of
/// logarithms and therefore require strictly positive finite terms.
pub fn MPContext::nprod(
  self : MPContext,
  f : (Int) -> @mpf.RawMpf raise?,
  start : Int,
  stop? : Int,
  algo? : StringView = "auto",
  tol? : @mpf.RawMpf,
  max_terms? : Int = 800,
) -> @mpf.RawMpf raise {
  match stop {
    Some(b) => {
      if start > b {
        return @mpf.RawMpf::one()
      }
      let p = self.working_precision()
      let mut acc = @mpf.RawMpf::one()
      for k in start..<=b {
        acc = acc.mul(f(k), p, Nearest)
      }
      acc.rounded(self.precision(), self.round_mode())
    }
    None => {
      if max_terms < 1 {
        raise ValueError("nprod: max_terms must be positive")
      }
      let p = self.working_precision()
      let tol_abs = match tol {
        Some(v) => v.abs(p, Nearest)
        None => self.series_tolerance(p)
      }
      let tight = tol_abs.mul_int(8, p, Nearest)
      let loose = tol_abs.mul_int(24, p, Nearest)
      let tail_gate = @mpf.RawMpf::from_mantissa_exponent(1N, -6, 0, Down)
      let mut slog = @mpf.RawMpf::zero()
      let partials : Array[@mpf.RawMpf] = []
      let terms : Array[@mpf.RawMpf] = []
      let mut last_abs_term = @mpf.RawMpf::infinity()
      let window = 18
      for i in 0..<max_terms {
        let k = start + i
        let tk = f(k)
        if !tk.is_finite() {
          raise DomainError("nprod: non-finite term in product")
        }
        if tk <= @mpf.RawMpf::zero() {
          raise DomainError("nprod: infinite products require positive terms")
        }
        let log_tk = @libelefun.ln(tk, p, Nearest) catch {
          err => raise from_libelefun_error(err)
        }
        slog = slog.add(log_tk, p, Nearest)
        partials.push(slog)
        terms.push(log_tk)
        let abs_term = log_tk.abs(p, Nearest)
        last_abs_term = abs_term
        if partials.length() >= 3 {
          let ps = trailing_window(partials, window)
          let ts = trailing_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.estimate_series_limit(
            ps, ts, start_idx, algo, p,
          )
          let delta = est.sub(slog, p, Nearest).abs(p, Nearest)
          if err.is_finite() && err <= tight && delta <= loose {
            return checked_mpf_exp(est, self.precision(), self.round_mode())
          }
          if abs_term <= tol_abs && delta <= loose {
            return checked_mpf_exp(est, self.precision(), self.round_mode())
          }
        } else if log_tk.is_zero() {
          return checked_mpf_exp(slog, self.precision(), self.round_mode())
        }
      }
      if partials.length() >= 3 {
        let ps = trailing_window(partials, 18)
        let ts = trailing_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.estimate_series_limit(ps, ts, start_idx, algo, p)
        let delta = est.sub(slog, p, Nearest).abs(p, Nearest)
        if err.is_finite() && err <= loose && delta <= loose {
          return checked_mpf_exp(est, self.precision(), self.round_mode())
        }
        if est.is_finite() && last_abs_term <= tail_gate {
          return checked_mpf_exp(est, self.precision(), self.round_mode())
        }
      }
      if slog.is_finite() && last_abs_term <= tail_gate {
        return checked_mpf_exp(slog, self.precision(), self.round_mode())
      }
      raise ConvergenceError("nprod: product did not converge")
    }
  }
}

///|
/// Numerical derivative `d^n f(x)` for unary real functions.
///
/// Semantics aligned with mpmath `diff` subset:
/// - `n=0` returns `f(x)`.
/// - `n=1` supports one-sided derivative with `direction`.
/// - `n>=2` uses symmetric finite-difference formulas, and for higher order
///   derivatives uses central stencil + Richardson correction.
pub fn MPContext::diff(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  n? : Int = 1,
  direction? : Int = 0,
  algo? : StringView = "step",
) -> @mpf.RawMpf raise {
  if n < 0 {
    raise ValueError("diff: n must be non-negative")
  }
  let algo_key = algo.to_lower()
  match algo_key {
    "step" => ()
    "quad" => ()
    _ => raise ValueError("diff: unknown method '\{algo}'")
  }
  if n == 0 {
    return f(x)
  }
  let p = if algo_key == "quad" {
    self.working_precision() + 12
  } else {
    self.working_precision()
  }
  if n == 1 {
    return self.first_derivative(f, x, direction, p)
  }
  if direction != 0 {
    raise ValueError("diff: direction is supported only for first derivative")
  }
  if n == 2 {
    return self.second_derivative(f, x, p)
  }
  self.central_difference_derivative(f, x, n, p)
}

///|
/// Return derivatives `[f(x), f'(x), ..., f^(n)(x)]`.
///
/// This mirrors mpmath `diffs` for unary real functions.
pub fn MPContext::diffs(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  n? : Int = 1,
  algo? : StringView = "step",
) -> Array[@mpf.RawMpf] raise {
  if n < 0 {
    raise ValueError("diffs: n must be non-negative")
  }
  let out : Array[@mpf.RawMpf] = []
  for k in 0..<=n {
    out.push(self.diff(f, x, n=k, algo~))
  }
  out
}

///|
/// Build the unary function `x -> d^n f(x)`.
///
/// Errors raised while evaluating the derivative are propagated to the caller.
pub fn MPContext::diffun(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  n? : Int = 1,
  algo? : StringView = "step",
) -> (@mpf.RawMpf) -> @mpf.RawMpf raise {
  fn(x : @mpf.RawMpf) raise { self.diff(f, x, n~, algo~) }
}

///|
/// Return Taylor coefficients `[a0, ..., an]` around `x`, where
/// `a_k = f^(k)(x) / k!`.
pub fn MPContext::taylor(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x : @mpf.RawMpf,
  n : Int,
  algo? : StringView = "step",
) -> Array[@mpf.RawMpf] raise {
  if n < 0 {
    raise ValueError("taylor: n must be non-negative")
  }
  let p = self.working_precision() + 12
  let out : Array[@mpf.RawMpf] = []
  let mut fact = @mpf.RawMpf::one()
  for k in 0..<=n {
    if k > 0 {
      fact = fact.mul_int(k, p, Nearest)
    }
    let dk = self.diff(f, x, n=k, algo~)
    let ck = if k == 0 { dk } else { checked_mpf_div(dk, fact, p, Nearest) }
    out.push(ck.rounded(self.precision(), self.round_mode()))
  }
  out
}

///|
fn MPContext::apply_partial_derivative3(
  self : MPContext,
  f : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf) -> @mpf.RawMpf raise?,
  xyz : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf),
  orders : (Int, Int, Int),
  algo : StringView,
) -> @mpf.RawMpf raise {
  let (x, y, z) = xyz
  let (nx, ny, nz) = orders
  if nx < 0 || ny < 0 || nz < 0 {
    raise ValueError("diff_partial3: derivative orders must be non-negative")
  }
  if nx == 0 && ny == 0 && nz == 0 {
    let v = f(x, y, z)
    require_finite_value("diff_partial3", v)
    return v
  }
  let algo_key = algo.to_lower()
  match algo_key {
    "step" => ()
    "quad" => ()
    _ => raise ValueError("diff_partial3: unknown method '\{algo}'")
  }
  let p = if algo_key == "quad" {
    self.working_precision() + 12
  } else {
    self.working_precision()
  }
  let total_order = nx + ny + nz
  let step_cap = if total_order >= 4 {
    140
  } else if total_order >= 3 {
    168
  } else {
    220
  }
  let step_prec = if self.precision() > step_cap {
    step_cap
  } else {
    self.precision()
  }
  let hx = if nx == 0 {
    @mpf.RawMpf::one()
  } else {
    self.differentiation_step(x, nx, step_prec)
  }
  let hy = if ny == 0 {
    @mpf.RawMpf::one()
  } else {
    self.differentiation_step(y, ny, step_prec)
  }
  let hz = if nz == 0 {
    @mpf.RawMpf::one()
  } else {
    self.differentiation_step(z, nz, step_prec)
  }
  let mut sum1 = @mpf.RawMpf::zero()
  let half_hx = if nx == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hx, 2, p, Nearest)
  }
  let half_hy = if ny == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hy, 2, p, Nearest)
  }
  let half_hz = if nz == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hz, 2, p, Nearest)
  }
  for i in 0..<=nx {
    let ci = binomial_coefficient(nx, i)
    let xi = if nx == 0 {
      x
    } else {
      x.add(half_hx.mul_int(nx - 2 * i, p, Nearest), p, Nearest)
    }
    for j in 0..<=ny {
      let cj = binomial_coefficient(ny, j)
      let yj = if ny == 0 {
        y
      } else {
        y.add(half_hy.mul_int(ny - 2 * j, p, Nearest), p, Nearest)
      }
      for k in 0..<=nz {
        let ck = binomial_coefficient(nz, k)
        let sign = if ((i + j + k) & 1) == 0 { 1 } else { -1 }
        let coeff = sign * ci * cj * ck
        let zk = if nz == 0 {
          z
        } else {
          z.add(half_hz.mul_int(nz - 2 * k, p, Nearest), p, Nearest)
        }
        let fv = f(xi, yj, zk)
        require_finite_value("diff_partial3", fv)
        sum1 = sum1.add(fv.mul_int(coeff, p, Nearest), p, Nearest)
      }
    }
  }
  let mut den1 = @mpf.RawMpf::one()
  if nx > 0 {
    den1 = den1.mul(checked_mpf_pow_int(hx, nx, p, Nearest), p, Nearest)
  }
  if ny > 0 {
    den1 = den1.mul(checked_mpf_pow_int(hy, ny, p, Nearest), p, Nearest)
  }
  if nz > 0 {
    den1 = den1.mul(checked_mpf_pow_int(hz, nz, p, Nearest), p, Nearest)
  }
  let d1 = checked_mpf_div(sum1, den1, p, self.round_mode())
  let hx2 = if nx == 0 { hx } else { checked_mpf_div_int(hx, 2, p, Nearest) }
  let hy2 = if ny == 0 { hy } else { checked_mpf_div_int(hy, 2, p, Nearest) }
  let hz2 = if nz == 0 { hz } else { checked_mpf_div_int(hz, 2, p, Nearest) }
  if nx + ny + nz <= 1 {
    return d1
  }
  let mut sum2 = @mpf.RawMpf::zero()
  let half_hx2 = if nx == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hx2, 2, p, Nearest)
  }
  let half_hy2 = if ny == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hy2, 2, p, Nearest)
  }
  let half_hz2 = if nz == 0 {
    @mpf.RawMpf::zero()
  } else {
    checked_mpf_div_int(hz2, 2, p, Nearest)
  }
  for i in 0..<=nx {
    let ci = binomial_coefficient(nx, i)
    let xi = if nx == 0 {
      x
    } else {
      x.add(half_hx2.mul_int(nx - 2 * i, p, Nearest), p, Nearest)
    }
    for j in 0..<=ny {
      let cj = binomial_coefficient(ny, j)
      let yj = if ny == 0 {
        y
      } else {
        y.add(half_hy2.mul_int(ny - 2 * j, p, Nearest), p, Nearest)
      }
      for k in 0..<=nz {
        let ck = binomial_coefficient(nz, k)
        let sign = if ((i + j + k) & 1) == 0 { 1 } else { -1 }
        let coeff = sign * ci * cj * ck
        let zk = if nz == 0 {
          z
        } else {
          z.add(half_hz2.mul_int(nz - 2 * k, p, Nearest), p, Nearest)
        }
        let fv = f(xi, yj, zk)
        require_finite_value("diff_partial3", fv)
        sum2 = sum2.add(fv.mul_int(coeff, p, Nearest), p, Nearest)
      }
    }
  }
  let mut den2 = @mpf.RawMpf::one()
  if nx > 0 {
    den2 = den2.mul(checked_mpf_pow_int(hx2, nx, p, Nearest), p, Nearest)
  }
  if ny > 0 {
    den2 = den2.mul(checked_mpf_pow_int(hy2, ny, p, Nearest), p, Nearest)
  }
  if nz > 0 {
    den2 = den2.mul(checked_mpf_pow_int(hz2, nz, p, Nearest), p, Nearest)
  }
  let d2 = checked_mpf_div(sum2, den2, p, self.round_mode())
  let correction = checked_mpf_div_int(d2.sub(d1, p, Nearest), 3, p, Nearest)
  d2.add(correction, p, self.round_mode())
}

///|
/// Mixed partial derivative for 3-variable real functions.
///
/// `orders=(nx, ny, nz)` computes
/// `d^(nx+ny+nz) f / (dx^nx dy^ny dz^nz)` at `(x, y, z)`.
pub fn MPContext::diff_partial3(
  self : MPContext,
  f : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf) -> @mpf.RawMpf raise?,
  xyz : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf),
  orders : (Int, Int, Int),
  algo? : StringView = "step",
) -> @mpf.RawMpf raise {
  let (x, y, z) = xyz
  require_finite_value("diff_partial3", x)
  require_finite_value("diff_partial3", y)
  require_finite_value("diff_partial3", z)
  let v = self.apply_partial_derivative3(f, xyz, orders, algo)
  v.rounded(self.precision(), self.round_mode())
}

///|
fn MPContext::findroot_secant(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x_prev0 : @mpf.RawMpf,
  x0 : @mpf.RawMpf,
  tol : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let mut x_prev = x_prev0
  let mut x = x0
  let mut y_prev = f(x_prev)
  let mut y = f(x)
  require_finite_value("findroot", y_prev)
  require_finite_value("findroot", y)
  if within_tolerance(y_prev, tol, prec) {
    return x_prev.rounded(self.precision(), self.round_mode())
  }
  if within_tolerance(y, tol, prec) {
    return x.rounded(self.precision(), self.round_mode())
  }
  for _ in 0..<max_steps {
    let denom = y.sub(y_prev, prec, Nearest)
    if denom.is_zero() {
      raise ConvergenceError("findroot: zero slope in secant iteration")
    }
    let step = checked_mpf_div(
      y.mul(x.sub(x_prev, prec, Nearest), prec, Nearest),
      denom,
      prec,
      Nearest,
    )
    let x_next = x.sub(step, prec, Nearest)
    if within_tolerance(x_next.sub(x, prec, Nearest), tol, prec) {
      return x_next.rounded(self.precision(), self.round_mode())
    }
    x_prev = x
    y_prev = y
    x = x_next
    y = f(x)
    require_finite_value("findroot", y)
    if within_tolerance(y, tol, prec) {
      return x.rounded(self.precision(), self.round_mode())
    }
  }
  raise ConvergenceError("findroot: secant did not converge")
}

///|
/// Scalar root finder for real functions.
///
/// - With `x1`: secant method.
/// - Without `x1`: Newton method with automatic secant fallback when slope is
///   near zero.
/// Raises `MPError::ConvergenceError` when the iteration budget is exhausted.
pub fn MPContext::findroot(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  x0 : @mpf.RawMpf,
  x1? : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 80,
  solver? : StringView = "auto",
) -> @mpf.RawMpf raise {
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.default_numerical_tolerance()
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let key = solver.to_lower()
  if key == "bisect" || key == "bisection" {
    return match x1 {
      Some(x_start) =>
        self.findroot_interval(f, x0, x_start, tol=tol_abs, max_steps=steps)
      None =>
        raise ValueError(
          "findroot: bisect solver requires x1 as bracket endpoint",
        )
    }
  }
  let use_secant = match key {
    "auto" =>
      match x1 {
        Some(_) => true
        None => false
      }
    "newton" => false
    "mnewton" => false
    "anewton" => false
    "secant" => true
    "muller" => true
    "illinois" => true
    "pegasus" => true
    "anderson" => true
    "ridder" => true
    _ => raise ValueError("findroot: unknown solver '\{solver}'")
  }
  if use_secant {
    return match x1 {
      Some(x_start) => self.findroot_secant(f, x0, x_start, tol_abs, steps, p)
      None => {
        let h = self.differentiation_step(x0, 1, p)
        self.findroot_secant(f, x0, x0.add(h, p, Nearest), tol_abs, steps, p)
      }
    }
  }
  let mut x = x0
  for _ in 0..<steps {
    let y = f(x)
    require_finite_value("findroot", y)
    if within_tolerance(y, tol_abs, p) {
      return x.rounded(self.precision(), self.round_mode())
    }
    let dy = self.first_derivative(f, x, 0, p)
    if dy.is_zero() {
      let h = self.differentiation_step(x, 1, p)
      return self.findroot_secant(f, x, x.add(h, p, Nearest), tol_abs, steps, p)
    }
    let step = checked_mpf_div(y, dy, p, Nearest)
    let x_next = x.sub(step, p, Nearest)
    if within_tolerance(x_next.sub(x, p, Nearest), tol_abs, p) {
      return x_next.rounded(self.precision(), self.round_mode())
    }
    x = x_next
  }
  raise ConvergenceError("findroot: Newton iteration did not converge")
}

///|
/// Bracketed root finder on a real interval using bisection.
///
/// Requires opposite signs at interval endpoints (or an endpoint root).
/// This corresponds to mpmath `findroot(..., solver='bisect')` subset.
pub fn MPContext::findroot_interval(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 120,
) -> @mpf.RawMpf raise {
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.default_numerical_tolerance()
  }
  if !a.is_finite() || !b.is_finite() {
    raise ValueError("findroot_interval: interval endpoints must be finite")
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut lo = a
  let mut hi = b
  if lo > hi {
    let t = lo
    lo = hi
    hi = t
  }
  let mut f_lo = f(lo)
  let mut f_hi = f(hi)
  require_finite_value("findroot_interval", f_lo)
  require_finite_value("findroot_interval", f_hi)
  if within_tolerance(f_lo, tol_abs, p) {
    return lo.rounded(self.precision(), self.round_mode())
  }
  if within_tolerance(f_hi, tol_abs, p) {
    return hi.rounded(self.precision(), self.round_mode())
  }
  let mut s_lo = f_lo.signum()
  let s_hi = f_hi.signum()
  if s_lo == s_hi {
    raise ValueError("findroot_interval: interval does not bracket a root")
  }
  for _ in 0..<steps {
    let mid = checked_mpf_div_int(lo.add(hi, p, Nearest), 2, p, Nearest)
    let f_mid = f(mid)
    require_finite_value("findroot_interval", f_mid)
    if within_tolerance(f_mid, tol_abs, p) ||
      within_tolerance(hi.sub(lo, p, Nearest), tol_abs, p) {
      return mid.rounded(self.precision(), self.round_mode())
    }
    let s_mid = f_mid.signum()
    if s_mid == s_lo {
      lo = mid
      f_lo = f_mid
      s_lo = f_lo.signum()
    } else {
      hi = mid
      f_hi = f_mid
      ignore(f_hi)
    }
  }
  raise ConvergenceError("findroot_interval: bisection did not converge")
}

///|
fn MPContext::evaluate_root_system(
  self : MPContext,
  f : (@mpf.RawMpf, @mpf.RawMpf) -> (@mpf.RawMpf, @mpf.RawMpf) raise?,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise {
  ignore(self)
  let (f1, f2) = f(x, y)
  require_finite_value("findroot2", f1)
  require_finite_value("findroot2", f2)
  (f1, f2)
}

///|
/// Two-dimensional nonlinear system solver using Newton iteration.
///
/// Solves:
/// - `f1(x,y)=0`
/// - `f2(x,y)=0`
/// with numerically estimated Jacobian from central differences.
/// This is the current mpmath-like multidimensional `findroot` subset.
pub fn MPContext::findroot2(
  self : MPContext,
  f : (@mpf.RawMpf, @mpf.RawMpf) -> (@mpf.RawMpf, @mpf.RawMpf) raise?,
  x0 : @mpf.RawMpf,
  y0 : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 80,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise {
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => v.abs(p, Nearest)
    None => self.default_numerical_tolerance()
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut x = x0
  let mut y = y0
  for _ in 0..<steps {
    let (f1, f2) = self.evaluate_root_system(f, x, y)
    if max_absolute_pair(f1, f2, p) <= tol_abs {
      return (
        x.rounded(self.precision(), self.round_mode()),
        y.rounded(self.precision(), self.round_mode()),
      )
    }
    let hx = self.differentiation_step(x, 1, p)
    let hy = self.differentiation_step(y, 1, p)
    let xp = x.add(hx, p, Nearest)
    let xm = x.sub(hx, p, Nearest)
    let yp = y.add(hy, p, Nearest)
    let ym = y.sub(hy, p, Nearest)
    let (f1_xp, f2_xp) = self.evaluate_root_system(f, xp, y)
    let (f1_xm, f2_xm) = self.evaluate_root_system(f, xm, y)
    let (f1_yp, f2_yp) = self.evaluate_root_system(f, x, yp)
    let (f1_ym, f2_ym) = self.evaluate_root_system(f, x, ym)
    let two_hx = hx.mul_int(2, p, Nearest)
    let two_hy = hy.mul_int(2, p, Nearest)
    let j11 = checked_mpf_div(f1_xp.sub(f1_xm, p, Nearest), two_hx, p, Nearest)
    let j21 = checked_mpf_div(f2_xp.sub(f2_xm, p, Nearest), two_hx, p, Nearest)
    let j12 = checked_mpf_div(f1_yp.sub(f1_ym, p, Nearest), two_hy, p, Nearest)
    let j22 = checked_mpf_div(f2_yp.sub(f2_ym, p, Nearest), two_hy, p, Nearest)
    let det = j11.mul(j22, p, Nearest).sub(j12.mul(j21, p, Nearest), p, Nearest)
    if det.is_zero() {
      raise ConvergenceError("findroot2: singular Jacobian")
    }
    let dx = checked_mpf_div(
      f1.mul(j22, p, Nearest).sub(f2.mul(j12, p, Nearest), p, Nearest),
      det,
      p,
      Nearest,
    )
    let dy = checked_mpf_div(
      j11.mul(f2, p, Nearest).sub(j21.mul(f1, p, Nearest), p, Nearest),
      det,
      p,
      Nearest,
    )
    let x_next = x.sub(dx, p, Nearest)
    let y_next = y.sub(dy, p, Nearest)
    if max_absolute_pair(
        x_next.sub(x, p, Nearest),
        y_next.sub(y, p, Nearest),
        p,
      ) <=
      tol_abs {
      let (g1, g2) = self.evaluate_root_system(f, x_next, y_next)
      if max_absolute_pair(g1, g2, p) <= tol_abs {
        return (
          x_next.rounded(self.precision(), self.round_mode()),
          y_next.rounded(self.precision(), self.round_mode()),
        )
      }
    }
    x = x_next
    y = y_next
  }
  raise ConvergenceError("findroot2: Newton iteration did not converge")
}

///|
fn MPContext::quadrature_tolerance(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -28 } else if prec > 120 { -24 } else { -20 }
  @mpf.RawMpf::from_mantissa_exponent(1N, shift, 0, Down)
}

///|
fn quadrature_step_limit(max_steps : Int, max_degree : Int?) -> Int {
  let base = if max_steps < 1 { 1 } else { max_steps }
  match max_degree {
    Some(d) => if d > 0 { d } else { base }
    None => base
  }
}

///|
fn is_positive_infinity(x : @mpf.RawMpf) -> Bool {
  x.is_infinite() && x.sign == 0
}

///|
fn is_negative_infinity(x : @mpf.RawMpf) -> Bool {
  x.is_infinite() && x.sign == 1
}

///|
fn MPContext::simpson_quadrature(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let h = checked_mpf_div_int(b.sub(a, prec, Nearest), n, prec, Nearest)
  let fa = f(a)
  let fb = f(b)
  require_finite_value("quad", fa)
  require_finite_value("quad", fb)
  let mut odd = @mpf.RawMpf::zero()
  let mut even = @mpf.RawMpf::zero()
  for i in 1..<n {
    let xi = a.add(h.mul_int(i, prec, Nearest), prec, Nearest)
    let yi = f(xi)
    require_finite_value("quad", yi)
    if (i & 1) == 0 {
      even = even.add(yi, prec, Nearest)
    } else {
      odd = odd.add(yi, prec, Nearest)
    }
  }
  let weighted = fa
    .add(fb, prec, Nearest)
    .add(
      odd
      .mul_int(4, prec, Nearest)
      .add(even.mul_int(2, prec, Nearest), prec, Nearest),
      prec,
      Nearest,
    )
  checked_mpf_div_int(h, 3, prec, Nearest).mul(
    weighted,
    prec,
    self.round_mode(),
  )
}

///|
fn MPContext::midpoint_quadrature(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let h = checked_mpf_div_int(b.sub(a, prec, Nearest), n, prec, Nearest)
  let half_h = checked_mpf_div_int(h, 2, prec, Nearest)
  let mut sum = @mpf.RawMpf::zero()
  for i in 0..<n {
    let xi = a
      .add(half_h, prec, Nearest)
      .add(h.mul_int(i, prec, Nearest), prec, Nearest)
    let yi = f(xi)
    require_finite_value("quad", yi)
    sum = sum.add(yi, prec, Nearest)
  }
  h.mul(sum, prec, self.round_mode())
}

///|
fn MPContext::adaptive_midpoint_quadrature(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let tol = self.quadrature_tolerance(prec)
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut n = 8
  let mut prev = self.midpoint_quadrature(f, a, b, n, prec)
  for _ in 0..<steps {
    n = n * 2
    let cur = self.midpoint_quadrature(f, a, b, n, prec)
    let err = cur.sub(prev, prec, Nearest).abs(prec, Nearest)
    if err <= tol {
      return cur.rounded(self.precision(), self.round_mode())
    }
    prev = cur
  }
  prev.rounded(self.precision(), self.round_mode())
}

///|
fn MPContext::integrate_to_positive_infinity(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let g = (u : @mpf.RawMpf) => {
    let one_minus_u = @mpf.RawMpf::one().sub(u, prec, Nearest)
    let t = u.div(one_minus_u, prec, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    let x = a.add(t, prec, Nearest)
    let den2 = one_minus_u.mul(one_minus_u, prec, Nearest)
    let jac = @mpf.RawMpf::one().div(den2, prec, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    f(x).mul(jac, prec, Nearest)
  }
  self.adaptive_midpoint_quadrature(
    g,
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::one(),
    max_steps,
    prec,
  )
}

///|
fn MPContext::integrate_from_negative_infinity(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let g = (u : @mpf.RawMpf) => {
    let one_minus_u = @mpf.RawMpf::one().sub(u, prec, Nearest)
    let t = u.div(one_minus_u, prec, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    let x = b.sub(t, prec, Nearest)
    let den2 = one_minus_u.mul(one_minus_u, prec, Nearest)
    let jac = @mpf.RawMpf::one().div(den2, prec, Nearest) catch {
      err => raise from_mpf_error(err)
    }
    f(x).mul(jac, prec, Nearest)
  }
  self.adaptive_midpoint_quadrature(
    g,
    @mpf.RawMpf::zero(),
    @mpf.RawMpf::one(),
    max_steps,
    prec,
  )
}

///|
fn MPContext::integrate_real_line(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let g = (t : @mpf.RawMpf) => {
    let t2 = t.mul(t, prec, Nearest)
    let den = @mpf.RawMpf::one().sub(t2, prec, Nearest)
    let x = t.div(den, prec, Nearest) catch { err => raise from_mpf_error(err) }
    let jac = @mpf.RawMpf::one()
      .add(t2, prec, Nearest)
      .div(den.mul(den, prec, Nearest), prec, Nearest) catch {
        err => raise from_mpf_error(err)
      }
    f(x).mul(jac, prec, Nearest)
  }
  self.adaptive_midpoint_quadrature(
    g,
    @mpf.RawMpf::negative_one(),
    @mpf.RawMpf::one(),
    max_steps,
    prec,
  )
}

///|
fn MPContext::integrate_segment(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  if a == b {
    return @mpf.RawMpf::zero()
  }
  if a > b {
    return self
      .integrate_segment(f, b, a, max_steps, prec)
      .negated(self.precision(), self.round_mode())
  }
  if a.is_finite() && b.is_finite() {
    let tol = self.quadrature_tolerance(prec)
    let mut n = 2
    let mut prev = self.simpson_quadrature(f, a, b, n, prec)
    for _ in 0..<max_steps {
      n = n * 2
      let cur = self.simpson_quadrature(f, a, b, n, prec)
      let err = cur.sub(prev, prec, Nearest).abs(prec, Nearest)
      if err <= tol {
        return cur.rounded(self.precision(), self.round_mode())
      }
      prev = cur
    }
    return prev.rounded(self.precision(), self.round_mode())
  }
  if a.is_finite() && is_positive_infinity(b) {
    return self.integrate_to_positive_infinity(f, a, max_steps, prec)
  }
  if is_negative_infinity(a) && b.is_finite() {
    return self.integrate_from_negative_infinity(f, b, max_steps, prec)
  }
  if is_negative_infinity(a) && is_positive_infinity(b) {
    return self.integrate_real_line(f, max_steps, prec)
  }
  raise ValueError("quad: unsupported infinite interval endpoints")
}

///|
/// One-dimensional numerical integration (tanh-sinh-style entrypoint).
///
/// Current implementation supports finite and infinite endpoints via variable
/// transformations; API shape matches mpmath `quadts` subset.
pub fn MPContext::quadts(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise {
  let steps = quadrature_step_limit(max_steps, max_degree)
  self.integrate_segment(f, a, b, steps, self.working_precision())
}

///|
/// One-dimensional numerical integration (Gauss-Legendre-style entrypoint).
///
/// This currently shares the same adaptive core as `quadts`, providing mpmath
/// API compatibility for the migrated subset.
pub fn MPContext::quadgl(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise {
  let steps = quadrature_step_limit(max_steps, max_degree)
  self.integrate_segment(f, a, b, steps, self.working_precision())
}

///|
/// Piecewise one-dimensional numerical integration over multiple breakpoints.
///
/// `points=[x0, x1, ..., xn]` integrates each adjacent segment and sums the
/// results. Supports finite and selected infinite endpoint combinations.
pub fn MPContext::quad(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  points : ArrayView[@mpf.RawMpf],
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise {
  if points.length() < 2 {
    raise ValueError("quad: at least two interval points are required")
  }
  let p = self.working_precision()
  let steps = quadrature_step_limit(max_steps, max_degree)
  let mut s = @mpf.RawMpf::zero()
  for i in 0..<(points.length() - 1) {
    s = s.add(
      self.integrate_segment(f, points[i], points[i + 1], steps, p),
      p,
      Nearest,
    )
  }
  s.rounded(self.precision(), self.round_mode())
}
