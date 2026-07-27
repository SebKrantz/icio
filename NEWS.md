icio 1.0.0
=======================

First release of **icio**, a rename and consolidation of the CRAN package
[**decompr**](https://cran.r-project.org/package=decompr) (Quast and Kummritz 2015), whose
original maintainer is no longer active. The package is now maintained by
[Sebastian Krantz](https://github.com/SebKrantz), a co-author of later **decompr** versions,
at <https://github.com/SebKrantz/icio>. **decompr**'s version history ended at 8.0.0; **icio**
starts fresh at 1.0.0 and keeps no backwards compatibility with it. Everything below is
relative to `decompr 8.0.0`.

### Loading ICIO tables

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
  [GlobalValueChains.jl](https://github.com/SebKrantz/GlobalValueChains.jl).

* Fixed: an output vector supplied through an `iot` object was silently ignored, because the
  loader looked for the element `output` while `data(leather)` and the `iot` documentation
  call it `out` (R's partial matching does not bridge the two). Both names are now accepted,
  as is an optional `va` element.

* The object itself is unchanged from `decompr 8.0.0`: `A`, `B`, `Lb`, `E`, `ESR`, `Vc`, `G`,
  `N`, `GN`, `k`, `i`, `X`, `Y`, `Yd`, `Ym`. Only `A` and `B` are dense `GN x GN` matrices;
  the masked and block-diagonal variants the decompositions need are derived on the fly.

### Running decompositions

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

* `bm()`, `leontief()`, `kww()`, `wwz()` and `wwz2kww()` are otherwise unchanged, including
  their arguments and term names.

* Fixed: 34 roxygen lines in `wwz()`'s documentation used a typographic apostrophe (`#’`)
  instead of `#'` and were therefore silently dropped, leaving the help page without its
  `@return` section describing the 16 terms.

### Removed

* The RStudio addin (`decomp_gadget()`) and its `addins.dcf`, the deprecated `load_tables()`
  interface, the unused `tiva()` stub, the `kww_example` / `kww_experimental` scratch files,
  and the package startup message.

* The `gvc` package is no longer suggested; it was not used by any test, example or vignette.

---

The four decompositions themselves are unchanged and continue to implement:

| Function | Method | Level | Terms |
|----------|--------|-------|-------|
| `bm()` | Borin & Mancini (2019) | country / sector / bilateral | up to 13 |
| `leontief()` | Hummels, Ishii & Yi (2001) | country x industry | continuous VA origin |
| `kww()` | Koopman, Wang & Wei (2014) | country | 9 |
| `wwz()` | Wang, Wei & Zhu (2013) | bilateral country x sector | 16 |

`bm()` covers the full set of Stata `icio` perspectives and approaches (exporter/world/self,
source/sink, exports/imports), is the R counterpart of `decompose()` in
GlobalValueChains.jl, and agrees with it to machine precision on real ICIO tables. Its
`perspective = "world", approach = "sink"` variant is the Borin-Mancini correction to the
biased KWW decomposition.
