test_that("as_igraph.lb_result() errors without igraph installed (mocked)", {
  result <- structure(
    list(ptr = NULL, conn = NULL, query = NULL,
         col_names = character(0), col_types = character(0)),
    class = "lb_result"
  )
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) if (pkg == "igraph") FALSE else TRUE,
    .package = "base"
  )
  expect_error(as_igraph(result), class = "rladybugdb_error_missing_pkg")
})

test_that("as_igraph.lb_result() builds graph from node/rel columns", {
  skip_if_not(requireNamespace("igraph", quietly = TRUE), "igraph not available")
  conn <- make_test_conn()
  lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
  lb_execute(conn, "CREATE REL TABLE Knows (FROM Person TO Person, since INT64)")
  lb_execute(conn, "CREATE (:Person {name: 'Alice'})")
  lb_execute(conn, "CREATE (:Person {name: 'Bob'})")
  lb_execute(conn,
    "MATCH (a:Person {name:'Alice'}), (b:Person {name:'Bob'}) CREATE (a)-[:Knows {since: 2020}]->(b)")
  result <- lb_execute(conn,
    "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a, r, b")
  g <- as_igraph(result)
  expect_true(igraph::is_igraph(g))
  expect_equal(igraph::vcount(g), 2L)
  expect_equal(igraph::ecount(g), 1L)
})

test_that("as_igraph.lb_result() errors when no graph columns present", {
  skip_if_not(requireNamespace("igraph", quietly = TRUE), "igraph not available")
  conn <- make_test_conn()
  lb_execute(conn, "CREATE NODE TABLE T (x INT64, PRIMARY KEY(x))")
  lb_execute(conn, "CREATE (:T {x: 1})")
  result <- lb_execute(conn, "MATCH (t:T) RETURN t.x AS x")
  expect_error(as_igraph(result), class = "rladybugdb_error_no_graph_cols")
})

test_that("as_tbl_graph.lb_result() builds tbl_graph from node/rel columns", {
  skip_if_not(requireNamespace("igraph",    quietly = TRUE), "igraph not available")
  skip_if_not(requireNamespace("tidygraph", quietly = TRUE), "tidygraph not available")
  conn <- make_test_conn()
  lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
  lb_execute(conn, "CREATE REL TABLE Knows (FROM Person TO Person)")
  lb_execute(conn, "CREATE (:Person {name: 'X'})")
  lb_execute(conn, "CREATE (:Person {name: 'Y'})")
  lb_execute(conn,
    "MATCH (a:Person {name:'X'}), (b:Person {name:'Y'}) CREATE (a)-[:Knows]->(b)")
  result <- lb_execute(conn,
    "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a, r, b")
  tg <- as_tbl_graph(result)
  expect_s3_class(tg, "tbl_graph")
})
