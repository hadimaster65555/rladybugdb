#' Load an R data frame into a LadybugDB table via CSV
#'
#' Writes `df` to a temporary CSV file and executes a `COPY` statement to load
#' it into `table`. The table must already exist in the database.
#'
#' @param conn An `lb_connection` object.
#' @param df A `data.frame` (or tibble) to load.
#' @param table Character. The name of the target node or relationship table.
#'
#' @return Invisible `NULL`. Called for its side effect.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))")
#' people <- data.frame(name = c("Alice", "Bob"), age = c(30L, 25L))
#' lb_copy_from_df(conn, people, "Person")
#' }
#'
#' @importFrom utils write.csv
#' @export
lb_copy_from_df <- function(conn, df, table) {
  .lb_check_conn(conn)

  if (!is.data.frame(df)) {
    rlang::abort("`df` must be a data.frame.", class = "rladybugdb_error_invalid_arg")
  }
  if (!is.character(table) || length(table) != 1L) {
    rlang::abort("`table` must be a single character string.",
                 class = "rladybugdb_error_invalid_arg")
  }

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  utils::write.csv(df, tmp, row.names = FALSE, na = "")

  lb_copy_from_csv(conn, tmp, table)
}

#' Load a CSV file into a LadybugDB table
#'
#' Executes `COPY <table> FROM '<path>'` using LadybugDB's built-in CSV loader.
#' The table must already exist.
#'
#' @param conn An `lb_connection` object.
#' @param path Character. Absolute path to a CSV file. The file must be
#'   accessible from the process running LadybugDB.
#' @param table Character. The name of the target node or relationship table.
#' @param header Logical. Does the CSV file have a header row? Default `TRUE`.
#' @param delim Character. Field delimiter. Default `","`.
#'
#' @return An `lb_result` (the result of the COPY statement).
#'
#' @examples
#' \dontrun{
#' lb_copy_from_csv(conn, "/data/people.csv", "Person")
#' }
#'
#' @export
lb_copy_from_csv <- function(conn, path, table, header = TRUE, delim = ",") {
  .lb_check_conn(conn)

  if (!is.character(path) || length(path) != 1L) {
    rlang::abort("`path` must be a single character string.",
                 class = "rladybugdb_error_invalid_arg")
  }

  # Build COPY query with options
  options <- character(0)
  if (!header) options <- c(options, "header=false")
  if (!identical(delim, ",")) {
    options <- c(options, sprintf("delim='%s'", delim))
  }

  opts_str <- if (length(options)) {
    paste0(" (", paste(options, collapse = ", "), ")")
  } else {
    ""
  }

  query <- sprintf("COPY %s FROM '%s'%s", table, path, opts_str)
  lb_execute(conn, query)
}
