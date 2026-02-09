///|
test "bit helpers and gcd" {
  assert_eq(bit_length(0N), 0)
  assert_eq(bitcount(-15N), 4)
  assert_eq(trailing(40N), 3)
  assert_eq(trailing_zero_bits(-40N), 3)
  assert_eq(gcd(48N, 18N), 6N)
  assert_eq(gcd(-48N, 18N), 6N)
}

///|
test "isqrt and sqrtrem" {
  assert_eq(isqrt(0N), 0N)
  assert_eq(isqrt(1N), 1N)
  assert_eq(isqrt(15N), 3N)
  assert_eq(isqrt(16N), 4N)
  let (r, rem) = sqrtrem(27N)
  assert_eq(r, 5N)
  assert_eq(rem, 2N)
}

///|
test "bin_to_radix and numeral" {
  assert_eq(bin_to_radix(5N, 1, 10, 3), 2500N)
  assert_eq(numeral(255N, base=16), "ff")
  assert_eq(numeral(-10N, base=2), "-1010")
}

///|
test "panic isqrt negative" {
  ignore(isqrt(-1N))
}

///|
test "panic numeral invalid base" {
  ignore(numeral(10N, base=1))
}
