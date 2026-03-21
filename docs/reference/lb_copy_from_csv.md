# Load a CSV file into a LadybugDB table

Executes `COPY <table> FROM '<path>'` using LadybugDB's built-in CSV
loader. The table must already exist.

## Usage

``` r
lb_copy_from_csv(conn, path, table, header = TRUE, delim = ",")
```

## Arguments

- conn:

  An `lb_connection` object.

- path:

  Character. Absolute path to a CSV file. The file must be accessible
  from the process running LadybugDB.

- table:

  Character. The name of the target node or relationship table.

- header:

  Logical. Does the CSV file have a header row? Default `TRUE`.

- delim:

  Character. Field delimiter. Default `","`.

## Value

An `lb_result` (the result of the COPY statement).

## Examples

``` r
if (FALSE) { # \dontrun{
lb_copy_from_csv(conn, "/data/people.csv", "Person")
} # }
```
