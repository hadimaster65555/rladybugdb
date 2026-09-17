## Test environments

* macOS Tahoe 26.6.2 (aarch64), R 4.6.1, Apple Clang 21.
* `R CMD check --as-cran rladybugdb_0.4.4.tar.gz` with all Suggests
  installed, run with `CFLAGS` and `CXX20FLAGS` set to `-g -O2 -Wall
  -pedantic` so the diagnostics reported by the Debian pre-test are
  reproduced locally.

## R CMD check results

0 errors | 0 warnings | 1 note

## Additional portability verification

* Debian-based Linux container (aarch64), Clang 19.1.7: focused C++20
  16-byte atomic link and runtime-load test.

## NOTE: CRAN incoming feasibility

```
New submission
```

This is a new submission.

## Changes in response to the 0.4.3 incoming Debian install pre-test

The Debian R-devel pre-test using Clang 23.1.1 installed the package
successfully, but `00install.out` contained significant warnings
(`-Wgnu-anonymous-struct` and `-Wnested-anon-types`) from the bundled RE2
sources in the vendored LadybugDB tree.

The configure script forwarded R's configured compiler flags unchanged to the
CMake build of the bundled engine, so `-Wall -pedantic` was applied to
third-party code that intentionally uses compiler extensions. Those diagnostics
are not actionable in this package. Configure now removes diagnostic-only flags
(`-Wall`, `-Wextra`, `-W`, `-pedantic`, `-Wpedantic`, `-pedantic-errors`,
`-Weverything`) before passing R's flags to the bundled build. Every other
configured flag, including optimisation, debugging, architecture, hardening
(for example `-Wp,-D_FORTIFY_SOURCE=3`), linker, and sanitizer settings, is
still passed through unchanged. This package's own sources in `src/` are
unaffected and continue to compile with R's full flags, including `-pedantic`,
through `src/Makevars`.

No warning suppression flags were added, so the build does not depend on
compiler-specific `-Wno-*` options.

## Changes in response to the 0.4.2 incoming Debian install pre-test

The Debian R-devel pre-test using Clang 23.1.1 compiled LadybugDB to 100% and
linked `rladybugdb.so`, but the temporary-load test then failed with an
unresolved `__atomic_compare_exchange` symbol. LadybugDB uses a 16-byte
`std::atomic<EvictionCandidate>`; Debian Clang implements this operation using
the compiler's `libatomic` runtime, which was absent from the final package
link command.

The configure script now compiles and links a small C++20 executable using the
same compiler and flags reported by R. It first tests the 16-byte atomic
operation without an additional library, then retries with `-latomic` if
needed. The detected library is placed after the static LadybugDB archive in
`PKG_LIBS`. Configuration fails early with a specific diagnostic if neither
link succeeds.

A focused Debian-based Linux Clang test reproduced the unresolved symbol
without `-latomic`; the same executable linked and ran successfully with `-latomic`
and resolved `libatomic.so.1`. On the macOS test system, the operation is
provided natively and the package correctly avoids adding `-latomic`. The full
check reported above completed successfully, including installation, loading,
compiled-code inspection, and tests.

## Changes in response to the 0.4.1 incoming install pre-tests

The Debian R-devel pre-test used Clang 23 and found that the bundled Thrift
transport header used `uint8_t` and `uint32_t` without directly including the
standard fixed-width integer header. The vendored source patch now includes
`<stdint.h>` before those declarations.

The Windows R-devel pre-test used Rtools/MinGW and exposed two upstream
compiler-assumption issues. CRoaring's C inline definition produced an external
symbol that collided with the C++ translation unit's definition of
`roaring_bitmap_contains`, and LadybugDB selected the MSVC-only
`_set_se_translator` API for every `_WIN32` compiler. The vendored source patch
now gives the affected CRoaring inline function internal linkage on MinGW,
omits the corresponding external-inline declaration there, and restricts the
structured-exception translator to `_MSC_VER` builds. The package configure
script also enables LadybugDB's malloc-backed buffer manager on
MINGW/MSYS/CYGWIN, so Rtools does not depend on MSVC structured exception
handling.

The source archive and checksum manifest were regenerated after applying these
patches. A fresh build from the resulting archive and the check reported above
both completed successfully; in particular:

```
* checking whether package 'rladybugdb' can be installed ... OK
* checking compiled code ... OK
* checking tests ... OK
```

## Changes in response to the 0.4.0 incoming pre-test

The 0.4.0 incoming pre-test reported unsafe symbols in precompiled upstream
LadybugDB and OpenSSL libraries. Version 0.4.1 no longer downloads or ships
precompiled libraries or runtime DLLs.

The package now contains the LadybugDB 0.20.4 source archive and builds a
static library during installation with CMake and R's configured C/C++
toolchain. The archive has a pinned SHA-256 checksum, and the reproducible
vendoring procedure and CRAN-specific source patch are included under
`tools/`. The source patch removes or disables native code paths that call
`abort`, `exit`, the system RNG, or write directly to stdout/stderr. Native
remote-extension installation is disabled in the CRAN build, so OpenSSL and
the upstream HTTP client are not linked.

The resulting package installs one shared library and no third-party runtime
DLLs. In the check reported above, both relevant checks now pass:

```
* checking compilation flags in Makevars ... OK
* checking compiled code ... OK
```

All examples, tests, vignettes, and the PDF and HTML manuals also pass. The
source package contains no `.o`, `.a`, `.so`, `.dll`, `.dylib`, or executable
files.

The source tarball is 8.7 MB. A clean native installation took approximately
14 minutes elapsed on the macOS test system. The build performs no network
access and is deliberately limited to at most two parallel compile jobs.
