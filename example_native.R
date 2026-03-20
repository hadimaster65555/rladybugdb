# example_native.R — end-to-end test of the native Rcpp implementation
# No Python, no reticulate. Requires the package to be compiled first:
#   Rscript tools/vendor.R          # download lbug C library
#   R CMD INSTALL .                  # compile and install
# OR in development:
#   devtools::load_all(".")          # requires src/vendor/ already populated

library(rladybugdb)

cat("rladybugdb", as.character(packageVersion("rladybugdb")), "— native Rcpp test\n")
cat("LadybugDB C library version:", ladybugdb_version(), "\n\n")

# ── Helper ──────────────────────────────────────────────────────────────────
ok <- function(label) cat(sprintf("  [OK] %s\n", label))
fail <- function(label, msg) stop(sprintf("FAIL: %s — %s", label, msg))

check <- function(label, expr) {
  result <- tryCatch(expr, error = function(e) e)
  if (inherits(result, "error")) fail(label, conditionMessage(result))
  ok(label)
  invisible(result)
}

assert_equal <- function(a, b, label) {
  if (!identical(a, b)) {
    fail(label, sprintf("expected %s got %s",
                        deparse(b, nlines = 1), deparse(a, nlines = 1)))
  }
  ok(label)
}

# ── 1. Open in-memory database ───────────────────────────────────────────────
cat("1. Database + connection\n")
db   <- check("lb_database() returns lb_database", {
  d <- lb_database(":memory:")
  stopifnot(inherits(d, "lb_database"), d$path == ":memory:")
  d
})
conn <- check("lb_connection() returns lb_connection", {
  c <- lb_connection(db)
  stopifnot(inherits(c, "lb_connection"))
  c
})
check("print methods work", {
  capture.output(print(db))
  capture.output(print(conn))
})

# ── 2. DDL ───────────────────────────────────────────────────────────────────
cat("\n2. Schema creation (DDL)\n")
check("CREATE NODE TABLE Person", {
  invisible(lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))"))
})
check("CREATE NODE TABLE City", {
  invisible(lb_execute(conn, "CREATE NODE TABLE City (name STRING, country STRING, PRIMARY KEY(name))"))
})
check("CREATE REL TABLE LivesIn", {
  invisible(lb_execute(conn, "CREATE REL TABLE LivesIn (FROM Person TO City, since INT64)"))
})

# ── 3. INSERT ────────────────────────────────────────────────────────────────
cat("\n3. Data insertion\n")
check("INSERT persons", {
  invisible(lb_execute(conn, "CREATE (:Person {name: 'Alice', age: 30})"))
  invisible(lb_execute(conn, "CREATE (:Person {name: 'Bob',   age: 25})"))
  invisible(lb_execute(conn, "CREATE (:Person {name: 'Carol', age: 35})"))
})
check("INSERT cities", {
  invisible(lb_execute(conn, "CREATE (:City {name: 'London', country: 'UK'})"))
  invisible(lb_execute(conn, "CREATE (:City {name: 'Paris',  country: 'France'})"))
})
check("CREATE relationships", {
  invisible(lb_execute(conn,
    "MATCH (p:Person {name:'Alice'}), (c:City {name:'London'}) CREATE (p)-[:LivesIn {since:2018}]->(c)"))
  invisible(lb_execute(conn,
    "MATCH (p:Person {name:'Bob'}),   (c:City {name:'Paris'})  CREATE (p)-[:LivesIn {since:2021}]->(c)"))
})

# ── 4. Basic query → data.frame ──────────────────────────────────────────────
cat("\n4. Queries → data.frame\n")
df <- check("MATCH returns data.frame", {
  d <- lb_query(conn,
    "MATCH (p:Person) RETURN p.name AS name, p.age AS age ORDER BY p.name")
  stopifnot(is.data.frame(d), nrow(d) == 3L)
  d
})
cat("   Person table:\n")
print(df)

df_join <- check("JOIN query with 5 columns", {
  d <- lb_query(conn,
    "MATCH (p:Person)-[r:LivesIn]->(c:City)
     RETURN p.name AS person, p.age AS age,
            c.name AS city, c.country AS country, r.since AS since
     ORDER BY p.name")
  stopifnot(nrow(d) == 2L, ncol(d) == 5L)
  d
})
cat("   Join result:\n")
print(df_join)

# ── 5. Type assertions ───────────────────────────────────────────────────────
cat("\n5. Type mapping\n")
check("INT64 → numeric", {
  d <- lb_query(conn, "MATCH (p:Person {name:'Alice'}) RETURN p.age AS age")
  stopifnot(is.numeric(d$age), d$age == 30)
})
check("STRING → character", {
  d <- lb_query(conn, "MATCH (p:Person {name:'Alice'}) RETURN p.name AS name")
  stopifnot(is.character(d$name), d$name == "Alice")
})

invisible(lb_execute(conn, "CREATE NODE TABLE Typed (
  id     INT64,
  f      FLOAT,
  d      DOUBLE,
  b      BOOLEAN,
  dt     DATE,
  ts     TIMESTAMP,
  s      STRING,
  PRIMARY KEY(id)
)"))
invisible(lb_execute(conn, "CREATE (:Typed {
  id: 1,
  f:  1.5,
  d:  2.718281828,
  b:  true,
  dt: date('2024-06-01'),
  ts: timestamp('2024-06-01T12:00:00'),
  s:  'hello'
})"))
typed <- lb_query(conn, "MATCH (t:Typed) RETURN t.f AS f, t.d AS d, t.b AS b,
                                                 t.dt AS dt, t.ts AS ts, t.s AS s")
check("FLOAT/DOUBLE → numeric", stopifnot(is.numeric(typed$f), is.numeric(typed$d)))
check("BOOL → logical",         stopifnot(is.logical(typed$b), isTRUE(typed$b)))
check("DATE → Date class",      stopifnot(inherits(typed$dt, "Date"),
                                          format(typed$dt) == "2024-06-01"))
check("TIMESTAMP → POSIXct",    stopifnot(inherits(typed$ts, "POSIXct")))
check("STRING → character",     stopifnot(typed$s == "hello"))

# NULL → NA
invisible(lb_execute(conn, "CREATE NODE TABLE Nullable (id INT64, v STRING, PRIMARY KEY(id))"))
invisible(lb_execute(conn, "CREATE (:Nullable {id: 1, v: 'present'})"))
invisible(lb_execute(conn, "CREATE (:Nullable {id: 2})"))
null_df <- lb_query(conn, "MATCH (n:Nullable) RETURN n.v AS v ORDER BY n.id")
check("NULL → NA", stopifnot(is.na(null_df$v[2])))

# INT32 → integer
invisible(lb_execute(conn, "CREATE NODE TABLE TInt32 (v INT32, PRIMARY KEY(v))"))
invisible(lb_execute(conn, "CREATE (:TInt32 {v: 42})"))
i32_df <- lb_query(conn, "MATCH (x:TInt32) RETURN x.v AS v")
check("INT32 → integer", stopifnot(is.integer(i32_df$v), i32_df$v == 42L))

# LIST column
invisible(lb_execute(conn, "CREATE NODE TABLE TList (id INT64, tags STRING[], PRIMARY KEY(id))"))
invisible(lb_execute(conn, "CREATE (:TList {id: 1, tags: ['r', 'graph', 'db']})"))
list_df <- lb_query(conn, "MATCH (x:TList) RETURN x.tags AS tags")
check("LIST → list column", stopifnot(is.list(list_df$tags), length(list_df$tags[[1]]) == 3L))

# ── 6. Parameterised queries ─────────────────────────────────────────────────
cat("\n6. Parameterised queries\n")
check("STRING param", {
  d <- lb_query(conn,
    "MATCH (p:Person) WHERE p.name = $n RETURN p.name AS name",
    parameters = list(n = "Alice"))
  stopifnot(nrow(d) == 1L, d$name == "Alice")
})
check("INTEGER param", {
  d <- lb_query(conn,
    "MATCH (p:Person) WHERE p.age > $min RETURN p.name AS name ORDER BY p.name",
    parameters = list(min = 28L))
  stopifnot(nrow(d) == 2L)
})
check("DOUBLE param", {
  d <- lb_query(conn,
    "MATCH (t:Typed) WHERE t.d > $threshold RETURN t.s AS s",
    parameters = list(threshold = 2.0))
  stopifnot(nrow(d) == 1L)
})

# ── 7. Bulk load from data.frame ─────────────────────────────────────────────
cat("\n7. Bulk load (lb_copy_from_df)\n")
more_people <- data.frame(
  name = c("Dave", "Eve"),
  age  = c(28L, 32L),
  stringsAsFactors = FALSE
)
check("lb_copy_from_df inserts rows", {
  invisible(lb_copy_from_df(conn, more_people, "Person"))
  d <- lb_query(conn, "MATCH (p:Person) RETURN count(p) AS n")
  stopifnot(d$n == 5L)
})

# ── 8. NODE and REL columns ───────────────────────────────────────────────────
cat("\n8. NODE / REL column structure\n")
check("NODE column has _ID and _LABEL", {
  d <- lb_query(conn, "MATCH (p:Person {name:'Alice'}) RETURN p")
  node <- d$p[[1]]
  stopifnot(
    is.list(node),
    "_ID"    %in% names(node),
    "_LABEL" %in% names(node),
    node[["_LABEL"]] == "Person"
  )
})
check("REL column has _SRC, _DST, _LABEL", {
  d <- lb_query(conn, "MATCH (p:Person)-[r:LivesIn]->(c:City) RETURN r LIMIT 1")
  rel <- d$r[[1]]
  stopifnot(
    is.list(rel),
    all(c("_SRC", "_DST", "_LABEL") %in% names(rel)),
    rel[["_LABEL"]] == "LivesIn"
  )
})

# ── 9. Graph conversion ───────────────────────────────────────────────────────
cat("\n9. Graph conversion\n")
if (requireNamespace("igraph", quietly = TRUE)) {
  g <- check("as_igraph() builds igraph", {
    result <- lb_execute(conn,
      "MATCH (p:Person)-[r:LivesIn]->(c:City) RETURN p, r, c")
    gr <- as_igraph(result)
    stopifnot(igraph::is_igraph(gr),
              igraph::vcount(gr) == 4L,   # 2 persons + 2 cities
              igraph::ecount(gr) == 2L)
    gr
  })
  cat(sprintf("   Vertices: %d  Edges: %d\n",
              igraph::vcount(g), igraph::ecount(g)))
} else {
  cat("   [SKIP] igraph not installed\n")
}

if (requireNamespace("igraph",    quietly = TRUE) &&
    requireNamespace("tidygraph", quietly = TRUE)) {
  check("as_tbl_graph() builds tbl_graph", {
    result <- lb_execute(conn,
      "MATCH (p:Person)-[r:LivesIn]->(c:City) RETURN p, r, c")
    tg <- as_tbl_graph(result)
    stopifnot(inherits(tg, "tbl_graph"))
  })
} else {
  cat("   [SKIP] tidygraph not installed\n")
}

# ── 10. Arrow / tibble output ─────────────────────────────────────────────────
cat("\n10. Optional output formats\n")
if (requireNamespace("arrow", quietly = TRUE)) {
  check("as_arrow_table() works", {
    result <- lb_execute(conn,
      "MATCH (p:Person) RETURN p.name AS name, p.age AS age")
    at <- as_arrow_table(result)
    stopifnot(inherits(at, "ArrowTabular") || inherits(at, "Table"),
              nrow(at) == 5L)
  })
} else {
  cat("   [SKIP] arrow not installed\n")
}
if (requireNamespace("tibble", quietly = TRUE)) {
  check("as_tibble() works", {
    result <- lb_execute(conn,
      "MATCH (p:Person) RETURN p.name AS name")
    tbl <- tibble::as_tibble(result)
    stopifnot(inherits(tbl, "tbl_df"))
  })
} else {
  cat("   [SKIP] tibble not installed\n")
}

# ── 11. Error handling ────────────────────────────────────────────────────────
cat("\n11. Error handling\n")
check("bad Cypher → rladybugdb_error_query", {
  err <- tryCatch(lb_execute(conn, "NOT VALID CYPHER"), error = function(e) e)
  stopifnot(inherits(err, "rladybugdb_error_query"))
})
check("bad path arg → rladybugdb_error_invalid_arg", {
  err <- tryCatch(lb_database(123), error = function(e) e)
  stopifnot(inherits(err, "rladybugdb_error_invalid_arg"))
})
check("ladybugdb_install() is deprecated (not an error)", {
  suppressWarnings(ladybugdb_install())
})
check("ladybugdb_is_installed() returns TRUE", {
  stopifnot(isTRUE(ladybugdb_is_installed()))
})

# ── 12. Cleanup ───────────────────────────────────────────────────────────────
cat("\n12. Cleanup\n")
check("lb_close(conn)", lb_close(conn))
check("lb_close(db)",   lb_close(db))

cat("\n── All checks passed. No Python involved. ──\n")
