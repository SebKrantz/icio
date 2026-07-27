#' Run a GVC Decomposition
#'
#' A compact interface to the four decompositions: it dispatches on \code{method} and, given a list
#' of 'icio' objects (e.g. one per year), runs the decomposition on each and stacks the results.
#'
#' @param x an 'icio' class object from \code{\link{load_icio}} or \code{\link{load_icio_csv}}, or a
#' (preferably named) list of such objects, e.g. one ICIO table per year.
#' @param method character. The decomposition method: \code{"bm"} (the default and recommended
#' method, see \code{\link{bm}}), \code{"leontief"}, \code{"kww"} or \code{"wwz"}.
#' @param \dots further arguments passed to \code{\link{bm}}, \code{\link{leontief}},
#' \code{\link{kww}} or \code{\link{wwz}}.
#' @param idcol character. Only used if \code{x} is a list: the name of the identifier column
#' prepended to the stacked result. It holds the names of \code{x}, or the list indices if \code{x}
#' is unnamed. Set to \code{NULL} to omit it.
#' @return A \code{data.table} - see \code{\link{bm}}, \code{\link{leontief}}, \code{\link{kww}} or
#' \code{\link{wwz}} for the columns of each decomposition. If \code{x} is a list, the results are
#' stacked with \code{\link[data.table]{rbindlist}} and prefixed with \code{idcol}.
#' @details Building an 'icio' object is by far the most expensive step (it involves inverting a
#' \code{GN x GN} matrix), so it is done once by \code{\link{load_icio}} and reused across
#' decompositions. Pass the object to \code{\link{bm}}, \code{\link{leontief}}, \code{\link{kww}} or
#' \code{\link{wwz}} directly if you prefer.
#' @author Sebastian Krantz, Bastiaan Quast
#' @references
#' Hummels, D., Ishii, J., & Yi, K. M. (2001). The nature and growth of vertical specialization in world trade. \emph{Journal of international Economics, 54}(1), 75-96.
#'
#' Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and double counting in gross exports. \emph{American Economic Review, 104}(2), 459-94.
#'
#' Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying international production sharing at the bilateral and sector levels (No. w19677). \emph{National Bureau of Economic Research}.
#'
#' Borin, A., & Mancini, M. (2019). Measuring What Matters in Global Value Chains and Value-Added Trade. \emph{World Bank Policy Research Working Paper 8804}.
#' @export
#' @seealso \code{\link{load_icio}}, \code{\link{bm}}, \code{\link{icio-package}}
#' @examples
#' # Load leather example data
#' data(leather)
#'
#' # Explore the data
#' str(leather)
#'
#' # Create the 'icio' object
#' m <- load_icio(leather)
#'
#' ## Decomposing gross exports:
#'
#' # Borin-Mancini (2019), the recommended method
#' decomp(m)
#' decomp(m, aggregation = "bilateral")
#'
#' # Leontief, Koopman-Wang-Wei and Wang-Wei-Zhu
#' decomp(m, method = "leontief")
#' decomp(m, method = "kww")
#' decomp(m, method = "wwz")
#'
#' # Multiple tables at once, e.g. one per year, stacked with a 'Year' column
#' decomp(list(`2015` = m, `2016` = m), idcol = "Year")

decomp <- function(x, method = c("bm", "leontief", "kww", "wwz"), ..., idcol = "Label") {

  method <- match.arg(method)

  if(!inherits(x, "icio")) {
    if(!is.list(x) || !length(x) || !all(vapply(x, inherits, TRUE, "icio")))
      stop("'x' must be an 'icio' object created by load_icio() or load_icio_csv(), or a list of such objects.")
    res <- lapply(x, decomp, method = method, ...)
    if(is.null(idcol)) return(rbindlist(res))
    if(is.null(names(res))) names(res) <- seq_along(res)
    return(rbindlist(res, idcol = idcol))
  }

  switch(method,
         bm = bm(x, ...),
         leontief = leontief(x, ...),
         kww = kww(x, ...),
         wwz = wwz(x, ...))
}
