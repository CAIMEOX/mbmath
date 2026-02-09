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
) -> Bool {
  let left = @mpf.mpf_sub(lo, offset, wp, @mpf.round_floor)
  let right = @mpf.mpf_sub(hi, offset, wp, @mpf.round_ceiling)
  let ql = @mpf.mpf_div(left, period, wp, @mpf.round_floor)
  let qh = @mpf.mpf_div(right, period, wp, @mpf.round_ceiling)
  let k_min = @mpf.mpf_ceil(ql, 0, @mpf.round_nearest)
  let k_max = @mpf.mpf_floor(qh, 0, @mpf.round_nearest)
  @mpf.mpf_le(k_min, k_max)
}

///|
pub fn mpi_cos_sin(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) {
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
  let ca = @libelefun.mpf_cos(s.lo, wp, @mpf.round_nearest)
  let cb = @libelefun.mpf_cos(s.hi, wp, @mpf.round_nearest)
  let sa = @libelefun.mpf_sin(s.lo, wp, @mpf.round_nearest)
  let sb = @libelefun.mpf_sin(s.hi, wp, @mpf.round_nearest)
  let (c_lo0, c_hi0) = @mpf.mpf_min_max([ca, cb])
  let (s_lo0, s_hi0) = @mpf.mpf_min_max([sa, sb])
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
  let cos_iv = {
    lo: @mpf.mpf_pos(c_lo, out_prec, @mpf.round_floor),
    hi: @mpf.mpf_pos(c_hi, out_prec, @mpf.round_ceiling),
  }
  let sin_iv = {
    lo: @mpf.mpf_pos(s_lo, out_prec, @mpf.round_floor),
    hi: @mpf.mpf_pos(s_hi, out_prec, @mpf.round_ceiling),
  }
  (cos_iv, sin_iv)
}

///|
pub fn mpi_cos(s : RawMpi, prec : Int) -> RawMpi {
  mpi_cos_sin(s, prec).0
}

///|
pub fn mpi_sin(s : RawMpi, prec : Int) -> RawMpi {
  mpi_cos_sin(s, prec).1
}

///|
pub fn mpi_tan(s : RawMpi, prec : Int) -> RawMpi {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = mpi_cos_sin(s, wp)
  mpi_div(si, c, if prec > 0 { prec } else { wp })
}

///|
pub fn mpi_cot(s : RawMpi, prec : Int) -> RawMpi {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let (c, si) = mpi_cos_sin(s, wp)
  mpi_div(c, si, if prec > 0 { prec } else { wp })
}
