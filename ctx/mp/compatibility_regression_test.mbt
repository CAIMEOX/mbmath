///|
fn mpf_from_double_exact(x : Double) -> @mpf.RawMpf {
  let bits = Double::reinterpret_as_uint64(x)
  let zero_u = UInt64::default()
  let one_u = UInt64::extend_uint(1)
  let sign = (bits >> 63) & one_u
  let exp_mask = (one_u << 11) - one_u
  let frac_mask = (one_u << 52) - one_u
  let exp_u = (bits >> 52) & exp_mask
  let frac_u = bits & frac_mask
  let exp_bits = exp_u.to_int()
  if exp_bits == 0x7ff {
    if frac_u == zero_u {
      if sign == zero_u {
        @mpf.finf
      } else {
        @mpf.fninf
      }
    } else {
      @mpf.fnan
    }
  } else if exp_bits == 0 {
    if frac_u == zero_u {
      @mpf.fzero
    } else {
      let man0 = BigInt::from_uint64(frac_u)
      let man = if sign == zero_u { man0 } else { -man0 }
      @mpf.from_man_exp(man, -1074, 0, @mpf.round_down)
    }
  } else {
    let man0 = BigInt::from_uint64(frac_u) + (1N << 52)
    let man = if sign == zero_u { man0 } else { -man0 }
    @mpf.from_man_exp(man, exp_bits - 1075, 0, @mpf.round_down)
  }
}

///|
fn mpf_absolute_difference(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf {
  @mpf.mpf_abs(
    @mpf.mpf_sub(x, y, prec, @mpf.round_nearest),
    prec,
    @mpf.round_nearest,
  )
}

///|
fn mpf_relative_error(
  x : @mpf.RawMpf,
  y : @mpf.RawMpf,
  prec : Int,
) -> @mpf.RawMpf raise @mpf.MpfError {
  let num = mpf_absolute_difference(x, y, prec)
  let den0 = @mpf.mpf_abs(y, prec, @mpf.round_nearest)
  let den = if @mpf.is_zero(den0) {
    @mpf.from_man_exp(1N, -prec / 2, 0, @mpf.round_down)
  } else {
    den0
  }
  @mpf.mpf_div(num, den, prec, @mpf.round_nearest)
}

///|
fn roundtrip_mpf(x : @mpf.RawMpf) -> @mpf.RawMpf {
  if @mpf.is_nan(x) {
    @mpf.fnan
  } else if @mpf.is_inf(x) {
    if x.sign == 1 {
      @mpf.fninf
    } else {
      @mpf.finf
    }
  } else if @mpf.is_zero(x) {
    @mpf.fzero
  } else {
    let man = if x.sign == 1 { -x.man } else { x.man }
    @mpf.from_man_exp(man, x.exp, 0, @mpf.round_down)
  }
}

///|
fn roundtrip_mpc(z : @mpc.RawMpc) -> @mpc.RawMpc {
  @mpc.from_parts(roundtrip_mpf(z.real), roundtrip_mpf(z.imag))
}

///|
fn roundtrip_matrix(ctx : MPContext, m : MpfMatrix) -> MpfMatrix raise MPError {
  let out = ctx.matrix(m.rows, m.cols)
  for i in 0..<m.rows {
    for j in 0..<m.cols {
      out.set(i, j, roundtrip_mpf(m.get(i, j)))
    }
  }
  out
}

///|
test "compatibility subset from mpmath test_compatibility" {
  let xs : Array[Double] = [
    1.25, -2.5, 3.75e100, -4.125e-80, 2.0e30, -6.0, 1.0e-10, 7.5e20, -9.25e-40, 3.141592653589793,
  ]
  let ys : Array[Double] = [
    -3.5, 4.75, -9.0e60, 8.0e-70, -3.0e25, -6.0, 1.0e-10, -2.5e10, 1.25e-30, 3.141592653589793,
  ]

  for i in 0..<xs.length() {
    let x = xs[i]
    let y = ys[i]
    let mpx = mpf_from_double_exact(x)
    let mpy = mpf_from_double_exact(y)

    @debug.assert_eq(@mpf.mpf_lt(mpx, mpy), x < y)
    @debug.assert_eq(@mpf.mpf_gt(mpx, mpy), x > y)
    @debug.assert_eq(@mpf.mpf_eq(mpx, mpy), x == y)
    @debug.assert_eq(!@mpf.mpf_eq(mpx, mpy), x != y)
    @debug.assert_eq(@mpf.mpf_le(mpx, mpy), x <= y)
    @debug.assert_eq(@mpf.mpf_ge(mpx, mpy), x >= y)

    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_add(mpx, mpy, 53, @mpf.round_nearest),
        mpf_from_double_exact(x + y),
      ),
    )
    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_mul(mpx, mpy, 53, @mpf.round_nearest),
        mpf_from_double_exact(x * y),
      ),
    )
    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_div(mpx, mpy, 53, @mpf.round_nearest),
        mpf_from_double_exact(x / y),
      ),
    )
    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_abs(mpx, 53, @mpf.round_nearest),
        mpf_from_double_exact(Double::abs(x)),
      ),
    )
    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_ceil(mpx, 0, @mpf.round_nearest),
        mpf_from_double_exact(Double::ceil(x)),
      ),
    )
    assert_true(
      @mpf.mpf_eq(
        @mpf.mpf_floor(mpx, 0, @mpf.round_nearest),
        mpf_from_double_exact(Double::floor(x)),
      ),
    )

    let repr_m = @mpf.from_str(
      Double::to_string(x),
      prec=53,
      rnd=@mpf.round_nearest,
    )
    assert_true(@mpf.mpf_eq(repr_m, mpx))
  }

  let a = @mpf.from_str(
    "4.4408920985006262E-16",
    prec=53,
    rnd=@mpf.round_nearest,
  )
  let b = @mpf.from_str(
    "1.7763568394002505E-15",
    prec=53,
    rnd=@mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(a, b))
  assert_true(
    @mpf.mpf_gt(
      @mpf.mpf_neg(a, 0, @mpf.round_down),
      @mpf.mpf_neg(b, 0, @mpf.round_down),
    ),
  )
}

///|
test "compatibility sqrt subset from mpmath test_compatibility" {
  let xs : Array[Double] = [1.0e-120, 1.0e-30, 0.25, 2.0, 10.0, 1.0e20]
  let mut fail = 0
  for x in xs {
    let xd = Double::abs(x)
    let mpx = mpf_from_double_exact(xd)
    let mp_high = @mpf.mpf_sqrt(mpx, 220, @mpf.round_nearest)
    let mp_low = @mpf.mpf_sqrt(mpx, 53, @mpf.round_nearest)
    let fp = mpf_from_double_exact(Double::sqrt(xd))
    let err_low = mpf_absolute_difference(mp_low, mp_high, 240)
    let err_fp = mpf_absolute_difference(fp, mp_high, 240)
    assert_true(@mpf.mpf_le(err_low, err_fp))
    if !@mpf.mpf_eq(mp_low, fp) {
      fail += 1
    }
  }
  assert_true(fail < xs.length())
}

///|
test "pickle-roundtrip subset from mpmath test_pickle" {
  let ctx = new(200, @mpf.round_nearest)

  let f = @mpf.from_str("0.5")
  assert_true(@mpf.mpf_eq(f, roundtrip_mpf(f)))

  let z = @mpc.from_parts(@mpf.from_str("0.5"), @mpf.from_str("0.2"))
  @debug.assert_eq(z, roundtrip_mpc(z))

  let row = ctx.matrix_from_vector([
    matrix_integer(ctx, 1),
    ctx.sin(matrix_integer(ctx, 1)),
  ])
  @debug.assert_eq(row, roundtrip_matrix(ctx, row))

  let mat = ctx.matrix_from_rows([
    [matrix_integer(ctx, 1), matrix_integer(ctx, 2)],
    [matrix_integer(ctx, 3), matrix_integer(ctx, 4)],
  ])
  @debug.assert_eq(mat, roundtrip_matrix(ctx, mat))
}

///|
test "torture asymptotic consistency subset from mpmath test_torture" {
  let lo = new(140, @mpf.round_nearest)
  let hi = new(320, @mpf.round_nearest)

  let xs = ["1e-10", "0.25", "2", "10", "1e10"]
  for s in xs {
    let xlo = lo.make_float(s)
    let xhi = hi.make_float(s)

    let rel_exp = mpf_relative_error(lo.exp(xlo), hi.exp(xhi), 260)
    assert_true(@mpf.mpf_lt(rel_exp, @mpf.from_str("1e-18")))

    let rel_ln = mpf_relative_error(lo.ln(xlo), hi.ln(xhi), 260)
    assert_true(@mpf.mpf_lt(rel_ln, @mpf.from_str("1e-18")))

    let rel_sin = mpf_relative_error(lo.sin(xlo), hi.sin(xhi), 260)
    assert_true(@mpf.mpf_lt(rel_sin, @mpf.from_str("1e-17")))
  }

  let gs = ["0.5", "1.25", "5.5", "20"]
  for s in gs {
    let glo = lo.make_float(s)
    let ghi = hi.make_float(s)
    let rel_gamma = mpf_relative_error(lo.gamma(glo), hi.gamma(ghi), 260)
    assert_true(@mpf.mpf_lt(rel_gamma, @mpf.from_str("1e-18")))
  }
}
