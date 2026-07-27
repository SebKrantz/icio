#' Borin-Mancini Decomposition of Gross Exports and Imports
#'
#' Decomposes gross exports (or imports) into value-added and Global Value Chain (GVC) components
#' following the Borin and Mancini (2019) framework, as implemented in the Stata \code{icio}
#' command (Belotti, Borin and Mancini 2021). It is the R counterpart of the \code{decompose()}
#' function in the Julia package \code{GlobalValueChains.jl}, and operates on an \code{icio}
#' object created by \code{\link{load_icio}}.
#'
#' @param x an object of class \code{icio} obtained from \code{\link{load_icio}}.
#' @param aggregation character. The level of the decomposition:
#'  \code{"country"} (one row per exporting/importing country), \code{"sector"} (one row per
#'  exporting country-industry), or \code{"bilateral"} (one row per exporting country-industry
#'  and importing country for exports, or per importing country and value-added origin for
#'  imports). Default \code{"country"}.
#' @param perspective character. The accounting perspective defining the perimeter for double
#'  counting: \code{"exporter"} (exporting-country perimeter, additive across sectors and
#'  destinations), \code{"world"} (world perimeter, "corrected KWW", country level only),
#'  \code{"self"} (the export flow's own perimeter, giving the broader Johnson (2018) / Los et
#'  al. (2016) value added \eqn{DVA^\star \supseteq DVA}; sector and bilateral levels only), or
#'  \code{"importer"} (for \code{flow = "imports"}). Default \code{"exporter"}.
#' @param approach character. How double-counted items are allocated across shipments:
#'  \code{"source"} (value added recorded the first time it leaves the country of origin) or
#'  \code{"sink"} (the last time). The two coincide at the whole-country exporter perimeter
#'  (country level). \code{"world"} accepts both; \code{"self"} and imports ignore it. Default
#'  \code{"source"}.
#' @param flow character. \code{"exports"} (default) decomposes gross exports; \code{"imports"}
#'  decomposes a country's gross imports from the importer perspective (Borin and Mancini 2019,
#'  eq. 51) into value added (\code{VA}) and double counting (\code{DC}).
#'
#' @details
#' The supported combinations mirror the Stata \code{icio} command and \code{GlobalValueChains.jl}:
#'
#' \tabular{lllll}{
#'  \strong{flow} \tab \strong{aggregation} \tab \strong{perspective} \tab \strong{approach} \tab \strong{terms} \cr
#'  exports \tab country   \tab exporter \tab source(=sink) \tab 13 \cr
#'  exports \tab country   \tab world    \tab source        \tab  9 \cr
#'  exports \tab country   \tab world    \tab sink          \tab  9 \cr
#'  exports \tab sector    \tab exporter \tab source        \tab 13 \cr
#'  exports \tab sector    \tab exporter \tab sink          \tab  9 \cr
#'  exports \tab sector    \tab self     \tab -             \tab  9 \cr
#'  exports \tab bilateral \tab exporter \tab source        \tab 13 \cr
#'  exports \tab bilateral \tab exporter \tab sink          \tab 10 (adds VAXIM) \cr
#'  exports \tab bilateral \tab self     \tab -             \tab  9 \cr
#'  imports \tab country   \tab importer \tab -             \tab  3 (GIMP VA DC) \cr
#'  imports \tab bilateral \tab importer \tab -             \tab  2 (VA DC, by origin) \cr
#' }
#'
#' All terms are in the same units as the input-output table (e.g. millions of USD). The
#' following accounting identities hold for exports: \code{GEXP = DC + FC}, \code{DC = DVA + DDC},
#' \code{FC = FVA + FDC}, \code{DVA = VAX + REF}, and (exporter/source only)
#' \code{GVC = GVCB + GVCF = GEXP - DAVAX} and \code{GVCB = FC + DDC}; for imports
#' \code{GIMP = VA + DC}.
#'
#' \tabular{ll}{
#'  \code{GEXP} \tab Gross exports. \cr
#'  \code{DC} / \code{FC} \tab Domestic / foreign content. \cr
#'  \code{DVA} / \code{FVA} \tab Domestic / foreign value added. \cr
#'  \code{DDC} / \code{FDC} \tab Domestic / foreign double counting. \cr
#'  \code{VAX} \tab Domestic value added absorbed abroad (Johnson and Noguera 2012). \cr
#'  \code{REF} \tab Reflection: domestic value added returning home. \cr
#'  \code{DAVAX} \tab Domestic value added directly absorbed by the importer (source approach). \cr
#'  \code{VAXIM} \tab Domestic value added absorbed by the direct importer, incl. re-processing
#'    (sink approach; \code{DAVAX} \eqn{\le} \code{VAXIM} \eqn{\le} \code{VAX}). \cr
#'  \code{GVC} \tab GVC-related trade (value added crossing more than one border). \cr
#'  \code{GVCB} / \code{GVCF} \tab Backward / forward GVC participation. \cr
#'  \code{GIMP} \tab Gross imports (\code{= VA + DC}). \cr
#'  \code{VA} / \code{DC} \tab Value added / double counting in imports (by origin at the
#'    bilateral level). \cr
#' }
#'
#' The exporter / source decomposition is additive: the \code{"sector"} result is the sum of the
#' \code{"bilateral"} result over importers, and the \code{"country"} result is the sum of the
#' \code{"sector"} result over industries. The \code{"sink"} approach shares the domestic content
#' \code{DC} and foreign content \code{FC} with \code{"source"} at every cell; only the
#' value-added vs double-counted split differs. The \code{"self"} perimeter draws the boundary at
#' the export flow itself, so \code{DVA} (there \eqn{DVA^\star}) is weakly larger than under either
#' exporter approach.
#'
#' @return A \code{data.table} with one row per unit and one column per value-added term,
#'  preceded by factor identifier columns: \code{Exporting_Country} (country exports);
#'  \code{Exporting_Country, Exporting_Industry} (sector); \code{Exporting_Country,
#'  Exporting_Industry, Importing_Country} (bilateral exports); \code{Importing_Country} (country
#'  imports); or \code{Importing_Country, Origin_Country} (bilateral imports). The attribute
#'  \code{"decomposition"} is set to \code{"bm"}.
#'
#' @author Sebastian Krantz
#' @references
#' Borin, A. and Mancini, M. (2019). Measuring What Matters in Global Value Chains and
#' Value-Added Trade. \emph{World Bank Policy Research Working Paper 8804}.
#'
#' Belotti, F., Borin, A. and Mancini, M. (2021). icio: Economic analysis with intercountry
#' input-output tables. \emph{The Stata Journal, 21}(3), 708-755.
#' @export
#' @seealso \code{\link{kww}}, \code{\link{wwz}}, \code{\link{leontief}}, \code{\link{icio-package}}
#' @examples
#' # Load example data and create an 'icio' object
#' data(leather)
#' dec <- load_icio(leather)
#'
#' # Country-level decomposition (exporter perspective, source approach; 13 terms)
#' bm(dec)
#'
#' # Country-level "corrected KWW" (world perspective, sink approach; 9 terms)
#' bm(dec, perspective = "world", approach = "sink")
#'
#' # Sector- and bilateral-sector-level decompositions
#' bm(dec, aggregation = "sector")
#' bm(dec, aggregation = "bilateral", approach = "sink")   # adds VAXIM
#'
#' # Self (own-flow) perimeter, and the importer-perspective import decomposition
#' bm(dec, aggregation = "bilateral", perspective = "self")
#' bm(dec, flow = "imports")
bm <- function(x,
               aggregation = c("country", "sector", "bilateral"),
               perspective = c("exporter", "world", "self", "importer"),
               approach    = c("source", "sink"),
               flow        = c("exports", "imports")) {

  if(!inherits(x, "icio"))
    stop("x must be an object of class 'icio' created by the load_icio() function.")
  aggregation <- match.arg(aggregation)
  perspective <- match.arg(perspective)
  approach    <- match.arg(approach)
  flow        <- match.arg(flow)

  P <- .bm_prep(x)

  if(flow == "imports") {
    # importer is the only perimeter for imports; the global default 'exporter' maps to it
    if(!perspective %in% c("exporter", "importer"))
      stop("flow = 'imports' uses perspective = 'importer'; got perspective = '", perspective, "'.")
    if(aggregation == "sector")
      stop("Sectoral imports (sectimp) are not yet implemented; use aggregation = 'country' or 'bilateral'.")
    res <- .bm_imports(P, aggregation)

  } else {                                        # exports
    if(perspective == "importer")
      stop("perspective = 'importer' requires flow = 'imports'.")

    if(perspective == "self") {
      if(aggregation == "country")
        stop("perspective = 'self' is available for aggregation = 'sector' or 'bilateral' only.")
      res <- .bm_self(P, aggregation)

    } else if(perspective == "world") {
      if(aggregation != "country")
        stop("perspective = 'world' is only available for aggregation = 'country'.")
      res <- .bm_world(P, approach)

    } else {                                      # exporter
      if(aggregation == "country") {
        res <- .bm_source(P, "country")           # source == sink at the country perimeter
      } else if(approach == "source") {
        res <- .bm_source(P, aggregation)
      } else {                                    # sink, sector / bilateral
        res <- .bm_sink(P, aggregation)
      }
    }
  }

  .bm_finalize(res$out)
}


## ------------------------------------------------------------------------------------------------
## Internal helpers
## ------------------------------------------------------------------------------------------------

# factor column from integer codes
.bm_fct <- function(codes, levels) structure(codes, levels = levels, class = "factor")

# finalize a list of columns into a 'bm' data.table
.bm_finalize <- function(out) {
  out <- lapply(out, unname)
  setDT(out)
  setattr(out, "decomposition", "bm")
  out
}

# Shared precomputation reused by all engines. Returns a named list; engines pull it into scope
# with list2env(P, environment()).
.bm_prep <- function(x) {

  A <- B <- Lb <- Vc <- E <- ESR <- Y <- Yd <- Ym <- X <-
    G <- N <- GN <- k <- i <- NULL
  list2env(x, environment())

  Nseq    <- seq_len(N)
  blk     <- function(g) (g - 1L) * N + Nseq          # row/col range for country g
  ctryvec <- rep(seq_len(G), each = N)                # country of each country-sector
  idiag   <- cbind(seq_len(GN), ctryvec)              # [j, country(j)] extraction index
  IN      <- diag(N)

  # Foreign input coefficients: A with the domestic blocks zeroed. Several engines slice this by
  # country block, so it is materialized once here.
  Am <- A
  for(g in seq_len(G)) { bg <- blk(g); Am[bg, bg] <- 0 }

  ## Per-cell value-added multipliers (length GN). The domestic ones are block-diagonal products,
  ## so they are formed from the diagonal blocks of B and the local Leontief blocks Lb -- neither
  ## Bd, Bm nor a dense L is ever materialized. Wcol = L %*% Yd[idiag] is likewise block-diagonal.
  VBdom  <- numeric(GN)                               # domestic VA multiplier
  VLdom  <- numeric(GN)                               # local domestic VA multiplier
  Wcol   <- numeric(GN)                               # L_rr Y_rr, stacked
  Yddiag <- Yd[idiag]                                 # domestic final demand per country-sector
  for(g in seq_len(G)) {
    bg <- blk(g)
    VBdom[bg] <- as.vector(Vc[bg] %*% B[bg, bg, drop = FALSE])
    VLdom[bg] <- as.vector(Vc[bg] %*% Lb[[g]])
    Wcol[bg]  <- Lb[[g]] %*% Yddiag[bg]
  }
  VBfor <- as.vector(Vc %*% B) - VBdom                # foreign VA multiplier

  ## exporter/source foreign-VA-once coefficient
  fvacoef <- numeric(GN)
  for(s in seq_len(G)) {
    bs <- blk(s)
    Ms <- Am[bs, , drop = FALSE] %*% B[, bs, drop = FALSE]   # N x N (= sum_{j!=s} A_sj B_js)
    fvacoef[bs] <- solve(t(IN + Ms), VBfor[bs])
  }

  BFD <- B %*% Y                                      # output driven by each country's final demand

  list(G = G, N = N, GN = GN, k = k, i = i, Nseq = Nseq, blk = blk, ctryvec = ctryvec,
       idiag = idiag, IN = IN, A = A, Am = Am, B = B, Lb = Lb, Vc = Vc, X = X, E = E, ESR = ESR,
       Y = Y, Yd = Yd, Ym = Ym, VBdom = VBdom, VBfor = VBfor, VLdom = VLdom, fvacoef = fvacoef,
       Wcol = Wcol, BFD = BFD)
}

# directly-absorbed exports DAE and absorbed-abroad exports VAXE (GN x G), exporter/source
.bm_dae_vaxe <- function(P) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  Am <- Wcol <- BFD <- X <- Ym <- G <- blk <- idiag <- NULL
  list2env(P, environment())
  DAE  <- Ym
  VAXE <- Ym
  for(r in seq_len(G)) {
    br <- blk(r)
    DAE[, r]  <- DAE[, r] + Am[, br, drop = FALSE] %*% Wcol[br]
    Mr        <- Am[, br, drop = FALSE] %*% BFD[br, , drop = FALSE]   # GN x G
    VAXE[, r] <- VAXE[, r] + Am[, br, drop = FALSE] %*% X[br] - Mr[idiag]
  }
  list(DAE = DAE, VAXE = VAXE)
}

## ------------------------------------------------------------------------------------------------
## Engine: exporter / source (13 terms), country / sector / bilateral
## ------------------------------------------------------------------------------------------------
.bm_source <- function(P, aggregation) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  ESR <- VBdom <- VBfor <- VLdom <- fvacoef <- G <- N <- GN <- k <- i <- ctryvec <- NULL
  list2env(P, environment())
  ord13 <- c("GEXP","DC","DVA","VAX","DAVAX","REF","DDC","FC","FVA","FDC","GVC","GVCB","GVCF")

  if(aggregation == "bilateral") {
    dv   <- .bm_dae_vaxe(P); DAE <- dv$DAE; VAXE <- dv$VAXE
    GEXP  <- ESR
    DC    <- VBdom   * ESR
    FC    <- VBfor   * ESR
    DVA   <- VLdom   * ESR
    DDC   <- DC - DVA
    FVA   <- fvacoef * ESR
    FDC   <- FC - FVA
    DAVAX <- VLdom * DAE
    VAX   <- VLdom * VAXE
    REF   <- DVA - VAX
    GVC   <- ESR - DAVAX
    GVCB  <- FC + DDC
    GVCF  <- GVC - GVCB
    terms <- list(GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, DAVAX = DAVAX, REF = REF,
                  DDC = DDC, FC = FC, FVA = FVA, FDC = FDC, GVC = GVC, GVCB = GVCB, GVCF = GVCF)
    expsec <- rep.int(seq_len(GN), G)
    imp    <- rep(seq_len(G), each = GN)
    keep   <- ctryvec[expsec] != imp                  # drop within-country flows
    out <- c(list(Exporting_Country  = .bm_fct(ctryvec[expsec][keep], k),
                  Exporting_Industry = .bm_fct(rep.int(seq_len(N), G)[expsec][keep], i),
                  Importing_Country  = .bm_fct(imp[keep], k)),
             lapply(terms[ord13], function(m) as.vector(m)[keep]))
    return(list(out = out, nr = sum(keep)))
  }

  ## sector-level source terms (summed over importers)
  sec <- .bm_source_sec(P)
  if(aggregation == "sector") {
    out <- c(list(Exporting_Country  = .bm_fct(ctryvec, k),
                  Exporting_Industry = .bm_fct(rep.int(seq_len(N), G), i)),
             sec[ord13])
    return(list(out = out, nr = GN))
  }

  ## country level: sum sector terms within country
  cty <- lapply(sec[ord13], function(v) rowsum(v, ctryvec, reorder = FALSE)[, 1L])
  out <- c(list(Exporting_Country = .bm_fct(seq_len(G), k)), cty)
  list(out = out, nr = G)
}

# sector-level source terms as a named list of GN-length vectors (13 terms)
.bm_source_sec <- function(P) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  E <- VBdom <- VBfor <- VLdom <- fvacoef <- NULL
  list2env(P, environment())
  dv <- .bm_dae_vaxe(P); DAE <- dv$DAE; VAXE <- dv$VAXE
  GEXP  <- E
  DC    <- VBdom * E
  DVA   <- VLdom * E
  VAX   <- VLdom * rowSums2(VAXE)
  DAVAX <- VLdom * rowSums2(DAE)
  REF   <- DVA - VAX
  DDC   <- DC - DVA
  FC    <- VBfor * E
  FVA   <- fvacoef * E
  FDC   <- FC - FVA
  GVC   <- E - DAVAX
  GVCB  <- FC + DDC
  GVCF  <- GVC - GVCB
  list(GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, DAVAX = DAVAX, REF = REF,
       DDC = DDC, FC = FC, FVA = FVA, FDC = FDC, GVC = GVC, GVCB = GVCB, GVCF = GVCF)
}

## ------------------------------------------------------------------------------------------------
## Engine: world perspective (9 terms), country level. Domestic side + FC from source; only
## FVA/FDC change with the world approach (Borin & Mancini 2019, eq. 52 source / eq. 54 sink).
## ------------------------------------------------------------------------------------------------
.bm_world <- function(P, approach) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  A <- Am <- B <- Lb <- Vc <- E <- Ym <- Wcol <- VBfor <- VLdom <- G <- GN <- k <- blk <- ctryvec <- idiag <- NULL
  list2env(P, environment())
  sec <- .bm_source_sec(P)
  agg <- function(v) rowsum(v, ctryvec, reorder = FALSE)[, 1L]
  cty <- lapply(sec, agg)

  if(approach == "sink") {
    ## world/sink foreign VA (eq. 54)
    Yms     <- rowSums2(Ym)
    wv      <- Yms + as.vector(Am %*% Wcol)
    Wrex    <- numeric(GN)                             # L %*% wv, block-diagonal
    for(g in seq_len(G)) { bg <- blk(g); Wrex[bg] <- Lb[[g]] %*% wv[bg] }
    AsrWrex <- matrix(0, GN, G)
    VBR     <- matrix(0, GN, G)
    for(r in seq_len(G)) {
      br <- blk(r)
      AsrWrex[, r] <- Am[, br, drop = FALSE] %*% Wrex[br]
      VBR[, r]     <- colSums2(B[br, , drop = FALSE] * Vc[br])   # sum_{m in r} V_m B[m, ]
    }
    dv     <- .bm_dae_vaxe(P); DAE <- dv$DAE
    TC     <- VBR * AsrWrex
    fva_cs <- VBfor * (rowSums2(DAE) - DAE[idiag]) + (rowSums2(TC) - TC[idiag])
    FVA    <- agg(fva_cs)
  } else {
    ## world/source foreign VA (eq. 52): FVA_s = sum_{t not in s} VLdom_t * (A[,s] %*% L_ss E_s)_t
    FVA <- numeric(G)
    for(s in seq_len(G)) {
      bs   <- blk(s)
      etil <- Lb[[s]] %*% E[bs]                          # L_ss E_s (N-vector)
      w    <- as.vector(A[, bs, drop = FALSE] %*% etil)   # GN-vector
      keep <- ctryvec != s                                # foreign origins only
      FVA[s] <- sum(VLdom[keep] * w[keep])
    }
  }

  cty$FVA <- FVA
  cty$FDC <- cty$FC - FVA
  ord9 <- c("GEXP","DC","DVA","VAX","REF","DDC","FC","FVA","FDC")
  out  <- c(list(Exporting_Country = .bm_fct(seq_len(G), k)), cty[ord9])
  list(out = out, nr = G)
}

## ------------------------------------------------------------------------------------------------
## Engine: exporter / sink (Borin & Mancini 2019, eq. 33-39), sector (9) / bilateral (10, +VAXIM).
## Same country perimeter as source; VA recorded the last time it leaves s. DC/FC match source.
## ------------------------------------------------------------------------------------------------
.bm_sink <- function(P, aggregation) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  A <- B <- Lb <- E <- ESR <- X <- Y <- BFD <- VBdom <- VBfor <- G <- N <- GN <- k <- i <- IN <- blk <- ctryvec <- NULL
  list2env(P, environment())
  ABFD <- A %*% BFD
  Yrow <- rowSums2(Y)                                    # GN
  bilateral <- aggregation == "bilateral"

  if(bilateral) {
    nr <- G * (G - 1L) * N
    expg <- integer(nr); expn <- integer(nr); impr <- integer(nr)
    GEXP <- numeric(nr); DC <- numeric(nr); DVA <- numeric(nr); VAX <- numeric(nr)
    VAXIM <- numeric(nr); REF <- numeric(nr); DDC <- numeric(nr)
    FC <- numeric(nr); FVA <- numeric(nr); FDC <- numeric(nr)
    row <- 0L
  } else {
    DVA <- numeric(GN); FVA <- numeric(GN); REF <- numeric(GN)
  }

  for(s in seq_len(G)) {
    bs    <- blk(s)
    Ass   <- A[bs, bs, drop = FALSE]
    Bsrng <- B[, bs, drop = FALSE]                       # GN x N
    Fsinv <- solve((IN - Ass) %*% B[bs, bs, drop = FALSE])
    ehat    <- Fsinv %*% E[bs]
    Xtil    <- X - Bsrng %*% ehat                        # GN
    AXtil   <- A %*% Xtil                                # GN
    rhs_s   <- ABFD[bs, s] - Ass %*% BFD[bs, s]
    Xtil_s  <- BFD[, s] - Bsrng %*% (Fsinv %*% rhs_s)    # GN
    AXtil_s <- A %*% Xtil_s
    for(r in seq_len(G)) {
      if(r == s) next
      br  <- blk(r)
      Lrr <- Lb[[r]]; Arr <- A[br, br, drop = FALSE]; Asr <- A[bs, br, drop = FALSE]
      Psi  <- Yrow[br] + AXtil[br] - Arr %*% Xtil[br]
      Phi  <- as.vector(Y[bs, r] + Asr %*% (Lrr %*% Psi))                # N
      Psir <- Y[br, s] + AXtil_s[br] - Arr %*% Xtil_s[br]
      Phir <- as.vector(Asr %*% (Lrr %*% Psir))                         # N
      if(bilateral) {
        rhsvx <- ABFD[bs, r] - Ass %*% BFD[bs, r] + Y[bs, r]
        xr    <- BFD[, r] - Bsrng %*% (Fsinv %*% rhsvx)                 # GN
        arx   <- A[br, , drop = FALSE] %*% xr - Arr %*% xr[br]          # N
        Phivx <- as.vector(Y[bs, r] + Asr %*% (Lrr %*% (Y[br, r] + arx)))
        for(kk in seq_len(N)) {
          n <- bs[kk]; row <- row + 1L
          e_sr <- ESR[n, r]
          DCv <- VBdom[n] * e_sr; FCv <- VBfor[n] * e_sr
          DVAv <- VBdom[n] * Phi[kk]; FVAv <- VBfor[n] * Phi[kk]; REFv <- VBdom[n] * Phir[kk]
          expg[row] <- s; expn[row] <- kk; impr[row] <- r
          GEXP[row] <- e_sr; DC[row] <- DCv; FC[row] <- FCv
          DVA[row] <- DVAv; DDC[row] <- DCv - DVAv
          FVA[row] <- FVAv; FDC[row] <- FCv - FVAv
          REF[row] <- REFv; VAX[row] <- DVAv - REFv
          VAXIM[row] <- VBdom[n] * Phivx[kk]
        }
      } else {
        for(kk in seq_len(N)) {
          n <- bs[kk]
          DVA[n] <- DVA[n] + VBdom[n] * Phi[kk]
          FVA[n] <- FVA[n] + VBfor[n] * Phi[kk]
          REF[n] <- REF[n] + VBdom[n] * Phir[kk]
        }
      }
    }
  }

  if(bilateral) {
    out <- list(Exporting_Country  = .bm_fct(expg, k),
                Exporting_Industry = .bm_fct(expn, i),
                Importing_Country  = .bm_fct(impr, k),
                GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, VAXIM = VAXIM, REF = REF,
                DDC = DDC, FC = FC, FVA = FVA, FDC = FDC)
    return(list(out = out, nr = nr))
  }
  GEXP <- E; DC <- VBdom * E; FC <- VBfor * E
  DDC  <- DC - DVA; FDC <- FC - FVA; VAX <- DVA - REF
  out <- list(Exporting_Country  = .bm_fct(ctryvec, k),
              Exporting_Industry = .bm_fct(rep.int(seq_len(N), G), i),
              GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, REF = REF,
              DDC = DDC, FC = FC, FVA = FVA, FDC = FDC)
  list(out = out, nr = GN)
}

## ------------------------------------------------------------------------------------------------
## Engine: self perimeter (Borin & Mancini 2019, eq. 47-49), sector (sectexp) / bilateral (sectbil).
## Perimeter = the export flow itself. Rank-1 perimeter update: DVA* = VBdom/(1+a) e,
## FVA* = VBfor/(1+a) e; VAX* = (DVA*/e) VAXE (perimeter-invariant reflection share). 9 terms.
## ------------------------------------------------------------------------------------------------
.bm_self <- function(P, aggregation) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  A <- B <- E <- ESR <- X <- Y <- BFD <- VBdom <- VBfor <- G <- N <- GN <- k <- i <- IN <- blk <- ctryvec <- NULL
  list2env(P, environment())

  if(aggregation == "sector") {
    VAXEsum <- numeric(GN); DVA <- numeric(GN); VAX <- numeric(GN); FVA <- numeric(GN)
    for(s in seq_len(G)) {
      bs <- blk(s)
      for(r in seq_len(G)) {
        if(r == s) next
        br   <- blk(r)
        vaxe <- as.vector(A[bs, br, drop = FALSE] %*% (X[br] - BFD[br, s]))   # N
        VAXEsum[bs] <- VAXEsum[bs] + Y[bs, r] + vaxe
      }
      Bss <- B[bs, bs, drop = FALSE]
      Ms  <- (Bss - IN) - A[bs, bs, drop = FALSE] %*% Bss                     # sum_{j!=s} A_sj B_js
      d   <- 1 + diag(Ms)
      DVA[bs] <- VBdom[bs] / d * E[bs]
      VAX[bs] <- VBdom[bs] / d * VAXEsum[bs]
      FVA[bs] <- VBfor[bs] / d * E[bs]
    }
    GEXP <- E; DC <- VBdom * E; FC <- VBfor * E
    REF  <- DVA - VAX; DDC <- DC - DVA; FDC <- FC - FVA
    out <- list(Exporting_Country  = .bm_fct(ctryvec, k),
                Exporting_Industry = .bm_fct(rep.int(seq_len(N), G), i),
                GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, REF = REF,
                DDC = DDC, FC = FC, FVA = FVA, FDC = FDC)
    return(list(out = out, nr = GN))
  }

  ## bilateral (sectbil)
  nr <- G * (G - 1L) * N
  expg <- integer(nr); expn <- integer(nr); impr <- integer(nr)
  GEXP <- numeric(nr); DC <- numeric(nr); DVA <- numeric(nr); VAX <- numeric(nr)
  REF <- numeric(nr); DDC <- numeric(nr); FC <- numeric(nr); FVA <- numeric(nr); FDC <- numeric(nr)
  row <- 0L
  for(s in seq_len(G)) {
    bs <- blk(s)
    for(r in seq_len(G)) {
      if(r == s) next
      br   <- blk(r)
      Asr  <- A[bs, br, drop = FALSE]
      Psr  <- Asr %*% B[br, bs, drop = FALSE]                      # A_sr B_rs (N x N)
      vaxe <- as.vector(Asr %*% (X[br] - BFD[br, s]))              # N
      dPsr <- diag(Psr)
      for(kk in seq_len(N)) {
        row <- row + 1L; gi <- bs[kk]
        e     <- ESR[gi, r]
        cstar <- VBdom[gi] / (1 + dPsr[kk])
        DVAv  <- cstar * e
        VAXv  <- cstar * (Y[gi, r] + vaxe[kk])
        DCv   <- VBdom[gi] * e; FCv <- VBfor[gi] * e
        FVAv  <- VBfor[gi] / (1 + dPsr[kk]) * e
        expg[row] <- s; expn[row] <- kk; impr[row] <- r
        GEXP[row] <- e; DC[row] <- DCv; FC[row] <- FCv
        DVA[row] <- DVAv; VAX[row] <- VAXv; REF[row] <- DVAv - VAXv
        DDC[row] <- DCv - DVAv; FVA[row] <- FVAv; FDC[row] <- FCv - FVAv
      }
    }
  }
  out <- list(Exporting_Country  = .bm_fct(expg, k),
              Exporting_Industry = .bm_fct(expn, i),
              Importing_Country  = .bm_fct(impr, k),
              GEXP = GEXP, DC = DC, DVA = DVA, VAX = VAX, REF = REF,
              DDC = DDC, FC = FC, FVA = FVA, FDC = FDC)
  list(out = out, nr = nr)
}

## ------------------------------------------------------------------------------------------------
## Engine: importer perspective, gross imports (Borin & Mancini 2019, eq. 51). Country (gimp/va/dc)
## and bilateral (va/dc by value-added origin). Column-block Woodbury update of B per importer.
## ------------------------------------------------------------------------------------------------
.bm_imports <- function(P, aggregation) {
  # NULL-initialised so R CMD check does not flag the list2env() locals as globals
  A <- B <- ESR <- Vc <- G <- GN <- k <- IN <- blk <- NULL
  list2env(P, environment())
  BESR <- B %*% ESR                                     # GN x G, BESR[,r] = B d^r
  va <- matrix(0, GN, G); dc <- matrix(0, GN, G)
  for(r in seq_len(G)) {
    br    <- blk(r)
    Irr   <- IN - A[br, br, drop = FALSE]
    Frinv <- solve(B[br, br, drop = FALSE] %*% Irr)     # K_r = B_rr (I - A_rr)
    BMcol <- B[, br, drop = FALSE] %*% Irr              # B_.r (I - A_rr)
    BMcol[br, ] <- BMcol[br, ] - IN                     # - I_.r
    Bdr     <- BESR[, r]
    btil_dr <- as.vector(Bdr - BMcol %*% (Frinv %*% Bdr[br]))     # B~^r d^r
    gr      <- Bdr[br]                                            # (B d^r)_r
    hr      <- as.vector(A[, br, drop = FALSE] %*% gr)            # A_.r g^r
    hr[br]  <- 0                                                  # keep t != r
    Bhr     <- as.vector(B %*% hr)
    btil_hr <- as.vector(Bhr - BMcol %*% (Frinv %*% Bhr[br]))     # B~^r h^r
    va[, r] <- Vc * btil_dr
    dc[, r] <- Vc * btil_hr
  }

  if(aggregation == "country") {
    VA <- colSums2(va); DC <- colSums2(dc)
    out <- list(Importing_Country = .bm_fct(seq_len(G), k),
                GIMP = VA + DC, VA = VA, DC = DC)
    return(list(out = out, nr = G))
  }

  ## bilateral: value-added origin j breakdown of r's imports (all j, incl. re-imported domestic)
  nr <- G * G
  impr <- integer(nr); orij <- integer(nr); VA <- numeric(nr); DC <- numeric(nr)
  row <- 0L
  for(r in seq_len(G)) {
    for(j in seq_len(G)) {
      row <- row + 1L; bj <- blk(j)
      impr[row] <- r; orij[row] <- j
      VA[row] <- sum(va[bj, r]); DC[row] <- sum(dc[bj, r])
    }
  }
  out <- list(Importing_Country = .bm_fct(impr, k), Origin_Country = .bm_fct(orij, k),
              VA = VA, DC = DC)
  list(out = out, nr = nr)
}
