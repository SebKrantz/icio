# Validate icio::bm() on the EMERGING ICIO data against GlobalValueChains.jl (Julia), whose
# output is itself validated to ~1e-6 against the Stata `icio` command. The two implementations
# share the same algorithm, so they should agree to ~1e-12 (double precision).
#
# Local/dev script (misc/ is git-ignored). Requires the EMERGING .qs2 table and the Julia-generated
# reference CSVs under ICIO_CSV/EMERGING_Broad_Sectors/ (regenerate with the Julia harness
# misc/ICIO_decomp_variants.jl). Run:
#
#   Rscript misc/validate_bm_emerging.R

suppressMessages({
  devtools::load_all(quiet = TRUE)   # run from the package root
  library(qs2); library(data.table)
})

base <- "/Users/sebastiankrantz/Documents/Data/EMERGING/ICIO_CSV/EMERGING_Broad_Sectors"
qs2f <- "/Users/sebastiankrantz/Documents/Data/EMERGING/EMERGING_Broad_Sectors.qs2"
yr   <- 2015L

EM  <- qs_read(qs2f)
d   <- EM$DATA[[as.character(yr)]]
# residual VA (no o/v) -> matches icio / GlobalValueChains.jl read_icio_csv
dec <- load_icio(d$T, d$FD, EM$Regions$ISO3, EM$Sectors$Broad_Sector_Code)

## Read a Julia reference CSV, drop an optional `year` column (filter to yr).
read_ref <- function(file) {
  R <- fread(file.path(base, file))
  if ("year" %in% names(R)) R <- R[year == yr][, year := NULL]
  R[]
}

## Diff R output `Rd` against Julia reference `J`. `idmap` maps R id columns -> Julia id columns;
## `terms` are the (lower-case Julia) term columns, matched by name (order-independent). Inner-joins
## on ids, so a sample reference automatically restricts the comparison.
report <- function(tag, Rd, J, idmap, terms) {
  Rd <- as.data.table(Rd); J <- as.data.table(J)
  for (rc in names(idmap)) Rd[[idmap[[rc]]]] <- as.character(Rd[[rc]])
  for (tc in terms)        Rd[[paste0(tc, ".R")]] <- as.numeric(Rd[[toupper(tc)]])
  ids  <- unname(unlist(idmap))
  keep <- c(ids, paste0(terms, ".R"))
  m <- merge(J, Rd[, ..keep], by = ids)
  cat(sprintf("== %-40s (%d / %d rows) ==\n", tag, nrow(m), nrow(J)))
  worst <- 0
  for (tc in terms) {
    a <- as.numeric(m[[tc]]); b <- m[[paste0(tc, ".R")]]
    big <- abs(a) > 1; mrel <- if (any(big)) max(abs(a[big] - b[big]) / abs(a[big])) else 0
    mabs <- max(abs(a - b)); worst <- max(worst, mrel)
    cat(sprintf("   %-6s maxrel=%.2e  maxabs=%.3g\n", tc, mrel, mabs))
  }
  cat(sprintf("   -> worst maxrel = %.2e  %s\n\n", worst, if (worst < 1e-9) "OK" else "**CHECK**"))
}

T13 <- c("gexp","dc","dva","vax","davax","ref","ddc","fc","fva","fdc","gvc","gvcb","gvcf")
T9  <- c("gexp","dc","dva","vax","ref","ddc","fc","fva","fdc")
T10 <- c("gexp","dc","dva","vax","vaxim","ref","ddc","fc","fva","fdc")
idC <- list(Exporting_Country = "country")
idS <- list(Exporting_Country = "from_region", Exporting_Industry = "from_sector")
idB <- list(Exporting_Country = "from_region", Exporting_Industry = "from_sector",
            Importing_Country = "to_region")

## country/source reference: aggregate the sector/source reference to country
secref <- read_ref("EM_GVC_SEC_BM19.csv")
ctyref <- secref[, lapply(.SD, sum), by = .(country = from_region), .SDcols = T13]

## 1. country, exporter/source (13)
report("country exporter/source", bm(dec), ctyref, idC, T13)
## 2. country, world/sink (9)
report("country world/sink", bm(dec, perspective = "world", approach = "sink"),
       read_ref("EM_GVC_KWW_BM19.csv"), idC, T9)
## 3. country, world/source (9)
report("country world/source", bm(dec, perspective = "world", approach = "source"),
       read_ref("EM_GVC_KWW_WS_BM19.csv"), idC, T9)
## 4. sector, exporter/source (13)
report("sector exporter/source", bm(dec, aggregation = "sector"), secref, idS, T13)
## 5. sector, exporter/sink (9)
report("sector exporter/sink", bm(dec, aggregation = "sector", approach = "sink"),
       read_ref("EM_GVC_SEC_SINK_BM19.csv"), idS, T9)
## 6. sector, self (9)
report("sector self", bm(dec, aggregation = "sector", perspective = "self"),
       read_ref("EM_GVC_SEC_SELF_BM19.csv"), idS, T9)
## 7. bilateral, exporter/source (13) -- sample. NB: this older reference indexes sectors by
## integer AND was written at ~7 significant figures, so expect ~1e-6 relative (CSV precision),
## not the ~1e-12 of the freshly-written references. The source bilateral engine is unchanged.
bsref <- read_ref("EM_GVC_BIL_SEC_SAMPLE.csv")
if (is.numeric(bsref$from_sector))
  bsref[, from_sector := EM$Sectors$Broad_Sector_Code[from_sector]]
report("bilateral exporter/source", bm(dec, aggregation = "bilateral"), bsref, idB, T13)
## 8. bilateral, exporter/sink (10, +VAXIM) -- sample
report("bilateral exporter/sink", bm(dec, aggregation = "bilateral", approach = "sink"),
       read_ref("EM_GVC_BIL_SINK_SAMPLE.csv"), idB, T10)
## 9. bilateral, self (9) -- sample
report("bilateral self", bm(dec, aggregation = "bilateral", perspective = "self"),
       read_ref("EM_GVC_BIL_SELF_SAMPLE.csv"), idB, T9)
## 10. imports, country (gimp va dc)
report("imports country", bm(dec, flow = "imports"),
       read_ref("EM_GVC_IMP_BM19.csv"), list(Importing_Country = "importer"),
       c("gimp","va","dc"))
