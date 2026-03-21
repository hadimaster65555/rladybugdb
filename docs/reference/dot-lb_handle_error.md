# Handle Python exceptions from LadybugDB

Wraps a call expression, catches any condition, and re-throws as a typed
R error with the Python traceback attached.

## Usage

``` r
.lb_handle_error(expr)
```

## Arguments

- expr:

  Expression to evaluate.
