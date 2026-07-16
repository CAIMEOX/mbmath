///|
fn assert_mpc_eq_parts(
  z : RawMpc,
  re : @mpf.RawMpf,
  im : @mpf.RawMpf,
) -> Unit raise {
  assert_true(z.real == re)
  assert_true(z.imag == im)
}

///|
test "basic_ops add/sub/mul/div real-complex subset from mpmath" {
  let z = RawMpc::new(@mpf.RawMpf::parse("2.5"), @mpf.RawMpf::zero())
  assert_mpc_eq_parts(
    z.add_real(@mpf.RawMpf::from_int(3), 120, Nearest),
    @mpf.RawMpf::parse("5.5"),
    @mpf.RawMpf::zero(),
  )
  assert_mpc_eq_parts(
    z.sub_real(@mpf.RawMpf::from_int(3), 120, Nearest),
    @mpf.RawMpf::parse("-0.5"),
    @mpf.RawMpf::zero(),
  )
  assert_mpc_eq_parts(
    z.mul_real(@mpf.RawMpf::from_int(3), 120, Nearest),
    @mpf.RawMpf::parse("7.5"),
    @mpf.RawMpf::zero(),
  )
  assert_mpc_eq_parts(
    RawMpc::new(@mpf.RawMpf::from_int(6), @mpf.RawMpf::zero()).div_real(
      @mpf.RawMpf::from_int(3),
      120,
      Nearest,
    ),
    @mpf.RawMpf::from_int(2),
    @mpf.RawMpf::zero(),
  )
}

///|
test "basic_ops complex zeros multiplication grid from mpmath" {
  let vals : Array[Int] = [0, 2]
  let vals2 : Array[Int] = [0, 3]
  let vals3 : Array[Int] = [0, 4]
  let vals4 : Array[Int] = [0, 5]
  for a in vals {
    for b in vals2 {
      for c in vals3 {
        for d in vals4 {
          let z1 = RawMpc::new(
            @mpf.RawMpf::from_int(a),
            @mpf.RawMpf::from_int(b),
          )
          let z2 = RawMpc::new(
            @mpf.RawMpf::from_int(c),
            @mpf.RawMpf::from_int(d),
          )
          let m = z1.mul(z2, 140, Nearest)
          let exp_re = @mpf.RawMpf::from_int(a * c - b * d)
          let exp_im = @mpf.RawMpf::from_int(a * d + b * c)
          assert_mpc_eq_parts(m, exp_re, exp_im)
        }
      }
    }
  }
}

///|
test "basic_ops power subset from mpmath" {
  let six = RawMpc::new(@mpf.RawMpf::from_int(6), @mpf.RawMpf::zero())
  assert_mpc_eq_parts(
    six.pow_int(3, 160, Nearest),
    @mpf.RawMpf::from_int(216),
    @mpf.RawMpf::zero(),
  )
  let p = six.pow_real(@mpf.RawMpf::from_int(3), 160, Nearest)
  assert_mpc_eq_parts(p, @mpf.RawMpf::from_int(216), @mpf.RawMpf::zero())
}

///|
test "basic_ops reciprocal infinity subset from mpmath" {
  let z = RawMpc::new(@mpf.RawMpf::infinity(), @mpf.RawMpf::one())
  let r = z.reciprocal(120, Nearest)
  assert_mpc_eq_parts(r, @mpf.RawMpf::zero(), @mpf.RawMpf::zero())
  let w = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::infinity())
  let q = RawMpc::new(@mpf.RawMpf::one(), @mpf.RawMpf::one()).div(
    w,
    120,
    Nearest,
  )
  assert_mpc_eq_parts(q, @mpf.RawMpf::zero(), @mpf.RawMpf::zero())
}

///|
test "basic_ops hash and equality subset from mpmath" {
  let z1 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(3))
  let z2 = RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(3))
  let z3 = RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(2))
  @debug.assert_eq(z1.stable_hash(), z2.stable_hash())
  assert_not_eq(z1.stable_hash(), z3.stable_hash())
}
