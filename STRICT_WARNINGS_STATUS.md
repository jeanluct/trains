# Strict Warnings Status

This document is the single source of truth for strict-warning work.

## Current Snapshot

Build profile:

- `cmake -S . -B build-strict -DTRAINS_STRICT_WARNINGS=ON`
- `cmake --build build-strict --target clean`
- `cmake --build build-strict 2>&1 | tee strict-warnings-phase2j.log`

Warning counts:

| Warning Type | Baseline (`strict-warnings.log`) | Current (`strict-warnings-phase2j.log`) | Delta |
| --- | ---: | ---: | ---: |
| `-Wconversion` | 134 | 0 | -134 |
| `-Wsign-conversion` | 124 | 0 | -124 |
| `-Wextra-semi` | 74 | 0 | -74 |
| `-Wshadow` | 17 | 0 | -17 |
| `-Wunused-parameter` | 16 | 0 | -16 |
| `-Wold-style-cast` | 2 | 0 | -2 |
| `-Wuseless-cast` | 1 | 0 | -1 |
| `-Wnull-dereference` | 1 | 1 | 0 |
| **Total** | **369** | **1** | **-368** |

## Completed Work

### Phase 1 (low-risk noise cleanup)

Completed:

- Removed extra semicolons in inline header constructors.
- Removed intentionally unused parameter names in throwing dummy operators.
- Replaced low-risk old/useless casts.
- Fixed local shadowing names.

Outcome:

- Removed all `-Wextra-semi`, `-Wunused-parameter`, `-Wold-style-cast`, and `-Wuseless-cast` warnings.

### Phase 2 (type-boundary normalization)

Completed:

- Normalized signed/unsigned boundaries in headers and core source files.
- Added explicit narrow conversions at clear boundaries.
- Standardized index variable types around container access.

Main touched areas:

- Headers: `trains/newarray.h`, `trains/graph.h`, `trains/edgevert.h`, `trains/braid.h`
- Sources: `src/Graphset.cpp`, `src/graph.cpp`, `src/Graputil.cpp`, `src/Graphalg.cpp`, `src/ttt.cpp`, `src/edgevert.cpp`, `src/hshoe.cpp`, `src/Batch.cpp`, `src/Matrix.cpp`, `src/braid.cpp`, `src/help.cpp`, `src/frontend.cpp`, `src/train.cpp`

Trend snapshots:

- `strict-warnings-phase2d.log`: 126 total
- `strict-warnings-phase2e.log`: 67 total
- `strict-warnings-phase2f.log`: 34 total
- `strict-warnings-phase2g.log`: 24 total
- `strict-warnings-phase2h.log`: 15 total
- `strict-warnings-phase2i.log`: 8 total
- `strict-warnings-phase2j.log`: 1 total

Outcome:

- Removed all `-Wconversion` and `-Wsign-conversion` warnings.

## Remaining Issue

### `-Wnull-dereference` (single diagnostic)

Current warning:

- `/usr/include/c++/13/bits/stl_algobase.h:398:17`
- `warning: potential null pointer dereference [-Wnull-dereference]`

Compiler backtrace points through:

- `std::copy`/`std::vector<long>::operator=` internals (inlined)
- `trains::MyArray<T>::operator=` in `trains/newarray.h`
- `trains::graph::MakeIrreducible(bool)` in `src/Graphalg.cpp`

Interpretation:

- This is emitted from inlined STL internals after optimization.
- It may be a conservative analyzer path rather than a concrete runtime fault.
- It still touches core assignment flow, so it remains open until verified.

## What Remains

1. Build a minimal reproducer for the `MyArray` assignment path used in `MakeIrreducible()`.
2. Run targeted tests under `ASan` and `UBSan` for that path.
3. Audit `MyArray<T>::operator=` invariants (self-assignment, empty state, allocation/copy preconditions).
4. Close with one of:
   - code fix + test + warning gone, or
   - narrow documented toolchain-specific suppression with evidence.

## Validation Gates Used

Run after each warning-reduction batch:

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- strict clean rebuild with log capture

Current test status: `ctest` passes (`8/8`).
