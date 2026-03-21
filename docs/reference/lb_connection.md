# Open a connection to a LadybugDB database

Open a connection to a LadybugDB database

## Usage

``` r
lb_connection(database, num_threads = NULL)
```

## Arguments

- database:

  An `lb_database` object created by
  [`lb_database()`](https://rladybugdb.github.io/rladybugdb/reference/lb_database.md).

- num_threads:

  Integer. Number of threads LadybugDB may use. `NULL` leaves the
  default (typically all available cores).

## Value

An object of class `lb_connection`.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
} # }
```
