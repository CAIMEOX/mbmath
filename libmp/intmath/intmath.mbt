///|
fn abs_bigint(x : BigInt) -> BigInt {
  if x < 0N {
    -x
  } else {
    x
  }
}

///|
pub(all) suberror IntMathError {
  ValueError(String)
} derive(Debug, Eq)

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
pub fn integer_sqrt(n : BigInt) -> BigInt raise IntMathError {
  if n < 0N {
    raise ValueError("isqrt: negative input")
  }
  if n <= 1N {
    n
  } else {
    let mut x = 1N << ((n.bit_length() + 1) / 2)
    while x > n / x {
      x = (x + n / x) >> 1
    } nobreak {
      x
    }
  }
}

///|
pub fn integer_sqrt_rem(n : BigInt) -> (BigInt, BigInt) raise IntMathError {
  if n < 0N {
    raise ValueError("sqrtrem: negative input")
  }
  let r = integer_sqrt(n)
  (r, n - r * r)
}

///|
pub fn scale_binary_to_radix(
  x : BigInt,
  xbits : Int,
  base : Int,
  bdigits : Int,
) -> BigInt raise IntMathError {
  if base <= 1 {
    raise ValueError("bin_to_radix: base must be greater than 1")
  }
  if bdigits < 0 {
    raise ValueError("bin_to_radix: bdigits must be non-negative")
  }
  let factor = BigInt::from_int(base).pow(BigInt::from_int(bdigits))
  if xbits >= 0 {
    (x * factor) >> xbits
  } else {
    (x * factor) << -xbits
  }
}

///|
pub fn format_radix(n : BigInt, base? : Int = 10) -> String raise IntMathError {
  if base < 2 || base > 36 {
    raise ValueError("numeral: base must be in [2, 36]")
  }
  n.to_string(radix=base)
}
