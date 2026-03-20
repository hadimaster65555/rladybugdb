#' Assert that an object is an lb_connection
#'
#' @param conn Object to check.
#' @keywords internal
.lb_check_conn <- function(conn) {
  if (!inherits(conn, "lb_connection")) {
    rlang::abort(
      "`conn` must be an `lb_connection` object created by `lb_connection()`.",
      class = "rladybugdb_error_invalid_conn"
    )
  }
  invisible(conn)
}

#' Handle C++ exceptions from LadybugDB
#'
#' Wraps a call expression, catches any condition thrown by the Rcpp layer,
#' and re-throws as a typed R error with class `rladybugdb_error_query`.
#'
#' @param expr Expression to evaluate.
#' @keywords internal
.lb_handle_error <- function(expr) {
  tryCatch(
    expr,
    error = function(e) {
      rlang::abort(
        conditionMessage(e),
        class = c("rladybugdb_error_query", "rladybugdb_error"),
        parent = e
      )
    }
  )
}
