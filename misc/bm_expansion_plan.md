# Expand `icio::bm()` to the full Borin–Mancini (2019) variant surface

> **Historical.** Written when the package was still called `decompr` and before the object was
> reduced (`decompr 8.0.0`). The plan has been carried out: `bm()` supports the full variant
> surface, and the "Field mapping" section below is out of date -- the object now stores the
> **full** `A` and the local Leontief blocks `Lb`, so nothing has to be reconstructed. Kept as a
> record of the Julia↔R mapping; see `?bm` and `?load_icio` for the current state.

## Goal

`GlobalValueChains.jl` (formerly `ICIO.jl`) now implements the **full** `icio` decomposition
surface via `decompose(m; flow, level, perspective, approach)`. The R counterpart `bm()`
(`R/bm.R`) currently supports only **4** of those variants:

| aggregation | perspective | approach | terms | status |
|-------------|-------------|----------|-------|--------|
| country     | exporter    | source   | 13    | ✅ |
| sector      | exporter    | source   | 13    | ✅ |
| bilateral   | exporter    | source   | 13    | ✅ |
| country     | world       | sink     | 9     | ✅ |

This plan extends `bm()` to the **same set** of variants Julia exposes, keeping the two packages
1:1 so the existing cross-validation (`misc/validate_bm_emerging.R`, agreement ~1e-13) covers
every variant.

## Target surface (parity with `decompose()`)

`bm(x, aggregation, perspective, approach, flow)` — new arg `flow`; `perspective` gains
`"self"` and `"importer"`.

**Exports** (`flow = "exports"`, default):

| aggregation | perspective | approach        | n  | term columns |
|-------------|-------------|-----------------|----|--------------|
| country     | exporter    | source (=sink)  | 13 | GEXP DC DVA VAX DAVAX REF DDC FC FVA FDC GVC GVCB GVCF |
| country     | world       | source          | 9  | GEXP DC DVA VAX REF DDC FC FVA FDC |
| country     | world       | sink            | 9  | GEXP DC DVA VAX REF DDC FC FVA FDC |
| sector      | exporter    | source          | 13 | (as country source) |
| sector      | exporter    | **sink**        | 9  | GEXP DC DVA VAX REF DDC FC FVA FDC |
| sector      | **self**    | —               | 9  | GEXP DC DVA VAX REF DDC FC FVA FDC |
| bilateral   | exporter    | source          | 13 | (as country source) |
| bilateral   | exporter    | **sink**        | 10 | GEXP DC DVA VAX **VAXIM** REF DDC FC FVA FDC |
| bilateral   | **self**    | —               | 9  | GEXP DC DVA VAX REF DDC FC FVA FDC |

**Imports** (`flow = "imports"`, importer perspective):

| aggregation | n | term columns | id columns |
|-------------|---|--------------|------------|
| country     | 3 | GIMP VA DC   | Importing_Country |
| bilateral   | 2 | VA DC        | Importing_Country, Origin_Country |

`world` is country-only; `self` is sector/bilateral-only; sectoral imports (`sectimp`) and the
world-source/self VAX are **not** deferred here — they are all delivered except `sectimp`
(same deferral as Julia: throw a clear "not implemented" error).

## Field mapping: Julia `ICIOModel` → icio object

The icio object (from `load_icio`) already carries almost everything. The one gap:
Julia uses the **full** coefficient matrix `A` (incl. domestic blocks), while icio stores only
`Am` (foreign `A`, domestic blocks zeroed). Reconstruct the full `A` cheaply from the
block-diagonal local Leontief `L`:

```
A_gg = I_N − solve(L[g-block, g-block])          # since L_gg = (I − A_gg)^{-1}
A    = Am; for g: A[g-block, g-block] <- A_gg     # foreign blocks already in Am
```

(G cheap N×N inverses — much cheaper than reinverting `B`.) Then:

| Julia field / helper | icio / bm.R |
|----------------------|----------------|
| `G,N,GN`             | `G,N,GN` |
| `X` (output)         | `X` (= o) |
| `V` (VA coef v/o)    | `Vc` |
| `A` (full)           | **reconstructed** `Am + blockdiag(I − solve(L_gg))` |
| `B`                  | `B` |
| `L` (block-diag)     | `L` |
| `E`, `ESR`           | `E`, `ESR` |
| `FD` (= Y)           | `Y` |
| `Yd`, `Ym`           | `Yd`, `Ym` |
| `VBdom`              | `colSums2(Bd * Vc)` |
| `VBfor`              | `colSums2(Bm * Vc)` |
| `VLdom`              | `colSums2(L  * Vc)` |
| `fvacoef`            | per-country `solve(t(I + M_s), VBfor_s)`, `M_s = Am_s· B_·s` |
| `_BFD` = `B·FD`      | `BFD <- B %*% Y` |
| `_Wcol`              | `Wcol <- L %*% Yd[idiag]` |
| `ctry(i)`            | `ctryvec` |
| `blockrange(g)`      | `blk(g) <- (g-1)*N + seq_len(N)` |

## Code structure (`R/bm.R`)

Refactor the monolithic `bm()` into a **dispatcher + shared prep + one engine per variant**,
each engine a faithful port of the matching Julia function. All internal (`.bm_*`), un-exported,
kept in `bm.R` (icio keeps one file per decomposition).

* `bm(x, aggregation, perspective, approach, flow)` — validate the combination (clear errors
  listing valid options per `flow`), build prep, route, assemble `data.frame` (`attr =
  "decomposition" = "bm"`).
* `.bm_prep(x)` → list of all shared objects above (full `A`, `B`, `L`, coef vectors, `BFD`,
  `Wcol`, `blk`, `ctryvec`, `idiag`, …). Engines start with `list2env(P, environment())`.
* `.bm_source(P, aggregation)` — existing 13-term source logic (country/sector/bilateral),
  unchanged. Ports `_source_sector` / `_source_bilateral` (already validated).
* `.bm_world(P, approach)` — country FVA/FDC only; domestic side + FC from `.bm_source` country.
  * sink: existing eq. 54 code (`Wrex`, `TC`).
  * **source (new)**: eq. 52 — `FVA_s = Σ_{t∉s} VLdom_t · (A[:,s-block] · (L_ss E_s))_t`.
* `.bm_sink(P, aggregation)` — ports `_sink_sector` / `_sink_bilateral` (eq. 33–39). Per exporter
  `s`: `Fs = (I−A_ss) B_ss`; `Xtil = X − B_·s (Fs\E_s)`, `Xtil_s = BFD_·s − B_·s(Fs\rhs_s)`;
  per importer `r` the brackets `Φ_sr`, `Φ^ref_sr`; DVA=VBdom·Φ, FVA=VBfor·Φ, REF=VBdom·Φ^ref,
  VAX=DVA−REF. Bilateral adds **VAXIM** = VBdom·Φ^vx (absorbed-in-r output). DC/FC = source values.
* `.bm_self(P, aggregation)` — ports `_self_sector` / `_self_bilateral` (eq. 47–49). Rank-1
  perimeter update: denom `1+α`, α = `Ms[n,n]` (sectexp, `Ms=(B_ss−I)−A_ss B_ss`) or
  `(A_sr B_rs)[n,n]` (sectbil). DVA★=VBdom/(1+α)·e, FVA★=VBfor/(1+α)·e; VAX★=(DVA★/e)·VAXE,
  REF★=DVA★−VAX★; DC/FC perimeter-invariant.
* `.bm_imports(P, aggregation)` — ports `_imports_core` (+ country/bilateral). Per importer `r`:
  column-block Woodbury `B̃^r` from cached `B` (`K_r = B_rr(I−A_rr)`, `BMcol = B_·r(I−A_rr) − I_·r`),
  `VA = Vc·(B̃^r d^r)`, `DC = Vc·(B̃^r h^r)`, `h^r = (A_·r (B d^r)_r)` with r-block zeroed;
  `gimp = va+dc`. Bilateral keeps the origin index `j`.

Column names stay **UPPER-CASE** (existing bm() convention); id columns are factors
(`Exporting_Country`, `Exporting_Industry`, `Importing_Country`, new `Origin_Country`).

## Numerical anchors (why this is correct without re-deriving the math)

Every new R engine is a line-by-line port of a Julia engine already Stata-validated to ~1e-6 and
mutually cross-checked by BM2019 identities. The R port inherits those guarantees and is
additionally checked against Julia to ~1e-13 (double precision, same algorithm) in
`misc/validate_bm_emerging.R`.

## Tests (`tests/testthat/test_bm.R`, leather toy table — no Stata/Julia needed)

Add `test_that` blocks mirroring Julia's `runtests.jl` identity/anchor set:

* **Sizes**: sector/self 9 terms, bilateral/sink 10 (VAXIM), bilateral/self 9, imports
  country 3 / bilateral 2; correct row counts.
* **Accounting identities** per new variant: `GEXP=DC+FC`, `DC=DVA+DDC`, `FC=FVA+FDC`,
  `DVA=VAX+REF`; imports `GIMP=VA+DC`; non-negativity.
* **Cross-engine anchors** (pin new engines to source/world already tested):
  * `Σ_r sink DVA/FVA/VAX/REF (over importers) == country/source` (sector & bilateral).
  * `sink DC == source DC`, `sink FC == source FC` elementwise.
  * `DAVAX ≤ VAXIM ≤ VAX` (bilateral sink).
  * world source & world sink FVA share the same world total; both ≤ FC.
  * self `DVA★ ≥ DVAsource` and `≥ DVAsink`; self `DC == source DC`.
  * imports: `Σ_r gimp == Σ_s gexp`; origin va sums to importer va.
* **Option validation**: new error paths (`world` at sector, `self` at country, `sectimp`).

## Meta / docs

* `R/bm.R` roxygen: document `flow`, `"self"`/`"importer"` perspectives, sink/self approaches,
  the full variant table, VAXIM/GIMP/VA terms, and imports id columns. Regenerate `man/bm.Rd`
  and `NAMESPACE` with `devtools::document()`.
* `R/decomp.R`: no code change (passes `...`), add a `flow`/`perspective` example.
* `NEWS.md`: expand the 7.0.0 `bm()` bullet to list the full surface (bm() is unreleased in
  7.0.0, so enrich that entry rather than bump; note here if a bump is preferred).
* `misc/validate_bm_emerging.R`: extend to diff all new variants against the Julia
  `EM_GVC_*_STATA`/reference CSVs (world/source, sector/sink, bilateral/sink, sector/self,
  bilateral/self, imports).

## Verification

1. `devtools::document()` then `devtools::test()` — all old + new testthat blocks green.
2. `R CMD check` clean.
3. `Rscript misc/validate_bm_emerging.R` — every variant agrees with Julia to ~1e-13 on EMERGING.

## Deferred (same as Julia)

* `sectimp` (`flow="imports", aggregation="sector"`) — clear "not implemented" error.
* `origin()/destination()` supply–demand matrix, Excel export, `groups()` aggregation.
