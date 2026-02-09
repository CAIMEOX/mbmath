///|
fn abs_bigint(x : BigInt) -> BigInt {
  if x < 0N {
    -x
  } else {
    x
  }
}

///|
pub fn bit_length(x : BigInt) -> Int {
  x.bit_length()
}

///|
pub fn bitcount(x : BigInt) -> Int {
  abs_bigint(x).bit_length()
}

///|
pub fn trailing_zero_bits(x : BigInt) -> Int {
  trailing(x)
}

///|
pub fn trailing(x : BigInt) -> Int {
  let n = abs_bigint(x)
  if n == 0N {
    0
  } else {
    n.ctz()
  }
}

///|
pub fn gcd(a : BigInt, b : BigInt) -> BigInt {
  let mut x = abs_bigint(a)
  let mut y = abs_bigint(b)
  while y != 0N {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
pub fn isqrt(n : BigInt) -> BigInt {
  if n < 0N {
    abort("isqrt: negative input")
  }
  if n <= 1N {
    n
  } else {
    let mut x = 1N << ((n.bit_length() + 1) / 2)
    while x > n / x {
      x = (x + n / x) >> 1
    } else {
      x
    }
  }
}

///|
pub fn sqrtrem(n : BigInt) -> (BigInt, BigInt) {
  if n < 0N {
    abort("sqrtrem: negative input")
  }
  let r = isqrt(n)
  (r, n - r * r)
}

///|
pub fn bin_to_radix(
  x : BigInt,
  xbits : Int,
  base : Int,
  bdigits : Int,
) -> BigInt {
  if base <= 1 {
    abort("bin_to_radix: base must be greater than 1")
  }
  if bdigits < 0 {
    abort("bin_to_radix: bdigits must be non-negative")
  }
  let factor = BigInt::from_int(base).pow(BigInt::from_int(bdigits))
  if xbits >= 0 {
    (x * factor) >> xbits
  } else {
    (x * factor) << -xbits
  }
}

///|
pub fn numeral(n : BigInt, base? : Int = 10) -> String {
  if base < 2 || base > 36 {
    abort("numeral: base must be in [2, 36]")
  }
  n.to_string(radix=base)
}
