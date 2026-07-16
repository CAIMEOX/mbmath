///|
fn assert_close_mpf_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
  comparison_precision? : Int = 640,
) -> Unit raise {
  let y = @mpf.RawMpf::parse(expected, prec=comparison_precision, rnd=Nearest)
  let err = x
    .sub(y, comparison_precision, Nearest)
    .abs(comparison_precision, Nearest)
  let tolerance = @mpf.RawMpf::parse(
    tol,
    prec=comparison_precision,
    rnd=Nearest,
  )
  assert_true(err < tolerance)
}
