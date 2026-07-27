# define context
context("leontief")

# load test data
data(leather)
list2env(leather, environment())

dec <- load_icio(leather)

# leontief decomposition
# with default post-multiplication (exports)
l <- decomp(dec, method = "leontief")

# test output format (i.e. structure not numbers)
test_that("output size matches", {
  expect_equal( length(l), 5 )
  expect_equal( dim(l)[1], 81 )
})

test_that("output format matches", {
  expect_match( typeof(l[[5]]), "double" )
})

# test output content (i.e. numbers)
test_that("output matches", {
  expect_equal( l[[5]][1],  28.52278, tolerance = .002 )
  expect_equal( l[[5]][81], 34.74381, tolerance = .002 )
})


context("leontief-output")

# leontief decomposition
lo <- decomp(dec, method = "leontief", post = "output")

test_that("output size matches", {
  expect_equal( length(lo), 5 )
  expect_equal( dim(lo)[1], 81 )
})

test_that("output format matches", {
  expect_match(typeof( lo[[5]]), "double" )
})

# test output content (i.e. numbers)
test_that("output matches", {
  expect_equal( lo[[5]][1],  66.75361799, tolerance = .002 )
  expect_equal( lo[[5]][81], 96.78316785, tolerance = .002 )
})


context("leontief-finalDemand")

# leontief decomposition
lfd <- decomp(dec, method = "leontief", post = "final_demand")

test_that("output size matches", {
  expect_equal( length(lfd), 4)
  expect_equal( dim(lfd)[1], 27)
})

test_that("output format matches", {
  expect_match(typeof(lfd[[4]]), "double")
})

# test output content (i.e. numbers)
test_that("output matches", {
  expect_equal(lfd[[4]][1], 24.3345824, tolerance = .002)
  expect_equal(lfd[[4]][20], 23.6841309, tolerance = .002)
})

test_that("long = FALSE returns the matrix", {
  lm <- leontief(dec, long = FALSE)
  expect_true(is.matrix(lm))
  expect_equal(dim(lm), c(9L, 9L))
  expect_false(attr(lm, "long"))
})
