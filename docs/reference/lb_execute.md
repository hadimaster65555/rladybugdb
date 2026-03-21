# Execute a Cypher query

Sends a Cypher query string to LadybugDB and returns an `lb_result`
object. For DDL or DML statements (CREATE TABLE, CREATE, MERGE, …) the
result contains metadata; for MATCH/RETURN it contains rows.

## Usage

``` r
lb_execute(conn, query, parameters = NULL)
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

## Value

An object of class `lb_result`.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
lb_execute(conn, "CREATE NODE TABLE Person (name STRING, PRIMARY KEY(name))")
lb_execute(conn, "CREATE (:Person {name: $name})",
           parameters = list(name = "Alice"))
} # }
```
