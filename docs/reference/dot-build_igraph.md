# Build an igraph from a data frame with node/rel list-columns

Heuristic: columns whose values are named lists containing `_id` /
`_label` / `properties` are NODE columns; those containing `_src` /
`_dst` are REL columns.

## Usage

``` r
.build_igraph(df)
```
