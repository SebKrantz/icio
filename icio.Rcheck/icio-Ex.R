pkgname <- "icio"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('icio')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("bm")
### * bm

flush(stderr()); flush(stdout())

### Name: bm
### Title: Borin-Mancini Decomposition of Gross Exports and Imports
### Aliases: bm

### ** Examples

# Load example data and create an 'icio' object
data(leather)
dec <- load_icio(leather)

# Country-level decomposition (exporter perspective, source approach; 13 terms)
bm(dec)

# Country-level "corrected KWW" (world perspective, sink approach; 9 terms)
bm(dec, perspective = "world", approach = "sink")

# Sector- and bilateral-sector-level decompositions
bm(dec, aggregation = "sector")
bm(dec, aggregation = "bilateral", approach = "sink")   # adds VAXIM

# Self (own-flow) perimeter, and the importer-perspective import decomposition
bm(dec, aggregation = "bilateral", perspective = "self")
bm(dec, flow = "imports")



cleanEx()
nameEx("decomp")
### * decomp

flush(stderr()); flush(stdout())

### Name: decomp
### Title: Run a GVC Decomposition
### Aliases: decomp

### ** Examples

# Load leather example data
data(leather)

# Explore the data
str(leather)

# Create the 'icio' object
m <- load_icio(leather)

## Decomposing gross exports:

# Borin-Mancini (2019), the recommended method
decomp(m)
decomp(m, aggregation = "bilateral")

# Leontief, Koopman-Wang-Wei and Wang-Wei-Zhu
decomp(m, method = "leontief")
decomp(m, method = "kww")
decomp(m, method = "wwz")

# Multiple tables at once, e.g. one per year, stacked with a 'Year' column
decomp(list(`2015` = m, `2016` = m), idcol = "Year")



cleanEx()
nameEx("kww")
### * kww

flush(stderr()); flush(stdout())

### Name: kww
### Title: Koopman-Wang-Wei Decomposition of Gross Exports
### Aliases: kww

### ** Examples

# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)
 
# Perform the KWW decomposition
kww(m)




cleanEx()
nameEx("leontief")
### * leontief

flush(stderr()); flush(stdout())

### Name: leontief
### Title: Leontief Decomposition
### Aliases: leontief

### ** Examples

# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)

# Perform the Leontief decomposition of each country-industries 
# exports into their value added origins by country-industry
leontief(m)



cleanEx()
nameEx("load_icio")
### * load_icio

flush(stderr()); flush(stdout())

### Name: load_icio
### Title: Load an Inter-Country Input-Output Table
### Aliases: load_icio

### ** Examples

# Load example data
data(leather)

# Create intermediate object (class 'icio') from an 'iot' object
m <- load_icio(leather)

# Equivalent: passing the matrices directly
m <- load_icio(leather$inter, leather$final, leather$countries, leather$industries)

# Examine the object
str(m)



cleanEx()
nameEx("load_icio_csv")
### * load_icio_csv

flush(stderr()); flush(stdout())

### Name: load_icio_csv
### Title: Load an ICIO Table from the 'icio' CSV Format
### Aliases: load_icio_csv

### ** Examples

## Not run: 
##D # A table exported for the Stata 'icio' command, together with its country list
##D m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv")
##D 
##D # Supplying the real sector codes so they appear in the results
##D m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv",
##D                    industries = c("AFF", "MIN", "MAN"))
##D 
##D decomp(m, aggregation = "bilateral")
## End(Not run)



cleanEx()
nameEx("wwz")
### * wwz

flush(stderr()); flush(stdout())

### Name: wwz
### Title: Wang-Wei-Zhu Decomposition of Gross Exports
### Aliases: wwz

### ** Examples

# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)

# Perform the WWZ decomposition
wwz(m)



cleanEx()
nameEx("wwz2kww")
### * wwz2kww

flush(stderr()); flush(stdout())

### Name: wwz2kww
### Title: Koopman-Wang-Wei from Wang-Wei-Zhu Decomposition
### Aliases: wwz2kww

### ** Examples


# Load example data
data(leather)

# Create intermediate object (class 'icio')
m <- load_icio(leather)
 
# Perform the WWZ decomposition
WWZ <- wwz(m)

# Obtain a disaggregated KWW decomposition
KWW <- wwz2kww(WWZ)

# Aggregate KWW 
wwz2kww(WWZ, aggregate = TRUE)

# Same as running KWW directly, but the former is more efficient 
# if we already have the WWZ
kww(m)



### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
