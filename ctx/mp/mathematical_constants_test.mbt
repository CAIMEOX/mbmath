///|
test "Apery constant exceeds legacy fixed-string precision" {
  let ctx = MPContext::new(640, Nearest)
  let value = ctx.apery_constant()
  assert_close_mpf_str(
    value, "1.20205690315959428539973816151144999076498629234049888179227155534183820578631309018645587360933525814619915779526071941849199599867328321377639683720790016145394178294936006671919157552224249424",
    "2e-190",
  )
  @debug.assert_eq(value, ctx.zeta(ctx.from_int(3)))
}

///|
test "Catalan constant uses arbitrary-precision trigamma identity" {
  let ctx = MPContext::new(640, Nearest)
  let value = ctx.catalan_constant()
  assert_close_mpf_str(
    value, "0.915965594177219015054603514932384110774149374281672134266498119621763019776254769479356512926115106248574422619196199579035898803325859059431594737481158406995332028773319460519038727478164087866",
    "2e-190",
  )
  let quarter = @mpf.RawMpf::one().scale_pow2(-2)
  let three_quarters = ctx.mul(ctx.from_int(3), quarter)
  let identity = ctx
    .sub(ctx.polygamma(1, quarter), ctx.polygamma(1, three_quarters))
    .scale_pow2(-4)
  assert_close_mpf_str(ctx.sub(value, identity), "0", "2e-190")
}

///|
test "Euler-Mascheroni constant exceeds legacy fixed-string precision" {
  let ctx = MPContext::new(640, Nearest)
  assert_close_mpf_str(
    ctx.euler_mascheroni_constant(),
    "0.577215664901532860606512090082402431042159335939923598805767234884867726777664670936947063291746749514631447249807082480960504014486542836224173997644923536253500333742937337737673942792595258247",
    "2e-190",
  )
}
