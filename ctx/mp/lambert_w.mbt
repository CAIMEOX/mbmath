///|
/// Evaluate a real branch of the Lambert W function.
///
/// Branch `0` is real for `x >= -1/e`; branch `-1` is real on
/// `[-1/e, 0]`. Inputs outside those domains raise `ComplexResult` and must use
/// `complex_lambert_w` explicitly.
pub fn MPContext::lambert_w(
  self : MPContext,
  x : @mpf.RawMpf,
  branch? : Int = 0,
) -> @mpf.RawMpf raise MPError {
  if x.is_nan() {
    return @mpf.RawMpf::nan()
  }
  if branch != 0 && branch != -1 {
    raise ComplexResult("Lambert W branch is not real-valued")
  }
  let input_bits = if x.bc > 0 { x.bc } else { 0 }
  let target = if self.precision() > input_bits {
    self.precision()
  } else {
    input_bits
  }
  let p = target + 96
  let e = checked_mpf_exp(@mpf.RawMpf::one(), p, Nearest)
  let boundary = checked_mpf_div(@mpf.RawMpf::negative_one(), e, p, Nearest)
  if branch == 0 && x < boundary {
    raise ComplexResult("principal Lambert W value is complex below -1/e")
  }
  if branch == -1 && (x < boundary || (x.sign == 0 && !x.is_zero())) {
    raise ComplexResult("Lambert W branch -1 is real only on [-1/e, 0]")
  }
  let value = @mpc.RawMpc::new(x, @mpf.RawMpf::zero()).lambert_w(
    self.precision(),
    self.round_mode(),
    branch~,
  ) catch {
    err => raise from_mpc_error(err)
  }
  value.real
}

///|
/// Evaluate the Lambert W function on any integer branch for a complex input.
pub fn MPContext::complex_lambert_w(
  self : MPContext,
  z : @mpc.RawMpc,
  branch? : Int = 0,
) -> @mpc.RawMpc raise MPError {
  z.lambert_w(self.precision(), self.round_mode(), branch~) catch {
    err => raise from_mpc_error(err)
  }
}
