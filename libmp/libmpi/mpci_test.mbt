///|
fn point_ci(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpci {
  RawMpci::new(RawMpi::point(real), RawMpi::point(imag))
}

///|
fn assert_mpci_contains(z : RawMpci, w : @mpc.RawMpc) -> Unit raise {
  assert_true(z.contains_point(w.real, w.imag))
}

///|
fn assert_mpi_contains(x : RawMpi, v : @mpf.RawMpf) -> Unit raise {
  assert_true(x.lo <= v)
  assert_true(x.hi >= v)
}

///|
fn assert_mpci_loggamma_corners_enclosed(
  z : RawMpci,
  prec : Int,
  label : String,
) -> Unit raise {
  let lg = z.loggamma(prec)
  let p00 = @mpc.RawMpc::new(z.real.lo, z.imag.lo).loggamma(prec, Nearest)
  if !lg.contains_point(p00.real, p00.imag) {
    fail("loggamma enclosure failed at corner (lo,lo): \{label}")
  }
  let p10 = @mpc.RawMpc::new(z.real.hi, z.imag.lo).loggamma(prec, Nearest)
  if !lg.contains_point(p10.real, p10.imag) {
    fail("loggamma enclosure failed at corner (hi,lo): \{label}")
  }
  let p01 = @mpc.RawMpc::new(z.real.lo, z.imag.hi).loggamma(prec, Nearest)
  if !lg.contains_point(p01.real, p01.imag) {
    fail("loggamma enclosure failed at corner (lo,hi): \{label}")
  }
  let p11 = @mpc.RawMpc::new(z.real.hi, z.imag.hi).loggamma(prec, Nearest)
  if !lg.contains_point(p11.real, p11.imag) {
    fail("loggamma enclosure failed at corner (hi,hi): \{label}")
  }
  if z.imag.lo <= @mpf.RawMpf::zero() && z.imag.hi >= @mpf.RawMpf::zero() {
    let pr0 = @mpc.RawMpc::new(z.real.lo, @mpf.RawMpf::zero()).loggamma(
      prec,
      Nearest,
    )
    if !lg.contains_point(pr0.real, pr0.imag) {
      fail("loggamma enclosure failed at real-axis (lo,0): \{label}")
    }
    let pr1 = @mpc.RawMpc::new(z.real.hi, @mpf.RawMpf::zero()).loggamma(
      prec,
      Nearest,
    )
    if !lg.contains_point(pr1.real, pr1.imag) {
      fail("loggamma enclosure failed at real-axis (hi,0): \{label}")
    }
  }
}

///|
test "mpci basic arithmetic encloses mpc point results" {
  let z = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("1.25"),
    @mpf.RawMpf::parse("-2.5"),
  )
  let w = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("0.75"),
    @mpf.RawMpf::parse("3.0"),
  )
  let zi = point_ci(z.real, z.imag)
  let wi = point_ci(w.real, w.imag)
  let add_iv = zi.add(wi, 120)
  let add_ref = z.add(w, 120, Nearest)
  assert_mpci_contains(add_iv, add_ref)
  let sub_iv = zi.sub(wi, 120)
  let sub_ref = z.sub(w, 120, Nearest)
  assert_mpci_contains(sub_iv, sub_ref)
  let mul_iv = zi.mul(wi, 120)
  let mul_ref = z.mul(w, 120, Nearest)
  assert_mpci_contains(mul_iv, mul_ref)
  let div_iv = zi.div(wi, 120)
  let div_ref = z.div(w, 120, Nearest)
  assert_mpci_contains(div_iv, div_ref)
}

///|
test "mpci constructors and unary" {
  let z = RawMpci::new(interval(1, 2), interval(-3, -2))
  assert_true(
    z.contains_point(@mpf.RawMpf::parse("1.5"), @mpf.RawMpf::parse("-2.5")),
  )
  let p = z.rounded(80)
  @debug.assert_eq(p, z)
  let n = z.negated(80)
  assert_true(
    n.contains_point(@mpf.RawMpf::parse("-1.5"), @mpf.RawMpf::parse("2.5")),
  )
}

///|
test "mpci interval multiplication and division subset" {
  let z = RawMpci::new(interval(1, 2), interval(3, 4))
  let w = RawMpci::new(interval(2, 3), interval(-2, -1))
  let m = z.mul(w, 100)
  assert_true(m.real.lo <= @mpf.RawMpf::from_int(5))
  assert_true(m.real.hi >= @mpf.RawMpf::from_int(14))
  assert_true(m.imag.lo <= @mpf.RawMpf::from_int(2))
  assert_true(m.imag.hi >= @mpf.RawMpf::from_int(11))
  let q = z.div(
    point_ci(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(0)),
    100,
  )
  assert_true(
    q.contains_point(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::parse("1.5")),
  )
  assert_true(
    q.contains_point(@mpf.RawMpf::parse("1.0"), @mpf.RawMpf::parse("2.0")),
  )
}

///|
test "mpci advanced functions enclose mpc results" {
  let z = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("1.25"),
    @mpf.RawMpf::parse("-0.75"),
  )
  let zi = point_ci(z.real, z.imag)
  let e_iv = zi.exp(140)
  assert_mpci_contains(e_iv, z.exp(140, Nearest))
  let s_iv = zi.sin(140)
  assert_mpci_contains(s_iv, z.sin(140, Nearest))
  let c_iv = zi.cos(140)
  assert_mpci_contains(c_iv, z.cos(140, Nearest))
  let sq_iv = zi.square(140)
  assert_mpci_contains(sq_iv, z.square(140, Nearest))
  let cube_interval = zi.pow_int(3, 140)
  assert_mpci_contains(cube_interval, z.pow_int(3, 140, Nearest))
  let w = @mpc.RawMpc::new(@mpf.RawMpf::parse("0.5"), @mpf.RawMpf::parse("1.0"))
  let wi = point_ci(w.real, w.imag)
  let p_iv = zi.pow(wi, 140)
  assert_mpci_contains(p_iv, z.pow(w, 140, Nearest))
}

///|
test "mpci abs arg log subset" {
  let z = @mpc.RawMpc::new(@mpf.RawMpf::from_int(3), @mpf.RawMpf::from_int(4))
  let zi = point_ci(z.real, z.imag)
  let a = zi.abs(140)
  assert_mpi_contains(a, z.abs(140, Nearest))
  let arg = zi.arg(140)
  assert_mpi_contains(arg, z.arg(140, Nearest))
  let l_iv = zi.log(140)
  assert_mpci_contains(l_iv, z.log(140, Nearest))
}

///|
test "mpci gamma family encloses mpc points" {
  let z = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("1.25"),
    @mpf.RawMpf::parse("-0.75"),
  )
  let zi = point_ci(z.real, z.imag)
  let g = zi.gamma(180)
  let g_ref = z.gamma(180, Nearest)
  assert_true(g.contains_point(g_ref.real, g_ref.imag))
  let rg = zi.rgamma(180)
  let rg_ref = z.rgamma(180, Nearest)
  assert_true(rg.contains_point(rg_ref.real, rg_ref.imag))
  let lg = zi.loggamma(180)
  let lg_ref = z.loggamma(180, Nearest)
  assert_true(lg.contains_point(lg_ref.real, lg_ref.imag))
  let f = zi.factorial(180)
  let f_ref = z.factorial(180, Nearest)
  assert_true(f.contains_point(f_ref.real, f_ref.imag))
}

///|
test "mpci gamma cross real axis near poles subset" {
  let iv = RawMpci::new(
    RawMpi::new(@mpf.RawMpf::parse("-2.4"), @mpf.RawMpf::parse("-1.6")),
    RawMpi::new(@mpf.RawMpf::parse("-0.2"), @mpf.RawMpf::parse("0.2")),
  )
  let g = iv.gamma(200)
  let z1 = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("-2.3"),
    @mpf.RawMpf::parse("0.1"),
  )
  let z2 = @mpc.RawMpc::new(
    @mpf.RawMpf::parse("-1.7"),
    @mpf.RawMpf::parse("-0.1"),
  )
  assert_mpci_contains(g, z1.gamma(200, Nearest))
  assert_mpci_contains(g, z2.gamma(200, Nearest))
  let lg = iv.loggamma(200)
  assert_mpci_contains(lg, z1.loggamma(200, Nearest))
  assert_mpci_contains(lg, z2.loggamma(200, Nearest))
  let rg = iv.rgamma(200)
  assert_mpci_contains(rg, z1.rgamma(200, Nearest))
  assert_mpci_contains(rg, z2.rgamma(200, Nearest))
}

///|
test "mpci loggamma corner-enclosure subset from mpmath interval tests" {
  let p = 220
  let boxes : Array[RawMpci] = [
    RawMpci::new(interval(2, 3), interval(1, 4)),
    RawMpci::new(interval(2, 3), interval(-4, -1)),
    RawMpci::new(interval(2, 3), interval(-1, 4)),
    RawMpci::new(interval(2, 3), interval(-4, 1)),
    RawMpci::new(interval(2, 3), interval(-4, 4)),
    RawMpci::new(interval(-3, -2), interval(2, 4)),
    RawMpci::new(interval(-3, -2), interval(-4, -2)),
  ]
  for i, box in boxes {
    assert_mpci_loggamma_corners_enclosed(box, p, "\{i}")
  }
}

///|
test "mpci arg quadrant subset from mpmath interval tests" {
  let p = 200
  let z1 = RawMpci::new(interval(-2, -1), interval(3, 4))
  let t1 = z1.arg(p)
  assert_mpi_contains(
    t1,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t1,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::from_int(4)).arg(
      p,
      Nearest,
    ),
  )
  let z2 = RawMpci::new(interval(-2, -1), interval(-4, -3))
  let t2 = z2.arg(p)
  assert_mpi_contains(
    t2,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(-3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t2,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::from_int(-4)).arg(
      p,
      Nearest,
    ),
  )
  let pi = @libelefun.pi(p, Nearest)
  let z3 = RawMpci::new(interval(-2, -1), interval(-3, 3))
  let t3 = z3.arg(p)
  assert_mpi_contains(t3, pi)
  assert_mpi_contains(t3, pi.negated(0, Down))
  let z4 = RawMpci::new(interval(-2, 2), interval(-3, 3))
  let t4 = z4.arg(p)
  assert_mpi_contains(t4, pi)
  assert_mpi_contains(t4, pi.negated(0, Down))
}

///|
test "mpci arg extended quadrant subset from mpmath interval tests" {
  let p = 200
  let z1 = RawMpci::new(interval(-2, 1), interval(3, 4))
  let t1 = z1.arg(p)
  assert_mpi_contains(
    t1,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t1,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(3)).arg(
      p,
      Nearest,
    ),
  )
  let z2 = RawMpci::new(interval(1, 2), interval(3, 4))
  let t2 = z2.arg(p)
  assert_mpi_contains(
    t2,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t2,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(4)).arg(
      p,
      Nearest,
    ),
  )
  let z3 = RawMpci::new(interval(1, 2), interval(-2, 3))
  let t3 = z3.arg(p)
  assert_mpi_contains(
    t3,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(-2)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t3,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(3)).arg(
      p,
      Nearest,
    ),
  )
  let z4 = RawMpci::new(interval(1, 2), interval(-4, -3))
  let t4 = z4.arg(p)
  assert_mpi_contains(
    t4,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(1), @mpf.RawMpf::from_int(-4)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t4,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(-3)).arg(
      p,
      Nearest,
    ),
  )
  let z5 = RawMpci::new(interval(-1, 2), interval(-4, -3))
  let t5 = z5.arg(p)
  assert_mpi_contains(
    t5,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::from_int(-3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t5,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(-3)).arg(
      p,
      Nearest,
    ),
  )
  let z6 = RawMpci::new(interval(-2, -1), interval(-4, -3))
  let t6 = z6.arg(p)
  assert_mpi_contains(
    t6,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-2), @mpf.RawMpf::from_int(-3)).arg(
      p,
      Nearest,
    ),
  )
  assert_mpi_contains(
    t6,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(-1), @mpf.RawMpf::from_int(-4)).arg(
      p,
      Nearest,
    ),
  )
}

///|
test "mpci abs and pow_int extended subset from mpmath interval tests" {
  @debug.assert_eq(
    RawMpci::new(RawMpi::zero(), interval(2, 3)).abs(160),
    interval(2, 3),
  )
  let a1 = RawMpci::new(RawMpi::zero(), interval(-3, 2)).abs(160)
  assert_mpi_contains(a1, @mpf.RawMpf::zero())
  assert_mpi_contains(a1, @mpf.RawMpf::from_int(3))
  let a2 = RawMpci::new(interval(3, 5), interval(4, 12)).abs(160)
  assert_mpi_contains(a2, @mpf.RawMpf::from_int(5))
  assert_mpi_contains(a2, @mpf.RawMpf::from_int(13))
  let a3 = RawMpci::new(interval(3, 5), interval(-4, 12)).abs(160)
  assert_mpi_contains(a3, @mpf.RawMpf::from_int(3))
  assert_mpi_contains(a3, @mpf.RawMpf::from_int(13))
  let z = point_ci(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(2))
  let p1 = z.pow_int(-1, 180)
  assert_mpci_contains(
    p1,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(2)).pow_int(
      -1,
      180,
      Nearest,
    ),
  )
  let p2 = z.pow_int(-2, 180)
  assert_mpci_contains(
    p2,
    @mpc.RawMpc::new(@mpf.RawMpf::from_int(2), @mpf.RawMpf::from_int(2)).pow_int(
      -2,
      180,
      Nearest,
    ),
  )
}
