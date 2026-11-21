## Resubmission after archival

rladybugdb 0.4.4 was archived on 2026-11-06 because installation errors on
the four CRAN macOS flavors were not corrected in time. Version 0.4.6 fixes
those errors and the two additional issues that the CRAN auto-check reported
for 0.4.4, gcc-UBSAN and M1mac. Version 0.4.5, submitted earlier on
2026-11-21, had the macOS fixes but not the gcc-UBSAN fixes. This submission
replaces it, so please disregard the pending 0.4.5 submission.

All other flavors were OK for 0.4.4. The other changes are small: ggplot2
and dplyr, which one vignette loads, are declared in Suggests; the bundled
engine now also builds on Windows on ARM64 (Rtools' clang); and a test that
needs the suggested bit64 package now skips when bit64 is not installed.

### gcc-UBSAN

```
.../lbug-src/third_party/mbedtls/include/mbedtls/sha256.h:49:16: warning: type 'struct mbedtls_sha256_context' violates the C++ One Definition Rule [-Wodr]
```

The bundled Mbed TLS is compiled as C++. Outside its own sources it renames
private struct members (`MBEDTLS_PRIVATE`), so the library and the engine's
SHA-256 wrapper saw two definitions of the same struct. The member names are
now the same everywhere.

```
src/processor/result/factorized_table.cpp:757:30: runtime error: member access within misaligned address 0x... for type 'struct overflow_value_t', which requires 8 byte alignment
third_party/re2/onepass.cpp:424:27: runtime error: index 1 out of bounds for type 'unsigned int [1]'
```

The engine packs values in its row layouts (factorized-table tuples, string,
list and struct row data, hash-join entries, sort-key tuple information)
without padding, and read or wrote them through typed pointers. Those
accesses now copy the values with `memcpy`. RE2's one-pass matcher indexed a
one-element array past its end; it now uses a flexible array member, as
upstream RE2 does. All of these changes are in the bundled engine and are
recorded in `tools/patches/ladybugdb-sanitizers.patch`.

### M1mac, r-release-macos-x86_64, r-oldrel-macos-arm64, r-oldrel-macos-x86_64

```
configure: ERROR: CMake 3.15 or newer is required.
```

`configure` only looked for `cmake` on the `PATH`. As described in "Writing R
Extensions" (Using cmake), it now checks the `CMAKE` environment variable,
then the `PATH`, then `/Applications/CMake.app/Contents/bin/cmake`,
`/opt/homebrew/bin/cmake`, and `/usr/local/bin/cmake`, and reports the CMake
it uses in the installation log. The bundled engine also configures with
CMake 4.4.5, the version the M1mac notes list.

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

Compared with 0.4.5, version 0.4.6 changes only the bundled engine (the
sanitizer and Windows ARM64 patches), one test, and the package metadata.
The results below are for the final 0.4.6 sources.

Sanitizer checks of 0.4.6:

* CRAN's gcc-ASAN/UBSAN setup in R-hub's gcc-asan image (Fedora 44,
  R-devel, GCC 16 with `-fsanitize=address,undefined,bounds-strict` and
  `-flto=10`, which `configure` also passes to the bundled engine): the
  package installs without warnings (no `-Wodr`), and there are no sanitizer
  reports in the installation log, the tests (206 passed; 7 skipped because
  igraph, tidygraph, and arrow could not be installed in that image), the
  examples, or the vignettes.
* Local, macOS 26.6.2 (arm64), R 4.6.1, with the engine and the package
  compiled by Apple clang 21 with `-fsanitize=undefined
  -fstrict-flex-arrays=3`: no runtime errors in the tests (228 passed, none
  skipped), the examples, or the vignettes.

Other checks of 0.4.6:

* Local `R CMD check --as-cran` of the built tarball, macOS 26.6.2 (arm64),
  R 4.6.1 (CRAN's arm64 build), Apple clang 21, CMake 4.4.5 (the version on
  the M1mac machine): 1 NOTE (archived package); tests, examples, vignettes,
  and both manuals OK.
* GitHub Actions: a macOS 15 runner building with the macOS 14 SDK and
  `MACOSX_DEPLOYMENT_TARGET=14.0`, with Homebrew's cmake removed and
  CMake.app installed (the r-release-macos-arm64 setup), and the same with
  `MACOSX_DEPLOYMENT_TARGET=11.0` (bundled {fmt}); macOS arm64 and x86_64
  (R release and oldrel-1), Ubuntu x86_64 (R release, oldrel-1, and devel),
  Ubuntu arm64 (R release), Windows x86_64 (R release, oldrel-1, and
  devel), and Windows ARM64 (R release, Rtools' clang 19): OK.
* R-hub: linux (R-devel), ubuntu-release, ubuntu-next (R-patched), and
  ubuntu-clang (clang 23): OK. gcc16 (Fedora 44, GCC 16.2.1) installs and
  passes the tests; with that container's `-O3`, GCC 16 reports
  `-Warray-bounds` inside libstdc++'s `std::sort` in one unchanged file of
  the bundled engine, while with the `-g -O2` flags of CRAN's fedora-gcc,
  GCC 16.2.0 gives no warnings for that file. clang23 (clang 23 with libc++)
  installs, but the tests segfault inside `demangle()` in Rcpp.so when the
  first `Rcpp::stop()` records its stack trace, because that container's
  Rcpp reads the libc++ `std::string` with libstdc++'s layout; 0.4.4 fails
  identically there, and in R-hub's debian-clang image (clang 23 and libc++,
  every package built from source) the tests of 0.4.5 passed.
* win-builder (R-devel, R-release, and R-oldrelease): OK.

Checks of 0.4.5 for the older macOS toolchains (the macOS-specific code is
unchanged in 0.4.6):

* R 4.6.1 with CMake available only as `/Applications/CMake.app` (not on
  the `PATH`), as on CRAN's macOS machines: `configure` found CMake.app and
  selected `std::format`; 1 NOTE (archived package).
* R 4.5.2 (CRAN's big-sur arm64 build, as on r-oldrel-macos-arm64) with
  LLVM clang 14.0.6 and its libc++, the open-source counterpart of Apple
  clang 14.0.0 (Apple's Command Line Tools 14.2 were not available here),
  the macOS 15.4 SDK, and a macOS 11 deployment target, again with CMake
  only as CMake.app: `configure` selected the bundled {fmt}; 1 NOTE
  (archived package); tests OK.
* LLVM clang 15.0.7 and its libc++ (the counterpart of Apple clang 14.0.3,
  CRAN's x86_64 macOS compiler), x86_64, macOS 11 target: the bundled engine
  and the package's own sources compile without errors or warnings
  (compilation only).
* win-builder (R-devel, R-release, and R-oldrelease): OK.

mac-builder was unavailable (HTTP 502) from 2026-11-15 to 2026-11-21, so the
macOS results above come from the local and GitHub Actions runs.

## R CMD check results

0 errors | 0 warnings | 1 note

* New submission. Package was archived on CRAN (Archived on 2026-11-06 as
  issues were not corrected in time); this version fixes those issues.
