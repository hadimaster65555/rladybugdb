# LadybugDB query result

`lb_result` is an S3 class wrapping a LadybugDB `QueryResult` Python
object. Use
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html),
[as_tibble()](https://tibble.tidyverse.org/reference/as_tibble.html), or
[`as_arrow_table()`](https://rladybugdb.github.io/rladybugdb/reference/as_arrow_table.md)
to extract results.

## Usage

``` r
new_lb_result(py_result, query = NULL)
```

## Arguments

- py_result:

  A Python `QueryResult` object returned by `Connection$execute()`.

- query:

  The Cypher query string (stored for informational purposes).

## Value

An object of class `lb_result`.
