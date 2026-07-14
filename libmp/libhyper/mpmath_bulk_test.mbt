///|
fn dps_to_prec(dps : Int) -> Int {
  if dps < 1 {
    96
  } else {
    dps * 4 + 96
  }
}

///|
fn mantissa_digit_count(expected_text : String) -> Int {
  let mut digits = 0
  for c in expected_text {
    if c == 'e' || c == 'E' {
      break
    }
    if c >= '0' && c <= '9' {
      digits += 1
    }
  }
  digits
}

///|
fn assert_close_numeric(
  v : @mpf.RawMpf,
  dps : Int,
  expected_text : String,
) -> Unit raise {
  let prec = dps_to_prec(dps)
  let expected = @mpf.from_str(expected_text, prec~, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(v, expected, prec, @mpf.round_nearest),
    prec,
    @mpf.round_nearest,
  )
  let digits = mantissa_digit_count(expected_text)
  let sig_digits = if digits <= 1 { 0 } else { digits - 1 }
  let rel_tol = if sig_digits == 0 {
    @mpf.fone
  } else {
    @mpf.from_str("1e-\{sig_digits}", prec~, rnd=@mpf.round_nearest)
  }
  let mut scale = @mpf.mpf_abs(expected, prec, @mpf.round_nearest)
  if @mpf.mpf_lt(scale, @mpf.fone) {
    scale = @mpf.fone
  }
  let tol = @mpf.mpf_mul(scale, rel_tol, prec, @mpf.round_nearest)
  assert_true(@mpf.mpf_le(err, tol))
}

///|
fn assert_small_abs(v : @mpf.RawMpf, bound : String) -> Unit raise {
  let bound_v = @mpf.from_str(bound, prec=240, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_lt(@mpf.mpf_abs(v, 240, @mpf.round_nearest), bound_v))
}

///|
fn assert_between(v : @mpf.RawMpf, lo : String, hi : String) -> Unit raise {
  let lo_v = @mpf.from_str(lo, prec=240, rnd=@mpf.round_nearest)
  let hi_v = @mpf.from_str(hi, prec=240, rnd=@mpf.round_nearest)
  assert_true(@mpf.mpf_gt(v, lo_v) && @mpf.mpf_lt(v, hi_v))
}

///|
test "mpmath bulk ei zero and infinities" {
  let e0 = mpf_ei(@mpf.fzero, 140, @mpf.round_nearest)
  assert_true(@mpf.is_inf(e0) && e0.sign == 1)
  let ep = mpf_ei(@mpf.finf, 140, @mpf.round_nearest)
  assert_true(@mpf.is_inf(ep) && ep.sign == 0)
  let en = mpf_ei(@mpf.fninf, 140, @mpf.round_nearest)
  assert_true(@mpf.is_zero(en))
}

///|
test "mpmath bulk ei x=0.5" {
  assert_between(
    mpf_ei(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    "0.4",
    "0.5",
  )
}

///|
test "mpmath bulk ei x=1" {
  assert_between(mpf_ei(@mpf.from_int(1), 220, @mpf.round_nearest), "1", "2")
}

///|
test "mpmath bulk ei x=2" {
  assert_close_numeric(
    mpf_ei(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "4.95423435600189016",
  )
}

///|
test "mpmath bulk ei x=3" {
  assert_between(mpf_ei(@mpf.from_int(3), 220, @mpf.round_nearest), "9", "11")
}

///|
test "mpmath bulk ei x=5" {
  assert_between(mpf_ei(@mpf.from_int(5), 220, @mpf.round_nearest), "35", "45")
}

///|
test "mpmath bulk ei x=20" {
  assert_close_numeric(
    mpf_ei(@mpf.from_int(20), 220, @mpf.round_nearest),
    18,
    "25615652.66405658",
  )
}

///|
test "mpmath bulk ei x=-0.5" {
  assert_close_numeric(
    mpf_ei(@mpf.from_str("-0.5"), 220, @mpf.round_nearest),
    18,
    "-0.5597735947761608",
  )
}

///|
test "mpmath bulk ei x=-1" {
  assert_close_numeric(
    mpf_ei(@mpf.from_int(-1), 220, @mpf.round_nearest),
    18,
    "-0.2193839343955202",
  )
}

///|
test "mpmath bulk ei x=-2" {
  assert_close_numeric(
    mpf_ei(@mpf.from_int(-2), 220, @mpf.round_nearest),
    18,
    "-0.04890051070806111",
  )
}

///|
test "mpmath bulk si x=0" {
  assert_true(@mpf.is_zero(mpf_si(@mpf.fzero, 160, @mpf.round_nearest)))
}

///|
test "mpmath bulk si x=0.5" {
  assert_close_numeric(
    mpf_si(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.49310741804306668",
  )
}

///|
test "mpmath bulk si x=1" {
  assert_close_numeric(
    mpf_si(@mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.94608307036718301",
  )
}

///|
test "mpmath bulk si x=2" {
  assert_between(
    mpf_si(@mpf.from_int(2), 220, @mpf.round_nearest),
    "1.5",
    "1.7",
  )
}

///|
test "mpmath bulk si x=3" {
  assert_between(
    mpf_si(@mpf.from_int(3), 220, @mpf.round_nearest),
    "1.7",
    "1.95",
  )
}

///|
test "mpmath bulk si x=5" {
  assert_between(
    mpf_si(@mpf.from_int(5), 220, @mpf.round_nearest),
    "1.4",
    "1.7",
  )
}

///|
test "mpmath bulk si x=50" {
  assert_close_numeric(
    mpf_si(@mpf.from_int(50), 220, @mpf.round_nearest),
    18,
    "1.55161707248593589",
  )
}

///|
test "mpmath bulk si infinities" {
  assert_between(mpf_si(@mpf.finf, 180, @mpf.round_nearest), "1.5", "1.7")
  assert_between(mpf_si(@mpf.fninf, 180, @mpf.round_nearest), "-1.7", "-1.5")
}

///|
test "mpmath bulk ci x=0" {
  let c0 = mpf_ci(@mpf.fzero, 160, @mpf.round_nearest)
  assert_true(@mpf.is_inf(c0) && c0.sign == 1)
}

///|
test "mpmath bulk ci x=0.5" {
  assert_close_numeric(
    mpf_ci(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "-0.1777840788066129",
  )
}

///|
test "mpmath bulk ci x=1" {
  assert_close_numeric(
    mpf_ci(@mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.33740392290096813",
  )
}

///|
test "mpmath bulk ci x=2" {
  assert_close_numeric(
    mpf_ci(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.42298082877486499",
  )
}

///|
test "mpmath bulk ci x=3" {
  assert_close_numeric(
    mpf_ci(@mpf.from_int(3), 220, @mpf.round_nearest),
    18,
    "0.11962978600800032",
  )
}

///|
test "mpmath bulk ci x=5" {
  assert_close_numeric(
    mpf_ci(@mpf.from_int(5), 220, @mpf.round_nearest),
    18,
    "-0.1900297496566438",
  )
}

///|
test "mpmath bulk ci x=50" {
  assert_close_numeric(
    mpf_ci(@mpf.from_int(50), 220, @mpf.round_nearest),
    18,
    "-0.0056283863241163",
  )
}

///|
test "mpmath bulk ci x=1e10 small" {
  assert_small_abs(
    mpf_ci(@mpf.from_str("1e10"), 240, @mpf.round_nearest),
    "1e-8",
  )
}

///|
test "mpmath bulk ci infinity" {
  assert_true(
    @mpf.mpf_eq(mpf_ci(@mpf.finf, 180, @mpf.round_nearest), @mpf.fzero),
  )
}

///|
test "mpmath bulk e1 special values" {
  let e0 = mpf_e1(@mpf.fzero, 180, @mpf.round_nearest)
  assert_true(@mpf.is_inf(e0) && e0.sign == 0)
  assert_true(
    @mpf.mpf_eq(mpf_e1(@mpf.finf, 180, @mpf.round_nearest), @mpf.fzero),
  )
}

///|
test "mpmath bulk e1 positive points" {
  assert_close_numeric(
    mpf_e1(@mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.55977359477616081",
  )
  assert_close_numeric(
    mpf_e1(@mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.21938393439552027",
  )
  assert_close_numeric(
    mpf_e1(@mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.04890051070806111",
  )
}

///|
test "mpmath bulk expint n1 basic points" {
  assert_close_numeric(
    mpf_expint(1, @mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.55977359477616081",
  )
  assert_close_numeric(
    mpf_expint(1, @mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.21938393439552027",
  )
  assert_close_numeric(
    mpf_expint(1, @mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.04890051070806111",
  )
}

///|
test "mpmath bulk expint n2 basic points" {
  assert_true(
    @mpf.mpf_eq(mpf_expint(2, @mpf.fzero, 180, @mpf.round_nearest), @mpf.fone),
  )
  assert_close_numeric(
    mpf_expint(2, @mpf.from_str("0.5"), 220, @mpf.round_nearest),
    18,
    "0.32664386232455301",
  )
  assert_close_numeric(
    mpf_expint(2, @mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.14849550677592204",
  )
}

///|
test "mpmath bulk expint n3 basic points" {
  assert_close_numeric(
    mpf_expint(3, @mpf.fzero, 220, @mpf.round_nearest),
    18,
    "0.5",
  )
  assert_close_numeric(
    mpf_expint(3, @mpf.from_int(1), 220, @mpf.round_nearest),
    18,
    "0.10969196719776013",
  )
  assert_close_numeric(
    mpf_expint(3, @mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.03013337979781589",
  )
}

///|
test "mpmath bulk expint n4 n5 points" {
  assert_close_numeric(
    mpf_expint(4, @mpf.from_int(2), 220, @mpf.round_nearest),
    18,
    "0.02502284121366030",
  )
  assert_close_numeric(
    mpf_expint(5, @mpf.from_str("3.5"), 220, @mpf.round_nearest),
    18,
    "0.00379018173510554",
  )
}

///|
test "mpmath bulk expint high n points" {
  let a = mpf_expint(7, @mpf.from_str("3.5"), 220, @mpf.round_nearest)
  let b = mpf_expint(10, @mpf.from_int(10), 240, @mpf.round_nearest)
  assert_true(
    @mpf.mpf_gt(a, @mpf.fzero) && @mpf.mpf_lt(a, @mpf.from_str("0.01")),
  )
  assert_true(
    @mpf.mpf_gt(b, @mpf.fzero) && @mpf.mpf_lt(b, @mpf.from_str("0.01")),
  )
}

///|
test "mpmath bulk gamma mode positive x" {
  assert_close_numeric(
    mpf_expint(1, @mpf.from_str("0.5"), 220, @mpf.round_nearest, gamma=true),
    18,
    "0.60653065971263342",
  )
  assert_close_numeric(
    mpf_expint(2, @mpf.from_int(2), 220, @mpf.round_nearest, gamma=true),
    18,
    "0.40600584970983807",
  )
}

///|
test "mpmath bulk gamma mode negative x subset" {
  assert_true(
    @mpf.mpf_eq(
      mpf_expint(2, @mpf.from_int(-1), 180, @mpf.round_nearest, gamma=true),
      @mpf.fzero,
    ),
  )
  assert_between(
    mpf_expint(3, @mpf.from_int(-1), 220, @mpf.round_nearest, gamma=true),
    "2",
    "3",
  )
}
