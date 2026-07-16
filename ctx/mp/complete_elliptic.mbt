///|
/// Evaluate the complete elliptic integral of the first kind for a real
/// parameter `m <= 1`.
pub fn MPContext::complete_elliptic_first_kind(
  self : MPContext,
  m : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.ellipk(m, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the complete elliptic integral of the second kind for a real
/// parameter `m <= 1`.
pub fn MPContext::complete_elliptic_second_kind(
  self : MPContext,
  m : @mpf.RawMpf,
) -> @mpf.RawMpf raise MPError {
  @libhyper.ellipe(m, self.precision(), self.round_mode()) catch {
    err => raise from_libhyper_error(err)
  }
}

///|
/// Evaluate the principal complete elliptic integral of the first kind for a
/// complex parameter.
pub fn MPContext::complex_complete_elliptic_first_kind(
  self : MPContext,
  m : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  m.ellipk(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}

///|
/// Evaluate the principal complete elliptic integral of the second kind for a
/// complex parameter.
pub fn MPContext::complex_complete_elliptic_second_kind(
  self : MPContext,
  m : @mpc.RawMpc,
) -> @mpc.RawMpc raise MPError {
  m.ellipe(self.precision(), self.round_mode()) catch {
    err => raise from_mpc_error(err)
  }
}
