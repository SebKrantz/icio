# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this is

`icio` is an R package (v1.0.0, GPL-3) implementing four global value
chain (GVC) decompositions of gross exports from inter-country
input-output (ICIO) tables: Borin-Mancini (2019), Leontief
(Hummels-Ishii-Yi 2001), KWW (Koopman-Wang-Wei 2014), and WWZ
(Wang-Wei-Zhu 2013).
[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) is the
recommended method and reproduces the Stata `icio` command; it is the
1:1 R counterpart of
[`decompose()`](https://rdrr.io/r/stats/decompose.html) in
[GlobalValueChains.jl](https://github.com/SebKrantz/GlobalValueChains.jl)
(Julia, checked out locally at `~/Documents/Julia/ICIO.jl` — the
directory kept the old name).

The package is derived from `decompr`, whose maintainer went inactive.
`decompr`’s last CRAN release was 6.9.0; its 7.0.0 (full
[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) variant
surface) and 8.0.0 (object reduction) were developed but never
published, so `icio 1.0.0`’s NEWS is written against 6.9.0. The git
working directory is still named `decompr`; the package inside it is
`icio`. There is **no backwards compatibility with `decompr`** — do not
add compatibility shims or aliases.

## Commands

All from the package root. `devtools`/`roxygen2` are the expected
toolchain (they are not declared in `DESCRIPTION`).

``` r

devtools::load_all()      # load with C code compiled
devtools::document()      # regenerate man/*.Rd and NAMESPACE from roxygen comments
devtools::test()          # run the testthat suite
devtools::check()         # full R CMD check (what CI runs)
devtools::build_vignettes()
pkgdown::build_site()
```

``` sh
R CMD build . && R CMD check --as-cran icio_1.0.0.tar.gz
Rscript -e 'devtools::test(filter = "bm")'   # single test file (tests/testthat/test_bm.R)
Rscript misc/validate_bm_emerging.R          # local-only: bm() vs Julia on real ICIO data
```

`NAMESPACE` and everything under `man/` are roxygen-generated — never
hand-edit them; edit the roxygen block above the function and re-run
`devtools::document()`. Renaming anything that `useDynLib` touches
requires `rm src/*.o src/*.so && pkgbuild::compile_dll(force = TRUE)`;
`make` alone will report “Nothing to be done” because the stale `.o` is
newer than the `.c`.

CI (`.github/workflows/`): `R-CMD-check` on
Windows/macOS(release+devel)/Ubuntu, `test-coverage`, and `pkgdown`
deploy — all on push/PR to `master`.

## Architecture

The package is organised as **one file per decomposition**, all
operating on a single shared intermediate object.

### The `icio` object

[`load_icio()`](https://sebkrantz.github.io/icio/reference/load_icio.md)
([R/load_icio.R](https://sebkrantz.github.io/icio/R/load_icio.R)) is the
entry point for everything. It takes the raw ICIO matrices (`inter` =
GN×GN intermediate demand, `final` = GN×(G·M) final demand, `countries`
= G, `industries` = N, optional `output` and `va`) and precomputes what
the decompositions need. An `iot`-class list like `data(leather)` passed
as the first argument is detected via
[`inherits()`](https://rdrr.io/r/base/class.html) — there is
deliberately no separate `iot` parameter. Note that `leather` names its
output vector `out` while other `iot` producers use `output`; the loader
accepts both (`$` partial matching does *not* bridge them, which was a
silent bug in `decompr`).

[`load_icio_csv()`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md)
reads the Stata `icio` CSV format (headerless `GN × (GN + G)` matrix
`[inter | final]` + a one-column country list) via
[`data.table::fread()`](https://rdrr.io/pkg/data.table/man/fread.html),
and delegates.

The object’s fields:

- `A` = input coefficients (**full**, including domestic blocks); `B` =
  Leontief inverse `(I-A)^-1`. These are the **only** two dense GN×GN
  matrices, and the only two fields carrying independent information.
- `Lb` = **list of G local Leontief blocks** `(I-A_gg)^-1`, one N×N
  matrix per country — not a dense GN×GN matrix, which would be
  `1 - 1/G` structural zeros.
- `Vc` = value-added coefficients `va/output`; `E`/`ESR` = exports;
  `X`/`Y`/`Yd`/`Ym`; `G`/`N`/`GN`/`k`/`i`.

**Do not add masked or block-diagonal copies back to the object.**
`decompr` up to 6.9.0 also stored `Am` (A with domestic blocks zeroed),
`Bd`/`Bm` (domestic/foreign parts of B), a dense `L`, plus
`Eint`/`Efd`/`rownam`. All were derivable, and `Bd`/`L` were ~99% zeros
at realistic G. Each decomposition derives what it needs:

- [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) and
  [`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) never
  materialise `Bd`, `Bm` or a dense `L` — every product involving them
  is block-diagonal, so they loop over `B[bg, bg]` and `Lb[[g]]`. Both
  materialise `Am` once.
- [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) uses the
  masked matrices in dense GN×GN products throughout, so it rebuilds
  `Am`, `Bd`, `Bm`, `Eint` (`= ESR - Ym`) and `Efd` (`= Ym`) on entry.
  It uses `Lb` blockwise.
- Re-associate before materialising:
  [`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) computes
  `Bm %*% (Am %*% (L %*% Z))` with `Z` only G columns wide instead of
  `Bm %*% Am %*% L`, which is what made it ~10× faster.

Row/column ordering is **country-major**: `C1I1, C1I2, ..., C2I1, ...`,
so country `g`’s block is `(g-1)*N + seq_len(N)`. Every engine relies on
this. Names come from `as.vector(t(outer(k, i, paste, sep = ".")))` and
are on `names(Vc)` / `dimnames(B)`.

Decomposition functions all start with `list2env(x, environment())` to
pull the object’s fields into scope (initialise them to `NULL` first —
`R CMD check` flags undefined globals otherwise).

### Decompositions

| File | Export | Output |
|----|----|----|
| [R/bm.R](https://sebkrantz.github.io/icio/R/bm.R) | [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) | up to 13 terms; the recommended method |
| [R/leontief.R](https://sebkrantz.github.io/icio/R/leontief.R) | [`leontief()`](https://sebkrantz.github.io/icio/reference/leontief.md) | VA origins of exports/output/final demand; long or wide |
| [R/kww.R](https://sebkrantz.github.io/icio/R/kww.R) | [`kww()`](https://sebkrantz.github.io/icio/reference/kww.md), [`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md) | 9 country-level terms; [`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md) aggregates a WWZ result instead of recomputing |
| [R/wwz.R](https://sebkrantz.github.io/icio/R/wwz.R) | [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) | G·N·G rows × 16 terms + totals + checksums |
| [R/decomp.R](https://sebkrantz.github.io/icio/R/decomp.R) | [`decomp()`](https://sebkrantz.github.io/icio/reference/decomp.md) | `switch(method)` + `...`; on a *list* of `icio` objects runs each and `rbindlist`s with an `idcol` |

Results are **data.tables** with factor identifier columns
(`Exporting_Country`, `Exporting_Industry`, `Importing_Country`,
`Origin_Country`) followed by term columns, tagged with
`attr(x, "decomposition")` (`"wwz"`, `"kww"`, `"bm"`) —
[`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md)
dispatches on that attribute. They are built **column-list-first** and
then handed to
[`data.table::setDT()`](https://rdrr.io/pkg/data.table/man/setDT.html),
which is why the engines never call
[`data.frame()`](https://rdrr.io/r/base/data.frame.html); set attributes
with `setattr()`, not `attr<-`, to avoid copying. Consequence to
remember when writing tests or examples: `d[, "GEXP"]` yields a
one-column table and `d[c("a","b")]` is a *join*, not a column subset —
use `d$GEXP`, `d[, .(a, b)]` or `as.data.frame(d)`.

### `bm()` structure

[R/bm.R](https://sebkrantz.github.io/icio/R/bm.R) is a **dispatcher +
shared prep + one engine per variant**:

- [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) validates
  the `aggregation` × `perspective` × `approach` × `flow` combination
  and routes.
- `.bm_prep(x)` computes everything shared: `Am`, the three VA
  multipliers (`VBdom`/`VBfor`/`VLdom`, built blockwise from `B[bg, bg]`
  and `Lb[[g]]`), `fvacoef`, `Wcol` and `BFD`. Engines get this list as
  `P` and pull it into scope with `list2env(P, environment())`.
- `.bm_source` (exporter/source, 13 terms), `.bm_world` (country-level
  “corrected KWW”), `.bm_sink` (BM19 eq. 33-39), `.bm_self` (eq. 47-49),
  `.bm_imports` (eq. 51, Woodbury update of `B` per importer). Each is a
  line-by-line port of the corresponding Julia engine.

Term columns are UPPER-CASE by convention here (the other decompositions
use mixed case), and
[`bm()`](https://sebkrantz.github.io/icio/reference/bm.md)’s argument is
`aggregation` where Julia’s is `level` — this divergence is deliberate.
[misc/bm_expansion_plan.md](https://sebkrantz.github.io/icio/misc/bm_expansion_plan.md)
documents the Julia↔︎R field mapping (its “Field mapping” section is
historical/stale — see the note at its top).

### C code

[src/rowmult.c](https://sebkrantz.github.io/icio/src/rowmult.c) contains
a single routine, `C_rowmult(x, v)` = column-scaling of a matrix
(`t(t(x) * v)`), registered via `R_init_icio` with
`R_forceSymbols(TRUE)` — call it as `.Call(C_rowmult, ...)`, not by
string name. Used in
[`load_icio()`](https://sebkrantz.github.io/icio/reference/load_icio.md)
and [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md).
[`matrixStats::rowSums2`](https://rdrr.io/pkg/matrixStats/man/rowSums2.html)/`colSums2`
are used throughout for the same reason (avoiding copies on large ICIO
tables, which run to thousands of rows).

## Testing

`tests/testthat/` covers `load_icio`/`load_icio_csv`, `leontief`, `wwz`,
and `bm` against the 3×3 `leather` toy table. The `bm` tests are the
model to follow for new work: output dimensions, **accounting
identities** (`GEXP = DC + FC`, `DC = DVA + DDC`, `DVA = VAX + REF`,
`GIMP = VA + DC`), **additivity** (bilateral sums to sector sums to
country), cross-engine anchors, and error paths for invalid option
combinations. Ground truth beyond identities is established externally
against `GlobalValueChains.jl`/Stata `icio` via
`misc/validate_bm_emerging.R`, which needs local data not in the repo.

Two testthat gotchas here: the suite runs on edition 2, so
`ignore_attr =` is not honoured — use
[`unname()`](https://rdrr.io/r/base/unname.html). And
`expect_identical()` fails on two equal data.tables because each carries
its own `.internal.selfref` pointer — use `expect_equal()`.

## Not part of the build

`.Rbuildignore` excludes `misc/`, `pkgdown/`, `.github/`, `CLAUDE.md`
and `cran-comments.md`.
