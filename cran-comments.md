# Resubmission

Thanks for the review. All four points have been addressed:

1. **Software names in single quotes in Title and Description.** The Description now
   writes `'Stata'` and the `'icio'` command in single quotes. (The Title names no
   software.)

2. **References with linking.** The Description's plain-text reference block has been
   replaced by inline references in the `authors (year) <doi:...>` form, with no space
   after `doi:`:
   - Hummels, Ishii and Yi (2001) <doi:10.1016/S0022-1996(00)00093-3>
   - Koopman, Wang and Wei (2014) <doi:10.1257/aer.104.2.459>
   - Wang, Wei and Zhu (2013) <doi:10.3386/w19677>
   - Borin and Mancini (2019) <doi:10.1596/1813-9450-8804>
   - Belotti, Borin and Mancini (2021) <doi:10.1177/1536867X211045573>

3. **`\dontrun{}`.** The only occurrence was in `load_icio_csv()`, where the example read
   CSV files that were not shipped. Rather than switching to `\donttest{}`, the example is
   now fully executable and unwrapped: it writes the built-in `leather` table to
   `tempfile()`s in the 'icio' CSV format, reads them back, and unlinks them. It runs in
   well under a second. No `\dontrun{}` or `\donttest{}` remains in the package.

4. **Resetting `options()`.** The vignette set `options(width = 90)` without restoring it.
   It now saves the previous value (`oldopts <- options(width = 90)`) and restores it with
   `options(oldopts)` in a final chunk. The package sets no other options, and no graphical
   parameters or working directory anywhere in examples, vignettes or tests.

Also fixed while re-checking: `.Rbuildignore` did not exclude an editor workspace file in
the package root, which produced a "Non-standard file/directory found at top level" NOTE.


# Submission

This is the first submission of `icio`.

`icio` is a rename and consolidation of the CRAN package `decompr`, whose maintainer
(Bastiaan Quast) is no longer active. I am a co-author of `decompr` and am taking the
package over under the new name; Bastiaan Quast and the other `decompr` authors are
retained as authors. `decompr` remains on CRAN and is unaffected by this submission.

The name `icio` refers to inter-country input-output tables and matches the 'Stata' `icio`
command (Belotti, Borin and Mancini 2021) whose decompositions the package reproduces.

Possibly misspelled words in DESCRIPTION are surnames (Borin, Mancini, Koopman, Hummels,
Ishii, Yi, Zhu, Belotti) and the abbreviations ICIO and GVC.


# Test environments

- local macOS install, R 4.6.0
- GitHub Actions
   - Windows Server, R release
   - macOS, R release
   - macOS, R devel
   - Ubuntu, R release


# R CMD check

0 errors | 0 warnings | 1 note

The remaining note is the unavoidable "New submission".
