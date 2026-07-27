# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`decompr` is a CRAN R package (v8.0.0, GPL-3) implementing four global value chain (GVC)
decompositions of gross exports from inter-country input-output (ICIO) tables:
Leontief (Hummels-Ishii-Yi 2001), KWW (Koopman-Wang-Wei 2014), WWZ (Wang-Wei-Zhu 2013), and
Borin-Mancini (2019). Companion packages: `gvc` (R, GVC indicators) and
`GlobalValueChains.jl` (Julia — `bm()` is its 1:1 R counterpart).

## Commands

All from the package root. `devtools`/`roxygen2` are the expected toolchain (they are not
declared in `DESCRIPTION`).

```r
devtools::load_all()      # load with C code compiled
devtools::document()      # regenerate man/*.Rd and NAMESPACE from roxygen comments
devtools::test()          # run the testthat suite
devtools::check()         # full R CMD check (what CI runs)
devtools::build_vignettes()
pkgdown::build_site()
```

```sh
R CMD build . && R CMD check decompr_8.0.0.tar.gz
Rscript -e 'devtools::test(filter = "bm")'   # single test file (tests/testthat/test_bm.R)
Rscript misc/validate_bm_emerging.R          # local-only: bm() vs Julia on real ICIO data
```

`NAMESPACE` and everything under `man/` are roxygen-generated — never hand-edit them; edit the
roxygen block above the function and re-run `devtools::document()`.

CI (`.github/workflows/`): `R-CMD-check` on Windows/macOS(release+devel)/Ubuntu, `test-coverage`,
and `pkgdown` deploy — all on push/PR to `master`.

## Architecture

The package is organised as **one file per decomposition**, all operating on a single shared
intermediate object.

### The `decompr` object

`load_tables_vectors()` ([R/load_tables_vectors.R](R/load_tables_vectors.R)) is the entry point
for everything. It takes the raw ICIO matrices (`x` = GN×GN intermediate demand, `y` = GN×(G·M)
final demand, `k` = G countries, `i` = N industries, optional `o` output and `v` value added, or
an `iot`-class list like `data(leather)`) and precomputes what the decompositions need:

- `A` = input coefficients (**full**, including domestic blocks); `B` = Leontief inverse `(I-A)^-1`.
  These are the **only** two dense GN×GN matrices, and the only two fields carrying independent
  information.
- `Lb` = **list of G local Leontief blocks** `(I-A_gg)^-1`, one N×N matrix per country — not a
  dense GN×GN matrix, which would be `1 - 1/G` structural zeros.
- `Vc` = value-added coefficients `v/o`; `E`/`ESR` = exports; `X`/`Y`/`Yd`/`Ym`; `G`/`N`/`GN`/`k`/`i`.

**Do not add masked or block-diagonal copies back to the object.** Before 8.0.0 it also stored
`Am` (A with domestic blocks zeroed), `Bd`/`Bm` (domestic/foreign parts of B), a dense `L`, plus
`Eint`/`Efd`/`rownam`. All were derivable, and `Bd`/`L` were ~99% zeros at realistic G. Each
decomposition now derives what it needs:

- `bm()` and `kww()` never materialise `Bd`, `Bm` or a dense `L` — every product involving them is
  block-diagonal, so they loop over `B[bg, bg]` and `Lb[[g]]`. Both materialise `Am` once.
- `wwz()` uses the masked matrices in dense GN×GN products throughout, so it rebuilds `Am`, `Bd`,
  `Bm`, `Eint` (`= ESR - Ym`) and `Efd` (`= Ym`) on entry. It uses `Lb` blockwise.
- Re-associate before materialising: `kww()` computes `Bm %*% (Am %*% (L %*% Z))` with `Z` only G
  columns wide instead of `Bm %*% Am %*% L`, which is what made it 18× faster.

Row/column ordering is **country-major**: `C1I1, C1I2, ..., C2I1, ...`, so country `g`'s block is
`(g-1)*N + seq_len(N)`. Every engine relies on this. Names come from
`as.vector(t(outer(k, i, paste, sep = ".")))` and are on `names(Vc)` / `dimnames(B)`.

Decomposition functions all start with `list2env(x, environment())` to pull the object's fields
into scope (initialise them to `NULL` first — `R CMD check` flags undefined globals otherwise).

### Decompositions

| File | Export | Output |
|------|--------|--------|
| [R/leontief.R](R/leontief.R) | `leontief()` | VA origins of exports/output/final demand; long or wide |
| [R/kww.R](R/kww.R) | `kww()`, `wwz2kww()` | 9 country-level terms; `wwz2kww()` aggregates a WWZ result instead of recomputing |
| [R/wwz.R](R/wwz.R) | `wwz()` | data.frame, G·N·G rows × 16 terms + totals + checksums |
| [R/bm.R](R/bm.R) | `bm()` | data.frame, up to 13 terms; the recommended method |
| [R/decomp.R](R/decomp.R) | `decomp()` | thin wrapper: `load_tables_vectors()` + `switch(method)` + `...` |

Results are data.frames with factor identifier columns (`Exporting_Country`,
`Exporting_Industry`, `Importing_Country`, `Origin_Country`) followed by term columns, tagged
with `attr(x, "decomposition")` (`"wwz"`, `"kww"`, `"bm"`) — `wwz2kww()` dispatches on that
attribute. Data frames are built column-list-first and then given `class`/`row.names` directly
rather than via `data.frame()`, for speed.

### `bm()` structure

[R/bm.R](R/bm.R) is a **dispatcher + shared prep + one engine per variant**:

- `bm()` validates the `aggregation` × `perspective` × `approach` × `flow` combination and routes.
- `.bm_prep(x)` computes everything shared: `Am`, the three VA multipliers (`VBdom`/`VBfor`/`VLdom`,
  built blockwise from `B[bg, bg]` and `Lb[[g]]`), `fvacoef`, `Wcol` and `BFD`. Engines get this
  list as `P` and pull it into scope with `list2env(P, environment())`.
- `.bm_source` (exporter/source, 13 terms), `.bm_world` (country-level "corrected KWW"),
  `.bm_sink` (BM19 eq. 33-39), `.bm_self` (eq. 47-49), `.bm_imports` (eq. 51, Woodbury update of
  `B` per importer). Each is a line-by-line port of the corresponding Julia engine.

Term columns are UPPER-CASE by convention here (the other decompositions use mixed case).
[misc/bm_expansion_plan.md](misc/bm_expansion_plan.md) documents the variant surface and the
Julia↔decompr field mapping; keep it in sync when adding variants.

### C code

[src/rowmult.c](src/rowmult.c) contains a single routine, `C_rowmult(x, v)` = column-scaling of a
matrix (`t(t(x) * v)`), registered via `R_init_decompr` with `R_forceSymbols(TRUE)` — call it as
`.Call(C_rowmult, ...)`, not by string name. Used in `load_tables_vectors()` and `wwz()`.
`matrixStats::rowSums2`/`colSums2` are used throughout for the same reason (avoiding copies on
large ICIO tables, which run to thousands of rows).

## Testing

`tests/testthat/` covers `leontief`, `wwz`, and `bm` against the 3×3 `leather` toy table. The
`bm` tests are the model to follow for new work: output dimensions, **accounting identities**
(`GEXP = DC + FC`, `DC = DVA + DDC`, `DVA = VAX + REF`, `GIMP = VA + DC`), **additivity**
(bilateral sums to sector sums to country), cross-engine anchors, and error paths for invalid
option combinations. Ground truth beyond identities is established externally against
`GlobalValueChains.jl`/Stata `icio` via `misc/validate_bm_emerging.R`, which needs local data not
in the repo.

## Not part of the build

`.Rbuildignore` excludes `R/decomp_gadget.R` (RStudio addin), `R/tiva.R`, `R/kww_example.R`,
`R/kww_experimental.R`, plus `misc/`, `pkgdown/`, and `.github/`. Those R files are tracked in
git but are *not* installed, so nothing in the shipped package may depend on them.
