# load the package
library(icio)

# load test data
data(leather)
list2env(leather, environment())

dec <- load_icio(leather)

# WWZ decomposition
w <- decomp(dec, method = "wwz")

# define context
context("output format")

test_that("output size matches", {
  expect_equal(length(w), 29 )
  expect_equal(dim(w)[1], 27 )
})

test_that("output format matches", {
  expect_match(typeof(w[[5]]), "double")
})


# test that verbose turns some messages on
test_that("verbose computation 1/2",
          expect_message(decomp(dec, method = "wwz", verbose = TRUE),
                         "Starting decomposing the trade flow"))

test_that("verbose computation 2/2",
          expect_message(decomp(dec, method = "wwz", verbose = TRUE),
                         "16/16, elapsed time:"))

##
## Custom va
##
context("custom va")

va <- out - colSums(inter)

## WWZ decomposition: specify va
w.2 <- decomp(load_icio(inter, final, countries, industries, output = out, va = va),
              method = "wwz")

test_that("specifying va leaves output unchanged",
          expect_equal(w.2, w))   # not identical(): each data.table has its own selfref


## WWZ decomposition: only argentina
va[4:9] <- 0
w.arg <- decomp(load_icio(inter, final, countries, industries, output = out, va = va),
                method = "wwz")

test_that("only argentina has positive numbers",
          expect_true(any(w.arg$DVA_FIN[1:9] > 0)))

test_that("turkey and germany are 0",
          expect_true(all(w.arg$DVA_FIN[10:27] == 0)))


## now we only care about the transport_equipment industry
va <- out - colSums(inter)
va[1:9 %% 3 != 0] <- 0
w.transport <- decomp(load_icio(inter, final, countries, industries, output = out, va = va),
                      method = "wwz")

within <- w.transport$Exporting_Country == w.transport$Importing_Country
test_that("only within-country flows are 0",
          expect_true(all(w.transport$DVA_FIN[within] == 0)))

test_that("all others should be greater than 0",
          expect_true(all(w.transport$DVA_FIN[!within] > 0)))
