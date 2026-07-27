# icio 1.0.0

First release of **icio**, a rename and consolidation of the CRAN package
[**decompr**](https://cran.r-project.org/package=decompr) (Quast and Kummritz 2015), whose
original maintainer is no longer active. The package is now maintained by
[Sebastian Krantz](https://github.com/SebKrantz), a co-author of later **decompr** versions,
at <https://github.com/SebKrantz/icio>, and starts fresh at 1.0.0 with **no backwards
compatibility** with **decompr**.

The last CRAN release of **decompr** was **6.9.0**, and everything below is relative to it.
Two further **decompr** versions were developed but never published -- 7.0.0 (completing the
Borin-Mancini variant surface) and 8.0.0 (reducing the intermediate object) -- so their
changes are included here.

## The Borin-Mancini decomposition

* `bm()` now covers the **full set of Stata `icio` perspectives and approaches**. In 6.9.0 it
  offered the exporter/source and world/sink variants only; it now additionally supports
  - `perspective = "exporter"` with `approach = "sink"` (9 terms; the bilateral level adds
    `VAXIM`, the domestic VA absorbed by the direct importer),
  - `perspective = "world"` with `approach = "source"` (9 terms),
  - `perspective = "self"` (sector or bilateral level), the export flow's own perimeter, giving
    the broader Johnson (2018) / Los et al. (2016) domestic value added (9 terms), and
  - `flow = "imports"`, an importer-perspective decomposition of gross imports into value added
    and double counting (`GIMP = VA + DC`), at the country level or by value-added origin.

  It remains the R counterpart of `decompose()` in the Julia package
  [GlobalValueChains.jl](https://github.com/SebKrantz/GlobalValueChains.jl) (formerly `ICIO.jl`),
  reproduces the Stata `icio` command's output, and agrees with the Julia implementation to
  machine precision on real ICIO tables.

## Loading ICIO tables

* `load_tables_vectors()` is replaced by **`load_icio()`**, which returns an object of class
  **`icio`** (previously `decompr`). Its arguments are named after the elements of an `iot`
  table -- `inter`, `final`, `countries`, `industries`, `output`, `va` -- rather than
  `x, y, k, i, o, v`. An `iot`-class list such as `data(leather)` is detected automatically
  when passed as the first argument, so there is no separate `iot` argument:
  `load_icio(leather)` and `load_icio(inter, final, countries, industries)` both work.

* New **`load_icio_csv()`** reads the CSV format of the Stata `icio` command -- a headerless
  `GN x (GN + G)` matrix `[inter | final]` plus a one-column country-list file -- via
  `data.table::fread()`. Industry codes may be given as a vector, as a path to a one-column
  CSV, or omitted (defaulting to `sector1 ... sectorN`). This mirrors `read_icio_csv()` in
  GlobalValueChains.jl.

* **The intermediate object has been reduced.** In 6.9.0 it carried five dense `GN x GN`
  matrices, but only two held independent information: `Am`, `Bd`, `Bm` and `L` were masked or
  block-diagonal copies of the input coefficients and of the Leontief inverse, and `Bd` and `L`
  were stored dense despite being block-diagonal, hence `1 - 1/G` structural zeros (98% at
  `G = 50`). The object now holds the **full** input coefficient matrix `A` (previously only
  `Am`, with the domestic blocks zeroed, was kept) and the domestic Leontief inverse as the list
  `Lb` of the `G` local `N x N` blocks it consists of. The fields `Am`, `Bd`, `Bm`, `L`, `Eint`,
  `Efd` and `rownam` are gone; the object is `A`, `B`, `Lb`, `E`, `ESR`, `Vc`, `G`, `N`, `GN`,
  `k`, `i`, `X`, `Y`, `Yd`, `Ym`. Code that used the removed fields can rebuild them with

  ```r
  Am <- A; Bd <- matrix(0, GN, GN); Bm <- B; L <- matrix(0, GN, GN)
  for (g in seq_len(G)) {
    bg <- (g - 1L) * N + seq_len(N)
    Am[bg, bg] <- 0; Bd[bg, bg] <- B[bg, bg]; Bm[bg, bg] <- 0; L[bg, bg] <- Lb[[g]]
  }
  ```

  and `Efd` equals `Ym`, `Eint` equals `ESR - Ym`, `rownam` equals `names(Vc)`.

* The decomposition functions derive whatever masked forms they need. `leontief()`, `kww()` and
  `bm()` work entirely off the diagonal blocks of `B` and off `Lb`, without ever materializing a
  dense `Bd`, `Bm` or `L`. `wwz()`, which uses the masked matrices in dense products throughout,
  rebuilds `Am`, `Bd` and `Bm` on entry.

* The loader is **faster and allocates far less**: the block-diagonal `L` comes from `G` small
  solves instead of one dense `solve(I - Ad)` (two orders of magnitude cheaper for an identical
  result), exports by destination are assembled from `inter` and `Y` directly instead of from a
  masked `cbind(inter, final)` copy, and forming `I - A` in place avoids a `GN x GN` identity
  matrix. On a 50-country, 40-industry table the object went from 160 MB to 66 MB and
  construction from 5.2 to 4.1 seconds, with all decompositions reproducing their previous
  results to within 3e-12 relative.

* Fixed: an output vector supplied through an `iot` object was silently ignored, because the
  loader looked for the element `output` while `data(leather)` and the `iot` documentation
  call it `out` (R's partial matching does not bridge the two). Both names are now accepted,
  as is an optional `va` element.

## Running decompositions

* `decomp()` now takes an `icio` object (or a list of them) instead of raw tables, so the
  expensive construction step is always explicit and reusable. Its default `method` is
  `"bm"`, the recommended decomposition.

* Given a **list of `icio` objects** -- typically one ICIO table per year -- `decomp()` runs
  the decomposition on each and stacks the results with `data.table::rbindlist()`, prepending
  an identifier column named by `idcol` (default `"Label"`, `NULL` to omit). This mirrors the
  `Dict` method of `decompose()` in GlobalValueChains.jl.

* **All decompositions now return a `data.table`** rather than a `data.frame`. Note that
  `d[, "GEXP"]` returns a one-column table rather than a vector, and `d[c("GEXP", "DVA")]` is
  a join rather than a column subset -- use `d$GEXP`, `d[, .(GEXP, DVA)]`, or
  `as.data.frame(d)` for base-R semantics. `data.table` is a new dependency.

* `kww()` is **substantially faster**: re-associating `Bm %*% Am %*% L %*% Z` as
  `Bm %*% (Am %*% (L %*% Z))`, with `Z` having only `G` columns, removes two `GN x GN x GN`
  matrix products. On a 2000 x 2000 table it went from 10.3 to 0.6 seconds. A dead `Vc * B`
  allocation was also removed.

* `bm()`, `leontief()`, `kww()`, `wwz()` and `wwz2kww()` are otherwise unchanged, including
  their arguments and term names.

* Fixed: 34 roxygen lines in `wwz()`'s documentation used a typographic apostrophe (`#’`)
  instead of `#'` and were therefore silently dropped, leaving the help page without its
  `@return` section describing the 16 terms.

## Removed

* The RStudio addin (`decomp_gadget()`) and its `addins.dcf`, the deprecated `load_tables()`
  interface, the unused `tiva()` stub, the `kww_example` / `kww_experimental` scratch files,
  and the package startup message.

* The `gvc` package is no longer suggested; it was not used by any test, example or vignette.
  (It is in any case unaffected by the object reduction, using only `G`, `N`, `GN`, `k`, `i`
  and `X`.)

## Documentation

* New pkgdown website at <https://sebkrantz.github.io/icio/> and a rewritten package vignette,
  `vignette("icio")`.


# decompr 6.9.0
* Added the Borin-Mancini (2019) decomposition via the new `bm()` function (also available
  through `decomp(method = "bm")`). It decomposes gross exports into up to 13 value-added and
  GVC terms at the country, sector, or bilateral-sector level, under the exporter/source or
  world/sink perspective. It is the R counterpart of `decompose()` in the Julia package
  `ICIO.jl` and reproduces the Stata `icio` command's output.
* The `kww()` documentation now notes that the KWW decomposition is biased (it systematically
  underestimates foreign value added) and points to `bm(perspective = "world", approach = "sink")`
  for the Borin-Mancini correction. Cross-references to `bm()` were added throughout.
