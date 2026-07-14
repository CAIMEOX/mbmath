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
  @mpf.from_man_exp(1N, -(p - 8), 0, @mpf.round_down)
}

///|
fn checked_mpf_div(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @mpf.mpf_div(x, y, prec, rnd) catch {
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
  checked_mpf_div(x, @mpf.from_int(n), prec, rnd)
}

///|
fn checked_mpf_pow_int(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  @mpf.mpf_pow_int(x, n, prec, rnd) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn within_tolerance(x : @mpf.RawMpf, tol : @mpf.RawMpf, prec : Int) -> Bool {
  @mpf.mpf_le(@mpf.mpf_abs(x, prec, @mpf.round_nearest), tol)
}

///|
fn require_finite_value(name : String, x : @mpf.RawMpf) -> Unit raise MPError {
  if !@mpf.is_finite(x) {
    raise DomainError("\{name}: non-finite value")
  }
}

///|
fn max_absolute_pair(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf {
  let ax = @mpf.mpf_abs(x, prec, @mpf.round_nearest)
  let ay = @mpf.mpf_abs(y, prec, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, ay) {
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
    let s = @mpf.mpf_sign(t)
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
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
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
      out.push(
        @mpf.mpf_sub(partials[i], partials[i - 1], prec, @mpf.round_nearest),
      )
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
    return (s, @mpf.finf)
  }
  let t0 = terms[terms.length() - 2]
  let t1 = terms[terms.length() - 1]
  let at0 = @mpf.mpf_abs(t0, prec, @mpf.round_nearest)
  let at1 = @mpf.mpf_abs(t1, prec, @mpf.round_nearest)
  if @mpf.is_zero(at1) {
    return (s, @mpf.fzero)
  }
  if @mpf.is_zero(at0) {
    return (s, at1)
  }
  let ratio = checked_mpf_div(at1, at0, prec, @mpf.round_nearest)
  let mut tail = @mpf.fzero
  let ratio_cut = checked_mpf_div_int(
    @mpf.from_int(3),
    5,
    prec,
    @mpf.round_nearest,
  )
  if @mpf.mpf_lt(ratio, ratio_cut) {
    let one_minus_ratio = @mpf.mpf_sub(
      @mpf.fone, ratio, prec, @mpf.round_nearest,
    )
    if !@mpf.is_zero(one_minus_ratio) &&
      @mpf.mpf_gt(one_minus_ratio, @mpf.fzero) {
      tail = checked_mpf_div(
        @mpf.mpf_mul(t1, ratio, prec, @mpf.round_nearest),
        one_minus_ratio,
        prec,
        @mpf.round_nearest,
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
        @mpf.from_int(k),
        @mpf.from_int(k - 1),
        prec,
        @mpf.round_nearest,
      )
      let inv_ratio = checked_mpf_div(at0, at1, prec, @mpf.round_nearest)
      let ln_q = @libelefun.mpf_ln(q, prec, @mpf.round_nearest) catch {
        err => raise from_libelefun_error(err)
      }
      let ln_r = @libelefun.mpf_ln(inv_ratio, prec, @mpf.round_nearest) catch {
        err => raise from_libelefun_error(err)
      }
      if @mpf.is_zero(ln_q) {
        tail = t1
      } else {
        let p_est = checked_mpf_div(ln_r, ln_q, prec, @mpf.round_nearest)
        let denom = @mpf.mpf_sub(p_est, @mpf.fone, prec, @mpf.round_nearest)
        if @mpf.is_zero(denom) || @mpf.mpf_le(denom, @mpf.fzero) {
          tail = t1
        } else {
          tail = @mpf.mpf_mul(
            t1,
            checked_mpf_div(@mpf.from_int(k), denom, prec, @mpf.round_nearest),
            prec,
            @mpf.round_nearest,
          )
        }
      }
    }
  }
  let est = @mpf.mpf_add(s, tail, prec, @mpf.round_nearest)
  (est, @mpf.mpf_abs(tail, prec, @mpf.round_nearest))
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
    prev2.push(@mpf.fzero)
  }
  let mut prev1 : Array[@mpf.RawMpf] = []
  for s in partials {
    prev1.push(s)
  }
  let mut best = partials[n - 1]
  let mut prev_even = best
  let mut err = @mpf.finf
  let mut have_even = false
  for k in 0..<(n - 1) {
    let len = prev1.length()
    if len < 2 {
      break
    }
    let cur : Array[@mpf.RawMpf] = []
    for i in 0..<(len - 1) {
      let diff = @mpf.mpf_sub(prev1[i + 1], prev1[i], prec, @mpf.round_nearest)
      if @mpf.is_zero(diff) || !@mpf.is_finite(diff) {
        cur.push(@mpf.fnan)
      } else {
        let inv = checked_mpf_div(@mpf.fone, diff, prec, @mpf.round_nearest)
        cur.push(@mpf.mpf_add(prev2[i + 1], inv, prec, @mpf.round_nearest))
      }
    }
    let order = k + 1
    if (order & 1) == 0 && cur.length() > 0 {
      let cand = cur[0]
      if @mpf.is_finite(cand) {
        err = @mpf.mpf_abs(
          @mpf.mpf_sub(cand, prev_even, prec, @mpf.round_nearest),
          prec,
          @mpf.round_nearest,
        )
        best = cand
        prev_even = cand
        have_even = true
      }
    }
    prev2 = prev1
    prev1 = cur
  }
  if !have_even {
    err = @mpf.mpf_abs(
      @mpf.mpf_sub(best, partials[n - 1], prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
  }
  (best, err)
}

///|
fn MPContext::estimate_series_limit(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  terms : ArrayView[@mpf.RawMpf],
  start : Int,
  algo : String,
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
  let mut h = @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
  let ax = @mpf.mpf_abs(x, prec, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, @mpf.fone) {
    h = @mpf.mpf_mul(h, ax, prec, @mpf.round_nearest)
  }
  if @mpf.is_zero(h) {
    @mpf.from_man_exp(1N, -8, 0, @mpf.round_down)
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
    let y1 = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
    require_finite_value("diff", y0)
    require_finite_value("diff", y1)
    return checked_mpf_div(
      @mpf.mpf_sub(y1, y0, prec, @mpf.round_nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  if direction < 0 {
    let y0 = f(x)
    let y1 = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
    require_finite_value("diff", y0)
    require_finite_value("diff", y1)
    return checked_mpf_div(
      @mpf.mpf_sub(y0, y1, prec, @mpf.round_nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  let yp = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
  let ym = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
  require_finite_value("diff", yp)
  require_finite_value("diff", ym)
  checked_mpf_div(
    @mpf.mpf_sub(yp, ym, prec, @mpf.round_nearest),
    @mpf.mpf_mul_int(h, 2, prec, @mpf.round_nearest),
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
  let yp = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
  let ym = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
  require_finite_value("diff", y0)
  require_finite_value("diff", yp)
  require_finite_value("diff", ym)
  let num = @mpf.mpf_add(
    @mpf.mpf_sub(
      yp,
      @mpf.mpf_mul_int(y0, 2, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    ),
    ym,
    prec,
    @mpf.round_nearest,
  )
  checked_mpf_div(
    num,
    @mpf.mpf_mul(h, h, prec, @mpf.round_nearest),
    prec,
    self.round_mode(),
  )
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
  let half_h = checked_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  let mut sum = @mpf.fzero
  for k in 0..<=n {
    let coeff_i = binomial_coefficient(n, k)
    let coeff = if (k & 1) == 0 { coeff_i } else { -coeff_i }
    let offset = n - 2 * k
    let xk = @mpf.mpf_add(
      x,
      @mpf.mpf_mul_int(half_h, offset, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    let yk = f(xk)
    require_finite_value("diff", yk)
    let term = @mpf.mpf_mul_int(yk, coeff, prec, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, prec, @mpf.round_nearest)
  }
  let hpow = checked_mpf_pow_int(h, n, prec, @mpf.round_nearest)
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
  let h2 = checked_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  if @mpf.is_zero(h2) {
    return d1
  }
  let d2 = self.central_difference_at_step(f, x, n, h2, prec)
  let correction = checked_mpf_div_int(
    @mpf.mpf_sub(d2, d1, prec, @mpf.round_nearest),
    3,
    prec,
    @mpf.round_nearest,
  )
  @mpf.mpf_add(d2, correction, prec, self.round_mode())
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
    @mpf.mpf_sum(xs, p, self.round_mode(), absolute~)
  } else {
    let ys : Array[@mpf.RawMpf] = []
    for x0 in xs {
      let x = if absolute {
        @mpf.mpf_abs(x0, p, @mpf.round_nearest)
      } else {
        x0
      }
      ys.push(@mpf.mpf_mul(x, x, p, @mpf.round_nearest))
    }
    @mpf.mpf_sum(ys, p, self.round_mode())
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
  let mut acc = @mpf.fone
  for x in xs {
    acc = @mpf.mpf_mul(acc, x, p, self.round_mode())
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
  algo? : String = "levin",
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  if partial_sums.length() < 3 {
    raise ValueError("levin: need at least 3 partial sums")
  }
  let p = self.working_precision()
  let terms = self.terms_from_partial_sums(partial_sums, p)
  let (est, err) = self.estimate_series_limit(partial_sums, terms, 1, algo, p)
  (
    @mpf.mpf_pos(est, self.precision(), self.round_mode()),
    @mpf.mpf_pos(err, self.precision(), self.round_mode()),
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
    return @mpf.fzero
  }
  let mut k = start
  let mut s = @mpf.fzero
  while (step > 0 && k <= stop) || (step < 0 && k >= stop) {
    s = @mpf.mpf_add(s, f(k), p, @mpf.round_nearest)
    k += step
  }
  @mpf.mpf_pos(s, self.precision(), self.round_mode())
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
  algo? : String = "auto",
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
        Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
        None => self.series_tolerance(p)
      }
      let tight = @mpf.mpf_mul_int(tol_abs, 8, p, @mpf.round_nearest)
      let loose = @mpf.mpf_mul_int(tol_abs, 24, p, @mpf.round_nearest)
      let tail_gate = @mpf.from_man_exp(1N, -6, 0, @mpf.round_down)
      let mut s = @mpf.fzero
      let partials : Array[@mpf.RawMpf] = []
      let terms : Array[@mpf.RawMpf] = []
      let mut last_abs_term = @mpf.finf
      let window = 18
      for i in 0..<max_terms {
        let k = start + i
        let term = f(k)
        s = @mpf.mpf_add(s, term, p, @mpf.round_nearest)
        partials.push(s)
        terms.push(term)
        let abs_term = @mpf.mpf_abs(term, p, @mpf.round_nearest)
        last_abs_term = abs_term
        if partials.length() >= 3 {
          let ps = trailing_window(partials, window)
          let ts = trailing_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.estimate_series_limit(
            ps, ts, start_idx, algo, p,
          )
          let delta = @mpf.mpf_abs(
            @mpf.mpf_sub(est, s, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          )
          if @mpf.is_finite(err) &&
            @mpf.mpf_le(err, tight) &&
            @mpf.mpf_le(delta, loose) {
            return @mpf.mpf_pos(est, self.precision(), self.round_mode())
          }
          if @mpf.mpf_le(abs_term, tol_abs) && @mpf.mpf_le(delta, loose) {
            return @mpf.mpf_pos(est, self.precision(), self.round_mode())
          }
        } else if @mpf.is_zero(term) {
          return @mpf.mpf_pos(s, self.precision(), self.round_mode())
        }
      }
      if partials.length() >= 3 {
        let ps = trailing_window(partials, 18)
        let ts = trailing_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.estimate_series_limit(ps, ts, start_idx, algo, p)
        let delta = @mpf.mpf_abs(
          @mpf.mpf_sub(est, s, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
        if @mpf.is_finite(err) &&
          @mpf.mpf_le(err, loose) &&
          @mpf.mpf_le(delta, loose) {
          return @mpf.mpf_pos(est, self.precision(), self.round_mode())
        }
        if @mpf.is_finite(est) && @mpf.mpf_le(last_abs_term, tail_gate) {
          return @mpf.mpf_pos(est, self.precision(), self.round_mode())
        }
      }
      if @mpf.is_finite(s) && @mpf.mpf_le(last_abs_term, tail_gate) {
        return @mpf.mpf_pos(s, self.precision(), self.round_mode())
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
  algo? : String = "auto",
  tol? : @mpf.RawMpf,
  max_terms? : Int = 800,
) -> @mpf.RawMpf raise {
  match stop {
    Some(b) => {
      if start > b {
        return @mpf.fone
      }
      let p = self.working_precision()
      let mut acc = @mpf.fone
      for k in start..<=b {
        acc = @mpf.mpf_mul(acc, f(k), p, @mpf.round_nearest)
      }
      @mpf.mpf_pos(acc, self.precision(), self.round_mode())
    }
    None => {
      if max_terms < 1 {
        raise ValueError("nprod: max_terms must be positive")
      }
      let p = self.working_precision()
      let tol_abs = match tol {
        Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
        None => self.series_tolerance(p)
      }
      let tight = @mpf.mpf_mul_int(tol_abs, 8, p, @mpf.round_nearest)
      let loose = @mpf.mpf_mul_int(tol_abs, 24, p, @mpf.round_nearest)
      let tail_gate = @mpf.from_man_exp(1N, -6, 0, @mpf.round_down)
      let mut slog = @mpf.fzero
      let partials : Array[@mpf.RawMpf] = []
      let terms : Array[@mpf.RawMpf] = []
      let mut last_abs_term = @mpf.finf
      let window = 18
      for i in 0..<max_terms {
        let k = start + i
        let tk = f(k)
        if !@mpf.is_finite(tk) {
          raise DomainError("nprod: non-finite term in product")
        }
        if @mpf.mpf_le(tk, @mpf.fzero) {
          raise DomainError("nprod: infinite products require positive terms")
        }
        let log_tk = @libelefun.mpf_ln(tk, p, @mpf.round_nearest) catch {
          err => raise from_libelefun_error(err)
        }
        slog = @mpf.mpf_add(slog, log_tk, p, @mpf.round_nearest)
        partials.push(slog)
        terms.push(log_tk)
        let abs_term = @mpf.mpf_abs(log_tk, p, @mpf.round_nearest)
        last_abs_term = abs_term
        if partials.length() >= 3 {
          let ps = trailing_window(partials, window)
          let ts = trailing_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.estimate_series_limit(
            ps, ts, start_idx, algo, p,
          )
          let delta = @mpf.mpf_abs(
            @mpf.mpf_sub(est, slog, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          )
          if @mpf.is_finite(err) &&
            @mpf.mpf_le(err, tight) &&
            @mpf.mpf_le(delta, loose) {
            return checked_mpf_exp(est, self.precision(), self.round_mode())
          }
          if @mpf.mpf_le(abs_term, tol_abs) && @mpf.mpf_le(delta, loose) {
            return checked_mpf_exp(est, self.precision(), self.round_mode())
          }
        } else if @mpf.is_zero(log_tk) {
          return checked_mpf_exp(slog, self.precision(), self.round_mode())
        }
      }
      if partials.length() >= 3 {
        let ps = trailing_window(partials, 18)
        let ts = trailing_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.estimate_series_limit(ps, ts, start_idx, algo, p)
        let delta = @mpf.mpf_abs(
          @mpf.mpf_sub(est, slog, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
        if @mpf.is_finite(err) &&
          @mpf.mpf_le(err, loose) &&
          @mpf.mpf_le(delta, loose) {
          return checked_mpf_exp(est, self.precision(), self.round_mode())
        }
        if @mpf.is_finite(est) && @mpf.mpf_le(last_abs_term, tail_gate) {
          return checked_mpf_exp(est, self.precision(), self.round_mode())
        }
      }
      if @mpf.is_finite(slog) && @mpf.mpf_le(last_abs_term, tail_gate) {
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
  algo? : String = "step",
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
  algo? : String = "step",
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
  algo? : String = "step",
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
  algo? : String = "step",
) -> Array[@mpf.RawMpf] raise {
  if n < 0 {
    raise ValueError("taylor: n must be non-negative")
  }
  let p = self.working_precision() + 12
  let out : Array[@mpf.RawMpf] = []
  let mut fact = @mpf.fone
  for k in 0..<=n {
    if k > 0 {
      fact = @mpf.mpf_mul_int(fact, k, p, @mpf.round_nearest)
    }
    let dk = self.diff(f, x, n=k, algo~)
    let ck = if k == 0 {
      dk
    } else {
      checked_mpf_div(dk, fact, p, @mpf.round_nearest)
    }
    out.push(@mpf.mpf_pos(ck, self.precision(), self.round_mode()))
  }
  out
}

///|
fn MPContext::apply_partial_derivative3(
  self : MPContext,
  f : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf) -> @mpf.RawMpf raise?,
  xyz : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf),
  orders : (Int, Int, Int),
  algo : String,
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
    @mpf.fone
  } else {
    self.differentiation_step(x, nx, step_prec)
  }
  let hy = if ny == 0 {
    @mpf.fone
  } else {
    self.differentiation_step(y, ny, step_prec)
  }
  let hz = if nz == 0 {
    @mpf.fone
  } else {
    self.differentiation_step(z, nz, step_prec)
  }
  let mut sum1 = @mpf.fzero
  let half_hx = if nx == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hx, 2, p, @mpf.round_nearest)
  }
  let half_hy = if ny == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hy, 2, p, @mpf.round_nearest)
  }
  let half_hz = if nz == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hz, 2, p, @mpf.round_nearest)
  }
  for i in 0..<=nx {
    let ci = binomial_coefficient(nx, i)
    let xi = if nx == 0 {
      x
    } else {
      @mpf.mpf_add(
        x,
        @mpf.mpf_mul_int(half_hx, nx - 2 * i, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    for j in 0..<=ny {
      let cj = binomial_coefficient(ny, j)
      let yj = if ny == 0 {
        y
      } else {
        @mpf.mpf_add(
          y,
          @mpf.mpf_mul_int(half_hy, ny - 2 * j, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
      for k in 0..<=nz {
        let ck = binomial_coefficient(nz, k)
        let sign = if ((i + j + k) & 1) == 0 { 1 } else { -1 }
        let coeff = sign * ci * cj * ck
        let zk = if nz == 0 {
          z
        } else {
          @mpf.mpf_add(
            z,
            @mpf.mpf_mul_int(half_hz, nz - 2 * k, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          )
        }
        let fv = f(xi, yj, zk)
        require_finite_value("diff_partial3", fv)
        sum1 = @mpf.mpf_add(
          sum1,
          @mpf.mpf_mul_int(fv, coeff, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
    }
  }
  let mut den1 = @mpf.fone
  if nx > 0 {
    den1 = @mpf.mpf_mul(
      den1,
      checked_mpf_pow_int(hx, nx, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if ny > 0 {
    den1 = @mpf.mpf_mul(
      den1,
      checked_mpf_pow_int(hy, ny, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if nz > 0 {
    den1 = @mpf.mpf_mul(
      den1,
      checked_mpf_pow_int(hz, nz, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let d1 = checked_mpf_div(sum1, den1, p, self.round_mode())
  let hx2 = if nx == 0 {
    hx
  } else {
    checked_mpf_div_int(hx, 2, p, @mpf.round_nearest)
  }
  let hy2 = if ny == 0 {
    hy
  } else {
    checked_mpf_div_int(hy, 2, p, @mpf.round_nearest)
  }
  let hz2 = if nz == 0 {
    hz
  } else {
    checked_mpf_div_int(hz, 2, p, @mpf.round_nearest)
  }
  if nx + ny + nz <= 1 {
    return d1
  }
  let mut sum2 = @mpf.fzero
  let half_hx2 = if nx == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hx2, 2, p, @mpf.round_nearest)
  }
  let half_hy2 = if ny == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hy2, 2, p, @mpf.round_nearest)
  }
  let half_hz2 = if nz == 0 {
    @mpf.fzero
  } else {
    checked_mpf_div_int(hz2, 2, p, @mpf.round_nearest)
  }
  for i in 0..<=nx {
    let ci = binomial_coefficient(nx, i)
    let xi = if nx == 0 {
      x
    } else {
      @mpf.mpf_add(
        x,
        @mpf.mpf_mul_int(half_hx2, nx - 2 * i, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      )
    }
    for j in 0..<=ny {
      let cj = binomial_coefficient(ny, j)
      let yj = if ny == 0 {
        y
      } else {
        @mpf.mpf_add(
          y,
          @mpf.mpf_mul_int(half_hy2, ny - 2 * j, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
      for k in 0..<=nz {
        let ck = binomial_coefficient(nz, k)
        let sign = if ((i + j + k) & 1) == 0 { 1 } else { -1 }
        let coeff = sign * ci * cj * ck
        let zk = if nz == 0 {
          z
        } else {
          @mpf.mpf_add(
            z,
            @mpf.mpf_mul_int(half_hz2, nz - 2 * k, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          )
        }
        let fv = f(xi, yj, zk)
        require_finite_value("diff_partial3", fv)
        sum2 = @mpf.mpf_add(
          sum2,
          @mpf.mpf_mul_int(fv, coeff, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
      }
    }
  }
  let mut den2 = @mpf.fone
  if nx > 0 {
    den2 = @mpf.mpf_mul(
      den2,
      checked_mpf_pow_int(hx2, nx, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if ny > 0 {
    den2 = @mpf.mpf_mul(
      den2,
      checked_mpf_pow_int(hy2, ny, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if nz > 0 {
    den2 = @mpf.mpf_mul(
      den2,
      checked_mpf_pow_int(hz2, nz, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let d2 = checked_mpf_div(sum2, den2, p, self.round_mode())
  let correction = checked_mpf_div_int(
    @mpf.mpf_sub(d2, d1, p, @mpf.round_nearest),
    3,
    p,
    @mpf.round_nearest,
  )
  @mpf.mpf_add(d2, correction, p, self.round_mode())
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
  algo? : String = "step",
) -> @mpf.RawMpf raise {
  let (x, y, z) = xyz
  require_finite_value("diff_partial3", x)
  require_finite_value("diff_partial3", y)
  require_finite_value("diff_partial3", z)
  let v = self.apply_partial_derivative3(f, xyz, orders, algo)
  @mpf.mpf_pos(v, self.precision(), self.round_mode())
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
    return @mpf.mpf_pos(x_prev, self.precision(), self.round_mode())
  }
  if within_tolerance(y, tol, prec) {
    return @mpf.mpf_pos(x, self.precision(), self.round_mode())
  }
  for _ in 0..<max_steps {
    let denom = @mpf.mpf_sub(y, y_prev, prec, @mpf.round_nearest)
    if @mpf.is_zero(denom) {
      raise ConvergenceError("findroot: zero slope in secant iteration")
    }
    let step = checked_mpf_div(
      @mpf.mpf_mul(
        y,
        @mpf.mpf_sub(x, x_prev, prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      ),
      denom,
      prec,
      @mpf.round_nearest,
    )
    let x_next = @mpf.mpf_sub(x, step, prec, @mpf.round_nearest)
    if within_tolerance(
        @mpf.mpf_sub(x_next, x, prec, @mpf.round_nearest),
        tol,
        prec,
      ) {
      return @mpf.mpf_pos(x_next, self.precision(), self.round_mode())
    }
    x_prev = x
    y_prev = y
    x = x_next
    y = f(x)
    require_finite_value("findroot", y)
    if within_tolerance(y, tol, prec) {
      return @mpf.mpf_pos(x, self.precision(), self.round_mode())
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
  solver? : String = "auto",
) -> @mpf.RawMpf raise {
  let p = self.working_precision()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
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
        self.findroot_secant(
          f,
          x0,
          @mpf.mpf_add(x0, h, p, @mpf.round_nearest),
          tol_abs,
          steps,
          p,
        )
      }
    }
  }
  let mut x = x0
  for _ in 0..<steps {
    let y = f(x)
    require_finite_value("findroot", y)
    if within_tolerance(y, tol_abs, p) {
      return @mpf.mpf_pos(x, self.precision(), self.round_mode())
    }
    let dy = self.first_derivative(f, x, 0, p)
    if @mpf.is_zero(dy) {
      let h = self.differentiation_step(x, 1, p)
      return self.findroot_secant(
        f,
        x,
        @mpf.mpf_add(x, h, p, @mpf.round_nearest),
        tol_abs,
        steps,
        p,
      )
    }
    let step = checked_mpf_div(y, dy, p, @mpf.round_nearest)
    let x_next = @mpf.mpf_sub(x, step, p, @mpf.round_nearest)
    if within_tolerance(
        @mpf.mpf_sub(x_next, x, p, @mpf.round_nearest),
        tol_abs,
        p,
      ) {
      return @mpf.mpf_pos(x_next, self.precision(), self.round_mode())
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
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.default_numerical_tolerance()
  }
  if !@mpf.is_finite(a) || !@mpf.is_finite(b) {
    raise ValueError("findroot_interval: interval endpoints must be finite")
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut lo = a
  let mut hi = b
  if @mpf.mpf_gt(lo, hi) {
    let t = lo
    lo = hi
    hi = t
  }
  let mut f_lo = f(lo)
  let mut f_hi = f(hi)
  require_finite_value("findroot_interval", f_lo)
  require_finite_value("findroot_interval", f_hi)
  if within_tolerance(f_lo, tol_abs, p) {
    return @mpf.mpf_pos(lo, self.precision(), self.round_mode())
  }
  if within_tolerance(f_hi, tol_abs, p) {
    return @mpf.mpf_pos(hi, self.precision(), self.round_mode())
  }
  let mut s_lo = @mpf.mpf_sign(f_lo)
  let s_hi = @mpf.mpf_sign(f_hi)
  if s_lo == s_hi {
    raise ValueError("findroot_interval: interval does not bracket a root")
  }
  for _ in 0..<steps {
    let mid = checked_mpf_div_int(
      @mpf.mpf_add(lo, hi, p, @mpf.round_nearest),
      2,
      p,
      @mpf.round_nearest,
    )
    let f_mid = f(mid)
    require_finite_value("findroot_interval", f_mid)
    if within_tolerance(f_mid, tol_abs, p) ||
      within_tolerance(@mpf.mpf_sub(hi, lo, p, @mpf.round_nearest), tol_abs, p) {
      return @mpf.mpf_pos(mid, self.precision(), self.round_mode())
    }
    let s_mid = @mpf.mpf_sign(f_mid)
    if s_mid == s_lo {
      lo = mid
      f_lo = f_mid
      s_lo = @mpf.mpf_sign(f_lo)
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
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.default_numerical_tolerance()
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut x = x0
  let mut y = y0
  for _ in 0..<steps {
    let (f1, f2) = self.evaluate_root_system(f, x, y)
    if @mpf.mpf_le(max_absolute_pair(f1, f2, p), tol_abs) {
      return (
        @mpf.mpf_pos(x, self.precision(), self.round_mode()),
        @mpf.mpf_pos(y, self.precision(), self.round_mode()),
      )
    }
    let hx = self.differentiation_step(x, 1, p)
    let hy = self.differentiation_step(y, 1, p)
    let xp = @mpf.mpf_add(x, hx, p, @mpf.round_nearest)
    let xm = @mpf.mpf_sub(x, hx, p, @mpf.round_nearest)
    let yp = @mpf.mpf_add(y, hy, p, @mpf.round_nearest)
    let ym = @mpf.mpf_sub(y, hy, p, @mpf.round_nearest)
    let (f1_xp, f2_xp) = self.evaluate_root_system(f, xp, y)
    let (f1_xm, f2_xm) = self.evaluate_root_system(f, xm, y)
    let (f1_yp, f2_yp) = self.evaluate_root_system(f, x, yp)
    let (f1_ym, f2_ym) = self.evaluate_root_system(f, x, ym)
    let two_hx = @mpf.mpf_mul_int(hx, 2, p, @mpf.round_nearest)
    let two_hy = @mpf.mpf_mul_int(hy, 2, p, @mpf.round_nearest)
    let j11 = checked_mpf_div(
      @mpf.mpf_sub(f1_xp, f1_xm, p, @mpf.round_nearest),
      two_hx,
      p,
      @mpf.round_nearest,
    )
    let j21 = checked_mpf_div(
      @mpf.mpf_sub(f2_xp, f2_xm, p, @mpf.round_nearest),
      two_hx,
      p,
      @mpf.round_nearest,
    )
    let j12 = checked_mpf_div(
      @mpf.mpf_sub(f1_yp, f1_ym, p, @mpf.round_nearest),
      two_hy,
      p,
      @mpf.round_nearest,
    )
    let j22 = checked_mpf_div(
      @mpf.mpf_sub(f2_yp, f2_ym, p, @mpf.round_nearest),
      two_hy,
      p,
      @mpf.round_nearest,
    )
    let det = @mpf.mpf_sub(
      @mpf.mpf_mul(j11, j22, p, @mpf.round_nearest),
      @mpf.mpf_mul(j12, j21, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
    if @mpf.is_zero(det) {
      raise ConvergenceError("findroot2: singular Jacobian")
    }
    let dx = checked_mpf_div(
      @mpf.mpf_sub(
        @mpf.mpf_mul(f1, j22, p, @mpf.round_nearest),
        @mpf.mpf_mul(f2, j12, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      det,
      p,
      @mpf.round_nearest,
    )
    let dy = checked_mpf_div(
      @mpf.mpf_sub(
        @mpf.mpf_mul(j11, f2, p, @mpf.round_nearest),
        @mpf.mpf_mul(j21, f1, p, @mpf.round_nearest),
        p,
        @mpf.round_nearest,
      ),
      det,
      p,
      @mpf.round_nearest,
    )
    let x_next = @mpf.mpf_sub(x, dx, p, @mpf.round_nearest)
    let y_next = @mpf.mpf_sub(y, dy, p, @mpf.round_nearest)
    if @mpf.mpf_le(
        max_absolute_pair(
          @mpf.mpf_sub(x_next, x, p, @mpf.round_nearest),
          @mpf.mpf_sub(y_next, y, p, @mpf.round_nearest),
          p,
        ),
        tol_abs,
      ) {
      let (g1, g2) = self.evaluate_root_system(f, x_next, y_next)
      if @mpf.mpf_le(max_absolute_pair(g1, g2, p), tol_abs) {
        return (
          @mpf.mpf_pos(x_next, self.precision(), self.round_mode()),
          @mpf.mpf_pos(y_next, self.precision(), self.round_mode()),
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
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
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
  @mpf.is_inf(x) && x.sign == 0
}

///|
fn is_negative_infinity(x : @mpf.RawMpf) -> Bool {
  @mpf.is_inf(x) && x.sign == 1
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
  let h = checked_mpf_div_int(
    @mpf.mpf_sub(b, a, prec, @mpf.round_nearest),
    n,
    prec,
    @mpf.round_nearest,
  )
  let fa = f(a)
  let fb = f(b)
  require_finite_value("quad", fa)
  require_finite_value("quad", fb)
  let mut odd = @mpf.fzero
  let mut even = @mpf.fzero
  for i in 1..<n {
    let xi = @mpf.mpf_add(
      a,
      @mpf.mpf_mul_int(h, i, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    let yi = f(xi)
    require_finite_value("quad", yi)
    if (i & 1) == 0 {
      even = @mpf.mpf_add(even, yi, prec, @mpf.round_nearest)
    } else {
      odd = @mpf.mpf_add(odd, yi, prec, @mpf.round_nearest)
    }
  }
  let weighted = @mpf.mpf_add(
    @mpf.mpf_add(fa, fb, prec, @mpf.round_nearest),
    @mpf.mpf_add(
      @mpf.mpf_mul_int(odd, 4, prec, @mpf.round_nearest),
      @mpf.mpf_mul_int(even, 2, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    ),
    prec,
    @mpf.round_nearest,
  )
  @mpf.mpf_mul(
    checked_mpf_div_int(h, 3, prec, @mpf.round_nearest),
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
  let h = checked_mpf_div_int(
    @mpf.mpf_sub(b, a, prec, @mpf.round_nearest),
    n,
    prec,
    @mpf.round_nearest,
  )
  let half_h = checked_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  let mut sum = @mpf.fzero
  for i in 0..<n {
    let xi = @mpf.mpf_add(
      @mpf.mpf_add(a, half_h, prec, @mpf.round_nearest),
      @mpf.mpf_mul_int(h, i, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    let yi = f(xi)
    require_finite_value("quad", yi)
    sum = @mpf.mpf_add(sum, yi, prec, @mpf.round_nearest)
  }
  @mpf.mpf_mul(h, sum, prec, self.round_mode())
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
    let err = @mpf.mpf_abs(
      @mpf.mpf_sub(cur, prev, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    if @mpf.mpf_le(err, tol) {
      return @mpf.mpf_pos(cur, self.precision(), self.round_mode())
    }
    prev = cur
  }
  @mpf.mpf_pos(prev, self.precision(), self.round_mode())
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
    let one_minus_u = @mpf.mpf_sub(@mpf.fone, u, prec, @mpf.round_nearest)
    let t = @mpf.mpf_div(u, one_minus_u, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    let x = @mpf.mpf_add(a, t, prec, @mpf.round_nearest)
    let den2 = @mpf.mpf_mul(one_minus_u, one_minus_u, prec, @mpf.round_nearest)
    let jac = @mpf.mpf_div(@mpf.fone, den2, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.adaptive_midpoint_quadrature(g, @mpf.fzero, @mpf.fone, max_steps, prec)
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
    let one_minus_u = @mpf.mpf_sub(@mpf.fone, u, prec, @mpf.round_nearest)
    let t = @mpf.mpf_div(u, one_minus_u, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    let x = @mpf.mpf_sub(b, t, prec, @mpf.round_nearest)
    let den2 = @mpf.mpf_mul(one_minus_u, one_minus_u, prec, @mpf.round_nearest)
    let jac = @mpf.mpf_div(@mpf.fone, den2, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.adaptive_midpoint_quadrature(g, @mpf.fzero, @mpf.fone, max_steps, prec)
}

///|
fn MPContext::integrate_real_line(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise {
  let g = (t : @mpf.RawMpf) => {
    let t2 = @mpf.mpf_mul(t, t, prec, @mpf.round_nearest)
    let den = @mpf.mpf_sub(@mpf.fone, t2, prec, @mpf.round_nearest)
    let x = @mpf.mpf_div(t, den, prec, @mpf.round_nearest) catch {
      err => raise from_mpf_error(err)
    }
    let jac = @mpf.mpf_div(
      @mpf.mpf_add(@mpf.fone, t2, prec, @mpf.round_nearest),
      @mpf.mpf_mul(den, den, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    ) catch {
      err => raise from_mpf_error(err)
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.adaptive_midpoint_quadrature(g, @mpf.fnone, @mpf.fone, max_steps, prec)
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
  if @mpf.mpf_eq(a, b) {
    return @mpf.fzero
  }
  if @mpf.mpf_gt(a, b) {
    return @mpf.mpf_neg(
      self.integrate_segment(f, b, a, max_steps, prec),
      self.precision(),
      self.round_mode(),
    )
  }
  if @mpf.is_finite(a) && @mpf.is_finite(b) {
    let tol = self.quadrature_tolerance(prec)
    let mut n = 2
    let mut prev = self.simpson_quadrature(f, a, b, n, prec)
    for _ in 0..<max_steps {
      n = n * 2
      let cur = self.simpson_quadrature(f, a, b, n, prec)
      let err = @mpf.mpf_abs(
        @mpf.mpf_sub(cur, prev, prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      )
      if @mpf.mpf_le(err, tol) {
        return @mpf.mpf_pos(cur, self.precision(), self.round_mode())
      }
      prev = cur
    }
    return @mpf.mpf_pos(prev, self.precision(), self.round_mode())
  }
  if @mpf.is_finite(a) && is_positive_infinity(b) {
    return self.integrate_to_positive_infinity(f, a, max_steps, prec)
  }
  if is_negative_infinity(a) && @mpf.is_finite(b) {
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
  let mut s = @mpf.fzero
  for i in 0..<(points.length() - 1) {
    s = @mpf.mpf_add(
      s,
      self.integrate_segment(f, points[i], points[i + 1], steps, p),
      p,
      @mpf.round_nearest,
    )
  }
  @mpf.mpf_pos(s, self.precision(), self.round_mode())
}
