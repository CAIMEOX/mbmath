///|
fn unit_interval() -> RawMpi {
  { lo: @mpf.RawMpf::negative_one(), hi: @mpf.RawMpf::one() }
}

///|
fn interval_contains_periodic_point(
  lo : @mpf.RawMpf,
  hi : @mpf.RawMpf,
  offset : @mpf.RawMpf,
  period : @mpf.RawMpf,
  wp : Int,
) -> Bool raise MpiError {
  let left = lo.sub(offset, wp, Floor)
  let right = hi.sub(offset, wp, Ceiling)
  let ql = left.div(period, wp, Floor) catch {
    err => raise from_mpf_error(err)
  }
  let qh = right.div(period, wp, Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  let k_min = ql.ceil(0, Nearest)
  let k_max = qh.floor(0, Nearest)
  k_min <= k_max
}

///|
fn inflate_trig_endpoint(
  v : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  more : @mpf.RawMpf,
  less : @mpf.RawMpf,
) -> @mpf.RawMpf {
  let use_more = (v.sign == 1) == (rnd == Floor)
  let p = if use_more { more } else { less }
  let out = v.mul(p, prec, rnd)
  if out > @mpf.RawMpf::one() {
    @mpf.RawMpf::one()
  } else if out < @mpf.RawMpf::negative_one() {
    @mpf.RawMpf::negative_one()
  } else {
    out
  }
}

///|
pub fn RawMpi::cos_sin(
  s : RawMpi,
  prec : Int,
) -> (RawMpi, RawMpi) raise MpiError {
  if s.lo.is_zero() && s.hi.is_zero() {
    return (RawMpi::one(), RawMpi::zero())
  }
  if !s.lo.is_finite() || !s.hi.is_finite() {
    let u = unit_interval()
    return (u, u)
  }
  let wp = if prec > 0 { prec + 32 } else { 96 }
  let out_prec = if prec > 0 { prec } else { wp }
  let pi = elefun_pi_checked(wp, Nearest)
  let half_pi = pi.scale_pow2(-1)
  let neg_half_pi = half_pi.negated(0, Down)
  let two_pi = pi.mul_int(2, wp, Nearest)
  let width = s.width(wp)
  if !width.is_finite() || width >= two_pi {
    let u = unit_interval()
    return (u, u)
  }
  // Evaluate endpoints with directional rounding to preserve enclosure.
  let ca_lo = elefun_cos_checked(s.lo, wp, Floor)
  let ca_hi = elefun_cos_checked(s.lo, wp, Ceiling)
  let cb_lo = elefun_cos_checked(s.hi, wp, Floor)
  let cb_hi = elefun_cos_checked(s.hi, wp, Ceiling)
  let sa_lo = elefun_sin_checked(s.lo, wp, Floor)
  let sa_hi = elefun_sin_checked(s.lo, wp, Ceiling)
  let sb_lo = elefun_sin_checked(s.hi, wp, Floor)
  let sb_hi = elefun_sin_checked(s.hi, wp, Ceiling)
  let (c_lo0, _) = @mpf.RawMpf::min_max([ca_lo, cb_lo]) catch {
    err => raise from_mpf_error(err)
  }
  let (_, c_hi0) = @mpf.RawMpf::min_max([ca_hi, cb_hi]) catch {
    err => raise from_mpf_error(err)
  }
  let (s_lo0, _) = @mpf.RawMpf::min_max([sa_lo, sb_lo]) catch {
    err => raise from_mpf_error(err)
  }
  let (_, s_hi0) = @mpf.RawMpf::min_max([sa_hi, sb_hi]) catch {
    err => raise from_mpf_error(err)
  }
  let mut c_lo = c_lo0
  let mut c_hi = c_hi0
  let mut s_lo = s_lo0
  let mut s_hi = s_hi0
  if interval_contains_periodic_point(
      s.lo,
      s.hi,
      @mpf.RawMpf::zero(),
      two_pi,
      wp,
    ) {
    c_hi = @mpf.RawMpf::one()
  }
  if interval_contains_periodic_point(s.lo, s.hi, pi, two_pi, wp) {
    c_lo = @mpf.RawMpf::negative_one()
  }
  if interval_contains_periodic_point(s.lo, s.hi, half_pi, two_pi, wp) {
    s_hi = @mpf.RawMpf::one()
  }
  if interval_contains_periodic_point(s.lo, s.hi, neg_half_pi, two_pi, wp) {
    s_lo = @mpf.RawMpf::negative_one()
  }
  let more = @mpf.RawMpf::from_mantissa_exponent(
    (1N << wp) + (1N << 10),
    -wp,
    0,
    Down,
  )
  let less = @mpf.RawMpf::from_mantissa_exponent(
    (1N << wp) - (1N << 10),
    -wp,
    0,
    Down,
  )
  let cos_iv = {
    lo: inflate_trig_endpoint(c_lo, out_prec, Floor, more, less),
    hi: inflate_trig_endpoint(c_hi, out_prec, Ceiling, more, less),
  }
  let sin_iv = {
    lo: inflate_trig_endpoint(s_lo, out_prec, Floor, more, less),
    hi: inflate_trig_endpoint(s_hi, out_prec, Ceiling, more, less),
  }
  (cos_iv, sin_iv)
}

///|
pub fn RawMpi::cos(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  s.cos_sin(prec).0
}

///|
pub fn RawMpi::sin(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  s.cos_sin(prec).1
}

///|
pub fn RawMpi::tan(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = s.cos_sin(wp)
  si.div(c, if prec > 0 { prec } else { wp })
}

///|
pub fn RawMpi::cot(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = s.cos_sin(wp)
  c.div(si, if prec > 0 { prec } else { wp })
}
