///|
test "bit helpers and gcd" {
  @debug.assert_eq(bit_length(0N), 0)
  @debug.assert_eq(bitcount(-15N), 4)
  @debug.assert_eq(trailing(40N), 3)
  @debug.assert_eq(trailing_zero_bits(-40N), 3)
  @debug.assert_eq(gcd(48N, 18N), 6N)
  @debug.assert_eq(gcd(-48N, 18N), 6N)
}

///|
test "isqrt and sqrtrem" {
  @debug.assert_eq(isqrt(0N), 0N)
  @debug.assert_eq(isqrt(1N), 1N)
  @debug.assert_eq(isqrt(15N), 3N)
  @debug.assert_eq(isqrt(16N), 4N)
  let (r, rem) = sqrtrem(27N)
  @debug.assert_eq(r, 5N)
  @debug.assert_eq(rem, 2N)
}

///|
test "bin_to_radix and numeral" {
  @debug.assert_eq(bin_to_radix(5N, 1, 10, 3), 2500N)
  @debug.assert_eq(numeral(255N, base=16), "ff")
  @debug.assert_eq(numeral(-10N, base=2), "-1010")
}

///|
test "panic isqrt negative" {
  ignore(isqrt(-1N))
}

///|
test "panic numeral invalid base" {
  ignore(numeral(10N, base=1))
}
