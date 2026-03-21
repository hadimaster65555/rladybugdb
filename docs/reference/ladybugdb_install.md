# Install the real_ladybug Python package

Uses
[`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html)
to install `real_ladybug` into the active Python environment. Run this
once after installing the R package.

## Usage

``` r
ladybugdb_install(envname = NULL, method = "auto", ...)
```

## Arguments

- envname:

  Name of the Python / conda environment to install into. Defaults to
  `NULL` (uses the currently active reticulate environment).

- method:

  Installation method passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).
  `"auto"` tries pip first.

- ...:

  Additional arguments forwarded to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

## Value

Invisible `NULL`. Called for its side effect.

## Examples

``` r
if (FALSE) { # \dontrun{
ladybugdb_install()
} # }
```
