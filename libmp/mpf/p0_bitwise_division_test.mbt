///|
fn assert_raw(x : RawMpf, sign : Int, man : BigInt, exp : Int) -> Unit raise {
  assert_eq(x.sign, sign)
  assert_eq(x.man, man)
  assert_eq(x.exp, exp)
}

///|
test "p0 bitwise round_down matrix from mpmath" {
  assert_eq(from_man_exp(0N, -4, 4, round_down), fzero)
  assert_raw(from_man_exp(240N, -4, 4, round_down), 0, 15N, 0)
  assert_raw(from_man_exp(241N, -4, 4, round_down), 0, 15N, 0)
  assert_raw(from_man_exp(255N, -4, 4, round_down), 0, 15N, 0)
  assert_raw(from_man_exp(-240N, -4, 4, round_down), 1, 15N, 0)
  assert_raw(from_man_exp(-241N, -4, 4, round_down), 1, 15N, 0)
  assert_raw(from_man_exp(-255N, -4, 4, round_down), 1, 15N, 0)
}

///|
test "p0 bitwise round_up matrix from mpmath" {
  assert_eq(from_man_exp(0N, -4, 4, round_up), fzero)
  assert_raw(from_man_exp(240N, -4, 4, round_up), 0, 15N, 0)
  assert_raw(from_man_exp(241N, -4, 4, round_up), 0, 1N, 4)
  assert_raw(from_man_exp(255N, -4, 4, round_up), 0, 1N, 4)
  assert_raw(from_man_exp(-240N, -4, 4, round_up), 1, 15N, 0)
  assert_raw(from_man_exp(-241N, -4, 4, round_up), 1, 1N, 4)
  assert_raw(from_man_exp(-255N, -4, 4, round_up), 1, 1N, 4)
}

///|
test "p0 bitwise floor and ceiling matrix from mpmath" {
  assert_raw(from_man_exp(241N, -4, 4, round_floor), 0, 15N, 0)
  assert_raw(from_man_exp(-241N, -4, 4, round_floor), 1, 1N, 4)
  assert_raw(from_man_exp(241N, -4, 4, round_ceiling), 0, 1N, 4)
  assert_raw(from_man_exp(-241N, -4, 4, round_ceiling), 1, 15N, 0)
}

///|
test "p0 bitwise nearest tie-even subset from mpmath" {
  assert_raw(from_man_exp(247N, -4, 4, round_nearest), 0, 15N, 0)
  assert_raw(from_man_exp(248N, -4, 4, round_nearest), 0, 1N, 4)
  assert_raw(from_man_exp(249N, -4, 4, round_nearest), 0, 1N, 4)
  assert_raw(from_man_exp(232N, -4, 4, round_nearest), 0, 7N, 1)
  assert_raw(from_man_exp(233N, -4, 4, round_nearest), 0, 15N, 0)
  assert_raw(from_man_exp(-247N, -4, 4, round_nearest), 1, 15N, 0)
  assert_raw(from_man_exp(-248N, -4, 4, round_nearest), 1, 1N, 4)
  assert_raw(from_man_exp(-249N, -4, 4, round_nearest), 1, 1N, 4)
}

///|
test "p0 bitwise historical rounding bugs subset" {
  assert_raw(from_man_exp(31N, 0, 4, round_up), 0, 1N, 5)
  assert_raw(from_man_exp(-31N, 0, 4, round_floor), 1, 1N, 5)
  assert_raw(from_man_exp(255N, 0, 7, round_up), 0, 1N, 8)
  assert_raw(from_man_exp(-255N, 0, 7, round_floor), 1, 1N, 8)
}

///|
test "p0 exact add cancellation subset from mpmath" {
  let tiny = from_man_exp(1N, -332, 0, round_down)
  assert_eq(
    mpf_sub(mpf_add(fone, tiny, 0, round_nearest), fone, 0, round_nearest),
    tiny,
  )
  assert_eq(
    mpf_sub(mpf_add(tiny, fone, 0, round_nearest), fone, 0, round_nearest),
    tiny,
  )
  let tiny_neg = mpf_neg(tiny, 0, round_down)
  assert_eq(
    mpf_sub(mpf_add(fone, tiny_neg, 0, round_nearest), fone, 0, round_nearest),
    tiny_neg,
  )
  assert_eq(mpf_add(fone, fzero, 0, round_nearest), fone)
  assert_eq(mpf_add(fzero, fone, 0, round_nearest), fone)
  assert_eq(mpf_add(fzero, fzero, 0, round_nearest), fzero)
}

///|
test "p0 tight integer division exactness subset from mpmath" {
  let pairs : Array[(Int, Int, Int)] = [
    (17, 13, 4),
    (-17, 13, 4),
    (1025, -257, 9),
    (-4097, -65, 7),
  ]
  for item in pairs {
    let (a, b, w) = item
    let p = a * b
    let pa = from_int(p)
    let aa = from_int(a)
    let bb = from_int(b)
    assert_eq(mpf_div(pa, aa, w, round_floor), bb)
    assert_eq(mpf_div(pa, aa, w, round_ceiling), bb)
    assert_eq(mpf_div(pa, aa, w, round_down), bb)
    assert_eq(mpf_div(pa, aa, w, round_up), bb)
    assert_eq(mpf_div(pa, aa, w, round_nearest), bb)
  }
}

///|
test "p0 epsilon division rounding subset from mpmath" {
  let a = from_str("0b0.101000000000000000000000000000000000000000000000001")
  let b = from_str("0b1.10101")
  let c = mpf_mul(a, b, 260, round_floor)
  assert_eq(mpf_div(c, b, 2, round_down), from_str("0b0.10"))
  assert_eq(mpf_div(c, b, 3, round_down), from_str("0b0.101"))
  assert_eq(mpf_div(c, b, 2, round_up), from_str("0b0.11"))
  assert_eq(mpf_div(c, b, 3, round_up), from_str("0b0.110"))
  assert_eq(mpf_div(c, b, 2, round_floor), from_str("0b0.10"))
  assert_eq(mpf_div(c, b, 3, round_floor), from_str("0b0.101"))
  assert_eq(mpf_div(c, b, 2, round_ceiling), from_str("0b0.11"))
  assert_eq(mpf_div(c, b, 3, round_ceiling), from_str("0b0.110"))
}

///|
test "p0 epsilon division negative rounding subset from mpmath" {
  let a = from_str("-0b0.101000000000000000000000000000000000000000000000001")
  let b = from_str("0b1.10101")
  let c = mpf_mul(a, b, 260, round_floor)
  assert_eq(mpf_div(c, b, 2, round_down), from_str("-0b0.10"))
  assert_eq(mpf_div(c, b, 3, round_up), from_str("-0b0.110"))
  assert_eq(mpf_div(c, b, 2, round_floor), from_str("-0b0.11"))
  assert_eq(mpf_div(c, b, 3, round_floor), from_str("-0b0.110"))
  assert_eq(mpf_div(c, b, 2, round_ceiling), from_str("-0b0.10"))
  assert_eq(mpf_div(c, b, 3, round_ceiling), from_str("-0b0.101"))
}

///|
test "p0 basic ops mod/floor-div style subset from mpmath" {
  let a = from_str("30.21")
  let b = from_str("2.53")
  let q = mpf_floor(mpf_div(a, b, 120, round_nearest), 0, round_nearest)
  let r = mpf_mod(a, b, 120, round_nearest)
  assert_eq(q, from_int(11))
  assert_eq(r, from_str("2.380000000000003"))
}
