#' Koopman-Wang-Wei Decomposition of Gross Exports
#' 
#' This function performs the Koopman-Wang-Wei (2014) decomposition of a countries gross exports into 9 separate value added components.
#' 
#' @param x an object of the class 'icio' obtained from \code{\link{load_icio}}.
#' @author Sebastian Krantz
#' @return A \code{data.table} where a country's gross exports is decomposed into 9 components (columns), as detailed in Figure 1 of the AER paper:
#'  \tabular{ll}{
#'  \emph{Term} \tab \emph{Description} \cr
#'  \code{DVA_FIN} \tab Domestic VA in final goods exports. \cr
#'  \code{DVA_INT} \tab Domestic VA in intermediate exports absorbed by direct importers (used to produce a locally consumed final good). \cr
#'  \code{DVA_INTrex} \tab Domestic VA in intermediate exports reexported to third countries and absorbed there. \cr
#'  \code{RDV_FIN} \tab Domestic VA in intermediate exports that returns home via final imports. \cr
#'  \code{RDV_INT} \tab Domestic VA in intermediate exports that returns home via intermediate imports (used to produce a domestically consumed final good). \cr
#'  \code{DDC} \tab Double counted DVA in intermediate exports (arising from 2-way trade in intermediate goods). \cr
#'  \code{FVA_FIN} \tab Foreign VA in final goods exports. \cr
#'  \code{FVA_INT} \tab Foreign VA in intermediate exports. \cr
#'  \code{FDC} \tab Double counted FVA in intermediate exports (arising from 2-way trade in intermediate goods). \cr
#'  }
#' @references Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and double counting in gross exports. \emph{American Economic Review, 104}(2), 459-94.
#'
#' Borin, A., & Mancini, M. (2019). Measuring What Matters in Global Value Chains and Value-Added Trade. \emph{World Bank Policy Research Working Paper 8804}.
#' @note The KWW decomposition is known to be biased. As shown by Borin and Mancini (2019), it
#' systematically underestimates the foreign value added in exports -- and correspondingly overstates
#' foreign double counting -- because the entire foreign content that the direct importer re-exports to
#' third countries is classified as 'foreign double counted', including the part (value added generated in
#' the importing country and re-exported onwards) that is never recorded as foreign value added in any other
#' flow. KWW also overlooks the bilateral dimension of trade, so it cannot correctly split domestic value
#' added between absorption by the direct importer and by third markets (hence indicators such as DAVAX
#' cannot be derived from it). Borin and Mancini (2019) correct these issues using a sink-based, world-level
#' perspective for the foreign content of exports; this corrected KWW decomposition is available as
#' \code{\link{bm}(x, perspective = "world", approach = "sink")}.
#' @export
#' @seealso \code{\link{bm}}, \code{\link{wwz}}, \code{\link{wwz2kww}}, \code{\link{icio-package}}
#' @examples
#' # Load example data
#' data(leather)
#'
#' # Create intermediate object (class 'icio')
#' m <- load_icio(leather)
#'  
#' # Perform the KWW decomposition
#' kww(m)
#' 



# Note: Sector level is false, only aggregated is correct !!
kww <- function(x) {
  
  if(!inherits(x, "icio")) stop("x must be an object of class 'icio' created by the load_icio() function.")
  
  A <- B <- Lb <- Y <- Vc <- N <- G <- GN <- Ym <- Yd <- E <- k <- NULL # First need to initialize as NULL to avoid R CMD check error.
  list2env(x, environment())

  Nseq <- seq_len(N)
  blk <- function(g) (g - 1L) * N + Nseq

  # Foreign input coefficients: A with the domestic blocks zeroed.
  Am <- A
  for (g in seq_len(G)) { bg <- blk(g); Am[bg, bg] <- 0 }

  # The domestic parts of B and the local Leontief inverse L are block-diagonal, so the products
  # below are formed blockwise from the diagonal blocks of B and from Lb. This avoids materializing
  # Bd, Bm and a dense L, and -- by re-associating Bm %*% Am %*% L %*% Z as Bm %*% (Am %*% (L %*% Z))
  # with Z of only G columns -- also avoids two GN x GN matrix products.
  BdZ <- function(Z) {           # domestic (block-diagonal) part of B %*% Z
    out <- matrix(0, GN, ncol(Z))
    for (g in seq_len(G)) { bg <- blk(g); out[bg, ] <- B[bg, bg, drop = FALSE] %*% Z[bg, , drop = FALSE] }
    out
  }
  BmZ <- function(Z) B %*% Z - BdZ(Z)   # foreign part of B %*% Z
  LZ  <- function(Z) {                  # L %*% Z, L block-diagonal
    out <- matrix(0, GN, ncol(Z))
    for (g in seq_len(G)) { bg <- blk(g); out[bg, ] <- Lb[[g]] %*% Z[bg, , drop = FALSE] }
    out
  }

  # breaking up gross output according to where it is ultimately absorbed...
  Xc <- B %*% Y                  # Xc = 'Gross output decomposition matrix'
  # Value added by destination of final absorption (domestic and exported VA)
  VBY <- Vc * Xc   # VBY = value-added production matrix (same as diag(Vc) %*% Xc)
  # Elements in the diagonal columns give each country’s production of value added absorbed at home.
  # Exports of value added can be defined as the elements in the off-diagonal columns of this GN × G matrix
  i1 <- rep(1:N, G)
  i2 <- rep(0:(G-1L), each = N)
  idiag <- i1 + (N * i2) + (GN * i2)
  VBY[idiag] <- 0
  # Obviously it excludes value added produced by the home country that returns home after being processed abroad.

  # Terms 1-3: VA Exports
  vae <- rowSums(VBY)               # Total VA exports, which are broken down as follows:
  T1 <- Vc * rowSums(BdZ(Ym))       # VA in the country’s (direct) final goods exports to different importers.
  T2 <- Vc * drop(BmZ(cbind(Yd[idiag]))) # VA in the country’s intermediate exports used by the direct importer to produce final goods consumed by the direct importer.
  T3 <- vae - (T1 + T2)             # VA in the country’s intermediate exports used by the direct importer to produce final goods absorbed in third countries.

  # Now we consider the FVA and double counted terms (eventually absorbed at home) in gross exports.

  # Terms 4-6: Domestic content in intermediate exports that finally returns home
  T4 <- Vc * BmZ(Ym)[idiag]         # DVA that is initially embodied in its intermediate exports but is returned home as part of imports of the final good.
  AmLYd <- Am %*% LZ(Yd)
  T5 <- Vc * BmZ(AmLYd)[idiag]    # DVA that is initially embodied in intermediate goods exports but then returned home via intermediate imports to produce final goods that are absorbed at home.
      # T4 and T5 are parts of the source country’s GDP but represent a double-counted portion in official gross export statistics (counted at least twice in trade statistics as they first leave Country 1 for Country 2, and then leave Country 2 for Country 1 and stay in country 1).
  Ediag <- Yd
  Ediag[idiag] <- E
  T6 <- Vc * BmZ(Am %*% LZ(Ediag))[idiag] # Pure double-counted DVA in intermediate exports that return home and are already captured in T4 and T5 (exists only if two-way trade in intermediate goods, not part of countries GDP) we cannot directly see where they are absorbed.

  # Terms 7-9: Foreign VA
  T7 <- T8 <- T9 <- E
  ifac <- as.factor(i1[-(1:N)])
  Yms <- rowSums(Ym)                 # needed for T7
  AmLYds <- rowSums(AmLYd)           # Needed for T8
  for(s in 1:G) {
    is <- 1L + (s - 1L) * N
    is <- is:(is + N - 1L)
    tmp <- rowsum(x_OP_y(B, Vc, "*", -is, is, -is), ifac, reorder = FALSE) # x_OP_y statement same as Vc[-is] * B[-is, is] but faster # rowsum is the r sum, -is is the t sum...
    T7[is] <- tmp %*% Yms[is]        # FVA in final goods exports
    T8[is] <- tmp %*% AmLYds[is]     # FVA in intermediate goods exports
  }
  T9 <- E - (vae + T4 + T5 + T6 + T7 + T8)  # double counted intermediate exports produced abroad
  out <- list(T1, T2, T3, T4, T5, T6, T7, T8, T9)
  names(out) <- c("DVA_FIN", "DVA_INT", "DVA_INTrex", "RDV_FIN", "RDV_INT", "DDC", "FVA_FIN", "FVA_INT", "FDC")
  attr(out, "row.names") <- .set_row_names(GN)
  class(out) <- "data.frame"
  # Aggregating: Necessary, other wise not correct... (as seen in some negative values in T9 at sector level)
  out <- c(list(Country = structure(seq_along(k), levels = k, class = "factor")),
           rowsum(out, rep(k, each = N), reorder = FALSE))
  setDT(out)
  setattr(out, "decomposition", "kww")
  out
}


#' Koopman-Wang-Wei from Wang-Wei-Zhu Decomposition
#' 
#' This function by default returns a disaggregated version of the the Koopman-Wang-Wei (KWW) decomposition breaking up sector-level gross exports into 9 value added terms,
#' from an already computed and more detailed (16 term) Wang-Wei-Zhu decomposition of sector-level gross exports. An aggregation option also allows obtaining the aggregate KWW decomposition. 
#' 
#' @param x a data.table with the WWZ decomposition obtained from \code{\link{wwz}}. Alternatively an 'icio' class object from \code{\link{load_icio}} can be supplied, which will toggle calling \code{wwz()} first. 
#' @param aggregate logical. \code{TRUE} aggregates the KWW decomposition to the country level, giving exactly the same output as \code{\link{kww}}. \code{FALSE} maintains the sector level decomposition in KWW format. 
#' @details The mapping of the 16 terms in the WWZ decomposition to the 9 terms in the KWW decomposition is provided in table E2 in the appendix of the WWZ (2013) paper. The table is reproduced here using the term naming 
#' conventions followed in this package.
#'
#' \tabular{lll}{
#'  \emph{WWZ Terms} \tab \emph{KWW Term} \tab \emph{Description} \cr
#'  \code{DVA_FIN} \tab \code{DVA_FIN} \tab Domestic VA in final goods exports. \cr
#'  \code{DVA_INT, DVA_INTrexI1} \tab \code{DVA_INT} \tab Domestic VA in intermediate exports absorbed by direct importers. WWZ separates VA absorbed directly from VA that transits through third countries before returning to the direct importer. \cr
#'  \code{DVA_INTrexF, DVA_INTrexI2} \tab \code{DVA_INTrex} \tab Domestic VA in intermediate exports reexported to third countries and absorbed there. WWZ separates VA in final goods exports of direct importer to third countries from VA in intermediate exports to third countries. \cr
#'  \code{RDV_FIN, RDV_FIN2} \tab \code{RDV_FIN} \tab Domestic VA in intermediate exports that returns home via final imports. WWZ separates final imports from the direct importer and from third countries. \cr
#'  \code{RDV_INT} \tab \code{RDV_INT} \tab Domestic VA in intermediate exports that returns via intermediate imports (used to produce a locally consumed final good). \cr
#'  \code{DDC_FIN, DDC_INT} \tab \code{DDC} \tab Double counted domestic VA in gross exports. WWZ separates double counting due to final and intermediate exports production. \cr
#'  \code{MVA_FIN, OVA_FIN} \tab \code{FVA_FIN} \tab Foreign VA in final goods exports. WWZ separates FVA from direct importer and from third countries. \cr
#'  \code{MVA_INT, OVA_INT} \tab \code{FVA_INT} \tab Foreign VA in intermediate exports. WWZ separates FVA from direct importer and from third countries. \cr
#'  \code{MDC, ODC} \tab \code{FDC} \tab Double counted foreign VA in gross exports. WWZ separates FDC from direct importer and from third countries. \cr
#'  }
#'  
#' @author Sebastian Krantz
#' @return A \code{data.table} with exports decomposed into 9 components (columns), see the table above and \code{\link{kww}} for a shorter description of the 9 terms.
#' @note If both WWZ and KWW decompositions are required, it is computationally more efficient to call \code{wwz2kww(x, aggregate = TRUE)} on an already computed WWZ decomposition, than to call \code{\link{kww}} on an 'icio' object. 
#' @references Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and double counting in gross exports. \emph{American Economic Review, 104}(2), 459-94.
#' 
#' Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying international production sharing at the bilateral and sector levels (No. w19677). \emph{National Bureau of Economic Research}.
#' @export
#' @seealso \code{\link{wwz}}, \code{\link{kww}}, \code{\link{icio-package}}
#' @examples
#' 
#' # Load example data
#' data(leather)
#'
#' # Create intermediate object (class 'icio')
#' m <- load_icio(leather)
#'  
#' # Perform the WWZ decomposition
#' WWZ <- wwz(m)
#' 
#' # Obtain a disaggregated KWW decomposition
#' KWW <- wwz2kww(WWZ)
#' 
#' # Aggregate KWW 
#' wwz2kww(WWZ, aggregate = TRUE)
#' 
#' # Same as running KWW directly, but the former is more efficient 
#' # if we already have the WWZ
#' kww(m)

# This is correct, I checked it !!
wwz2kww <- function(x, aggregate = FALSE) {
  d <- attr(x, "decomposition")
  if(!is.data.frame(x) || is.null(d) || d != "wwz") {
    if(!inherits(x, "icio")) stop("x must be a WWZ decomposition obtained from wwz(), or an object of class 'icio' created by the load_icio() function.")
    x <- wwz(x)
  }
  x <- unclass(x) # Some extra $ subsetting speed
  y <- x[1:3]     # the three identifier columns
  y$DVA_FIN <- x$DVA_FIN
  y$DVA_INT <- x$DVA_INT + x$DVA_INTrexI1
  y$DVA_INTrex <- x$DVA_INTrexF + x$DVA_INTrexI2
  y$RDV_FIN <- x$RDV_FIN + x$RDV_FIN2
  y$RDV_INT <- x$RDV_INT
  y$DDC <- x$DDC_FIN + x$DDC_INT
  y$FVA_FIN <- x$OVA_FIN + x$MVA_FIN
  y$FVA_INT <- x$OVA_INT + x$MVA_INT
  y$FDC <- x$ODC + x$MDC
  if(!aggregate) {
    setDT(y)
    setattr(y, "decomposition", "kww")
    return(y)
  }
  out <- c(list(Country = unique(x$Exporting_Country)),
           as.data.frame(rowsum(do.call(cbind, y[-(1:3)]), x$Exporting_Country, reorder = FALSE)))
  setDT(out)
  setattr(out, "decomposition", "kww")
  out
}


# Attempt to calculate KWW faster from aggregating intermediate input matrices and inverting... not finished 
# kww0 <- function(x, inter) {
#   list2env(x, environment())
#   kvec <- factor(rep(k, each = N), levels = k)
#   Yc <- rowsum(Y, kvec)
#   IOc <- t(rowsum(t(rowsum(inter, kvec)), kvec))
#   o <- drop(rowsum(X, kvec))
#   
#   A <- IOc / outer(rep.int(1L, G), o) # Significantly faster than:  t(t(x) / o)
#   A[!is.finite(A)] <- 0
#   
#   II <- diag(G)
#   Bc <- solve(II - A)
#   # t(rowsum(t(rowsum(B, kvec)), kvec))  # Not the same as BC, unfortunately...
#   
#   # breaking up gross output according to where it is ultimately absorbed...
#   Xc <- Bc %*% Yc # Xc = 'Gross output decomposition matrix'
#   Vc <- drop(rowsum(Vc * X, kvec) / o)
#   VBc <- diag(Vc) %*% Bc
#   dimnames(VBc) <- dimnames(Bc)
#   # Value added by destination of final absorption (domestic and exported VA)
#   VAc <- Xc * Vc
#   # ...  
# }
