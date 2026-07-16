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
pub fn RawMpi::scale_pow2(s : RawMpi, n : Int) -> RawMpi {
  { lo: s.lo.scale_pow2(n), hi: s.hi.scale_pow2(n) }
}

///|
pub fn RawMpi::cosh_sinh(
  s : RawMpi,
  prec : Int,
) -> (RawMpi, RawMpi) raise MpiError {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let e1 = s.exp(wp)
  let e2 = RawMpi::one().div(e1, wp)
  let c = e1.add(e2, prec=out).scale_pow2(-1)
  let sh = e1.sub(e2, prec=out).scale_pow2(-1)
  (c, sh)
}

///|
pub fn RawMpi::atan2(
  y : RawMpi,
  x : RawMpi,
  prec : Int,
) -> RawMpi raise MpiError {
  let p = default_prec(prec)
  let ya = y.lo
  let yb = y.hi
  let xa = x.lo
  let xb = x.hi
  if ya.is_zero() && yb.is_zero() {
    if xa >= @mpf.RawMpf::zero() {
      return RawMpi::zero()
    }
    return RawMpi::pi(p)
  }
  if xa >= @mpf.RawMpf::zero() {
    let a = if ya >= @mpf.RawMpf::zero() {
      elefun_atan2_checked(ya, xb, p, Floor)
    } else {
      elefun_atan2_checked(ya, xa, p, Floor)
    }
    let b = if yb >= @mpf.RawMpf::zero() {
      elefun_atan2_checked(yb, xa, p, Ceiling)
    } else {
      elefun_atan2_checked(yb, xb, p, Ceiling)
    }
    return RawMpi::new(a, b)
  }
  if ya >= @mpf.RawMpf::zero() {
    let b = elefun_atan2_checked(ya, xa, p, Ceiling)
    let a = if xb <= @mpf.RawMpf::zero() {
      elefun_atan2_checked(yb, xb, p, Floor)
    } else {
      elefun_atan2_checked(ya, xb, p, Floor)
    }
    return RawMpi::new(a, b)
  }
  if yb <= @mpf.RawMpf::zero() {
    let a = elefun_atan2_checked(yb, xa, p, Floor)
    let b = if xb <= @mpf.RawMpf::zero() {
      elefun_atan2_checked(ya, xb, p, Ceiling)
    } else {
      elefun_atan2_checked(yb, xb, p, Ceiling)
    }
    return RawMpi::new(a, b)
  }
  let b = elefun_pi_checked(p, Ceiling)
  let a = b.negated(0, Down)
  RawMpi::new(a, b)
}

///|
pub fn RawMpci::exp(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let r = z.real.exp(wp)
  let (c, s) = z.imag.cos_sin(wp)
  { real: r.mul(c, prec=out), imag: r.mul(s, prec=out) }
}

///|
pub fn RawMpci::cos(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  let wp = if prec > 0 { prec + 10 } else { 90 }
  let out = default_prec(prec)
  let (c, s) = z.real.cos_sin(wp)
  let (ch, sh) = z.imag.cosh_sinh(wp)
  let re = c.mul(ch, prec=out)
  let im = s.mul(sh, prec=out)
  { real: re, imag: im.negated(prec=out) }
}

///|
pub fn RawMpci::sin(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  let wp = if prec > 0 { prec + 10 } else { 90 }
  let out = default_prec(prec)
  let (c, s) = z.real.cos_sin(wp)
  let (ch, sh) = z.imag.cosh_sinh(wp)
  { real: s.mul(ch, prec=out), imag: c.mul(sh, prec=out) }
}

///|
pub fn RawMpci::abs(z : RawMpci, prec : Int) -> RawMpi raise MpiError {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  if z.real == RawMpi::zero() {
    return z.imag.abs(prec=out)
  }
  if z.imag == RawMpi::zero() {
    return z.real.abs(prec=out)
  }
  let a = z.real.square(prec=wp)
  let b = z.imag.square(prec=wp)
  let t = a.add(b, prec=wp)
  t.sqrt(out)
}

///|
pub fn RawMpci::arg(z : RawMpci, prec : Int) -> RawMpi raise MpiError {
  z.imag.atan2(z.real, prec)
}

///|
pub fn RawMpci::log(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  { real: z.abs(wp).log(out), imag: z.arg(out) }
}

///|
pub fn RawMpci::square(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  let wp = work_prec(prec)
  let out = default_prec(prec)
  let re = z.real.square(prec=wp).sub(z.imag.square(prec=wp), prec=out)
  let im = z.real.mul(z.imag, prec=out).scale_pow2(1)
  { real: re, imag: im }
}

///|
pub fn RawMpci::pow_int(
  z : RawMpci,
  n : Int,
  prec : Int,
) -> RawMpci raise MpiError {
  let out = default_prec(prec)
  if n < 0 {
    return RawMpci::one().div(z.pow_int(-n, out + 20), out)
  }
  if n == 0 {
    return RawMpci::one()
  }
  if n == 1 {
    return z.rounded(out)
  }
  if n == 2 {
    return z.square(out)
  }
  let wp = out + 20
  let mut result = RawMpci::one()
  let mut base = z
  let mut e = n
  while e > 0 {
    if (e & 1) == 1 {
      result = result.mul(base, wp)
    }
    e = e >> 1
    if e > 0 {
      base = base.square(wp)
    }
  }
  result.rounded(out)
}

///|
pub fn RawMpci::pow(
  z : RawMpci,
  w : RawMpci,
  prec : Int,
) -> RawMpci raise MpiError {
  if w.imag == RawMpi::zero() && w.real.lo == w.real.hi {
    if w.real.lo.is_zero() {
      return RawMpci::one()
    }
    match maybe_integer(w.real.lo) {
      Some(n) => return z.pow_int(n, prec)
      None => ()
    }
  }
  let wp = work_prec(prec)
  let out = default_prec(prec)
  w.mul(z.log(wp), wp).exp(out)
}
