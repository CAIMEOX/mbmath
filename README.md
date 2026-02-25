# MoonBit Arbitrary-Precision Math Library

## Introduction

`mbmath` is an active MoonBit port of core `mpmath` layers, including arbitrary-precision real (`mpf`), complex (`mpc`), interval (`mpi`/`mpci`) arithmetic, and selected special-function families.

Current baseline (2026-02-25):

- Runtime test baseline: `moon -C mbmath test --target native` => `309 passed`, `0 failed`.
- Python migration board: `30` files in `部分`, `7` files still `未开始`, `0` files marked `已迁移`.
- High-level numeric APIs now include Stage C (`diff/quad/findroot/summation/levin/nsum/nprod`) and Stage D first slice (`matrix/linalg/eigen/ode` subsets).

The project is usable on the implemented surface, but still not full-parity with upstream `mpmath`.

## Roadmap

1. Deepen Stage D
- Expand matrix/linalg/eigen coverage beyond current subset (`qr/svd/hermitian` and broader random-matrix parity).
- Add higher-level ODE APIs (`odefun`-style cached evaluator and adaptive stepping).

2. Finish remaining P2 unstarted files
- `test_calculus.py`, `test_cli.py`, `test_compatibility.py`, `test_matrices.py`, `test_pickle.py`, `test_torture.py`, `test_visualization.py`.

3. Reliability hardening
- Continue removing remaining runtime `try!` and replace with structured `raise` propagation.
- Add focused regression tests for difficult precision/conditioning edge cases.

4. Release preparation
- Publish explicit parity matrix (supported/partial/unsupported functions).
- Cut preview release with compatibility notes and known limitations.

