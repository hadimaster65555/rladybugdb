#' Convert an lb_result to a data frame
#'
#' Retrieves all rows from a LadybugDB query result as an R `data.frame`.
#' Conversion is done natively via the Rcpp layer — no Python required.
#'
#' @param x An `lb_result` object.
#' @param ... Unused; kept for S3 compatibility.
#'
#' @return A `data.frame`.
#'
#' @export
as.data.frame.lb_result <- function(x, ...) {
  raw <- .lb_handle_error(lb_result_fetch_all(x$ptr))
  # List columns (LIST, ARRAY, NODE, REL, STRUCT, MAP) must be wrapped with I()
  # to prevent as.data.frame() from expanding them into multiple columns.
  for (i in seq_along(raw)) {
    if (is.list(raw[[i]])) raw[[i]] <- I(raw[[i]])
  }
  as.data.frame(raw, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Convert an lb_result to an Arrow Table
#'
#' @param x An `lb_result` object.
#' @param ... Unused.
#'
#' @return An [arrow::Table][arrow::Table-class] object.
#'
#' @export
as_arrow_table <- function(x, ...) {
  UseMethod("as_arrow_table")
}

#' @export
as_arrow_table.lb_result <- function(x, ...) {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    rlang::abort(
      "Package `arrow` is required. Install it with `install.packages('arrow')`.",
      class = "rladybugdb_error_missing_pkg"
    )
  }
  arrow::as_arrow_table(as.data.frame(x))
}

#' Convert an lb_result to a tibble
#'
#' @param x An `lb_result` object.
#' @param ... Passed to [as.data.frame.lb_result()].
#'
#' @return A [tibble::tibble()].
#'
#' @export
as_tibble.lb_result <- function(x, ...) {
  if (!requireNamespace("tibble", quietly = TRUE)) {
    rlang::abort(
      "Package `tibble` is required. Install it with `install.packages('tibble')`.",
      class = "rladybugdb_error_missing_pkg"
    )
  }
  tibble::as_tibble(as.data.frame(x, ...))
}
