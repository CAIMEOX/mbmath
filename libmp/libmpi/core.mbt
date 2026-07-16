///|
fn from_mpf_error(err : @mpf.MpfError) -> MpiError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    DivisionByZero(msg) => DomainError(msg)
    OverflowError(msg) => ValueError(msg)
    ParseError(msg) => ParseError(msg)
    FormatError(msg) => ValueError(msg)
    UnsupportedError(msg) => UnsupportedError(msg)
  }
}

///|
fn from_libelefun_error(err : @libelefun.LibElefunError) -> MpiError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    ComplexResult(msg) => DomainError(msg)
  }
}

///|
fn from_gammazeta_error(err : @gammazeta.GammaZetaError) -> MpiError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => DomainError(msg)
  }
}

///|
fn from_mpc_error(err : @mpc.MpcError) -> MpiError {
  match err {
    ValueError(msg) => ValueError(msg)
    DomainError(msg) => DomainError(msg)
    PoleError(msg) => DomainError(msg)
    ConvergenceError(msg) => ConvergenceError(msg)
  }
}

///|
fn elefun_pi_checked(
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.pi(prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_exp_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.exp(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_atan_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.atan(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_atan2_checked(
  y : @mpf.RawMpf,
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.atan2(y, x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_cos_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.cos(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
fn elefun_sin_checked(
  x : @mpf.RawMpf,
  prec : Int,
  rnd : @mpf.RoundMode,
) -> @mpf.RawMpf raise MpiError {
  @libelefun.sin(x, prec, rnd) catch {
    err => raise from_libelefun_error(err)
  }
}

///|
let fhalf : @mpf.RawMpf = @mpf.RawMpf::from_mantissa_exponent(1N, -1, 0, Down)

///|
fn maybe_integer(x : @mpf.RawMpf) -> Int? {
  if !x.is_finite() {
    return None
  }
  if x.is_zero() {
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
  if x == @mpf.RawMpf::from_int(signed_n) {
    Some(signed_n)
  } else {
    None
  }
}

///|
fn nan_to_lo(x : @mpf.RawMpf) -> @mpf.RawMpf {
  if x.is_nan() {
    @mpf.RawMpf::negative_infinity()
  } else {
    x
  }
}

///|
fn nan_to_hi(x : @mpf.RawMpf) -> @mpf.RawMpf {
  if x.is_nan() {
    @mpf.RawMpf::infinity()
  } else {
    x
  }
}

///|
pub fn RawMpi::new(lo : @mpf.RawMpf, hi : @mpf.RawMpf) -> RawMpi {
  if lo.is_nan() || hi.is_nan() {
    { lo: @mpf.RawMpf::negative_infinity(), hi: @mpf.RawMpf::infinity() }
  } else if lo <= hi {
    { lo, hi }
  } else {
    { lo: hi, hi: lo }
  }
}

///|
pub impl Neg for RawMpi with fn neg(x) {
  RawMpi::new(-x.hi, -x.lo)
}

///|
pub impl Hash for RawMpi with fn hash_combine(x, hasher) {
  hasher.combine(x.lo)
  hasher.combine(x.hi)
}

///|
pub fn RawMpi::point(x : @mpf.RawMpf) -> RawMpi {
  { lo: x, hi: x }
}

///|
pub fn RawMpi::strictly_less_than(
  s : RawMpi,
  t : RawMpi,
) -> Bool raise MpiError {
  if s.hi < t.lo {
    true
  } else if s.lo >= t.hi {
    false
  } else {
    raise UnorderedError(
      "RawMpi::strictly_less_than: overlapping intervals are unordered",
    )
  }
}

///|
pub fn RawMpi::less_or_equal(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  if s.hi <= t.lo {
    true
  } else if s.lo > t.hi {
    false
  } else {
    raise UnorderedError(
      "RawMpi::less_or_equal: overlapping intervals are unordered",
    )
  }
}

///|
pub fn RawMpi::strictly_greater_than(
  s : RawMpi,
  t : RawMpi,
) -> Bool raise MpiError {
  t.strictly_less_than(s)
}

///|
pub fn RawMpi::greater_or_equal(s : RawMpi, t : RawMpi) -> Bool raise MpiError {
  t.less_or_equal(s)
}

///|
pub fn RawMpi::overlaps(x : RawMpi, y : RawMpi) -> Bool {
  !(y.hi < x.lo || y.lo > x.hi)
}

///|
pub fn RawMpi::add(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  let a = nan_to_lo(s.lo.add(t.lo, prec, Floor))
  let b = nan_to_hi(s.hi.add(t.hi, prec, Ceiling))
  { lo: a, hi: b }
}

///|
pub fn RawMpi::sub(s : RawMpi, t : RawMpi, prec? : Int = 0) -> RawMpi {
  let a = nan_to_lo(s.lo.sub(t.hi, prec, Floor))
  let b = nan_to_hi(s.hi.sub(t.lo, prec, Ceiling))
  { lo: a, hi: b }
}

///|
pub fn RawMpi::width(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  s.hi.sub(s.lo, prec, Up)
}

///|
pub fn RawMpi::midpoint(s : RawMpi, prec : Int) -> @mpf.RawMpf {
  s.lo.add(s.hi, prec, Nearest).scale_pow2(-1)
}

///|
pub fn RawMpi::rounded(s : RawMpi, prec : Int) -> RawMpi {
  { lo: s.lo.rounded(prec, Floor), hi: s.hi.rounded(prec, Ceiling) }
}

///|
pub fn RawMpi::negated(s : RawMpi, prec? : Int = 0) -> RawMpi {
  { lo: s.hi.negated(prec, Floor), hi: s.lo.negated(prec, Ceiling) }
}

///|
pub fn RawMpi::abs(s : RawMpi, prec? : Int = 0) -> RawMpi {
  let sas = s.lo.signum()
  let sbs = s.hi.signum()
  if sas >= 0 {
    return { lo: s.lo.rounded(prec, Floor), hi: s.hi.rounded(prec, Ceiling) }
  }
  if sbs >= 0 {
    let neg_lo = s.lo.negated(0, Down)
    let hi = if neg_lo < s.hi {
      s.hi.rounded(prec, Ceiling)
    } else {
      neg_lo.rounded(prec, Ceiling)
    }
    return { lo: @mpf.RawMpf::zero(), hi }
  }
  { lo: s.hi.negated(prec, Floor), hi: s.lo.negated(prec, Ceiling) }
}

///|
pub fn RawMpi::mul_real(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  s.mul({ lo: t, hi: t }, prec~)
}

///|
pub fn RawMpi::div_real(
  s : RawMpi,
  t : @mpf.RawMpf,
  prec : Int,
) -> RawMpi raise MpiError {
  s.div({ lo: t, hi: t }, prec)
}

///|
pub fn RawMpi::mul(
  s : RawMpi,
  t : RawMpi,
  prec? : Int = 0,
) -> RawMpi raise MpiError {
  let sas = s.lo.signum()
  let sbs = s.hi.signum()
  let tas = t.lo.signum()
  let tbs = t.hi.signum()
  if sas == 0 && sbs == 0 {
    if t.lo == @mpf.RawMpf::negative_infinity() ||
      t.hi == @mpf.RawMpf::infinity() {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
    return RawMpi::zero()
  }
  if tas == 0 && tbs == 0 {
    if s.lo == @mpf.RawMpf::negative_infinity() ||
      s.hi == @mpf.RawMpf::infinity() {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
    return RawMpi::zero()
  }
  if sas >= 0 {
    if tas >= 0 {
      let a = s.lo.mul(t.lo, prec, Floor)
      let b = s.hi.mul(t.hi, prec, Ceiling)
      return {
        lo: if a.is_nan() {
          @mpf.RawMpf::zero()
        } else {
          a
        },
        hi: if b.is_nan() {
          @mpf.RawMpf::infinity()
        } else {
          b
        },
      }
    }
    if tbs <= 0 {
      let a = s.hi.mul(t.lo, prec, Floor)
      let b = s.lo.mul(t.hi, prec, Ceiling)
      return {
        lo: if a.is_nan() {
          @mpf.RawMpf::negative_infinity()
        } else {
          a
        },
        hi: if b.is_nan() {
          @mpf.RawMpf::zero()
        } else {
          b
        },
      }
    }
    let a = s.hi.mul(t.lo, prec, Floor)
    let b = s.hi.mul(t.hi, prec, Ceiling)
    return {
      lo: if a.is_nan() {
        @mpf.RawMpf::negative_infinity()
      } else {
        a
      },
      hi: if b.is_nan() {
        @mpf.RawMpf::infinity()
      } else {
        b
      },
    }
  }
  if sbs <= 0 {
    if tas >= 0 {
      let a = s.lo.mul(t.hi, prec, Floor)
      let b = s.hi.mul(t.lo, prec, Ceiling)
      return {
        lo: if a.is_nan() {
          @mpf.RawMpf::negative_infinity()
        } else {
          a
        },
        hi: if b.is_nan() {
          @mpf.RawMpf::zero()
        } else {
          b
        },
      }
    }
    if tbs <= 0 {
      let a = s.hi.mul(t.hi, prec, Floor)
      let b = s.lo.mul(t.lo, prec, Ceiling)
      return {
        lo: if a.is_nan() {
          @mpf.RawMpf::zero()
        } else {
          a
        },
        hi: if b.is_nan() {
          @mpf.RawMpf::infinity()
        } else {
          b
        },
      }
    }
    let a = s.lo.mul(t.hi, prec, Floor)
    let b = s.lo.mul(t.lo, prec, Ceiling)
    return {
      lo: if a.is_nan() {
        @mpf.RawMpf::negative_infinity()
      } else {
        a
      },
      hi: if b.is_nan() {
        @mpf.RawMpf::infinity()
      } else {
        b
      },
    }
  }
  let cases : Array[@mpf.RawMpf] = [
    s.lo.mul(t.lo, 0, Down),
    s.lo.mul(t.hi, 0, Down),
    s.hi.mul(t.lo, 0, Down),
    s.hi.mul(t.hi, 0, Down),
  ]
  for v in cases {
    if v.is_nan() {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
  }
  let (mn, mx) = @mpf.RawMpf::min_max(cases) catch {
    err => raise from_mpf_error(err)
  }
  { lo: mn.rounded(prec, Floor), hi: mx.rounded(prec, Ceiling) }
}

///|
pub fn RawMpi::square(s : RawMpi, prec? : Int = 0) -> RawMpi raise MpiError {
  if s.lo >= @mpf.RawMpf::zero() {
    return {
      lo: s.lo.mul(s.lo, prec, Floor),
      hi: s.hi.mul(s.hi, prec, Ceiling),
    }
  }
  if s.hi <= @mpf.RawMpf::zero() {
    return {
      lo: s.hi.mul(s.hi, prec, Floor),
      hi: s.lo.mul(s.lo, prec, Ceiling),
    }
  }
  let neg_lo = s.lo.negated(0, Down)
  let (_, mx) = @mpf.RawMpf::min_max([neg_lo, s.hi]) catch {
    err => raise from_mpf_error(err)
  }
  { lo: @mpf.RawMpf::zero(), hi: mx.mul(mx, prec, Ceiling) }
}

///|
pub fn RawMpi::div(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let sas = s.lo.signum()
  let sbs = s.hi.signum()
  let tas = t.lo.signum()
  let tbs = t.hi.signum()
  if sas == 0 && sbs == 0 {
    if (tas < 0 && tbs > 0) || tas == 0 || tbs == 0 {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
    return RawMpi::zero()
  }
  if tas < 0 && tbs > 0 {
    return { lo: @mpf.RawMpf::negative_infinity(), hi: @mpf.RawMpf::infinity() }
  }
  if tas < 0 {
    return s.negated().div(t.negated(), prec)
  }
  if tas == 0 {
    if sas < 0 && sbs > 0 {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
    if tas == tbs {
      return {
        lo: @mpf.RawMpf::negative_infinity(),
        hi: @mpf.RawMpf::infinity(),
      }
    }
    if sas >= 0 {
      let lo = s.lo.div(t.hi, prec, Floor) catch {
        err => raise from_mpf_error(err)
      }
      return { lo, hi: @mpf.RawMpf::infinity() }
    }
    let hi = s.hi.div(t.hi, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo: @mpf.RawMpf::negative_infinity(), hi }
  }
  if sas >= 0 {
    let a = s.lo.div(t.hi, prec, Floor) catch {
      err => raise from_mpf_error(err)
    }
    let b = s.hi.div(t.lo, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return {
      lo: if a.is_nan() {
        @mpf.RawMpf::zero()
      } else {
        a
      },
      hi: if b.is_nan() {
        @mpf.RawMpf::infinity()
      } else {
        b
      },
    }
  }
  if sbs <= 0 {
    let a = s.lo.div(t.lo, prec, Floor) catch {
      err => raise from_mpf_error(err)
    }
    let b = s.hi.div(t.hi, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return {
      lo: if a.is_nan() {
        @mpf.RawMpf::negative_infinity()
      } else {
        a
      },
      hi: if b.is_nan() {
        @mpf.RawMpf::zero()
      } else {
        b
      },
    }
  }
  let a = s.lo.div(t.lo, prec, Floor) catch { err => raise from_mpf_error(err) }
  let b = s.hi.div(t.lo, prec, Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  {
    lo: if a.is_nan() {
      @mpf.RawMpf::negative_infinity()
    } else {
      a
    },
    hi: if b.is_nan() {
      @mpf.RawMpf::infinity()
    } else {
      b
    },
  }
}

///|
pub fn RawMpi::pi(prec : Int) -> RawMpi raise MpiError {
  { lo: elefun_pi_checked(prec, Floor), hi: elefun_pi_checked(prec, Ceiling) }
}

///|
pub fn RawMpi::exp(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  {
    lo: elefun_exp_checked(s.lo, prec, Floor),
    hi: elefun_exp_checked(s.hi, prec, Ceiling),
  }
}

///|
pub fn RawMpi::log(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let lo = @libelefun.ln(s.lo, prec, Floor) catch {
    err => raise from_libelefun_error(err)
  }
  let hi = @libelefun.ln(s.hi, prec, Ceiling) catch {
    err => raise from_libelefun_error(err)
  }
  { lo, hi }
}

///|
pub fn RawMpi::sqrt(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  let lo = s.lo.sqrt(prec, Floor) catch { err => raise from_mpf_error(err) }
  let hi = s.hi.sqrt(prec, Ceiling) catch { err => raise from_mpf_error(err) }
  { lo, hi }
}

///|
pub fn RawMpi::atan(s : RawMpi, prec : Int) -> RawMpi raise MpiError {
  {
    lo: elefun_atan_checked(s.lo, prec, Floor),
    hi: elefun_atan_checked(s.hi, prec, Ceiling),
  }
}

///|
pub fn RawMpi::pow_int(
  s : RawMpi,
  n : Int,
  prec : Int,
) -> RawMpi raise MpiError {
  if n < 0 {
    return RawMpi::one().div(s.pow_int(-n, prec + 20), prec)
  }
  if n == 0 {
    return RawMpi::one()
  }
  if n == 1 {
    return s
  }
  if n == 2 {
    return s.square(prec~)
  }
  if (n & 1) == 1 {
    let lo = s.lo.pow_int(n, prec, Floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = s.hi.pow_int(n, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  let sas = s.lo.signum()
  let sbs = s.hi.signum()
  if sas >= 0 {
    let lo = s.lo.pow_int(n, prec, Floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = s.hi.pow_int(n, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  if sbs <= 0 {
    let lo = s.hi.pow_int(n, prec, Floor) catch {
      err => raise from_mpf_error(err)
    }
    let hi = s.lo.pow_int(n, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
    return { lo, hi }
  }
  let neg_lo = s.lo.negated(0, Down)
  let hi = if neg_lo >= s.hi {
    neg_lo.pow_int(n, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
  } else {
    s.hi.pow_int(n, prec, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
  }
  { lo: @mpf.RawMpf::zero(), hi }
}

///|
pub fn RawMpi::pow(s : RawMpi, t : RawMpi, prec : Int) -> RawMpi raise MpiError {
  if t.lo == t.hi && t.lo.is_finite() {
    if t.lo.is_zero() {
      return RawMpi::one()
    }
    match maybe_integer(t.lo) {
      Some(n) => return s.pow_int(n, prec)
      None => ()
    }
    if t.lo == fhalf {
      return s.sqrt(prec)
    }
  }
  let u = s.log(prec + 20)
  let v = u.mul(t, prec=prec + 20)
  v.exp(prec)
}
