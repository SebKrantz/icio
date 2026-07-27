# Wang-Wei-Zhu Decomposition of Gross Exports

This function performs the Wang-Wei-Zhu decomposition of country-sector
level gross exports into 16 value added components by importing country.

## Usage

``` r
wwz(x, verbose = FALSE)
```

## Arguments

- x:

  an object of the class 'icio' obtained from
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).

- verbose:

  logical, should timings of the calculation be displayed? Default is
  FALSE

## Value

A long-format `data.table` with one row per (exporting country-industry,
importing country) pair and columns `Exporting_Country`,
`Exporting_Industry`, `Importing_Country` followed by the 16
decomposition terms (as detailed in Table E1 in the appendix of Wang,
Wei & Zhu 2013) and diagnostic items:

|  |  |
|----|----|
| *Term* | *Description* |
| `DVA_FIN` | Domestic VA in final goods exports. |
| `DVA_INT` | Domestic VA in intermediate exports used by direct importer to produce domestic final goods consumed at home. |
| `DVA_INTrexI1` | Domestic VA in intermediate exports used by the direct importer to produce intermediate exports for production of final goods in third countries that are then imported and consumed by the direct importer. |
| `DVA_INTrexF` | Domestic VA in intermediate exports used by the direct importer to produce final goods exports to third countries. |
| `DVA_INTrexI2` | Domestic VA in intermediate exports used by the direct importer to produce intermediate exports to third countries. |
| `RDV_INT` | Domestic VA in intermediate exports that returns via intermediate imports (i.e. is used to produce a locally consumed final good). |
| `RDV_FIN` | Domestic VA in intermediate exports that returns home via final goods imports from the direct importer. |
| `RDV_FIN2` | Domestic VA in intermediate exports that returns home via final goods imports from third countries. |
| `OVA_FIN` | Third countries’ VA in final goods exports. |
| `MVA_FIN` | Direct importer’s VA in final goods exports. |
| `OVA_INT` | Third countries’ VA in intermediate exports. |
| `MVA_INT` | Direct importer’s VA in intermediate exports. |
| `DDC_FIN` | Double counted domestic VA used to produce final goods exports. |
| `DDC_INT` | Double counted domestic VA used to produce intermediate exports. |
| `ODC` | Double counted third countries’ VA in home country’s exports production. |
| `MDC` | Double counted direct importer’s VA in home country’s exports production. |
| *Diagnostic Item* | *Description* |
| `texp` | Total exports (matrix `ESR` from [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)). |
| `texpint` | Exports for intermediate production (matrix `Eint` from [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)). |
| `texpfd` | Exports for final demand (matrix `Efd` from [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)). |
| `texpdiff` | Difference between total exports and the sum of the 16 terms. |
| `texpdiffpercent` | ... in percent of total exports. |
| `texpfddiff` | Difference between final exports and the sum of DVA_FIN, OVA_FIN and MVA_FIN. |
| `texpfddiffpercent` | ... in percent of final exports. |
| `texpintdiff` | Difference between intermediate exports and the sum of all remaining terms. |
| `texpintdiffpercent` | ... in percent of intermediate exports. |
| `DViX_Fsr` | DVA embodied in gross exports based on forward linkage. |

## Details

Adapted from code by Fei Wang.

## References

Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying
international production sharing at the bilateral and sector levels (No.
w19677). *National Bureau of Economic Research*.

## See also

[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md),
[`wwz2kww`](https://sebkrantz.github.io/icio/reference/wwz2kww.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Bastiaan Quast

## Examples

``` r
# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)

# Perform the WWZ decomposition
wwz(m)
#>     Exporting_Country  Exporting_Industry Importing_Country    DVA_FIN
#>                <fctr>              <fctr>            <fctr>      <num>
#>  1:         Argentina         Agriculture         Argentina  0.0000000
#>  2:         Argentina         Agriculture            Turkey  5.4744354
#>  3:         Argentina         Agriculture           Germany  7.5385668
#>  4:         Argentina Textile_and_Leather         Argentina  0.0000000
#>  5:         Argentina Textile_and_Leather            Turkey  1.4704511
#>  6:         Argentina Textile_and_Leather           Germany  3.9470004
#>  7:         Argentina Transport_Equipment         Argentina  0.0000000
#>  8:         Argentina Transport_Equipment            Turkey  0.3534427
#>  9:         Argentina Transport_Equipment           Germany  0.5655083
#> 10:            Turkey         Agriculture         Argentina  6.2797497
#> 11:            Turkey         Agriculture            Turkey  0.0000000
#> 12:            Turkey         Agriculture           Germany 11.8896593
#> 13:            Turkey Textile_and_Leather         Argentina  7.2273648
#> 14:            Turkey Textile_and_Leather            Turkey  0.0000000
#> 15:            Turkey Textile_and_Leather           Germany 13.7238725
#> 16:            Turkey Transport_Equipment         Argentina  0.8407805
#> 17:            Turkey Transport_Equipment            Turkey  0.0000000
#> 18:            Turkey Transport_Equipment           Germany  3.4331870
#> 19:           Germany         Agriculture         Argentina  7.8610949
#> 20:           Germany         Agriculture            Turkey 15.2949565
#> 21:           Germany         Agriculture           Germany  0.0000000
#> 22:           Germany Textile_and_Leather         Argentina  6.5544233
#> 23:           Germany Textile_and_Leather            Turkey  8.3797057
#> 24:           Germany Textile_and_Leather           Germany  0.0000000
#> 25:           Germany Transport_Equipment         Argentina 16.9168288
#> 26:           Germany Transport_Equipment            Turkey 23.7239990
#> 27:           Germany Transport_Equipment           Germany  0.0000000
#>     Exporting_Country  Exporting_Industry Importing_Country    DVA_FIN
#>                <fctr>              <fctr>            <fctr>      <num>
#>        DVA_INT DVA_INTrexI1 DVA_INTrexF DVA_INTrexI2     RDV_INT    RDV_FIN
#>          <num>        <num>       <num>        <num>       <num>      <num>
#>  1:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#>  2:  2.6813686   1.13634407  1.40930027  0.504931544 0.168614730 0.70568372
#>  3:  5.1055954   0.41301548  2.07223830  0.184142503 0.241349852 1.40626760
#>  4:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#>  5:  1.6059520   0.51989101  0.73959485  0.238689217 0.078969730 0.33143582
#>  6:  6.4499428   0.53948810  2.81987967  0.236761536 0.317887034 1.98497120
#>  7:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#>  8:  0.1488951   0.02512465  0.05166467  0.011502878 0.004631660 0.01867612
#>  9:  0.3167888   0.02878668  0.13002229  0.012763061 0.014519380 0.09346627
#> 10:  1.1190525   0.42428189  0.32364669  0.127683939 0.154036261 0.17353911
#> 11:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#> 12:  9.1875645   0.44406842  2.46325705  0.104348906 0.693923875 3.73948515
#> 13:  1.0471326   0.46078259  0.29530382  0.140987907 0.151185856 0.13152490
#> 14:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#> 15: 12.0058480   0.62802955  3.90680904  0.127367338 0.950059562 5.57979048
#> 16:  0.1781916   0.02204374  0.02060577  0.006672856 0.008562439 0.01119518
#> 17:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#> 18:  0.6546040   0.03517716  0.21633307  0.007037041 0.049810123 0.31139842
#> 19:  2.0199906   0.28226589  0.28018271  0.060605877 0.820750168 0.57157404
#> 20:  2.0603035   0.11637081  0.47705677  0.015705424 0.736949683 0.97226390
#> 21:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#> 22:  0.7909465   0.11961386  0.15208027  0.027530616 0.309465907 0.25977474
#> 23:  3.6874998   0.18967992  0.78711215  0.023624112 1.222414373 1.69900744
#> 24:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#> 25:  2.3746384   0.18110921  0.25997068  0.039006620 0.436904740 0.42764724
#> 26:  3.2689405   0.14831124  0.60720101  0.018387426 0.907106729 1.37381855
#> 27:  0.0000000   0.00000000  0.00000000  0.000000000 0.000000000 0.00000000
#>        DVA_INT DVA_INTrexI1 DVA_INTrexF DVA_INTrexI2     RDV_INT    RDV_FIN
#>          <num>        <num>       <num>        <num>       <num>      <num>
#>        RDV_FIN2    OVA_FIN    MVA_FIN    OVA_INT    MVA_INT     DDC_FIN
#>           <num>      <num>      <num>      <num>      <num>       <num>
#>  1: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#>  2: 0.347019751 0.41126356 0.21430105 0.19588405 0.10207118 0.064864146
#>  3: 0.084582830 0.29510308 0.56633015 0.19467191 0.37359342 0.087209223
#>  4: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#>  5: 0.166207540 0.24200608 0.18754280 0.26256584 0.20347560 0.027678457
#>  6: 0.107403534 0.50340436 0.64959526 0.81211670 1.04795907 0.106880311
#>  7: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#>  8: 0.007976699 0.09668098 0.04987633 0.04203798 0.02168679 0.001418669
#>  9: 0.005810004 0.07980213 0.15468957 0.04511074 0.08744330 0.005097011
#> 10: 0.182994956 0.83991301 0.38033734 0.15006977 0.06795601 0.107000467
#> 11: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#> 12: 0.057224342 0.72010537 1.59023530 0.55070767 1.21614811 0.452925213
#> 13: 0.200948224 0.91653494 0.75610026 0.13297218 0.10969609 0.101320108
#> 14: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#> 15: 0.074151999 1.43574094 1.74038658 1.24831079 1.51318619 0.597136653
#> 16: 0.009457655 0.24206509 0.11715443 0.05450683 0.02638016 0.005182273
#> 17: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#> 18: 0.004084652 0.47838059 0.98843243 0.09450248 0.19526151 0.031112965
#> 19: 0.131707311 0.89832585 0.44057920 0.22998309 0.11279400 0.605435276
#> 20: 0.029961455 0.85721388 1.74782965 0.11412326 0.23269341 0.531356894
#> 21: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#> 22: 0.058019038 0.70047263 0.64510407 0.08462563 0.07793643 0.224432812
#> 23: 0.046204332 0.82475330 0.89554095 0.36128082 0.39228915 0.921022483
#> 24: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#> 25: 0.084238072 5.26294538 2.92022578 0.77714301 0.43120969 0.314861124
#> 26: 0.035453172 4.09529671 7.38070428 0.58558374 1.05536198 0.673700534
#> 27: 0.000000000 0.00000000 0.00000000 0.00000000 0.00000000 0.000000000
#>        RDV_FIN2    OVA_FIN    MVA_FIN    OVA_INT    MVA_INT     DDC_FIN
#>           <num>      <num>      <num>      <num>      <num>       <num>
#>        DDC_INT        ODC        MDC  texp texpint texpfd texpdiff
#>          <num>      <num>      <num> <num>   <num>  <num>    <num>
#>  1: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#>  2: 0.07171574 0.33673597 0.17546624  14.0     7.9    6.1        0
#>  3: 0.09804177 0.18474634 0.35454534  19.2    10.8    8.4        0
#>  4: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#>  5: 0.08379741 0.36155510 0.28018741   6.8     4.9    1.9        0
#>  6: 0.28388511 0.82641514 1.06640983  21.7    16.6    5.1        0
#>  7: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#>  8: 0.01286371 0.03530681 0.01821428   0.9     0.4    0.5        0
#>  9: 0.02894336 0.04466665 0.08658247   1.7     0.9    0.8        0
#> 10: 0.06712404 0.20829312 0.09432126  10.7     3.2    7.5        0
#> 11: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#> 12: 0.44050153 0.51423688 1.13560832  35.2    21.0   14.2        0
#> 13: 0.06941710 0.19656847 0.16216018  12.1     3.2    8.9        0
#> 14: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#> 15: 0.65512387 1.31733277 1.59685374  47.1    30.2   16.9        0
#> 16: 0.01834868 0.02618153 0.01267131   1.6     0.4    1.2        0
#> 17: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#> 18: 0.09174341 0.10075490 0.20818030   6.9     2.0    4.9        0
#> 19: 0.09794912 0.32658836 0.16017355  14.9     5.7    9.2        0
#> 20: 0.10138593 0.16842209 0.34340686  23.8     5.9   17.9        0
#> 21: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#> 22: 0.04935351 0.12817618 0.11804455  10.3     2.4    7.9        0
#> 23: 0.21797800 0.50430185 0.54758551  20.7    10.6   10.1        0
#> 24: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#> 25: 0.26247603 0.58577113 0.32502408  31.6     6.5   25.1        0
#> 26: 0.44822829 0.70583084 1.27207602  46.3    11.1   35.2        0
#> 27: 0.00000000 0.00000000 0.00000000   0.0     0.0    0.0        0
#>        DDC_INT        ODC        MDC  texp texpint texpfd texpdiff
#>          <num>      <num>      <num> <num>   <num>  <num>    <num>
#>     texpdiffpercent texpfddiff texpfddiffpercent texpintdiff texpintdiffpercent
#>               <num>      <num>             <num>       <num>              <num>
#>  1:               0          0                 0           0                  0
#>  2:               0          0                 0           0                  0
#>  3:               0          0                 0           0                  0
#>  4:               0          0                 0           0                  0
#>  5:               0          0                 0           0                  0
#>  6:               0          0                 0           0                  0
#>  7:               0          0                 0           0                  0
#>  8:               0          0                 0           0                  0
#>  9:               0          0                 0           0                  0
#> 10:               0          0                 0           0                  0
#> 11:               0          0                 0           0                  0
#> 12:               0          0                 0           0                  0
#> 13:               0          0                 0           0                  0
#> 14:               0          0                 0           0                  0
#> 15:               0          0                 0           0                  0
#> 16:               0          0                 0           0                  0
#> 17:               0          0                 0           0                  0
#> 18:               0          0                 0           0                  0
#> 19:               0          0                 0           0                  0
#> 20:               0          0                 0           0                  0
#> 21:               0          0                 0           0                  0
#> 22:               0          0                 0           0                  0
#> 23:               0          0                 0           0                  0
#> 24:               0          0                 0           0                  0
#> 25:               0          0                 0           0                  0
#> 26:               0          0                 0           0                  0
#> 27:               0          0                 0           0                  0
#>     texpdiffpercent texpfddiff texpfddiffpercent texpintdiff texpintdiffpercent
#>               <num>      <num>             <num>       <num>              <num>
#>       DViX_Fsr
#>          <num>
#>  1:  0.0000000
#>  2: 12.6653262
#>  3: 18.5127115
#>  4:  0.0000000
#>  5:  5.0399905
#>  6: 15.2000533
#>  7:  0.0000000
#>  8:  0.4855005
#>  9:  0.9139796
#> 10:  9.5810525
#> 11:  0.0000000
#> 12: 32.5558824
#> 13:  8.8144222
#> 14:  0.0000000
#> 15: 34.0847033
#> 16:  0.9503192
#> 17:  0.0000000
#> 18:  3.8384373
#> 19: 16.3782379
#> 20: 26.3978378
#> 21:  0.0000000
#> 22:  9.6143465
#> 23: 17.5471871
#> 24:  0.0000000
#> 25: 14.8384045
#> 26: 22.0663893
#> 27:  0.0000000
#>       DViX_Fsr
#>          <num>
```
