# Convert an lb_result to a data frame

Retrieves all rows from a LadybugDB query result as an R `data.frame`.
When the `arrow` package is available the conversion goes through the
Arrow IPC pathway (zero-copy for numeric types); otherwise pandas is
used.

## Usage

``` r
# S3 method for class 'lb_result'
as.data.frame(x, ..., use_arrow = TRUE)
```

## Arguments

- x:

  An `lb_result` object.

- ...:

  Unused; kept for S3 compatibility.

- use_arrow:

  Logical. Attempt the Arrow pathway when the `arrow` package is
  installed? Default `TRUE`.

## Value

A `data.frame`.
