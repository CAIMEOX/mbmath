///|
test "Hardy Z matches high-precision real and complex values" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.hardy_z(ctx.from_int(1)),
    "-0.736305462867317734677899828925614672097397237394171858460249175255270172811240146213068305465534660856006178623468572042875916801266832878733860639086133661454078636",
    "2e-143",
    comparison_precision=560,
  )
  let complex_value = ctx.complex_hardy_z(
    ctx.complex(ctx.from_int(3), ctx.from_int(4)),
  )
  assert_close_mpf_str(
    complex_value.real,
    "-0.18528957643663149760039364022749391337260599132642905032294370896258487859455823311549287912471289015233574644291526717591486486602681581303884497344959035691322443",
    "2e-142",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    complex_value.imag,
    "-0.277309919805565224699247949034438373994142127621290944060653305723799968656024857996390913473864694269725381982667077852591343993578462343599261974898716852027446501",
    "2e-142",
    comparison_precision=560,
  )
}

///|
test "Hardy Z derivatives use analytic zeta and theta jets" {
  let ctx = MPContext::new(500, Nearest)
  assert_close_mpf_str(
    ctx.hardy_z(ctx.from_int(10), order=1),
    "-0.030452773175529900572198549150508796624537733662792860725775415870537282510368799882176713662060512370384702156478553311452603160234875762699041474339409510199968523",
    "2e-143",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    ctx.hardy_z(ctx.from_int(10), order=4),
    "-0.000992808888780816701741939354295172295739138465071376633565121719659584847894783159455131490520058055028084898519151856720346623992447847339171763699820113724706751803",
    "2e-143",
    comparison_precision=560,
  )
}

///|
test "Hardy Z supports arbitrary complex derivative orders" {
  let ctx = MPContext::new(500, Nearest)
  let value = ctx.complex_hardy_z(
    ctx.complex(ctx.parse("3.25"), ctx.parse("1.5")),
    order=6,
  )
  assert_close_mpf_str(
    value.real,
    "0.0584259102330989523055035841641496052457293565091423986283145592076070794006445057807738279737890881889318428790720382202595823490610711056495083658616451905119026827",
    "2e-141",
    comparison_precision=560,
  )
  assert_close_mpf_str(
    value.imag,
    "0.0194331298331404965715945253482462424753938999605018571028638373313876533110014757102475143520422127724768792198458242804475650897115759304073113428654574264686208259",
    "2e-141",
    comparison_precision=560,
  )
}

///|
test "Hardy Z parity, defining identity, and errors are explicit" {
  let ctx = MPContext::new(300, Nearest)
  let t = ctx.parse("2.25")
  for order in 0..<=4 {
    let positive = ctx.hardy_z(t, order~)
    let negative = ctx.hardy_z(t.negated(0, Down), order~)
    let expected = if (order & 1) == 1 {
      positive.negated(360, Nearest)
    } else {
      positive
    }
    assert_close_mpf_str(
      negative.sub(expected, 360, Nearest),
      "0",
      "2e-82",
      comparison_precision=360,
    )
  }
  let theta = ctx.riemann_siegel_theta(t)
  let phase = ctx.complex(@mpf.RawMpf::zero(), theta).exp(360, Nearest)
  let zeta = ctx.complex_zeta(ctx.complex(@mpf.RawMpf::half(), t))
  let identity = phase.mul(zeta, 360, Nearest)
  assert_close_mpf_str(
    ctx.hardy_z(t).sub(identity.real, 360, Nearest),
    "0",
    "2e-82",
    comparison_precision=360,
  )
  assert_close_mpf_str(identity.imag, "0", "2e-82", comparison_precision=360)
  assert_true(ctx.hardy_z(@mpf.RawMpf::nan()).is_nan())
  try ctx.hardy_z(t, order=-1) catch {
    DomainError(_) => ()
    _ => fail("unexpected negative Hardy-Z derivative error")
  } noraise {
    _ => fail("expected negative Hardy-Z derivative error")
  }
}
