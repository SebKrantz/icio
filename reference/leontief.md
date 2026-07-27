# Leontief Decomposition

The Leontief decomposition of gross flows (exports, final demand,
output) into their value added origins.

## Usage

``` r
leontief(x, post = c("exports", "output", "final_demand", "none"), long = TRUE)
```

## Arguments

- x:

  an object of class 'icio'.

- post:

  post-multiply the value added multiplier matrix \[\\VB =
  V(I-A)^{-1}\\\] with something to deduce the value added origins
  thereof. The default is `"exports"` \\VAE = V(I-A)^{-1}E\\, where
  \\E\\ is a diagonal matrix with exports along the diagonal yielding
  the country-industry level sources of value added (rows) for each
  using (column) country-industry; similarly for `"output"`. Option
  `"final_demand"` computes value added origins of final demand by
  source country-industry and importing country, by computing \\VAY =
  V(I-A)^{-1}Y\\ where \\Y\\ is the corresponding GN x G matrix
  contained in `x`. Option `"none"` just returns \\VB\\ which gives the
  value added shares.

- long:

  logical. Transform the output data into a long (tidy) data set or not,
  default is `TRUE`.

## Value

If `long = TRUE` a molten `data.table` containing the elements of the
decomposed flows matrix in the final column, preceded by several
identifier columns. If `long = FALSE` the decomposed flows matrix is
simply returned.

## Details

The Leontief decomposition is obtained by pre-multiplying the flow
measure (e.g. exports) with the value added multiplier matrix \[\\VB =
V(I-A)^{-1}\\\], obtained by pre-multiplying the Leontief Inverse matrix
\[\\B = (I-A)^{-1}\\\] with a diagonal matrix \[\\V\\\] containing the
direct value added share in each industries output.

\\V\\ is obtained as `diag(v / o)` where `o` is total industry output.
`v` is either supplied to
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)
or computed as `o - colSums(x)` with `x` the raw IO matrix. If `o` is
not supplied to
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md),
it is computed as `rowSums(x) + rowSums(y)` where `y` is the matrix of
final demands. If both `o` and `v` are not supplied to
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md),
this is equivalent to computing \\V\\ as `diag(1 - colSums(A))`, with
\\A\\ is the row-normalized IO matrix also used to compute the Leontief
Inverse \[\\B\\\].

## References

Leontief, W. (Ed.). (1986). Input-output economics. *Oxford University
Press*.

Hummels, D., Ishii, J., & Yi, K. M. (2001). The nature and growth of
vertical specialization in world trade. *Journal of international
Economics, 54*(1), 75-96.

Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying
international production sharing at the bilateral and sector levels (No.
w19677). *National Bureau of Economic Research*.

## See also

[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md),
[`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Bastiaan Quast

## Examples

``` r
# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)

# Perform the Leontief decomposition of each country-industries 
# exports into their value added origins by country-industry
leontief(m)
#>     Source_Country     Source_Industry Using_Country      Using_Industry
#>             <fctr>              <fctr>        <fctr>              <fctr>
#>  1:      Argentina         Agriculture     Argentina         Agriculture
#>  2:      Argentina         Agriculture     Argentina Textile_and_Leather
#>  3:      Argentina         Agriculture     Argentina Transport_Equipment
#>  4:      Argentina         Agriculture        Turkey         Agriculture
#>  5:      Argentina         Agriculture        Turkey Textile_and_Leather
#>  6:      Argentina         Agriculture        Turkey Transport_Equipment
#>  7:      Argentina         Agriculture       Germany         Agriculture
#>  8:      Argentina         Agriculture       Germany Textile_and_Leather
#>  9:      Argentina         Agriculture       Germany Transport_Equipment
#> 10:      Argentina Textile_and_Leather     Argentina         Agriculture
#> 11:      Argentina Textile_and_Leather     Argentina Textile_and_Leather
#> 12:      Argentina Textile_and_Leather     Argentina Transport_Equipment
#> 13:      Argentina Textile_and_Leather        Turkey         Agriculture
#> 14:      Argentina Textile_and_Leather        Turkey Textile_and_Leather
#> 15:      Argentina Textile_and_Leather        Turkey Transport_Equipment
#> 16:      Argentina Textile_and_Leather       Germany         Agriculture
#> 17:      Argentina Textile_and_Leather       Germany Textile_and_Leather
#> 18:      Argentina Textile_and_Leather       Germany Transport_Equipment
#> 19:      Argentina Transport_Equipment     Argentina         Agriculture
#> 20:      Argentina Transport_Equipment     Argentina Textile_and_Leather
#> 21:      Argentina Transport_Equipment     Argentina Transport_Equipment
#> 22:      Argentina Transport_Equipment        Turkey         Agriculture
#> 23:      Argentina Transport_Equipment        Turkey Textile_and_Leather
#> 24:      Argentina Transport_Equipment        Turkey Transport_Equipment
#> 25:      Argentina Transport_Equipment       Germany         Agriculture
#> 26:      Argentina Transport_Equipment       Germany Textile_and_Leather
#> 27:      Argentina Transport_Equipment       Germany Transport_Equipment
#> 28:         Turkey         Agriculture     Argentina         Agriculture
#> 29:         Turkey         Agriculture     Argentina Textile_and_Leather
#> 30:         Turkey         Agriculture     Argentina Transport_Equipment
#> 31:         Turkey         Agriculture        Turkey         Agriculture
#> 32:         Turkey         Agriculture        Turkey Textile_and_Leather
#> 33:         Turkey         Agriculture        Turkey Transport_Equipment
#> 34:         Turkey         Agriculture       Germany         Agriculture
#> 35:         Turkey         Agriculture       Germany Textile_and_Leather
#> 36:         Turkey         Agriculture       Germany Transport_Equipment
#> 37:         Turkey Textile_and_Leather     Argentina         Agriculture
#> 38:         Turkey Textile_and_Leather     Argentina Textile_and_Leather
#> 39:         Turkey Textile_and_Leather     Argentina Transport_Equipment
#> 40:         Turkey Textile_and_Leather        Turkey         Agriculture
#> 41:         Turkey Textile_and_Leather        Turkey Textile_and_Leather
#> 42:         Turkey Textile_and_Leather        Turkey Transport_Equipment
#> 43:         Turkey Textile_and_Leather       Germany         Agriculture
#> 44:         Turkey Textile_and_Leather       Germany Textile_and_Leather
#> 45:         Turkey Textile_and_Leather       Germany Transport_Equipment
#> 46:         Turkey Transport_Equipment     Argentina         Agriculture
#> 47:         Turkey Transport_Equipment     Argentina Textile_and_Leather
#> 48:         Turkey Transport_Equipment     Argentina Transport_Equipment
#> 49:         Turkey Transport_Equipment        Turkey         Agriculture
#> 50:         Turkey Transport_Equipment        Turkey Textile_and_Leather
#> 51:         Turkey Transport_Equipment        Turkey Transport_Equipment
#> 52:         Turkey Transport_Equipment       Germany         Agriculture
#> 53:         Turkey Transport_Equipment       Germany Textile_and_Leather
#> 54:         Turkey Transport_Equipment       Germany Transport_Equipment
#> 55:        Germany         Agriculture     Argentina         Agriculture
#> 56:        Germany         Agriculture     Argentina Textile_and_Leather
#> 57:        Germany         Agriculture     Argentina Transport_Equipment
#> 58:        Germany         Agriculture        Turkey         Agriculture
#> 59:        Germany         Agriculture        Turkey Textile_and_Leather
#> 60:        Germany         Agriculture        Turkey Transport_Equipment
#> 61:        Germany         Agriculture       Germany         Agriculture
#> 62:        Germany         Agriculture       Germany Textile_and_Leather
#> 63:        Germany         Agriculture       Germany Transport_Equipment
#> 64:        Germany Textile_and_Leather     Argentina         Agriculture
#> 65:        Germany Textile_and_Leather     Argentina Textile_and_Leather
#> 66:        Germany Textile_and_Leather     Argentina Transport_Equipment
#> 67:        Germany Textile_and_Leather        Turkey         Agriculture
#> 68:        Germany Textile_and_Leather        Turkey Textile_and_Leather
#> 69:        Germany Textile_and_Leather        Turkey Transport_Equipment
#> 70:        Germany Textile_and_Leather       Germany         Agriculture
#> 71:        Germany Textile_and_Leather       Germany Textile_and_Leather
#> 72:        Germany Textile_and_Leather       Germany Transport_Equipment
#> 73:        Germany Transport_Equipment     Argentina         Agriculture
#> 74:        Germany Transport_Equipment     Argentina Textile_and_Leather
#> 75:        Germany Transport_Equipment     Argentina Transport_Equipment
#> 76:        Germany Transport_Equipment        Turkey         Agriculture
#> 77:        Germany Transport_Equipment        Turkey Textile_and_Leather
#> 78:        Germany Transport_Equipment        Turkey Transport_Equipment
#> 79:        Germany Transport_Equipment       Germany         Agriculture
#> 80:        Germany Transport_Equipment       Germany Textile_and_Leather
#> 81:        Germany Transport_Equipment       Germany Transport_Equipment
#>     Source_Country     Source_Industry Using_Country      Using_Industry
#>             <fctr>              <fctr>        <fctr>              <fctr>
#>            FVAX
#>           <num>
#>  1: 28.52278143
#>  2:  2.79395126
#>  3:  0.35606694
#>  4:  1.81066955
#>  5:  3.11738415
#>  6:  0.35901126
#>  7:  1.23641723
#>  8:  1.30283802
#>  9:  4.12087363
#> 10:  1.06206936
#> 11: 19.12053186
#> 12:  0.41813924
#> 13:  0.48370042
#> 14:  1.83290239
#> 15:  0.43058635
#> 16:  0.59370415
#> 17:  1.15375958
#> 18:  4.74903511
#> 19:  0.21043693
#> 20:  0.14228369
#> 21:  1.06369578
#> 22:  0.03329456
#> 23:  0.07905450
#> 24:  0.04024626
#> 25:  0.02318460
#> 26:  0.07482343
#> 27:  0.19326212
#> 28:  0.71952151
#> 29:  1.34237213
#> 30:  0.11504126
#> 31: 34.92704803
#> 32:  6.99949698
#> 33:  1.47711579
#> 34:  2.55430885
#> 35:  1.52213499
#> 36:  6.18062537
#> 37:  0.41201175
#> 38:  1.38523849
#> 39:  0.11764036
#> 40:  2.69291816
#> 41: 40.16714096
#> 42:  1.31799873
#> 43:  1.10939926
#> 44:  1.15207241
#> 45:  9.50690317
#> 46:  0.03482652
#> 47:  0.08553139
#> 48:  0.02667530
#> 49:  0.81210167
#> 50:  0.90751892
#> 51:  3.16041392
#> 52:  0.11511911
#> 53:  0.07448266
#> 54:  0.64647326
#> 55:  0.92530356
#> 56:  2.25142713
#> 57:  0.16222512
#> 58:  2.31122022
#> 59:  2.05958253
#> 60:  0.51211484
#> 61: 29.87633590
#> 62:  5.24719728
#> 63:  9.60069308
#> 64:  0.64666560
#> 65:  0.72785683
#> 66:  0.08244379
#> 67:  1.53837777
#> 68:  2.54889673
#> 69:  0.63316614
#> 70:  1.45935830
#> 71: 18.95868110
#> 72:  8.15831503
#> 73:  0.66638333
#> 74:  0.65080723
#> 75:  0.25807221
#> 76:  1.29066963
#> 77:  1.48802285
#> 78:  0.56934671
#> 79:  1.73217260
#> 80:  1.51401054
#> 81: 34.74381924
#>            FVAX
#>           <num>
```
