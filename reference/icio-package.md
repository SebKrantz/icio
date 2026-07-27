# Global Value Chain Decomposition of Inter-Country Input-Output Tables

Four global value chain (GVC) decompositions are implemented. The
Leontief decomposition derives the value added origin of exports by
country and industry as in Hummels, Ishii and Yi (2001). The Koopman,
Wang and Wei (2014) decomposition splits country-level exports into 9
value added components, and the Wang, Wei and Zhu (2013) decomposition
splits bilateral exports into 16 value added components. The Borin and
Mancini (2019) decomposition splits country-, sector- or bilateral-level
exports into up to 13 value added and GVC components, and also provides
a corrected version of the (biased) KWW decomposition. It is the
recommended method and reproduces the Stata `icio` command.

## Contents

Functions to load an ICIO table and create an 'icio' object

[`load_icio()`](https://sebkrantz.github.io/icio/reference/load_icio.md)  
[`load_icio_csv()`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md)

Functions to perform GVC decompositions on an 'icio' object

[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md)  
[`leontief()`](https://sebkrantz.github.io/icio/reference/leontief.md)  
[`kww()`](https://sebkrantz.github.io/icio/reference/kww.md)  
[`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md)

Interface function dispatching on the method, also for lists of 'icio'
objects (e.g. several years)

[`decomp()`](https://sebkrantz.github.io/icio/reference/decomp.md)

Function to obtain KWW decomposition from WWZ decomposition

[`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md)

Example ICIO data

[`data("leather")`](https://sebkrantz.github.io/icio/reference/leather.md)

## Note

`icio` is derived from the CRAN package `decompr` (Quast and Kummritz
2015), of which the author was a co-author and which is no longer
maintained. [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md)
is the R counterpart of
[`decompose()`](https://rdrr.io/r/stats/decompose.html) in the Julia
package
[GlobalValueChains.jl](https://github.com/SebKrantz/GlobalValueChains.jl).

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

Belotti, F., Borin, A., & Mancini, M. (2021). icio: Economic analysis
with inter-country input-output tables. *The Stata Journal, 21*(3),
708-755.

## See also

https://sebkrantz.github.io/icio/

## Author

Sebastian Krantz <sebastian.krantz@graduateinstitute.ch>  
Bastiaan Quast  
Fei Wang  
Victor Stolzenburg
