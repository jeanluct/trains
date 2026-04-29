*trains* is a C++ library originally written by **[Toby Hall](https://www.liverpool.ac.uk/people/toby-hall)**.   It is an implementation of Bestvina and Handel's algorithm for determining train tracks of surface homeomorphisms (Topology **34** (1995), 109-140).

As Toby only maintains a version of *trains* with a graphical interface for Windows, this is based on the last command-line version (trains4).  **Toby Hall is not responsible for bugs in this GitHub version of the software, since he is not involved in its maintenance.**

The code is maintained by **[Jean-Luc Thiffeault](https://people.math.wisc.edu/~thiffeault/)**.  It is being updated to run on current C++ compilers.

## Building

The project builds with CMake. The top-level `Makefile` is a backwards-compatible wrapper around CMake.

- Preferred CMake flow:
  - `cmake -S . -B build`
  - `cmake --build build`
- Back-compatible Make targets:
  - `make` (build library + executables)
  - `make lib` (build static library only)
  - `make clean`
  - `make distclean`

### Optional strict warnings profile

Enable additional compile-time checks without changing default behavior:

- `cmake -S . -B build -DTRAINS_STRICT_WARNINGS=ON`
- `cmake --build build`

This adds an extended warning set for GNU/Clang (`-Wextra`, `-Wpedantic`,
`-Wconversion`, `-Wsign-conversion`, etc.) and `/W4` on MSVC.
