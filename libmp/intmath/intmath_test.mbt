///|
test "bit helpers and gcd" {
  @debug.assert_eq(0N.bit_length(), 0)
  @debug.assert_eq((-15N).bit_length(), 4)
  @debug.assert_eq(40N.ctz(), 3)
  @debug.assert_eq((-40N).ctz(), 3)
  @debug.assert_eq(gcd(48N, 18N), 6N)
  @debug.assert_eq(gcd(-48N, 18N), 6N)
}

///|
test "isqrt and sqrtrem" {
  @debug.assert_eq(integer_sqrt(0N), 0N)
  @debug.assert_eq(integer_sqrt(1N), 1N)
  @debug.assert_eq(integer_sqrt(15N), 3N)
  @debug.assert_eq(integer_sqrt(16N), 4N)
  let (r, rem) = integer_sqrt_rem(27N)
  @debug.assert_eq(r, 5N)
  @debug.assert_eq(rem, 2N)
}

///|
test "bin_to_radix and numeral" {
  @debug.assert_eq(scale_binary_to_radix(5N, 1, 10, 3), 2500N)
  @debug.assert_eq(format_radix(255N, base=16), "ff")
  @debug.assert_eq(format_radix(-10N, base=2), "-1010")
}

///|
test "panic isqrt negative" {
  ignore(integer_sqrt(-1N))
}

///|
test "panic numeral invalid base" {
  ignore(format_radix(10N, base=1))
}
