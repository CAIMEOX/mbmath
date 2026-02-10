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
  @mpf.from_str("1.46163214496", prec=96, rnd=@mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn gamma_min_b() -> @mpf.RawMpf raise MpiError {
  @mpf.from_str("1.46163214497", prec=96, rnd=@mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
}

///|
fn gamma_mono_imag() -> RawMpi raise MpiError {
  let lo = @mpf.from_str("-1.1", prec=96, rnd=@mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
  let hi = @mpf.from_str("1.1", prec=96, rnd=@mpf.round_nearest) catch {
    err => raise from_mpf_error(err)
  }
  mpi_make(lo, hi)
}

///|
fn lift_real_interval(x : RawMpi) -> RawMpci {
  { real: x, imag: mpi_zero }
}

///|
fn mpc_loggamma_point(
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
  p : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc {
  @mpc.mpc_loggamma(@mpc.from_parts(re, im), p, rnd)
}

///|
fn mpc_gamma_kind_point(
  z : @mpc.RawMpc,
  p : Int,
  kind : Int,
  rnd : @mpf.RoundMode,
) -> @mpc.RawMpc raise MpiError {
  if kind == gamma_kind_gamma {
    @mpc.mpc_gamma(z, p, rnd)
  } else if kind == gamma_kind_rgamma {
    @mpc.mpc_rgamma(z, p, rnd)
  } else if kind == gamma_kind_loggamma {
    @mpc.mpc_loggamma(z, p, rnd)
  } else if kind == gamma_kind_factorial {
    @mpc.mpc_factorial(z, p, rnd)
  } else {
    raise MpiError::UnsupportedError("mpc_gamma_kind_point: unknown kind")
  }
}

///|
fn widen_mpi_with_value(x : RawMpi, v : @mpf.RawMpf, p : Int) -> RawMpi {
  if @mpf.is_nan(v) {
    x
  } else {
    let lo = if @mpf.mpf_lt(v, x.lo) {
      @mpf.mpf_pos(v, p, @mpf.round_floor)
    } else {
      x.lo
    }
    let hi = if @mpf.mpf_gt(v, x.hi) {
      @mpf.mpf_pos(v, p, @mpf.round_ceiling)
    } else {
      x.hi
    }
    mpi_make(lo, hi)
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
    return mpi_gamma_kind(mpi_add(z, mpi_one, prec=wp), p, gamma_kind_gamma)
  }
  if @mpf.mpf_gt(z.lo, min_b) {
    if kind == gamma_kind_gamma {
      let lo = @gammazeta.mpf_gamma(z.lo, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_gamma(z.hi, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else if kind == gamma_kind_rgamma {
      let lo = @gammazeta.mpf_rgamma(z.hi, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_rgamma(z.lo, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else if kind == gamma_kind_loggamma {
      let lo = @gammazeta.mpf_loggamma(z.lo, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_loggamma(z.hi, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else {
      raise MpiError::UnsupportedError("mpi_gamma_kind: unknown kind")
    }
  }
  if @mpf.mpf_gt(z.lo, @mpf.fzero) && @mpf.mpf_lt(z.hi, min_a) {
    if kind == gamma_kind_gamma {
      let lo = @gammazeta.mpf_gamma(z.hi, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_gamma(z.lo, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else if kind == gamma_kind_rgamma {
      let lo = @gammazeta.mpf_rgamma(z.lo, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_rgamma(z.hi, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else if kind == gamma_kind_loggamma {
      let lo = @gammazeta.mpf_loggamma(z.hi, p, @mpf.round_floor) catch {
        err => raise from_gammazeta_error(err)
      }
      let hi = @gammazeta.mpf_loggamma(z.lo, p, @mpf.round_ceiling) catch {
        err => raise from_gammazeta_error(err)
      }
      return mpi_make(lo, hi)
    } else {
      raise MpiError::UnsupportedError("mpi_gamma_kind: unknown kind")
    }
  }
  let znew = mpi_add(z, mpi_one, prec=wp)
  if kind == gamma_kind_gamma {
    mpi_div(mpi_gamma_kind(znew, p + 2, kind), z, p)
  } else if kind == gamma_kind_rgamma {
    mpi_mul(mpi_gamma_kind(znew, p + 2, kind), z, prec=p)
  } else if kind == gamma_kind_loggamma {
    mpi_sub(mpi_gamma_kind(znew, p + 2, kind), mpi_log(z, p + 2), prec=p)
  } else {
    raise MpiError::UnsupportedError("mpi_gamma_kind: unknown kind")
  }
}

///|
pub fn mpi_gamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_gamma)
}

///|
pub fn mpi_loggamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_loggamma)
}

///|
pub fn mpi_rgamma(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
  mpi_gamma_kind(z, prec, gamma_kind_rgamma)
}

///|
pub fn mpi_factorial(z : RawMpi, prec : Int) -> RawMpi raise MpiError {
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
  if @mpf.mpf_eq(z.real.lo, z.real.hi) && @mpf.mpf_eq(z.imag.lo, z.imag.hi) {
    let wp = p + 24
    let z0 = @mpc.from_parts(z.real.lo, z.imag.lo)
    let lo = mpc_gamma_kind_point(z0, wp, kind, @mpf.round_floor)
    let hi = mpc_gamma_kind_point(z0, wp, kind, @mpf.round_ceiling)
    return mpci_pos(
      mpci_make(mpi_make(lo.real, hi.real), mpi_make(lo.imag, hi.imag)),
      p,
    )
  }
  if z.imag == mpi_zero &&
    (kind != gamma_kind_loggamma || @mpf.mpf_gt(z.real.lo, @mpf.fzero)) {
    return lift_real_interval(mpi_gamma_kind(z.real, p, kind))
  }
  let mut wp = p + 20
  if kind != gamma_kind_loggamma {
    let amag = if @mpf.is_finite(z.real.hi) {
      z.real.hi.exp + z.real.hi.bc
    } else {
      0
    }
    let bmag = if @mpf.is_finite(z.imag.hi) {
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
    z0 = mpci_add(z, mpci_one, wp)
    k = gamma_kind_gamma
  }
  if @mpf.mpf_lt(z0.real.lo, min_b) && mpi_overlap(z0.imag, mono_imag) {
    let znew = mpci_add(z0, mpci_one, wp)
    if k == gamma_kind_gamma {
      return mpci_div(mpci_gamma_kind(znew, p + 2, k), z0, p)
    } else if k == gamma_kind_rgamma {
      return mpci_mul(mpci_gamma_kind(znew, p + 2, k), z0, p)
    } else if k == gamma_kind_loggamma {
      return mpci_sub(mpci_gamma_kind(znew, p + 2, k), mpci_log(z0, p + 2), p)
    } else {
      raise MpiError::UnsupportedError("mpci_gamma_kind: unknown kind")
    }
  }
  let (minre, maxre, minim, maxim) = if @mpf.mpf_ge(z0.imag.lo, @mpf.fzero) {
    (
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, @mpf.round_floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, @mpf.round_ceiling),
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, @mpf.round_floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, @mpf.round_ceiling),
    )
  } else if @mpf.mpf_le(z0.imag.hi, @mpf.fzero) {
    (
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, @mpf.round_floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, @mpf.round_ceiling),
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, @mpf.round_floor),
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, @mpf.round_ceiling),
    )
  } else {
    let maxre = mpc_loggamma_point(
      z0.real.hi,
      @mpf.fzero,
      wp,
      @mpf.round_ceiling,
    )
    let minre = if @mpf.mpf_gt(
        @mpf.mpf_neg(z0.imag.lo, 0, @mpf.round_down),
        z0.imag.hi,
      ) {
      mpc_loggamma_point(z0.real.lo, z0.imag.lo, wp, @mpf.round_ceiling)
    } else {
      mpc_loggamma_point(z0.real.lo, z0.imag.hi, wp, @mpf.round_ceiling)
    }
    (
      minre,
      maxre,
      mpc_loggamma_point(z0.real.hi, z0.imag.lo, wp, @mpf.round_floor),
      mpc_loggamma_point(z0.real.hi, z0.imag.hi, wp, @mpf.round_floor),
    )
  }
  let mut w = mpci_make(
    mpi_make(minre.real, maxre.real),
    mpi_make(minim.imag, maxim.imag),
  )
  if k == gamma_kind_loggamma {
    w = widen_mpci_with_point(
      w,
      @mpc.mpc_loggamma(
        @mpc.from_parts(z0.real.lo, z0.imag.lo),
        wp,
        @mpf.round_nearest,
      ),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      @mpc.mpc_loggamma(
        @mpc.from_parts(z0.real.hi, z0.imag.lo),
        wp,
        @mpf.round_nearest,
      ),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      @mpc.mpc_loggamma(
        @mpc.from_parts(z0.real.lo, z0.imag.hi),
        wp,
        @mpf.round_nearest,
      ),
      wp,
    )
    w = widen_mpci_with_point(
      w,
      @mpc.mpc_loggamma(
        @mpc.from_parts(z0.real.hi, z0.imag.hi),
        wp,
        @mpf.round_nearest,
      ),
      wp,
    )
    if @mpf.mpf_le(z0.imag.lo, @mpf.fzero) &&
      @mpf.mpf_ge(z0.imag.hi, @mpf.fzero) {
      w = widen_mpci_with_point(
        w,
        @mpc.mpc_loggamma(
          @mpc.from_parts(z0.real.lo, @mpf.fzero),
          wp,
          @mpf.round_nearest,
        ),
        wp,
      )
      w = widen_mpci_with_point(
        w,
        @mpc.mpc_loggamma(
          @mpc.from_parts(z0.real.hi, @mpf.fzero),
          wp,
          @mpf.round_nearest,
        ),
        wp,
      )
    }
    return mpci_pos(w, p)
  }
  if k == gamma_kind_rgamma {
    w = mpci_neg(w, wp)
  }
  mpci_exp(w, p)
}

///|
pub fn mpci_gamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_gamma)
}

///|
pub fn mpci_loggamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_loggamma)
}

///|
pub fn mpci_rgamma(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_rgamma)
}

///|
pub fn mpci_factorial(z : RawMpci, prec : Int) -> RawMpci raise MpiError {
  mpci_gamma_kind(z, prec, gamma_kind_factorial)
}
