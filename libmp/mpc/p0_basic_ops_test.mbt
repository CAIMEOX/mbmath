///|
fn assert_mpc_eq_parts(
  z : RawMpc,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Unit raise {
  assert_true(@mpf.mpf_eq(z.real, re))
  assert_true(@mpf.mpf_eq(z.imag, im))
}

///|
test "p0 basic_ops add/sub/mul/div real-complex subset from mpmath" {
  let z = from_parts(@mpf.from_str("2.5"), @mpf.fzero)
  assert_mpc_eq_parts(
    mpc_add_mpf(z, @mpf.from_int(3), 120, @mpf.round_nearest),
    @mpf.from_str("5.5"),
    @mpf.fzero,
  )
  assert_mpc_eq_parts(
    mpc_sub_mpf(z, @mpf.from_int(3), 120, @mpf.round_nearest),
    @mpf.from_str("-0.5"),
    @mpf.fzero,
  )
  assert_mpc_eq_parts(
    mpc_mul_mpf(z, @mpf.from_int(3), 120, @mpf.round_nearest),
    @mpf.from_str("7.5"),
    @mpf.fzero,
  )
  assert_mpc_eq_parts(
    mpc_div_mpf(
      from_parts(@mpf.from_int(6), @mpf.fzero),
      @mpf.from_int(3),
      120,
      @mpf.round_nearest,
    ),
    @mpf.from_int(2),
    @mpf.fzero,
  )
}

///|
test "p0 basic_ops complex zeros multiplication grid from mpmath" {
  let vals : Array[Int] = [0, 2]
  let vals2 : Array[Int] = [0, 3]
  let vals3 : Array[Int] = [0, 4]
  let vals4 : Array[Int] = [0, 5]
  for a in vals {
    for b in vals2 {
      for c in vals3 {
        for d in vals4 {
          let z1 = from_parts(@mpf.from_int(a), @mpf.from_int(b))
          let z2 = from_parts(@mpf.from_int(c), @mpf.from_int(d))
          let m = mpc_mul(z1, z2, 140, @mpf.round_nearest)
          let exp_re = @mpf.from_int(a * c - b * d)
          let exp_im = @mpf.from_int(a * d + b * c)
          assert_mpc_eq_parts(m, exp_re, exp_im)
        }
      }
    }
  }
}

///|
test "p0 basic_ops power subset from mpmath" {
  let six = from_parts(@mpf.from_int(6), @mpf.fzero)
  assert_mpc_eq_parts(
    mpc_pow_int(six, 3, 160, @mpf.round_nearest),
    @mpf.from_int(216),
    @mpf.fzero,
  )
  let p = mpc_pow_mpf(six, @mpf.from_int(3), 160, @mpf.round_nearest)
  assert_mpc_eq_parts(p, @mpf.from_int(216), @mpf.fzero)
}

///|
test "p0 basic_ops reciprocal infinity subset from mpmath" {
  let z = from_parts(@mpf.finf, @mpf.fone)
  let r = mpc_reciprocal(z, 120, @mpf.round_nearest)
  assert_mpc_eq_parts(r, @mpf.fzero, @mpf.fzero)
  let w = from_parts(@mpf.from_int(2), @mpf.finf)
  let q = mpc_div(from_parts(@mpf.fone, @mpf.fone), w, 120, @mpf.round_nearest)
  assert_mpc_eq_parts(q, @mpf.fzero, @mpf.fzero)
}

///|
test "p0 basic_ops hash and equality subset from mpmath" {
  let z1 = from_parts(@mpf.from_int(2), @mpf.from_int(3))
  let z2 = from_parts(@mpf.from_int(2), @mpf.from_int(3))
  let z3 = from_parts(@mpf.from_int(3), @mpf.from_int(2))
  assert_eq(mpc_hash(z1), mpc_hash(z2))
  assert_not_eq(mpc_hash(z1), mpc_hash(z3))
}
