///|
/// Stage E integration surface: minimal CLI and visualization adapters.
pub let mbmath_version : String = "0.2.0"

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
  literal : String,
  dps? : Int = 32,
) -> String raise MPError {
  self.to_string(self.make_float(literal), dps~)
}

///|
/// Evaluate a simple integer division expression (`numer/denom`) in CLI mode.
pub fn MPContext::cli_eval_division(
  self : MPContext,
  numer : Int,
  denom : Int,
  dps? : Int = 32,
) -> String raise MPError {
  let out = self.div(self.make_int(numer), self.make_int(denom))
  self.to_string(out, dps~)
}

///|
/// Minimal axis container used by `plot/cplot` APIs.
pub struct PlotAxes {
  mut xlabel : String
  mut ylabel : String
} derive(Show, Eq)

///|
/// Create an empty plot axes object.
pub fn plot_axes() -> PlotAxes {
  { xlabel: "", ylabel: "" }
}

///|
type UnaryMpcFn = (@mpc.RawMpc) -> @mpc.RawMpc

///|
fn p4_linspace(
  start : @mpf.RawMpf,
  end_ : @mpf.RawMpf,
  samples : Int,
  prec : Int,
) -> Array[@mpf.RawMpf] raise MPError {
  if samples < 2 {
    raise MPError::ValueError("plot: samples must be >= 2")
  }
  let span = @mpf.mpf_sub(end_, start, prec, @mpf.round_nearest)
  let step = @mpf.mpf_div(
    span,
    @mpf.from_int(samples - 1),
    prec,
    @mpf.round_nearest,
  ) catch {
    err => raise from_mpf_error(err)
  }
  let out : Array[@mpf.RawMpf] = []
  for i in 0..<samples {
    out.push(
      @mpf.mpf_add(
        start,
        @mpf.mpf_mul_int(step, i, prec, @mpf.round_nearest),
        prec,
        @mpf.round_nearest,
      ),
    )
  }
  out
}

///|
/// Sample `f` on a real interval and attach mpmath-style axes labels.
pub fn MPContext::plot(
  self : MPContext,
  f : UnaryMpfFn,
  interval : (@mpf.RawMpf, @mpf.RawMpf),
  axes : PlotAxes,
  samples? : Int = 65,
) -> Array[(@mpf.RawMpf, @mpf.RawMpf)] raise MPError {
  let (a, b) = interval
  let wp = if self.precision() > 0 { self.precision() + 24 } else { 80 }
  let xs = p4_linspace(a, b, samples, wp)
  axes.xlabel = "x"
  axes.ylabel = "f(x)"
  let out : Array[(@mpf.RawMpf, @mpf.RawMpf)] = []
  for x in xs {
    let y = f(x)
    out.push(
      (
        @mpf.mpf_pos(x, self.precision(), self.round_mode()),
        @mpf.mpf_pos(y, self.precision(), self.round_mode()),
      ),
    )
  }
  out
}

///|
/// Sample `f` on a rectangular complex grid and attach mpmath-style labels.
pub fn MPContext::cplot(
  self : MPContext,
  f : UnaryMpcFn,
  re_interval : (@mpf.RawMpf, @mpf.RawMpf),
  im_interval : (@mpf.RawMpf, @mpf.RawMpf),
  axes : PlotAxes,
  samples? : Int = 17,
) -> Array[(@mpc.RawMpc, @mpc.RawMpc)] raise MPError {
  let (rx0, rx1) = re_interval
  let (iy0, iy1) = im_interval
  let wp = if self.precision() > 0 { self.precision() + 24 } else { 80 }
  let rs = p4_linspace(rx0, rx1, samples, wp)
  let imags = p4_linspace(iy0, iy1, samples, wp)
  axes.xlabel = "Re(z)"
  axes.ylabel = "Im(z)"
  let out : Array[(@mpc.RawMpc, @mpc.RawMpc)] = []
  for re in rs {
    for im in imags {
      let z = @mpc.from_parts(re, im)
      let w = f(z)
      out.push(
        (
          @mpc.mpc_pos(z, self.precision(), self.round_mode()),
          @mpc.mpc_pos(w, self.precision(), self.round_mode()),
        ),
      )
    }
  }
  out
}
