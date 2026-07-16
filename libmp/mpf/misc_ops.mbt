///|
let py_hash_modulus : BigInt = 2305843009213693951N

///|
let py_hash_bits : Int = 61

///|
let py_hash_inf : Int = 314159

///|
let py_hash_nan : Int = 0

///|
let mpf_rand_gen : @random.Rand = @random.Rand::new()

///|
fn hash_exp_shift(exp : Int) -> Int {
  if exp >= 0 {
    exp % py_hash_bits
  } else {
    py_hash_bits - 1 - (-1 - exp) % py_hash_bits
  }
}

///|
pub fn RawMpf::frexp(x : RawMpf) -> (RawMpf, Int) raise MpfError {
  if x.is_zero() {
    (RawMpf::zero(), 0)
  } else if !x.is_finite() {
    raise DomainError("RawMpf::frexp: non-finite input")
  } else {
    let n = x.bc + x.exp
    (x.scale_pow2(-n), n)
  }
}

///|
pub fn RawMpf::stable_hash(x : RawMpf) -> Int {
  if x.is_nan() {
    return py_hash_nan
  }
  if x == RawMpf::infinity() {
    return py_hash_inf
  }
  if x == RawMpf::negative_infinity() {
    return -py_hash_inf
  }
  if x.is_zero() {
    return 0
  }
  let mut h = x.man % py_hash_modulus
  let shift = hash_exp_shift(x.exp)
  h = (h << shift) % py_hash_modulus
  if x.sign == 1 {
    h = -h
  }
  if h == -1N {
    -2
  } else {
    h.to_int()
  }
}

///|
pub impl Hash for RawMpf with fn hash(x) {
  x.stable_hash()
}

///|
pub impl Hash for RawMpf with fn hash_combine(x, hasher) {
  hasher.combine_int(x.stable_hash())
}

///|
pub fn RawMpf::perturb(
  x : RawMpf,
  eps_sign : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if rnd == Nearest {
    return x.rounded(prec, rnd)
  }
  let perturb_sign = if eps_sign == 0 { 0 } else { 1 }
  let eps : RawMpf = {
    sign: perturb_sign,
    man: 1N,
    exp: x.exp + x.bc - prec - 1,
    bc: 1,
  }
  let eps_is_negative = perturb_sign == 1
  let away = if x.sign == 1 {
    (rnd == Down || rnd == Ceiling) != eps_is_negative
  } else {
    (rnd == Up || rnd == Ceiling) != eps_is_negative
  }
  if away {
    x.add(eps, prec, rnd)
  } else {
    x.rounded(prec, rnd)
  }
}

///|
pub fn RawMpf::random(prec : Int) -> RawMpf {
  if prec <= 0 {
    return RawMpf::zero()
  }
  let man = mpf_rand_gen.bigint(prec)
  RawMpf::from_mantissa_exponent(man, -prec, prec, Floor)
}
