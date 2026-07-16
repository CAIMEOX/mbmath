///|
/// Return increasing working precisions suitable for an iteration with the
/// requested convergence order.
///
/// The last entry is always `target`. Earlier entries are conservatively
/// rounded so each precision increase is slightly smaller than `order`.
pub fn precision_steps(
  start : Int,
  target : Int,
  order? : Int = 2,
) -> Array[Int] raise IntMathError {
  if start < 0 || target < 0 {
    raise ValueError("precision_steps: precisions must be non-negative")
  }
  if start == 0 && target > 0 {
    raise ValueError(
      "precision_steps: start must be positive for a positive target",
    )
  }
  if order < 2 {
    raise ValueError("precision_steps: order must be at least 2")
  }
  let descending = [target]
  while BigInt::from_int(descending[descending.length() - 1]) >
        BigInt::from_int(start) * BigInt::from_int(order) {
    descending.push(descending[descending.length() - 1] / order + 2)
  }
  let result : Array[Int] = []
  let mut i = descending.length() - 1
  while i >= 0 {
    result.push(descending[i])
    i -= 1
  }
  result
}

///|
/// Return `floor(sqrt(x * 2^precision))` exactly.
///
/// This is the fixed-point square-root primitive used by higher-level
/// Newton iterations. Both `x` and `precision` must be non-negative.
pub fn scaled_integer_sqrt(
  x : BigInt,
  precision : Int,
) -> BigInt raise IntMathError {
  if x < 0N {
    raise ValueError("scaled_integer_sqrt: negative radicand")
  }
  if precision < 0 {
    raise ValueError("scaled_integer_sqrt: precision must be non-negative")
  }
  integer_sqrt(x << precision)
}
