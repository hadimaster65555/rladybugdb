# Close a LadybugDB connection or database

Releases resources held by an `lb_connection` or `lb_database` object.
After calling `lb_close()`, the object should not be used.

## Usage

``` r
lb_close(x, ...)
```

## Arguments

- x:

  An `lb_connection` or `lb_database` object.

- ...:

  Unused; included for S3 generics compatibility.

## Value

Invisible `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
db   <- lb_database(":memory:")
conn <- lb_connection(db)
lb_close(conn)
lb_close(db)
} # }
```
