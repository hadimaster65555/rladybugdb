#' LadybugDB query result
#'
#' `lb_result` is an S3 class wrapping a native LadybugDB `QueryResult` handle.
#' Use [as.data.frame()], [as_tibble()][tibble::as_tibble()], or
#' [as_arrow_table()] to extract results.
#'
#' @param ptr An external pointer (`SEXP`) to the underlying C query result.
#' @param conn The `lb_connection` that produced this result (kept alive to
#'   prevent GC ordering issues).
#' @param query The Cypher query string (stored for informational purposes).
#'
#' @return An object of class `lb_result`.
#' @keywords internal
new_lb_result <- function(ptr, conn = NULL, query = NULL) {
  # Eagerly fetch column metadata so print() is cheap and doesn't re-execute.
  col_names <- tryCatch(lb_result_column_names(ptr), error = function(e) character(0))
  col_types <- tryCatch(lb_result_column_types(ptr), error = function(e) character(0))

  structure(
    list(
      ptr       = ptr,
      conn      = conn,
      query     = query,
      col_names = col_names,
      col_types = col_types
    ),
    class = "lb_result"
  )
}

#' @export
print.lb_result <- function(x, ...) {
  nc <- length(x$col_names)
  if (nc == 0L) {
    cat("<lb_result> (no columns)\n")
    return(invisible(x))
  }

  df <- tryCatch(as.data.frame(x), error = function(e) NULL)
  if (is.null(df)) {
    cat(sprintf("<lb_result> [? x %d] columns: %s\n",
                nc, paste(x$col_names, collapse = ", ")))
  } else {
    cat(sprintf("<lb_result> [%d x %d]\n", nrow(df), ncol(df)))
    print(df, ...)
  }
  invisible(x)
}

#' @importFrom utils capture.output
#' @export
format.lb_result <- function(x, ...) {
  df <- tryCatch(as.data.frame(x), error = function(e) NULL)
  if (is.null(df)) {
    "<lb_result>"
  } else {
    paste0(
      sprintf("<lb_result> [%d x %d]\n", nrow(df), ncol(df)),
      paste(capture.output(print(df)), collapse = "\n")
    )
  }
}
