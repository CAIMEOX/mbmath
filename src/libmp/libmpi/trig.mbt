///|
fn unit_interval() -> RawMpi {
  { lo: @mpf.fnone, hi: @mpf.fone }
}

///|
fn interval_contains_periodic_point(
  lo : @mpf.RawMpf,
  hi : @mpf.RawMpf,
  offset : @mpf.RawMpf,
  period : @mpf.RawMpf,
  wp : Int,
) -> Bool raise MpiError {
  let left = @mpf.mpf_sub(lo, offset, wp, @mpf.round_floor)
  let right = @mpf.mpf_sub(hi, offset, wp, @mpf.round_ceiling)
  let ql = @mpf.mpf_div(left, period, wp, @mpf.round_floor) catch {
    err => raise from_mpf_error(err)
  }
  let qh = @mpf.mpf_div(right, period, wp, @mpf.round_ceiling) catch {
    err => raise from_mpf_error(err)
  }
  let k_min = @mpf.mpf_ceil(ql, 0, @mpf.round_nearest)
  let k_max = @mpf.mpf_floor(qh, 0, @mpf.round_nearest)
  @mpf.mpf_le(k_min, k_max)
}

///|
fn inflate_trig_endpoint(
  v : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
  more : @mpf.RawMpf,
  less : @mpf.RawMpf,
) -> @mpf.RawMpf {
  let use_more = (v.sign == 1) == (rnd == @mpf.round_floor)
  let p = if use_more { more } else { less }
  let out = @mpf.mpf_mul(v, p, prec, rnd)
  if @mpf.mpf_gt(out, @mpf.fone) {
    @mpf.fone
  } else if @mpf.mpf_lt(out, @mpf.fnone) {
    @mpf.fnone
  } else {
    out
  }
}

///|
pub fn mpi_cos_sin(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) raise MpiError {
  if @mpf.is_zero(s.lo) && @mpf.is_zero(s.hi) {
    return (mpi_one, mpi_zero)
  }
  if !@mpf.is_finite(s.lo) || !@mpf.is_finite(s.hi) {
    let u = unit_interval()
    return (u, u)
  }
  let wp = if prec > 0 { prec + 32 } else { 96 }
  let out_prec = if prec > 0 { prec } else { wp }
  let pi = @libelefun.mpf_pi(wp, @mpf.round_nearest)
  let half_pi = @mpf.mpf_shift(pi, -1)
  let neg_half_pi = @mpf.mpf_neg(half_pi, 0, @mpf.round_down)
  let two_pi = @mpf.mpf_mul_int(pi, 2, wp, @mpf.round_nearest)
  let width = mpi_delta(s, wp)
  if !@mpf.is_finite(width) || @mpf.mpf_ge(width, two_pi) {
    let u = unit_interval()
    return (u, u)
  }
  // Evaluate endpoints with directional rounding to preserve enclosure.
  let ca_lo = @libelefun.mpf_cos(s.lo, wp, @mpf.round_floor)
  let ca_hi = @libelefun.mpf_cos(s.lo, wp, @mpf.round_ceiling)
  let cb_lo = @libelefun.mpf_cos(s.hi, wp, @mpf.round_floor)
  let cb_hi = @libelefun.mpf_cos(s.hi, wp, @mpf.round_ceiling)
  let sa_lo = @libelefun.mpf_sin(s.lo, wp, @mpf.round_floor)
  let sa_hi = @libelefun.mpf_sin(s.lo, wp, @mpf.round_ceiling)
  let sb_lo = @libelefun.mpf_sin(s.hi, wp, @mpf.round_floor)
  let sb_hi = @libelefun.mpf_sin(s.hi, wp, @mpf.round_ceiling)
  let (c_lo0, _) = @mpf.mpf_min_max([ca_lo, cb_lo]) catch {
    err => raise from_mpf_error(err)
  }
  let (_, c_hi0) = @mpf.mpf_min_max([ca_hi, cb_hi]) catch {
    err => raise from_mpf_error(err)
  }
  let (s_lo0, _) = @mpf.mpf_min_max([sa_lo, sb_lo]) catch {
    err => raise from_mpf_error(err)
  }
  let (_, s_hi0) = @mpf.mpf_min_max([sa_hi, sb_hi]) catch {
    err => raise from_mpf_error(err)
  }
  let mut c_lo = c_lo0
  let mut c_hi = c_hi0
  let mut s_lo = s_lo0
  let mut s_hi = s_hi0
  if interval_contains_periodic_point(s.lo, s.hi, @mpf.fzero, two_pi, wp) {
    c_hi = @mpf.fone
  }
  if interval_contains_periodic_point(s.lo, s.hi, pi, two_pi, wp) {
    c_lo = @mpf.fnone
  }
  if interval_contains_periodic_point(s.lo, s.hi, half_pi, two_pi, wp) {
    s_hi = @mpf.fone
  }
  if interval_contains_periodic_point(s.lo, s.hi, neg_half_pi, two_pi, wp) {
    s_lo = @mpf.fnone
  }
  let more = @mpf.from_man_exp((1N << wp) + (1N << 10), -wp, 0, @mpf.round_down)
  let less = @mpf.from_man_exp((1N << wp) - (1N << 10), -wp, 0, @mpf.round_down)
  let cos_iv = {
    lo: inflate_trig_endpoint(c_lo, out_prec, @mpf.round_floor, more, less),
    hi: inflate_trig_endpoint(c_hi, out_prec, @mpf.round_ceiling, more, less),
  }
  let sin_iv = {
    lo: inflate_trig_endpoint(s_lo, out_prec, @mpf.round_floor, more, less),
    hi: inflate_trig_endpoint(s_hi, out_prec, @mpf.round_ceiling, more, less),
  }
  (cos_iv, sin_iv)
}

///|
pub fn mpi_cos(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_cos_sin(s, prec).0
}

///|
pub fn mpi_sin(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_cos_sin(s, prec).1
}

///|
pub fn mpi_tan(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = mpi_cos_sin(s, wp)
  mpi_div(si, c, if prec > 0 { prec } else { wp })
}

///|
pub fn mpi_cot(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = mpi_cos_sin(s, wp)
  mpi_div(c, si, if prec > 0 { prec } else { wp })
}
