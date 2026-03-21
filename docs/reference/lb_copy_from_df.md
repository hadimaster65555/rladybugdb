# Load an R data frame into a LadybugDB table via CSV

Writes `df` to a temporary CSV file and executes a `COPY` statement to
load it into `table`. The table must already exist in the database.

## Usage

``` r
lb_copy_from_df(conn, df, table)
```

## Arguments

- conn:

  An `lb_connection` object.

- df:

  A `data.frame` (or tibble) to load.

- table:

  Character. The name of the target node or relationship table.

## Value

Invisible `NULL`. Called for its side effect.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
lb_execute(conn, "CREATE NODE TABLE Person (name STRING, age INT64, PRIMARY KEY(name))")
people <- data.frame(name = c("Alice", "Bob"), age = c(30L, 25L))
lb_copy_from_df(conn, people, "Person")
} # }
```
