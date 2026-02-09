///|
fn point_ci(real : @mpf.RawMpf, imag : @mpf.RawMpf) -> RawMpci {
  mpci_make(mpi_from_mpf(real), mpi_from_mpf(imag))
}

///|
fn assert_mpci_contains(z : RawMpci, w : @mpc.RawMpc) -> Unit raise {
  assert_true(mpci_contains_mpf(z, w.real, w.imag))
}

///|
fn assert_mpi_contains(x : RawMpi, v : @mpf.RawMpf) -> Unit raise {
  assert_true(@mpf.mpf_le(x.lo, v))
  assert_true(@mpf.mpf_ge(x.hi, v))
}

///|
test "mpci basic arithmetic encloses mpc point results" {
  let z = @mpc.from_parts(@mpf.from_str("1.25"), @mpf.from_str("-2.5"))
  let w = @mpc.from_parts(@mpf.from_str("0.75"), @mpf.from_str("3.0"))
  let zi = point_ci(z.real, z.imag)
  let wi = point_ci(w.real, w.imag)
  let add_iv = mpci_add(zi, wi, 120)
  let add_ref = @mpc.mpc_add(z, w, 120, @mpf.round_nearest)
  assert_mpci_contains(add_iv, add_ref)
  let sub_iv = mpci_sub(zi, wi, 120)
  let sub_ref = @mpc.mpc_sub(z, w, 120, @mpf.round_nearest)
  assert_mpci_contains(sub_iv, sub_ref)
  let mul_iv = mpci_mul(zi, wi, 120)
  let mul_ref = @mpc.mpc_mul(z, w, 120, @mpf.round_nearest)
  assert_mpci_contains(mul_iv, mul_ref)
  let div_iv = mpci_div(zi, wi, 120)
  let div_ref = @mpc.mpc_div(z, w, 120, @mpf.round_nearest)
  assert_mpci_contains(div_iv, div_ref)
}

///|
test "mpci constructors and unary" {
  let z = mpci_make(interval(1, 2), interval(-3, -2))
  assert_true(mpci_contains_mpf(z, @mpf.from_str("1.5"), @mpf.from_str("-2.5")))
  let p = mpci_pos(z, 80)
  assert_eq(p, z)
  let n = mpci_neg(z, 80)
  assert_true(mpci_contains_mpf(n, @mpf.from_str("-1.5"), @mpf.from_str("2.5")))
}

///|
test "mpci interval multiplication and division subset" {
  let z = mpci_make(interval(1, 2), interval(3, 4))
  let w = mpci_make(interval(2, 3), interval(-2, -1))
  let m = mpci_mul(z, w, 100)
  assert_true(@mpf.mpf_le(m.real.lo, @mpf.from_int(5)))
  assert_true(@mpf.mpf_ge(m.real.hi, @mpf.from_int(14)))
  assert_true(@mpf.mpf_le(m.imag.lo, @mpf.from_int(2)))
  assert_true(@mpf.mpf_ge(m.imag.hi, @mpf.from_int(11)))
  let q = mpci_div(z, point_ci(@mpf.from_int(2), @mpf.from_int(0)), 100)
  assert_true(mpci_contains_mpf(q, @mpf.from_str("0.5"), @mpf.from_str("1.5")))
  assert_true(mpci_contains_mpf(q, @mpf.from_str("1.0"), @mpf.from_str("2.0")))
}

///|
test "mpci advanced functions enclose mpc results" {
  let z = @mpc.from_parts(@mpf.from_str("1.25"), @mpf.from_str("-0.75"))
  let zi = point_ci(z.real, z.imag)
  let e_iv = mpci_exp(zi, 140)
  assert_mpci_contains(e_iv, @mpc.mpc_exp(z, 140, @mpf.round_nearest))
  let s_iv = mpci_sin(zi, 140)
  assert_mpci_contains(s_iv, @mpc.mpc_sin(z, 140, @mpf.round_nearest))
  let c_iv = mpci_cos(zi, 140)
  assert_mpci_contains(c_iv, @mpc.mpc_cos(z, 140, @mpf.round_nearest))
  let sq_iv = mpci_square(zi, 140)
  assert_mpci_contains(sq_iv, @mpc.mpc_square(z, 140, @mpf.round_nearest))
  let p3_iv = mpci_pow_int(zi, 3, 140)
  assert_mpci_contains(p3_iv, @mpc.mpc_pow_int(z, 3, 140, @mpf.round_nearest))
  let w = @mpc.from_parts(@mpf.from_str("0.5"), @mpf.from_str("1.0"))
  let wi = point_ci(w.real, w.imag)
  let p_iv = mpci_pow(zi, wi, 140)
  assert_mpci_contains(p_iv, @mpc.mpc_pow(z, w, 140, @mpf.round_nearest))
}

///|
test "mpci abs arg log subset" {
  let z = @mpc.from_parts(@mpf.from_int(3), @mpf.from_int(4))
  let zi = point_ci(z.real, z.imag)
  let a = mpci_abs(zi, 140)
  assert_mpi_contains(a, @mpc.mpc_abs(z, 140, @mpf.round_nearest))
  let arg = mpci_arg(zi, 140)
  assert_mpi_contains(arg, @mpc.mpc_arg(z, 140, @mpf.round_nearest))
  let l_iv = mpci_log(zi, 140)
  assert_mpci_contains(l_iv, @mpc.mpc_log(z, 140, @mpf.round_nearest))
}

///|
test "mpci gamma family encloses mpc points" {
  let z = @mpc.from_parts(@mpf.from_str("1.25"), @mpf.from_str("-0.75"))
  let zi = point_ci(z.real, z.imag)
  let g = mpci_gamma(zi, 180)
  let g_ref = @mpc.mpc_gamma(z, 180, @mpf.round_nearest)
  assert_true(mpci_contains_mpf(g, g_ref.real, g_ref.imag))
  let rg = mpci_rgamma(zi, 180)
  let rg_ref = @mpc.mpc_rgamma(z, 180, @mpf.round_nearest)
  assert_true(mpci_contains_mpf(rg, rg_ref.real, rg_ref.imag))
  let lg = mpci_loggamma(zi, 180)
  let lg_ref = @mpc.mpc_loggamma(z, 180, @mpf.round_nearest)
  assert_true(mpci_contains_mpf(lg, lg_ref.real, lg_ref.imag))
  let f = mpci_factorial(zi, 180)
  let f_ref = @mpc.mpc_factorial(z, 180, @mpf.round_nearest)
  assert_true(mpci_contains_mpf(f, f_ref.real, f_ref.imag))
}

///|
test "mpci gamma cross real axis near poles subset" {
  let iv = mpci_make(
    mpi_make(@mpf.from_str("-2.4"), @mpf.from_str("-1.6")),
    mpi_make(@mpf.from_str("-0.2"), @mpf.from_str("0.2")),
  )
  let g = mpci_gamma(iv, 200)
  let z1 = @mpc.from_parts(@mpf.from_str("-2.3"), @mpf.from_str("0.1"))
  let z2 = @mpc.from_parts(@mpf.from_str("-1.7"), @mpf.from_str("-0.1"))
  assert_mpci_contains(g, @mpc.mpc_gamma(z1, 200, @mpf.round_nearest))
  assert_mpci_contains(g, @mpc.mpc_gamma(z2, 200, @mpf.round_nearest))
  let lg = mpci_loggamma(iv, 200)
  assert_mpci_contains(lg, @mpc.mpc_loggamma(z1, 200, @mpf.round_nearest))
  assert_mpci_contains(lg, @mpc.mpc_loggamma(z2, 200, @mpf.round_nearest))
  let rg = mpci_rgamma(iv, 200)
  assert_mpci_contains(rg, @mpc.mpc_rgamma(z1, 200, @mpf.round_nearest))
  assert_mpci_contains(rg, @mpc.mpc_rgamma(z2, 200, @mpf.round_nearest))
}
