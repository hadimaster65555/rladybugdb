# Open a LadybugDB database

Creates (or opens) a LadybugDB database at the given path. Use
`":memory:"` for an in-memory database.

## Usage

``` r
lb_database(path = ":memory:", read_only = FALSE)
```

## Arguments

- path:

  File-system path to the database directory, or `":memory:"` for an
  ephemeral in-memory database.

- read_only:

  Logical. Open the database in read-only mode? Default `FALSE`.

## Value

An object of class `lb_database` (an opaque wrapper around the
underlying Python `Database` object).

## Examples

``` r
if (FALSE) { # \dontrun{
db <- lb_database(":memory:")
} # }
```
