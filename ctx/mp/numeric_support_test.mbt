///|
fn assert_close_mpf_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let comparison_precision = 640
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
