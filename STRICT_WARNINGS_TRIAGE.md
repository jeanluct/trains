# Strict Warnings Triage

Build profile used:

- `cmake -S . -B build-strict -DTRAINS_STRICT_WARNINGS=ON`
- `cmake --build build-strict`

Log captured in `strict-warnings.log`.

Latest strict snapshot was captured in `strict-warnings-phase2j.log` after
conversion/sign-conversion cleanup.

## Warning counts by type

Baseline (`strict-warnings.log`):

- `-Wconversion`: 134
- `-Wsign-conversion`: 124
- `-Wextra-semi`: 74
- `-Wshadow`: 17
- `-Wunused-parameter`: 16
- `-Wold-style-cast`: 2
- `-Wuseless-cast`: 1
- `-Wnull-dereference`: 1

Current (`strict-warnings-phase2j.log`):

- `-Wconversion`: 0
- `-Wsign-conversion`: 0
- `-Wextra-semi`: 0
- `-Wshadow`: 0
- `-Wunused-parameter`: 0
- `-Wold-style-cast`: 0
- `-Wuseless-cast`: 0
- `-Wnull-dereference`: 1

## Hotspots (by file)

- `src/Graphset.cpp`: 96
- `trains/newarray.h`: 48
- `trains/graph.h`: 45
- `src/graph.cpp`: 36
- `trains/edgevert.h`: 26
- `src/Graputil.cpp`: 24
- `src/Graphalg.cpp`: 18
- `src/ttt.cpp`: 16

## Triage by importance

### 1) `-Wconversion` / `-Wsign-conversion` (High)

Why this matters:

- These can hide real numeric bugs (sign flips, truncation, index wraparound).
- This codebase frequently mixes `int`, `long`, `uint`, and STL size types.
- Some warnings occur in indexing and graph-label logic where bad conversions can
  become correctness bugs on edge cases.

Risk assessment:

- **High overall** due to volume and location in core graph algorithms.
- Many are likely "legacy-safe" in normal input ranges, but not all are benign.

Suggested treatment order:

1. `src/Graphset.cpp` and `src/graph.cpp`
2. `src/Graputil.cpp` and `src/Graphalg.cpp`
3. header-level helpers (`trains/graph.h`, `trains/newarray.h`, `trains/braid.h`, `trains/edgevert.h`)

### 2) `-Wshadow` (Medium)

Why this matters:

- Shadowing increases review/debug burden and can cause accidental misuse of the
  wrong variable.
- Most occurrences are local-loop redeclarations; usually low runtime risk.

Risk assessment:

- **Medium maintainability risk**, generally low immediate correctness risk.

### 3) `-Wunused-parameter` (Low)

Why this matters:

- Mostly from intentionally "dummy" operators in `trains/edgevert.h` that throw.

Risk assessment:

- **Low**. Cosmetic; can be silenced by unnamed params or `[[maybe_unused]]`.

### 4) `-Wextra-semi` (Low)

Why this matters:

- Style-only warnings from trailing semicolons after inline constructor bodies in
  headers (`trains/newarray.h`, `trains/graph.h`, `trains/embedding.h`).

Risk assessment:

- **Low**. No behavior impact.

### 5) `-Wold-style-cast` / `-Wuseless-cast` (Low)

Why this matters:

- Minor style modernization opportunities.

Risk assessment:

- **Low**.

### 6) `-Wnull-dereference` (Investigate, likely false positive)

Observed at:

- `/usr/include/c++/13/bits/stl_algobase.h` (instantiated from `MyArray` assignment path)

Why this matters:

- This one is emitted from inlined STL internals under optimization; it may be a
  conservative compiler diagnostic.

Risk assessment:

- **Medium until confirmed**, but likely not a direct bug report against STL.
- Needs targeted repro/minimization before deciding whether to suppress or code-change.

Detailed analysis (remaining warning):

- Reported location is inside libstdc++ (`stl_algobase.h`) because template code from
  `std::copy`/`std::vector` is inlined into the optimized compile unit.
- GCC diagnostic backtrace maps this to the project path:
  - `trains::MyArray<T>::operator=` (`trains/newarray.h`)
  - called from `trains::graph::MakeIrreducible(bool)` (`src/Graphalg.cpp`)
- Interpretation: compiler's static analyzer sees at least one feasible path where
  source/destination pointer could be null at the copy site.

Important nuance:

- This does **not** automatically prove a runtime crash.
- It can arise from conservative reasoning around empty containers, allocation
  assumptions, or template expansion under optimization.
- But because the warning touches copy/assignment in core data structures, it
  should be treated as unresolved until verified.

Recommended closure workflow:

1. Create a minimal reproducer that exercises the same `MyArray` assignment route.
2. Run focused tests under `ASan` and `UBSan` on that path.
3. Audit `MyArray` assignment invariants and allocation/copy preconditions.
4. If no defect is reproducible, add narrow toolchain-conditional suppression with
   inline rationale and a link to the reproducer notes.

## Practical prioritization

If we start fixing warnings, highest ROI is:

1. Normalize integer/index types in graph algorithms (`int`/`long`/`uint`/`size_t`).
2. Remove easy noise (`-Wextra-semi`, `-Wunused-parameter`, shadowed loop vars).
3. Rebuild strict profile and re-triage remaining conversion/null-deref warnings.

No code behavior changes were made in this triage pass.

Status update: conversion/sign-conversion cleanup is complete; only the single
`-Wnull-dereference` diagnostic remains pending Phase 4 investigation.
