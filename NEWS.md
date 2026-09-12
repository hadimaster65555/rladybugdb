# rladybugdb 0.4.0

## Engine and native safety

* Updated the embedded engine from LadybugDB 0.15.2 to 0.20.4. Platform
  artifacts and matching headers are selected for macOS, Linux, and Windows
  and verified against pinned SHA-256 checksums.
* Linked the upstream static library on macOS and Linux, eliminating the local
  `@rpath/liblbug.dylib` development failure. Windows installs its matching
  runtime DLL through `install.libs.R`.
* Result, connection, and database ownership is now explicit. Closed-handle,
  live-child, finalizer, and double-close paths are checked natively.
* Fixed R-devel/Windows compilation by passing explicit `Rboolean` values to
  Arrow external-pointer finalizers.
* Fixed Windows loading by installing the checksum-verified OpenSSL runtime
  DLLs required by the upstream LadybugDB DLL.
* Added a persisted 0.15.2 compatibility fixture and migration guidance.

## Results, parameters, and types

* `as.data.frame()` is repeatable and `print()`/`format()` use a bounded,
  non-consuming preview.
* Added `lb_fetch()`, `lb_has_next()`, `lb_reset()`, `lb_result_info()`,
  `lb_query_summary()`, and `lb_next_result()` for streaming and multi-result
  queries.
* Named parameters now require unique, non-empty names. All typed R missing
  scalars bind as database `NULL`, and binding failures identify the parameter
  in a typed error.
* Added parameter support for dates, timestamps, `integer64`, raw bytes, lists,
  arrays, and structs.
* Added exact DECIMAL and INT128 output, configurable INT64/UINT64 handling,
  raw BLOB output, UTC timestamp handling, and structured INTERVAL, UNION, and
  recursive-path values.

## R integrations

* Added native Arrow C Data Interface export, chunked Arrow fetching, Arrow
  table registration, and `lb_copy_from_arrow()`. Data-frame loading prefers
  Arrow and retains CSV as an explicit fallback.
* Added a DBI driver with connection, query, binding, fetch, transaction,
  quoting, and table metadata methods.
* Added query timeout, interruption, transaction, scoped-connection, database
  configuration, and extension management helpers.
* Graph conversion now handles recursive paths, empty results, null-leading
  columns, multiple labels and relationship types, isolated nodes, and exact
  internal identifiers.

## Packaging

* Removed tracked compiler output and the old bundled dylib, regenerated Rcpp
  and R documentation, and excluded development-only assets from source builds.
* Added cross-platform R CMD check and native sanitizer CI jobs, installed
  examples, and extension and storage-migration vignettes.

# rladybugdb 0.2.0

* Replaced the original Python/reticulate backend with native Rcpp bindings to
  LadybugDB 0.15.2.
