# Package index

## Connect

Open databases and manage connections.

- [`lb_database()`](https://rladybugdb.github.io/rladybugdb/reference/lb_database.md)
  : Open a LadybugDB database
- [`lb_connection()`](https://rladybugdb.github.io/rladybugdb/reference/lb_connection.md)
  : Open a connection to a LadybugDB database
- [`lb_close()`](https://rladybugdb.github.io/rladybugdb/reference/lb_close.md)
  : Close a LadybugDB connection or database

## Query

Run Cypher queries against an open connection.

- [`lb_execute()`](https://rladybugdb.github.io/rladybugdb/reference/lb_execute.md)
  : Execute a Cypher query
- [`lb_query()`](https://rladybugdb.github.io/rladybugdb/reference/lb_query.md)
  : Execute a Cypher query and return a data frame

## Load data

Bulk-load R data frames or CSV files into LadybugDB tables.

- [`lb_copy_from_df()`](https://rladybugdb.github.io/rladybugdb/reference/lb_copy_from_df.md)
  : Load an R data frame into a LadybugDB table via CSV
- [`lb_copy_from_csv()`](https://rladybugdb.github.io/rladybugdb/reference/lb_copy_from_csv.md)
  : Load a CSV file into a LadybugDB table

## Result conversion

Convert an `lb_result` into standard R data structures.

- [`as.data.frame(`*`<lb_result>`*`)`](https://rladybugdb.github.io/rladybugdb/reference/as.data.frame.lb_result.md)
  : Convert an lb_result to a data frame
- [`as_arrow_table()`](https://rladybugdb.github.io/rladybugdb/reference/as_arrow_table.md)
  : Convert an lb_result to an Arrow Table
- [`as_tibble.lb_result()`](https://rladybugdb.github.io/rladybugdb/reference/as_tibble.lb_result.md)
  : Convert an lb_result to a tibble

## Graph analysis

Convert query results into igraph or tidygraph objects.

- [`as_igraph()`](https://rladybugdb.github.io/rladybugdb/reference/as_igraph.md)
  : Convert an lb_result to an igraph object
- [`as_tbl_graph()`](https://rladybugdb.github.io/rladybugdb/reference/as_tbl_graph.md)
  : Convert an lb_result to a tbl_graph (tidygraph)

## Package info

Check the installed C library version and compatibility.

- [`ladybugdb_version()`](https://rladybugdb.github.io/rladybugdb/reference/ladybugdb_version.md)
  : Return the LadybugDB C library version string
- [`ladybugdb_is_installed()`](https://rladybugdb.github.io/rladybugdb/reference/ladybugdb_is_installed.md)
  : Check whether real_ladybug is importable
- [`ladybugdb_install()`](https://rladybugdb.github.io/rladybugdb/reference/ladybugdb_install.md)
  : Install the real_ladybug Python package
