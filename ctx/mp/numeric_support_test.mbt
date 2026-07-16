///|
fn assert_close_mpf_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let y = @mpf.RawMpf::parse(expected, prec=320, rnd=Nearest)
  let err = x.sub(y, 320, Nearest).abs(320, Nearest)
  let tolerance = @mpf.RawMpf::parse(tol, prec=320, rnd=Nearest)
  assert_true(err < tolerance)
}
