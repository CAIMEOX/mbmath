///|
fn dps_to_prec_approx(dps : Int) -> Int {
  if dps <= 0 {
    64
  } else {
    dps * 4 + 20
  }
}

///|
fn auto_parse_prec(s : StringView) -> Int {
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
fn strip_spaces(s : StringView) -> String {
  let out = StringBuilder(size_hint=s.length())
  for c in s {
    if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
      out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn split_exact_two(
  s : StringView,
  sep : StringView,
) -> (StringView, StringView)? {
  let parts : Array[StringView] = []
  for part in s.split(sep) {
    parts.push(part)
  }
  if parts.length() == 2 {
    Some((parts[0], parts[1]))
  } else {
    None
  }
}

///|
fn slice_view(
  s : StringView,
  start : Int,
  end : Int,
) -> StringView raise MpiError {
  if start < 0 || end < start || end > s.length() {
    raise ParseError("interval parser produced an invalid string slice")
  }
  if (start < s.length() && s.get_char(start) is None) ||
    (end < s.length() && s.get_char(end) is None) {
    raise ParseError("interval parser split a Unicode character")
  }
  s.view(start_offset=start, end_offset=end)
}

///|
fn split_exp_string(s : StringView) -> (StringView, StringView) {
  match split_exact_two(s, "e") {
    Some((m, e)) => (m, e)
    None => (s, "")
  }
}

///|
fn first_diff_index(a : StringView, b : StringView) -> Int {
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
  x : StringView,
  y : StringView,
  percent : Bool,
  prec : Int,
) -> RawMpi raise MpiError {
  let base_prec = if prec > 0 {
    prec
  } else {
    let joined = StringBuilder(size_hint=x.length() + y.length())
    joined.write_view(x)
    joined.write_view(y)
    auto_parse_prec(joined.to_string())
  }
  let wp = base_prec + 20
  let out_prec = if prec > 0 { prec } else { 0 }
  let xa = @mpf.RawMpf::parse(x, prec=wp, rnd=Floor) catch {
    err => raise from_mpf_error(err)
  }
  let xb = @mpf.RawMpf::parse(x, prec=wp, rnd=Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  let mut width = @mpf.RawMpf::parse(y, prec=wp, rnd=Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  if width.signum() < 0 {
    raise ValueError("RawMpi::parse: interval width must be nonnegative")
  }
  if percent {
    let xa_abs = xa.abs(wp, Ceiling)
    let xb_abs = xb.abs(wp, Ceiling)
    let (_, mx) = @mpf.RawMpf::min_max([xa_abs, xb_abs]) catch {
      err => raise from_mpf_error(err)
    }
    width = mx.mul(width, wp, Ceiling)
    width = width.div(@mpf.RawMpf::from_int(100), wp, Ceiling) catch {
      err => raise from_mpf_error(err)
    }
  }
  let lo = xa.sub(width, out_prec, Floor)
  let hi = xb.add(width, out_prec, Ceiling)
  RawMpi::new(lo, hi)
}

///|
pub fn RawMpi::parse(s : StringView, prec? : Int = 0) -> RawMpi raise MpiError {
  let text = strip_spaces(s)
  let wp = if prec > 0 { prec } else { auto_parse_prec(text) }
  match split_exact_two(text, "+-") {
    Some((x, y)) => return mpi_from_str_a_b(x, y, false, wp)
    None => ()
  }
  if text.contains("(") {
    if text.has_prefix("(") || !text.contains(")") {
      raise ParseError("RawMpi::parse: malformed interval string")
    }
    match split_exact_two(text, "(") {
      Some((x, tail)) => {
        if !tail.has_suffix(")") {
          raise ParseError("RawMpi::parse: malformed interval string")
        }
        let mut y = slice_view(tail, 0, tail.length() - 1)
        let percent = y.has_suffix("%")
        if percent {
          y = slice_view(y, 0, y.length() - 1)
        }
        return mpi_from_str_a_b(x, y, percent, wp)
      }
      None => raise ParseError("RawMpi::parse: malformed interval string")
    }
  }
  if text.contains(",") {
    if !text.contains("[") || !text.contains("]") {
      raise ParseError("RawMpi::parse: malformed interval string")
    }
    if text.has_prefix("[") {
      if !text.has_suffix("]") {
        raise ParseError("RawMpi::parse: malformed interval string")
      }
      let inner = slice_view(text, 1, text.length() - 1)
      match split_exact_two(inner, ",") {
        Some((a, b)) => {
          let lo = @mpf.RawMpf::parse(a, prec=wp, rnd=Floor) catch {
            err => raise from_mpf_error(err)
          }
          let hi = @mpf.RawMpf::parse(b, prec=wp, rnd=Ceiling) catch {
            err => raise from_mpf_error(err)
          }
          return RawMpi::new(lo, hi)
        }
        None => raise ParseError("RawMpi::parse: malformed interval string")
      }
    }
    match split_exact_two(text, "[") {
      Some((prefix, rhs1)) =>
        match split_exact_two(rhs1, ",") {
          Some((y, rhs2)) =>
            match split_exact_two(rhs2, "]") {
              Some((z, suffix)) => {
                let lo_text = StringBuilder(
                  size_hint=prefix.length() + y.length() + suffix.length(),
                )
                lo_text.write_view(prefix)
                lo_text.write_view(y)
                lo_text.write_view(suffix)
                let hi_text = StringBuilder(
                  size_hint=prefix.length() + z.length() + suffix.length(),
                )
                hi_text.write_view(prefix)
                hi_text.write_view(z)
                hi_text.write_view(suffix)
                let lo = @mpf.RawMpf::parse(
                  lo_text.to_string(),
                  prec=wp,
                  rnd=Floor,
                ) catch {
                  err => raise from_mpf_error(err)
                }
                let hi = @mpf.RawMpf::parse(
                  hi_text.to_string(),
                  prec=wp,
                  rnd=Ceiling,
                ) catch {
                  err => raise from_mpf_error(err)
                }
                return RawMpi::new(lo, hi)
              }
              None =>
                raise ParseError("RawMpi::parse: malformed interval string")
            }
          None => raise ParseError("RawMpi::parse: malformed interval string")
        }
      None => raise ParseError("RawMpi::parse: malformed interval string")
    }
  }
  let lo = @mpf.RawMpf::parse(text, prec=wp, rnd=Floor) catch {
    err => raise from_mpf_error(err)
  }
  let hi = @mpf.RawMpf::parse(text, prec=wp, rnd=Ceiling) catch {
    err => raise from_mpf_error(err)
  }
  RawMpi::new(lo, hi)
}

///|
pub fn RawMpi::format_with(
  s : RawMpi,
  dps? : Int = 15,
  mode? : StringView = "brackets",
  use_spaces? : Bool = true,
  error_dps? : Int = 4,
  left_bracket? : StringView = "[",
  right_bracket? : StringView = "]",
  base? : Int = 10,
  binary_exp? : Bool = false,
) -> String raise MpiError {
  let sp = if use_spaces { " " } else { "" }
  let a_str = s.lo.format(dps~, base~, binary_exp~) catch {
    err => raise from_mpf_error(err)
  }
  let b_str = s.hi.format(dps~, base~, binary_exp~) catch {
    err => raise from_mpf_error(err)
  }
  match mode {
    "plusminus" => {
      let p = dps_to_prec_approx(dps)
      let mid = s.midpoint(p)
      let delta_half = s.width(p).scale_pow2(-1)
      let mid_str = mid.format(dps~, base~, binary_exp~) catch {
        err => raise from_mpf_error(err)
      }
      let delta_str = delta_half.format(dps~, base~, binary_exp~) catch {
        err => raise from_mpf_error(err)
      }
      let out = StringBuilder(
        size_hint=mid_str.length() + delta_str.length() + sp.length() * 2 + 2,
      )
      out.write_string(mid_str)
      out.write_view(sp)
      out.write_string("+-")
      out.write_view(sp)
      out.write_string(delta_str)
      out.to_string()
    }
    "percent" => {
      let p = dps_to_prec_approx(dps)
      let mid = s.midpoint(p)
      let delta = s.width(p)
      let percent = if mid.is_zero() {
        @mpf.RawMpf::zero()
      } else {
        let num = delta.mul_int(100, p + 12, Nearest)
        let den = mid.mul_int(2, p + 12, Nearest)
        num.div(den, p + 12, Nearest) catch {
          err => raise from_mpf_error(err)
        }
      }
      let mid_str = mid.format(dps~, base~, binary_exp~) catch {
        err => raise from_mpf_error(err)
      }
      let pct_str = percent.format(dps=error_dps, base~, binary_exp~) catch {
        err => raise from_mpf_error(err)
      }
      let out = StringBuilder(
        size_hint=mid_str.length() + pct_str.length() + sp.length() + 3,
      )
      out.write_string(mid_str)
      out.write_view(sp)
      out.write_char('(')
      out.write_string(pct_str)
      out.write_string("%)")
      out.to_string()
    }
    "brackets" => {
      let out = StringBuilder(
        size_hint=left_bracket.length() +
          a_str.length() +
          sp.length() +
          b_str.length() +
          right_bracket.length() +
          1,
      )
      out.write_view(left_bracket)
      out.write_string(a_str)
      out.write_char(',')
      out.write_view(sp)
      out.write_string(b_str)
      out.write_view(right_bracket)
      out.to_string()
    }
    "diff" => {
      let mut left = a_str
      let mut right = b_str
      if left == right {
        left = s.lo.format(dps=dps + 3, base~, binary_exp~) catch {
          err => raise from_mpf_error(err)
        }
        right = s.hi.format(dps=dps + 3, base~, binary_exp~) catch {
          err => raise from_mpf_error(err)
        }
      }
      let (lm, le) = split_exp_string(left)
      let (rm, re) = split_exp_string(right)
      if le == re {
        if lm != rm {
          let i = first_diff_index(lm, rm)
          let prefix = slice_view(lm, 0, i)
          let ltail = slice_view(lm, i, lm.length())
          let rtail = slice_view(rm, i, rm.length())
          let out = StringBuilder(
            size_hint=left.length() +
              right.length() +
              left_bracket.length() +
              right_bracket.length() +
              sp.length() +
              le.length() +
              3,
          )
          out.write_view(prefix)
          out.write_view(left_bracket)
          out.write_view(ltail)
          out.write_char(',')
          out.write_view(sp)
          out.write_view(rtail)
          out.write_view(right_bracket)
          if !le.is_empty() {
            out.write_char('e')
            out.write_view(le)
          }
          out.to_string()
        } else {
          let out = StringBuilder(
            size_hint=lm.length() +
              left_bracket.length() +
              right_bracket.length() +
              le.length() +
              1,
          )
          out.write_view(lm)
          out.write_view(left_bracket)
          out.write_view(right_bracket)
          if !le.is_empty() {
            out.write_char('e')
            out.write_view(le)
          }
          out.to_string()
        }
      } else {
        let out = StringBuilder(
          size_hint=left_bracket.length() +
            left.length() +
            sp.length() +
            right.length() +
            right_bracket.length() +
            1,
        )
        out.write_view(left_bracket)
        out.write_string(left)
        out.write_char(',')
        out.write_view(sp)
        out.write_string(right)
        out.write_view(right_bracket)
        out.to_string()
      }
    }
    _ => raise UnsupportedError("RawMpi::format_with: unknown mode")
  }
}

///|
pub fn RawMpi::format(s : RawMpi, dps? : Int = 15) -> String raise MpiError {
  s.format_with(dps~)
}

///|
pub fn RawMpi::format_at_precision(
  s : RawMpi,
  prec : Int,
) -> String raise MpiError {
  let dps = prec_to_dps_approx(prec) + 5
  s.format_with(dps~)
}
