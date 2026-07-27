# Borin-Mancini Decomposition of Gross Exports and Imports

Decomposes gross exports (or imports) into value-added and Global Value
Chain (GVC) components following the Borin and Mancini (2019) framework,
as implemented in the Stata `icio` command (Belotti, Borin and Mancini
2021). It is the R counterpart of the
[`decompose()`](https://rdrr.io/r/stats/decompose.html) function in the
Julia package `GlobalValueChains.jl`, and operates on an `icio` object
created by
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).

## Usage

``` r
bm(
  x,
  aggregation = c("country", "sector", "bilateral"),
  perspective = c("exporter", "world", "self", "importer"),
  approach = c("source", "sink"),
  flow = c("exports", "imports")
)
```

## Arguments

- x:

  an object of class `icio` obtained from
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md).

- aggregation:

  character. The level of the decomposition: `"country"` (one row per
  exporting/importing country), `"sector"` (one row per exporting
  country-industry), or `"bilateral"` (one row per exporting
  country-industry and importing country for exports, or per importing
  country and value-added origin for imports). Default `"country"`.

- perspective:

  character. The accounting perspective defining the perimeter for
  double counting: `"exporter"` (exporting-country perimeter, additive
  across sectors and destinations), `"world"` (world perimeter,
  "corrected KWW", country level only), `"self"` (the export flow's own
  perimeter, giving the broader Johnson (2018) / Los et al. (2016) value
  added \\DVA^\star \supseteq DVA\\; sector and bilateral levels only),
  or `"importer"` (for `flow = "imports"`). Default `"exporter"`.

- approach:

  character. How double-counted items are allocated across shipments:
  `"source"` (value added recorded the first time it leaves the country
  of origin) or `"sink"` (the last time). The two coincide at the
  whole-country exporter perimeter (country level). `"world"` accepts
  both; `"self"` and imports ignore it. Default `"source"`.

- flow:

  character. `"exports"` (default) decomposes gross exports; `"imports"`
  decomposes a country's gross imports from the importer perspective
  (Borin and Mancini 2019, eq. 51) into value added (`VA`) and double
  counting (`DC`).

## Value

A `data.table` with one row per unit and one column per value-added
term, preceded by factor identifier columns: `Exporting_Country`
(country exports); `Exporting_Country, Exporting_Industry` (sector);
`Exporting_Country, Exporting_Industry, Importing_Country` (bilateral
exports); `Importing_Country` (country imports); or
`Importing_Country, Origin_Country` (bilateral imports). The attribute
`"decomposition"` is set to `"bm"`.

## Details

The supported combinations mirror the Stata `icio` command and
`GlobalValueChains.jl`:

|          |                 |                 |               |                      |
|----------|-----------------|-----------------|---------------|----------------------|
| **flow** | **aggregation** | **perspective** | **approach**  | **terms**            |
| exports  | country         | exporter        | source(=sink) | 13                   |
| exports  | country         | world           | source        | 9                    |
| exports  | country         | world           | sink          | 9                    |
| exports  | sector          | exporter        | source        | 13                   |
| exports  | sector          | exporter        | sink          | 9                    |
| exports  | sector          | self            | \-            | 9                    |
| exports  | bilateral       | exporter        | source        | 13                   |
| exports  | bilateral       | exporter        | sink          | 10 (adds VAXIM)      |
| exports  | bilateral       | self            | \-            | 9                    |
| imports  | country         | importer        | \-            | 3 (GIMP VA DC)       |
| imports  | bilateral       | importer        | \-            | 2 (VA DC, by origin) |

All terms are in the same units as the input-output table (e.g. millions
of USD). The following accounting identities hold for exports:
`GEXP = DC + FC`, `DC = DVA + DDC`, `FC = FVA + FDC`, `DVA = VAX + REF`,
and (exporter/source only) `GVC = GVCB + GVCF = GEXP - DAVAX` and
`GVCB = FC + DDC`; for imports `GIMP = VA + DC`.

|  |  |
|----|----|
| `GEXP` | Gross exports. |
| `DC` / `FC` | Domestic / foreign content. |
| `DVA` / `FVA` | Domestic / foreign value added. |
| `DDC` / `FDC` | Domestic / foreign double counting. |
| `VAX` | Domestic value added absorbed abroad (Johnson and Noguera 2012). |
| `REF` | Reflection: domestic value added returning home. |
| `DAVAX` | Domestic value added directly absorbed by the importer (source approach). |
| `VAXIM` | Domestic value added absorbed by the direct importer, incl. re-processing (sink approach; `DAVAX` \\\le\\ `VAXIM` \\\le\\ `VAX`). |
| `GVC` | GVC-related trade (value added crossing more than one border). |
| `GVCB` / `GVCF` | Backward / forward GVC participation. |
| `GIMP` | Gross imports (`= VA + DC`). |
| `VA` / `DC` | Value added / double counting in imports (by origin at the bilateral level). |

The exporter / source decomposition is additive: the `"sector"` result
is the sum of the `"bilateral"` result over importers, and the
`"country"` result is the sum of the `"sector"` result over industries.
The `"sink"` approach shares the domestic content `DC` and foreign
content `FC` with `"source"` at every cell; only the value-added vs
double-counted split differs. The `"self"` perimeter draws the boundary
at the export flow itself, so `DVA` (there \\DVA^\star\\) is weakly
larger than under either exporter approach.

## References

Borin, A. and Mancini, M. (2019). Measuring What Matters in Global Value
Chains and Value-Added Trade. *World Bank Policy Research Working Paper
8804*.

Belotti, F., Borin, A. and Mancini, M. (2021). icio: Economic analysis
with intercountry input-output tables. *The Stata Journal, 21*(3),
708-755.

## See also

[`kww`](https://sebkrantz.github.io/icio/reference/kww.md),
[`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md),
[`leontief`](https://sebkrantz.github.io/icio/reference/leontief.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Sebastian Krantz

## Examples

``` r
# Load example data and create an 'icio' object
data(leather)
dec <- load_icio(leather)

# Country-level decomposition (exporter perspective, source approach; 13 terms)
bm(dec)
#>    Exporting_Country  GEXP        DC       DVA      VAX    DAVAX       REF
#>               <fctr> <num>     <num>     <num>    <num>    <num>     <num>
#> 1:         Argentina  64.3  53.68996  52.81756 46.73209 34.79877  6.085473
#> 2:            Turkey 113.6  92.46175  89.82482 77.34144 65.50360 12.483373
#> 3:           Germany 147.6 111.29058 106.84240 96.71914 89.31689 10.123261
#>          DDC       FC      FVA       FDC      GVC     GVCB     GVCF
#>        <num>    <num>    <num>     <num>    <num>    <num>    <num>
#> 1: 0.8723949 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 2: 2.6369363 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 3: 4.4481800 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551

# Country-level "corrected KWW" (world perspective, sink approach; 9 terms)
bm(dec, perspective = "world", approach = "sink")
#>    Exporting_Country  GEXP        DC       DVA      VAX       REF       DDC
#>               <fctr> <num>     <num>     <num>    <num>     <num>     <num>
#> 1:         Argentina  64.3  53.68996  52.81756 46.73209  6.085473 0.8723949
#> 2:            Turkey 113.6  92.46175  89.82482 77.34144 12.483373 2.6369363
#> 3:           Germany 147.6 111.29058 106.84240 96.71914 10.123261 4.4481800
#>          FC       FVA      FDC
#>       <num>     <num>    <num>
#> 1: 10.61004  8.471827 2.138217
#> 2: 21.13825 18.265189 2.873058
#> 3: 36.30942 33.128506 3.180911

# Sector- and bilateral-sector-level decompositions
bm(dec, aggregation = "sector")
#>    Exporting_Country  Exporting_Industry  GEXP        DC       DVA       VAX
#>               <fctr>              <fctr> <num>     <num>     <num>     <num>
#> 1:         Argentina         Agriculture  33.2 29.795288 29.493900 26.540382
#> 2:         Argentina Textile_and_Leather  28.5 22.056767 21.569374 18.582499
#> 3:         Argentina Transport_Equipment   2.6  1.837902  1.754288  1.609208
#> 4:            Turkey         Agriculture  45.9 38.432068 37.469257 32.468054
#> 5:            Turkey Textile_and_Leather  59.2 48.074157 46.789941 39.702280
#> 6:            Turkey Transport_Equipment   8.5  5.955528  5.565619  5.171110
#> 7:           Germany         Agriculture  38.7 33.067867 32.402844 29.139637
#> 8:           Germany Textile_and_Leather  31.0 25.719889 25.082406 21.487520
#> 9:           Germany Transport_Equipment  77.9 52.502827 49.357153 46.091985
#>        DAVAX       REF        DDC        FC        FVA        FDC       GVC
#>        <num>     <num>      <num>     <num>      <num>      <num>     <num>
#> 1: 20.385155 2.9535185 0.30138767  3.404712  3.3423229 0.06238937 12.814845
#> 2: 13.084653 2.9868748 0.48739312  6.443233  6.3486717 0.09456147 15.415347
#> 3:  1.328962 0.1450801 0.08361414  0.762098  0.7438425 0.01825550  1.271038
#> 4: 27.673077 5.0012037 0.96281049  7.467932  7.2556717 0.21226046 18.226923
#> 5: 33.025635 7.0876610 1.28421633 11.125843 10.8426216 0.28322154 26.174365
#> 6:  4.804889 0.3945085 0.38990949  2.544472  2.4573486 0.08712297  3.695111
#> 7: 26.657741 3.2632066 0.66502295  5.632133  5.4445468 0.18758643 12.042259
#> 8: 18.915931 3.5948858 0.63748284  5.280111  5.1021480 0.17796309 12.084069
#> 9: 43.743217 3.2651685 3.14567421 25.397173 24.5181932 0.87897942 34.156783
#>          GVCB      GVCF
#>         <num>     <num>
#> 1:  3.7060999  9.108745
#> 2:  6.9306263  8.484721
#> 3:  0.8457122  0.425326
#> 4:  8.4307426  9.796180
#> 5: 12.4100595 13.764306
#> 6:  2.9343811  0.760730
#> 7:  6.2971562  5.745103
#> 8:  5.9175939  6.166475
#> 9: 28.5428469  5.613936
bm(dec, aggregation = "bilateral", approach = "sink")   # adds VAXIM
#>     Exporting_Country  Exporting_Industry Importing_Country  GEXP         DC
#>                <fctr>              <fctr>            <fctr> <num>      <num>
#>  1:         Argentina         Agriculture            Turkey  14.0 12.5642780
#>  2:         Argentina Textile_and_Leather            Turkey   6.8  5.2626672
#>  3:         Argentina Transport_Equipment            Turkey   0.9  0.6361968
#>  4:         Argentina         Agriculture           Germany  19.2 17.2310098
#>  5:         Argentina Textile_and_Leather           Germany  21.7 16.7940996
#>  6:         Argentina Transport_Equipment           Germany   1.7  1.2017051
#>  7:            Turkey         Agriculture         Argentina  10.7  8.9591095
#>  8:            Turkey Textile_and_Leather         Argentina  12.1  9.8259679
#>  9:            Turkey Transport_Equipment         Argentina   1.6  1.1210406
#> 10:            Turkey         Agriculture           Germany  35.2 29.4729584
#> 11:            Turkey Textile_and_Leather           Germany  47.1 38.2481890
#> 12:            Turkey Transport_Equipment           Germany   6.9  4.8344878
#> 13:           Germany         Agriculture         Argentina  14.9 12.7315559
#> 14:           Germany Textile_and_Leather         Argentina  10.3  8.5456405
#> 15:           Germany Transport_Equipment         Argentina  31.6 21.2976809
#> 16:           Germany         Agriculture            Turkey  23.8 20.3363108
#> 17:           Germany Textile_and_Leather            Turkey  20.7 17.1742484
#> 18:           Germany Transport_Equipment            Turkey  46.3 31.2051464
#>           DVA        VAX      VAXIM        REF         DDC         FC
#>         <num>      <num>      <num>      <num>       <num>      <num>
#>  1: 12.357451 11.1495220  8.6467883 1.20792920 0.206826787  1.4357220
#>  2:  5.172419  4.5941134  3.3363970 0.57830552 0.090248234  1.5373328
#>  3:  0.631643  0.5994267  0.5204712 0.03221630 0.004553866  0.2638032
#>  4: 16.976780 15.2571096 12.8017283 1.71967093 0.254229282  1.9689902
#>  5: 16.492276 14.0624444 10.6916234 2.42983148 0.301823747  4.9059004
#>  6:  1.186992  1.0694721  0.9062318 0.11752004 0.014713011  0.4982949
#>  7:  8.736465  8.2433496  7.5330947 0.49311499 0.222644951  1.7408905
#>  8:  9.616970  9.1484943  8.4243413 0.46847613 0.208997408  2.2740321
#>  9:  1.110273  1.0804233  1.0374013 0.02984949 0.010767873  0.4789594
#> 10: 28.549111 24.0661500 21.1873007 4.48296078 0.923847609  5.7270416
#> 11: 37.042781 30.4161318 25.8904388 6.62664940 1.205407773  8.8518110
#> 12:  4.769217  4.3868947  4.1249837 0.38232239 0.065270704  2.0655122
#> 13: 11.915655 10.4287782  9.9293481 1.48687667 0.815901115  2.1684441
#> 14:  8.240814  7.6235647  7.3729745 0.61724929 0.304826489  1.7543595
#> 15: 20.852668 19.8817549 19.4540442 0.97091322 0.445012839 10.3023191
#> 16: 19.622631 17.9073356 17.3509403 1.71529555 0.713679736  3.4636892
#> 17: 15.942630 12.9978655 12.0796413 2.94476411 1.231618843  3.5257516
#> 18: 30.268005 27.8798434 27.1400321 2.38816205 0.937140969 15.0948536
#>            FVA         FDC
#>          <num>       <num>
#>  1:  1.4120879 0.023634130
#>  2:  1.5109695 0.026363357
#>  3:  0.2619149 0.001888290
#>  4:  1.9399394 0.029050821
#>  5:  4.8177315 0.088168896
#>  6:  0.4921940 0.006100846
#>  7:  1.6976272 0.043263282
#>  8:  2.2256637 0.048368449
#>  9:  0.4743588 0.004600523
#> 10:  5.5475241 0.179517565
#> 11:  8.5728425 0.278968549
#> 12:  2.0376256 0.027886602
#> 13:  2.0294794 0.138964627
#> 14:  1.6917808 0.062578720
#> 15: 10.0870532 0.215265891
#> 16:  3.3421349 0.121554238
#> 17:  3.2729090 0.252842628
#> 18: 14.6415307 0.453322843

# Self (own-flow) perimeter, and the importer-perspective import decomposition
bm(dec, aggregation = "bilateral", perspective = "self")
#>     Exporting_Country  Exporting_Industry Importing_Country  GEXP         DC
#>                <fctr>              <fctr>            <fctr> <num>      <num>
#>  1:         Argentina         Agriculture            Turkey  14.0 12.5642780
#>  2:         Argentina Textile_and_Leather            Turkey   6.8  5.2626672
#>  3:         Argentina Transport_Equipment            Turkey   0.9  0.6361968
#>  4:         Argentina         Agriculture           Germany  19.2 17.2310098
#>  5:         Argentina Textile_and_Leather           Germany  21.7 16.7940996
#>  6:         Argentina Transport_Equipment           Germany   1.7  1.2017051
#>  7:            Turkey         Agriculture         Argentina  10.7  8.9591095
#>  8:            Turkey Textile_and_Leather         Argentina  12.1  9.8259679
#>  9:            Turkey Transport_Equipment         Argentina   1.6  1.1210406
#> 10:            Turkey         Agriculture           Germany  35.2 29.4729584
#> 11:            Turkey Textile_and_Leather           Germany  47.1 38.2481890
#> 12:            Turkey Transport_Equipment           Germany   6.9  4.8344878
#> 13:           Germany         Agriculture         Argentina  14.9 12.7315559
#> 14:           Germany Textile_and_Leather         Argentina  10.3  8.5456405
#> 15:           Germany Transport_Equipment         Argentina  31.6 21.2976809
#> 16:           Germany         Agriculture            Turkey  23.8 20.3363108
#> 17:           Germany Textile_and_Leather            Turkey  20.7 17.1742484
#> 18:           Germany Transport_Equipment            Turkey  46.3 31.2051464
#>            DVA        VAX        REF          DDC         FC        FVA
#>          <num>      <num>      <num>        <num>      <num>      <num>
#>  1: 12.5408413 11.3093443 1.23149696 0.0234366879  1.4357220  1.4330439
#>  2:  5.2474241  4.6594894 0.58793467 0.0152430467  1.5373328  1.5328800
#>  3:  0.6359948  0.6032297 0.03276518 0.0002019919  0.2638032  0.2637194
#>  4: 17.1754381 15.4311807 1.74425742 0.0555716402  1.9689902  1.9626401
#>  5: 16.6868841 14.2378939 2.44899022 0.1072155581  4.9059004  4.8745805
#>  6:  1.2005992  1.0814895 0.11910974 0.0011059286  0.4982949  0.4978363
#>  7:  8.9460790  8.4231507 0.52292827 0.0130305178  1.7408905  1.7383585
#>  8:  9.7972118  9.3017324 0.49547939 0.0287561155  2.2740321  2.2673771
#>  9:  1.1206087  1.0893588 0.03124996 0.0004319315  0.4789594  0.4787748
#> 10: 29.1787145 24.6186741 4.56004040 0.2942438143  5.7270416  5.6698656
#> 11: 37.8044783 31.0979346 6.70654362 0.4437107309  8.8518110  8.7491227
#> 12:  4.8256250  4.4354571 0.39016788 0.0088628304  2.0655122  2.0617256
#> 13: 12.6972319 11.1461149 1.55111705 0.0343240023  2.1684441  2.1625980
#> 14:  8.5262197  7.8844796 0.64174009 0.0194208287  1.7543595  1.7503725
#> 15: 21.1724475 20.1691229 1.00332460 0.1252334637 10.3023191 10.2417399
#> 16: 20.2439513 18.4771429 1.76680841 0.0923595022  3.4636892  3.4479584
#> 17: 17.0792118 14.0530011 3.02621073 0.0950365762  3.5257516  3.5062413
#> 18: 30.7980923 28.3662260 2.43186631 0.4070541417 15.0948536 14.8979494
#>              FDC
#>            <num>
#>  1: 2.678114e-03
#>  2: 4.452806e-03
#>  3: 8.375726e-05
#>  4: 6.350180e-03
#>  5: 3.131986e-02
#>  6: 4.585805e-04
#>  7: 2.532027e-03
#>  8: 6.655052e-03
#>  9: 1.845407e-04
#> 10: 5.717602e-02
#> 11: 1.026884e-01
#> 12: 3.786603e-03
#> 13: 5.846079e-03
#> 14: 3.986959e-03
#> 15: 6.057914e-02
#> 16: 1.573071e-02
#> 17: 1.951034e-02
#> 18: 1.969041e-01
bm(dec, flow = "imports")
#>    Importing_Country  GIMP        VA       DC
#>               <fctr> <num>     <num>    <num>
#> 1:         Argentina  81.2  79.63233 1.567672
#> 2:            Turkey 112.5 108.71967 3.780326
#> 3:           Germany 131.8 127.14834 4.651660
```
