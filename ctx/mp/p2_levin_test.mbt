///|
test "p2 levin subset from mpmath test_levin" {
  let ctx = new(260, @mpf.round_nearest)
  let p = 260
  let partials_alt : Array[@mpf.RawMpf] = []
  let mut s_alt = @mpf.fzero
  for k in 1..<=30 {
    let sign = if (k & 1) == 1 { @mpf.fone } else { @mpf.fnone }
    let term = @mpf.mpf_div(sign, @mpf.from_int(k), p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    s_alt = @mpf.mpf_add(s_alt, term, p, @mpf.round_nearest)
    partials_alt.push(s_alt)
  }
  let (v_alt, e_alt) = ctx.levin(partials_alt, algo="levin")
  let ln2 = @libelefun.mpf_ln2(p, @mpf.round_nearest)
  assert_close_mpf_str(
    @mpf.mpf_sub(v_alt, ln2, p, @mpf.round_nearest),
    "0",
    "3e-6",
  )
  assert_true(@mpf.mpf_lt(e_alt, @mpf.from_str("5e-4")))

  let partials_pos : Array[@mpf.RawMpf] = []
  let mut s_pos = @mpf.fzero
  for k in 1..<=40 {
    let kk = @mpf.from_int(k)
    let k2 = @mpf.mpf_mul(kk, kk, p, @mpf.round_nearest)
    let term = @mpf.mpf_div(@mpf.fone, k2, p, @mpf.round_nearest) catch {
      _ => @mpf.fnan
    }
    s_pos = @mpf.mpf_add(s_pos, term, p, @mpf.round_nearest)
    partials_pos.push(s_pos)
  }
  let (v_rich, _) = ctx.levin(partials_pos, algo="richardson")
  let pi = @libelefun.mpf_pi(p, @mpf.round_nearest)
  let pi2 = @mpf.mpf_mul(pi, pi, p, @mpf.round_nearest)
  let pi2_over_6 = @mpf.mpf_div(pi2, @mpf.from_int(6), p, @mpf.round_nearest) catch {
    _ => @mpf.fnan
  }
  assert_close_mpf_str(
    @mpf.mpf_sub(v_rich, pi2_over_6, p, @mpf.round_nearest),
    "0",
    "2e-3",
  )
}

///|
test "p2 levin invalid input subset" {
  let ctx = new(200, @mpf.round_nearest)
  let bad_short : Result[(@mpf.RawMpf, @mpf.RawMpf), MPError] = try? ctx.levin([
    @mpf.fone,
    @mpf.from_int(2),
  ])
  match bad_short {
    Ok(_) => fail("expected ValueError for short partial sequence")
    Err(MPError::ValueError(_)) => ()
    Err(_) => fail("unexpected error type")
  }
}
