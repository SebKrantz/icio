library(icio)

data(leather)
list2env(leather, environment())

context("load_icio")

dec <- load_icio(leather)

test_that("an 'iot' object and the raw matrices give the same result", {
  expect_s3_class(dec, "icio")
  expect_equal(dec, load_icio(inter, final, countries, industries))
  expect_equal(dec, load_icio(inter, final, countries, industries, output = out))
})

test_that("the 'out' element of an 'iot' object is picked up as output", {
  # leather's output vector is named 'out'; a deliberately different one must come through
  iot2 <- leather
  iot2$out <- out * 2
  expect_equal(unname(suppressMessages(load_icio(iot2))$X), unname(out * 2))
})

test_that("object structure is as documented", {
  expect_named(dec, c("A", "B", "Lb", "E", "ESR", "Vc", "G", "N", "GN",
                      "k", "i", "X", "Y", "Yd", "Ym"))
  expect_equal(c(dec$G, dec$N, dec$GN), c(3L, 3L, 9L))
  expect_equal(dim(dec$A), c(9L, 9L))
  expect_equal(dim(dec$B), c(9L, 9L))
  expect_length(dec$Lb, 3L)                      # one N x N block per country
  expect_equal(dim(dec$Lb[[1L]]), c(3L, 3L))
  expect_equal(unname(dec$E), unname(rowSums(dec$ESR)))
  expect_equal(dec$Y, dec$Yd + dec$Ym)
  expect_identical(dimnames(dec$B)[[1L]], names(dec$Vc))
})

test_that("dimension mismatches are caught", {
  expect_error(load_icio(inter, final, countries, industries[1:2]), "does not match")
  expect_error(load_icio(inter, final[1:6, ], countries, industries), "does not match")
  expect_error(load_icio(inter, final[, 1:2], countries, industries), "not a multiple")
})

context("load_icio_csv")

test_that("the icio CSV format round-trips", {
  tbl <- tempfile(fileext = ".csv")
  cl  <- tempfile(fileext = ".csv")
  on.exit(unlink(c(tbl, cl)))
  utils::write.table(cbind(unname(inter), unname(final)), tbl,
                     sep = ",", row.names = FALSE, col.names = FALSE)
  utils::write.table(countries, cl, sep = ",", row.names = FALSE, col.names = FALSE,
                     quote = FALSE)

  m <- load_icio_csv(tbl, cl, industries = industries)
  expect_s3_class(m, "icio")
  expect_equal(unname(m$E), unname(dec$E))
  expect_equal(unname(m$B), unname(dec$B))
  expect_equal(bm(m)$GEXP, bm(dec)$GEXP)

  # countries may be given directly, industries default to sector1..sectorN
  m2 <- load_icio_csv(tbl, countries)
  expect_identical(m2$i, c("sector1", "sector2", "sector3"))
  expect_equal(unname(m2$E), unname(dec$E))

  expect_error(load_icio_csv(tbl, countries, industries = industries[1:2]), "expected N")
  expect_error(load_icio_csv(tbl, c(countries, "XXX")), "not divisible")
})
