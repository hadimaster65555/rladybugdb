#' Execute a Cypher query
#'
#' Sends a Cypher query string to LadybugDB and returns an `lb_result` object.
#' For DDL or DML statements (CREATE TABLE, CREATE, MERGE, …) the result
#' contains metadata; for MATCH/RETURN it contains rows.
#'
#' @param conn An `lb_connection` object from [lb_connection()].
#' @param query A single character string containing a Cypher query.
#' @param parameters A named list of query parameters for parameterised queries.
#'   `NULL` (default) means no parameters.
#'
#' @return An object of class `lb_result`.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
#' lb_execute(conn, "CREATE (:Person {name: $name})",
#'            parameters = list(name = "Alice"))
#' }
#'
#' @export
lb_execute <- function(conn, query, parameters = NULL) {
  .lb_check_conn(conn)

  if (!is.character(query) || length(query) != 1L) {
    rlang::abort("`query` must be a single character string.",
                 class = "rladybugdb_error_invalid_arg")
  }

  ptr <- if (is.null(parameters)) {
    .lb_handle_error(lb_connection_execute(conn$ptr, query))
  } else {
    if (!is.list(parameters)) {
      rlang::abort("`parameters` must be a named list or NULL.",
                   class = "rladybugdb_error_invalid_arg")
    }
    .lb_handle_error(lb_connection_execute_params(conn$ptr, query, parameters))
  }

  new_lb_result(ptr, conn = conn, query = query)
}

#' Execute a Cypher query and return a data frame
#'
#' Convenience wrapper around [lb_execute()] that immediately converts the
#' result to an R `data.frame`. Equivalent to
#' `as.data.frame(lb_execute(conn, query, ...))`.
#'
#' @inheritParams lb_execute
#' @param ... Passed to [as.data.frame.lb_result()].
#'
#' @return A `data.frame`.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))")
#' lb_execute(conn, "CREATE (:Person {name: 'Alice', age: 30})")
#' df <- lb_query(conn, "MATCH (p:Person) RETURN p.name, p.age")
#' }
#'
#' @export
lb_query <- function(conn, query, parameters = NULL, ...) {
  result <- lb_execute(conn, query, parameters = parameters)
  as.data.frame(result, ...)
}
