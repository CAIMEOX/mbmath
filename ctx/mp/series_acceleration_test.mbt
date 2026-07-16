///|
test "levin subset from mpmath test_levin" {
  let ctx = MPContext::new(260, Nearest)
  let p = 260
  let partials_alt : Array[@mpf.RawMpf] = []
  let mut s_alt = @mpf.RawMpf::zero()
  for k in 1..<=30 {
    let sign = if (k & 1) == 1 {
      @mpf.RawMpf::one()
    } else {
      @mpf.RawMpf::negative_one()
    }
    let term = sign.div(@mpf.RawMpf::from_int(k), p, Nearest)
    s_alt = s_alt.add(term, p, Nearest)
    partials_alt.push(s_alt)
  }
  let (v_alt, e_alt) = ctx.levin(partials_alt, algo="levin")
  let ln2 = @libelefun.ln2(p, Nearest)
  assert_close_mpf_str(v_alt.sub(ln2, p, Nearest), "0", "3e-6")
  assert_true(e_alt < @mpf.RawMpf::parse("5e-4"))

  let partials_pos : Array[@mpf.RawMpf] = []
  let mut s_pos = @mpf.RawMpf::zero()
  for k in 1..<=40 {
    let kk = @mpf.RawMpf::from_int(k)
    let k2 = kk.mul(kk, p, Nearest)
    let term = @mpf.RawMpf::one().div(k2, p, Nearest)
    s_pos = s_pos.add(term, p, Nearest)
    partials_pos.push(s_pos)
  }
  let (v_rich, _) = ctx.levin(partials_pos, algo="richardson")
  let pi = @libelefun.pi(p, Nearest)
  let pi2 = pi.mul(pi, p, Nearest)
  let pi2_over_6 = pi2.div(@mpf.RawMpf::from_int(6), p, Nearest)
  assert_close_mpf_str(v_rich.sub(pi2_over_6, p, Nearest), "0", "2e-3")
}

///|
test "levin invalid input subset" {
  let ctx = MPContext::new(200, Nearest)
  try ctx.levin([@mpf.RawMpf::one(), @mpf.RawMpf::from_int(2)]) catch {
    ValueError(_) => ()
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("expected ValueError for short partial sequence")
  }
}
