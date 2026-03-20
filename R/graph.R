#' Convert an lb_result to an igraph object
#'
#' Extracts node and relationship columns from a LadybugDB query result and
#' constructs an [igraph::graph_from_data_frame()] object.
#'
#' Node columns must have LadybugDB type `NODE` and relationship columns type
#' `REL`/`RELATIONSHIP`. When the result contains no structural columns the
#' function aborts with an informative error.
#'
#' @param x An `lb_result` object.
#' @param ... Unused; kept for S3 compatibility.
#'
#' @return An [igraph::igraph] object.
#'
#' @examples
#' \dontrun{
#' db   <- lb_database(":memory:")
#' conn <- lb_connection(db)
#' lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
#' lb_execute(conn, "CREATE REL TABLE Knows (FROM Person TO Person)")
#' lb_execute(conn, "CREATE (:Person {name:'A'})-[:Knows]->(:Person {name:'B'})")
#' result <- lb_execute(conn, "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a, r, b")
#' g <- as_igraph(result)
#' }
#'
#' @export
as_igraph <- function(x, ...) {
  UseMethod("as_igraph")
}

#' @export
as_igraph.lb_result <- function(x, ...) {
  if (!requireNamespace("igraph", quietly = TRUE)) {
    rlang::abort(
      "Package `igraph` is required. Install it with `install.packages('igraph')`.",
      class = "rladybugdb_error_missing_pkg"
    )
  }

  df <- as.data.frame(x)
  .build_igraph(df)
}

#' Convert an lb_result to a tbl_graph (tidygraph)
#'
#' @param x An `lb_result` object.
#' @param ... Unused.
#'
#' @return A [tidygraph::tbl_graph()] object.
#'
#' @export
as_tbl_graph <- function(x, ...) {
  UseMethod("as_tbl_graph")
}

#' @export
as_tbl_graph.lb_result <- function(x, ...) {
  if (!requireNamespace("tidygraph", quietly = TRUE)) {
    rlang::abort(
      "Package `tidygraph` is required. Install it with `install.packages('tidygraph')`.",
      class = "rladybugdb_error_missing_pkg"
    )
  }
  g <- as_igraph(x, ...)
  tidygraph::as_tbl_graph(g)
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

#' Build an igraph from a data frame with node/rel list-columns
#'
#' Heuristic: columns whose values are named lists containing `_id` /
#' `_label` / `properties` are NODE columns; those containing `_src` / `_dst`
#' are REL columns.
#'
#' @keywords internal
.build_igraph <- function(df) {
  nodes_list <- list()
  edges_list <- list()

  for (col in names(df)) {
    vals <- df[[col]]
    if (!is.list(vals)) next

    first <- vals[[1L]]
    if (is.null(first)) next

    if (.is_node_val(first)) {
      nodes_list[[col]] <- .extract_nodes(vals, col)
    } else if (.is_rel_val(first)) {
      edges_list[[col]] <- .extract_rels(vals, col)
    }
  }

  if (length(edges_list) == 0L && length(nodes_list) == 0L) {
    rlang::abort(
      c(
        "No NODE or REL columns found in the query result.",
        i = "Return node/relationship variables in your MATCH clause, e.g. RETURN a, r, b"
      ),
      class = "rladybugdb_error_no_graph_cols"
    )
  }

  # Combine all node data frames, deduplicate by internal id
  if (length(nodes_list) > 0L) {
    all_nodes <- .rbind_fill(nodes_list)
    all_nodes <- all_nodes[!duplicated(all_nodes[["_ID"]]), , drop = FALSE]
  } else {
    all_nodes <- data.frame(`_ID` = character(0), check.names = FALSE)
  }

  if (length(edges_list) > 0L) {
    all_edges <- .rbind_fill(edges_list)
  } else {
    all_edges <- data.frame(from = character(0), to = character(0),
                            check.names = FALSE)
  }

  igraph::graph_from_data_frame(
    d        = all_edges,
    vertices = all_nodes,
    directed = TRUE
  )
}

# LadybugDB C layer returns node lists with uppercase keys: _ID, _LABEL
# and rel lists with: _SRC, _DST, _LABEL, _ID
# Properties are at the top level (not nested under "properties")

.is_node_val <- function(v) {
  is.list(v) && "_ID" %in% names(v) && "_LABEL" %in% names(v) && !"_SRC" %in% names(v)
}

.is_rel_val <- function(v) {
  is.list(v) && all(c("_SRC", "_DST") %in% names(v))
}

.extract_nodes <- function(vals, col_name) {
  rows <- lapply(vals, function(v) {
    # Properties are all keys that don't start with "_"
    prop_keys <- names(v)[!startsWith(names(v), "_")]
    props <- v[prop_keys]
    c(list(`_ID` = .node_id(v), `_LABEL` = v[["_LABEL"]]), props)
  })
  .rows_to_df(rows)
}

.extract_rels <- function(vals, col_name) {
  rows <- lapply(vals, function(v) {
    prop_keys <- names(v)[!startsWith(names(v), "_")]
    props <- v[prop_keys]
    c(list(from     = .node_id_from_ref(v[["_SRC"]]),
           to       = .node_id_from_ref(v[["_DST"]]),
           `_LABEL` = v[["_LABEL"]]), props)
  })
  .rows_to_df(rows)
}

.node_id <- function(v) {
  id <- v[["_ID"]]
  if (is.list(id)) {
    paste0(id[["table"]], ":", id[["offset"]])
  } else {
    as.character(id)
  }
}

.node_id_from_ref <- function(ref) {
  if (is.list(ref)) {
    paste0(ref[["table"]], ":", ref[["offset"]])
  } else {
    as.character(ref)
  }
}

# rbind a list of data frames that may have different columns (fills with NA)
.rbind_fill <- function(dfs) {
  all_cols <- unique(unlist(lapply(dfs, names)))
  dfs_aligned <- lapply(dfs, function(df) {
    missing <- setdiff(all_cols, names(df))
    for (col in missing) df[[col]] <- NA
    df[, all_cols, drop = FALSE]
  })
  do.call(rbind, dfs_aligned)
}

#' @importFrom stats setNames
.rows_to_df <- function(rows) {
  all_keys <- unique(unlist(lapply(rows, names)))
  out <- lapply(rows, function(r) {
    lapply(all_keys, function(k) {
      v <- r[[k]]
      if (is.null(v)) NA else v
    })
  })
  df <- as.data.frame(
    do.call(rbind, lapply(out, function(r) {
      setNames(as.data.frame(r, stringsAsFactors = FALSE), all_keys)
    })),
    stringsAsFactors = FALSE
  )
  df
}
