///|
/// Stage-0 minimal context shell.
pub struct MPContext {
  prec : Int
  rounding : @mpf.RoundMode
} derive(Show, Eq)

///|
pub fn new(prec : Int, rounding : @mpf.RoundMode) -> MPContext {
  { prec, rounding }
}

///|
pub fn MPContext::make_int(self : MPContext, n : Int) -> @mpf.RawMpf {
  ignore(self)
  @mpf.from_int(n)
}
