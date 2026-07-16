# mbmath

`mbmath` is an arbitrary-precision numerical computing library for MoonBit. It provides real, complex, and interval arithmetic together with special functions, calculus, root finding, quadrature, matrix algorithms, and ordinary differential equation solvers.

The design follows the layered architecture and numerical semantics of Python's [`mpmath`](https://mpmath.org/), while exposing MoonBit-native values, explicit precision and rounding, and typed errors.

## Features

- Arbitrary-precision real arithmetic with configurable binary precision and rounding modes
- Complex arithmetic, elementary functions, powers, roots, and branch-aware special functions
- Real and complex interval arithmetic with outward rounding
- Decimal parsing, formatting, base conversion, infinities, signed zero, and NaN support
- Elementary functions including logarithms, exponentials, trigonometric, and hyperbolic functions
- Gamma, log-gamma, reciprocal gamma, factorial, Bernoulli, psi, harmonic, and zeta functions
- Exponential and trigonometric integrals, AGM, and complete elliptic integrals
- Numerical differentiation, Taylor expansion, limits, summation, products, convergence acceleration, root finding, and quadrature
- Polynomial, Fourier, inverse Laplace, matrix-function, linear algebra, eigensystem, SVD, and ODE utilities

## Packages

| Package | Purpose |
| --- | --- |
| `libmp/mpf` | Core arbitrary-precision real representation, arithmetic, conversion, and formatting |
| `libmp/mpc` | Arbitrary-precision complex arithmetic and special functions |
| `libmp/libmpi` | Real and complex interval arithmetic, interval functions, and interval matrices |
| `libmp/libelefun` | Elementary transcendental functions and constants |
| `libmp/gammazeta` | Gamma, factorial, Bernoulli, psi, harmonic, and zeta families |
| `libmp/libhyper` | Exponential integrals, trigonometric integrals, AGM, and elliptic integrals |
| `libmp/intmath` | Integer helpers used by the numerical kernels |
| `ctx/mp` | High-level precision context, calculus, numerical methods, matrices, and ODE solvers |

## Installation

Add the module to a MoonBit project:

```bash
moon add CAIMEOX/moon_floating
```

Import the high-level context and real-number kernel in `moon.pkg`:

```moonbit
import {
  "CAIMEOX/moon_floating/ctx/mp",
  "CAIMEOX/moon_floating/libmp/mpf",
}
```

## Quick Start

```moonbit
let ctx = @mp.MPContext::new(256, @mpf.Nearest)
let two = ctx.from_int(2)
let root = ctx.sqrt(two)
println(ctx.to_string(root, dps=50))
```

The precision passed to `MPContext::new` is measured in bits. Low-level values use methods such as `x.add(y, precision, rounding)`, while constructors and parsers are associated with their owning types, for example `RawMpf::from_int` and `RawMpf::parse`. This keeps numerical behavior reproducible and allows directed rounding for interval calculations.

Operations with invalid domains, poles, malformed input, or failed convergence raise package-specific suberrors. Callers can let these errors propagate or handle them with MoonBit's `catch` syntax.

## mpmath Compatibility

`mbmath` aims to match `mpmath` semantics and precision on the operations it implements, including special values and complex branch behavior. It is not a Python binding or a source-compatible translation: APIs use MoonBit types, explicit contexts, and structured errors.

## Development

```bash
moon check --target all
moon test --target native
moon fmt
```

## License

Apache-2.0. See [LICENSE](LICENSE).
