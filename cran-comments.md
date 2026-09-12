## Test environments

* macOS Tahoe 26.6.2 (aarch64), R 4.5.2, Apple Clang 21.
* `R CMD check --as-cran --no-manual` with DBItest and nanoarrow installed.

## R CMD check results

0 errors | 0 warnings | 1 note

The NOTE reports references to `abort`, standard-error/output streams, `rand`,
and related symbols in the statically linked LadybugDB 0.20.4 library. These
symbols are supplied by the upstream engine archive; the R wrapper does not
call them directly. Static linking is used on macOS and Windows as required
for CRAN external libraries.

The package configure scripts select a matching LadybugDB 0.20.4 header and
static/import library for each supported platform, download only over HTTPS,
and verify the published SHA-256 checksum before compilation.
