decompr 8.0.0
=======================

**Breaking change**: the 'decompr' object returned by `load_tables_vectors()` has been reduced.
It carried five dense `GN x GN` matrices, but only two of them held independent information --
`Am`, `Bd`, `Bm` and `L` were masked or block-diagonal copies of the input coefficients and of the
Leontief inverse. `Bd` and `L` were additionally stored dense despite being block-diagonal, so at
`G` countries they were `1 - 1/G` structural zeros (98% at `G = 50`).

* The object now stores the **full** input coefficient matrix `A` (previously only `Am`, with the
  domestic blocks zeroed, was kept -- which forced `bm()` to reconstruct `A` on every call) and the
  domestic Leontief inverse as the list `Lb` of the `G` local `N x N` blocks it consists of, rather
  than as a dense `GN x GN` matrix. The fields `Am`, `Bd`, `Bm`, `L`, `Eint`, `Efd` and `rownam`
  were removed; `rownam` was not used by any decomposition and is still available as
  `names(x$Vc)`. `A`, `B`, `Lb`, `E`, `ESR`, `Vc`, `G`, `N`, `GN`, `k`, `i`, `X`, `Y`, `Yd` and
  `Ym` are unchanged or new. See `?load_tables_vectors` for how to recover the removed fields.

* The decomposition functions derive whatever masked forms they need. `leontief()`, `kww()` and
  `bm()` now work entirely off the diagonal blocks of `B` and off `Lb`, without ever materializing
  a dense `Bd`, `Bm` or `L`. `wwz()`, which uses the masked matrices in dense products throughout,
  rebuilds `Am`, `Bd` and `Bm` on entry.

* `kww()` is **substantially faster**: re-associating `Bm %*% Am %*% L %*% Z` as
  `Bm %*% (Am %*% (L %*% Z))`, with `Z` having only `G` columns, removes two `GN x GN x GN` matrix
  products. On a 2000 x 2000 table it went from 10.3 to 0.6 seconds. A dead `Vc * B` allocation was
  also removed.

* `load_tables_vectors()` is faster and allocates far less: the block-diagonal `L` is obtained from
  `G` small solves instead of one dense `solve(I - Ad)` (two orders of magnitude cheaper for an
  identical result), exports by destination are assembled from `x` and `Y` directly instead of from
  a masked `cbind(x, y)` copy, and forming `I - A` in place avoids a `GN x GN` identity matrix.

  On a 50-country, 40-industry table the object went from 160 MB to 66 MB and construction from
  5.2 to 4.1 seconds. All decompositions reproduce their 7.0.0 results to within 3e-12 relative.

* The complimentary 'gvc' package is unaffected: it only uses `G`, `N`, `GN`, `k`, `i` and `X`.

decompr 7.0.0
=======================
* Added the Borin-Mancini (2019) decomposition via the new `bm()` function (also available
  through `decomp(method = "bm")`). It decomposes gross exports into up to 13 value-added and
  GVC terms at the country, sector, or bilateral-sector level, and covers the full set of Stata
  `icio` perspectives and approaches:
  - `perspective = "exporter"` with `approach = "source"` (13 terms) or `approach = "sink"`
    (9 terms; the bilateral level adds `VAXIM`, the domestic VA absorbed by the direct importer);
  - `perspective = "world"` (country level) with `approach = "sink"` (corrected KWW) or
    `approach = "source"` (9 terms);
  - `perspective = "self"` (sector or bilateral level), the export flow's own perimeter giving
    the broader Johnson (2018) / Los et al. (2016) domestic value added (9 terms); and
  - `flow = "imports"`, an importer-perspective decomposition of gross imports into value added
    and double counting (`GIMP = VA + DC`), at the country level or by value-added origin.

  It is the R counterpart of `decompose()` in the Julia package `GlobalValueChains.jl` (formerly
  `ICIO.jl`), reproduces the Stata `icio` command's output, and agrees with the Julia
  implementation to machine precision on real ICIO tables.
* The `kww()` documentation now notes that the KWW decomposition is biased (it systematically
  underestimates foreign value added) and points to `bm(perspective = "world", approach = "sink")`
  for the Borin-Mancini correction. Cross-references to `bm()` were added throughout.
* New pkgdown website at https://bquast.github.io/decompr/, and updated [package vignette](https://bquast.github.io/decompr/articles/decompr.html).
* These edits were made by [Sebastian Krantz](https://github.com/SebKrantz), who is now also a package author.

decompr 6.4.0
=======================
* redo documentation
* small general fixes
* add ORCID


decompr 6.2.0
=======================
* documentation updates


decompr 6.0.0
=======================
* Added Koopman-Wang-Wei (KWW) decompositon and function to aggregate WWZ to KWW decomposition
* 2x performance improvement through C-code and matrixStats dependency
* Improved code security through additional checks
* Enhanced documentation providing more details about methods and resulting objects

decompr 5.2.0
=======================
* documentation redone


decompr 4.5.0
=======================
* code refactoring
* added v

decompr 4.1.0
=======================
* fix post multiplication "final_demand" of leontief()

decompr 4.0.0
=======================
* add post-multiplication argument to leontief method
* remove leontief_output(), functionality moved to leontief()
* use ellipsis for decomp function

decompr 3.0.0
=======================
* remove vertical_specialisation and vertical_specialization, will be included in gvc package
* add some attributes to output t.b. used by gvc package
* change the output format of leontief and leontief-output to long form (tidy data)
* add columns country and sectors names
* add DViX_Fsr to wwz
* add Vignette (decompr)
* add tests
* add Travis-CI support
* add coveralls.io support

decompr 2.1.0
=======================
* add a leontief_output decomposition method
* update the README.md file
* add warning when no method is specified in decomp (default is Leontief as of v.2)

decompr 2.0.0
=======================
* make load_tables_vectors default
* change notice to reflect new default
* update examples and data to reflect lt
* replace use of 2 dimensional arrays with matrices
* more efficient construction of rownam and z1
* replace use of length(k) with G
* replace use of various inefficient uses of diag() (e.g. with Vhat)
* improved spacing of code for legibility
* make leontief default method

decompr 1.3.2
=======================
* add notice

decompr 1.3.1
=======================
* fix citations etc.

decompr 1.3.0
=======================
* add load_tables_vectors to input in simple form

decompr 1.2.1
=======================
* update authors

decompr 1.2.0
=======================
* update citation code
* use " in stead of ' in examples and function arguments
* use match.arg for method in decomp function

decompr 1.1.0
=======================
* update references
* include more descriptive description

decompr 1.0.2
=======================
* update example data to regional tables for faster computations
* put back examples for non-decomp functions

decompr 1.0.1
=======================
* remove examples other than for **decomp** function, to pass CRAN test in time
* add cran-comments.md

decompr 1.0.0
=======================
* functions names use underscores in stead of periods
* method names use underscores in stead of periods
* examples reflect the above changes
* WIOD data set is now compressed using bzip2
* included this news file

decompr 0.7.0
=======================
* citation information is included

decompr 0.6.0
=======================
* example data set in included

decompr 0.5.0
=======================
* examples are included
