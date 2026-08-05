# load the package
library(icio)

# load test data
data(leather)
list2env(leather, environment())

dec <- load_icio(leather)

# base-R column selection: `DT[cols]` does not subset columns in data.table
cols <- function(d, x) as.data.frame(d)[x]

context("bm output format")

cty <- bm(dec)                                          # country, exporter/source (13 terms)
sec <- bm(dec, aggregation = "sector")
bil <- bm(dec, aggregation = "bilateral")
ws  <- bm(dec, perspective = "world", approach = "sink")  # country, world/sink (9 terms)

test_that("output sizes match", {
  expect_equal(dim(cty), c(3L, 14L))   # 1 id + 13 terms
  expect_equal(dim(sec), c(9L, 15L))   # 2 id + 13 terms
  expect_equal(dim(bil), c(18L, 16L))  # 3 id + 13 terms, within-country excluded (3*3*2)
  expect_equal(dim(ws),  c(3L, 10L))   # 1 id + 9 terms
})

test_that("identifier columns are factors and terms are double", {
  expect_s3_class(bil$Exporting_Country, "factor")
  expect_s3_class(bil$Importing_Country, "factor")
  expect_match(typeof(sec$GVC), "double")
  expect_true(all(bil$Exporting_Country != bil$Importing_Country))  # self-pairs excluded
  expect_identical(attr(cty, "decomposition"), "bm")
})

test_that("decomp() interface dispatches to bm", {
  d <- decomp(dec, aggregation = "sector")          # bm is the default method
  expect_equal(d$GVC, sec$GVC)
  expect_equal(decomp(dec, method = "bm", aggregation = "sector"), d)
})

test_that("decomp() stacks a list of 'icio' objects", {
  st <- decomp(list(`2015` = dec, `2016` = dec), aggregation = "sector", idcol = "Year")
  expect_equal(dim(st), c(2L * nrow(sec), ncol(sec) + 1L))
  expect_identical(names(st)[1L], "Year")
  expect_identical(unique(st$Year), c("2015", "2016"))
  expect_equal(st$GVC, rep(sec$GVC, 2L))
  expect_false("Label" %in% names(decomp(list(dec, dec), idcol = NULL)))
})

test_that("decomp() rejects raw tables and non-'icio' input", {
  expect_error(decomp(leather), "must be an 'icio' object")
  expect_error(decomp(list(dec, 1)), "must be an 'icio' object")
})

context("bm accounting identities")

test_that("identities hold (sector level)", {
  expect_equal(sec$GEXP, sec$DC + sec$FC)
  expect_equal(sec$DC,   sec$DVA + sec$DDC)
  expect_equal(sec$FC,   sec$FVA + sec$FDC)
  expect_equal(sec$DVA,  sec$VAX + sec$REF)
  expect_equal(sec$GVC,  sec$GVCB + sec$GVCF)
  expect_equal(sec$GVC,  sec$GEXP - sec$DAVAX)
  expect_equal(sec$GVCB, sec$FC + sec$DDC)
})

test_that("no negative GVC or gross exports", {
  expect_true(all(sec$GVC  >= -1e-9))
  expect_true(all(sec$GEXP >= -1e-9))
})

context("bm additivity")

test_that("bilateral sums to sector", {
  agg <- aggregate(cols(bil, c("GEXP", "DVA", "FVA", "DAVAX", "GVC")),
                   list(Exporting_Country = bil$Exporting_Country,
                        Exporting_Industry = bil$Exporting_Industry), sum)
  agg <- agg[order(agg$Exporting_Country, agg$Exporting_Industry), ]
  so  <- sec[order(sec$Exporting_Country, sec$Exporting_Industry), ]
  for (cl in c("GEXP", "DVA", "FVA", "DAVAX", "GVC"))
    expect_equal(so[[cl]], agg[[cl]], tolerance = 1e-8)
})

test_that("sector sums to country", {
  agg <- aggregate(cols(sec, c("GEXP", "DVA", "FVA", "GVC")),
                   list(Exporting_Country = sec$Exporting_Country), sum)
  for (cl in c("GEXP", "DVA", "FVA", "GVC"))
    expect_equal(cty[[cl]], agg[[cl]], tolerance = 1e-8)
})

context("bm cross-checks vs kww")

test_that("world/sink domestic terms and FC match kww aggregates", {
  K <- kww(dec)
  expect_equal(ws$GEXP, rowSums(K[, -1]), tolerance = 1e-8)            # gross exports
  expect_equal(ws$DVA,  K$DVA_FIN + K$DVA_INT + K$DVA_INTrex +
                        K$RDV_FIN + K$RDV_INT, tolerance = 1e-8)        # total DVA
  expect_equal(ws$DDC,  K$DDC, tolerance = 1e-8)                        # domestic double counting
  expect_equal(ws$FC,   K$FVA_FIN + K$FVA_INT + K$FDC, tolerance = 1e-8)# foreign content
})

test_that("world/sink and exporter/source share domestic side and FC", {
  for (cl in c("GEXP", "DC", "DVA", "VAX", "REF", "DDC", "FC"))
    expect_equal(ws[[cl]], cty[[cl]], tolerance = 1e-8)
})

context("bm value-added zeroing")

test_that("only the origin country has positive domestic value added", {
  va <- out - colSums(inter)
  va[4:9] <- 0  # keep only Argentina's value added (country-sectors 1:3)
  s.arg <- decomp(load_icio(inter, final, countries, industries, output = out, va = va),
                  aggregation = "sector")
  expect_true(all(s.arg$DVA[1:3] > 0))   # Argentina
  expect_true(all(s.arg$DVA[4:9] == 0))  # Turkey and Germany
})

## ------------------------------------------------------------------------------------------------
## Extended Borin-Mancini variants: exporter/sink, self perimeter, world/source, imports
## ------------------------------------------------------------------------------------------------

wsrc <- bm(dec, perspective = "world", approach = "source")   # country, world/source (9 terms)
seck <- bm(dec, aggregation = "sector",    approach = "sink")   # sector, exporter/sink (9 terms)
bilk <- bm(dec, aggregation = "bilateral", approach = "sink")   # bilateral, exporter/sink (10 terms)
secs <- bm(dec, aggregation = "sector",    perspective = "self")   # sector, self (9 terms)
bils <- bm(dec, aggregation = "bilateral", perspective = "self")   # bilateral, self (9 terms)
impc <- bm(dec, flow = "imports")                               # imports, country (3 terms)
impb <- bm(dec, flow = "imports", aggregation = "bilateral")    # imports, bilateral (2 terms)

context("bm extended variants: output format")

test_that("output sizes match", {
  expect_equal(dim(wsrc), c(3L, 10L))   # 1 id + 9 terms
  expect_equal(dim(seck), c(9L, 11L))   # 2 id + 9 terms
  expect_equal(dim(bilk), c(18L, 13L))  # 3 id + 10 terms (adds VAXIM)
  expect_equal(dim(secs), c(9L, 11L))   # 2 id + 9 terms
  expect_equal(dim(bils), c(18L, 12L))  # 3 id + 9 terms
  expect_equal(dim(impc), c(3L, 4L))    # 1 id + 3 terms
  expect_equal(dim(impb), c(9L, 4L))    # 2 id + 2 terms (all origins incl. self)
  expect_true("VAXIM" %in% names(bilk))
  expect_identical(attr(impc, "decomposition"), "bm")
})

context("bm extended variants: accounting identities")

test_that("identities hold for every new export variant", {
  for (d in list(wsrc, seck, bilk, secs, bils)) {
    expect_equal(d$GEXP, d$DC + d$FC)
    expect_equal(d$DC,   d$DVA + d$DDC)
    expect_equal(d$FC,   d$FVA + d$FDC)
    expect_equal(d$DVA,  d$VAX + d$REF)
  }
  expect_equal(impc$GIMP, impc$VA + impc$DC)                    # imports
  for (d in list(wsrc, seck, bilk, secs, bils, impc, impb))
    for (cl in setdiff(names(d), c("Exporting_Country","Exporting_Industry",
                                   "Importing_Country","Origin_Country")))
      expect_true(all(d[[cl]] >= -1e-9))                        # non-negativity
})

context("bm extended variants: cross-engine anchors")

test_that("exporter/sink aggregates over importers to exporter/source (country totals)", {
  agg <- aggregate(cols(seck, c("DVA","FVA","VAX","REF")),
                   list(Exporting_Country = seck$Exporting_Country), sum)
  for (cl in c("DVA","FVA","VAX","REF")) expect_equal(cty[[cl]], agg[[cl]], tolerance = 1e-8)
  expect_equal(seck$DC, sec$DC, tolerance = 1e-8)               # DC/FC perimeter-invariant
  expect_equal(seck$FC, sec$FC, tolerance = 1e-8)
})

test_that("world source and sink FVA share the same world total and are <= FC", {
  expect_equal(sum(wsrc$FVA), sum(ws$FVA), tolerance = 1e-8)
  expect_true(all(wsrc$FVA <= wsrc$FC + 1e-9))
  expect_true(all(ws$FVA   <= ws$FC   + 1e-9))
})

test_that("bilateral sink nests DAVAX <= VAXIM <= VAX", {
  key <- function(d) paste(d$Exporting_Country, d$Exporting_Industry, d$Importing_Country)
  o1 <- order(key(bil)); o2 <- order(key(bilk))
  expect_true(all(bilk$VAXIM[o2] - bil$DAVAX[o1] >= -1e-9))
  expect_true(all(bilk$VAX[o2]   - bilk$VAXIM[o2] >= -1e-9))
})

test_that("self perimeter dominates the exporter DVA (eq. 46) and shares DC", {
  key <- function(d) paste(d$Exporting_Country, d$Exporting_Industry, d$Importing_Country)
  o1 <- order(key(bil)); o2 <- order(key(bilk)); os <- order(key(bils))
  expect_true(all(bils$DVA[os] - bil$DVA[o1]  >= -1e-9))
  expect_true(all(bils$DVA[os] - bilk$DVA[o2] >= -1e-9))
  expect_equal(bils$DC[os], bil$DC[o1], tolerance = 1e-8)
})

test_that("imports are world-consistent and additive over origin", {
  expect_equal(sum(impc$GIMP), sum(cty$GEXP), tolerance = 1e-8)
  agg <- aggregate(cols(impb, c("VA","DC")), list(Importing_Country = impb$Importing_Country), sum)
  expect_equal(impc$VA, agg$VA, tolerance = 1e-8)
  expect_equal(impc$DC, agg$DC, tolerance = 1e-8)
})

context("bm extended variants: option validation")

test_that("invalid combinations raise clear errors", {
  expect_error(bm(dec, perspective = "self"),                        "sector.*bilateral")
  expect_error(bm(dec, aggregation = "sector", perspective = "world"), "only.*country")
  expect_error(bm(dec, flow = "imports", aggregation = "sector"),    "not yet implemented")
  expect_error(bm(dec, perspective = "importer"),                    "flow = 'imports'")
})
