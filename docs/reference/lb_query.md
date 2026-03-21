# Execute a Cypher query and return a data frame

Convenience wrapper around
[`lb_execute()`](https://rladybugdb.github.io/rladybugdb/reference/lb_execute.md)
that immediately converts the result to an R `data.frame`. Equivalent to
`as.data.frame(lb_execute(conn, query, ...))`.

## Usage

``` r
lb_query(conn, query, parameters = NULL, ...)
```

## Arguments

- conn:

  An `lb_connection` object from
  [`lb_connection()`](https://rladybugdb.github.io/rladybugdb/reference/lb_connection.md).

- query:

  A single character string containing a Cypher query.

- parameters:

  A named list of query parameters for parameterised queries. `NULL`
  (default) means no parameters.

- ...:

  Passed to
  [`as.data.frame.lb_result()`](https://rladybugdb.github.io/rladybugdb/reference/as.data.frame.lb_result.md).

## Value

A `data.frame`.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))")
lb_execute(conn, "CREATE (:Person {name: 'Alice', age: 30})")
df <- lb_query(conn, "MATCH (p:Person) RETURN p.name, p.age")
} # }
```
