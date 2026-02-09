///|
fn default_prec(prec : Int) -> Int {
  if prec > 0 {
    prec
  } else {
    80
  }
}

///|
fn work_prec(prec : Int) -> Int {
  if prec > 0 {
    prec + 20
  } else {
    96
  }
}

///|
pub fn mpi_shift(s : RawMpi, n : Int) -> RawMpi {
  { lo: @mpf.mpf_shift(s.lo, n), hi: @mpf.mpf_shift(s.hi, n) }
}

///|
pub fn mpi_cosh_sinh(s : RawMpi, prec : Int) -> (RawMpi, RawMpi) {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let e1 = mpi_exp(s, wp)
  let e2 = mpi_div(mpi_one, e1, wp)
  let c = mpi_shift(mpi_add(e1, e2, prec=out), -1)
  let sh = mpi_shift(mpi_sub(e1, e2, prec=out), -1)
  (c, sh)
}

///|
pub fn mpi_atan2(y : RawMpi, x : RawMpi, prec : Int) -> RawMpi {
  let p = default_prec(prec)
  let ya = y.lo
  let yb = y.hi
  let xa = x.lo
  let xb = x.hi
  if @mpf.is_zero(ya) && @mpf.is_zero(yb) {
    if @mpf.mpf_ge(xa, @mpf.fzero) {
      return mpi_zero
    }
    return mpi_pi(p)
  }
  if @mpf.mpf_ge(xa, @mpf.fzero) {
    let a = if @mpf.mpf_ge(ya, @mpf.fzero) {
      @libelefun.mpf_atan2(ya, xb, p, @mpf.round_floor)
    } else {
      @libelefun.mpf_atan2(ya, xa, p, @mpf.round_floor)
    }
    let b = if @mpf.mpf_ge(yb, @mpf.fzero) {
      @libelefun.mpf_atan2(yb, xa, p, @mpf.round_ceiling)
    } else {
      @libelefun.mpf_atan2(yb, xb, p, @mpf.round_ceiling)
    }
    return mpi_make(a, b)
  }
  if @mpf.mpf_ge(ya, @mpf.fzero) {
    let b = @libelefun.mpf_atan2(ya, xa, p, @mpf.round_ceiling)
    let a = if @mpf.mpf_le(xb, @mpf.fzero) {
      @libelefun.mpf_atan2(yb, xb, p, @mpf.round_floor)
    } else {
      @libelefun.mpf_atan2(ya, xb, p, @mpf.round_floor)
    }
    return mpi_make(a, b)
  }
  if @mpf.mpf_le(yb, @mpf.fzero) {
    let a = @libelefun.mpf_atan2(yb, xa, p, @mpf.round_floor)
    let b = if @mpf.mpf_le(xb, @mpf.fzero) {
      @libelefun.mpf_atan2(ya, xb, p, @mpf.round_ceiling)
    } else {
      @libelefun.mpf_atan2(yb, xb, p, @mpf.round_ceiling)
    }
    return mpi_make(a, b)
  }
  let b = @libelefun.mpf_pi(p, @mpf.round_ceiling)
  let a = @mpf.mpf_neg(b, 0, @mpf.round_down)
  mpi_make(a, b)
}

///|
pub fn mpci_exp(z : RawMpci, prec : Int) -> RawMpci {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let r = mpi_exp(z.real, wp)
  let (c, s) = mpi_cos_sin(z.imag, wp)
  { real: mpi_mul(r, c, prec=out), imag: mpi_mul(r, s, prec=out) }
}

///|
pub fn mpci_cos(z : RawMpci, prec : Int) -> RawMpci {
  let wp = if prec > 0 { prec + 10 } else { 90 }
  let out = default_prec(prec)
  let (c, s) = mpi_cos_sin(z.real, wp)
  let (ch, sh) = mpi_cosh_sinh(z.imag, wp)
  let re = mpi_mul(c, ch, prec=out)
  let im = mpi_mul(s, sh, prec=out)
  { real: re, imag: mpi_neg(im, prec=out) }
}

///|
pub fn mpci_sin(z : RawMpci, prec : Int) -> RawMpci {
  let wp = if prec > 0 { prec + 10 } else { 90 }
  let out = default_prec(prec)
  let (c, s) = mpi_cos_sin(z.real, wp)
  let (ch, sh) = mpi_cosh_sinh(z.imag, wp)
  { real: mpi_mul(s, ch, prec=out), imag: mpi_mul(c, sh, prec=out) }
}

///|
pub fn mpci_abs(z : RawMpci, prec : Int) -> RawMpi {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  if z.real == mpi_zero {
    return mpi_abs(z.imag, prec=out)
  }
  if z.imag == mpi_zero {
    return mpi_abs(z.real, prec=out)
  }
  let a = mpi_square(z.real, prec=wp)
  let b = mpi_square(z.imag, prec=wp)
  let t = mpi_add(a, b, prec=wp)
  mpi_sqrt(t, out)
}

///|
pub fn mpci_arg(z : RawMpci, prec : Int) -> RawMpi {
  mpi_atan2(z.imag, z.real, prec)
}

///|
pub fn mpci_log(z : RawMpci, prec : Int) -> RawMpci {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  { real: mpi_log(mpci_abs(z, wp), out), imag: mpci_arg(z, out) }
}

///|
pub fn mpci_square(z : RawMpci, prec : Int) -> RawMpci {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let re = mpi_sub(
    mpi_square(z.real, prec=wp),
    mpi_square(z.imag, prec=wp),
    prec=out,
  )
  let im = mpi_shift(mpi_mul(z.real, z.imag, prec=out), 1)
  { real: re, imag: im }
}

///|
pub fn mpci_pow_int(z : RawMpci, n : Int, prec : Int) -> RawMpci {
  let out = default_prec(prec)
  if n < 0 {
    return mpci_div(mpci_one, mpci_pow_int(z, -n, out + 20), out)
  }
  if n == 0 {
    return mpci_one
  }
  if n == 1 {
    return mpci_pos(z, out)
  }
  if n == 2 {
    return mpci_square(z, out)
  }
  let wp = out + 20
  let mut result = mpci_one
  let mut base = z
  let mut e = n
  while e > 0 {
    if (e & 1) == 1 {
      result = mpci_mul(result, base, wp)
    }
    e = e >> 1
    if e > 0 {
      base = mpci_square(base, wp)
    }
  }
  mpci_pos(result, out)
}

///|
pub fn mpci_pow(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  if w.imag == mpi_zero && @mpf.mpf_eq(w.real.lo, w.real.hi) {
    if @mpf.is_zero(w.real.lo) {
      return mpci_one
    }
    match maybe_integer(w.real.lo) {
      Some(n) => return mpci_pow_int(z, n, prec)
      None => ()
    }
  }
  let wp = work_prec(prec)
  let out = default_prec(prec)
  mpci_exp(mpci_mul(w, mpci_log(z, wp), wp), out)
}
