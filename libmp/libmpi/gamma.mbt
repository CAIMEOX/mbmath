///|
let gamma_kind_gamma = 0

///|
let gamma_kind_factorial = 1

///|
let gamma_kind_rgamma = 2

///|
let gamma_kind_loggamma = 3

///|
fn gamma_min_a() -> @mpf.RawMpf raise MpiError {
  @mpf.RawMpf::parse("1.46163214496", prec=96, rnd=Nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn gamma_min_b() -> @mpf.RawMpf raise MpiError {
  @mpf.RawMpf::parse("1.46163214497", prec=96, rnd=Nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn gamma_mono_imag() -> RawMpi raise MpiError {
  let lo = @mpf.RawMpf::parse("-1.1", prec=96, rnd=Nearest) catch {
    err => raise from_mpf_error(err)
  }
  let hi = @mpf.RawMpf::parse("1.1", prec=96, rnd=Nearest) catch {
    err => raise from_mpf_error(err)
  }
  RawMpi::new(lo, hi)
}

///|
fn lift_real_interval(x : RawMpi) -> RawMpci {
  { real: x, imag: RawMpi::zero() }
}

///|
fn mpc_loggamma_point(
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
  p : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MpiError {
  @mpc.RawMpc::new(re, im).loggamma(p, rnd) catch {
    err => raise from_mpc_error(err)
  }
}

///|
fn mpc_gamma_kind_point(
  z : @mpc.RawMpc,
  p : Int,
  kind : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MpiError {
  if kind == gamma_kind_gamma {
    z.gamma(p, rnd) catch {
      err => raise from_mpc_error(err)
    }
  } else if kind == gamma_kind_rgamma {
    z.rgamma(p, rnd) catch {
      err => raise from_mpc_error(err)
    }
  } else if kind == gamma_kind_loggamma {
    z.loggamma(p, rnd) catch {
      err => raise from_mpc_error(err)
    }
  } else if kind == gamma_kind_factorial {
    z.factorial(p, rnd) catch {
      err => raise from_mpc_error(err)
    }
  } else {
    raise UnsupportedError("complex gamma interval evaluation: unknown kind")
  }
}

///|
fn widen_mpi_with_value(x : RawMpi, v : @mpf.RawMpf, p : Int) -> RawMpi {
  if v.is_nan() {
    x
  } else {
    let lo = if v < x.lo { v.rounded(p, Floor) } else { x.lo }
    let hi = if v > x.hi { v.rounded(p, Ceiling) } else { x.hi }
    RawMpi::new(lo, hi)
  }
}

///|
fn widen_mpci_with_point(z : RawMpci, w : @mpc.RawMpc, p : Int) -> RawMpci {
  {
    real: widen_mpi_with_value(z.real, w.real, p),
    imag: widen_mpi_with_value(z.imag, w.imag, p),
  }
}

///|
fn mpi_gamma_kind(z : RawMpi, prec : Int, kind : Int) -> RawMpi raise MpiError {
  let p = default_prec(prec)
  let wp = p + 20
  let min_a = gamma_min_a()
  let min_b = gamma_min_b()
  if kind == gamma_kind_factorial {
    return mpi_gamma_kind(z.add(RawMpi::one(), prec=wp), p, gamma_kind_gamma)
  }
  if z.lo > min_b {
    if kind == gamma_kind_gamma {
      let lo = @gammazeta.gamma(z.lo, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.gamma(z.hi, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else if kind == gamma_kind_rgamma {
      let lo = @gammazeta.rgamma(z.hi, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.rgamma(z.lo, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else if kind == gamma_kind_loggamma {
      let lo = @gammazeta.loggamma(z.lo, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.loggamma(z.hi, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else {
      raise UnsupportedError("gamma interval evaluation: unknown kind")
    }
  }
  if z.lo > @mpf.RawMpf::zero() && z.hi < min_a {
    if kind == gamma_kind_gamma {
      let lo = @gammazeta.gamma(z.hi, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.gamma(z.lo, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else if kind == gamma_kind_rgamma {
      let lo = @gammazeta.rgamma(z.lo, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.rgamma(z.hi, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else if kind == gamma_kind_loggamma {
      let lo = @gammazeta.loggamma(z.hi, p, Floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.loggamma(z.lo, p, Ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return RawMpi::new(lo, hi)
    } else {
      raise UnsupportedError("gamma interval evaluation: unknown kind")
    }
  }
  let znew = z.add(RawMpi::one(), prec=wp)
  if kind == gamma_kind_gamma {
    mpi_gamma_kind(znew, p + 2, kind).div(z, p)
  } else if kind == gamma_kind_rgamma {
    mpi_gamma_kind(znew, p + 2, kind).mul(z, prec=p)
  } else if kind == gamma_kind_loggamma {
    mpi_gamma_kind(znew, p + 2, kind).sub(z.log(p + 2), prec=p)
  } else {
    raise UnsupportedError("gamma interval evaluation: unknown kind")
  }
}

///|
pub fn RawMpi::gamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_gamma)
}

///|
pub fn RawMpi::loggamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_loggamma)
}

///|
pub fn RawMpi::rgamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_rgamma)
}

///|
pub fn RawMpi::factorial(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_factorial)
}

///|
fn mpci_gamma_kind(
  z : RawMpci,
  prec : Int,
  kind : Int,
) -> RawMpci raise MpiError {
  let p = default_prec(prec)
  let min_b = gamma_min_b()
  let mono_imag = gamma_mono_imag()
  if z.real.lo == z.real.hi && z.imag.lo == z.imag.hi {
    let wp = p + 24
    let z0 = @mpc.RawMpc::new(z.real.lo, z.imag.lo)
    let lo = mpc_gamma_kind_point(z0, wp, kind, Floor)
    let hi = mpc_gamma_kind_point(z0, wp, kind, Ceiling)
    return RawMpci::new(
      RawMpi::new(lo.real, hi.real),
      RawMpi::new(lo.imag, hi.imag),
    ).rounded(p)
  }
  if z.imag == RawMpi::zero() &&
    (kind != gamma_kind_loggamma || z.real.lo > @mpf.RawMpf::zero()) {
    return lift_real_interval(mpi_gamma_kind(z.real, p, kind))
  }
  let mut wp = p + 20
  if kind != gamma_kind_loggamma {
    let amag = if z.real.hi.is_finite() {
      z.real.hi.exp + z.real.hi.bc
    } else {
      0
    }
    let bmag = if z.imag.hi.is_finite() {
      z.imag.hi.exp + z.imag.hi.bc
    } else {
      0
    }
    let mag = if amag > bmag { amag } else { bmag }
    if mag > 0 {
      wp += mag + 8
    }
  }
  let mut z0 = z
  let mut k = kind
  if kind == gamma_kind_factorial {
    z0 = z.add(RawMpci::one(), wp)
    k = gamma_kind_gamma
  }
  if z0.real.lo < min_b && z0.imag.overlaps(mono_imag) {
    let znew = z0.add(RawMpci::one(), wp)
    if k == gamma_kind_gamma {
      return mpci_gamma_kind(znew, p + 2, k).div(z0, p)
    } else if k == gamma_kind_rgamma {
      return mpci_gamma_kind(znew, p + 2, k).mul(z0, p)
    } else if k == gamma_kind_loggamma {
      return mpci_gamma_kind(znew, p + 2, k).sub(z0.log(p + 2), p)
    } else {
      raise UnsupportedError("complex gamma interval evaluation: unknown kind")
    }
  }
  let (minre, maxre, minim, maxim) = if z0.imag.lo >= @mpf.RawMpf::zero() {
    (
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, Floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, Ceiling),
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, Floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, Ceiling),
    )
  } else if z0.imag.hi <= @mpf.RawMpf::zero() {
    (
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, Floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, Ceiling),
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, Floor),
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, Ceiling),
    )
  } else {
    let maxre = mpc_loggamma_point(z0.real.hi, @mpf.RawMpf::zero(), wp, Ceiling)
    let minre = if z0.imag.lo.negated(0, Down) > z0.imag.hi {
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, Ceiling)
    } else {
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, Ceiling)
    }
    (
      minre,
      maxre,
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, Floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, Floor),
    )
  }
  let mut w = RawMpci::new(
    RawMpi::new(minre.real, maxre.real),
    RawMpi::new(minim.imag, maxim.imag),
  )
  if k == gamma_kind_loggamma {
    w = widen_mpci_with_point(
      w,
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, Nearest),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, Nearest),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, Nearest),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, Nearest),
      wp,
    )
    if z0.imag.lo <= @mpf.RawMpf::zero() && z0.imag.hi >= @mpf.RawMpf::zero() {
      w = widen_mpci_with_point(
        w,
        mpc_loggamma_point(z0.real.lo, @mpf.RawMpf::zero(), wp, Nearest),
        wp,
      )
      w = widen_mpci_with_point(
        w,
        mpc_loggamma_point(z0.real.hi, @mpf.RawMpf::zero(), wp, Nearest),
        wp,
      )
    }
    return w.rounded(p)
  }
  if k == gamma_kind_rgamma {
    w = w.negated(wp)
  }
  w.exp(p)
}

///|
pub fn RawMpci::gamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_gamma)
}

///|
pub fn RawMpci::loggamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_loggamma)
}

///|
pub fn RawMpci::rgamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_rgamma)
}

///|
pub fn RawMpci::factorial(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_factorial)
}
