///|
pub fn mpci_make(real : RawMpi, imag : RawMpi) -> RawMpci {
  { real, imag }
}

///|
pub fn mpci_pos(z : RawMpci, prec : Int) -> RawMpci {
  { real: mpi_pos(z.real, prec), imag: mpi_pos(z.imag, prec) }
}

///|
pub fn mpci_neg(z : RawMpci, prec : Int) -> RawMpci {
  { real: mpi_neg(z.real, prec~), imag: mpi_neg(z.imag, prec~) }
}

///|
pub fn mpci_add(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  { real: mpi_add(z.real, w.real, prec~), imag: mpi_add(z.imag, w.imag, prec~) }
}

///|
pub fn mpci_sub(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  { real: mpi_sub(z.real, w.real, prec~), imag: mpi_sub(z.imag, w.imag, prec~) }
}

///|
pub fn mpci_mul(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let r1 = mpi_mul(z.real, w.real, prec=wp)
  let r2 = mpi_mul(z.imag, w.imag, prec=wp)
  let i1 = mpi_mul(z.real, w.imag, prec=wp)
  let i2 = mpi_mul(z.imag, w.real, prec=wp)
  { real: mpi_sub(r1, r2, prec~), imag: mpi_add(i1, i2, prec~) }
}

///|
pub fn mpci_div(z : RawMpci, w : RawMpci, prec : Int) -> RawMpci {
  let wp = if prec > 0 { prec + 20 } else { 80 }
  let m1 = mpi_square(w.real, prec=wp)
  let m2 = mpi_square(w.imag, prec=wp)
  let m = mpi_add(m1, m2, prec=wp)
  let re_num = mpi_add(
    mpi_mul(z.real, w.real, prec=wp),
    mpi_mul(z.imag, w.imag, prec=wp),
    prec=wp,
  )
  let im_num = mpi_sub(
    mpi_mul(z.imag, w.real, prec=wp),
    mpi_mul(z.real, w.imag, prec=wp),
    prec=wp,
  )
  {
    real: mpi_div(re_num, m, if prec > 0 { prec } else { wp }),
    imag: mpi_div(im_num, m, if prec > 0 { prec } else { wp }),
  }
}

///|
pub fn mpci_contains_mpf(
  z : RawMpci,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Bool {
  @mpf.mpf_le(z.real.lo, re) &&
  @mpf.mpf_ge(z.real.hi, re) &&
  @mpf.mpf_le(z.imag.lo, im) &&
  @mpf.mpf_ge(z.imag.hi, im)
}
