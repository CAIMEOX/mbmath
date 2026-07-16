///|
/// Return all prime numbers less than or equal to `limit`.
pub fn primes_up_to(limit : Int) -> Array[Int] {
  if limit < 2 {
    return []
  }
  let sieve : Array[Bool] = []
  for _ in 0..<=limit {
    sieve.push(true)
  }
  sieve[0] = false
  sieve[1] = false
  let mut p = 2
  while p <= limit / p {
    if sieve[p] {
      let mut multiple = p * p
      while multiple <= limit {
        sieve[multiple] = false
        multiple += p
      }
    }
    p += 1
  }
  let result : Array[Int] = []
  for n in 2..<=limit {
    if sieve[n] {
      result.push(n)
    }
  }
  result
}

///|
fn miller_rabin_witness(n : BigInt, d : BigInt, s : Int, base : Int) -> Bool {
  let n_minus_one = n - 1N
  let mut x = BigInt::from_int(base).pow(d, modulus=n)
  if x == 1N || x == n_minus_one {
    return true
  }
  for _ in 1..<s {
    x = x.pow(2N, modulus=n)
    if x == n_minus_one {
      return true
    }
  }
  false
}

///|
/// Determine whether an arbitrary-size integer is prime.
///
/// Small factors are removed exactly. Remaining candidates use the same
/// deterministic witness bounds as mpmath through `341550071728321`; larger
/// inputs use its fixed small-prime Miller-Rabin witness set.
pub fn is_prime(n : BigInt) -> Bool {
  if n < 2N {
    return false
  }
  if (n & 1N) == 0N {
    return n == 2N
  }
  let small_primes = [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
  if n < 50N {
    for p in small_primes {
      if n == BigInt::from_int(p) {
        return true
      }
    }
    return false
  }
  for p in small_primes {
    if n % BigInt::from_int(p) == 0N {
      return false
    }
  }
  let n_minus_one = n - 1N
  let s = n_minus_one.ctz()
  let d = n_minus_one >> s
  let witnesses = if n < 1373653N {
    [2, 3]
  } else if n < 341550071728321N {
    [2, 3, 5, 7, 11, 13, 17]
  } else {
    small_primes
  }
  for base in witnesses {
    if !miller_rabin_witness(n, d, s, base) {
      return false
    }
  }
  true
}

///|
/// Evaluate the Möbius function `mu(n)` exactly for arbitrary-size integers.
pub fn moebius(n : BigInt) -> Int {
  let mut value = abs_bigint(n)
  if value < 2N {
    return value.to_int()
  }
  let mut factors = 0
  let mut p = 2N
  while p <= value / p {
    if value % p == 0N {
      value /= p
      factors += 1
      if value % p == 0N {
        return 0
      }
    }
    p = if p == 2N { 3N } else { p + 2N }
  }
  if value > 1N {
    factors += 1
  }
  if (factors & 1) == 0 {
    1
  } else {
    -1
  }
}
