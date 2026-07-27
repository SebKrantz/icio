# Koopman-Wang-Wei from Wang-Wei-Zhu Decomposition

This function by default returns a disaggregated version of the the
Koopman-Wang-Wei (KWW) decomposition breaking up sector-level gross
exports into 9 value added terms, from an already computed and more
detailed (16 term) Wang-Wei-Zhu decomposition of sector-level gross
exports. An aggregation option also allows obtaining the aggregate KWW
decomposition.

## Usage

``` r
wwz2kww(x, aggregate = FALSE)
```

## Arguments

- x:

  a data.table with the WWZ decomposition obtained from
  [`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md).
  Alternatively an 'icio' class object from
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)
  can be supplied, which will toggle calling
  [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) first.

- aggregate:

  logical. `TRUE` aggregates the KWW decomposition to the country level,
  giving exactly the same output as
  [`kww`](https://sebkrantz.github.io/icio/reference/kww.md). `FALSE`
  maintains the sector level decomposition in KWW format.

## Value

A `data.table` with exports decomposed into 9 components (columns), see
the table above and
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md) for a shorter
description of the 9 terms.

## Details

The mapping of the 16 terms in the WWZ decomposition to the 9 terms in
the KWW decomposition is provided in table E2 in the appendix of the WWZ
(2013) paper. The table is reproduced here using the term naming
conventions followed in this package.

|  |  |  |
|----|----|----|
| *WWZ Terms* | *KWW Term* | *Description* |
| `DVA_FIN` | `DVA_FIN` | Domestic VA in final goods exports. |
| `DVA_INT, DVA_INTrexI1` | `DVA_INT` | Domestic VA in intermediate exports absorbed by direct importers. WWZ separates VA absorbed directly from VA that transits through third countries before returning to the direct importer. |
| `DVA_INTrexF, DVA_INTrexI2` | `DVA_INTrex` | Domestic VA in intermediate exports reexported to third countries and absorbed there. WWZ separates VA in final goods exports of direct importer to third countries from VA in intermediate exports to third countries. |
| `RDV_FIN, RDV_FIN2` | `RDV_FIN` | Domestic VA in intermediate exports that returns home via final imports. WWZ separates final imports from the direct importer and from third countries. |
| `RDV_INT` | `RDV_INT` | Domestic VA in intermediate exports that returns via intermediate imports (used to produce a locally consumed final good). |
| `DDC_FIN, DDC_INT` | `DDC` | Double counted domestic VA in gross exports. WWZ separates double counting due to final and intermediate exports production. |
| `MVA_FIN, OVA_FIN` | `FVA_FIN` | Foreign VA in final goods exports. WWZ separates FVA from direct importer and from third countries. |
| `MVA_INT, OVA_INT` | `FVA_INT` | Foreign VA in intermediate exports. WWZ separates FVA from direct importer and from third countries. |
| `MDC, ODC` | `FDC` | Double counted foreign VA in gross exports. WWZ separates FDC from direct importer and from third countries. |

## Note

If both WWZ and KWW decompositions are required, it is computationally
more efficient to call `wwz2kww(x, aggregate = TRUE)` on an already
computed WWZ decomposition, than to call
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md) on an 'icio'
object.

## References

Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and
double counting in gross exports. *American Economic Review, 104*(2),
459-94.

Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying
international production sharing at the bilateral and sector levels (No.
w19677). *National Bureau of Economic Research*.

## See also

[`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md),
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Sebastian Krantz

## Examples

``` r

# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)
 
# Perform the WWZ decomposition
WWZ <- wwz(m)

# Obtain a disaggregated KWW decomposition
KWW <- wwz2kww(WWZ)

# Aggregate KWW 
wwz2kww(WWZ, aggregate = TRUE)
#>      Country  DVA_FIN  DVA_INT DVA_INTrex   RDV_FIN   RDV_INT       DDC
#>       <fctr>    <num>    <num>      <num>     <num>     <num>     <num>
#> 1: Argentina 19.34940 18.97119   8.411491  5.259501 0.8259724 0.8723949
#> 2:    Turkey 43.39461 26.20678   7.740053 10.475795 2.0075781 2.6369363
#> 3:   Germany 78.73101 15.23967   2.748464  5.689669 4.4335916 4.4481800
#>      FVA_FIN  FVA_INT      FDC
#>        <num>    <num>    <num>
#> 1:  3.450595 3.388617 3.770832
#> 2: 10.205386 5.359698 5.573163
#> 3: 26.668992 4.455024 5.185401

# Same as running KWW directly, but the former is more efficient 
# if we already have the WWZ
kww(m)
#>      Country  DVA_FIN  DVA_INT DVA_INTrex   RDV_FIN   RDV_INT       DDC
#>       <fctr>    <num>    <num>      <num>     <num>     <num>     <num>
#> 1: Argentina 19.34940 18.97119   8.411491  5.259501 0.8259724 0.8723949
#> 2:    Turkey 43.39461 26.20678   7.740053 10.475795 2.0075781 2.6369363
#> 3:   Germany 78.73101 15.23967   2.748464  5.689669 4.4335916 4.4481800
#>      FVA_FIN  FVA_INT      FDC
#>        <num>    <num>    <num>
#> 1:  3.450595 3.388617 3.770832
#> 2: 10.205386 5.359698 5.573163
#> 3: 26.668992 4.455024 5.185401
```
