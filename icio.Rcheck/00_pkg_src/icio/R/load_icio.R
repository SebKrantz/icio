#' Load an Inter-Country Input-Output Table
#'
#' Reads the raw ICIO matrices and precomputes everything the decompositions need,
#' returning an 'icio' class object. This is the entry point for all decompositions.
#'
#' @param inter intermediate demand table supplied as a numeric matrix of dimensions GN x GN (G = no. of countries, N = no. of industries).
#' Both rows and columns should be arranged first by country, then by industry (e.g. C1I1, C1I2, ..., C2I1, C2I2, ...) and should match (symmetry),
#' such that rows and columns refer to the same country-industries.
#' Alternatively, an Input-Output Table object of class 'iot' can be passed here - a list with elements
#' 'inter', 'final', 'countries', 'industries' and (optionally) 'output' - in which case the remaining table arguments are taken from it. See \code{\link{leather}}.
#' @param final final demand table supplied as a numeric matrix of dimensions GN x GM (M = no. of final demand categories recorded for each country).
#' The rows of \code{final} need to match the rows of \code{inter}, and the columns should also be arranged first by country, then by final demand category
#' (e.g. C1FD1, C1FD2, ..., C2FD1, C2FD2, ...) with the order of the countries the same as in \code{inter}.
#' @param countries character. A vector of country or region names of length G, arranged in the same order as they occur in the rows and columns of \code{inter} and \code{final}.
#' @param industries character. A vector of industry names of length N, arranged in the same order as they occur in the rows and columns of \code{inter} and the rows of \code{final}.
#' @param output numeric. A vector of gross outputs for each country-industry matching the rows of \code{inter} and \code{final}. If not provided it will be computed as \code{rowSums(inter) + rowSums(final)}.
#' @param va numeric. A vector of value added for each country-industry matching the columns of \code{inter}. If not provided it will be computed as \code{output - colSums(inter)}, which is what the Stata \code{icio} command does.
#' @param null_inventory logical. \code{TRUE} sets the inventory (last final demand category for each country) to zero.
#' @return An 'icio' class object - a list with the following elements:
#'  \tabular{rrrl}{
#'  A  \tab\tab\tab Input coefficients matrix (\code{inter} column-normalized by \code{output}), including the domestic blocks. \cr
#'  B  \tab\tab\tab Leontief Inverse matrix \eqn{(I - A)^{-1}}. \cr
#'  Lb \tab\tab\tab List of \code{G} domestic (local) Leontief Inverse blocks \eqn{(I - A_{gg})^{-1}}, one \code{N x N} matrix per country. \cr
#'  E  \tab\tab\tab Total Exports (output of each country-industry servicing foreign production or foreign final demand). \cr
#'  ESR \tab\tab\tab Total Exports by destination country. \cr
#'  Vc \tab\tab\tab Value added content of output (\code{va / output}). \cr
#'  G \tab\tab\tab Number of countries. \cr
#'  N \tab\tab\tab Number of industries. \cr
#'  GN \tab\tab\tab Number of country-industries. \cr
#'  k \tab\tab\tab Vector of country names. \cr
#'  i \tab\tab\tab Vector of industry names. \cr
#'  X \tab\tab\tab Total Output (\code{ = output}). \cr
#'  Y \tab\tab\tab Total Final Demand by destination country. \cr
#'  Yd \tab\tab\tab Domestic Final Demand. \cr
#'  Ym \tab\tab\tab Foreign Final Demand. \cr
#'  }
#'  The country-industry names identifying the rows and columns are available as \code{names(x$Vc)}
#'  or \code{dimnames(x$B)[[1L]]}.
#' @details Only \code{A} and \code{B} are dense \code{GN x GN} matrices. The masked and
#'  block-diagonal variants of them that the decompositions require (\eqn{A} with the domestic blocks
#'  zeroed, the domestic and foreign parts of \eqn{B}) are derived on the fly by the functions that
#'  need them, being either recoverable from \code{A} and \code{B} in a few operations or, in the case
#'  of the domestic Leontief inverse, block-diagonal and thus \eqn{1 - 1/G} structural zeros.
#'
#'  Value added defaults to the column residual of the table (\code{output - colSums(inter)}), which
#'  reproduces the Stata \code{icio} command exactly. Supplying a \code{va} that differs from it makes
#'  the column sums of \eqn{V B} deviate from 1, so identities such as \code{GEXP = DC + FC} may no
#'  longer hold exactly - faithful to the supplied data.
#' @author Sebastian Krantz, Bastiaan Quast. Adapted from code by Fei Wang.
#' @export
#' @seealso \code{\link{load_icio_csv}}, \code{\link{decomp}}, \code{\link{bm}}, \code{\link{icio-package}}
#' @examples
#' # Load example data
#' data(leather)
#'
#' # Create intermediate object (class 'icio') from an 'iot' object
#' m <- load_icio(leather)
#'
#' # Equivalent: passing the matrices directly
#' m <- load_icio(leather$inter, leather$final, leather$countries, leather$industries)
#'
#' # Examine the object
#' str(m)

load_icio <- function(inter, final, countries, industries, output = NULL, va = NULL,
                      null_inventory = FALSE) {

    ## extract objects from an 'iot' object passed as the first argument
    if(inherits(inter, "iot")) {
      iot <- inter
      inter <- iot$inter
      final <- iot$final
      countries <- iot$countries
      industries <- iot$industries
      # the output vector is called 'out' in data(leather) but 'output' elsewhere
      if(is.null(output)) output <- if(is.null(iot[["output"]])) iot[["out"]] else iot[["output"]]
      if(is.null(va)) va <- iot[["va"]]
    }

    # Some extra checks at little cost: sometimes IO data is wrongly imported or pre-processed
    if(!is.numeric(inter) || anyNA(inter)) warning("'inter' is not numeric or contains missing values")
    if(!is.numeric(final) || anyNA(final)) warning("'final' is not numeric or contains missing values")
    if(!is.character(countries) || anyNA(countries)) warning("'countries' is not character or contains missing values")
    if(!is.character(industries) || anyNA(industries)) warning("'industries' is not character or contains missing values")

    ## find number of sections and regions compute combination
    G <- length(countries)
    N <- length(industries)
    GN <- G * N
    dx <- dim(inter)
    dy <- dim(final)

    # Some dimension checking
    if(!all(dx == GN)) stop("'inter' of dimension ", paste(dx, collapse = " * "), " does not match length(countries) * length(industries) = ", GN)
    if(dy[1L] != GN) stop("nrow(final) = ", dy[1L], " does not match length(countries) * length(industries) = ", GN)
    if(dy[2L] %% G) stop("The number of final demand categories ncol(final) = ", dy[2L], " is not a multiple of the number of countries length(countries) = ", G)

    ## create vector of unique combinations of regions and sectors
    rownam <- as.vector(t(outer(countries, industries, paste, sep = ".")))

    ## contruct final demand components
    fdc <- dy[2L] / G

    ## null inventory if needed
    if (isTRUE(null_inventory)) final[, fdc * (1:G)] <- 0

    ## define dimensions
    ## -> only needed for matrices that will be "manually"
    ## (e.g. in a for-loop) filled
    ## For matrix copies, no need for setting the dimensions,
    ## only increases the memory burden
    Yd <- ESR <- Y <- matrix(0, nrow = GN, ncol = G)

    # output can be computed...
    if (is.null(output)) {
      output <- rowSums(inter) + rowSums(final)
    } else {
      if(!is.numeric(output) || anyNA(output)) warning("'output' is not numeric or contains missing values")
      if(length(output) != GN) stop("length(output) = ", length(output), " does not match length(countries) * length(industries) = ", GN)
      if(is.character(m <- all.equal(rowSums(inter) + rowSums(final), output)))
        message("'output' supplied is different from rowSums(inter) + rowSums(final). ", m)
    }

    ## this might not be the best way to construct V
    if (is.null(va)) {
      va <- output - colSums(inter)
    } else {
      if(!is.numeric(va) || anyNA(va)) warning("'va' is not numeric or contains missing values")
      if(length(va) != GN) stop("length(va) = ", length(va), " does not match length(countries) * length(industries) = ", GN)
      if(is.character(m <- all.equal(output - colSums(inter), va)))
        message("'va' supplied is different from output - colSums(inter). ", m)
    }

    # A <- inter / outer(rep.int(1L, GN), output) # Significantly faster than:  t(t(inter) / output)
    A <- .Call(C_rowmult, inter, 1 / output)
    A[!is.finite(A)] <- 0

    ## B = (I - A)^-1. Forming (I - A) in place avoids allocating a GN x GN identity matrix.
    IA <- -A
    diag(IA) <- diag(IA) + 1
    B <- solve(IA)
    rm(IA)

    ## The domestic economy Leontief inverse is block-diagonal: store the G blocks it consists of
    ## rather than a dense GN x GN matrix that is (1 - 1/G) zeros. G small solves instead of one
    ## large one, which is also two orders of magnitude faster than solve(I - Ad).
    IN <- diag(N)
    Lb <- vector("list", G)
    for (j in 1:G) {
        m <- 1L + (j - 1L) * N
        n <- N + (j - 1L) * N
        Lb[[j]] <- solve(IN - A[m:n, m:n])
    }
    rm(IN)

    Vc <- va / output
    Vc[!is.finite(Vc)] <- 0
    ## Vhat <- diag(Vc)

    ## Part 2: computing final demand: Y
    if(fdc > 1L) {
        for (j in 1:G) {
            m <- 1L + (j - 1L) * fdc
            n <- fdc + (j - 1L) * fdc

            Y[, j] <- rowSums2(final, cols = m:n)
        }
    } else if(fdc == 1L) {
        Y <- final
    }

    ## domestic final demand
    Ym <- Y


    ## Part 3: computing export: E, Esr
    ## Exports for final demand are just the foreign part of Y, so ESR is assembled directly from
    ## 'inter' and Y. This avoids materializing a masked cbind(inter, final) copy.
    for (j in 1:G) {
        m <- 1L + (j - 1L) * N
        n <- N + (j - 1L) * N

        Yd[m:n, j] <- Y[m:n, j]
        Ym[m:n, j] <- 0

        ## intermediate exports to j, excluding j's demand for its own goods
        ESR[, j] <- rowSums2(inter, cols = m:n)
        ESR[m:n, j] <- 0
    }

    ## total exports by destination = intermediate exports + final goods exports (= Ym)
    ESR <- ESR + Ym
    E <- rowSums2(ESR)


    ## Part 4: naming the rows and columns in variables
    names(Vc) <- rownam
    names(output) <- rownam
    names(E) <- rownam
    dny <- list(rownam, countries)
    dimnames(Y) <- dny
    dimnames(Yd) <- dny
    dimnames(Ym) <- dny
    dimnames(ESR) <- dny
    dnx <- list(rownam, rownam)
    dimnames(A) <- dnx
    dimnames(B) <- dnx

    ## Part 5: creating the 'icio' object
    out <- list(A = A,                  # kww, wwz, bm
                B = B,                  # leontief, kww, bm
                Lb = Lb,                # kww, wwz, bm
                E = E,
                ESR = ESR,
                Vc = Vc,

                ## country/industry parameter
                G = G,
                N = N,
                GN = GN,
                k = countries,
                i = industries,

                X = output,             # leontief
                Y = Y,                  # leontief
                Yd = Yd,
                Ym = Ym)

    class(out) <- "icio"

    ## Part 6: returning object
    return(out)

}


#' Load an ICIO Table from the 'icio' CSV Format
#'
#' Reads an Inter-Country Input-Output table from the CSV format used by the Stata \code{icio}
#' command and returns an 'icio' class object, ready for \code{\link{decomp}} and the
#' decomposition functions.
#'
#' @param table character. Path to a headerless \code{GN x (GN + G)} CSV file holding the matrix
#' \code{[inter | final]}: the first GN columns are the intermediate transactions, the last G columns
#' the final demand (one aggregated column per country). Read with \code{\link[data.table]{fread}}.
#' @param countries character. Either a vector of G country codes, or the path to a headerless
#' one-column CSV file containing them (the country list file of the Stata \code{icio} command).
#' @param industries character. Either a vector of N industry codes, the path to a headerless
#' one-column CSV file containing them, or \code{NULL} (the default) to generate
#' \code{"sector1", ..., "sectorN"}. The number of industries is inferred as \code{N = GN / G}.
#' @param output numeric. Optional vector of gross outputs, see \code{\link{load_icio}}.
#' @param va numeric. Optional vector of value added, see \code{\link{load_icio}}. The default is the
#' column residual of the table, which reproduces the Stata \code{icio} command.
#' @param \dots further arguments passed to \code{\link[data.table]{fread}}.
#' @return An 'icio' class object, see \code{\link{load_icio}}.
#' @author Sebastian Krantz
#' @export
#' @seealso \code{\link{load_icio}}, \code{\link{decomp}}, \code{\link{icio-package}}
#' @examples
#' \dontrun{
#' # A table exported for the Stata 'icio' command, together with its country list
#' m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv")
#'
#' # Supplying the real sector codes so they appear in the results
#' m <- load_icio_csv("EM_2015.csv", "EM_countrylist.csv",
#'                    industries = c("AFF", "MIN", "MAN"))
#'
#' decomp(m, aggregation = "bilateral")
#' }

load_icio_csv <- function(table, countries, industries = NULL, output = NULL, va = NULL, ...) {

  countries <- read_codes(countries, "countries")
  G <- length(countries)

  M <- as.matrix(fread(table, header = FALSE, ...))
  if(!is.numeric(M)) stop("'table' must contain only numeric data: it should be a headerless GN x (GN + G) matrix [inter | final]")
  GN <- nrow(M)
  if(GN %% G) stop("'table' has ", GN, " rows but there are ", G, " countries; ", GN, " is not divisible by ", G)
  N <- GN %/% G
  if(ncol(M) != GN + G) stop("'table' has ", ncol(M), " columns, expected GN + G = ", GN + G,
                             " (", GN, " intermediate + ", G, " final demand)")

  industries <- if(is.null(industries)) paste0("sector", seq_len(N)) else read_codes(industries, "industries")
  if(length(industries) != N) stop("got ", length(industries), " industry names, expected N = GN / G = ", N)

  dimnames(M) <- NULL
  load_icio(inter = M[, seq_len(GN), drop = FALSE],
            final = M[, GN + seq_len(G), drop = FALSE],
            countries = countries, industries = industries,
            output = output, va = va)
}

# A character vector of codes, or the path to a headerless one-column CSV file containing them.
read_codes <- function(x, arg) {
  if(!is.character(x)) stop("'", arg, "' must be a character vector of codes or a path to a one-column CSV file")
  if(length(x) == 1L && file.exists(x)) return(as.character(fread(x, header = FALSE)[[1L]]))
  x
}
