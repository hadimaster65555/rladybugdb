# Changelog

## rladybugdb 0.2.0

### Breaking changes

- Python/reticulate backend removed.
  [`ladybugdb_install()`](https://rladybugdb.github.io/rladybugdb/reference/ladybugdb_install.md)
  is now deprecated and does nothing. Remove any calls to it from your
  scripts.

### New features

- **Native Rcpp C++ bindings** to the LadybugDB C library (`liblbug`
  v0.15.2). No Python runtime is required — the C library ships with the
  package.
- [`ladybugdb_version()`](https://rladybugdb.github.io/rladybugdb/reference/ladybugdb_version.md)
  returns the version of the bundled C library.
- Parameterised queries via the `parameters` list argument in
  [`lb_execute()`](https://rladybugdb.github.io/rladybugdb/reference/lb_execute.md)
  and
  [`lb_query()`](https://rladybugdb.github.io/rladybugdb/reference/lb_query.md).
  Use `$name` placeholders in Cypher to avoid injection bugs.
- [`as_arrow_table()`](https://rladybugdb.github.io/rladybugdb/reference/as_arrow_table.md)
  generic for zero-copy Arrow output from an `lb_result`.
- [`as_tbl_graph()`](https://rladybugdb.github.io/rladybugdb/reference/as_tbl_graph.md)
  converts query results directly to a
  [`tidygraph::tbl_graph`](https://tidygraph.data-imaginist.com/reference/tbl_graph.html).

### Improvements

- `LIST` / `ARRAY` columns are now returned as proper R list columns
  (one R list element per row) rather than collapsed strings.
- `DATE` columns map to `Date`; `TIMESTAMP` columns map to `POSIXct`;
  `INT64` values map to `double` (exact up to 2^53, covers all graph
  IDs).
- [`lb_copy_from_df()`](https://rladybugdb.github.io/rladybugdb/reference/lb_copy_from_df.md)
  and
  [`lb_copy_from_csv()`](https://rladybugdb.github.io/rladybugdb/reference/lb_copy_from_csv.md)
  use LadybugDB’s native bulk loader, which is orders of magnitude
  faster than row-by-row `CREATE`.
