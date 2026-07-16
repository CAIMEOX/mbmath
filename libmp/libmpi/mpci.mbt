///|
pub fn RawMpci::new(real : RawMpi, imag : RawMpi) -> RawMpci {
  { real, imag }
}

///|
pub impl Neg for RawMpci with fn neg(z) {
  RawMpci::new(-z.real, -z.imag)
}

///|
pub impl Hash for RawMpci with fn hash_combine(z, hasher) {
  hasher.combine(z.real)
  hasher.combine(z.imag)
}

///|
pub fn RawMpci::rounded(z : RawMpci, prec : Int) -> RawMpci {
  { real: z.real.rounded(prec), imag: z.imag.rounded(prec) }
}

///|
pub fn RawMpci::negated(z : RawMpci, prec : Int) -> RawMpci {
  { real: z.real.negated(prec~), imag: z.imag.negated(prec~) }
}

///|
pub fn RawMpci::add(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  { real: z.real.add(w.real, prec~), imag: z.imag.add(w.imag, prec~) }
}

///|
pub fn RawMpci::sub(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  { real: z.real.sub(w.real, prec~), imag: z.imag.sub(w.imag, prec~) }
}

///|
pub fn RawMpci::mul(
  z : RawMpci,
  w : RawMpci,
  prec : Int,
) -> RawMpci raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let r1 = z.real.mul(w.real, prec=wp)
  let r2 = z.imag.mul(w.imag, prec=wp)
  let i1 = z.real.mul(w.imag, prec=wp)
  let i2 = z.imag.mul(w.real, prec=wp)
  { real: r1.sub(r2, prec~), imag: i1.add(i2, prec~) }
}

///|
pub fn RawMpci::div(
  z : RawMpci,
  w : RawMpci,
  prec : Int,
) -> RawMpci raise MpiError {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let m1 = w.real.square(prec=wp)
  let m2 = w.imag.square(prec=wp)
  let m = m1.add(m2, prec=wp)
  let re_num = z.real
    .mul(w.real, prec=wp)
    .add(z.imag.mul(w.imag, prec=wp), prec=wp)
  let im_num = z.imag
    .mul(w.real, prec=wp)
    .sub(z.real.mul(w.imag, prec=wp), prec=wp)
  {
    real: re_num.div(m, if prec > 0 { prec } else { wp }),
    imag: im_num.div(m, if prec > 0 { prec } else { wp }),
  }
}

///|
pub fn RawMpci::contains_point(
  z : RawMpci,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Bool {
  z.real.lo <= re && z.real.hi >= re && z.imag.lo <= im && z.imag.hi >= im
}
