# Convert an lb_result to an igraph object

Extracts node and relationship columns from a LadybugDB query result and
constructs an
[`igraph::graph_from_data_frame()`](https://r.igraph.org/reference/graph_from_data_frame.html)
object.

## Usage

``` r
as_igraph(x, ...)
```

## Arguments

- x:

  An `lb_result` object.

- ...:

  Unused; kept for S3 compatibility.

## Value

An igraph::igraph object.

## Details

Node columns must have LadybugDB type `NODE` and relationship columns
type `REL`/`RELATIONSHIP`. When the result contains no structural
columns the function aborts with an informative error.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
lb_execute(conn, "CREATE REL TABLE Knows (FROM Person TO Person)")
lb_execute(conn, "CREATE (:Person {name:'A'})-[:Knows]->(:Person {name:'B'})")
result <- lb_execute(conn, "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a, r, b")
g <- as_igraph(result)
} # }
```
