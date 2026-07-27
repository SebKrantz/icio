# Global Value Chain Decomposition with icio

**icio** implements four gross-export decompositions from the Global
Value Chain (GVC) literature. All decompositions operate on an
inter-country input-output (ICIO) table and answer the question: *where
does the value added embodied in a country’s exports ultimately
originate?*

| Function | Reference | Level | Terms |
|----|----|----|---:|
| [`leontief()`](https://sebkrantz.github.io/icio/reference/leontief.md) | Hummels, Ishii & Yi (2001) | country-industry origin | continuous shares |
| [`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) | Koopman, Wang & Wei (2014) | country | 9 |
| [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) | Wang, Wei & Zhu (2013) | bilateral country-industry | 16 |
| [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) | Borin & Mancini (2019) | country / sector / bilateral | up to 13 |

[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) is the
recommended decomposition. Its world/sink perspective also provides a
corrected version of the biased KWW decomposition.

## The leather dataset

The package ships with `leather`, a minimal 3-country × 3-industry ICIO
table covering the leather GVC for Argentina, Turkey, and Germany.

``` r

library(icio)
data(leather)

leather$countries
#> [1] "Argentina" "Turkey"    "Germany"
leather$industries
#> [1] "Agriculture"         "Textile_and_Leather" "Transport_Equipment"

# Intermediate demand matrix (9 × 9)
leather$inter
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9]
#>  [1,] 16.1  5.1  1.8  3.2  4.3  0.4  3.1  2.8  4.9
#>  [2,]  2.4  8.0  3.2  0.1  3.2  1.6  1.2  3.9 11.5
#>  [3,]  0.9  0.5  4.0  0.0  0.1  0.3  0.0  0.4  0.5
#>  [4,]  1.1  1.9  0.2 18.0 13.2  6.1  9.0  3.1  8.9
#>  [5,]  0.3  2.8  0.1  6.1 28.1  6.3  2.1  2.5 25.6
#>  [6,]  0.0  0.1  0.3  4.1  3.2  8.9  0.2  0.0  1.8
#>  [7,]  1.2  4.2  0.3  4.1  1.2  0.6 29.0 19.5 17.9
#>  [8,]  1.3  1.1  0.0  3.2  4.8  2.6  5.1 29.1 24.1
#>  [9,]  2.1  1.4  3.0  4.1  3.1  3.9 11.3  8.1 51.3

# Final demand matrix (9 × 3)
leather$final
#>       [,1] [,2] [,3]
#>  [1,] 21.5  6.1  8.4
#>  [2,] 16.2  1.9  5.1
#>  [3,] 11.0  0.5  0.8
#>  [4,]  7.5 29.5 14.2
#>  [5,]  8.9 24.9 16.9
#>  [6,]  1.2 18.5  4.9
#>  [7,]  9.2 17.9 51.2
#>  [8,]  7.9 10.1 38.5
#>  [9,] 25.1 35.2 68.4

# Gross output vector (length 9)
leather$out
#> [1]  77.7  58.3  19.0 112.7 124.6  43.2 156.3 127.8 217.0
```

The rows and columns of `inter` and the rows of `final` are ordered by
country first, then industry — 9 country-industry combinations in total.

## Building an `icio` object

[`load_icio()`](https://sebkrantz.github.io/icio/reference/load_icio.md)
parses the raw ICIO matrices and pre-computes what the decompositions
need: the input coefficients `A`, the Leontief inverse `B`, the `G`
blocks `Lb` of the domestic Leontief inverse, value-added coefficients
`Vc`, final demand (`Y`, `Yd`, `Ym`) and exports (`E`, `ESR`). Only `A`
and `B` are dense `GN x GN` matrices; the masked and block-diagonal
variants the decompositions use are derived on the fly.

Inverting `(I - A)` is by far the most expensive step, so build the
object once and reuse it across decompositions.

``` r

x <- load_icio(leather)
class(x)
#> [1] "icio"
names(x)
#>  [1] "A"   "B"   "Lb"  "E"   "ESR" "Vc"  "G"   "N"   "GN"  "k"   "i"   "X"   "Y"   "Yd" 
#> [15] "Ym"
```

An `iot`-class list like `leather` is detected automatically;
equivalently you can pass the matrices directly as
`load_icio(inter, final, countries, industries)`. Tables in the CSV
format of the Stata `icio` command are read with
[`load_icio_csv()`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md).

The key scalars:

``` r

x$G  # number of countries
#> [1] 3
x$N  # number of industries
#> [1] 3
```

The value-added coefficient vector `Vc = v / o` gives the direct
value-added share of each country-industry’s gross output:

``` r

round(x$Vc, 3)
#>         Argentina.Agriculture Argentina.Textile_and_Leather Argentina.Transport_Equipment 
#>                         0.673                         0.569                         0.321 
#>            Turkey.Agriculture    Turkey.Textile_and_Leather    Turkey.Transport_Equipment 
#>                         0.619                         0.509                         0.289 
#>           Germany.Agriculture   Germany.Textile_and_Leather   Germany.Transport_Equipment 
#>                         0.610                         0.457                         0.325
```

Total exports by country-industry:

``` r

round(x$E, 2)
#>         Argentina.Agriculture Argentina.Textile_and_Leather Argentina.Transport_Equipment 
#>                          33.2                          28.5                           2.6 
#>            Turkey.Agriculture    Turkey.Textile_and_Leather    Turkey.Transport_Equipment 
#>                          45.9                          59.2                           8.5 
#>           Germany.Agriculture   Germany.Textile_and_Leather   Germany.Transport_Equipment 
#>                          38.7                          31.0                          77.9
```

## Leontief decomposition

[`leontief()`](https://sebkrantz.github.io/icio/reference/leontief.md)
pre-multiplies the Leontief inverse by the value-added coefficient
matrix and post-multiplies by exports. The result gives the value-added
origin (rows) of each exporting country-industry (columns).

``` r

leo <- leontief(x)
head(leo, 12)
#>     Source_Country     Source_Industry Using_Country      Using_Industry       FVAX
#>             <fctr>              <fctr>        <fctr>              <fctr>      <num>
#>  1:      Argentina         Agriculture     Argentina         Agriculture 28.5227814
#>  2:      Argentina         Agriculture     Argentina Textile_and_Leather  2.7939513
#>  3:      Argentina         Agriculture     Argentina Transport_Equipment  0.3560669
#>  4:      Argentina         Agriculture        Turkey         Agriculture  1.8106696
#>  5:      Argentina         Agriculture        Turkey Textile_and_Leather  3.1173841
#>  6:      Argentina         Agriculture        Turkey Transport_Equipment  0.3590113
#>  7:      Argentina         Agriculture       Germany         Agriculture  1.2364172
#>  8:      Argentina         Agriculture       Germany Textile_and_Leather  1.3028380
#>  9:      Argentina         Agriculture       Germany Transport_Equipment  4.1208736
#> 10:      Argentina Textile_and_Leather     Argentina         Agriculture  1.0620694
#> 11:      Argentina Textile_and_Leather     Argentina Textile_and_Leather 19.1205319
#> 12:      Argentina Textile_and_Leather     Argentina Transport_Equipment  0.4181392
```

Each row identifies a *source* country-industry, a *using*
country-industry, and the amount of value added from the source embodied
in the using sector’s exports. Setting `long = FALSE` returns the
underlying matrix directly.

## Koopman-Wang-Wei (KWW) decomposition

[`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) aggregates
to the country level and splits exports into 9 components: domestic
value added (DVA), foreign value added (FVA), and various
double-counting terms.

``` r

kww(x)
#>      Country  DVA_FIN  DVA_INT DVA_INTrex   RDV_FIN   RDV_INT       DDC   FVA_FIN
#>       <fctr>    <num>    <num>      <num>     <num>     <num>     <num>     <num>
#> 1: Argentina 19.34940 18.97119   8.411491  5.259501 0.8259724 0.8723949  3.450595
#> 2:    Turkey 43.39461 26.20678   7.740053 10.475795 2.0075781 2.6369363 10.205386
#> 3:   Germany 78.73101 15.23967   2.748464  5.689669 4.4335916 4.4481800 26.668992
#>     FVA_INT      FDC
#>       <num>    <num>
#> 1: 3.388617 3.770832
#> 2: 5.359698 5.573163
#> 3: 4.455024 5.185401
```

> **Note:** The KWW decomposition contains a known systematic bias — it
> underestimates foreign value added by conflating some of it with
> domestic double-counting. Use
> `bm(perspective = "world", approach = "sink")` for the Borin-Mancini
> correction (see below).

## Wang-Wei-Zhu (WWZ) decomposition

[`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) operates at
the bilateral country-industry level and decomposes exports into 16
value-added and double-counting terms by importing country.

``` r

wz <- wwz(x)
dim(wz)
#> [1] 27 29
names(wz)
#>  [1] "Exporting_Country"  "Exporting_Industry" "Importing_Country"  "DVA_FIN"           
#>  [5] "DVA_INT"            "DVA_INTrexI1"       "DVA_INTrexF"        "DVA_INTrexI2"      
#>  [9] "RDV_INT"            "RDV_FIN"            "RDV_FIN2"           "OVA_FIN"           
#> [13] "MVA_FIN"            "OVA_INT"            "MVA_INT"            "DDC_FIN"           
#> [17] "DDC_INT"            "ODC"                "MDC"                "texp"              
#> [21] "texpint"            "texpfd"             "texpdiff"           "texpdiffpercent"   
#> [25] "texpfddiff"         "texpfddiffpercent"  "texpintdiff"        "texpintdiffpercent"
#> [29] "DViX_Fsr"
```

The result is a long-format `data.table` with one row per (exporting
country-industry, importing country) pair and one column per term,
preceded by three identifier columns (`Exporting_Country`,
`Exporting_Industry`, `Importing_Country`). Columns beyond the 16
decomposition terms are accounting diagnostics (`texp`, `texpint`,
`texpfd`, etc.).

``` r

# DVA_FIN for all exporters into Germany
subset(wz, Importing_Country == "Germany",
       select = c(Exporting_Country, Exporting_Industry, DVA_FIN))
#>    Exporting_Country  Exporting_Industry    DVA_FIN
#>               <fctr>              <fctr>      <num>
#> 1:         Argentina         Agriculture  7.5385668
#> 2:         Argentina Textile_and_Leather  3.9470004
#> 3:         Argentina Transport_Equipment  0.5655083
#> 4:            Turkey         Agriculture 11.8896593
#> 5:            Turkey Textile_and_Leather 13.7238725
#> 6:            Turkey Transport_Equipment  3.4331870
#> 7:           Germany         Agriculture  0.0000000
#> 8:           Germany Textile_and_Leather  0.0000000
#> 9:           Germany Transport_Equipment  0.0000000
```

[`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md)
maps the 16-term result to the 9-term KWW format when both are needed:

``` r

wwz2kww(wz)
#>     Exporting_Country  Exporting_Industry Importing_Country    DVA_FIN    DVA_INT
#>                <fctr>              <fctr>            <fctr>      <num>      <num>
#>  1:         Argentina         Agriculture         Argentina  0.0000000  0.0000000
#>  2:         Argentina         Agriculture            Turkey  5.4744354  3.8177127
#>  3:         Argentina         Agriculture           Germany  7.5385668  5.5186109
#>  4:         Argentina Textile_and_Leather         Argentina  0.0000000  0.0000000
#>  5:         Argentina Textile_and_Leather            Turkey  1.4704511  2.1258430
#>  6:         Argentina Textile_and_Leather           Germany  3.9470004  6.9894309
#>  7:         Argentina Transport_Equipment         Argentina  0.0000000  0.0000000
#>  8:         Argentina Transport_Equipment            Turkey  0.3534427  0.1740197
#>  9:         Argentina Transport_Equipment           Germany  0.5655083  0.3455755
#> 10:            Turkey         Agriculture         Argentina  6.2797497  1.5433344
#> 11:            Turkey         Agriculture            Turkey  0.0000000  0.0000000
#> 12:            Turkey         Agriculture           Germany 11.8896593  9.6316330
#> 13:            Turkey Textile_and_Leather         Argentina  7.2273648  1.5079152
#> 14:            Turkey Textile_and_Leather            Turkey  0.0000000  0.0000000
#> 15:            Turkey Textile_and_Leather           Germany 13.7238725 12.6338776
#> 16:            Turkey Transport_Equipment         Argentina  0.8407805  0.2002353
#> 17:            Turkey Transport_Equipment            Turkey  0.0000000  0.0000000
#> 18:            Turkey Transport_Equipment           Germany  3.4331870  0.6897811
#> 19:           Germany         Agriculture         Argentina  7.8610949  2.3022565
#> 20:           Germany         Agriculture            Turkey 15.2949565  2.1766743
#> 21:           Germany         Agriculture           Germany  0.0000000  0.0000000
#> 22:           Germany Textile_and_Leather         Argentina  6.5544233  0.9105603
#> 23:           Germany Textile_and_Leather            Turkey  8.3797057  3.8771798
#> 24:           Germany Textile_and_Leather           Germany  0.0000000  0.0000000
#> 25:           Germany Transport_Equipment         Argentina 16.9168288  2.5557476
#> 26:           Germany Transport_Equipment            Turkey 23.7239990  3.4172517
#> 27:           Germany Transport_Equipment           Germany  0.0000000  0.0000000
#>     Exporting_Country  Exporting_Industry Importing_Country    DVA_FIN    DVA_INT
#>                <fctr>              <fctr>            <fctr>      <num>      <num>
#>     DVA_INTrex    RDV_FIN     RDV_INT        DDC    FVA_FIN    FVA_INT        FDC
#>          <num>      <num>       <num>      <num>      <num>      <num>      <num>
#>  1: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#>  2: 1.91423181 1.05270347 0.168614730 0.13657989  0.6255646 0.29795523 0.51220221
#>  3: 2.25638080 1.49085043 0.241349852 0.18525099  0.8614332 0.56826533 0.53929167
#>  4: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#>  5: 0.97828407 0.49764336 0.078969730 0.11147587  0.4295489 0.46604144 0.64174252
#>  6: 3.05664120 2.09237473 0.317887034 0.39076543  1.1529996 1.86007577 1.89282497
#>  7: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#>  8: 0.06316755 0.02665282 0.004631660 0.01428238  0.1465573 0.06372476 0.05352109
#>  9: 0.14278535 0.09927627 0.014519380 0.03404037  0.2344917 0.13255405 0.13124912
#> 10: 0.45133063 0.35653406 0.154036261 0.17412451  1.2202503 0.21802578 0.30261437
#> 11: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#> 12: 2.56760596 3.79670949 0.693923875 0.89342675  2.3103407 1.76685578 1.64984520
#> 13: 0.43629173 0.33247312 0.151185856 0.17073721  1.6726352 0.24266827 0.35872865
#> 14: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#> 15: 4.03417638 5.65394247 0.950059562 1.25226053  3.1761275 2.76149698 2.91418651
#> 16: 0.02727863 0.02065283 0.008562439 0.02353095  0.3592195 0.08088699 0.03885285
#> 17: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#> 18: 0.22337011 0.31548308 0.049810123 0.12285637  1.4668130 0.28976398 0.30893521
#> 19: 0.34078859 0.70328136 0.820750168 0.70338439  1.3389051 0.34277710 0.48676190
#> 20: 0.49276219 1.00222535 0.736949683 0.63274282  2.6050435 0.34681668 0.51182895
#> 21: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#> 22: 0.17961089 0.31779378 0.309465907 0.27378632  1.3455767 0.16256206 0.24622074
#> 23: 0.81073626 1.74521177 1.222414373 1.13900048  1.7202943 0.75356998 1.05188736
#> 24: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#> 25: 0.29897730 0.51188531 0.436904740 0.57733715  8.1831712 1.20835270 0.91079521
#> 26: 0.62558843 1.40927173 0.907106729 1.12192882 11.4760010 1.64094572 1.97790686
#> 27: 0.00000000 0.00000000 0.000000000 0.00000000  0.0000000 0.00000000 0.00000000
#>     DVA_INTrex    RDV_FIN     RDV_INT        DDC    FVA_FIN    FVA_INT        FDC
#>          <num>      <num>       <num>      <num>      <num>      <num>      <num>
```

## Borin-Mancini (BM) decomposition

[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) is the most
flexible decomposition. It supports three aggregation levels
(`"country"`, `"sector"`, `"bilateral"`) and two accounting perspectives
(`"exporter"` with 13 terms, or `"world"` with 9 terms).

### Country level (exporter perspective, 13 terms)

``` r

bm(x)
#>    Exporting_Country  GEXP        DC       DVA      VAX    DAVAX       REF       DDC
#>               <fctr> <num>     <num>     <num>    <num>    <num>     <num>     <num>
#> 1:         Argentina  64.3  53.68996  52.81756 46.73209 34.79877  6.085473 0.8723949
#> 2:            Turkey 113.6  92.46175  89.82482 77.34144 65.50360 12.483373 2.6369363
#> 3:           Germany 147.6 111.29058 106.84240 96.71914 89.31689 10.123261 4.4481800
#>          FC      FVA       FDC      GVC     GVCB     GVCF
#>       <num>    <num>     <num>    <num>    <num>    <num>
#> 1: 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 2: 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 3: 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551
```

The 13 terms break gross exports (`GEXP`) into domestic content (`DC`)
and foreign content (`FC`), and further into value-added and
double-counting components. GVC participation is measured by
`GVC = GEXP - DAVAX`, split into backward (`GVCB`) and forward (`GVCF`)
linkages.

### Sector level

``` r

bm(x, aggregation = "sector")
#>    Exporting_Country  Exporting_Industry  GEXP        DC       DVA       VAX     DAVAX
#>               <fctr>              <fctr> <num>     <num>     <num>     <num>     <num>
#> 1:         Argentina         Agriculture  33.2 29.795288 29.493900 26.540382 20.385155
#> 2:         Argentina Textile_and_Leather  28.5 22.056767 21.569374 18.582499 13.084653
#> 3:         Argentina Transport_Equipment   2.6  1.837902  1.754288  1.609208  1.328962
#> 4:            Turkey         Agriculture  45.9 38.432068 37.469257 32.468054 27.673077
#> 5:            Turkey Textile_and_Leather  59.2 48.074157 46.789941 39.702280 33.025635
#> 6:            Turkey Transport_Equipment   8.5  5.955528  5.565619  5.171110  4.804889
#> 7:           Germany         Agriculture  38.7 33.067867 32.402844 29.139637 26.657741
#> 8:           Germany Textile_and_Leather  31.0 25.719889 25.082406 21.487520 18.915931
#> 9:           Germany Transport_Equipment  77.9 52.502827 49.357153 46.091985 43.743217
#>          REF        DDC        FC        FVA        FDC       GVC       GVCB      GVCF
#>        <num>      <num>     <num>      <num>      <num>     <num>      <num>     <num>
#> 1: 2.9535185 0.30138767  3.404712  3.3423229 0.06238937 12.814845  3.7060999  9.108745
#> 2: 2.9868748 0.48739312  6.443233  6.3486717 0.09456147 15.415347  6.9306263  8.484721
#> 3: 0.1450801 0.08361414  0.762098  0.7438425 0.01825550  1.271038  0.8457122  0.425326
#> 4: 5.0012037 0.96281049  7.467932  7.2556717 0.21226046 18.226923  8.4307426  9.796180
#> 5: 7.0876610 1.28421633 11.125843 10.8426216 0.28322154 26.174365 12.4100595 13.764306
#> 6: 0.3945085 0.38990949  2.544472  2.4573486 0.08712297  3.695111  2.9343811  0.760730
#> 7: 3.2632066 0.66502295  5.632133  5.4445468 0.18758643 12.042259  6.2971562  5.745103
#> 8: 3.5948858 0.63748284  5.280111  5.1021480 0.17796309 12.084069  5.9175939  6.166475
#> 9: 3.2651685 3.14567421 25.397173 24.5181932 0.87897942 34.156783 28.5428469  5.613936
```

### Bilateral sector level

``` r

bm(x, aggregation = "bilateral")
#>     Exporting_Country  Exporting_Industry Importing_Country  GEXP         DC        DVA
#>                <fctr>              <fctr>            <fctr> <num>      <num>      <num>
#>  1:            Turkey         Agriculture         Argentina  10.7  8.9591095  8.7346635
#>  2:            Turkey Textile_and_Leather         Argentina  12.1  9.8259679  9.5634845
#>  3:            Turkey Transport_Equipment         Argentina   1.6  1.1210406  1.0476459
#>  4:           Germany         Agriculture         Argentina  14.9 12.7315559 12.4755135
#>  5:           Germany Textile_and_Leather         Argentina  10.3  8.5456405  8.3338317
#>  6:           Germany Transport_Equipment         Argentina  31.6 21.2976809 20.0216436
#>  7:         Argentina         Agriculture            Turkey  14.0 12.5642780 12.4371868
#>  8:         Argentina Textile_and_Leather            Turkey   6.8  5.2626672  5.1463769
#>  9:         Argentina Transport_Equipment            Turkey   0.9  0.6361968  0.6072535
#> 10:           Germany         Agriculture            Turkey  23.8 20.3363108 19.9273303
#> 11:           Germany Textile_and_Leather            Turkey  20.7 17.1742484 16.7485744
#> 12:           Germany Transport_Equipment            Turkey  46.3 31.2051464 29.3355095
#> 13:         Argentina         Agriculture           Germany  19.2 17.2310098 17.0567133
#> 14:         Argentina Textile_and_Leather           Germany  21.7 16.7940996 16.4229968
#> 15:         Argentina Transport_Equipment           Germany   1.7  1.2017051  1.1470343
#> 16:            Turkey         Agriculture           Germany  35.2 29.4729584 28.7345939
#> 17:            Turkey Textile_and_Leather           Germany  47.1 38.2481890 37.2264561
#> 18:            Turkey Transport_Equipment           Germany   6.9  4.8344878  4.5179730
#>           VAX      DAVAX        REF        DDC         FC        FVA         FDC
#>         <num>      <num>      <num>      <num>      <num>      <num>       <num>
#>  1:  8.224093  7.2163401 0.51057032 0.22444602  1.7408905  1.6914093 0.049481197
#>  2:  9.079825  8.0548444 0.48365898 0.26248341  2.2740321  2.2161439 0.057888186
#>  3:  1.018431  0.9626616 0.02921527 0.07339473  0.4789594  0.4625597 0.016399618
#>  4: 10.951482  9.6750702 1.52403152 0.25604243  2.1684441  2.0962209 0.072223200
#>  5:  7.706572  7.1641956 0.62725969 0.21180881  1.7543595  1.6952298 0.059129673
#>  6: 19.072854 18.2515939 0.94879005 1.27603729 10.3023191  9.9457626 0.356556480
#>  7: 11.215869  8.0001479 1.22131820 0.12709119  1.4357220  1.4094133 0.026308772
#>  8:  4.569764  2.9980790 0.57661309 0.11629029  1.5373328  1.5147708 0.022562035
#>  9:  0.575969  0.4840523 0.03128448 0.02894336  0.2638032  0.2574840 0.006319211
#> 10: 18.188155 16.9826710 1.73917503 0.40898052  3.4636892  3.3483259 0.115363232
#> 11: 13.780948 11.7517352 2.96762614 0.42567402  3.5257516  3.4069182 0.118833420
#> 12: 27.019131 25.4916229 2.31637845 1.86963692 15.0948536 14.5724306 0.522422944
#> 13: 15.324513 12.3850073 1.73220028 0.17429648  1.9689902  1.9329096 0.036080601
#> 14: 14.012735 10.0865741 2.41026176 0.37110283  4.9059004  4.8339009 0.071999434
#> 15:  1.033239  0.8449095 0.11379565 0.05467078  0.4982949  0.4863586 0.011936287
#> 16: 24.243961 20.4567369 4.49063336 0.73836447  5.7270416  5.5642624 0.162779264
#> 17: 30.622454 24.9707904 6.60400204 1.02173293  8.8518110  8.6264777 0.225333351
#> 18:  4.152680  3.8422274 0.36529320 0.31651476  2.0655122  1.9947889 0.070723354
#>            GVC       GVCB       GVCF
#>          <num>      <num>      <num>
#>  1:  3.4836599  1.9653365  1.5183234
#>  2:  4.0451556  2.5365155  1.5086400
#>  3:  0.6373384  0.5523541  0.0849843
#>  4:  5.2249298  2.4244865  2.8004433
#>  5:  3.1358044  1.9661683  1.1696361
#>  6: 13.3484061 11.5783564  1.7700497
#>  7:  5.9998521  1.5628132  4.4370389
#>  8:  3.8019210  1.6536231  2.1482979
#>  9:  0.4159477  0.2927465  0.1232012
#> 10:  6.8173290  3.8726697  2.9446593
#> 11:  8.9482648  3.9514256  4.9968392
#> 12: 20.8083771 16.9644905  3.8438866
#> 13:  6.8149927  2.1432867  4.6717060
#> 14: 11.6134259  5.2770032  6.3364227
#> 15:  0.8550905  0.5529657  0.3021248
#> 16: 14.7432631  6.4654061  8.2778570
#> 17: 22.1292096  9.8735439 12.2556656
#> 18:  3.0577726  2.3820270  0.6757457
```

The bilateral result contains one row per (exporting country-industry,
importing country) pair, excluding within-country flows. Country- and
sector-level results are additive aggregations of this table.

### Corrected KWW (world perspective, 9 terms)

The world/sink perspective implements the Borin-Mancini correction to
the biased KWW decomposition. It is only available at the country level.

``` r

bm(x, perspective = "world", approach = "sink")
#>    Exporting_Country  GEXP        DC       DVA      VAX       REF       DDC       FC
#>               <fctr> <num>     <num>     <num>    <num>     <num>     <num>    <num>
#> 1:         Argentina  64.3  53.68996  52.81756 46.73209  6.085473 0.8723949 10.61004
#> 2:            Turkey 113.6  92.46175  89.82482 77.34144 12.483373 2.6369363 21.13825
#> 3:           Germany 147.6 111.29058 106.84240 96.71914 10.123261 4.4481800 36.30942
#>          FVA      FDC
#>        <num>    <num>
#> 1:  8.471827 2.138217
#> 2: 18.265189 2.873058
#> 3: 33.128506 3.180911
```

Comparing to
[`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) above,
`FVA` increases and `DDC` decreases accordingly.

### WWZ vs. BM (exporter/source): different perimeters

WWZ and BM (exporter/source) both decompose bilateral exports into
value-added and double-counting components, but they disagree on what
“double-counted” means — and that choice shapes which questions each
method can answer.

WWZ uses a *bilateral* perimeter: an item is double-counted only if it
crosses the same s→r border more than once. Compared to BM, this is
looser, so some items that BM classifies as double-counted appear as
value-added in WWZ. This makes WWZ well-suited to questions about the
GDP content of a specific trade flow — tariff incidence, bilateral trade
balances — but the tradeoff is that WWZ results do not add up: summing
bilateral terms over all importers does not recover a sensible
country-level total. WWZ also conflates source-based and sink-based
approaches within the same decomposition, so its terms are not on the
same accounting footing and GVC indicators such as DAVAX cannot be
computed from the output.

BM (exporter/source) uses the *exporting country* as the perimeter: an
item is double-counted the second time it crosses country s’s border,
wherever it goes. One approach throughout, so all 13 terms are
comparable. Bilateral results sum to sector totals, sector totals to
country totals — and DAVAX, GVC-related trade, and backward/forward
participation shares all come out of the same calculation. For most
country- or sector-level work, BM (exporter/source) is the natural
choice; reach for WWZ when the question is specifically about what
crosses a particular bilateral border.

## Convenience interface

[`decomp()`](https://sebkrantz.github.io/icio/reference/decomp.md) is a
single entry point for all methods, dispatching on `method` (default
`"bm"`) and passing `...` on to the decomposition function:

``` r

decomp(x, method = "leontief")
#>     Source_Country     Source_Industry Using_Country      Using_Industry        FVAX
#>             <fctr>              <fctr>        <fctr>              <fctr>       <num>
#>  1:      Argentina         Agriculture     Argentina         Agriculture 28.52278143
#>  2:      Argentina         Agriculture     Argentina Textile_and_Leather  2.79395126
#>  3:      Argentina         Agriculture     Argentina Transport_Equipment  0.35606694
#>  4:      Argentina         Agriculture        Turkey         Agriculture  1.81066955
#>  5:      Argentina         Agriculture        Turkey Textile_and_Leather  3.11738415
#>  6:      Argentina         Agriculture        Turkey Transport_Equipment  0.35901126
#>  7:      Argentina         Agriculture       Germany         Agriculture  1.23641723
#>  8:      Argentina         Agriculture       Germany Textile_and_Leather  1.30283802
#>  9:      Argentina         Agriculture       Germany Transport_Equipment  4.12087363
#> 10:      Argentina Textile_and_Leather     Argentina         Agriculture  1.06206936
#> 11:      Argentina Textile_and_Leather     Argentina Textile_and_Leather 19.12053186
#> 12:      Argentina Textile_and_Leather     Argentina Transport_Equipment  0.41813924
#> 13:      Argentina Textile_and_Leather        Turkey         Agriculture  0.48370042
#> 14:      Argentina Textile_and_Leather        Turkey Textile_and_Leather  1.83290239
#> 15:      Argentina Textile_and_Leather        Turkey Transport_Equipment  0.43058635
#> 16:      Argentina Textile_and_Leather       Germany         Agriculture  0.59370415
#> 17:      Argentina Textile_and_Leather       Germany Textile_and_Leather  1.15375958
#> 18:      Argentina Textile_and_Leather       Germany Transport_Equipment  4.74903511
#> 19:      Argentina Transport_Equipment     Argentina         Agriculture  0.21043693
#> 20:      Argentina Transport_Equipment     Argentina Textile_and_Leather  0.14228369
#> 21:      Argentina Transport_Equipment     Argentina Transport_Equipment  1.06369578
#> 22:      Argentina Transport_Equipment        Turkey         Agriculture  0.03329456
#> 23:      Argentina Transport_Equipment        Turkey Textile_and_Leather  0.07905450
#> 24:      Argentina Transport_Equipment        Turkey Transport_Equipment  0.04024626
#> 25:      Argentina Transport_Equipment       Germany         Agriculture  0.02318460
#> 26:      Argentina Transport_Equipment       Germany Textile_and_Leather  0.07482343
#> 27:      Argentina Transport_Equipment       Germany Transport_Equipment  0.19326212
#> 28:         Turkey         Agriculture     Argentina         Agriculture  0.71952151
#> 29:         Turkey         Agriculture     Argentina Textile_and_Leather  1.34237213
#> 30:         Turkey         Agriculture     Argentina Transport_Equipment  0.11504126
#> 31:         Turkey         Agriculture        Turkey         Agriculture 34.92704803
#> 32:         Turkey         Agriculture        Turkey Textile_and_Leather  6.99949698
#> 33:         Turkey         Agriculture        Turkey Transport_Equipment  1.47711579
#> 34:         Turkey         Agriculture       Germany         Agriculture  2.55430885
#> 35:         Turkey         Agriculture       Germany Textile_and_Leather  1.52213499
#> 36:         Turkey         Agriculture       Germany Transport_Equipment  6.18062537
#> 37:         Turkey Textile_and_Leather     Argentina         Agriculture  0.41201175
#> 38:         Turkey Textile_and_Leather     Argentina Textile_and_Leather  1.38523849
#> 39:         Turkey Textile_and_Leather     Argentina Transport_Equipment  0.11764036
#> 40:         Turkey Textile_and_Leather        Turkey         Agriculture  2.69291816
#> 41:         Turkey Textile_and_Leather        Turkey Textile_and_Leather 40.16714096
#> 42:         Turkey Textile_and_Leather        Turkey Transport_Equipment  1.31799873
#> 43:         Turkey Textile_and_Leather       Germany         Agriculture  1.10939926
#> 44:         Turkey Textile_and_Leather       Germany Textile_and_Leather  1.15207241
#> 45:         Turkey Textile_and_Leather       Germany Transport_Equipment  9.50690317
#> 46:         Turkey Transport_Equipment     Argentina         Agriculture  0.03482652
#> 47:         Turkey Transport_Equipment     Argentina Textile_and_Leather  0.08553139
#> 48:         Turkey Transport_Equipment     Argentina Transport_Equipment  0.02667530
#> 49:         Turkey Transport_Equipment        Turkey         Agriculture  0.81210167
#> 50:         Turkey Transport_Equipment        Turkey Textile_and_Leather  0.90751892
#> 51:         Turkey Transport_Equipment        Turkey Transport_Equipment  3.16041392
#> 52:         Turkey Transport_Equipment       Germany         Agriculture  0.11511911
#> 53:         Turkey Transport_Equipment       Germany Textile_and_Leather  0.07448266
#> 54:         Turkey Transport_Equipment       Germany Transport_Equipment  0.64647326
#> 55:        Germany         Agriculture     Argentina         Agriculture  0.92530356
#> 56:        Germany         Agriculture     Argentina Textile_and_Leather  2.25142713
#> 57:        Germany         Agriculture     Argentina Transport_Equipment  0.16222512
#> 58:        Germany         Agriculture        Turkey         Agriculture  2.31122022
#> 59:        Germany         Agriculture        Turkey Textile_and_Leather  2.05958253
#> 60:        Germany         Agriculture        Turkey Transport_Equipment  0.51211484
#> 61:        Germany         Agriculture       Germany         Agriculture 29.87633590
#> 62:        Germany         Agriculture       Germany Textile_and_Leather  5.24719728
#> 63:        Germany         Agriculture       Germany Transport_Equipment  9.60069308
#> 64:        Germany Textile_and_Leather     Argentina         Agriculture  0.64666560
#> 65:        Germany Textile_and_Leather     Argentina Textile_and_Leather  0.72785683
#> 66:        Germany Textile_and_Leather     Argentina Transport_Equipment  0.08244379
#> 67:        Germany Textile_and_Leather        Turkey         Agriculture  1.53837777
#> 68:        Germany Textile_and_Leather        Turkey Textile_and_Leather  2.54889673
#> 69:        Germany Textile_and_Leather        Turkey Transport_Equipment  0.63316614
#> 70:        Germany Textile_and_Leather       Germany         Agriculture  1.45935830
#> 71:        Germany Textile_and_Leather       Germany Textile_and_Leather 18.95868110
#> 72:        Germany Textile_and_Leather       Germany Transport_Equipment  8.15831503
#> 73:        Germany Transport_Equipment     Argentina         Agriculture  0.66638333
#> 74:        Germany Transport_Equipment     Argentina Textile_and_Leather  0.65080723
#> 75:        Germany Transport_Equipment     Argentina Transport_Equipment  0.25807221
#> 76:        Germany Transport_Equipment        Turkey         Agriculture  1.29066963
#> 77:        Germany Transport_Equipment        Turkey Textile_and_Leather  1.48802285
#> 78:        Germany Transport_Equipment        Turkey Transport_Equipment  0.56934671
#> 79:        Germany Transport_Equipment       Germany         Agriculture  1.73217260
#> 80:        Germany Transport_Equipment       Germany Textile_and_Leather  1.51401054
#> 81:        Germany Transport_Equipment       Germany Transport_Equipment 34.74381924
#>     Source_Country     Source_Industry Using_Country      Using_Industry        FVAX
#>             <fctr>              <fctr>        <fctr>              <fctr>       <num>
decomp(x, aggregation = "sector")
#>    Exporting_Country  Exporting_Industry  GEXP        DC       DVA       VAX     DAVAX
#>               <fctr>              <fctr> <num>     <num>     <num>     <num>     <num>
#> 1:         Argentina         Agriculture  33.2 29.795288 29.493900 26.540382 20.385155
#> 2:         Argentina Textile_and_Leather  28.5 22.056767 21.569374 18.582499 13.084653
#> 3:         Argentina Transport_Equipment   2.6  1.837902  1.754288  1.609208  1.328962
#> 4:            Turkey         Agriculture  45.9 38.432068 37.469257 32.468054 27.673077
#> 5:            Turkey Textile_and_Leather  59.2 48.074157 46.789941 39.702280 33.025635
#> 6:            Turkey Transport_Equipment   8.5  5.955528  5.565619  5.171110  4.804889
#> 7:           Germany         Agriculture  38.7 33.067867 32.402844 29.139637 26.657741
#> 8:           Germany Textile_and_Leather  31.0 25.719889 25.082406 21.487520 18.915931
#> 9:           Germany Transport_Equipment  77.9 52.502827 49.357153 46.091985 43.743217
#>          REF        DDC        FC        FVA        FDC       GVC       GVCB      GVCF
#>        <num>      <num>     <num>      <num>      <num>     <num>      <num>     <num>
#> 1: 2.9535185 0.30138767  3.404712  3.3423229 0.06238937 12.814845  3.7060999  9.108745
#> 2: 2.9868748 0.48739312  6.443233  6.3486717 0.09456147 15.415347  6.9306263  8.484721
#> 3: 0.1450801 0.08361414  0.762098  0.7438425 0.01825550  1.271038  0.8457122  0.425326
#> 4: 5.0012037 0.96281049  7.467932  7.2556717 0.21226046 18.226923  8.4307426  9.796180
#> 5: 7.0876610 1.28421633 11.125843 10.8426216 0.28322154 26.174365 12.4100595 13.764306
#> 6: 0.3945085 0.38990949  2.544472  2.4573486 0.08712297  3.695111  2.9343811  0.760730
#> 7: 3.2632066 0.66502295  5.632133  5.4445468 0.18758643 12.042259  6.2971562  5.745103
#> 8: 3.5948858 0.63748284  5.280111  5.1021480 0.17796309 12.084069  5.9175939  6.166475
#> 9: 3.2651685 3.14567421 25.397173 24.5181932 0.87897942 34.156783 28.5428469  5.613936
```

Given a list of `icio` objects — typically one ICIO table per year — it
runs the decomposition on each and stacks the results, prepending an
identifier column:

``` r

decomp(list(`2015` = x, `2016` = x), idcol = "Year")
#>      Year Exporting_Country  GEXP        DC       DVA      VAX    DAVAX       REF
#>    <char>            <fctr> <num>     <num>     <num>    <num>    <num>     <num>
#> 1:   2015         Argentina  64.3  53.68996  52.81756 46.73209 34.79877  6.085473
#> 2:   2015            Turkey 113.6  92.46175  89.82482 77.34144 65.50360 12.483373
#> 3:   2015           Germany 147.6 111.29058 106.84240 96.71914 89.31689 10.123261
#> 4:   2016         Argentina  64.3  53.68996  52.81756 46.73209 34.79877  6.085473
#> 5:   2016            Turkey 113.6  92.46175  89.82482 77.34144 65.50360 12.483373
#> 6:   2016           Germany 147.6 111.29058 106.84240 96.71914 89.31689 10.123261
#>          DDC       FC      FVA       FDC      GVC     GVCB     GVCF
#>        <num>    <num>    <num>     <num>    <num>    <num>    <num>
#> 1: 0.8723949 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 2: 2.6369363 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 3: 4.4481800 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551
#> 4: 0.8723949 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 5: 2.6369363 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 6: 4.4481800 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551
```

## Output format

All decompositions return a `data.table`, so column selection follows
data.table rules: `d$GEXP` and `d[["GEXP"]]` work as usual, but
`d[, "GEXP"]` returns a one-column table rather than a vector, and
`d[c("GEXP", "DVA")]` is a join, not a column subset — use
`d[, .(GEXP, DVA)]` or `as.data.frame(d)` if you want base-R semantics.

## References

Borin, A., & Mancini, M. (2019). Measuring what matters in global value
chains and value-added trade. *World Bank Policy Research Working Paper
8804*.

Koopman, R., Wang, Z., & Wei, S.-J. (2014). Tracing value-added and
double counting in gross exports. *American Economic Review, 104*(2),
459–494.

Wang, Z., Wei, S.-J., & Zhu, K. (2013). *Quantifying international
production sharing at the bilateral and sector levels*. NBER Working
Paper 19677.

Hummels, D., Ishii, J., & Yi, K.-M. (2001). The nature and growth of
vertical specialization in world trade. *Journal of International
Economics, 54*(1), 75–96.
