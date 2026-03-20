# rladybugdb — simple usage example
# Prerequisites: pip install real_ladybug pandas

library(reticulate)
use_python(Sys.which("python3"), required = TRUE)

# Load the package (use devtools::install() for a proper install)
devtools::load_all(".", quiet = TRUE)

# ── 1. Open an in-memory database ──────────────────────────────────────────
db   <- lb_database(":memory:")
conn <- lb_connection(db)

# ── 2. Define a schema ─────────────────────────────────────────────────────
# Wrap DDL in invisible() to suppress auto-print in scripts
# (in interactive R these would show "Table X has been created")
invisible(lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))"))
invisible(lb_execute(conn, "CREATE NODE TABLE City   (name STRING, country STRING, PRIMARY KEY(name))"))
invisible(lb_execute(conn, "CREATE REL TABLE LivesIn (FROM Person TO City, since INT64)"))

# ── 3. Insert data ─────────────────────────────────────────────────────────
invisible(lb_execute(conn, "CREATE (:Person {name: 'Alice', age: 30})"))
invisible(lb_execute(conn, "CREATE (:Person {name: 'Bob',   age: 25})"))
invisible(lb_execute(conn, "CREATE (:City   {name: 'London', country: 'UK'})"))
invisible(lb_execute(conn, "CREATE (:City   {name: 'Paris',  country: 'France'})"))
invisible(lb_execute(conn, "MATCH (p:Person {name:'Alice'}), (c:City {name:'London'}) CREATE (p)-[:LivesIn {since:2018}]->(c)"))
invisible(lb_execute(conn, "MATCH (p:Person {name:'Bob'}),   (c:City {name:'Paris'})  CREATE (p)-[:LivesIn {since:2021}]->(c)"))

# ── 4. Query → data.frame ──────────────────────────────────────────────────
cat("--- Query result as data.frame ---\n")
df <- lb_query(conn, "
  MATCH (p:Person)-[r:LivesIn]->(c:City)
  RETURN p.name AS person, p.age AS age, c.name AS city, c.country AS country, r.since AS since
  ORDER BY p.name
")
print(df)

# ── 5. Bulk load from a data frame ────────────────────────────────────────
cat("\n--- After bulk loading 2 more people ---\n")
invisible(lb_copy_from_df(conn, data.frame(name = c("Carol","Dave"), age = c(35L,28L)), "Person"))
print(lb_query(conn, "MATCH (p:Person) RETURN p.name AS name, p.age AS age ORDER BY p.name"))

# ── 6. Parameterised query ─────────────────────────────────────────────────
cat("\n--- Parameterised query (age > 28) ---\n")
result <- lb_execute(conn,
  "MATCH (p:Person) WHERE p.age > $min_age RETURN p.name AS name, p.age AS age ORDER BY p.name",
  parameters = list(min_age = 28L)
)
print(as.data.frame(result))

# ── 7. Graph conversion (requires igraph) ──────────────────────────────────
if (requireNamespace("igraph", quietly = TRUE)) {
  cat("\n--- igraph conversion ---\n")
  g <- as_igraph(lb_execute(conn, "MATCH (p:Person)-[r:LivesIn]->(c:City) RETURN p, r, c"))
  cat(sprintf("Vertices: %d  Edges: %d\n", igraph::vcount(g), igraph::ecount(g)))
  print(igraph::E(g))
}

# ── 8. Cleanup ─────────────────────────────────────────────────────────────
lb_close(conn)
lb_close(db)
cat("\nDone.\n")
