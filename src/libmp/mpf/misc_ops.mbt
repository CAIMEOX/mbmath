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
pub fn mpf_frexp(x : RawMpf) -> (RawMpf, Int) {
  if is_zero(x) {
    (fzero, 0)
  } else if !is_finite(x) {
    abort("mpf_frexp: non-finite input")
  } else {
    let n = x.bc + x.exp
    (mpf_shift(x, -n), n)
  }
}

///|
pub fn mpf_hash(x : RawMpf) -> Int {
  if is_nan(x) {
    return py_hash_nan
  }
  if x == finf {
    return py_hash_inf
  }
  if x == fninf {
    return -py_hash_inf
  }
  if is_zero(x) {
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
pub fn mpf_perturb(
  x : RawMpf,
  eps_sign : Int,
  prec : Int,
  rnd : RoundMode,
) -> RawMpf {
  if rnd == round_nearest {
    return mpf_pos(x, prec, rnd)
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
    (rnd == round_down || rnd == round_ceiling) != eps_is_negative
  } else {
    (rnd == round_up || rnd == round_ceiling) != eps_is_negative
  }
  if away {
    mpf_add(x, eps, prec, rnd)
  } else {
    mpf_pos(x, prec, rnd)
  }
}

///|
pub fn mpf_rand(prec : Int) -> RawMpf {
  if prec <= 0 {
    return fzero
  }
  let man = mpf_rand_gen.bigint(prec)
  from_man_exp(man, -prec, prec, round_floor)
}
