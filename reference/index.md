# Package index

- [`icio`](https://sebkrantz.github.io/icio/reference/icio-package.md)
  [`icio-package`](https://sebkrantz.github.io/icio/reference/icio-package.md)
  : Global Value Chain Decomposition of Inter-Country Input-Output
  Tables

## Data Input

Parse raw ICIO table matrices, or the Stata `icio` CSV format, into an
`icio` class object.

- [`load_icio()`](https://sebkrantz.github.io/icio/reference/load_icio.md)
  : Load an Inter-Country Input-Output Table
- [`load_icio_csv()`](https://sebkrantz.github.io/icio/reference/load_icio_csv.md)
  : Load an ICIO Table from the 'icio' CSV Format

## Leontief Decomposition

Derive the value-added origin of exports by country and industry
(Hummels, Ishii & Yi 2001).

- [`leontief()`](https://sebkrantz.github.io/icio/reference/leontief.md)
  : Leontief Decomposition

## Koopman-Wang-Wei (KWW) Decomposition

Split country-level exports into 9 value-added components (Koopman, Wang
& Wei 2014).

- [`kww()`](https://sebkrantz.github.io/icio/reference/kww.md) :
  Koopman-Wang-Wei Decomposition of Gross Exports
- [`wwz2kww()`](https://sebkrantz.github.io/icio/reference/wwz2kww.md) :
  Koopman-Wang-Wei from Wang-Wei-Zhu Decomposition

## Wang-Wei-Zhu (WWZ) Decomposition

Split bilateral exports into 16 value-added components by importing
country (Wang, Wei & Zhu 2013).

- [`wwz()`](https://sebkrantz.github.io/icio/reference/wwz.md) :
  Wang-Wei-Zhu Decomposition of Gross Exports

## Borin-Mancini (BM) Decomposition

Split gross exports into up to 13 value-added and GVC participation
components (Borin & Mancini 2019).

- [`bm()`](https://sebkrantz.github.io/icio/reference/bm.md) :
  Borin-Mancini Decomposition of Gross Exports and Imports

## Convenience Interface

Run any decomposition with a single call, also across several ICIO
tables (e.g. one per year).

- [`decomp()`](https://sebkrantz.github.io/icio/reference/decomp.md) :
  Run a GVC Decomposition

## Example Data

Built-in 3×3 ICIO table (leather sector) for testing and learning.

- [`leather`](https://sebkrantz.github.io/icio/reference/leather.md) :
  Leather Example ICIO Data
