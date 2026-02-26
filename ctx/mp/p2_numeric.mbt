///|
type UnaryMpfFn = (@mpf.RawMpf) -> @mpf.RawMpf

///|
type TernaryMpfFn = (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf) -> @mpf.RawMpf

///|
type System2Fn = (@mpf.RawMpf, @mpf.RawMpf) -> (@mpf.RawMpf, @mpf.RawMpf)

///|
type SeriesTermFn = (Int) -> @mpf.RawMpf

///|
fn MPContext::p2_work_prec(self : MPContext) -> Int {
  if self.precision() > 0 {
    self.precision() + 32
  } else {
    96
  }
}

///|
fn MPContext::p2_default_tol(self : MPContext) -> @mpf.RawMpf {
  let p = if self.precision() > 0 { self.precision() } else { 80 }
  @mpf.from_man_exp(1N, -(p - 8), 0, @mpf.round_down)
}

///|
fn p2_mpf_div(
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
fn p2_mpf_div_int(
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MPError {
  p2_mpf_div(x, @mpf.from_int(n), prec, rnd)
}

///|
fn p2_mpf_pow_int(
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
fn p2_is_small(x : @mpf.RawMpf, tol : @mpf.RawMpf, prec : Int) -> Bool {
  @mpf.mpf_le(@mpf.mpf_abs(x, prec, @mpf.round_nearest), tol)
}

///|
fn p2_assert_finite(name : String, x : @mpf.RawMpf) -> Unit raise MPError {
  if !@mpf.is_finite(x) {
    raise MPError::DomainError("\{name}: non-finite value")
  }
}

///|
fn p2_abs_max2(x : @mpf.RawMpf, y : @mpf.RawMpf, prec : Int) -> @mpf.RawMpf {
  let ax = @mpf.mpf_abs(x, prec, @mpf.round_nearest)
  let ay = @mpf.mpf_abs(y, prec, @mpf.round_nearest)
  if @mpf.mpf_gt(ax, ay) {
    ax
  } else {
    ay
  }
}

///|
fn p2_binom(n : Int, k : Int) -> Int {
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
fn p2_tail_window(
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
fn p2_terms_alternating(terms : ArrayView[@mpf.RawMpf]) -> Bool {
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
fn MPContext::p2_series_tol(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 220 { -36 } else if prec > 140 { -30 } else { -24 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
fn MPContext::p2_terms_from_partials(
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
fn MPContext::p2_series_richardson(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  terms : ArrayView[@mpf.RawMpf],
  start : Int,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  ignore(self)
  if partials.length() == 0 {
    raise MPError::ValueError("series: empty sequence")
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
  let ratio = p2_mpf_div(at1, at0, prec, @mpf.round_nearest)
  let mut tail = @mpf.fzero
  let ratio_cut = p2_mpf_div_int(@mpf.from_int(3), 5, prec, @mpf.round_nearest)
  if @mpf.mpf_lt(ratio, ratio_cut) {
    let one_minus_ratio = @mpf.mpf_sub(
      @mpf.fone, ratio, prec, @mpf.round_nearest,
    )
    if !@mpf.is_zero(one_minus_ratio) &&
      @mpf.mpf_gt(one_minus_ratio, @mpf.fzero) {
      tail = p2_mpf_div(
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
      let q = p2_mpf_div(
        @mpf.from_int(k),
        @mpf.from_int(k - 1),
        prec,
        @mpf.round_nearest,
      )
      let inv_ratio = p2_mpf_div(at0, at1, prec, @mpf.round_nearest)
      let ln_q = @libelefun.mpf_ln(q, prec, @mpf.round_nearest) catch {
        _ => @mpf.fzero
      }
      let ln_r = @libelefun.mpf_ln(inv_ratio, prec, @mpf.round_nearest) catch {
        _ => @mpf.fzero
      }
      if @mpf.is_zero(ln_q) {
        tail = t1
      } else {
        let p_est = p2_mpf_div(ln_r, ln_q, prec, @mpf.round_nearest)
        let denom = @mpf.mpf_sub(p_est, @mpf.fone, prec, @mpf.round_nearest)
        if @mpf.is_zero(denom) || @mpf.mpf_le(denom, @mpf.fzero) {
          tail = t1
        } else {
          tail = @mpf.mpf_mul(
            t1,
            p2_mpf_div(@mpf.from_int(k), denom, prec, @mpf.round_nearest),
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
fn MPContext::p2_series_wynn(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  ignore(self)
  let n = partials.length()
  if n < 3 {
    raise MPError::ValueError("levin: need at least 3 partial sums")
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
        let inv = p2_mpf_div(@mpf.fone, diff, prec, @mpf.round_nearest)
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
fn MPContext::p2_series_estimate(
  self : MPContext,
  partials : ArrayView[@mpf.RawMpf],
  terms : ArrayView[@mpf.RawMpf],
  start : Int,
  algo : String,
  prec : Int,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  let key = algo.to_lower()
  match key {
    "r" => self.p2_series_richardson(partials, terms, start, prec)
    "richardson" => self.p2_series_richardson(partials, terms, start, prec)
    "levin" => self.p2_series_wynn(partials, prec)
    "l" => self.p2_series_wynn(partials, prec)
    "shanks" => self.p2_series_wynn(partials, prec)
    "e" => self.p2_series_wynn(partials, prec)
    "euler" => self.p2_series_wynn(partials, prec)
    "sidi" => self.p2_series_wynn(partials, prec)
    "u" => self.p2_series_wynn(partials, prec)
    "v" => self.p2_series_wynn(partials, prec)
    "t" => self.p2_series_wynn(partials, prec)
    "auto" =>
      if p2_terms_alternating(terms) {
        self.p2_series_wynn(partials, prec)
      } else {
        self.p2_series_richardson(partials, terms, start, prec)
      }
    _ => raise MPError::ValueError("series: unknown method '\{algo}'")
  }
}

///|
fn MPContext::p2_diff_step(
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
fn MPContext::p2_diff_first(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  direction : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let h = self.p2_diff_step(x, 1, prec)
  if direction > 0 {
    let y0 = f(x)
    let y1 = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
    p2_assert_finite("diff", y0)
    p2_assert_finite("diff", y1)
    return p2_mpf_div(
      @mpf.mpf_sub(y1, y0, prec, @mpf.round_nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  if direction < 0 {
    let y0 = f(x)
    let y1 = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
    p2_assert_finite("diff", y0)
    p2_assert_finite("diff", y1)
    return p2_mpf_div(
      @mpf.mpf_sub(y0, y1, prec, @mpf.round_nearest),
      h,
      prec,
      self.round_mode(),
    )
  }
  let yp = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
  let ym = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
  p2_assert_finite("diff", yp)
  p2_assert_finite("diff", ym)
  p2_mpf_div(
    @mpf.mpf_sub(yp, ym, prec, @mpf.round_nearest),
    @mpf.mpf_mul_int(h, 2, prec, @mpf.round_nearest),
    prec,
    self.round_mode(),
  )
}

///|
fn MPContext::p2_diff_second(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let h = self.p2_diff_step(x, 2, prec)
  let y0 = f(x)
  let yp = f(@mpf.mpf_add(x, h, prec, @mpf.round_nearest))
  let ym = f(@mpf.mpf_sub(x, h, prec, @mpf.round_nearest))
  p2_assert_finite("diff", y0)
  p2_assert_finite("diff", yp)
  p2_assert_finite("diff", ym)
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
  p2_mpf_div(
    num,
    @mpf.mpf_mul(h, h, prec, @mpf.round_nearest),
    prec,
    self.round_mode(),
  )
}

///|
fn MPContext::p2_diff_central_n_at_step(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  n : Int,
  h : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let half_h = p2_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  let mut sum = @mpf.fzero
  for k in 0..<=n {
    let coeff_i = p2_binom(n, k)
    let coeff = if (k & 1) == 0 { coeff_i } else { -coeff_i }
    let offset = n - 2 * k
    let xk = @mpf.mpf_add(
      x,
      @mpf.mpf_mul_int(half_h, offset, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    let yk = f(xk)
    p2_assert_finite("diff", yk)
    let term = @mpf.mpf_mul_int(yk, coeff, prec, @mpf.round_nearest)
    sum = @mpf.mpf_add(sum, term, prec, @mpf.round_nearest)
  }
  let hpow = p2_mpf_pow_int(h, n, prec, @mpf.round_nearest)
  p2_mpf_div(sum, hpow, prec, self.round_mode())
}

///|
fn MPContext::p2_diff_central_n(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let h = self.p2_diff_step(x, n, prec)
  let d1 = self.p2_diff_central_n_at_step(f, x, n, h, prec)
  let h2 = p2_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  if @mpf.is_zero(h2) {
    return d1
  }
  let d2 = self.p2_diff_central_n_at_step(f, x, n, h2, prec)
  let correction = p2_mpf_div_int(
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
  let p = self.p2_work_prec()
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
  let p = self.p2_work_prec()
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
    raise MPError::ValueError("levin: need at least 3 partial sums")
  }
  let p = self.p2_work_prec()
  let terms = self.p2_terms_from_partials(partial_sums, p)
  let (est, err) = self.p2_series_estimate(partial_sums, terms, 1, algo, p)
  (
    @mpf.mpf_pos(est, self.precision(), self.round_mode()),
    @mpf.mpf_pos(err, self.precision(), self.round_mode()),
  )
}

///|
/// Finite integer-index summation `sum(f(k), k=start..stop, step)`.
pub fn MPContext::summation(
  self : MPContext,
  f : SeriesTermFn,
  start : Int,
  stop : Int,
  step? : Int = 1,
) -> @mpf.RawMpf raise MPError {
  if step == 0 {
    raise MPError::ValueError("summation: step must be non-zero")
  }
  let p = self.p2_work_prec()
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
  f : SeriesTermFn,
  start : Int,
  stop? : Int,
  algo? : String = "auto",
  tol? : @mpf.RawMpf,
  max_terms? : Int = 800,
) -> @mpf.RawMpf raise MPError {
  match stop {
    Some(b) => self.summation(f, start, b)
    None => {
      if max_terms < 1 {
        raise MPError::ValueError("nsum: max_terms must be positive")
      }
      let p = self.p2_work_prec()
      let tol_abs = match tol {
        Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
        None => self.p2_series_tol(p)
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
          let ps = p2_tail_window(partials, window)
          let ts = p2_tail_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.p2_series_estimate(ps, ts, start_idx, algo, p)
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
        let ps = p2_tail_window(partials, 18)
        let ts = p2_tail_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.p2_series_estimate(ps, ts, start_idx, algo, p)
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
      raise MPError::ConvergenceError("nsum: series did not converge")
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
  f : SeriesTermFn,
  start : Int,
  stop? : Int,
  algo? : String = "auto",
  tol? : @mpf.RawMpf,
  max_terms? : Int = 800,
) -> @mpf.RawMpf raise MPError {
  match stop {
    Some(b) => {
      if start > b {
        return @mpf.fone
      }
      let p = self.p2_work_prec()
      let mut acc = @mpf.fone
      for k in start..<=b {
        acc = @mpf.mpf_mul(acc, f(k), p, @mpf.round_nearest)
      }
      @mpf.mpf_pos(acc, self.precision(), self.round_mode())
    }
    None => {
      if max_terms < 1 {
        raise MPError::ValueError("nprod: max_terms must be positive")
      }
      let p = self.p2_work_prec()
      let tol_abs = match tol {
        Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
        None => self.p2_series_tol(p)
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
          raise MPError::DomainError("nprod: non-finite term in product")
        }
        if @mpf.mpf_le(tk, @mpf.fzero) {
          raise MPError::DomainError(
            "nprod: infinite products require positive terms",
          )
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
          let ps = p2_tail_window(partials, window)
          let ts = p2_tail_window(terms, window)
          let start_idx = start + partials.length() - ps.length()
          let (est, err) = self.p2_series_estimate(ps, ts, start_idx, algo, p)
          let delta = @mpf.mpf_abs(
            @mpf.mpf_sub(est, slog, p, @mpf.round_nearest),
            p,
            @mpf.round_nearest,
          )
          if @mpf.is_finite(err) &&
            @mpf.mpf_le(err, tight) &&
            @mpf.mpf_le(delta, loose) {
            return @libelefun.mpf_exp(est, self.precision(), self.round_mode())
          }
          if @mpf.mpf_le(abs_term, tol_abs) && @mpf.mpf_le(delta, loose) {
            return @libelefun.mpf_exp(est, self.precision(), self.round_mode())
          }
        } else if @mpf.is_zero(log_tk) {
          return @libelefun.mpf_exp(slog, self.precision(), self.round_mode())
        }
      }
      if partials.length() >= 3 {
        let ps = p2_tail_window(partials, 18)
        let ts = p2_tail_window(terms, 18)
        let start_idx = start + partials.length() - ps.length()
        let (est, err) = self.p2_series_estimate(ps, ts, start_idx, algo, p)
        let delta = @mpf.mpf_abs(
          @mpf.mpf_sub(est, slog, p, @mpf.round_nearest),
          p,
          @mpf.round_nearest,
        )
        if @mpf.is_finite(err) &&
          @mpf.mpf_le(err, loose) &&
          @mpf.mpf_le(delta, loose) {
          return @libelefun.mpf_exp(est, self.precision(), self.round_mode())
        }
        if @mpf.is_finite(est) && @mpf.mpf_le(last_abs_term, tail_gate) {
          return @libelefun.mpf_exp(est, self.precision(), self.round_mode())
        }
      }
      if @mpf.is_finite(slog) && @mpf.mpf_le(last_abs_term, tail_gate) {
        return @libelefun.mpf_exp(slog, self.precision(), self.round_mode())
      }
      raise MPError::ConvergenceError("nprod: product did not converge")
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
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  n? : Int = 1,
  direction? : Int = 0,
  algo? : String = "step",
) -> @mpf.RawMpf raise MPError {
  if n < 0 {
    raise MPError::ValueError("diff: n must be non-negative")
  }
  let algo_key = algo.to_lower()
  match algo_key {
    "step" => ()
    "quad" => ()
    _ => raise MPError::ValueError("diff: unknown method '\{algo}'")
  }
  if n == 0 {
    return f(x)
  }
  let p = if algo_key == "quad" {
    self.p2_work_prec() + 12
  } else {
    self.p2_work_prec()
  }
  if n == 1 {
    return self.p2_diff_first(f, x, direction, p)
  }
  if direction != 0 {
    raise MPError::ValueError(
      "diff: direction is supported only for first derivative",
    )
  }
  if n == 2 {
    return self.p2_diff_second(f, x, p)
  }
  self.p2_diff_central_n(f, x, n, p)
}

///|
/// Return derivatives `[f(x), f'(x), ..., f^(n)(x)]`.
///
/// This mirrors mpmath `diffs` for unary real functions.
pub fn MPContext::diffs(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  n? : Int = 1,
  algo? : String = "step",
) -> Array[@mpf.RawMpf] raise MPError {
  if n < 0 {
    raise MPError::ValueError("diffs: n must be non-negative")
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
/// Runtime derivative errors are mapped to `nan`, matching the permissive
/// high-level behavior expected by mpmath-compatible helper paths.
pub fn MPContext::diffun(
  self : MPContext,
  f : UnaryMpfFn,
  n? : Int = 1,
  algo? : String = "step",
) -> UnaryMpfFn {
  (x : @mpf.RawMpf) => self.diff(f, x, n~, algo~) catch { _ => @mpf.fnan }
}

///|
/// Return Taylor coefficients `[a0, ..., an]` around `x`, where
/// `a_k = f^(k)(x) / k!`.
pub fn MPContext::taylor(
  self : MPContext,
  f : UnaryMpfFn,
  x : @mpf.RawMpf,
  n : Int,
  algo? : String = "step",
) -> Array[@mpf.RawMpf] raise MPError {
  if n < 0 {
    raise MPError::ValueError("taylor: n must be non-negative")
  }
  let p = self.p2_work_prec() + 12
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
      p2_mpf_div(dk, fact, p, @mpf.round_nearest)
    }
    out.push(@mpf.mpf_pos(ck, self.precision(), self.round_mode()))
  }
  out
}

///|
fn MPContext::p2_diff_partial3_apply(
  self : MPContext,
  f : TernaryMpfFn,
  xyz : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf),
  orders : (Int, Int, Int),
  algo : String,
) -> @mpf.RawMpf raise MPError {
  let (x, y, z) = xyz
  let (nx, ny, nz) = orders
  if nx < 0 || ny < 0 || nz < 0 {
    raise MPError::ValueError(
      "diff_partial3: derivative orders must be non-negative",
    )
  }
  if nx == 0 && ny == 0 && nz == 0 {
    let v = f(x, y, z)
    p2_assert_finite("diff_partial3", v)
    return v
  }
  let algo_key = algo.to_lower()
  match algo_key {
    "step" => ()
    "quad" => ()
    _ => raise MPError::ValueError("diff_partial3: unknown method '\{algo}'")
  }
  let p = if algo_key == "quad" {
    self.p2_work_prec() + 12
  } else {
    self.p2_work_prec()
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
  let hx = if nx == 0 { @mpf.fone } else { self.p2_diff_step(x, nx, step_prec) }
  let hy = if ny == 0 { @mpf.fone } else { self.p2_diff_step(y, ny, step_prec) }
  let hz = if nz == 0 { @mpf.fone } else { self.p2_diff_step(z, nz, step_prec) }
  let mut sum1 = @mpf.fzero
  let half_hx = if nx == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hx, 2, p, @mpf.round_nearest)
  }
  let half_hy = if ny == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hy, 2, p, @mpf.round_nearest)
  }
  let half_hz = if nz == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hz, 2, p, @mpf.round_nearest)
  }
  for i in 0..<=nx {
    let ci = p2_binom(nx, i)
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
      let cj = p2_binom(ny, j)
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
        let ck = p2_binom(nz, k)
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
        p2_assert_finite("diff_partial3", fv)
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
      p2_mpf_pow_int(hx, nx, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if ny > 0 {
    den1 = @mpf.mpf_mul(
      den1,
      p2_mpf_pow_int(hy, ny, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if nz > 0 {
    den1 = @mpf.mpf_mul(
      den1,
      p2_mpf_pow_int(hz, nz, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let d1 = p2_mpf_div(sum1, den1, p, self.round_mode())
  let hx2 = if nx == 0 {
    hx
  } else {
    p2_mpf_div_int(hx, 2, p, @mpf.round_nearest)
  }
  let hy2 = if ny == 0 {
    hy
  } else {
    p2_mpf_div_int(hy, 2, p, @mpf.round_nearest)
  }
  let hz2 = if nz == 0 {
    hz
  } else {
    p2_mpf_div_int(hz, 2, p, @mpf.round_nearest)
  }
  if nx + ny + nz <= 1 {
    return d1
  }
  let mut sum2 = @mpf.fzero
  let half_hx2 = if nx == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hx2, 2, p, @mpf.round_nearest)
  }
  let half_hy2 = if ny == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hy2, 2, p, @mpf.round_nearest)
  }
  let half_hz2 = if nz == 0 {
    @mpf.fzero
  } else {
    p2_mpf_div_int(hz2, 2, p, @mpf.round_nearest)
  }
  for i in 0..<=nx {
    let ci = p2_binom(nx, i)
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
      let cj = p2_binom(ny, j)
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
        let ck = p2_binom(nz, k)
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
        p2_assert_finite("diff_partial3", fv)
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
      p2_mpf_pow_int(hx2, nx, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if ny > 0 {
    den2 = @mpf.mpf_mul(
      den2,
      p2_mpf_pow_int(hy2, ny, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  if nz > 0 {
    den2 = @mpf.mpf_mul(
      den2,
      p2_mpf_pow_int(hz2, nz, p, @mpf.round_nearest),
      p,
      @mpf.round_nearest,
    )
  }
  let d2 = p2_mpf_div(sum2, den2, p, self.round_mode())
  let correction = p2_mpf_div_int(
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
  f : TernaryMpfFn,
  xyz : (@mpf.RawMpf, @mpf.RawMpf, @mpf.RawMpf),
  orders : (Int, Int, Int),
  algo? : String = "step",
) -> @mpf.RawMpf raise MPError {
  let (x, y, z) = xyz
  p2_assert_finite("diff_partial3", x)
  p2_assert_finite("diff_partial3", y)
  p2_assert_finite("diff_partial3", z)
  let v = self.p2_diff_partial3_apply(f, xyz, orders, algo)
  @mpf.mpf_pos(v, self.precision(), self.round_mode())
}

///|
fn MPContext::p2_findroot_secant(
  self : MPContext,
  f : UnaryMpfFn,
  x_prev0 : @mpf.RawMpf,
  x0 : @mpf.RawMpf,
  tol : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let mut x_prev = x_prev0
  let mut x = x0
  let mut y_prev = f(x_prev)
  let mut y = f(x)
  p2_assert_finite("findroot", y_prev)
  p2_assert_finite("findroot", y)
  if p2_is_small(y_prev, tol, prec) {
    return @mpf.mpf_pos(x_prev, self.precision(), self.round_mode())
  }
  if p2_is_small(y, tol, prec) {
    return @mpf.mpf_pos(x, self.precision(), self.round_mode())
  }
  for _ in 0..<max_steps {
    let denom = @mpf.mpf_sub(y, y_prev, prec, @mpf.round_nearest)
    if @mpf.is_zero(denom) {
      raise MPError::ConvergenceError(
        "findroot: zero slope in secant iteration",
      )
    }
    let step = p2_mpf_div(
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
    if p2_is_small(@mpf.mpf_sub(x_next, x, prec, @mpf.round_nearest), tol, prec) {
      return @mpf.mpf_pos(x_next, self.precision(), self.round_mode())
    }
    x_prev = x
    y_prev = y
    x = x_next
    y = f(x)
    p2_assert_finite("findroot", y)
    if p2_is_small(y, tol, prec) {
      return @mpf.mpf_pos(x, self.precision(), self.round_mode())
    }
  }
  raise MPError::ConvergenceError("findroot: secant did not converge")
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
  f : UnaryMpfFn,
  x0 : @mpf.RawMpf,
  x1? : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 80,
  solver? : String = "auto",
) -> @mpf.RawMpf raise MPError {
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p2_default_tol()
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let key = solver.to_lower()
  if key == "bisect" || key == "bisection" {
    return match x1 {
      Some(x_start) =>
        self.findroot_interval(f, x0, x_start, tol=tol_abs, max_steps=steps)
      None =>
        raise MPError::ValueError(
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
    _ => raise MPError::ValueError("findroot: unknown solver '\{solver}'")
  }
  if use_secant {
    return match x1 {
      Some(x_start) =>
        self.p2_findroot_secant(f, x0, x_start, tol_abs, steps, p)
      None => {
        let h = self.p2_diff_step(x0, 1, p)
        self.p2_findroot_secant(
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
    p2_assert_finite("findroot", y)
    if p2_is_small(y, tol_abs, p) {
      return @mpf.mpf_pos(x, self.precision(), self.round_mode())
    }
    let dy = self.p2_diff_first(f, x, 0, p)
    if @mpf.is_zero(dy) {
      let h = self.p2_diff_step(x, 1, p)
      return self.p2_findroot_secant(
        f,
        x,
        @mpf.mpf_add(x, h, p, @mpf.round_nearest),
        tol_abs,
        steps,
        p,
      )
    }
    let step = p2_mpf_div(y, dy, p, @mpf.round_nearest)
    let x_next = @mpf.mpf_sub(x, step, p, @mpf.round_nearest)
    if p2_is_small(@mpf.mpf_sub(x_next, x, p, @mpf.round_nearest), tol_abs, p) {
      return @mpf.mpf_pos(x_next, self.precision(), self.round_mode())
    }
    x = x_next
  }
  raise MPError::ConvergenceError("findroot: Newton iteration did not converge")
}

///|
/// Bracketed root finder on a real interval using bisection.
///
/// Requires opposite signs at interval endpoints (or an endpoint root).
/// This corresponds to mpmath `findroot(..., solver='bisect')` subset.
pub fn MPContext::findroot_interval(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 120,
) -> @mpf.RawMpf raise MPError {
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p2_default_tol()
  }
  if !@mpf.is_finite(a) || !@mpf.is_finite(b) {
    raise MPError::ValueError(
      "findroot_interval: interval endpoints must be finite",
    )
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
  p2_assert_finite("findroot_interval", f_lo)
  p2_assert_finite("findroot_interval", f_hi)
  if p2_is_small(f_lo, tol_abs, p) {
    return @mpf.mpf_pos(lo, self.precision(), self.round_mode())
  }
  if p2_is_small(f_hi, tol_abs, p) {
    return @mpf.mpf_pos(hi, self.precision(), self.round_mode())
  }
  let mut s_lo = @mpf.mpf_sign(f_lo)
  let s_hi = @mpf.mpf_sign(f_hi)
  if s_lo == s_hi {
    raise MPError::ValueError(
      "findroot_interval: interval does not bracket a root",
    )
  }
  for _ in 0..<steps {
    let mid = p2_mpf_div_int(
      @mpf.mpf_add(lo, hi, p, @mpf.round_nearest),
      2,
      p,
      @mpf.round_nearest,
    )
    let f_mid = f(mid)
    p2_assert_finite("findroot_interval", f_mid)
    if p2_is_small(f_mid, tol_abs, p) ||
      p2_is_small(@mpf.mpf_sub(hi, lo, p, @mpf.round_nearest), tol_abs, p) {
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
  raise MPError::ConvergenceError(
    "findroot_interval: bisection did not converge",
  )
}

///|
fn MPContext::p2_eval_system2(
  self : MPContext,
  f : System2Fn,
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  ignore(self)
  let (f1, f2) = f(x, y)
  p2_assert_finite("findroot2", f1)
  p2_assert_finite("findroot2", f2)
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
  f : System2Fn,
  x0 : @mpf.RawMpf,
  y0 : @mpf.RawMpf,
  tol? : @mpf.RawMpf,
  max_steps? : Int = 80,
) -> (@mpf.RawMpf, @mpf.RawMpf) raise MPError {
  let p = self.p2_work_prec()
  let tol_abs = match tol {
    Some(v) => @mpf.mpf_abs(v, p, @mpf.round_nearest)
    None => self.p2_default_tol()
  }
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut x = x0
  let mut y = y0
  for _ in 0..<steps {
    let (f1, f2) = self.p2_eval_system2(f, x, y)
    if @mpf.mpf_le(p2_abs_max2(f1, f2, p), tol_abs) {
      return (
        @mpf.mpf_pos(x, self.precision(), self.round_mode()),
        @mpf.mpf_pos(y, self.precision(), self.round_mode()),
      )
    }
    let hx = self.p2_diff_step(x, 1, p)
    let hy = self.p2_diff_step(y, 1, p)
    let xp = @mpf.mpf_add(x, hx, p, @mpf.round_nearest)
    let xm = @mpf.mpf_sub(x, hx, p, @mpf.round_nearest)
    let yp = @mpf.mpf_add(y, hy, p, @mpf.round_nearest)
    let ym = @mpf.mpf_sub(y, hy, p, @mpf.round_nearest)
    let (f1_xp, f2_xp) = self.p2_eval_system2(f, xp, y)
    let (f1_xm, f2_xm) = self.p2_eval_system2(f, xm, y)
    let (f1_yp, f2_yp) = self.p2_eval_system2(f, x, yp)
    let (f1_ym, f2_ym) = self.p2_eval_system2(f, x, ym)
    let two_hx = @mpf.mpf_mul_int(hx, 2, p, @mpf.round_nearest)
    let two_hy = @mpf.mpf_mul_int(hy, 2, p, @mpf.round_nearest)
    let j11 = p2_mpf_div(
      @mpf.mpf_sub(f1_xp, f1_xm, p, @mpf.round_nearest),
      two_hx,
      p,
      @mpf.round_nearest,
    )
    let j21 = p2_mpf_div(
      @mpf.mpf_sub(f2_xp, f2_xm, p, @mpf.round_nearest),
      two_hx,
      p,
      @mpf.round_nearest,
    )
    let j12 = p2_mpf_div(
      @mpf.mpf_sub(f1_yp, f1_ym, p, @mpf.round_nearest),
      two_hy,
      p,
      @mpf.round_nearest,
    )
    let j22 = p2_mpf_div(
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
      raise MPError::ConvergenceError("findroot2: singular Jacobian")
    }
    let dx = p2_mpf_div(
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
    let dy = p2_mpf_div(
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
        p2_abs_max2(
          @mpf.mpf_sub(x_next, x, p, @mpf.round_nearest),
          @mpf.mpf_sub(y_next, y, p, @mpf.round_nearest),
          p,
        ),
        tol_abs,
      ) {
      let (g1, g2) = self.p2_eval_system2(f, x_next, y_next)
      if @mpf.mpf_le(p2_abs_max2(g1, g2, p), tol_abs) {
        return (
          @mpf.mpf_pos(x_next, self.precision(), self.round_mode()),
          @mpf.mpf_pos(y_next, self.precision(), self.round_mode()),
        )
      }
    }
    x = x_next
    y = y_next
  }
  raise MPError::ConvergenceError(
    "findroot2: Newton iteration did not converge",
  )
}

///|
fn MPContext::p2_quad_tol(self : MPContext, prec : Int) -> @mpf.RawMpf {
  ignore(self)
  let shift = if prec > 200 { -28 } else if prec > 120 { -24 } else { -20 }
  @mpf.from_man_exp(1N, shift, 0, @mpf.round_down)
}

///|
fn p2_quad_steps(max_steps : Int, max_degree : Int?) -> Int {
  let base = if max_steps < 1 { 1 } else { max_steps }
  match max_degree {
    Some(d) => if d > 0 { d } else { base }
    None => base
  }
}

///|
fn p2_is_pos_inf(x : @mpf.RawMpf) -> Bool {
  @mpf.is_inf(x) && x.sign == 0
}

///|
fn p2_is_neg_inf(x : @mpf.RawMpf) -> Bool {
  @mpf.is_inf(x) && x.sign == 1
}

///|
fn MPContext::p2_quad_simpson(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let h = p2_mpf_div_int(
    @mpf.mpf_sub(b, a, prec, @mpf.round_nearest),
    n,
    prec,
    @mpf.round_nearest,
  )
  let fa = f(a)
  let fb = f(b)
  p2_assert_finite("quad", fa)
  p2_assert_finite("quad", fb)
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
    p2_assert_finite("quad", yi)
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
    p2_mpf_div_int(h, 3, prec, @mpf.round_nearest),
    weighted,
    prec,
    self.round_mode(),
  )
}

///|
fn MPContext::p2_quad_midpoint(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  n : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let h = p2_mpf_div_int(
    @mpf.mpf_sub(b, a, prec, @mpf.round_nearest),
    n,
    prec,
    @mpf.round_nearest,
  )
  let half_h = p2_mpf_div_int(h, 2, prec, @mpf.round_nearest)
  let mut sum = @mpf.fzero
  for i in 0..<n {
    let xi = @mpf.mpf_add(
      @mpf.mpf_add(a, half_h, prec, @mpf.round_nearest),
      @mpf.mpf_mul_int(h, i, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    )
    let yi = f(xi)
    p2_assert_finite("quad", yi)
    sum = @mpf.mpf_add(sum, yi, prec, @mpf.round_nearest)
  }
  @mpf.mpf_mul(h, sum, prec, self.round_mode())
}

///|
fn MPContext::p2_quad_midpoint_adaptive(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let tol = self.p2_quad_tol(prec)
  let steps = if max_steps < 1 { 1 } else { max_steps }
  let mut n = 8
  let mut prev = self.p2_quad_midpoint(f, a, b, n, prec)
  for _ in 0..<steps {
    n = n * 2
    let cur = self.p2_quad_midpoint(f, a, b, n, prec)
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
fn MPContext::p2_quad_to_pos_inf(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let g = (u : @mpf.RawMpf) => {
    let one_minus_u = @mpf.mpf_sub(@mpf.fone, u, prec, @mpf.round_nearest)
    let t = @mpf.mpf_div(u, one_minus_u, prec, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    let x = @mpf.mpf_add(a, t, prec, @mpf.round_nearest)
    let den2 = @mpf.mpf_mul(one_minus_u, one_minus_u, prec, @mpf.round_nearest)
    let jac = @mpf.mpf_div(@mpf.fone, den2, prec, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.p2_quad_midpoint_adaptive(g, @mpf.fzero, @mpf.fone, max_steps, prec)
}

///|
fn MPContext::p2_quad_from_neg_inf(
  self : MPContext,
  f : UnaryMpfFn,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let g = (u : @mpf.RawMpf) => {
    let one_minus_u = @mpf.mpf_sub(@mpf.fone, u, prec, @mpf.round_nearest)
    let t = @mpf.mpf_div(u, one_minus_u, prec, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    let x = @mpf.mpf_sub(b, t, prec, @mpf.round_nearest)
    let den2 = @mpf.mpf_mul(one_minus_u, one_minus_u, prec, @mpf.round_nearest)
    let jac = @mpf.mpf_div(@mpf.fone, den2, prec, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.p2_quad_midpoint_adaptive(g, @mpf.fzero, @mpf.fone, max_steps, prec)
}

///|
fn MPContext::p2_quad_whole_line(
  self : MPContext,
  f : UnaryMpfFn,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  let g = (t : @mpf.RawMpf) => {
    let t2 = @mpf.mpf_mul(t, t, prec, @mpf.round_nearest)
    let den = @mpf.mpf_sub(@mpf.fone, t2, prec, @mpf.round_nearest)
    let x = @mpf.mpf_div(t, den, prec, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    let jac = @mpf.mpf_div(
      @mpf.mpf_add(@mpf.fone, t2, prec, @mpf.round_nearest),
      @mpf.mpf_mul(den, den, prec, @mpf.round_nearest),
      prec,
      @mpf.round_nearest,
    ) catch {
      _ => @mpf.fnan
    }
    @mpf.mpf_mul(f(x), jac, prec, @mpf.round_nearest)
  }
  self.p2_quad_midpoint_adaptive(g, @mpf.fnone, @mpf.fone, max_steps, prec)
}

///|
fn MPContext::p2_quad_segment(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps : Int,
  prec : Int,
) -> @mpf.RawMpf raise MPError {
  if @mpf.mpf_eq(a, b) {
    return @mpf.fzero
  }
  if @mpf.mpf_gt(a, b) {
    return @mpf.mpf_neg(
      self.p2_quad_segment(f, b, a, max_steps, prec),
      self.precision(),
      self.round_mode(),
    )
  }
  if @mpf.is_finite(a) && @mpf.is_finite(b) {
    let tol = self.p2_quad_tol(prec)
    let mut n = 2
    let mut prev = self.p2_quad_simpson(f, a, b, n, prec)
    for _ in 0..<max_steps {
      n = n * 2
      let cur = self.p2_quad_simpson(f, a, b, n, prec)
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
  if @mpf.is_finite(a) && p2_is_pos_inf(b) {
    return self.p2_quad_to_pos_inf(f, a, max_steps, prec)
  }
  if p2_is_neg_inf(a) && @mpf.is_finite(b) {
    return self.p2_quad_from_neg_inf(f, b, max_steps, prec)
  }
  if p2_is_neg_inf(a) && p2_is_pos_inf(b) {
    return self.p2_quad_whole_line(f, max_steps, prec)
  }
  raise MPError::ValueError("quad: unsupported infinite interval endpoints")
}

///|
/// One-dimensional numerical integration (tanh-sinh-style entrypoint).
///
/// Current implementation supports finite and infinite endpoints via variable
/// transformations; API shape matches mpmath `quadts` subset.
pub fn MPContext::quadts(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise MPError {
  let steps = p2_quad_steps(max_steps, max_degree)
  self.p2_quad_segment(f, a, b, steps, self.p2_work_prec())
}

///|
/// One-dimensional numerical integration (Gauss-Legendre-style entrypoint).
///
/// This currently shares the same adaptive core as `quadts`, providing mpmath
/// API compatibility for the migrated subset.
pub fn MPContext::quadgl(
  self : MPContext,
  f : UnaryMpfFn,
  a : @mpf.RawMpf,
  b : @mpf.RawMpf,
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise MPError {
  let steps = p2_quad_steps(max_steps, max_degree)
  self.p2_quad_segment(f, a, b, steps, self.p2_work_prec())
}

///|
/// Piecewise one-dimensional numerical integration over multiple breakpoints.
///
/// `points=[x0, x1, ..., xn]` integrates each adjacent segment and sums the
/// results. Supports finite and selected infinite endpoint combinations.
pub fn MPContext::quad(
  self : MPContext,
  f : UnaryMpfFn,
  points : ArrayView[@mpf.RawMpf],
  max_steps? : Int = 12,
  max_degree? : Int,
) -> @mpf.RawMpf raise MPError {
  if points.length() < 2 {
    raise MPError::ValueError("quad: at least two interval points are required")
  }
  let p = self.p2_work_prec()
  let steps = p2_quad_steps(max_steps, max_degree)
  let mut s = @mpf.fzero
  for i in 0..<(points.length() - 1) {
    s = @mpf.mpf_add(
      s,
      self.p2_quad_segment(f, points[i], points[i + 1], steps, p),
      p,
      @mpf.round_nearest,
    )
  }
  @mpf.mpf_pos(s, self.precision(), self.round_mode())
}
