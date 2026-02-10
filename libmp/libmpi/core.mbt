///|
fn from_mpf_error(err : @mpf.MpfError) -> MpiError {
  match err {
    @mpf.MpfError::ValueError(msg) => MpiError::ValueError(msg)
    @mpf.MpfError::DomainError(msg) => MpiError::DomainError(msg)
    @mpf.MpfError::DivisionByZero(msg) => MpiError::DomainError(msg)
    @mpf.MpfError::ParseError(msg) => MpiError::ParseError(msg)
    @mpf.MpfError::FormatError(msg) => MpiError::ValueError(msg)
    @mpf.MpfError::UnsupportedError(msg) => MpiError::UnsupportedError(msg)
  }
}

///|
fn from_libelefun_error(err : @libelefun.LibElefunError) -> MpiError {
  match err {
    @libelefun.LibElefunError::ValueError(msg) => MpiError::ValueError(msg)
    @libelefun.LibElefunError::DomainError(msg) => MpiError::DomainError(msg)
    @libelefun.LibElefunError::ComplexResult(msg) => MpiError::DomainError(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> MpiError {
  match err {
    @gammazeta.GammaZetaError::ValueError(msg) => MpiError::ValueError(msg)
    @gammazeta.GammaZetaError::DomainError(msg) => MpiError::DomainError(msg)
    @gammazeta.GammaZetaError::PoleError(msg) => MpiError::DomainError(msg)
  }
}

///|
let fhalf : @mpf.RawMpf = @mpf.from_man_exp(1N, -1, 0, @mpf.round_down)

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !@mpf.is_finite(x) {
    return None
  }
  if @mpf.is_zero(x) {
    return Some(0)
  }
  if x.exp < 0 {
    return None
  }
  let v = x.man << x.exp
  if v.bit_length() > 60 {
    return None
  }
  let n = v.to_int()
  let signed_n = if x.sign == 1 { -n } else { n }
  if @mpf.mpf_eq(x, @mpf.from_int(signed_n)) {
    Some(signed_n)
  } else {
    None
  }
}

///|
fn nan_to_lo(x : @mpf.RawMpf) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    @mpf.fninf
  } else {
    x
  }
}

///|
fn nan_to_hi(x : @mpf.RawMpf) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    @mpf.finf
  } else {
    x
  }
}

///|
pub fn mpi_make(lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> RawMpi {
  if @mpf.is_nan(lo) || @mpf.is_nan(hi) {
    { lo: @mpf.fninf, hi: @mpf.finf }
  } else if @mpf.mpf_le(lo, hi) {
    { lo, hi }
  } else {
    { lo: hi, hi: lo }
  }
}

///|
pub fn mpi_from_mpf(x : @mpf.RawMpf) -> RawMpi {
  { lo: x, hi: x }
}

///|
pub fn mpi_eq(s : RawMpi, t : RawMpi) -> Bool {
  s == t
}

///|
pub fn mpi_ne(s : RawMpi, t : RawMpi) -> Bool {
  s != t
}

///|
pub fn mpi_lt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  if @mpf.mpf_lt(s.hi, t.lo) {
    true
  } else if @mpf.mpf_ge(s.lo, t.hi) {
    false
  } else {
    raise MpiError::UnorderedError(
      "mpi_lt: overlapping intervals are unordered",
    )
  }
}

///|
pub fn mpi_le(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  if @mpf.mpf_le(s.hi, t.lo) {
    true
  } else if @mpf.mpf_gt(s.lo, t.hi) {
    false
  } else {
    raise MpiError::UnorderedError(
      "mpi_le: overlapping intervals are unordered",
    )
  }
}

///|
pub fn mpi_gt(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  mpi_lt(t, s)
}

///|
pub fn mpi_ge(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  mpi_le(t, s)
}

///|
pub fn mpi_overlap(x : RawMpi, y : RawMpi) -> Bool {
  !(@mpf.mpf_lt(y.hi, x.lo) || @mpf.mpf_gt(y.lo, x.hi))
}

///|
pub fn mpi_add(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  let a = nan_to_lo(@mpf.mpf_add(s.lo, t.lo, prec, @mpf.round_floor))
  let b = nan_to_hi(@mpf.mpf_add(s.hi, t.hi, prec, @mpf.round_ceiling))
  { lo: a, hi: b }
}

///|
pub fn mpi_sub(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  let a = nan_to_lo(@mpf.mpf_sub(s.lo, t.hi, prec, @mpf.round_floor))
  let b = nan_to_hi(@mpf.mpf_sub(s.hi, t.lo, prec, @mpf.round_ceiling))
  { lo: a, hi: b }
}

///|
pub fn mpi_delta(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  @mpf.mpf_sub(s.hi, s.lo, prec, @mpf.round_up)
}

///|
pub fn mpi_mid(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  @mpf.mpf_shift(@mpf.mpf_add(s.lo, s.hi, prec, @mpf.round_nearest), -1)
}

///|
pub fn mpi_pos(s : RawMpi, prec : Int) -> RawMpi {
  {
    lo: @mpf.mpf_pos(s.lo, prec, @mpf.round_floor),
    hi: @mpf.mpf_pos(s.hi, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_neg(s : RawMpi, prec? : Int = 0) -> RawMpi {
  {
    lo: @mpf.mpf_neg(s.hi, prec, @mpf.round_floor),
    hi: @mpf.mpf_neg(s.lo, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_abs(s : RawMpi, prec? : Int = 0) -> RawMpi {
  let sas = @mpf.mpf_sign(s.lo)
  let sbs = @mpf.mpf_sign(s.hi)
  if sas >= 0 {
    return {
      lo: @mpf.mpf_pos(s.lo, prec, @mpf.round_floor),
      hi: @mpf.mpf_pos(s.hi, prec, @mpf.round_ceiling),
    }
  }
  if sbs >= 0 {
    let neg_lo = @mpf.mpf_neg(s.lo, 0, @mpf.round_down)
    let hi = if @mpf.mpf_lt(neg_lo, s.hi) {
      @mpf.mpf_pos(s.hi, prec, @mpf.round_ceiling)
    } else {
      @mpf.mpf_pos(neg_lo, prec, @mpf.round_ceiling)
    }
    return { lo: @mpf.fzero, hi }
  }
  {
    lo: @mpf.mpf_neg(s.hi, prec, @mpf.round_floor),
    hi: @mpf.mpf_neg(s.lo, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_mul_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  mpi_mul(s, { lo: t, hi: t }, prec~)
}

///|
pub fn mpi_div_mpf(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  mpi_div(s, { lo: t, hi: t }, prec)
}

///|
pub fn mpi_mul(
  s : RawMpi,
  t : RawMpi,
  prec? : Int = 0,
) -> RawMpi raise MpiError {
  let sas = @mpf.mpf_sign(s.lo)
  let sbs = @mpf.mpf_sign(s.hi)
  let tas = @mpf.mpf_sign(t.lo)
  let tbs = @mpf.mpf_sign(t.hi)
  if sas == 0 && sbs == 0 {
    if t.lo == @mpf.fninf || t.hi == @mpf.finf {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
    return mpi_zero
  }
  if tas == 0 && tbs == 0 {
    if s.lo == @mpf.fninf || s.hi == @mpf.finf {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
    return mpi_zero
  }
  if sas >= 0 {
    if tas >= 0 {
      let a = @mpf.mpf_mul(s.lo, t.lo, prec, @mpf.round_floor)
      let b = @mpf.mpf_mul(s.hi, t.hi, prec, @mpf.round_ceiling)
      return {
        lo: if @mpf.is_nan(a) {
          @mpf.fzero
        } else {
          a
        },
        hi: if @mpf.is_nan(b) {
          @mpf.finf
        } else {
          b
        },
      }
    }
    if tbs <= 0 {
      let a = @mpf.mpf_mul(s.hi, t.lo, prec, @mpf.round_floor)
      let b = @mpf.mpf_mul(s.lo, t.hi, prec, @mpf.round_ceiling)
      return {
        lo: if @mpf.is_nan(a) {
          @mpf.fninf
        } else {
          a
        },
        hi: if @mpf.is_nan(b) {
          @mpf.fzero
        } else {
          b
        },
      }
    }
    let a = @mpf.mpf_mul(s.hi, t.lo, prec, @mpf.round_floor)
    let b = @mpf.mpf_mul(s.hi, t.hi, prec, @mpf.round_ceiling)
    return {
      lo: if @mpf.is_nan(a) {
        @mpf.fninf
      } else {
        a
      },
      hi: if @mpf.is_nan(b) {
        @mpf.finf
      } else {
        b
      },
    }
  }
  if sbs <= 0 {
    if tas >= 0 {
      let a = @mpf.mpf_mul(s.lo, t.hi, prec, @mpf.round_floor)
      let b = @mpf.mpf_mul(s.hi, t.lo, prec, @mpf.round_ceiling)
      return {
        lo: if @mpf.is_nan(a) {
          @mpf.fninf
        } else {
          a
        },
        hi: if @mpf.is_nan(b) {
          @mpf.fzero
        } else {
          b
        },
      }
    }
    if tbs <= 0 {
      let a = @mpf.mpf_mul(s.hi, t.hi, prec, @mpf.round_floor)
      let b = @mpf.mpf_mul(s.lo, t.lo, prec, @mpf.round_ceiling)
      return {
        lo: if @mpf.is_nan(a) {
          @mpf.fzero
        } else {
          a
        },
        hi: if @mpf.is_nan(b) {
          @mpf.finf
        } else {
          b
        },
      }
    }
    let a = @mpf.mpf_mul(s.lo, t.hi, prec, @mpf.round_floor)
    let b = @mpf.mpf_mul(s.lo, t.lo, prec, @mpf.round_ceiling)
    return {
      lo: if @mpf.is_nan(a) {
        @mpf.fninf
      } else {
        a
      },
      hi: if @mpf.is_nan(b) {
        @mpf.finf
      } else {
        b
      },
    }
  }
  let cases : Array[@mpf.RawMpf] = [
    @mpf.mpf_mul(s.lo, t.lo, 0, @mpf.round_down),
    @mpf.mpf_mul(s.lo, t.hi, 0, @mpf.round_down),
    @mpf.mpf_mul(s.hi, t.lo, 0, @mpf.round_down),
    @mpf.mpf_mul(s.hi, t.hi, 0, @mpf.round_down),
  ]
  for v in cases {
    if @mpf.is_nan(v) {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
  }
  let (mn, mx) = @mpf.mpf_min_max(cases) catch {
    err => raise from_mpf_error(err)
  }
  {
    lo: @mpf.mpf_pos(mn, prec, @mpf.round_floor),
    hi: @mpf.mpf_pos(mx, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_square(s : RawMpi, prec? : Int = 0) -> RawMpi raise MpiError {
  if @mpf.mpf_ge(s.lo, @mpf.fzero) {
    return {
      lo: @mpf.mpf_mul(s.lo, s.lo, prec, @mpf.round_floor),
      hi: @mpf.mpf_mul(s.hi, s.hi, prec, @mpf.round_ceiling),
    }
  }
  if @mpf.mpf_le(s.hi, @mpf.fzero) {
    return {
      lo: @mpf.mpf_mul(s.hi, s.hi, prec, @mpf.round_floor),
      hi: @mpf.mpf_mul(s.lo, s.lo, prec, @mpf.round_ceiling),
    }
  }
  let neg_lo = @mpf.mpf_neg(s.lo, 0, @mpf.round_down)
  let (_, mx) = @mpf.mpf_min_max([neg_lo, s.hi]) catch {
    err => raise from_mpf_error(err)
  }
  { lo: @mpf.fzero, hi: @mpf.mpf_mul(mx, mx, prec, @mpf.round_ceiling) }
}

///|
pub fn mpi_div(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let sas = @mpf.mpf_sign(s.lo)
  let sbs = @mpf.mpf_sign(s.hi)
  let tas = @mpf.mpf_sign(t.lo)
  let tbs = @mpf.mpf_sign(t.hi)
  if sas == 0 && sbs == 0 {
    if (tas < 0 && tbs > 0) || tas == 0 || tbs == 0 {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
    return mpi_zero
  }
  if tas < 0 && tbs > 0 {
    return { lo: @mpf.fninf, hi: @mpf.finf }
  }
  if tas < 0 {
    return mpi_div(mpi_neg(s), mpi_neg(t), prec)
  }
  if tas == 0 {
    if sas < 0 && sbs > 0 {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
    if tas == tbs {
      return { lo: @mpf.fninf, hi: @mpf.finf }
    }
    if sas >= 0 {
      let lo = @mpf.mpf_div(s.lo, t.hi, prec, @mpf.round_floor) catch {
        err => raise from_mpf_error(err)
      }
      return { lo, hi: @mpf.finf }
    }
    let hi = @mpf.mpf_div(s.hi, t.hi, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo: @mpf.fninf, hi }
  }
  if sas >= 0 {
    let a = @mpf.mpf_div(s.lo, t.hi, prec, @mpf.round_floor) catch {
      err => raise from_mpf_error(err)
    }
    let b = @mpf.mpf_div(s.hi, t.lo, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return {
      lo: if @mpf.is_nan(a) {
        @mpf.fzero
      } else {
        a
      },
      hi: if @mpf.is_nan(b) {
        @mpf.finf
      } else {
        b
      },
    }
  }
  if sbs <= 0 {
    let a = @mpf.mpf_div(s.lo, t.lo, prec, @mpf.round_floor) catch {
      err => raise from_mpf_error(err)
    }
    let b = @mpf.mpf_div(s.hi, t.hi, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return {
      lo: if @mpf.is_nan(a) {
        @mpf.fninf
      } else {
        a
      },
      hi: if @mpf.is_nan(b) {
        @mpf.fzero
      } else {
        b
      },
    }
  }
  let a = @mpf.mpf_div(s.lo, t.lo, prec, @mpf.round_floor) catch {
    err => raise from_mpf_error(err)
  }
  let b = @mpf.mpf_div(s.hi, t.lo, prec, @mpf.round_ceiling) catch {
    err => raise from_mpf_error(err)
  }
  {
    lo: if @mpf.is_nan(a) {
      @mpf.fninf
    } else {
      a
    },
    hi: if @mpf.is_nan(b) {
      @mpf.finf
    } else {
      b
    },
  }
}

///|
pub fn mpi_pi(prec : Int) -> RawMpi {
  {
    lo: @libelefun.mpf_pi(prec, @mpf.round_floor),
    hi: @libelefun.mpf_pi(prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_exp(s : RawMpi, prec : Int) -> RawMpi {
  {
    lo: @libelefun.mpf_exp(s.lo, prec, @mpf.round_floor),
    hi: @libelefun.mpf_exp(s.hi, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_log(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let lo = @libelefun.mpf_ln(s.lo, prec, @mpf.round_floor) catch {
    err => raise from_libelefun_error(err)
  }
  let hi = @libelefun.mpf_ln(s.hi, prec, @mpf.round_ceiling) catch {
    err => raise from_libelefun_error(err)
  }
  { lo, hi }
}

///|
pub fn mpi_sqrt(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let lo = @mpf.mpf_sqrt(s.lo, prec, @mpf.round_floor) catch {
    err => raise from_mpf_error(err)
  }
  let hi = @mpf.mpf_sqrt(s.hi, prec, @mpf.round_ceiling) catch {
    err => raise from_mpf_error(err)
  }
  { lo, hi }
}

///|
pub fn mpi_atan(s : RawMpi, prec : Int) -> RawMpi {
  {
    lo: @libelefun.mpf_atan(s.lo, prec, @mpf.round_floor),
    hi: @libelefun.mpf_atan(s.hi, prec, @mpf.round_ceiling),
  }
}

///|
pub fn mpi_pow_int(s : RawMpi, n : Int, prec : Int) -> RawMpi raise MpiError {
  if n < 0 {
    return mpi_div(mpi_one, mpi_pow_int(s, -n, prec + 20), prec)
  }
  if n == 0 {
    return mpi_one
  }
  if n == 1 {
    return s
  }
  if n == 2 {
    return mpi_square(s, prec~)
  }
  if (n & 1) == 1 {
    let lo = @mpf.mpf_pow_int(s.lo, n, prec, @mpf.round_floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = @mpf.mpf_pow_int(s.hi, n, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  let sas = @mpf.mpf_sign(s.lo)
  let sbs = @mpf.mpf_sign(s.hi)
  if sas >= 0 {
    let lo = @mpf.mpf_pow_int(s.lo, n, prec, @mpf.round_floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = @mpf.mpf_pow_int(s.hi, n, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  if sbs <= 0 {
    let lo = @mpf.mpf_pow_int(s.hi, n, prec, @mpf.round_floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = @mpf.mpf_pow_int(s.lo, n, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  let neg_lo = @mpf.mpf_neg(s.lo, 0, @mpf.round_down)
  let hi = if @mpf.mpf_ge(neg_lo, s.hi) {
    @mpf.mpf_pow_int(neg_lo, n, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
  } else {
    @mpf.mpf_pow_int(s.hi, n, prec, @mpf.round_ceiling) catch {
      err => raise from_mpf_error(err)
    }
  }
  { lo: @mpf.fzero, hi }
}

///|
pub fn mpi_pow(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  if @mpf.mpf_eq(t.lo, t.hi) && @mpf.is_finite(t.lo) {
    if @mpf.is_zero(t.lo) {
      return mpi_one
    }
    match maybe_integer(t.lo) {
      Some(n) => return mpi_pow_int(s, n, prec)
      None => ()
    }
    if @mpf.mpf_eq(t.lo, fhalf) {
      return mpi_sqrt(s, prec)
    }
  }
  let u = mpi_log(s, prec + 20)
  let v = mpi_mul(u, t, prec=prec + 20)
  mpi_exp(v, prec)
}
