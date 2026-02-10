///|
fn dps_to_prec_approx(dps : Int) -> Int {
  if dps <= 0 {
    64
  } else {
    dps * 4 + 20
  }
}

///|
fn auto_parse_prec(s : String) -> Int {
  let mut digits = 0
  for c in s {
    if c >= '0' && c <= '9' {
      digits += 1
    }
  }
  let mut p = dps_to_prec_approx(digits + 16)
  if p < 256 {
    p = 256
  }
  if p > 4096 {
    p = 4096
  }
  p
}

///|
fn prec_to_dps_approx(prec : Int) -> Int {
  if prec <= 0 {
    15
  } else {
    prec * 30103 / 100000 + 1
  }
}

///|
fn strip_spaces(s : String) -> String {
  let mut out = ""
  for c in s {
    if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
      out = out + c.to_string()
    }
  }
  out
}

///|
fn split_exact_two(s : String, sep : String) -> (String, String)? {
  let parts : Array[String] = []
  for part in s.split(sep) {
    parts.push(part.to_string())
  }
  if parts.length() == 2 {
    Some((parts[0], parts[1]))
  } else {
    None
  }
}

///|
fn substring(s : String, start : Int, end : Int) -> String {
  if start >= end {
    ""
  } else {
    s.unsafe_substring(start~, end~)
  }
}

///|
fn split_exp_string(s : String) -> (String, String) {
  match split_exact_two(s, "e") {
    Some((m, e)) => (m, e)
    None => (s, "")
  }
}

///|
fn first_diff_index(a : String, b : String) -> Int {
  let min_len = if a.length() < b.length() { a.length() } else { b.length() }
  let mut i = 0
  while i < min_len {
    if a.get_char(i) != b.get_char(i) {
      break
    }
    i += 1
  }
  i
}

///|
fn mpi_from_str_a_b(
  x : String,
  y : String,
  percent : Bool,
  prec : Int,
) -> RawMpi {
  let base_prec = if prec > 0 { prec } else { auto_parse_prec(x + y) }
  let wp = base_prec + 20
  let out_prec = if prec > 0 { prec } else { 0 }
  let xa = @mpf.from_str(x, prec=wp, rnd=@mpf.round_floor)
  let xb = @mpf.from_str(x, prec=wp, rnd=@mpf.round_ceiling)
  let mut width = @mpf.from_str(y, prec=wp, rnd=@mpf.round_ceiling)
  if @mpf.mpf_sign(width) < 0 {
    abort("mpi_from_str: interval width must be nonnegative")
  }
  if percent {
    let xa_abs = @mpf.mpf_abs(xa, wp, @mpf.round_ceiling)
    let xb_abs = @mpf.mpf_abs(xb, wp, @mpf.round_ceiling)
    let (_, mx) = @mpf.mpf_min_max([xa_abs, xb_abs])
    width = @mpf.mpf_mul(mx, width, wp, @mpf.round_ceiling)
    width = @mpf.mpf_div(width, @mpf.from_int(100), wp, @mpf.round_ceiling)
  }
  let lo = @mpf.mpf_sub(xa, width, out_prec, @mpf.round_floor)
  let hi = @mpf.mpf_add(xb, width, out_prec, @mpf.round_ceiling)
  mpi_make(lo, hi)
}

///|
pub fn mpi_from_str(s : String, prec? : Int = 0) -> RawMpi {
  let text = strip_spaces(s)
  let wp = if prec > 0 { prec } else { auto_parse_prec(text) }
  match split_exact_two(text, "+-") {
    Some((x, y)) => return mpi_from_str_a_b(x, y, false, wp)
    None => ()
  }
  if text.contains("(") {
    if text.has_prefix("(") || !text.contains(")") {
      abort("mpi_from_str: malformed interval string")
    }
    match split_exact_two(text, "(") {
      Some((x, tail)) => {
        if !tail.has_suffix(")") {
          abort("mpi_from_str: malformed interval string")
        }
        let mut y = substring(tail, 0, tail.length() - 1)
        let percent = y.has_suffix("%")
        if percent {
          y = substring(y, 0, y.length() - 1)
        }
        return mpi_from_str_a_b(x, y, percent, wp)
      }
      None => abort("mpi_from_str: malformed interval string")
    }
  }
  if text.contains(",") {
    if !text.contains("[") || !text.contains("]") {
      abort("mpi_from_str: malformed interval string")
    }
    if text.has_prefix("[") {
      if !text.has_suffix("]") {
        abort("mpi_from_str: malformed interval string")
      }
      let inner = substring(text, 1, text.length() - 1)
      match split_exact_two(inner, ",") {
        Some((a, b)) =>
          return mpi_make(
            @mpf.from_str(a, prec=wp, rnd=@mpf.round_floor),
            @mpf.from_str(b, prec=wp, rnd=@mpf.round_ceiling),
          )
        None => abort("mpi_from_str: malformed interval string")
      }
    }
    match split_exact_two(text, "[") {
      Some((prefix, rhs1)) =>
        match split_exact_two(rhs1, ",") {
          Some((y, rhs2)) =>
            match split_exact_two(rhs2, "]") {
              Some((z, suffix)) => {
                let lo = @mpf.from_str(
                  prefix + y + suffix,
                  prec=wp,
                  rnd=@mpf.round_floor,
                )
                let hi = @mpf.from_str(
                  prefix + z + suffix,
                  prec=wp,
                  rnd=@mpf.round_ceiling,
                )
                return mpi_make(lo, hi)
              }
              None => abort("mpi_from_str: malformed interval string")
            }
          None => abort("mpi_from_str: malformed interval string")
        }
      None => abort("mpi_from_str: malformed interval string")
    }
  }
  let lo = @mpf.from_str(text, prec=wp, rnd=@mpf.round_floor)
  let hi = @mpf.from_str(text, prec=wp, rnd=@mpf.round_ceiling)
  mpi_make(lo, hi)
}

///|
pub fn mpi_to_str_opts(
  s : RawMpi,
  dps? : Int = 15,
  mode? : String = "brackets",
  use_spaces? : Bool = true,
  error_dps? : Int = 4,
  left_bracket? : String = "[",
  right_bracket? : String = "]",
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String {
  let sp = if use_spaces { " " } else { "" }
  let a_str = @mpf.to_str_opts(s.lo, dps~, base~, binary_exp~)
  let b_str = @mpf.to_str_opts(s.hi, dps~, base~, binary_exp~)
  match mode {
    "plusminus" => {
      let p = dps_to_prec_approx(dps)
      let mid = mpi_mid(s, p)
      let delta_half = @mpf.mpf_shift(mpi_delta(s, p), -1)
      @mpf.to_str_opts(mid, dps~, base~, binary_exp~) +
      sp +
      "+-" +
      sp +
      @mpf.to_str_opts(delta_half, dps~, base~, binary_exp~)
    }
    "percent" => {
      let p = dps_to_prec_approx(dps)
      let mid = mpi_mid(s, p)
      let delta = mpi_delta(s, p)
      let percent = if @mpf.is_zero(mid) {
        @mpf.fzero
      } else {
        let num = @mpf.mpf_mul_int(delta, 100, p + 12, @mpf.round_nearest)
        let den = @mpf.mpf_mul_int(mid, 2, p + 12, @mpf.round_nearest)
        @mpf.mpf_div(num, den, p + 12, @mpf.round_nearest)
      }
      @mpf.to_str_opts(mid, dps~, base~, binary_exp~) +
      sp +
      "(" +
      @mpf.to_str_opts(percent, dps=error_dps, base~, binary_exp~) +
      "%)"
    }
    "brackets" => left_bracket + a_str + "," + sp + b_str + right_bracket
    "diff" => {
      let mut left = a_str
      let mut right = b_str
      if left == right {
        left = @mpf.to_str_opts(s.lo, dps=dps + 3, base~, binary_exp~)
        right = @mpf.to_str_opts(s.hi, dps=dps + 3, base~, binary_exp~)
      }
      let (lm, le) = split_exp_string(left)
      let (rm, re) = split_exp_string(right)
      if le == re {
        if lm != rm {
          let i = first_diff_index(lm, rm)
          let prefix = substring(lm, 0, i)
          let ltail = substring(lm, i, lm.length())
          let rtail = substring(rm, i, rm.length())
          let exp_suffix = if le is "" { "" } else { "e" + le }
          prefix +
          left_bracket +
          ltail +
          "," +
          sp +
          rtail +
          right_bracket +
          exp_suffix
        } else {
          let exp_suffix = if le is "" { "" } else { "e" + le }
          lm + left_bracket + right_bracket + exp_suffix
        }
      } else {
        left_bracket + left + "," + sp + right + right_bracket
      }
    }
    _ => abort("mpi_to_str_opts: unknown mode")
  }
}

///|
pub fn mpi_to_str(s : RawMpi, dps? : Int = 15) -> String {
  mpi_to_str_opts(s, dps~)
}

///|
pub fn mpi_str(s : RawMpi, prec : Int) -> String {
  let dps = prec_to_dps_approx(prec) + 5
  mpi_to_str_opts(s, dps~)
}
