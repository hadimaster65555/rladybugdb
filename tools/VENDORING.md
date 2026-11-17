# Vendoring LadybugDB

The CRAN source package includes a compressed LadybugDB source tree rather
than downloading platform binaries during installation. The source is the
`lbug` crate published by the LadybugDB project at crates.io, pinned by version
and SHA-256 in `tools/lbug_source_checksums`.

`tools/vendor.R` performs the maintainer-only refresh:

1. Download and verify the pinned upstream crate.
2. Extract its complete `lbug-src` directory.
3. Apply `tools/patches/ladybugdb-cran.patch`.
4. Route upstream `std::format` calls through `lbug::common::stringFormat`:
   `#include <format>` becomes `#include "common/string_format.h"` and
   `std::format(` becomes `lbug::common::stringFormat(` in `lbug-src/src`.
   This is a fixed-string rewrite, so it repeats exactly on engine updates.
5. Apply `tools/patches/ladybugdb-macos-compat.patch`, which is made against
   the rewritten tree.
6. Create `tools/vendor/ladybugdb-<version>.tar.xz` and update its checksum.

The CRAN patch adds a dedicated `LBUG_R_PACKAGE` CMake mode. It disables native
remote-extension downloads and their OpenSSL dependency, uses already
generated WAL sources so Python is not needed, supports the Rtools MinGW/LLVM
archivers, and removes code paths that terminate the host R process or write
directly to stdout/stderr. Third-party debug printers are compiled as no-ops.

The macOS compatibility patch lets the engine build with the older toolchains
on CRAN's macOS machines (Apple clang 14, and macOS SDKs before 15.4):

* `src/include/common/string_format.h` defines `stringFormat`. It forwards to
  `std::format`, or, when the `LBUG_FMT_FALLBACK` CMake option is on, to the
  header-only {fmt} library that LadybugDB bundles with spdlog. `configure`
  turns the option on when a compile-and-link probe shows that the C++ library
  cannot provide `std::format` for the deployment target. Setting
  `RLADYBUGDB_FMT_FALLBACK=yes` or `no` forces either implementation.
* C API handle destruction uses `std::atomic_ref` when the library provides
  it (`__cpp_lib_atomic_ref`) and the equivalent GCC/Clang atomic builtin
  otherwise.
* `std::ranges` algorithms are replaced by their `<algorithm>` equivalents.

LadybugDB and all bundled third-party license files remain inside the source
archive. Run `Rscript tools/vendor.R` only when intentionally updating the
pinned engine or the portability patches, then review and test the resulting
archive before committing it.

To change the macOS compatibility patch, prepare a tree at the state of step 4
(upstream crate, CRAN patch, rewrite), commit it to a scratch git repository,
make the changes there, and save the `git diff` output (default `a/` and `b/`
prefixes, applied with `patch -p1`) as
`tools/patches/ladybugdb-macos-compat.patch`.
