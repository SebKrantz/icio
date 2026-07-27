# Load an ICIO Table from the 'icio' CSV Format

Reads an Inter-Country Input-Output table from the CSV format used by
the Stata `icio` command and returns an 'icio' class object, ready for
[`decomp`](https://sebkrantz.github.io/icio/reference/decomp.md) and the
decomposition functions.

## Usage

``` r
load_icio_csv(
  table,
  countries,
  industries = NULL,
  output = NULL,
  va = NULL,
  ...
)
```

## Arguments

- table:

  character. Path to a headerless `GN x (GN + G)` CSV file holding the
  matrix `[inter | final]`: the first GN columns are the intermediate
  transactions, the last G columns the final demand (one aggregated
  column per country). Read with
  [`fread`](https://rdrr.io/pkg/data.table/man/fread.html).

- countries:

  character. Either a vector of G country codes, or the path to a
  headerless one-column CSV file containing them (the country list file
  of the Stata `icio` command).

- industries:

  character. Either a vector of N industry codes, the path to a
  headerless one-column CSV file containing them, or `NULL` (the
  default) to generate `"sector1", ..., "sectorN"`. The number of
  industries is inferred as `N = GN / G`.

- output:

  numeric. Optional vector of gross outputs, see
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).

- va:

  numeric. Optional vector of value added, see
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).
  The default is the column residual of the table, which reproduces the
  Stata `icio` command.

- ...:

  further arguments passed to
  [`fread`](https://rdrr.io/pkg/data.table/man/fread.html).

## Value

An 'icio' class object, see
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).

## See also

[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md),
[`decomp`](https://sebkrantz.github.io/icio/reference/decomp.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Sebastian Krantz

## Examples

``` r
if (FALSE) { # \dontrun{
# A table exported for the Stata 'icio' command, together with its country list
m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv")

# Supplying the real sector codes so they appear in the results
m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv",
                   industries = c("AFF", "MIN", "MAN"))

decomp(m, aggregation = "bilateral")
} # }
```
