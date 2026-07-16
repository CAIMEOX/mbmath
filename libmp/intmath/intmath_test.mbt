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
test "integer square root rejects negative input" {
  try integer_sqrt(-1N) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a negative integer square root")
  }
}

///|
test "radix formatting rejects an invalid base" {
  try format_radix(10N, base=1) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for an invalid radix")
  }
}

///|
test "precision steps follow the requested convergence order" {
  @debug.assert_eq(precision_steps(50, 1000), [66, 128, 253, 502, 1000])
  @debug.assert_eq(precision_steps(50, 1000, order=4), [65, 252, 1000])
  @debug.assert_eq(precision_steps(100, 100), [100])
}

///|
test "scaled integer square root is exactly floored" {
  @debug.assert_eq(scaled_integer_sqrt(2N, 10), 45N)
  @debug.assert_eq(scaled_integer_sqrt(81N, 0), 9N)
  @debug.assert_eq(scaled_integer_sqrt(0N, 200), 0N)
}

///|
test "integer Fibonacci and factorial families are exact" {
  @debug.assert_eq(fibonacci(0), 0N)
  @debug.assert_eq(fibonacci(100), 354224848179261915075N)
  @debug.assert_eq(fibonacci(-8), -21N)
  @debug.assert_eq(factorial(0), 1N)
  @debug.assert_eq(factorial(20), 2432902008176640000N)
  @debug.assert_eq(double_factorial(10), 3840N)
  @debug.assert_eq(double_factorial(9), 945N)
}

///|
test "prime enumeration and primality cover large BigInt inputs" {
  @debug.assert_eq(primes_up_to(20), [2, 3, 5, 7, 11, 13, 17, 19])
  @debug.assert_eq(primes_up_to(1), [])
  @debug.assert_eq(is_prime(2N), true)
  @debug.assert_eq(is_prime(32416190071N), true)
  @debug.assert_eq(is_prime(1050809297549059045041N), false)
  @debug.assert_eq(is_prime(341550071728321N), false)
}

///|
test "Moebius Euler and Stirling values match mpmath integer semantics" {
  @debug.assert_eq(moebius(0), 0)
  @debug.assert_eq(moebius(1), 1)
  @debug.assert_eq(moebius(-30), -1)
  @debug.assert_eq(moebius(12), 0)
  @debug.assert_eq(
    [
      euler_number(0),
      euler_number(1),
      euler_number(2),
      euler_number(3),
      euler_number(4),
      euler_number(5),
      euler_number(6),
      euler_number(8),
      euler_number(10),
    ],
    [1N, 0N, -1N, 0N, 5N, 0N, -61N, 1385N, -50521N],
  )
  @debug.assert_eq(
    [
      stirling_first(5, 0),
      stirling_first(5, 1),
      stirling_first(5, 2),
      stirling_first(5, 3),
      stirling_first(5, 4),
      stirling_first(5, 5),
    ],
    [0N, 24N, -50N, 35N, -10N, 1N],
  )
  @debug.assert_eq(
    [
      stirling_second(5, 0),
      stirling_second(5, 1),
      stirling_second(5, 2),
      stirling_second(5, 3),
      stirling_second(5, 4),
      stirling_second(5, 5),
    ],
    [0N, 1N, 15N, 25N, 10N, 1N],
  )
}

///|
test "large exact integer values match mpmath reference vectors" {
  @debug.assert_eq(
    fibonacci(500),
    139423224561697880139724382870407283950070256587697307264108962948325571622863290691557658876222521294125N,
  )
  @debug.assert_eq(euler_number(20), 370371188237525N)
  @debug.assert_eq(
    euler_number(50),
    -6053285248188621896314383785111649088103498225146815121N,
  )
  @debug.assert_eq(stirling_first(30, 7), -11139316913434780466101123891200N)
  @debug.assert_eq(stirling_second(30, 7), 4168916722553086402080N)
  @debug.assert_eq(
    scaled_integer_sqrt(12345678901234567890N, 257),
    1690876667901597630746076699535774523476031487742N,
  )
}

///|
test "exact integer domain failures are structured" {
  try scaled_integer_sqrt(-1N, 10) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a negative scaled square root")
  }
  try stirling_first(-1, 0) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for negative Stirling indices")
  }
  try double_factorial(-1) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a negative double factorial")
  }
}

///|
test "precision steps reject an invalid convergence order" {
  try precision_steps(10, 100, order=1) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for convergence order below two")
  }
}

///|
test "precision steps reject zero start for positive target" {
  try precision_steps(0, 100) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a zero starting precision")
  }
}

///|
test "factorial rejects a negative argument" {
  try factorial(-1) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a negative factorial")
  }
}

///|
test "Euler number rejects a negative index" {
  try euler_number(-2) catch {
    ValueError(_) => ()
  } noraise {
    _ => fail("expected ValueError for a negative Euler index")
  }
}
