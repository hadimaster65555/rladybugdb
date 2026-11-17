## Resubmission after archival

rladybugdb 0.4.4 was archived on 2026-11-06 because installation errors on
the four CRAN macOS flavors were not corrected in time. Version 0.4.5 fixes
those errors. It makes no other functional changes; all other flavors were
OK for 0.4.4.

### r-release-macos-x86_64, r-oldrel-macos-arm64, r-oldrel-macos-x86_64

```
configure: ERROR: CMake 3.15 or newer is required.
```

`configure` only looked for `cmake` on the `PATH`. As described in "Writing R
Extensions" (Using cmake), it now checks the `CMAKE` environment variable,
then the `PATH`, then `/Applications/CMake.app/Contents/bin/cmake`,
`/opt/homebrew/bin/cmake`, and `/usr/local/bin/cmake`, and reports the CMake
it uses in the installation log. This also addresses the M1mac additional
issue, which failed the same way.

### r-release-macos-arm64

```
src/c_api/connection.cpp:110: error: no member named 'atomic_ref' in namespace 'std'
```

The bundled LadybugDB source used `std::atomic_ref`, which libc++ provides
only from LLVM 19 (macOS SDK 15.4); this machine uses the macOS 14 SDK. The
vendored source now uses `std::atomic_ref` only when `__cpp_lib_atomic_ref`
is defined, and the equivalent GCC/Clang atomic builtin otherwise.

### Toolchains that never reached compilation

The three flavors that failed in `configure` use Apple clang 14 and build
for macOS 11. Their C++ library has no usable `std::format`, newer libc++
marks floating-point formatting unavailable for targets older than macOS
13.3, and `std::ranges` is incomplete there. The bundled engine now calls
`std::format` through a small wrapper that falls back to the {fmt} library
already contained in the engine source when a configure compile-and-link
probe finds `std::format` unavailable, and its `std::ranges` calls use
`<algorithm>` equivalents. The configure probes now compile in R's C++20
mode (`CXX20STD`). Other platforms keep using `std::format`.

Compiling the whole engine with clang 14 and 15 also showed seven template
declarations that need an explicit `typename` and one lambda that captured a
structured binding (both need clang 16), and SimSIMD's ARM bf16 kernels,
whose intrinsics `arm_neon.h` provides only from LLVM 16 (Apple clang 15).
These are fixed in standard C++, and SimSIMD skips the bf16 kernels on older
clang releases.

On macOS, `configure` also builds the engine for the deployment target that
R's compiler links the package for (read from a probe object). CMake 3.x
otherwise targets the host macOS when the SDK is newer than the host, which
produced `ld` warnings about objects built for a newer macOS in local tests.

All changes to the vendored engine are recorded in
`tools/patches/ladybugdb-macos-compat.patch` and reproduced from the pinned
upstream crate by `tools/vendor.R`; {fmt} is credited in `inst/COPYRIGHTS`.

## Test environments

Local, macOS 26.6.2 (arm64), `R CMD check --as-cran` of the built tarball:

* R 4.6.1, Apple clang 21, CMake available only as
  `/Applications/CMake.app` (not on the `PATH`), as on CRAN's macOS machines:
  `configure` found CMake.app and selected `std::format`; 1 NOTE (archived
  package), no warnings; tests, examples, vignettes, and both manuals OK.
* R 4.6.1, Apple clang 21, macOS 15.4 SDK, `MACOSX_DEPLOYMENT_TARGET=11.0`
  (selects the bundled {fmt}): installs, all tests pass. The only WARNING is
  an `ld` deployment-target mismatch against this R build's `libR.dylib`
  (built for macOS 13), which does not arise on CRAN's macOS 11 builds.
* R 4.6.1 with the macOS 14 SDK (CRAN r-release-macos-arm64 setup): PENDING
* R 4.5 (big-sur arm64 build) with Apple clang 14.0.0 from Command Line
  Tools 14.2 (CRAN r-oldrel-macos-arm64 compiler), macOS 11 target: PENDING
* Bundled engine compiled with Apple clang 14.0.3 from Command Line Tools
  14.3.1 for x86_64, macOS 11 target (CRAN macOS x86_64 compiler): PENDING

Remote:

* win-builder: R-devel, R-release, R-oldrelease: PENDING
* mac-builder: R-release, R-devel: PENDING
* R-hub: linux (R-devel), gcc16, clang23, ubuntu-clang, ubuntu-next
  (R-patched), ubuntu-release: PENDING
* GitHub Actions: Ubuntu (release, oldrel-1, devel, arm64), macOS
  (macos-14 and macos-15-intel, release and oldrel-1), Windows (release,
  oldrel-1, devel, arm64), and CRAN-like macOS jobs with CMake only in
  `/Applications/CMake.app`: PENDING

## R CMD check results

0 errors | 0 warnings | 1 note

* New submission. Package was archived on CRAN (Archived on 2026-11-06 as
  issues were not corrected in time); this version fixes those issues.
