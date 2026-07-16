///|
enum ParseState {
  Mantissa
  ExpSignOrDigit
  ExpDigits
} derive(Eq)

///|
priv struct ParsedFormatSpec {
  fill : Char
  align : Char
  sign : Char
  no_neg_0 : Bool
  alternate : Bool
  int_group_sep : Char?
  frac_group_sep : Char?
  rounding : RoundMode?
  width : Int
  precision : Int?
  ty : Char
}

///|
fn slice_owned(s : StringView, start : Int, end : Int) -> String {
  s.view(start_offset=start, end_offset=end).to_owned()
}

///|
fn pow5(n : Int) -> BigInt {
  let mut acc = 1N
  for _ in 0..<n {
    acc = acc * 5N
  }
  acc
}

///|
fn pow10(n : Int) -> BigInt {
  let mut acc = 1N
  for _ in 0..<n {
    acc = acc * 10N
  }
  acc
}

///|
fn trim_leading_zeros_digits(s : StringView) -> String {
  match s.find_by(c => c != '0') {
    Some(i) => s.view(start_offset=i).to_owned()
    None => "0"
  }
}

///|
fn trim_trailing_zeros_decimal_digits(s : StringView) -> String {
  let mut end = s.length()
  while end > 0 {
    match s.get_char(end - 1) {
      Some('0') => end -= 1
      _ => break
    }
  }
  if end == 0 {
    "0"
  } else {
    s.view(end_offset=end).to_owned()
  }
}

///|
fn parse_signed_decimal_int(s : StringView) -> Int raise MpfError {
  if s.is_empty() {
    raise ParseError("RawMpf::parse: empty exponent")
  }
  let mut sign = 1
  let mut start = 0
  match s.get_char(0) {
    Some('+') => start = 1
    Some('-') => {
      sign = -1
      start = 1
    }
    _ => ()
  }
  let mut has_digit = false
  let mut value = 0
  for i, c in s.iter2() {
    if i < start {
      continue
    }
    if c == '_' {
      continue
    }
    if !c.is_ascii_digit() {
      raise ParseError("RawMpf::parse: invalid exponent")
    }
    has_digit = true
    let d = c.to_int() - '0'.to_int()
    value = value * 10 + d
  }
  if !has_digit {
    raise ParseError("RawMpf::parse: missing exponent digits")
  }
  sign * value
}

///|
fn parse_decimal_finite(
  text : StringView,
  target_prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  let mut state = ParseState::Mantissa
  let mut sign = 0
  let mut idx = 0
  let digits_builder = StringBuilder(size_hint=text.length())
  let mut has_digit = false
  let mut seen_dot = false
  let mut frac_len = 0
  let mut exp_sign = 1
  let mut exp_value = 0
  let mut exp_has_digit = false
  for c in text {
    match state {
      Mantissa =>
        if (c == '+' || c == '-') && idx == 0 {
          sign = if c == '-' { 1 } else { 0 }
        } else if c == '_' {
          ignore(c)
        } else if c.is_ascii_digit() {
          digits_builder.write_char(c)
          has_digit = true
          if seen_dot {
            frac_len += 1
          }
        } else if c == '.' {
          if seen_dot {
            raise ParseError("RawMpf::parse: multiple decimal points")
          }
          seen_dot = true
        } else if c == 'e' || c == 'E' {
          if !has_digit {
            raise ParseError("RawMpf::parse: invalid mantissa")
          }
          state = ExpSignOrDigit
        } else {
          raise ParseError("RawMpf::parse: invalid character")
        }
      ExpSignOrDigit =>
        if c == '+' {
          exp_sign = 1
          state = ExpDigits
        } else if c == '-' {
          exp_sign = -1
          state = ExpDigits
        } else if c == '_' {
          ignore(c)
        } else if c.is_ascii_digit() {
          exp_has_digit = true
          exp_value = c.to_int() - '0'.to_int()
          state = ExpDigits
        } else {
          raise ParseError("RawMpf::parse: invalid exponent")
        }
      ExpDigits =>
        if c == '_' {
          ignore(c)
        } else if c.is_ascii_digit() {
          exp_has_digit = true
          let d = c.to_int() - '0'.to_int()
          exp_value = exp_value * 10 + d
        } else {
          raise ParseError("RawMpf::parse: invalid exponent")
        }
    }
    idx += 1
  }
  if !has_digit {
    raise ParseError("RawMpf::parse: no digits")
  }
  if state == ExpSignOrDigit || (state == ExpDigits && !exp_has_digit) {
    raise ParseError("RawMpf::parse: missing exponent digits")
  }
  let digits = trim_leading_zeros_digits(digits_builder.to_string())
  if digits == "0" {
    return RawMpf::zero()
  }
  let digits_big = BigInt::from_string(digits)
  let signed_digits = if sign == 0 { digits_big } else { -digits_big }
  let exp10 = exp_sign * exp_value - frac_len
  if exp10 >= 0 {
    let p5 = pow5(exp10)
    RawMpf::from_mantissa_exponent(signed_digits * p5, exp10, target_prec, rnd)
  } else {
    let k = -exp10
    let numerator = RawMpf::from_mantissa_exponent(signed_digits, -k, 0, Down)
    let denominator = RawMpf::from_mantissa_exponent(pow5(k), 0, 0, Down)
    numerator.div(denominator, target_prec, rnd)
  }
}

///|
fn parse_hex_finite(
  text : StringView,
  target_prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  let mut sign = 0
  let mut body = text
  if body.has_prefix("+") {
    body = body.view(start_offset=1)
  } else if body.has_prefix("-") {
    sign = 1
    body = body.view(start_offset=1)
  }
  let body_lower = body.to_lower()
  if !body_lower.has_prefix("0x") {
    raise ParseError("RawMpf::parse: invalid hex literal")
  }
  let hex_body = body_lower.view(start_offset=2)
  let mut marker_index = -1
  let mut marker = ' '
  for i, c in hex_body.iter2() {
    if c == 'p' || c == '@' {
      marker_index = i
      marker = c
      break
    }
  }
  let mant_part = if marker_index >= 0 {
    hex_body.view(end_offset=marker_index)
  } else {
    hex_body
  }
  let exp_part = if marker_index >= 0 {
    hex_body.view(start_offset=marker_index + 1)
  } else {
    ""
  }
  let mut exp2 = 0
  if marker_index >= 0 {
    let e = parse_signed_decimal_int(exp_part)
    exp2 = if marker == '@' { e * 4 } else { e }
  }
  let digits_builder = StringBuilder(size_hint=mant_part.length())
  let mut has_digit = false
  let mut seen_dot = false
  let mut frac_hex_len = 0
  for c in mant_part {
    if c == '_' {
      continue
    }
    if c == '.' {
      if seen_dot {
        raise ParseError("RawMpf::parse: multiple decimal points")
      }
      seen_dot = true
      continue
    }
    if !c.is_ascii_hexdigit() {
      raise ParseError("RawMpf::parse: invalid hex digit")
    }
    digits_builder.write_char(c)
    has_digit = true
    if seen_dot {
      frac_hex_len += 1
    }
  }
  if !has_digit {
    raise ParseError("RawMpf::parse: invalid hex literal")
  }
  let digits = trim_leading_zeros_digits(digits_builder.to_string())
  if digits == "0" {
    return RawMpf::zero()
  }
  let mut man = BigInt::from_string(digits, radix=16)
  if sign == 1 {
    man = -man
  }
  exp2 -= frac_hex_len * 4
  RawMpf::from_mantissa_exponent(man, exp2, target_prec, rnd)
}

///|
fn parse_pow2_finite(
  text : StringView,
  prefix : StringView,
  radix : Int,
  bits_per_digit : Int,
  target_prec : Int,
  rnd : RoundMode,
) -> RawMpf raise MpfError {
  let mut sign = 0
  let mut body = text
  if body.has_prefix("+") {
    body = body.view(start_offset=1)
  } else if body.has_prefix("-") {
    sign = 1
    body = body.view(start_offset=1)
  }
  let lower = body.to_lower()
  if !lower.has_prefix(prefix) {
    raise ParseError("RawMpf::parse: invalid literal")
  }
  let mant_part = lower.view(start_offset=prefix.length())
  let digits_builder = StringBuilder(size_hint=mant_part.length())
  let mut has_digit = false
  let mut seen_dot = false
  let mut frac_len = 0
  for c in mant_part {
    if c == '_' {
      continue
    }
    if c == '.' {
      if seen_dot {
        raise ParseError("RawMpf::parse: multiple decimal points")
      }
      seen_dot = true
      continue
    }
    let valid = if radix == 2 {
      c == '0' || c == '1'
    } else {
      c >= '0' && c <= '7'
    }
    if !valid {
      raise ParseError("RawMpf::parse: invalid digit")
    }
    digits_builder.write_char(c)
    has_digit = true
    if seen_dot {
      frac_len += 1
    }
  }
  if !has_digit {
    raise ParseError("RawMpf::parse: invalid literal")
  }
  let digits = trim_leading_zeros_digits(digits_builder.to_string())
  if digits == "0" {
    return RawMpf::zero()
  }
  let mut man = BigInt::from_string(digits, radix~)
  if sign == 1 {
    man = -man
  }
  let exp2 = -(frac_len * bits_per_digit)
  RawMpf::from_mantissa_exponent(man, exp2, target_prec, rnd)
}

///|
pub fn RawMpf::parse(
  s : StringView,
  prec? : Int = 0,
  rnd? : RoundMode = Nearest,
) -> RawMpf raise MpfError {
  let text = s.trim()
  if text.is_empty() {
    raise ParseError("RawMpf::parse: empty input")
  }
  let lower = text.to_lower()
  if lower == "inf" ||
    lower == "+inf" ||
    lower == "infinity" ||
    lower == "+infinity" {
    return RawMpf::infinity()
  }
  if lower == "-inf" || lower == "-infinity" {
    return RawMpf::negative_infinity()
  }
  if lower == "nan" || lower == "+nan" || lower == "-nan" {
    return RawMpf::nan()
  }
  let target_prec = if prec > 0 { prec } else { 53 }
  let mut check = text
  if check.has_prefix("+") || check.has_prefix("-") {
    check = check.view(start_offset=1)
  }
  let low_check = check.to_lower()
  if low_check.has_prefix("0x") {
    parse_hex_finite(text, target_prec, rnd)
  } else if low_check.has_prefix("0b") {
    parse_pow2_finite(text, "0b", 2, 1, target_prec, rnd)
  } else if low_check.has_prefix("0o") {
    parse_pow2_finite(text, "0o", 8, 3, target_prec, rnd)
  } else {
    parse_decimal_finite(text, target_prec, rnd)
  }
}

///|
fn fixed_parts(x : RawMpf) -> (String, String) {
  if x.exp >= 0 {
    ((x.man << x.exp).to_string(), "0")
  } else {
    let k = -x.exp
    let scaled = x.man * pow5(k)
    let digits = scaled.to_string()
    let len = digits.length()
    if len > k {
      let int_part = slice_owned(digits, 0, len - k)
      let frac_part = slice_owned(digits, len - k, len)
      (int_part, trim_trailing_zeros_decimal_digits(frac_part))
    } else {
      let zeros = "0".repeat(k - len)
      let frac_part = trim_trailing_zeros_decimal_digits(zeros + digits)
      ("0", frac_part)
    }
  }
}

///|
fn first_non_zero_index(s : String) -> Int? {
  s.find_by(c => c != '0')
}

///|
fn exact_digits_exp(x : RawMpf) -> (String, Int) raise MpfError {
  let (int_part, frac_part) = fixed_parts(x)
  if int_part != "0" {
    let frac = if frac_part == "0" { "" } else { frac_part }
    let digits = trim_leading_zeros_digits(int_part + frac)
    (digits, int_part.length() - 1)
  } else {
    guard first_non_zero_index(frac_part) is Some(idx) else {
      raise FormatError("cannot format an invalid finite representation")
    }
    let digits = slice_owned(frac_part, idx, frac_part.length())
    (digits, -(idx + 1))
  }
}

///|
fn round_significant(
  digits : String,
  exp10 : Int,
  dps : Int,
) -> (String, Int) raise MpfError {
  if digits.length() <= dps {
    (digits, exp10)
  } else {
    let kept = slice_owned(digits, 0, dps)
    guard digits.get_char(dps) is Some(next) else {
      raise FormatError("cannot round an invalid digit sequence")
    }
    let rest_has_nonzero = if dps + 1 >= digits.length() {
      false
    } else {
      let rest = slice_owned(digits, dps + 1, digits.length())
      first_non_zero_index(rest) is Some(_)
    }
    guard kept.get_char(kept.length() - 1) is Some(last_kept) else {
      raise FormatError("cannot round an empty digit sequence")
    }
    let last_digit = last_kept.to_int() - '0'.to_int()
    let should_increment = if next > '5' {
      true
    } else if next < '5' {
      false
    } else {
      rest_has_nonzero || last_digit % 2 == 1
    }
    if !should_increment {
      (kept, exp10)
    } else {
      let inc = (BigInt::from_string(kept) + 1N).to_string()
      if inc.length() > kept.length() {
        (slice_owned(inc, 0, dps), exp10 + 1)
      } else {
        (inc, exp10)
      }
    }
  }
}

///|
fn rounding_for_abs(rnd : RoundMode, sign : Int) -> RoundMode {
  if sign == 0 {
    rnd
  } else {
    match rnd {
      Floor => Ceiling
      Ceiling => Floor
      _ => rnd
    }
  }
}

///|
fn round_div_nonnegative(num : BigInt, den : BigInt, rnd : RoundMode) -> BigInt {
  let q = num / den
  let r = num % den
  if r == 0N {
    return q
  }
  match rnd {
    Down => q
    Floor => q
    Up => q + 1N
    Ceiling => q + 1N
    Nearest => {
      let twice = r * 2N
      if twice > den || (twice == den && (q & 1N) == 1N) {
        q + 1N
      } else {
        q
      }
    }
  }
}

///|
fn round_significant_with_mode(
  digits : String,
  exp10 : Int,
  dps : Int,
  rnd : RoundMode,
) -> (String, Int) raise MpfError {
  if digits.length() <= dps {
    (digits, exp10)
  } else {
    let kept = slice_owned(digits, 0, dps)
    let rest = slice_owned(digits, dps, digits.length())
    let rest_has_nonzero = first_non_zero_index(rest) is Some(_)
    guard digits.get_char(dps) is Some(next) else {
      raise FormatError("cannot round an invalid digit sequence")
    }
    let should_increment = match rnd {
      Down => false
      Floor => false
      Up => rest_has_nonzero
      Ceiling => rest_has_nonzero
      Nearest => {
        let rest_tail_has_nonzero = if dps + 1 >= digits.length() {
          false
        } else {
          let tail = slice_owned(digits, dps + 1, digits.length())
          first_non_zero_index(tail) is Some(_)
        }
        guard kept.get_char(kept.length() - 1) is Some(last_kept) else {
          raise FormatError("cannot round an empty digit sequence")
        }
        let last_digit = last_kept.to_int() - '0'.to_int()
        if next > '5' {
          true
        } else if next < '5' {
          false
        } else {
          rest_tail_has_nonzero || last_digit % 2 == 1
        }
      }
    }
    if !should_increment {
      (kept, exp10)
    } else {
      let inc = (BigInt::from_string(kept) + 1N).to_string()
      if inc.length() > kept.length() {
        (slice_owned(inc, 0, dps), exp10 + 1)
      } else {
        (inc, exp10)
      }
    }
  }
}

///|
fn should_use_scientific(exp10 : Int, min_fixed : Int, max_fixed : Int) -> Bool {
  exp10 < min_fixed || exp10 >= max_fixed
}

///|
fn mantissa_from_digits(digits : String) -> String {
  if digits.length() == 1 {
    digits + ".0"
  } else {
    let head = slice_owned(digits, 0, 1)
    let raw_tail = slice_owned(digits, 1, digits.length())
    let tail = trim_trailing_zeros_decimal_digits(raw_tail)
    if tail == "0" {
      head + ".0"
    } else {
      head + "." + tail
    }
  }
}

///|
fn scientific_from_digits(digits : String, exp10 : Int) -> String {
  let mantissa = mantissa_from_digits(digits)
  if exp10 >= 0 {
    "\{mantissa}e+\{exp10}"
  } else {
    "\{mantissa}e-\{-exp10}"
  }
}

///|
fn scientific_from_digits_for_g(digits : String, exp10 : Int) -> String {
  let mantissa = if digits.length() == 1 {
    digits
  } else {
    let head = slice_owned(digits, 0, 1)
    let raw_tail = slice_owned(digits, 1, digits.length())
    let tail = trim_trailing_zeros_decimal_digits(raw_tail)
    if tail == "0" {
      head
    } else {
      head + "." + tail
    }
  }
  if exp10 >= 0 {
    "\{mantissa}e+\{exp10}"
  } else {
    "\{mantissa}e-\{-exp10}"
  }
}

///|
fn fixed_from_digits(digits : String, exp10 : Int) -> String {
  if exp10 >= 0 {
    let int_len = exp10 + 1
    if int_len >= digits.length() {
      let int_part = digits + "0".repeat(int_len - digits.length())
      "\{int_part}.0"
    } else {
      let int_part = slice_owned(digits, 0, int_len)
      let raw_frac = slice_owned(digits, int_len, digits.length())
      let frac_part = trim_trailing_zeros_decimal_digits(raw_frac)
      "\{int_part}.\{frac_part}"
    }
  } else {
    let zeros = "0".repeat(-exp10 - 1)
    let raw_frac = zeros + digits
    let frac_part = trim_trailing_zeros_decimal_digits(raw_frac)
    "0.\{frac_part}"
  }
}

///|
fn fixed_from_digits_with_frac(
  digits : String,
  exp10 : Int,
  frac_digits : Int,
  force_point? : Bool = false,
) -> String raise MpfError {
  if frac_digits < 0 {
    raise FormatError("RawMpf::format_spec: invalid fraction digits")
  }
  let (int_part, raw_frac) = if exp10 >= 0 {
    let int_len = exp10 + 1
    if int_len >= digits.length() {
      (digits + "0".repeat(int_len - digits.length()), "")
    } else {
      (
        slice_owned(digits, 0, int_len),
        slice_owned(digits, int_len, digits.length()),
      )
    }
  } else {
    ("0", "0".repeat(-exp10 - 1) + digits)
  }
  if frac_digits == 0 {
    if force_point {
      int_part + "."
    } else {
      int_part
    }
  } else {
    let frac = if raw_frac.length() >= frac_digits {
      slice_owned(raw_frac, 0, frac_digits)
    } else {
      raw_frac.pad_end(frac_digits, '0')
    }
    "\{int_part}.\{frac}"
  }
}

///|
fn scientific_from_digits_with_precision(
  digits : String,
  exp10 : Int,
  precision : Int,
  alternate : Bool,
) -> String {
  let sig = precision + 1
  let padded = if digits.length() < sig {
    digits + "0".repeat(sig - digits.length())
  } else {
    digits
  }
  let head = slice_owned(padded, 0, 1)
  let tail = if precision == 0 { "" } else { slice_owned(padded, 1, sig) }
  let mantissa = if precision == 0 {
    if alternate {
      head + "."
    } else {
      head
    }
  } else {
    head + "." + tail
  }
  if exp10 >= 0 {
    "\{mantissa}e+\{exp10}"
  } else {
    "\{mantissa}e-\{-exp10}"
  }
}

///|
fn fixed_with_precision_abs(
  x : RawMpf,
  precision : Int,
  alternate : Bool,
  rnd : RoundMode,
) -> String raise MpfError {
  if precision < 0 {
    raise FormatError("RawMpf::format_spec: precision must be non-negative")
  }
  if x.is_zero() {
    if precision == 0 {
      if alternate {
        "0."
      } else {
        "0"
      }
    } else {
      "0." + "0".repeat(precision)
    }
  } else {
    let (digits, exp10) = exact_digits_exp(x)
    let d = BigInt::from_string(digits)
    let shift = exp10 - digits.length() + 1 + precision
    let scaled = if shift >= 0 {
      d * pow10(shift)
    } else {
      let den = pow10(-shift)
      round_div_nonnegative(d, den, rnd)
    }
    if precision == 0 {
      let digits0 = scaled.to_string()
      if alternate {
        digits0 + "."
      } else {
        digits0
      }
    } else {
      let scale = pow10(precision)
      let int_part = (scaled / scale).to_string()
      let frac_part = (scaled % scale).to_string().pad_start(precision, '0')
      "\{int_part}.\{frac_part}"
    }
  }
}

///|
fn scientific_with_precision_abs(
  x : RawMpf,
  precision : Int,
  alternate : Bool,
  rnd : RoundMode,
) -> String raise MpfError {
  if precision < 0 {
    raise FormatError("RawMpf::format_spec: precision must be non-negative")
  }
  if x.is_zero() {
    let frac = if precision == 0 {
      if alternate {
        "."
      } else {
        ""
      }
    } else {
      "." + "0".repeat(precision)
    }
    return "0\{frac}e+0"
  }
  let (exact_digits, exact_exp10) = exact_digits_exp(x)
  let (digits, exp10) = round_significant_with_mode(
    exact_digits,
    exact_exp10,
    precision + 1,
    rnd,
  )
  scientific_from_digits_with_precision(digits, exp10, precision, alternate)
}

///|
fn general_with_precision_abs(
  x : RawMpf,
  precision : Int,
  alternate : Bool,
  rnd : RoundMode,
) -> String raise MpfError {
  let precision = if precision <= 0 { 1 } else { precision }
  if x.is_zero() {
    if !alternate {
      return "0"
    }
    if precision == 1 {
      return "0."
    }
    return "0." + "0".repeat(precision - 1)
  }
  let (exact_digits, exact_exp10) = exact_digits_exp(x)
  let (digits, exp10) = round_significant_with_mode(
    exact_digits, exact_exp10, precision, rnd,
  )
  if should_use_scientific(exp10, -4, precision) {
    if alternate {
      scientific_from_digits_with_precision(digits, exp10, precision - 1, true)
    } else {
      scientific_from_digits_for_g(digits, exp10)
    }
  } else if alternate {
    let frac_digits = (precision - (exp10 + 1)).max(0)
    fixed_from_digits_with_frac(digits, exp10, frac_digits, force_point=true)
  } else {
    fixed_from_digits(digits, exp10)
  }
}

///|
fn to_hex_fixed_abs(x : RawMpf) -> String {
  to_pow2_fixed_abs(x, 16, 4, "0x")
}

///|
fn to_pow2_fixed_abs(
  x : RawMpf,
  base : Int,
  bits_per_digit : Int,
  prefix : String,
) -> String {
  if x.is_zero() {
    return "\{prefix}0.0"
  }
  if x.exp >= 0 {
    let i = (x.man << x.exp).to_string(radix=base)
    return "\{prefix}\{i}.0"
  }
  let shift = -x.exp
  let int_big = x.man >> shift
  let rem = x.man - (int_big << shift)
  let int_part = int_big.to_string(radix=base)
  if rem == 0N {
    "\{prefix}\{int_part}.0"
  } else {
    let n = (shift + bits_per_digit - 1) / bits_per_digit
    let frac_scaled = rem << (n * bits_per_digit - shift)
    let raw_frac = frac_scaled.to_string(radix=base).pad_start(n, '0')
    let frac = trim_trailing_zeros_decimal_digits(raw_frac)
    "\{prefix}\{int_part}.\{frac}"
  }
}

///|
fn to_hex_binary_abs(x : RawMpf, dps : Int) -> String {
  if x.is_zero() {
    return "0x0.0p+0"
  }
  let exp2 = x.exp + x.bc - 1
  let lead = 1N << (x.bc - 1)
  let tail = x.man - lead
  let frac_exact = if tail == 0N {
    "0"
  } else {
    let n = (x.bc - 1 + 3) / 4
    let shift = 4 * n - (x.bc - 1)
    let t = (tail << shift).to_string(radix=16).pad_start(n, '0')
    trim_trailing_zeros_decimal_digits(t)
  }
  let frac = if dps > 0 {
    if frac_exact.length() >= dps {
      slice_owned(frac_exact, 0, dps)
    } else {
      frac_exact.pad_end(dps, '0')
    }
  } else {
    frac_exact
  }
  if exp2 >= 0 {
    "0x1.\{frac}p+\{exp2}"
  } else {
    "0x1.\{frac}p-\{-exp2}"
  }
}

///|
pub fn RawMpf::format(
  x : RawMpf,
  dps? : Int = 15,
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String raise MpfError {
  if x.is_nan() {
    return "nan"
  }
  if x.is_infinite() {
    return if x.sign == 1 { "-inf" } else { "inf" }
  }
  if !x.is_finite() {
    raise UnsupportedError("RawMpf::format: unsupported raw value")
  }
  let sign_prefix = if x.sign == 1 { "-" } else { "" }
  let absx = if x.sign == 1 {
    { sign: 0, man: x.man, exp: x.exp, bc: x.bc }
  } else {
    x
  }
  if base == 10 {
    if absx.is_zero() {
      return "0.0"
    }
    if dps <= 0 {
      raise ValueError("RawMpf::format: dps must be positive")
    }
    let (exact_digits, exact_exp10) = exact_digits_exp(absx)
    let (digits, exp10) = round_significant(exact_digits, exact_exp10, dps)
    let body = if should_use_scientific(exp10, -4, dps) {
      scientific_from_digits(digits, exp10)
    } else {
      fixed_from_digits(digits, exp10)
    }
    sign_prefix + body
  } else if base == 16 {
    let body = if binary_exp {
      to_hex_binary_abs(absx, dps)
    } else {
      to_hex_fixed_abs(absx)
    }
    sign_prefix + body
  } else if base == 2 {
    if binary_exp {
      raise ValueError(
        "RawMpf::format: binary_exp is only supported with base=16",
      )
    }
    sign_prefix + to_pow2_fixed_abs(absx, 2, 1, "0b")
  } else if base == 8 {
    if binary_exp {
      raise ValueError(
        "RawMpf::format: binary_exp is only supported with base=16",
      )
    }
    sign_prefix + to_pow2_fixed_abs(absx, 8, 3, "0o")
  } else {
    raise ValueError("RawMpf::format: supported bases are 2, 8, 10 and 16")
  }
}

///|
fn positive_sign_prefix(sign : Char) -> String {
  if sign == '+' {
    "+"
  } else if sign == ' ' {
    " "
  } else {
    ""
  }
}

///|
fn maybe_uppercase_type(s : String, ty : Char) -> String {
  if ty == 'E' || ty == 'F' || ty == 'G' || ty == 'A' || ty == 'B' {
    s.to_upper()
  } else {
    s
  }
}

///|
fn lower_type(ty : Char) -> Char {
  if ty == 'E' {
    'e'
  } else if ty == 'F' {
    'f'
  } else if ty == 'G' {
    'g'
  } else if ty == 'A' {
    'a'
  } else if ty == 'B' {
    'b'
  } else {
    ty
  }
}

///|
fn pow2_fraction_exact_digits(
  x : RawMpf,
  base : Int,
  bits_per_digit : Int,
) -> String {
  let lead = 1N << (x.bc - 1)
  let tail = x.man - lead
  if tail == 0N {
    ""
  } else {
    let n = (x.bc - 1 + bits_per_digit - 1) / bits_per_digit
    let shift = bits_per_digit * n - (x.bc - 1)
    let t = (tail << shift).to_string(radix=base).pad_start(n, '0')
    trim_trailing_zeros_decimal_digits(t)
  }
}

///|
fn pad_or_truncate(s : String, size : Int) -> String {
  if size <= 0 {
    ""
  } else if s.length() >= size {
    slice_owned(s, 0, size)
  } else {
    s.pad_end(size, '0')
  }
}

///|
fn format_pow2_scientific_abs(
  x : RawMpf,
  base : Int,
  bits_per_digit : Int,
  prefix : String,
  precision : Int?,
  alternate : Bool,
  force_prefix : Bool,
) -> String raise MpfError {
  if x.is_zero() {
    let head = if force_prefix { prefix + "0" } else { "0" }
    let frac = match precision {
      Some(p) =>
        if p < 0 {
          raise FormatError(
            "RawMpf::format_spec: precision must be non-negative",
          )
        } else if p == 0 {
          if alternate {
            "."
          } else {
            ""
          }
        } else {
          "." + "0".repeat(p)
        }
      None => ""
    }
    return head + frac + "p+0"
  }
  let exp2 = x.exp + x.bc - 1
  let exact_frac = pow2_fraction_exact_digits(x, base, bits_per_digit)
  let frac = match precision {
    Some(p) =>
      if p < 0 {
        raise FormatError("RawMpf::format_spec: precision must be non-negative")
      } else {
        pad_or_truncate(exact_frac, p)
      }
    None => exact_frac
  }
  let head = if force_prefix { prefix + "1" } else { "1" }
  let use_point = match precision {
    Some(p) => p > 0 || alternate
    None => !frac.is_empty()
  }
  let mantissa = if use_point { head + "." + frac } else { head }
  if exp2 >= 0 {
    "\{mantissa}p+\{exp2}"
  } else {
    "\{mantissa}p-\{-exp2}"
  }
}

///|
fn add_grouping_left(s : String, sep : Char) -> String {
  if s.length() <= 3 {
    return s
  }
  let b = StringBuilder(size_hint=s.length() + s.length() / 3)
  let len = s.length()
  for i, c in s.iter2() {
    if i > 0 && (len - i) % 3 == 0 {
      b.write_char(sep)
    }
    b.write_char(c)
  }
  b.to_string()
}

///|
fn add_grouping_right(s : String, sep : Char) -> String {
  if s.length() <= 3 {
    return s
  }
  let b = StringBuilder(size_hint=s.length() + s.length() / 3)
  for i, c in s.iter2() {
    if i > 0 && i % 3 == 0 {
      b.write_char(sep)
    }
    b.write_char(c)
  }
  b.to_string()
}

///|
fn apply_digit_grouping(
  s : String,
  int_group_sep : Char?,
  frac_group_sep : Char?,
) -> String {
  let mut exp_index = -1
  for i, c in s.iter2() {
    if c == 'e' || c == 'E' {
      exp_index = i
      break
    }
  }
  let mantissa = if exp_index >= 0 { slice_owned(s, 0, exp_index) } else { s }
  let exp_suffix = if exp_index >= 0 {
    slice_owned(s, exp_index, s.length())
  } else {
    ""
  }
  let mut dot_index = -1
  for i, c in mantissa.iter2() {
    if c == '.' {
      dot_index = i
      break
    }
  }
  let (int_part, has_dot, frac_part) = if dot_index >= 0 {
    (
      slice_owned(mantissa, 0, dot_index),
      true,
      slice_owned(mantissa, dot_index + 1, mantissa.length()),
    )
  } else {
    (mantissa, false, "")
  }
  let grouped_int = match int_group_sep {
    Some(sep) => add_grouping_left(int_part, sep)
    None => int_part
  }
  let grouped_frac = match frac_group_sep {
    Some(sep) => add_grouping_right(frac_part, sep)
    None => frac_part
  }
  let grouped_mantissa = if has_dot {
    grouped_int + "." + grouped_frac
  } else {
    grouped_int
  }
  grouped_mantissa + exp_suffix
}

///|
fn decimal_body_is_zero(s : String) -> Bool {
  for c in s {
    if c != '0' && c != '.' {
      return false
    }
  }
  true
}

///|
pub fn RawMpf::to_string(x : RawMpf) -> String raise MpfError {
  x.format()
}

///|
fn format_char_at(format_spec : StringView, i : Int) -> Char raise MpfError {
  match format_spec.get_char(i) {
    Some(c) => c
    None => raise FormatError("RawMpf::format_spec: invalid character boundary")
  }
}

///|
fn parse_format_spec(
  format_spec : StringView,
) -> ParsedFormatSpec raise MpfError {
  let len = format_spec.length()
  let mut i = 0
  let mut fill = ' '
  let mut align = '>'
  let mut sign = '-'
  let mut no_neg_0 = false
  let mut align_explicit = false
  let mut alternate = false
  let mut int_group_sep : Char? = None
  let mut frac_group_sep : Char? = None
  let mut rounding : RoundMode? = None
  if len >= 2 {
    let c0 = format_char_at(format_spec, 0)
    let c1 = format_char_at(format_spec, 1)
    if c1 == '<' || c1 == '>' || c1 == '^' || c1 == '=' {
      fill = c0
      align = c1
      i = 2
      align_explicit = true
    }
  }
  if i == 0 && len >= 1 {
    let c0 = format_char_at(format_spec, 0)
    if c0 == '<' || c0 == '>' || c0 == '^' || c0 == '=' {
      align = c0
      i = 1
      align_explicit = true
    }
  }
  if i < len {
    let c = format_char_at(format_spec, i)
    if c == '+' || c == '-' || c == ' ' {
      sign = c
      i += 1
    }
  }
  if i < len && format_spec.get_char(i) == Some('z') {
    no_neg_0 = true
    i += 1
  }
  if i < len && format_spec.get_char(i) == Some('#') {
    alternate = true
    i += 1
  }
  if i < len && format_spec.get_char(i) == Some('0') {
    if !align_explicit {
      fill = '0'
      align = '='
    }
    i += 1
  }
  let mut width = 0
  while i < len {
    let c = format_char_at(format_spec, i)
    if c.is_ascii_digit() {
      width = width * 10 + (c.to_int() - '0'.to_int())
      i += 1
    } else {
      break
    }
  }
  if i < len {
    let c = format_char_at(format_spec, i)
    if c == ',' || c == '_' {
      int_group_sep = Some(c)
      i += 1
    }
  }
  let mut precision : Int? = None
  if i < len && format_spec.get_char(i) == Some('.') {
    i += 1
    let mut p = 0
    let mut has_digit = false
    while i < len {
      let c = format_char_at(format_spec, i)
      if c.is_ascii_digit() {
        has_digit = true
        p = p * 10 + (c.to_int() - '0'.to_int())
        i += 1
      } else {
        break
      }
    }
    if !has_digit {
      raise FormatError("RawMpf::format_spec: invalid precision")
    }
    precision = Some(p)
    if i < len {
      let c = format_char_at(format_spec, i)
      if c == ',' || c == '_' {
        frac_group_sep = Some(c)
        i += 1
      }
    }
  }
  if i < len {
    let c = format_char_at(format_spec, i)
    if c == 'U' {
      rounding = Some(Ceiling)
      i += 1
    } else if c == 'D' {
      rounding = Some(Floor)
      i += 1
    } else if c == 'Y' {
      rounding = Some(Up)
      i += 1
    } else if c == 'Z' {
      rounding = Some(Down)
      i += 1
    } else if c == 'N' {
      rounding = Some(Nearest)
      i += 1
    }
  }
  let mut ty = 'g'
  if i < len {
    ty = format_char_at(format_spec, i)
    i += 1
  }
  if i != len {
    raise FormatError("RawMpf::format_spec: unsupported format spec")
  }
  {
    fill,
    align,
    sign,
    no_neg_0,
    alternate,
    int_group_sep,
    frac_group_sep,
    rounding,
    width,
    precision,
    ty,
  }
}

///|
fn apply_alignment(
  s : String,
  width : Int,
  align : Char,
  fill : Char,
) -> String {
  if width <= s.length() {
    return s
  }
  let pad = width - s.length()
  if align == '<' {
    s + String::make(pad, fill)
  } else if align == '=' {
    let c0 = s.get_char(0)
    if c0 == Some('-') || c0 == Some('+') || c0 == Some(' ') {
      let head = slice_owned(s, 0, 1)
      let tail = slice_owned(s, 1, s.length())
      head + String::make(pad, fill) + tail
    } else {
      String::make(pad, fill) + s
    }
  } else if align == '^' {
    let left = pad / 2
    let right = pad - left
    String::make(left, fill) + s + String::make(right, fill)
  } else {
    String::make(pad, fill) + s
  }
}

///|
pub fn RawMpf::format_spec(
  x : RawMpf,
  format_spec : StringView,
  dps? : Int = 15,
) -> String raise MpfError {
  let spec = parse_format_spec(format_spec)
  let lower_ty = lower_type(spec.ty)
  let fmt_rnd = spec.rounding.unwrap_or(Nearest)
  let body = if x.is_nan() {
    let suffix = if lower_ty == '%' { "%" } else { "" }
    maybe_uppercase_type(
      positive_sign_prefix(spec.sign) + "nan" + suffix,
      spec.ty,
    )
  } else if x.is_infinite() {
    if x.sign == 1 {
      let suffix = if lower_ty == '%' { "%" } else { "" }
      maybe_uppercase_type("-inf" + suffix, spec.ty)
    } else {
      let suffix = if lower_ty == '%' { "%" } else { "" }
      maybe_uppercase_type(
        positive_sign_prefix(spec.sign) + "inf" + suffix,
        spec.ty,
      )
    }
  } else {
    let sign_prefix = if x.sign == 1 {
      "-"
    } else {
      positive_sign_prefix(spec.sign)
    }
    let absx = if x.sign == 1 {
      { sign: 0, man: x.man, exp: x.exp, bc: x.bc }
    } else {
      x
    }
    let abs_rnd = rounding_for_abs(fmt_rnd, x.sign)
    let (raw_core, suffix) = match lower_ty {
      'f' =>
        (
          fixed_with_precision_abs(
            absx,
            spec.precision.unwrap_or(6),
            spec.alternate,
            abs_rnd,
          ),
          "",
        )
      'e' =>
        (
          scientific_with_precision_abs(
            absx,
            spec.precision.unwrap_or(6),
            spec.alternate,
            abs_rnd,
          ),
          "",
        )
      'g' =>
        (
          general_with_precision_abs(
            absx,
            spec.precision.unwrap_or(dps),
            spec.alternate,
            abs_rnd,
          ),
          "",
        )
      '%' => {
        let scaled = absx.mul(RawMpf::from_int(100), 0, Down)
        (
          fixed_with_precision_abs(
            scaled,
            spec.precision.unwrap_or(6),
            spec.alternate,
            abs_rnd,
          ),
          "%",
        )
      }
      'a' =>
        (
          format_pow2_scientific_abs(
            absx,
            16,
            4,
            "0x",
            spec.precision,
            spec.alternate,
            true,
          ),
          "",
        )
      'b' =>
        (
          format_pow2_scientific_abs(
            absx,
            2,
            1,
            "0b",
            spec.precision,
            spec.alternate,
            spec.alternate,
          ),
          "",
        )
      _ =>
        raise FormatError(
          "RawMpf::format_spec: supported types are f, e, g, %, a and b",
        )
    }
    let sign_prefix = if x.sign == 1 &&
      spec.no_neg_0 &&
      (lower_ty == 'f' || lower_ty == '%') &&
      decimal_body_is_zero(raw_core) {
      positive_sign_prefix(spec.sign)
    } else {
      sign_prefix
    }
    let core = if lower_ty == 'f' ||
      lower_ty == 'e' ||
      lower_ty == 'g' ||
      lower_ty == '%' {
      apply_digit_grouping(raw_core, spec.int_group_sep, spec.frac_group_sep)
    } else {
      raw_core
    }
    maybe_uppercase_type(sign_prefix + core + suffix, spec.ty)
  }
  apply_alignment(body, spec.width, spec.align, spec.fill)
}
