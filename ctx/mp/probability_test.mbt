///|
test "inverse error function central values and endpoints match mpmath" {
  let ctx = MPContext::new(400, Nearest)
  @debug.assert_eq(
    ctx.inverse_error_function(@mpf.RawMpf::zero()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.inverse_error_function(@mpf.RawMpf::one()),
    @mpf.RawMpf::infinity(),
  )
  @debug.assert_eq(
    ctx.inverse_error_function(@mpf.RawMpf::negative_one()),
    @mpf.RawMpf::negative_infinity(),
  )
  let half = @mpf.RawMpf::half()
  let expected = "0.47693627620446987338141835364313055980896974905947064470388269591938344777464673348869591586998900994803303867347086861815542007544873179062"
  assert_close_mpf_str(ctx.inverse_error_function(half), expected, "2e-118")
  assert_close_mpf_str(
    ctx.inverse_error_function(half.negated(0, Down)),
    "-0.47693627620446987338141835364313055980896974905947064470388269591938344777464673348869591586998900994803303867347086861815542007544873179062",
    "2e-118",
  )
}

///|
test "inverse error function resolves an extreme endpoint tail" {
  let ctx = MPContext::new(500, Nearest)
  let input_context = MPContext::new(900, Nearest)
  let one_minus_tail = input_context.sub(
    input_context.from_int(1),
    input_context.parse("1e-100"),
  )
  assert_close_mpf_str(
    ctx.inverse_error_function(one_minus_tail),
    "15.065574702592645704404610541368897995968009540406658745025123629817516029433931656615329706556189201181562559799773206785384149295451872332098414248619128212520752333144",
    "2e-145",
  )
}

///|
test "inverse error function propagates domain and NaN semantics" {
  let ctx = MPContext::new(300, Nearest)
  assert_true(ctx.inverse_error_function(@mpf.RawMpf::nan()).is_nan())
  for x in [ctx.parse("1.01"), ctx.parse("-1.01")] {
    try ctx.inverse_error_function(x) catch {
      DomainError(_) => ()
      _ => fail("unexpected inverse error function domain error")
    } noraise {
      _ => fail("expected inverse error function domain error")
    }
  }
}

///|
test "real normal density and distribution tails match mpmath" {
  let ctx = MPContext::new(400, Nearest)
  assert_close_mpf_str(
    ctx.normal_probability_density(
      ctx.from_int(5),
      mean=ctx.from_int(0),
      standard_deviation=ctx.from_int(2),
    ),
    "0.008764150246784268681079161083374293074257087758860115210060160847961956697201097113168864429965725501627553086990993196797156952619",
    "2e-121",
  )
  assert_close_mpf_str(
    ctx.normal_cumulative_distribution(ctx.from_int(-10)),
    "0.000000000000000000000007619853024160526065973343251599308363504033277956960578035355462896615622059648170334151385182804671608163038227989829897198170614",
    "2e-141",
  )
  @debug.assert_eq(
    ctx.normal_cumulative_distribution(ctx.from_int(3), mean=ctx.from_int(3)),
    @mpf.RawMpf::half(),
  )
  @debug.assert_eq(
    ctx.normal_probability_density(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.normal_cumulative_distribution(@mpf.RawMpf::negative_infinity()),
    @mpf.RawMpf::zero(),
  )
  @debug.assert_eq(
    ctx.normal_cumulative_distribution(@mpf.RawMpf::infinity()),
    @mpf.RawMpf::one(),
  )
  assert_true(ctx.normal_probability_density(@mpf.RawMpf::nan()).is_nan())
  assert_true(ctx.normal_cumulative_distribution(@mpf.RawMpf::nan()).is_nan())
}

///|
test "normal distribution parameter semantics match mpmath formulas" {
  let ctx = MPContext::new(400, Nearest)
  let negative_sigma = ctx.from_int(-2)
  assert_close_mpf_str(
    ctx.normal_probability_density(
      ctx.from_int(5),
      standard_deviation=negative_sigma,
    ),
    "-0.008764150246784268681079161083374293074257087758860115210060160847961956697201097113168864429965725501627553086990993196797156952619",
    "2e-121",
  )
  assert_close_mpf_str(
    ctx.normal_cumulative_distribution(
      ctx.from_int(5),
      standard_deviation=negative_sigma,
    ),
    "0.00620966532577613516697810457419222112789774692309276826856285470333023640775249632488341223199407500754214328546773805547966646393",
    "2e-120",
  )
  for density in [true, false] {
    try {
      if density {
        ignore(
          ctx.normal_probability_density(
            ctx.from_int(1),
            standard_deviation=@mpf.RawMpf::zero(),
          ),
        )
      } else {
        ignore(
          ctx.normal_cumulative_distribution(
            ctx.from_int(1),
            standard_deviation=@mpf.RawMpf::zero(),
          ),
        )
      }
    } catch {
      PoleError(_) => ()
      _ => fail("unexpected zero-deviation error")
    } noraise {
      _ => fail("expected zero-deviation error")
    }
  }
}

///|
test "complex normal density and distribution match mpmath" {
  let ctx = MPContext::new(400, Nearest)
  let z = ctx.complex(ctx.from_int(2), ctx.from_int(3))
  let mean = ctx.complex(ctx.parse("0.5"), ctx.parse("-0.25"))
  let sigma = ctx.complex(ctx.parse("1.25"), ctx.parse("0.5"))
  assert_barnes_complex_close(
    ctx.complex_normal_probability_density(z, mean~, standard_deviation=sigma),
    "-0.1754813829130206888899318048468280440027576247823924297238685635092059469152944902243106734286497152676725284558711221118448583819",
    "0.1694946020526615930046490267855011487109332444077892527094535741774320750600425467943174181335183969313160041298492687417573660548",
    "2e-120",
  )
  assert_barnes_complex_close(
    ctx.complex_normal_cumulative_distribution(
      z,
      mean~,
      standard_deviation=sigma,
    ),
    "1.061496691715163810131398799190025243679447020044812761317895538943272643012622838268680578469989630431939149895148410281629316276",
    "-0.1015107545640919638237773923021155540828621997777676676503464987016908866480282776860896649755881462436578308054462396662291036694",
    "2e-119",
  )
  try
    ctx.complex_normal_probability_density(
      z,
      standard_deviation=@mpc.RawMpc::zero(),
    )
  catch {
    PoleError(_) => ()
    _ => fail("unexpected complex zero-deviation error")
  } noraise {
    _ => fail("expected complex zero-deviation error")
  }
}
