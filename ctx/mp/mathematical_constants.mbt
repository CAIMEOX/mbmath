///|
/// Return Apery's constant `zeta(3)` at the current context precision.
pub fn MPContext::apery_constant(self : MPContext) -> @mpf.RawMpf raise MPError {
  @gammazeta.apery(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return Catalan's constant at the current context precision.
pub fn MPContext::catalan_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.catalan(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the Euler-Mascheroni constant at the current context precision.
pub fn MPContext::euler_mascheroni_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.euler(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}

///|
/// Return the Glaisher-Kinkelin constant at the current context precision.
pub fn MPContext::glaisher_kinkelin_constant(
  self : MPContext,
) -> @mpf.RawMpf raise MPError {
  @gammazeta.glaisher(self.precision(), self.round_mode()) catch {
    err => raise from_gammazeta_error(err)
  }
}
