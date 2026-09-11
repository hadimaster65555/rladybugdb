#' Install the LadybugDB C library (deprecated)
#'
#' This function is deprecated. The C library is now bundled with the package
#' and no Python installation is required.
#'
#' @param ... Ignored.
#'
#' @return Invisible `NULL`.
#'
#' @examples
#' \dontrun{
#' ladybugdb_install()  # no longer needed
#' }
#'
#' @export
ladybugdb_install <- function(...) {
  .Deprecated(
    msg = paste0(
      "`ladybugdb_install()` is deprecated.\n",
      "The C library is now bundled; no Python installation is required."
    )
  )
  invisible(NULL)
}

#' Check whether LadybugDB is available
#'
#' Returns `TRUE` if the native LadybugDB C library is loaded and functional.
#'
#' @return `TRUE` or `FALSE`.
#'
#' @examples
#' ladybugdb_is_installed()
#'
#' @export
ladybugdb_is_installed <- function() {
  tryCatch({
    lb_database_version()
    TRUE
  }, error = function(e) FALSE)
}

#' Return the LadybugDB C library version string
#'
#' @return A character string, e.g. `"0.20.4"`.
#'
#' @examples
#' ladybugdb_version()
#'
#' @export
ladybugdb_version <- function() {
  lb_database_version()
}
