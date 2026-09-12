## Test environments

* macOS Tahoe 26.6.2 (aarch64), R 4.5.2, Apple Clang 21.
* win-builder and Debian incoming pre-tests, R-devel.
* `R CMD check --as-cran` with Suggests packages installed.

## R CMD check results

0 errors | 0 warnings | 2 notes

## NOTE 1: CRAN incoming feasibility

```
New submission

Possibly misspelled words in DESCRIPTION:
  LadybugDB (10:9)
```

This is a new submission.

The flagged word is the name of the upstream database. One occurrence of
`LadybugDB` in the Description field had been left unquoted; it is now quoted,
so every software, product, and language name in Title and Description
('LadybugDB', 'Cypher', 'Kuzu', 'Rcpp', 'Python') is consistently in single
quotes. The names are also recorded in `inst/WORDLIST`.

## NOTE 2: checking compiled code

The check reports symbols such as `abort`, `rand`, `printf`, `puts`,
`putchar`, `stderr`, `std::cout`, and `std::cerr`.

None of these are called by this package. The R wrapper sources
(`src/rladybugdb.cpp`, `src/RcppExports.cpp`) contain no calls to any of them;
all diagnostic output goes through `Rprintf()` / `REprintf()`. The only
undefined symbols in the wrapper objects that resemble the flagged names are
`Rprintf`, `REprintf`, and the compiler-emitted C++ ABI helpers
`__cxa_atexit` and `__cxa_guard_abort` (static-local initialisation), which are
not calls to `exit` or `abort`.

Every flagged symbol is linked in from the unmodified upstream LadybugDB
library, and each one is traceable to a specific upstream object file:

| Symbol                    | Upstream object file                                            | Origin                                             |
| ------------------------- | --------------------------------------------------------------- | -------------------------------------------------- |
| `printf`, `puts`, `putchar` | `roaring.c.o`                                                   | bundled CRoaring debug dump helpers (`roaring_bitmap_printf`, `container_printf`, `bitset_print`) |
| `std::cout`, `std::cerr`  | `ConsoleErrorListener.cpp.o`, `Parser.cpp.o`, `ParserATNSimulator.cpp.o`, `ATNState.cpp.o`, `RuntimeMetaData.cpp.o`, `TokenStreamRewriter.cpp.o` | bundled ANTLR4 C++ runtime used by the 'Cypher' parser |
| `std::cout`               | `terminal_progress_bar_display.cpp.o`                            | upstream interactive CLI shell progress bar, not reachable through the C API |
| `stderr`                  | `art_index.cpp.o`                                                | upstream adaptive-radix-tree index diagnostics      |
| `abort`                   | `prog.cpp.o`                                                     | upstream parser program object                      |
| `rand`                    | `extension_installer.cpp.o`                                      | upstream extension installer, not reachable through the DBI interface |

These live in diagnostic, CLI-only, and third-party vendored code paths that
the DBI bindings never enter. Because the platform artifacts are static
archives, the linker retains the symbols even though the code is not invoked,
which is the situation described by the check's own caveat that "the detected
symbols are linked into the code but might come from libraries and not actually
be called". Removing them would require patching upstream LadybugDB, and
patching the verified upstream binaries would defeat the checksum verification
described below.

On Windows the same symbols appear in the shipped upstream runtime DLLs
(`lbug_shared.dll`, and `_exit` from the unmodified OpenSSL `libcrypto-3-x64.dll`)
rather than in the wrapper.

## Bundled binaries

The `configure` and `configure.win` scripts select the matching LadybugDB
header and static/import library for each supported platform, download only
over HTTPS from the upstream release page, and verify pinned SHA-256 checksums
before compilation. On Windows the two OpenSSL runtime DLLs required by the
upstream LadybugDB DLL are likewise downloaded, verified against pinned
checksums, and installed beside the package DLL.
