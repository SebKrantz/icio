# Run a GVC Decomposition

A compact interface to the four decompositions: it dispatches on
`method` and, given a list of 'icio' objects (e.g. one per year), runs
the decomposition on each and stacks the results.

## Usage

``` r
decomp(x, method = c("bm", "leontief", "kww", "wwz"), ..., idcol = "Label")
```

## Arguments

- x:

  an 'icio' class object from
  [`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)
  or
  [`load_icio_csv`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md),
  or a (preferably named) list of such objects, e.g. one ICIO table per
  year.

- method:

  character. The decomposition method: `"bm"` (the default and
  recommended method, see
  [`bm`](https://sebkrantz.github.io/icio/reference/bm.md)),
  `"leontief"`, `"kww"` or `"wwz"`.

- ...:

  further arguments passed to
  [`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
  [`leontief`](https://sebkrantz.github.io/icio/reference/leontief.md),
  [`kww`](https://sebkrantz.github.io/icio/reference/kww.md) or
  [`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md).

- idcol:

  character. Only used if `x` is a list: the name of the identifier
  column prepended to the stacked result. It holds the names of `x`, or
  the list indices if `x` is unnamed. Set to `NULL` to omit it.

## Value

A `data.table` - see
[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`leontief`](https://sebkrantz.github.io/icio/reference/leontief.md),
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md) or
[`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md) for the
columns of each decomposition. If `x` is a list, the results are stacked
with [`rbindlist`](https://rdrr.io/pkg/data.table/man/rbindlist.html)
and prefixed with `idcol`.

## Details

Building an 'icio' object is by far the most expensive step (it involves
inverting a `GN x GN` matrix), so it is done once by
[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md)
and reused across decompositions. Pass the object to
[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`leontief`](https://sebkrantz.github.io/icio/reference/leontief.md),
[`kww`](https://sebkrantz.github.io/icio/reference/kww.md) or
[`wwz`](https://sebkrantz.github.io/icio/reference/wwz.md) directly if
you prefer.

## References

Hummels, D., Ishii, J., & Yi, K. M. (2001). The nature and growth of
vertical specialization in world trade. *Journal of international
Economics, 54*(1), 75-96.

Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and
double counting in gross exports. *American Economic Review, 104*(2),
459-94.

Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying
international production sharing at the bilateral and sector levels (No.
w19677). *National Bureau of Economic Research*.

Borin, A., & Mancini, M. (2019). Measuring What Matters in Global Value
Chains and Value-Added Trade. *World Bank Policy Research Working Paper
8804*.

## See also

[`load_icio`](https://sebkrantz.github.io/icio/reference/load_icio.md),
[`bm`](https://sebkrantz.github.io/icio/reference/bm.md),
[`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)

## Author

Sebastian Krantz, Bastiaan Quast

## Examples

``` r
# Load leather example data
data(leather)

# Explore the data
str(leather)
#> List of 5
#>  $ inter     : num [1:9, 1:9] 16.1 2.4 0.9 1.1 0.3 0 1.2 1.3 2.1 5.1 ...
#>  $ final     : num [1:9, 1:3] 21.5 16.2 11 7.5 8.9 1.2 9.2 7.9 25.1 6.1 ...
#>  $ countries : chr [1:3] "Argentina" "Turkey" "Germany"
#>  $ industries: chr [1:3] "Agriculture" "Textile_and_Leather" "Transport_Equipment"
#>  $ out       : num [1:9] 77.7 58.3 19 112.7 124.6 ...
#>  - attr(*, "class")= chr "iot"

# Create the 'icio' object
m <- load_icio(leather)

## Decomposing gross exports:

# Borin-Mancini (2019), the recommended method
decomp(m)
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
decomp(m, aggregation = "bilateral")
#>     Exporting_Country  Exporting_Industry Importing_Country  GEXP         DC
#>                <fctr>              <fctr>            <fctr> <num>      <num>
#>  1:            Turkey         Agriculture         Argentina  10.7  8.9591095
#>  2:            Turkey Textile_and_Leather         Argentina  12.1  9.8259679
#>  3:            Turkey Transport_Equipment         Argentina   1.6  1.1210406
#>  4:           Germany         Agriculture         Argentina  14.9 12.7315559
#>  5:           Germany Textile_and_Leather         Argentina  10.3  8.5456405
#>  6:           Germany Transport_Equipment         Argentina  31.6 21.2976809
#>  7:         Argentina         Agriculture            Turkey  14.0 12.5642780
#>  8:         Argentina Textile_and_Leather            Turkey   6.8  5.2626672
#>  9:         Argentina Transport_Equipment            Turkey   0.9  0.6361968
#> 10:           Germany         Agriculture            Turkey  23.8 20.3363108
#> 11:           Germany Textile_and_Leather            Turkey  20.7 17.1742484
#> 12:           Germany Transport_Equipment            Turkey  46.3 31.2051464
#> 13:         Argentina         Agriculture           Germany  19.2 17.2310098
#> 14:         Argentina Textile_and_Leather           Germany  21.7 16.7940996
#> 15:         Argentina Transport_Equipment           Germany   1.7  1.2017051
#> 16:            Turkey         Agriculture           Germany  35.2 29.4729584
#> 17:            Turkey Textile_and_Leather           Germany  47.1 38.2481890
#> 18:            Turkey Transport_Equipment           Germany   6.9  4.8344878
#>            DVA       VAX      DAVAX        REF        DDC         FC        FVA
#>          <num>     <num>      <num>      <num>      <num>      <num>      <num>
#>  1:  8.7346635  8.224093  7.2163401 0.51057032 0.22444602  1.7408905  1.6914093
#>  2:  9.5634845  9.079825  8.0548444 0.48365898 0.26248341  2.2740321  2.2161439
#>  3:  1.0476459  1.018431  0.9626616 0.02921527 0.07339473  0.4789594  0.4625597
#>  4: 12.4755135 10.951482  9.6750702 1.52403152 0.25604243  2.1684441  2.0962209
#>  5:  8.3338317  7.706572  7.1641956 0.62725969 0.21180881  1.7543595  1.6952298
#>  6: 20.0216436 19.072854 18.2515939 0.94879005 1.27603729 10.3023191  9.9457626
#>  7: 12.4371868 11.215869  8.0001479 1.22131820 0.12709119  1.4357220  1.4094133
#>  8:  5.1463769  4.569764  2.9980790 0.57661309 0.11629029  1.5373328  1.5147708
#>  9:  0.6072535  0.575969  0.4840523 0.03128448 0.02894336  0.2638032  0.2574840
#> 10: 19.9273303 18.188155 16.9826710 1.73917503 0.40898052  3.4636892  3.3483259
#> 11: 16.7485744 13.780948 11.7517352 2.96762614 0.42567402  3.5257516  3.4069182
#> 12: 29.3355095 27.019131 25.4916229 2.31637845 1.86963692 15.0948536 14.5724306
#> 13: 17.0567133 15.324513 12.3850073 1.73220028 0.17429648  1.9689902  1.9329096
#> 14: 16.4229968 14.012735 10.0865741 2.41026176 0.37110283  4.9059004  4.8339009
#> 15:  1.1470343  1.033239  0.8449095 0.11379565 0.05467078  0.4982949  0.4863586
#> 16: 28.7345939 24.243961 20.4567369 4.49063336 0.73836447  5.7270416  5.5642624
#> 17: 37.2264561 30.622454 24.9707904 6.60400204 1.02173293  8.8518110  8.6264777
#> 18:  4.5179730  4.152680  3.8422274 0.36529320 0.31651476  2.0655122  1.9947889
#>             FDC        GVC       GVCB       GVCF
#>           <num>      <num>      <num>      <num>
#>  1: 0.049481197  3.4836599  1.9653365  1.5183234
#>  2: 0.057888186  4.0451556  2.5365155  1.5086400
#>  3: 0.016399618  0.6373384  0.5523541  0.0849843
#>  4: 0.072223200  5.2249298  2.4244865  2.8004433
#>  5: 0.059129673  3.1358044  1.9661683  1.1696361
#>  6: 0.356556480 13.3484061 11.5783564  1.7700497
#>  7: 0.026308772  5.9998521  1.5628132  4.4370389
#>  8: 0.022562035  3.8019210  1.6536231  2.1482979
#>  9: 0.006319211  0.4159477  0.2927465  0.1232012
#> 10: 0.115363232  6.8173290  3.8726697  2.9446593
#> 11: 0.118833420  8.9482648  3.9514256  4.9968392
#> 12: 0.522422944 20.8083771 16.9644905  3.8438866
#> 13: 0.036080601  6.8149927  2.1432867  4.6717060
#> 14: 0.071999434 11.6134259  5.2770032  6.3364227
#> 15: 0.011936287  0.8550905  0.5529657  0.3021248
#> 16: 0.162779264 14.7432631  6.4654061  8.2778570
#> 17: 0.225333351 22.1292096  9.8735439 12.2556656
#> 18: 0.070723354  3.0577726  2.3820270  0.6757457

# Leontief, Koopman-Wang-Wei and Wang-Wei-Zhu
decomp(m, method = "leontief")
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
decomp(m, method = "kww")
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
decomp(m, method = "wwz")
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

# Multiple tables at once, e.g. one per year, stacked with a 'Year' column
decomp(list(`2015` = m, `2016` = m), idcol = "Year")
#>      Year Exporting_Country  GEXP        DC       DVA      VAX    DAVAX
#>    <char>            <fctr> <num>     <num>     <num>    <num>    <num>
#> 1:   2015         Argentina  64.3  53.68996  52.81756 46.73209 34.79877
#> 2:   2015            Turkey 113.6  92.46175  89.82482 77.34144 65.50360
#> 3:   2015           Germany 147.6 111.29058 106.84240 96.71914 89.31689
#> 4:   2016         Argentina  64.3  53.68996  52.81756 46.73209 34.79877
#> 5:   2016            Turkey 113.6  92.46175  89.82482 77.34144 65.50360
#> 6:   2016           Germany 147.6 111.29058 106.84240 96.71914 89.31689
#>          REF       DDC       FC      FVA       FDC      GVC     GVCB     GVCF
#>        <num>     <num>    <num>    <num>     <num>    <num>    <num>    <num>
#> 1:  6.085473 0.8723949 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 2: 12.483373 2.6369363 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 3: 10.123261 4.4481800 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551
#> 4:  6.085473 0.8723949 10.61004 10.43484 0.1752063 29.50123 11.48244 18.01879
#> 5: 12.483373 2.6369363 21.13825 20.55564 0.5826050 48.09640 23.77518 24.32122
#> 6: 10.123261 4.4481800 36.30942 35.06489 1.2445289 58.28311 40.75760 17.52551
```
