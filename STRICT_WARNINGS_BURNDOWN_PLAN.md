# Strict Warnings Burndown Plan

This plan targets warning reduction while minimizing behavior risk.

## Goals

1. Reduce strict-warning noise in phases.
2. Keep behavior unchanged.
3. Re-run tests after each phase and after each risky file batch.

## Baseline

From `strict-warnings.log` under `-DTRAINS_STRICT_WARNINGS=ON`:

- `-Wconversion`: 134
- `-Wsign-conversion`: 124
- `-Wextra-semi`: 74
- `-Wshadow`: 17
- `-Wunused-parameter`: 16
- `-Wold-style-cast`: 2
- `-Wuseless-cast`: 1
- `-Wnull-dereference`: 1

Hotspots:

- `src/Graphset.cpp`, `src/graph.cpp`, `src/Graputil.cpp`, `src/Graphalg.cpp`
- `trains/newarray.h`, `trains/graph.h`, `trains/edgevert.h`

## Safety Gates

Run after each phase (and optionally per-file batch in Phase 3):

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- `cmake --build build-strict`

## Phase 1 - Low-risk noise cleanup (expected big drop, low behavior risk)

Target warnings:

- `-Wextra-semi`
- `-Wunused-parameter`
- `-Wold-style-cast`
- `-Wuseless-cast`
- trivial `-Wshadow` renames in local scopes

Primary files:

- `trains/newarray.h`
- `trains/graph.h`
- `trains/embedding.h`
- `trains/edgevert.h`
- `src/train.cpp`, `src/braid.cpp`

Approach:

- Remove trailing `;` after inline constructor bodies.
- Mark intentionally unused parameters in throwing dummy operators.
- Replace old-style casts with `static_cast` where obvious.
- Rename shadowing locals only (no logic changes).

Success criteria:

- Majority of non-conversion warnings removed.
- Zero test regressions.

## Phase 2 - Type hygiene helpers and accessor normalization (medium risk)

Target warnings:

- recurrent header-level conversion/sign-conversion from helper accessors

Primary files:

- `trains/braid.h`
- `trains/edgevert.h`
- `trains/graph.h`
- `trains/newarray.h`

Approach:

- Introduce explicit casts at narrow boundaries.
- Normalize `TopIndex()`/size interactions to reduce repeated warning fan-out.
- Prefer local helper variables (`auto` + explicit cast once) instead of repeated mixed-type expressions.

Success criteria:

- Noticeable drop in conversion warnings originating from headers.
- No change in observable test behavior.

### Phase 2 status (in progress)

Applied so far:

- Added explicit accessor casts at header boundaries:
  - `trains/braid.h` (`Length()`)
  - `trains/edgevert.h` (`Valence()`)
  - `trains/graph.h` (`NumberEdges()`, `NumberVertices()`)
- Continued header type-boundary normalization:
  - `trains/newarray.h` (`Invert()` index variables normalized to `std::size_t`)
- Added low-risk variable/type boundary normalization in implementation files:
  - `src/Graphset.cpp` (`BoundaryPeripheralSet`, `IdentityGraph`, `ActOn`, `PrintSingularities`, `Load`)
  - `src/Batch.cpp` (local loop index rename in horseshoe parsing)
  - `src/Graputil.cpp` (local variable rename in `SingleVertexEmbeddingTighten`)

Validation run:

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- `cmake --build build-strict` (captured to `strict-warnings-phase2d.log`)

Current warning snapshot:

- `-Wconversion`: 83 (from 133 at end of phase 1)
- `-Wsign-conversion`: 42 (from 124 at end of phase 1)
- `-Wshadow`: resolved in this batch
- `-Wnull-dereference`: 1 (unchanged)

Phase-2 reduction so far:

- Phase-1 total: 273
- Current total: 126
- Eliminated in phase 2 so far: **147 warnings**

### Phase 2 continuation and closeout (completed)

Additional passes completed after `phase2d`:

- `src/graph.cpp`, `src/Graphalg.cpp`, `src/Graputil.cpp`, `src/ttt.cpp`, `src/edgevert.cpp`, `src/hshoe.cpp`
- `src/Batch.cpp`, `src/Matrix.cpp`, `src/braid.cpp`, `src/help.cpp`, `src/frontend.cpp`, `src/train.cpp`

Validation pattern used for each batch:

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- clean strict rebuild with log capture

Warning snapshots during continuation:

- `strict-warnings-phase2e.log`: total 67
- `strict-warnings-phase2f.log`: `-Wsign-conversion` 20, `-Wconversion` 13, `-Wnull-dereference` 1 (total 34)
- `strict-warnings-phase2g.log`: `-Wsign-conversion` 12, `-Wconversion` 11, `-Wnull-dereference` 1 (total 24)
- `strict-warnings-phase2h.log`: `-Wsign-conversion` 8, `-Wconversion` 6, `-Wnull-dereference` 1 (total 15)
- `strict-warnings-phase2i.log`: `-Wconversion` 5, `-Wsign-conversion` 2, `-Wnull-dereference` 1 (total 8)
- `strict-warnings-phase2j.log`: `-Wnull-dereference` 1 (total 1)

Current strict-warning state:

- `-Wconversion`: 0
- `-Wsign-conversion`: 0
- `-Wnull-dereference`: 1 (unchanged, emitted via inlined STL path)

Net result from baseline to current:

- Baseline total: 369
- Current total: 1
- Eliminated: **368 warnings**

## Phase 3 - Algorithm files conversion cleanup (highest risk)

Target warnings:

- bulk `-Wconversion` / `-Wsign-conversion`

Primary files (in order):

1. `src/Graphset.cpp`
2. `src/graph.cpp`
3. `src/Graputil.cpp`
4. `src/Graphalg.cpp`
5. `src/ttt.cpp`, `src/Batch.cpp`

Approach:

- Standardize loop/index variable types per container usage.
- Avoid implicit signed/unsigned arithmetic in index math.
- Isolate intentional narrow conversions and make them explicit.
- Keep refactors small and scoped to one warning cluster at a time.

Success criteria:

- Significant reduction in conversion/sign-conversion warnings.
- Tests pass after each touched-file batch.

## Phase 4 - Investigate `-Wnull-dereference` diagnostic

Target warning:

- single `-Wnull-dereference` emitted from inlined STL internals

Approach:

- Build minimal reproducer from the implicated `MyArray` assignment path.
- Determine whether warning is true issue, optimizer artifact, or toolchain false positive.
- If no actionable bug is found, document and optionally suppress locally/conditionally.

### Remaining diagnostic detail (current state)

Current warning (from `strict-warnings-phase2j.log`):

- `/usr/include/c++/13/bits/stl_algobase.h:398:17`
- `warning: potential null pointer dereference [-Wnull-dereference]`

Instantiation/call chain emitted by GCC points to:

- `std::copy` internals in `stl_algobase.h`
- `std::vector<long>::operator=`
- `trains::MyArray<long>::operator=` in `trains/newarray.h`
- `trains::graph::MakeIrreducible(bool)` in `src/Graphalg.cpp`

What this means:

- The warning is not from a direct dereference in user code at the reported file.
- GCC inlines template/library code and then performs path analysis on the optimized IR.
- A potentially null destination/source pointer path is inferred in the inlined copy path.

Plausible explanations (ordered by likelihood):

1. Conservative/static-analysis false positive on a valid empty-vector copy path.
2. Edge case in custom array assignment flow where ownership/state can transiently
   appear null to analysis despite valid runtime behavior.
3. Real latent bug if an invalid `MyArray` state is reachable before assignment.

Why we did not "quick-fix" it in Phase 2:

- Any change here touches container assignment semantics used broadly in core algorithms.
- A cast/index cleanup style fix is not sufficient; this requires semantic verification.
- Blind suppression would hide a potentially real memory-safety issue.

Investigation plan for Phase 4:

1. Reproduce in a reduced unit/integration case that hits `MakeIrreducible()` assignment.
2. Build with sanitizers (`ASan`/`UBSan`) and run targeted tests to look for concrete faults.
3. Inspect `MyArray<T>::operator=` invariants (self-assignment, empty state, allocation,
   copy length consistency).
4. If runtime evidence is clean and reproducer indicates analyzer artifact, contain warning
   suppression to this toolchain/version/path with rationale in code comments.

Exit criteria:

- Either: implement and validate a real fix with tests, warning removed.
- Or: document and narrowly suppress with reproducible evidence that behavior is safe.

## Test sensitivity assessment

Current CTest suite confidence against accidental behavior changes:

- **High** for gross breakage in core workflows (graph setup, matrix formatting, I/O round-trip, batch parse path, horseshoe->train->TTT integration smoke).
- **Medium** for subtle algorithmic behavior drift (exact train-track decisions, corner-case reducibility branching, deep singularity/gate edge cases).

Why not higher than medium overall:

- The suite is broad but not exhaustive on branch-level algorithm semantics.
- Most tests validate invariants and representative flows, not full oracle outputs across many known cases.

Recommended boost before/during Phase 3:

1. Add golden-case fixtures for known braids/horseshoe inputs with expected Thurston type and selected invariants.
2. Add regression tests around `FindTrack`, `FindReduction`, and singularity reporting outputs.
3. Add a strict-mode CI job so warning deltas are tracked continuously.

## Phase 1 status (completed)

Applied in this pass:

- removed trailing `;` after inline constructor bodies in:
  - `trains/newarray.h`
  - `trains/graph.h`
  - `trains/embedding.h`
- removed intentionally unused parameter names in throwing dummy operators:
  - `trains/edgevert.h`
- replaced low-risk cast/style issues:
  - `src/train.cpp` old-style cast -> `static_cast<long>(...)`
  - `src/Batch.cpp` function pointer cast -> `static_cast<int(*)(int)>(tolower)`
  - `src/braid.cpp` removed useless cast in horseshoe conversion loop
- fixed low-risk local shadowing names:
  - `src/frontend.cpp` matrix-print loop index rename
  - `src/ttt.cpp` renamed local `E` to `edgeImage`

Validation run:

- `cmake --build build`
- `ctest --test-dir build --output-on-failure`
- `cmake --build build-strict` (captured to `strict-warnings-phase1.log`)

Resulting warning counts (phase-1 snapshot):

- `-Wconversion`: 133 (from 134)
- `-Wsign-conversion`: 124 (unchanged)
- `-Wshadow`: 15 (from 17)
- `-Wnull-dereference`: 1 (unchanged)
- `-Wextra-semi`, `-Wunused-parameter`, `-Wold-style-cast`, `-Wuseless-cast`: resolved in this pass

Total warnings eliminated in Phase 1:

- Baseline total: 369
- Phase-1 total: 273
- Eliminated: **96 warnings**
