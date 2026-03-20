#' Open a LadybugDB database
#'
#' Creates (or opens) a LadybugDB database at the given path. Use
#' `":memory:"` for an in-memory database.
#'
#' @param path File-system path to the database directory, or `":memory:"` for
#'   an ephemeral in-memory database.
#' @param read_only Logical. Open the database in read-only mode? Default
#'   `FALSE`.
#'
#' @return An object of class `lb_database`.
#'
#' @examples
#' \dontrun{
#' db <- lb_database(":memory:")
#' }
#'
#' @export
lb_database <- function(path = ":memory:", read_only = FALSE) {
  if (!is.character(path) || length(path) != 1L) {
    rlang::abort("`path` must be a single character string.",
                 class = "rladybugdb_error_invalid_arg")
  }

  ptr <- .lb_handle_error(
    lb_database_open(path, isTRUE(read_only))
  )

  structure(
    list(ptr = ptr, path = path, read_only = isTRUE(read_only)),
    class = "lb_database"
  )
}

#' @export
print.lb_database <- function(x, ...) {
  cat(sprintf("<lb_database> path=%s read_only=%s\n", x$path, x$read_only))
  invisible(x)
}

#' Open a connection to a LadybugDB database
#'
#' @param database An `lb_database` object created by [lb_database()].
#' @param num_threads Integer. Number of threads LadybugDB may use. `NULL`
#'   leaves the default (typically all available cores).
#'
#' @return An object of class `lb_connection`.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' }
#'
#' @export
lb_connection <- function(database, num_threads = NULL) {
  if (!inherits(database, "lb_database")) {
    rlang::abort("`database` must be an `lb_database` object.",
                 class = "rladybugdb_error_invalid_arg")
  }

  n <- if (is.null(num_threads)) 0L else as.integer(num_threads)
  ptr <- .lb_handle_error(lb_connection_create(database$ptr, n))

  structure(
    list(ptr = ptr, database = database),
    class = "lb_connection"
  )
}

#' @export
print.lb_connection <- function(x, ...) {
  cat(sprintf("<lb_connection> db=%s\n", x$database$path))
  invisible(x)
}

#' Close a LadybugDB connection or database
#'
#' Releases resources held by an `lb_connection` or `lb_database` object.
#' After calling `lb_close()`, the object should not be used.
#'
#' @param x An `lb_connection` or `lb_database` object.
#' @param ... Unused; included for S3 generics compatibility.
#'
#' @return Invisible `NULL`.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' lb_close(conn)
#' lb_close(db)
#' }
#'
#' @export
lb_close <- function(x, ...) {
  UseMethod("lb_close")
}

#' @export
lb_close.lb_connection <- function(x, ...) {
  tryCatch(
    lb_connection_close(x$ptr),
    error = function(e) invisible(NULL)
  )
  invisible(NULL)
}

#' @export
lb_close.lb_database <- function(x, ...) {
  tryCatch(
    lb_database_close(x$ptr),
    error = function(e) invisible(NULL)
  )
  invisible(NULL)
}
