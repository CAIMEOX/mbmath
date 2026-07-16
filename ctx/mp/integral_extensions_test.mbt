///|
test "real logarithmic hyperbolic and Fresnel integrals match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  let x = ctx.e()
  assert_close_mpf_str(
    ctx.logarithmic_integral(x),
    "1.89511781635593675546652093433163426901706058173270759164622843188251383453380415354890071012613895697181109531794465374",
    "2e-105",
  )
  assert_close_mpf_str(
    ctx.hyperbolic_sine_integral(x),
    "4.11520706247846193054354276531316313696660362499787015502046704934697524386566661921242384008825311144896193755136389651",
    "2e-104",
  )
  assert_close_mpf_str(
    ctx.hyperbolic_cosine_integral(x),
    "4.09647459290515367364506130222620589612944703409655180515742076697023917454458080565738470969680796503017664186032629513",
    "2e-104",
  )
  assert_close_mpf_str(
    ctx.fresnel_sine_integral(x),
    "0.43718971814978764265868725438428452948713021793186035613194298170324973210923277062903203461911371223837729811354918098",
    "2e-105",
  )
  assert_close_mpf_str(
    ctx.fresnel_cosine_integral(x),
    "0.401777759590243011552892365438362860220596280266161354536005287564714557076064657511525760139554587116888238544902503407",
    "2e-105",
  )
}

///|
test "complex integral continuations match mpmath principal branches" {
  let ctx = MPContext::new(360, Nearest)
  let z = ctx.complex(ctx.e(), ctx.sqrt(ctx.from_int(3)))
  assert_barnes_complex_close(
    ctx.complex_logarithmic_integral(z),
    "2.28662658112562502306050440331540484572477465481134003283903981012103906304018841813504219001957095011384195723341172058",
    "1.50427225297269364116932343432328925743366749104020190075266448696169821423822541709169417010629361044733268167758183955",
    "2e-104",
  )
  assert_barnes_complex_close(
    ctx.complex_hyperbolic_sine_integral(z),
    "1.85810366559344467567155948729614976344093484895730775942454003757299016116628547701296776756893700845051131599057907657",
    "3.6643584291492026264258327784589448091042682016613263190937423216066711592567949353145728152947904765868814388421069948",
    "2e-104",
  )
  assert_barnes_complex_close(
    ctx.complex_hyperbolic_cosine_integral(z),
    "1.86787602931970483517379761840975553784022651464531715684993538737370638464172281291066440661762675764857950794960192262",
    "3.6777736939930415855565372591935700242997594712449985412836874550237149892805767358785484176328601997843438309447497946",
    "2e-104",
  )
  let scaled = z
    .scale_pow2(-1)
    .div_real(ctx.from_int(3).scale_pow2(-1), 420, Nearest)
  assert_barnes_complex_close(
    ctx.complex_fresnel_sine_integral(scaled),
    "0.0345343971970081820465991856741618674520680391544176019802885752999005431680544591921677543854843913552624289752726435926",
    "0.754859844188218736525936482448937036945761663621688418895609251996608911457035907835942928577644359774590142519019862681",
    "2e-104",
  )
  assert_barnes_complex_close(
    ctx.complex_fresnel_cosine_integral(scaled),
    "1.26158164599002737164227839467208729615255026977503844433633984599707787478662452145674069926165290100057076911256666547",
    "0.417949198775061892927252785709529213461973934250403644959095986427503979591399212053227246996236346183279902091887180237",
    "2e-104",
  )
}

///|
test "logarithmic integral special and offset semantics match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.logarithmic_integral(@mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.logarithmic_integral(@mpf.RawMpf::one()),
    @mpf.RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    ctx.logarithmic_integral(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.logarithmic_integral(ctx.from_int(2), offset=true),
    @mpf.RawMpf::zero(),
  )
  assert_close_mpf_str(
    ctx.logarithmic_integral(ctx.e(), offset=true),
    "0.84995403623844397062193204513702113249444500358150601581331928780750062932344462337618330449975560066579026554906990712",
    "2e-105",
  )
  assert_close_mpf_str(
    ctx.logarithmic_integral(@mpf.RawMpf::zero(), offset=true),
    "-1.04516378011749278484458888919461313652261557815120157583290914407501320521035953017271740562638335630602082976887474662",
    "2e-105",
  )
  try ctx.logarithmic_integral(ctx.from_int(-1)) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected logarithmic-integral real-domain error")
  } noraise {
    _ => fail("expected complex logarithmic-integral principal value")
  }
}

///|
test "hyperbolic integral origin infinity and negative-axis branches match mpmath" {
  let ctx = MPContext::new(360, Nearest)
  @debug.assert_eq(
    ctx.hyperbolic_sine_integral(@mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.hyperbolic_cosine_integral(@mpf.RawMpf::zero()),
    @mpf.RawMpf::negative_infinity(),
  )
  @debug.assert_eq(
    ctx.hyperbolic_sine_integral(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.hyperbolic_sine_integral(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::negative_infinity(),
  )
  try ctx.hyperbolic_cosine_integral(ctx.from_int(-20)) catch {
    ComplexResult(_) => ()
    _ => fail("unexpected hyperbolic-cosine-integral branch error")
  } noraise {
    _ => fail("expected complex hyperbolic-cosine-integral value")
  }
  assert_barnes_complex_close(
    ctx.complex_hyperbolic_cosine_integral(
      ctx.complex(ctx.from_int(-20), @mpf.RawMpf::zero()),
    ),
    "12807826.3320282943610629339487996274627064136343962909314054413475190555284611292007219651531337175943373328420070491783",
    "3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230665",
    "2e-98",
  )
}

///|
test "small hyperbolic and Fresnel integrals avoid cancellation" {
  let ctx = MPContext::new(500, Nearest)
  let input_context = MPContext::new(800, Nearest)
  let x = input_context.parse("1e-80")
  assert_close_mpf_str(ctx.hyperbolic_sine_integral(x), "1e-80", "2e-229")
  assert_close_mpf_str(
    ctx.hyperbolic_cosine_integral(x),
    "-183.6295917746221218608328042846667341770459597543619144838604648425209410474105337479428293438761171178427912761330928081918015331921379976970788155302576116223790513323014371297663176433061",
    "2e-143",
  )
  assert_close_mpf_str(
    ctx.fresnel_sine_integral(x),
    "5.235987755982988730771072305465838140328615665625176368291574320513027343810348331046724708903528446636913477522137177745156407682584303719542265680214135195750473504503230868509266074371582e-241",
    "2e-385",
  )
  assert_close_mpf_str(ctx.fresnel_cosine_integral(x), "1e-80", "2e-230")
}

///|
test "Fresnel integral infinities and odd symmetry are exact" {
  let ctx = MPContext::new(360, Nearest)
  for positive in [true, false] {
    let infinity = if positive {
      @mpf.RawMpf::infinity()
    } else {
      @mpf.RawMpf::negative_infinity()
    }
    let expected = if positive {
      @mpf.RawMpf::half()
    } else {
      @mpf.RawMpf::half().negated(0, Down)
    }
    @debug.assert_eq(ctx.fresnel_sine_integral(infinity), expected)
    @debug.assert_eq(ctx.fresnel_cosine_integral(infinity), expected)
  }
  let x = ctx.parse("3.25")
  @debug.assert_eq(
    ctx.fresnel_sine_integral(x.negated(0, Down)),
    ctx.fresnel_sine_integral(x).negated(360, Nearest),
  )
  @debug.assert_eq(
    ctx.fresnel_cosine_integral(x.negated(0, Down)),
    ctx.fresnel_cosine_integral(x).negated(360, Nearest),
  )
}

///|
test "large oscillatory Fresnel values retain their correction terms" {
  let ctx = MPContext::new(400, Nearest)
  let x = ctx.from_int(1000000000).mul_int(10, 0, Down)
  assert_close_mpf_str(
    ctx.fresnel_sine_integral(x),
    "0.499999999968169011381620932846223247325497127593109038397941706235142063849801297383812484538946481268445945634485688598",
    "2e-111",
  )
  assert_close_mpf_str(
    ctx.fresnel_cosine_integral(x),
    "0.499999999999999999999999999999898678816357662228556120536790272361095656624301135477657174697280727557078977290682045261",
    "2e-117",
  )
}

///|
test "large complex hyperbolic integrals preserve Ei branch corrections" {
  let ctx = MPContext::new(360, Nearest)
  let imaginary_axis = ctx.complex(@mpf.RawMpf::zero(), ctx.from_int(50))
  assert_barnes_complex_close(
    ctx.complex_hyperbolic_cosine_integral(imaginary_axis),
    "-0.00562838632411630544018589549846409957473375839534749948283951349874945380964527648369115346308012942319850911276337646406",
    "1.57079632679489661923132169163975144209858469968755291048747229615390820314310449931401741267105853399107404325664115332",
    "2e-104",
  )
  assert_barnes_complex_close(
    ctx.complex_hyperbolic_sine_integral(imaginary_axis),
    "0",
    "1.55161707248593589472798559485937754342000461591549367341918509476293747299004565871800424585201629502822091328780761818",
    "2e-104",
  )
  let upper = ctx.complex(ctx.from_int(2), ctx.from_int(50))
  let lower = ctx.complex(ctx.from_int(2), ctx.from_int(-50))
  let upper_chi = ctx.complex_hyperbolic_cosine_integral(upper)
  let upper_shi = ctx.complex_hyperbolic_sine_integral(upper)
  assert_barnes_complex_close(
    upper_chi, "-0.0183782829461330671492921645411135514710798609667039929933906071019663214897409847035384116898607863116473370326706659806",
    "1.50044351877120828303824300604256466483929115027820134389034247660786086342902734124905529884652099589768333120236702187",
    "2e-104",
  )
  assert_barnes_complex_close(
    upper_shi, "-0.0175150073784374479507600276497045529244131850557307285927490709287250171740213640028272878580047450505133090854478252646",
    "1.49788441427722846098227206158601971440168102300140928756262337883639019817926791005277519822762232694852764385636739661",
    "2e-104",
  )
  @debug.assert_eq(
    ctx.complex_hyperbolic_cosine_integral(lower),
    upper_chi.conjugate(360, Nearest),
  )
  @debug.assert_eq(
    ctx.complex_hyperbolic_sine_integral(lower),
    upper_shi.conjugate(360, Nearest),
  )
}
