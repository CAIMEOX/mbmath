///|
fn assert_close_mpf_str(
  x : @mpf.RawMpf,
  expected : String,
  tol : String,
) -> Unit raise {
  let y = @mpf.from_str(expected, prec=320, rnd=@mpf.round_nearest)
  let err = @mpf.mpf_abs(
    @mpf.mpf_sub(x, y, 320, @mpf.round_nearest),
    320,
    @mpf.round_nearest,
  )
  assert_true(@mpf.mpf_lt(err, @mpf.from_str(tol)))
}
