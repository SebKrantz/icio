# icio

[![License](http://img.shields.io/badge/license-GPLv3-brightgreen.svg?style=flat)](https://www.gnu.org/licenses/gpl-3.0.html)
[![CRAN Version](http://www.r-pkg.org/badges/version/icio)](https://cran.r-project.org/package=icio)
[![R build status](https://github.com/SebKrantz/icio/workflows/R-CMD-check/badge.svg)](https://github.com/SebKrantz/icio/actions?workflow=R-CMD-check)

**icio** decomposes gross exports from inter-country input-output (ICIO) tables into value-added and double-counting components, implementing four decompositions from the global value chain (GVC) literature:

| Function | Method | Level | Terms |
|----------|--------|-------|-------|
| `bm()` | Borin & Mancini (2019) | country / sector / bilateral | up to 13 |
| `leontief()` | Hummels, Ishii & Yi (2001) | country × industry | continuous VA origin |
| `kww()` | Koopman, Wang & Wei (2014) | country | 9 |
| `wwz()` | Wang, Wei & Zhu (2013) | bilateral country × sector | 16 |

`bm()` is the recommended state-of-the-art decomposition and reproduces the Stata [`icio`](https://www.tradeconomics.com/icio/) command (Belotti, Borin & Mancini 2021). It also provides a corrected version of the KWW decomposition (`perspective = "world", approach = "sink"`), which fixes a known systematic bias in `kww()`.

## Installation

```r
# install.packages("remotes")
remotes::install_github("SebKrantz/icio")
```

## Usage

```r
library(icio)

# The built-in 3x3 leather-sector ICIO table
data(leather)

# Build an 'icio' object: the expensive step (inverting I - A) is done once here
m <- load_icio(leather)

# ... or from the raw matrices, or from the Stata 'icio' CSV format
m <- load_icio(leather$inter, leather$final, leather$countries, leather$industries)
m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv")

# Borin-Mancini (2019): up to 13 terms, exporter perspective
bm(m)
bm(m, aggregation = "sector")
bm(m, aggregation = "bilateral", approach = "sink")

# Corrected KWW (world / sink perspective)
bm(m, perspective = "world", approach = "sink")

# Importer-perspective decomposition of gross imports
bm(m, flow = "imports")

# The other decompositions
leontief(m)
kww(m)
wwz(m)

# Unified interface, also for several tables at once (e.g. one per year)
decomp(m, aggregation = "bilateral")
decomp(list(`2015` = m, `2016` = m), method = "kww", idcol = "Year")
```

All decompositions return a `data.table`. See `vignette("icio")` for a detailed walk-through.

## Related

- [GlobalValueChains.jl](https://github.com/SebKrantz/GlobalValueChains.jl) — the Julia counterpart; `bm()` mirrors its `decompose()`.
- **icio** is derived from the CRAN package [decompr](https://cran.r-project.org/package=decompr), which is no longer maintained.

## References

- Borin, A., & Mancini, M. (2019). *Measuring What Matters in Global Value Chains and Value-Added Trade*. World Bank Policy Research Working Paper 8804.
- Belotti, F., Borin, A., & Mancini, M. (2021). icio: Economic analysis with inter-country input-output tables. *The Stata Journal*, 21(3), 708–755.
- Koopman, R., Wang, Z., & Wei, S.-J. (2014). Tracing value-added and double counting in gross exports. *American Economic Review*, 104(2), 459–494.
- Wang, Z., Wei, S.-J., & Zhu, K. (2013). *Quantifying International Production Sharing at the Bilateral and Sector Levels*. NBER Working Paper 19677.
- Hummels, D., Ishii, J., & Yi, K.-M. (2001). The nature and growth of vertical specialization in world trade. *Journal of International Economics*, 54(1), 75–96.
