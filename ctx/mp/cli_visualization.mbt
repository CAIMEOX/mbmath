///|
/// Version reported by CLI integrations.
pub let mbmath_version : String = "0.3.1"

///|
/// Version string used by CLI-style integrations.
pub fn cli_version() -> String {
  mbmath_version
}

///|
/// Parse and evaluate a numeric literal in CLI compatibility mode.
///
/// This mirrors the non-interactive literal path used by mpmath's CLI tests.
pub fn MPContext::cli_eval_literal(
  self : MPContext,
  literal : StringView,
  dps? : Int = 32,
) -> String raise MPError {
  self.to_string(self.parse(literal), dps~)
}

///|
/// Evaluate a simple integer division expression (`numer/denom`) in CLI mode.
pub fn MPContext::cli_eval_division(
  self : MPContext,
  numer : Int,
  denom : Int,
  dps? : Int = 32,
) -> String raise MPError {
  let out = self.div(self.from_int(numer), self.from_int(denom))
  self.to_string(out, dps~)
}

///|
/// Minimal axis container used by `plot/cplot` APIs.
pub struct PlotAxes {
  mut xlabel : String
  mut ylabel : String
} derive(Debug, Eq)

///|
/// Create an empty plot axes object.
pub fn PlotAxes::new() -> PlotAxes {
  { xlabel: "", ylabel: "" }
}

///|
fn plot_linspace(
  start : @mpf.RawMpf,
  end_ : @mpf.RawMpf,
  samples : Int,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  if samples < 2 {
    raise ValueError("plot: samples must be >= 2")
  }
  let span = end_.sub(start, prec, Nearest)
  let step = span.div(@mpf.RawMpf::from_int(samples - 1), prec, Nearest) catch {
    err => raise from_mpf_error(err)
  }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<samples {
    out.push(start.add(step.mul_int(i, prec, Nearest), prec, Nearest))
  }
  out
}

///|
/// Sample `f` on a real interval and attach mpmath-style axes labels.
pub fn MPContext::plot(
  self : MPContext,
  f : (@mpf.RawMpf) -> @mpf.RawMpf raise?,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  axes : PlotAxes,
  samples? : Int = 65,
) -> Array[(@mpf.RawMpf, @mpf.RawMpf)] raise {
  let (a, b) = interval
  let wp = if self.precision() > 0 { self.precision() + 24 } else { 80 }
  let xs = plot_linspace(a, b, samples, wp)
  axes.xlabel = "x"
  axes.ylabel = "f(x)"
  let out : Array[(@mpf.RawMpf, @mpf.RawMpf)] = []
  for x in xs {
    let y = f(x)
    out.push(
      (
        x.rounded(self.precision(), self.round_mode()),
        y.rounded(self.precision(), self.round_mode()),
      ),
    )
  }
  out
}

///|
/// Sample `f` on a rectangular complex grid and attach mpmath-style labels.
pub fn MPContext::cplot(
  self : MPContext,
  f : (@mpc.RawMpc) -> @mpc.RawMpc raise?,
  re_interval : (@mpf.RawMpf, @mpf.RawMpf),
  im_interval : (@mpf.RawMpf, @mpf.RawMpf),
  axes : PlotAxes,
  samples? : Int = 17,
) -> Array[(@mpc.RawMpc, @mpc.RawMpc)] raise {
  let (rx0, rx1) = re_interval
  let (iy0, iy1) = im_interval
  let wp = if self.precision() > 0 { self.precision() + 24 } else { 80 }
  let rs = plot_linspace(rx0, rx1, samples, wp)
  let imags = plot_linspace(iy0, iy1, samples, wp)
  axes.xlabel = "Re(z)"
  axes.ylabel = "Im(z)"
  let out : Array[(@mpc.RawMpc, @mpc.RawMpc)] = []
  for re in rs {
    for im in imags {
      let z = @mpc.RawMpc::new(re, im)
      let w = f(z)
      out.push(
        (
          z.rounded(self.precision(), self.round_mode()),
          w.rounded(self.precision(), self.round_mode()),
        ),
      )
    }
  }
  out
}
