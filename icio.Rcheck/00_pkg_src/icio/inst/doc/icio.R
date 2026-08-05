## ----setup, include=FALSE---------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  fig.width = 7
)
options(width = 90)

## ----data-------------------------------------------------------------------------------
library(icio)
data(leather)

leather$countries
leather$industries

# Intermediate demand matrix (9 × 9)
leather$inter

# Final demand matrix (9 × 3)
leather$final

# Gross output vector (length 9)
leather$out

## ----load-------------------------------------------------------------------------------
x <- load_icio(leather)
class(x)
names(x)

## ----dims-------------------------------------------------------------------------------
x$G  # number of countries
x$N  # number of industries

## ----vc---------------------------------------------------------------------------------
round(x$Vc, 3)

## ----exports----------------------------------------------------------------------------
round(x$E, 2)

## ----leontief---------------------------------------------------------------------------
leo <- leontief(x)
head(leo, 12)

## ----kww--------------------------------------------------------------------------------
kww(x)

## ----wwz--------------------------------------------------------------------------------
wz <- wwz(x)
dim(wz)
names(wz)

## ----wwz-slice--------------------------------------------------------------------------
# DVA_FIN for all exporters into Germany
subset(wz, Importing_Country == "Germany",
       select = c(Exporting_Country, Exporting_Industry, DVA_FIN))

## ----wwz2kww----------------------------------------------------------------------------
wwz2kww(wz)

## ----bm-country-------------------------------------------------------------------------
bm(x)

## ----bm-sector--------------------------------------------------------------------------
bm(x, aggregation = "sector")

## ----bm-bilateral-----------------------------------------------------------------------
bm(x, aggregation = "bilateral")

## ----bm-worldsink-----------------------------------------------------------------------
bm(x, perspective = "world", approach = "sink")

## ----decomp-----------------------------------------------------------------------------
decomp(x, method = "leontief")
decomp(x, aggregation = "sector")

## ----decomp-list------------------------------------------------------------------------
decomp(list(`2015` = x, `2016` = x), idcol = "Year")

