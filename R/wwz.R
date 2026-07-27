#' Wang-Wei-Zhu Decomposition of Gross Exports
#' 
#' This function performs the Wang-Wei-Zhu decomposition of country-sector level gross exports into 16 value added components by importing country.
#' 
#' @param x an object of the class 'icio' obtained from \code{\link{load_icio}}.
#' @param verbose logical, should timings of the calculation be displayed? Default is FALSE
#' @author Bastiaan Quast
#' @details Adapted from code by Fei Wang.
#' @return A long-format \code{data.table} with one row per (exporting country-industry, importing
#'  country) pair and columns \code{Exporting_Country}, \code{Exporting_Industry},
#'  \code{Importing_Country} followed by the 16 decomposition terms (as detailed in Table E1
#'  in the appendix of Wang, Wei & Zhu 2013) and diagnostic items:
#'  \tabular{ll}{
#'  \emph{Term} \tab \emph{Description} \cr
#'  \code{DVA_FIN} \tab Domestic VA in final goods exports. \cr
#'  \code{DVA_INT} \tab Domestic VA in intermediate exports used by direct importer to produce domestic final goods consumed at home. \cr
#'  \code{DVA_INTrexI1} \tab Domestic VA in intermediate exports used by the direct importer to produce intermediate exports for production of final goods in third countries that are then imported and consumed by the direct importer. \cr
#'  \code{DVA_INTrexF} \tab Domestic VA in intermediate exports used by the direct importer to produce final goods exports to third countries. \cr
#'  \code{DVA_INTrexI2} \tab Domestic VA in intermediate exports used by the direct importer to produce intermediate exports to third countries. \cr
#'  \code{RDV_INT} \tab Domestic VA in intermediate exports that returns via intermediate imports (i.e. is used to produce a locally consumed final good). \cr
#'  \code{RDV_FIN} \tab Domestic VA in intermediate exports that returns home via final goods imports from the direct importer. \cr
#'  \code{RDV_FIN2} \tab Domestic VA in intermediate exports that returns home via final goods imports from third countries. \cr
#'  \code{OVA_FIN} \tab Third countries’ VA in final goods exports. \cr
#'  \code{MVA_FIN} \tab Direct importer’s VA in final goods exports. \cr
#'  \code{OVA_INT} \tab Third countries’ VA in intermediate exports. \cr
#'  \code{MVA_INT} \tab Direct importer’s VA in intermediate exports. \cr
#'  \code{DDC_FIN} \tab Double counted domestic VA used to produce final goods exports. \cr
#'  \code{DDC_INT} \tab Double counted domestic VA used to produce intermediate exports. \cr
#'  \code{ODC} \tab Double counted third countries’ VA in home country’s exports production. \cr
#'  \code{MDC} \tab Double counted direct importer’s VA in home country’s exports production. \cr
#'  \emph{Diagnostic Item} \tab \emph{Description} \cr
#'  \code{texp} \tab Total exports (matrix \code{ESR} from \code{\link{load_icio}}). \cr
#'  \code{texpint} \tab Exports for intermediate production (matrix \code{Eint} from \code{\link{load_icio}}). \cr
#'  \code{texpfd} \tab Exports for final demand (matrix \code{Efd} from \code{\link{load_icio}}). \cr
#'  \code{texpdiff} \tab Difference between total exports and the sum of the 16 terms. \cr
#'  \code{texpdiffpercent} \tab ... in percent of total exports. \cr
#'  \code{texpfddiff} \tab Difference between final exports and the sum of DVA_FIN, OVA_FIN and MVA_FIN. \cr
#'  \code{texpfddiffpercent} \tab ... in percent of final exports. \cr
#'  \code{texpintdiff} \tab Difference between intermediate exports and the sum of all remaining terms. \cr
#'  \code{texpintdiffpercent} \tab ... in percent of intermediate exports. \cr
#'  \code{DViX_Fsr} \tab DVA embodied in gross exports based on forward linkage. \cr
#'  }
#' @references Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying international production sharing at the bilateral and sector levels (No. w19677). \emph{National Bureau of Economic Research}.
#' @export
#' @seealso \code{\link{bm}}, \code{\link{kww}}, \code{\link{wwz2kww}}, \code{\link{icio-package}}
#' @examples
#' # Load example data
#' data(leather)
#' 
#' # Create intermediate object (class 'icio')
#' m <- load_icio(leather)
#' 
#' # Perform the WWZ decomposition
#' wwz(m)

wwz <- function(x, verbose = FALSE) {
    
    if(!inherits(x, "icio")) stop("x must be an object of class 'icio' created by the load_icio() function.")
    
    # This loads all the elements into the current function namespace, and avoids 165 calls to x$... some of which are done inside loops.
    GN <- G <- ESR <- Vc <- Ym <- Lb <- A <- B <- Yd <- N <- X <- E <- k <- i <- NULL # First need to initialize as NULL to avoid R CMD check error.
    list2env(x, environment())

    ## Unlike the other decompositions, WWZ works with the masked matrices throughout (it uses them
    ## in dense GN x GN products, so there is nothing to gain from a blockwise formulation). Since
    ## the 'icio' object does not carry them, they are rebuilt here from A and B. The
    ## block-diagonal L is not needed densely and is used via Lb below.
    Am <- A
    Bd <- matrix(0, nrow = GN, ncol = GN)
    Bm <- B
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q)
        Am[mn, mn] <- 0
        Bd[mn, mn] <- B[mn, mn]
        Bm[mn, mn] <- 0
    }
    ## Final goods exports by destination are the foreign part of final demand; the remainder of
    ## exports by destination is intermediate.
    Efd  <- Ym
    Eint <- ESR - Ym

    ## Part 1: Decomposing Export into VA (16 items) defining ALL to
    ## contain all decomposed results
    ALL <- array(0, dim = c(GN, G, 19L))
    
    ## the order of 16 items and exp, expint, expfd
    decomp19 <- c("DVA_FIN",            # term #01 in equation (19)
                  "DVA_INT",            # term #02 in equation (19)
                  "DVA_INTrexI1",       # term #03 in equation (19)
                  "DVA_INTrexF",        # term #04 in equation (19)
                  "DVA_INTrexI2",       # term #05 in equation (19)
                  "RDV_INT",            # term #06 in equation (19)
                  "RDV_FIN",            # term #07 in equation (19)
                  "RDV_FIN2",           # term #08 in equation (19)
                  "OVA_FIN",            # term #09 in equation (19)
                  "MVA_FIN",            # term #10 in equation (19)
                  "OVA_INT",            # term #11 in equation (19)
                  "MVA_INT",            # term #12 in equation (19)
                  "DDC_FIN",            # term #13 in equation (19)
                  "DDC_INT",            # term #14 in equation (19)
                  "ODC",                # term #15 in equation (19)
                  "MDC",                # term #16 in equation (19)
                  "texp",               
                  "texpint",
                  "texpfd")
    
    ALL[, , 17L] <- ESR
    ALL[, , 18L] <- Eint
    ALL[, , 19L] <- Efd
    ## Eint <- NULL
    ## Efd <- NULL
    
    # Unit vector will come in handy in several places
    # u <- rep.int(1L, GN)
    
    ##
    ## all Terms are numbered as in Table A2 in the Appendix of WWZ
    ## 

    if(verbose) {
        message("Starting decomposing the trade flow ...")
        start <- Sys.time()
    }
    ## 
    ## DVA_FIN: DVA embodied in final exports (foreign final demand)
    ##

    ## Term 1
    Bd_Vhat_sum <- colSums(Bd * Vc)
    ALL[, , 1L] <- Ym * Bd_Vhat_sum
    # for (r in 1:G) ALL[, r, 1L] <- colSums(Bd_Vhat * outer(u, Ym[, r]))
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("1/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }
    
    ## 
    ## DVA_INT: DVA in intermediate exports used by direct importer (r) to produce local final products
    ## 

    ## VsLss = Vc * L is block-diagonal, so both its column sums and its product with ESR are
    ## formed one country block at a time from Lb (no dense GN x GN intermediate).
    VsLss_colSums <- numeric(GN)
    DViX_Fsr <- matrix(0, nrow = GN, ncol = G)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q)
        VsLss_r <- Vc[mn] * Lb[[r]]
        VsLss_colSums[mn] <- colSums(VsLss_r)
        DViX_Fsr[mn, ] <- VsLss_r %*% ESR[mn, , drop = FALSE]
    }
    ## try to calculate DViX_Fsr
    DViX_Fsr <- t(DViX_Fsr)
    dim(DViX_Fsr) <- NULL

    ## Term 2

    ALL[, , 2L] <- Am %*% Bd %*% Yd * VsLss_colSums

    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("2/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }



    ##
    ## DVA_INTrex: 
    ## 

    ## Term 3: DVA in intermediate exports used to produce intermediates that are re-exported to third countries for production of local final products
    z1 <- matrix(rowSums(Yd), nrow = GN, ncol = GN)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z1[mn, mn] <- 0
    }

    z2 <- Bm %*% z1
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z2[mn, mn] <- 0
    }

    z3 <- Am * t(z2)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 3L] <- VsLss_colSums * rowSums2(z3, cols = mn)
    }
    rm(z3)
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("3/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    
    ## Term 4: DVA in intermediate exports used by r to produce final products that are re-exported to third countries.
    z <- matrix(0, nrow = GN, ncol = GN)
    z1 <- rowSums(Ym)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z[, mn] <- z1 - Ym[, r]
        z[mn, mn] <- 0
    }
    
    z2 <- Am * t(Bd %*% z)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 4L] <- VsLss_colSums * rowSums2(z2, cols = mn)
    }
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("4/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    
    ## Term 5: DVA in intermediate exports used by r to produce intermediates that are re-exported to t for the latter’s production of final exports that are shipped to other countries except Country s
    z1 <- t(Bm %*% z)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z1[mn, mn] <- 0
    }
    
    z2 <- Am * z1
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 5L] <- VsLss_colSums * rowSums2(z2, cols = mn)
    }
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("5/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }
    

    ##
    ## RDV_G
    ## 

    
    
    ## Term 6: DVA that returns home via its final imports from r
    z <- matrix(0, nrow = GN, ncol = GN)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z[, mn] <- Yd[, r]
    }
    
    z1 <- Am * t(Bm %*% z)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 6L] <- VsLss_colSums * rowSums2(z1, cols = mn)
    }
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("6/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    
    ## Term 7: DVA that returns home via final imports from third countries
    z <- matrix(0, nrow = GN, ncol = GN)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z[, mn] <- Ym[, r]
    }
    
    z1 <- Am * t(Bd %*% z)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 7L] <- VsLss_colSums * rowSums2(z1, cols = mn)
    }
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("7/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }
    
    
    ## Term 8: DVA that returns home via its intermediate imports and used to produce domestic final products
    z1 <- Bm %*% z
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z1[mn, mn] <- 0
    }
    
    z2 <- Am * t(z1)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 8L] <- VsLss_colSums * rowSums2(z2, cols = mn)
    }
    rm(z2)
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("8/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    

    ##
    ## DDC
    ## 

    ## Part 2-9 == H10-(9): DDC_FIN OK ! : DVA embodied in its intermediate exports to Country r but returns home as its intermediate imports, and used for production of its final exports
    z <- matrix(0, nrow = GN, ncol = GN)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        z[mn, mn] <- rowSums2(Ym, rows = mn)
    }
    
    z1 <- Am * t(Bm %*% z)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 13L] <- VsLss_colSums * rowSums2(z1, cols = mn)
    }
    rm(z1)
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("9/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }
    
    ## Part 2-10 == H10-(10): DDC_INT
    Am_X <- .Call(C_rowmult, Am, X) # Am * outer(u, X)
    Vc_Bd_VsLss_colsums <- Bd_Vhat_sum - VsLss_colSums
    
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ALL[, r, 14L] <- Vc_Bd_VsLss_colsums * rowSums2(Am_X, cols = mn)
    }
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("10/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    ## Part 2-11 == H10-(11): MVA_FIN =[ VrBrs#Ysr ] H10-(14): OVA_FIN =[
    ## Sum(VtBts)#rYsr ] OK !
    ## VrBrs <- Vhat %*% Bm            # TODO
    VrBrs <- Vc * Bm
    # YYsr <- matrix(0, nrow = GN, ncol = GN)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 
        ## YYsr[, 1:GN] <- Ym[, r]
        ## z <- VrBrs * t(YYsr)
        ## just as fast, but more memory efficient
        z <- .Call(C_rowmult, VrBrs, Ym[, r]) # VrBrs * outer(u, Ym[, r])
        ALL[, r, 9L] <- colSums2(z, rows = -mn)  # OVA_FIN[ ,r ]
        ALL[, r, 10L] <- colSums2(z, rows = mn)  # MVA_FIN[ ,r ]
    }
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("12/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }
    ## 
    ## MVA_FIN
    ## 
    
    ## Part 2-12 == H10-(12):
    ## MVA_INT =[ VrBrs#AsrLrrYrr ] H10-(15): OVA_INT =[
    ## Sum(VtBts)#AsrLrrYrr ] OK !

    # YYrr <- matrix(0, nrow = GN, ncol = GN)
    Am_L <- Am                          # Am %*% L, column block by column block (L block-diagonal)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q)
        Am_L[, mn] <- Am[, mn, drop = FALSE] %*% Lb[[r]]
    }
    Am_L_t <- t(Am_L)
    rm(Am_L)
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q) 

        ## message("r: ", r, "  --> m: ", m, "  n: ", n)
        ## YYrr[, 1:GN] <- Yd[, r]
        ## z <- VrBrs * t(Am_L %*% YYrr)
        
        ## better is:
        zz <- colSums(Am_L_t * Yd[, r])
        z <- .Call(C_rowmult, VrBrs, zz) # VrBrs * outer(u, zz)
                
        ALL[, r, 11L] <- colSums2(z, rows = -mn)  #   OVA_INT[ ,r ]
        ALL[, r, 12L] <- colSums2(z, rows = mn)  #  MVA_INT[ ,r ]
    }
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("14/16, elapsed time: ", elapsed, " seconds")
        start <- Sys.time()
    }    
    ## Part 2-13 == H10-(13): MDC
    ## =[ VrBrs#AsrLrrEr* ] == H10-(16): ODC =[ Sum(VtBts)#AsrLrrEr* ] OK !
    # Er <- rep.int(0L, GN)
    Am_L_t <- Am_L_t * E
    for (r in 1:G) {
        q <- (r - 1L) * N
        mn <- (1L + q):(N + q)

        ## EEr <- matrix(0, nrow = GN, ncol = GN)
        ## EEr[m:n, 1:GN] <- E[m:n]
        ## z <- VrBrs * t(Am_L %*% EEr)
        # zz <- colSums(Am_L_t * `[<-`(Er, m:n, value = E[m:n]))
        zz <- colSums2(Am_L_t, rows = mn)
        z <- .Call(C_rowmult, VrBrs, zz) # VrBrs * outer(u, zz)

        ALL[, r, 15L] <- colSums2(z, rows = -mn)  # ODC[ ,r ]
        ALL[, r, 16L] <- colSums2(z, rows = mn)  # MDC[ ,r ]
    }
    rm(Am_L_t, VrBrs)
    
    if(verbose) {
        elapsed <- round(Sys.time() - start, digits = 3L)
        message("16/16, elapsed time: ", elapsed, " seconds")
    }
    
    

    
    # dimnames(ALL) <- list(rownam, k, decomp19)

    ## 
    ## Part 3
    ## Putting all results in one sheet

    ALLandTotal <- aperm(ALL, c(2L, 1L, 3L)) 
    dim(ALLandTotal) <- c(GN * G, 19L)
    dimnames(ALLandTotal)[[2L]] <- decomp19

    ## rm(ALL)
    # rownames(ALLandTotal) <- NULL  #bigrownam

    ## 
    ## Part 4
    ## checking the differences resulted in texp, texpfd, texpintdiff

    ## Total Export goods difference
    texpdiff <- rowSums2(ALLandTotal, cols = 1:16) - ALLandTotal[, 17L]
    texpdiffpercent <- texpdiff / ALLandTotal[, 17L] * 100
    texpdiffpercent[is.na(texpdiffpercent)] <- 0
    texpdiff <- round(texpdiff, 4L)
    texpdiffpercent <- round(texpdiffpercent, 4L)

    ## Total Export Final goods difference
    texpfddiff <- rowSums2(ALLandTotal, cols = c(1L, 9L, 10L)) - ALLandTotal[, 19L]
    texpfddiffpercent <- texpfddiff / ALLandTotal[, 19L] * 100
    texpfddiffpercent[is.na(texpfddiffpercent)] <- 0
    texpfddiff <- round(texpfddiff, 4L)
    texpfddiffpercent <- round(texpfddiffpercent, 4L)

    ## Total intermediate export goods difference
    texpintdiff <- rowSums2(ALLandTotal, cols = c(2:8, 11:16)) - ALLandTotal[, 18L]
    texpintdiffpercent <- texpintdiff/ALLandTotal[, 18L] * 100
    texpintdiffpercent[is.na(texpintdiffpercent)] <- 0
    texpintdiff <- round(texpintdiff, 4L)
    texpintdiffpercent <- round(texpintdiffpercent, 4L)
    
    sk <- seq_along(k)
    ALLandTotal <- c(list(Exporting_Country = structure(rep(sk, each = GN), levels = k, class = "factor"),
                          Exporting_Industry = structure(rep(seq_along(i), times = G, each = G), levels = i, class = "factor"),
                          Importing_Country = structure(rep(sk, times = GN), levels = k, class = "factor")),
                        setNames(lapply(1:ncol(ALLandTotal), function(i) ALLandTotal[, i]), colnames(ALLandTotal)),
                        list(texpdiff = texpdiff,
                        texpdiffpercent = texpdiffpercent,
                        texpfddiff = texpfddiff,
                        texpfddiffpercent = texpfddiffpercent,
                        texpintdiff = texpintdiff,
                        texpintdiffpercent = texpintdiffpercent,
                        DViX_Fsr = DViX_Fsr))
     
    setDT(ALLandTotal)
    setattr(ALLandTotal, "decomposition", "wwz")


    return(ALLandTotal)
}
