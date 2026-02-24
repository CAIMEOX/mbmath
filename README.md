# MoonBit Arbitrary-Precision Math Library

## Introduction

`mbmath` is an active MoonBit port of key `mpmath` numerical layers, centered on arbitrary-precision real (`mpf`), complex (`mpc`), interval (`mpi`/`mpci`) arithmetic, and selected special-function families.

Current baseline (2026-02-24):

- Runtime test baseline: `moon -C mbmath test` => `290 passed`, `0 failed`.
- Public API docs: all tracked `spec.mbt` files are documented per function (see `DOC_MIGRATION_BOARD.md`).
- Python test migration board: `24` files in `部分`, `13` files still `未开始`, `0` files fully marked `已迁移`.
- High-level API coverage is still a subset compared with upstream `mpmath`.

The project is usable for preview/integration on the implemented surface, but is not yet full-parity with `mpmath`.

## Rebased Roadmap

1. Core reliability hardening
- Remove remaining `try!` from non-test runtime code and propagate structured errors consistently.
- Add regression tests for all converted error paths.

2. Finish P1 semantic gaps
- Deepen `test_fp` complex branch consistency (especially zeta/gamma neighborhoods).
- Expand high-precision wrapper behaviors (`test_hp`, `test_mpmath`) and start `test_identify` subset.

3. Expand P2 numerical stack
- Broaden `diff/quad/findroot/summation` semantics and options.
- Add missing high-level extrapolation/summation APIs (`levin`, `nsum`, `nprod`, etc.).

4. Build linear algebra and ODE layers
- Add matrix/linalg/eigen/ode minimal viable stacks and migrate representative tests.

5. Integration and release preparation
- Cover CLI/compatibility/pickle/visualization/torture subsets.
- Publish explicit parity matrix and first release-quality compatibility notes.
