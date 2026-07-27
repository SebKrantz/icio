# Load an Inter-Country Input-Output Table

Reads the raw ICIO matrices and precomputes everything the
decompositions need, returning an 'icio' class object. This is the entry
point for all decompositions.

## Usage

``` r
load_icio(
  inter,
  final,
  countries,
  industries,
  output = NULL,
  va = NULL,
  null_inventory = FALSE
)
```

## Arguments

- inter:

  intermediate demand table supplied as a numeric matrix of dimensions
  GN x GN (G = no. of countries, N = no. of industries). Both rows and
  columns should be arranged first by country, then by industry (e.g.
  C1I1, C1I2, ..., C2I1, C2I2, ...) and should match (symmetry), such
  that rows and columns refer to the same country-industries.
  Alternatively, an Input-Output Table object of class 'iot' can be
  passed here - a list with elements 'inter', 'final', 'countries',
  'industries' and (optionally) 'output' - in which case the remaining
  table arguments are taken from it. See
  [`leather`](https://sebkrantz.github.io/icio/reference/leather.md).

- final:

  final demand table supplied as a numeric matrix of dimensions GN x GM
  (M = no. of final demand categories recorded for each country). The
  rows of `final` need to match the rows of `inter`, and the columns
  should also be arranged first by country, then by final demand
  category (e.g. C1FD1, C1FD2, ..., C2FD1, C2FD2, ...) with the order of
  the countries the same as in `inter`.

- countries:

  character. A vector of country or region names of length G, arranged
  in the same order as they occur in the rows and columns of `inter` and
  `final`.

- industries:

  character. A vector of industry names of length N, arranged in the
  same order as they occur in the rows and columns of `inter` and the
  rows of `final`.

- output:

  numeric. A vector of gross outputs for each country-industry matching
  the rows of `inter` and `final`. If not provided it will be computed
  as `rowSums(inter) + rowSums(final)`.

- va:

  numeric. A vector of value added for each country-industry matching
  the columns of `inter`. If not provided it will be computed as
  `output - colSums(inter)`, which is what the Stata `icio` command
  does.

- null_inventory:

  logical. `TRUE` sets the inventory (last final demand category for
  each country) to zero.

## Value

An 'icio' class object - a list with the following elements:

|  |  |  |  |
|----|----|----|----|
| A |  |  | Input coefficients matrix (`inter` column-normalized by `output`), including the domestic blocks. |
| B |  |  | Leontief Inverse matrix \\(I - A)^{-1}\\. |
| Lb |  |  | List of `G` domestic (local) Leontief Inverse blocks \\(I - A\_{gg})^{-1}\\, one `N x N` matrix per country. |
| E |  |  | Total Exports (output of each country-industry servicing foreign production or foreign final demand). |
| ESR |  |  | Total Exports by destination country. |
| Vc |  |  | Value added content of output (`va / output`). |
| G |  |  | Number of countries. |
| N |  |  | Number of industries. |
| GN |  |  | Number of country-industries. |
| k |  |  | Vector of country names. |
| i |  |  | Vector of industry names. |
| X |  |  | Total Output (` = output`). |
| Y |  |  | Total Final Demand by destination country. |
| Yd |  |  | Domestic Final Demand. |
| Ym |  |  | Foreign Final Demand. |

The country-industry names identifying the rows and columns are
available as `names(x$Vc)` or `dimnames(x$B)[[1L]]`.

## Details

Only `A` and `B` are dense `GN x GN` matrices. The masked and
block-diagonal variants of them that the decompositions require (\\A\\
with the domestic blocks zeroed, the domestic and foreign parts of
\\B\\) are derived on the fly by the functions that need them, being
either recoverable from `A` and `B` in a few operations or, in the case
of the domestic Leontief inverse, block-diagonal and thus \\1 - 1/G\\
structural zeros.

Value added defaults to the column residual of the table
(`output - colSums(inter)`), which reproduces the Stata `icio` command
exactly. Supplying a `va` that differs from it makes the column sums of
\\V B\\ deviate from 1, so identities such as `GEXP = DC + FC` may no
longer hold exactly - faithful to the supplied data.

## See also

[`load_icio_csv`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md),
[`decomp`](https://sebkrantz.github.io/icio/reference/decomp.md),
[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Sebastian Krantz, Bastiaan Quast. Adapted from code by Fei Wang.

## Examples

``` r
# Load example data
data(leather)

# Create intermediate object (class 'icio') from an 'iot' object
m <- load_icio(leather)

# Equivalent: passing the matrices directly
m <- load_icio(leather$inter, leather$final, leather$countries, leather$industries)

# Examine the object
str(m)
#> List of 15
#>  $ A  : num [1:9, 1:9] 0.20721 0.03089 0.01158 0.01416 0.00386 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>  $ B  : num [1:9, 1:9] 1.2764 0.0562 0.0197 0.035 0.0244 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>  $ Lb :List of 3
#>   ..$ : num [1:3, 1:3] 1.2691 0.0492 0.0192 0.1305 1.1666 ...
#>   ..$ : num [1:3, 1:3] 1.212 0.0957 0.0586 0.174 1.3128 ...
#>   ..$ : num [1:3, 1:3] 1.2537 0.0709 0.1246 0.2619 1.3253 ...
#>  $ E  : Named num [1:9] 33.2 28.5 2.6 45.9 59.2 8.5 38.7 31 77.9
#>   ..- attr(*, "names")= chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>  $ ESR: num [1:9, 1:3] 0 0 0 10.7 12.1 1.6 14.9 10.3 31.6 14 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:3] "Argentina" "Turkey" "Germany"
#>  $ Vc : Named num [1:9] 0.673 0.569 0.321 0.619 0.509 ...
#>   ..- attr(*, "names")= chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>  $ G  : int 3
#>  $ N  : int 3
#>  $ GN : int 9
#>  $ k  : chr [1:3] "Argentina" "Turkey" "Germany"
#>  $ i  : chr [1:3] "Agriculture" "Textile_and_Leather" "Transport_Equipment"
#>  $ X  : Named num [1:9] 77.7 58.3 19 112.7 124.6 ...
#>   ..- attr(*, "names")= chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>  $ Y  : num [1:9, 1:3] 21.5 16.2 11 7.5 8.9 1.2 9.2 7.9 25.1 6.1 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:3] "Argentina" "Turkey" "Germany"
#>  $ Yd : num [1:9, 1:3] 21.5 16.2 11 0 0 0 0 0 0 0 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:3] "Argentina" "Turkey" "Germany"
#>  $ Ym : num [1:9, 1:3] 0 0 0 7.5 8.9 1.2 9.2 7.9 25.1 6.1 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:9] "Argentina.Agriculture" "Argentina.Textile_and_Leather" "Argentina.Transport_Equipment" "Turkey.Agriculture" ...
#>   .. ..$ : chr [1:3] "Argentina" "Turkey" "Germany"
#>  - attr(*, "class")= chr "icio"
```
