# MoonBit Arbitrary-Precision Math Library

## Introduction

`mbmath` is an ongoing MoonBit port of core `mpmath` numeric infrastructure, with a focus on arbitrary-precision real (`mpf`) and complex (`mpc`) arithmetic plus selected special functions.

Current status:

- Project stage: preview-ready, not feature-complete parity with upstream `mpmath`.
- Core packages are in place: `libmp/mpf`, `libmp/mpc`, `libmp/libelefun`, `libmp/libhyper`, `libmp/gammazeta`, and `libmp/intmath`.
- `mpf` and `mpc` now cover broad arithmetic and conversion/formatting surfaces, including special values (`inf`, `-inf`, `nan`) for parsing/formatting.
- Test baseline is stable across all backends:
  - `moon test --target all` => 97 passed, 0 failed on `wasm`, `wasm-gc`, `js`, `native`.

The implementation is already useful for experimentation and early integration, while some edge-case semantics and full compatibility behaviors are still being expanded.

## Roadmap

1. **Close remaining semantic gaps in `libmp`**
   - Complete corner-case behavior for special values in all arithmetic paths.
   - Align error/exception behavior and formatting edge cases with `mpmath` test expectations.

2. **Increase numerical robustness and precision**
   - Continue replacing legacy bridge logic with pure `mpf` algorithms.
   - Improve stability and accuracy for hard regions of transcendental and special functions.

3. **Expand compatibility test coverage**
   - Migrate additional `mpmath` convert/str/format suites.
   - Add more differential tests against `mpmath` for `libelefun`, `libhyper`, and `gammazeta`.

4. **API hardening for public preview**
   - Freeze and document the initial stable subset.
   - Add concise package-level docs and examples for common `mpf`/`mpc` workflows.

5. **Toward first stable release**
   - Finish parity-critical gaps.
   - Publish compatibility matrix and versioned release notes.
