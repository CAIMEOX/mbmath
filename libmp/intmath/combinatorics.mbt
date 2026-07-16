///|
/// Return the exact `n`th Fibonacci number.
///
/// Negative indices follow the negafibonacci identity
/// `F(-n) = (-1)^(n+1) F(n)`. The implementation uses logarithmic fast
/// doubling and therefore does not lose precision for large values.
pub fn fibonacci(n : Int) -> BigInt {
  let negative = n < 0
  let mut k = if negative { -n } else { n }
  let mut a = 1N
  let mut b = 0N
  let mut p = 0N
  let mut q = 1N
  while k != 0 {
    if (k & 1) == 1 {
      let aq = a * q
      a = b * q + aq + a * p
      b = b * p + aq
      k -= 1
    } else {
      let old_p = p
      let old_q = q
      let qq = old_q * old_q
      p = old_p * old_p + qq
      q = qq + 2N * old_p * old_q
      k = k >> 1
    }
  }
  if negative && n % 2 == 0 {
    -b
  } else {
    b
  }
}

///|
/// Return the exact factorial `n!` for a non-negative integer.
pub fn factorial(n : Int) -> BigInt raise IntMathError {
  if n < 0 {
    raise ValueError("factorial: argument must be non-negative")
  }
  let mut result = 1N
  for k in 2..<=n {
    result *= BigInt::from_int(k)
  }
  result
}

///|
/// Return the exact double factorial `n!!` for a non-negative integer.
pub fn double_factorial(n : Int) -> BigInt raise IntMathError {
  if n < 0 {
    raise ValueError("double_factorial: argument must be non-negative")
  }
  let mut result = 1N
  let mut k = n
  while k > 1 {
    result *= BigInt::from_int(k)
    k -= 2
  }
  result
}

///|
/// Return the exact Euler number `E_n` from the expansion of `1 / cosh(x)`.
///
/// Odd-index Euler numbers are zero. Negative indices are outside the exact
/// integer sequence and raise `IntMathError::ValueError`.
pub fn euler_number(n : Int) -> BigInt raise IntMathError {
  if n < 0 {
    raise ValueError("euler_number: index must be non-negative")
  }
  if (n & 1) == 1 {
    return 0N
  }
  let a = [0N, 0N, 1N, 0N, 0N, 0N]
  let mut sum = 1N
  let mut m = 1
  while m <= n {
    let mut j = m + 1
    while j >= 0 {
      a[j + 1] = BigInt::from_int(j - 1) * a[j] +
        BigInt::from_int(j + 1) * a[j + 2]
      j -= 2
    }
    a.push(0N)
    sum = 0N
    let mut k = m + 1
    while k >= 0 {
      sum += a[k + 1]
      k -= 2
    }
    m += 1
  }
  let value = sum / (1N << n)
  if ((n / 2) & 1) == 1 {
    -value
  } else {
    value
  }
}

///|
/// Return the signed Stirling number of the first kind `s(n, k)` exactly.
pub fn stirling_first(n : Int, k : Int) -> BigInt raise IntMathError {
  if n < 0 || k < 0 {
    raise ValueError("stirling_first: indices must be non-negative")
  }
  if k > n {
    return 0N
  }
  let values : Array[BigInt] = []
  for _ in 0..<=k {
    values.push(0N)
  }
  values[0] = 1N
  for i in 1..<=n {
    let mut j = i.min(k)
    while j > 0 {
      values[j] = values[j - 1] - BigInt::from_int(i - 1) * values[j]
      j -= 1
    }
    values[0] = 0N
  }
  values[k]
}

///|
/// Return the Stirling number of the second kind `S(n, k)` exactly.
pub fn stirling_second(n : Int, k : Int) -> BigInt raise IntMathError {
  if n < 0 || k < 0 {
    raise ValueError("stirling_second: indices must be non-negative")
  }
  if k > n {
    return 0N
  }
  let values : Array[BigInt] = []
  for _ in 0..<=k {
    values.push(0N)
  }
  values[0] = 1N
  for i in 1..<=n {
    let mut j = i.min(k)
    while j > 0 {
      values[j] = values[j - 1] + BigInt::from_int(j) * values[j]
      j -= 1
    }
    values[0] = 0N
  }
  values[k]
}
