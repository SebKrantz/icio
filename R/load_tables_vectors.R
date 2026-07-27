#' Load the Input-Output and Final Demand Tables
#' 
#' This function loads the demand tables
#' and creates all matrices and variables required for the GVC decompositions.
#' 
#' @param iot a Input Output Table object - a list with elements 'inter' (= x), 'final' (= y), 'output' (= o), 'countries' (= k) and 'industries' (= i) of class 'iot'. 
#' Alternatively these objects can be passed directly to the function, at least x, y, k and i need to be supplied.
#' @param x intermediate demand table supplied as a numeric matrix of dimensions GN x GN (G = no. of country, N = no. of industries). 
#' Both rows and columns should be arranged first by country, then by industry (e.g. C1I1, C1I2, ..., C2I1, C2I2, ...) and should match (symmetry), 
#' such that rows and columns refer to the same country-industries.
#' @param y final demand table supplied as a numeric matrix of dimensions GN x MN (M = no. of final demand categories recorded for each country). 
#' The rows of y need to match the rows of x, and the columns should also be arranged first by country, then by final demand category (e.g. C1FD1, C1FD2, ..., C2FD1, C2FD2, ...) with the order of the 
#' countries the same as in x.
#' @param k character. A vector of country or region names of length G, arranged in the same order as they occur in the rows and columns of x, y.
#' @param i character. A vector of industry names of length N, arranged in the same order as they occur in the rows and columns of x and rows of y.
#' @param o numeric. A vector of final outputs for each country-industry matching the rows of x and y. If not provided it will be computed as \code{rowSums(x) + rowSums(y)}.
#' @param v numeric. A vector of value added for each country-industry matching the columns of x. If not provided it will be computed as \code{o - colSums(x)}.
#' @param null_inventory logical. \code{TRUE} sets the inventory (last final demand category for each country) to zero.
#' @return A 'decompr' class object - a list with the following elements:
#'  \tabular{rrrl}{
#'  A  \tab\tab\tab Input coefficients matrix (\code{x} column-normalized by output \code{o}), including the domestic blocks. \cr
#'  B  \tab\tab\tab Leontief Inverse matrix \eqn{(I - A)^{-1}}. \cr
#'  Lb \tab\tab\tab List of \code{G} domestic (local) Leontief Inverse blocks \eqn{(I - A_{gg})^{-1}}, one \code{N x N} matrix per country. \cr
#'  E  \tab\tab\tab Total Exports (output of each country-industry servicing foreign production or foreign final demand). \cr
#'  ESR \tab\tab\tab Total Exports by destination country. \cr
#'  Vc \tab\tab\tab Value added content of output (\code{v / o}). \cr
#'  G \tab\tab\tab Number of countries. \cr
#'  N \tab\tab\tab Number of industries. \cr
#'  GN \tab\tab\tab Number of country-industries. \cr
#'  k \tab\tab\tab Vector of country names. \cr
#'  i \tab\tab\tab Vector of industry names. \cr
#'  X \tab\tab\tab Total Output (\code{ = o}). \cr
#'  Y \tab\tab\tab Total Final Demand by destination country. \cr
#'  Yd \tab\tab\tab Domestic Final Demand. \cr
#'  Ym \tab\tab\tab Foreign Final Demand. \cr
#'  }
#'  The country-industry names identifying the rows and columns are available as \code{names(x$Vc)}
#'  or \code{dimnames(x$B)[[1L]]}.
#' @section Changes in version 8.0.0:
#'  The object was reduced from five dense \code{GN x GN} matrices to two. The fields \code{Am},
#'  \code{Bd}, \code{Bm} and \code{L} were masked or block-diagonal copies of \code{A} and \code{B}
#'  and have been removed, as have \code{Eint}, \code{Efd} and \code{rownam}. \code{A} is now stored
#'  in full (previously only \code{Am}, with the domestic blocks zeroed, was kept), and the
#'  block-diagonal domestic Leontief inverse is stored as the \code{G} blocks \code{Lb} it consists
#'  of rather than as a dense matrix that is 1 - 1/G zeros. The decomposition functions derive
#'  whatever masked forms they need. Code that used the removed fields can recover them with
#'  \code{Am <- A; Bd <- matrix(0, GN, GN); Bm <- B; L <- matrix(0, GN, GN)} and, for each country
#'  block \code{bg}, \code{Am[bg, bg] <- 0; Bd[bg, bg] <- B[bg, bg]; Bm[bg, bg] <- 0;
#'  L[bg, bg] <- Lb[[g]]}; further \code{Efd} equals \code{Ym} and \code{Eint} equals
#'  \code{ESR - Ym}.
#' @author Bastiaan Quast
#' @details Adapted from code by Fei Wang.
#' @export
#' @seealso \code{\link{leontief}}, \code{\link{kww}}, \code{\link{wwz}}, \code{\link{decompr-package}}
#' @examples
#' # Load example data
#' data(leather)
#' 
#' # Create intermediate object (class 'decompr')
#' decompr_object <- load_tables_vectors(leather)
#' 
#' # Examine the object                                    
#' str(decompr_object)


load_tables_vectors <- function(iot, x, y, k, i, o = NULL, v = NULL,
                                null_inventory = FALSE) {
  
    ## extract objects from iot object
    if(!missing(iot) && inherits(iot, 'iot')) {
      x <- iot$inter
      y <- iot$final
      k <- iot$countries
      i <- iot$industries
      o <- iot$output
    }
    
    # Some extra checks at little cost: sometimes IO data is wrongly imported or pre-processed
    if(!is.numeric(x) || anyNA(x)) warning("x is not numeric or contains missing values")
    if(!is.numeric(y) || anyNA(y)) warning("y is not numeric or contains missing values")
    if(!is.character(k) || anyNA(k)) warning("k is not character or contains missing values")
    if(!is.character(i) || anyNA(i)) warning("i is not character or contains missing values")
  
    ## find number of sections and regions compute combination
    G <- length(k)
    N <- length(i)
    GN <- G * N
    dx <- dim(x)
    dy <- dim(y)
    
    # Some dimension checking
    if(!all(dx == GN)) stop("x of dimension ", paste(dx, collapse = " * "), " does not match length(k) * length(i) = ", GN)
    if(dy[1L] != GN) stop("nrow(y) = ", dy[1L], " does not match length(k) * length(i) = ", GN)
    if(dy[2L] %% G) stop("The number of final demand categories ncol(y) = ", dy[2L], " is not a multiple of the number of countries length(k) = ", G)
                              
    ## create vector of unique combinations of regions and sectors
    rownam <- as.vector(t(outer(k, i, paste, sep = ".")))
    
    ## making the big rownames: bigrownam
    ## z01 <- t(matrix(rownam, nrow = GN, ncol = G))
    ## dim(z01) <- c((G) * GN, 1)
    ## z02 <- rep(k, times = GN)
    ## bigrownam <- paste(z01, z02, sep = ".")
    
    ## contruct final demand components
    fdc <- dy[2L] / G
    
    ## null inventory if needed
    if (isTRUE(null_inventory)) y[, fdc * (1:G)] <- 0
    
    ## define dimensions
    ## -> only needed for matrices that will be "manually"
    ## (e.g. in a for-loop) filled
    ## For matrix copies, no need for setting the dimensions,
    ## only increases the memory burden
    Yd <- ESR <- Y <- matrix(0, nrow = GN, ncol = G)

    # o can be computed...
    if (is.null(o)) {
      o <- rowSums(x) + rowSums(y)
    } else {
      if(!is.numeric(o) || anyNA(o)) warning("o is not numeric or contains missing values")
      if(length(o) != GN) stop("length(o) = ", length(o), " does not match length(k) * length(i) = ", GN)
      if(is.character(m <- all.equal(rowSums(x) + rowSums(y), o))) 
        message("o supplied is different from rowSums(x) + rowSums(y). ", m)
    }
    
    ## this might not be the best way to construct V
    if (is.null(v)) {
      v <- o - colSums(x)
    } else {
      if(!is.numeric(v) || anyNA(v)) warning("v is not numeric or contains missing values")
      if(length(v) != GN) stop("length(v) = ", length(v), " does not match length(k) * length(i) = ", GN)
      if(is.character(m <- all.equal(o - colSums(x), v))) 
        message("v supplied is different from o - colSums(x). ", m)
    }
    
    # A <- x / outer(rep.int(1L, GN), o) # Significantly faster than:  t(t(x) / o)
    A <- .Call(C_rowmult, x, 1 / o)
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

    Vc <- v / o
    Vc[!is.finite(Vc)] <- 0
    ## Vhat <- diag(Vc)

    ## Part 2: computing final demand: Y
    if(fdc > 1L) {
        for (j in 1:G) {
            m <- 1L + (j - 1L) * fdc
            n <- fdc + (j - 1L) * fdc

            Y[, j] <- rowSums2(y, cols = m:n)
        }
    } else if(fdc == 1L) {
        Y <- y
    }

    ## domestic final demand
    Ym <- Y
    
    
    ## Part 3: computing export: E, Esr
    ## Exports for final demand are just the foreign part of Y, so ESR is assembled directly from
    ## x and Y. This avoids materializing the masked cbind(x, y) the previous versions built.
    for (j in 1:G) {
        m <- 1L + (j - 1L) * N
        n <- N + (j - 1L) * N

        Yd[m:n, j] <- Y[m:n, j]
        Ym[m:n, j] <- 0

        ## intermediate exports to j, excluding j's demand for its own goods
        ESR[, j] <- rowSums2(x, cols = m:n)
        ESR[m:n, j] <- 0
    }

    ## total exports by destination = intermediate exports + final goods exports (= Ym)
    ESR <- ESR + Ym
    E <- rowSums2(ESR)


    ## Part 4: naming the rows and columns in variables
    names(Vc) <- rownam
    names(o) <- rownam
    names(E) <- rownam
    dny <- list(rownam, k)
    dimnames(Y) <- dny
    dimnames(Yd) <- dny
    dimnames(Ym) <- dny
    dimnames(ESR) <- dny
    dnx <- list(rownam, rownam)
    dimnames(A) <- dnx
    dimnames(B) <- dnx

    ## Part 5: creating decompr object. Only A and B are dense GN x GN: the masked (Am, Bm) and
    ## block-diagonal (Bd, L) variants earlier versions stored are derived by the decompositions
    ## that need them -- see the 'Changes in version 8.0.0' section above.
    out <- list(A = A,                  # kww, wwz, bm
                B = B,                  # leontief, kww, bm
                Lb = Lb,                # kww, wwz, bm
                E = E,
                ESR = ESR,
                Vc = Vc,
                ## fdc = fdc, ## never used

                ## country/industry parameter
                G = G,
                N = N,
                GN = GN,
                k = k,
                i = i,

                X = o,                  # leontief
                Y = Y,                  # leontief
                Yd = Yd,
                Ym = Ym)

    class(out) <- "decompr"
    
    ## Part 6: returning object
    return(out)
    
}
