#' @name icio-package
#' @title Global Value Chain Decomposition of Inter-Country Input-Output Tables
#' @author
#' Sebastian Krantz \email{sebastian.krantz@@graduateinstitute.ch}\cr
#' Bastiaan Quast\cr
#' Fei Wang\cr
#' Victor Stolzenburg
#' @description Four global value chain (GVC) decompositions are implemented. The Leontief decomposition
#' derives the value added origin of exports by country and industry as in Hummels, Ishii and Yi (2001).
#' The Koopman, Wang and Wei (2014) decomposition splits country-level exports into 9 value added components,
#' and the Wang, Wei and Zhu (2013) decomposition splits bilateral exports into 16 value added components.
#' The Borin and Mancini (2019) decomposition splits country-, sector- or bilateral-level exports into up to
#' 13 value added and GVC components, and also provides a corrected version of the (biased) KWW decomposition.
#' It is the recommended method and reproduces the Stata \code{icio} command.
#'
#' @section Contents:
#' Functions to load an ICIO table and create an 'icio' object
#'
#' \code{\link[=load_icio]{load_icio()}}\cr
#' \code{\link[=load_icio_csv]{load_icio_csv()}}
#'
#' Functions to perform GVC decompositions on an 'icio' object
#'
#' \code{\link[=bm]{bm()}}\cr
#' \code{\link[=leontief]{leontief()}}\cr
#' \code{\link[=kww]{kww()}}\cr
#' \code{\link[=wwz]{wwz()}}
#'
#' Interface function dispatching on the method, also for lists of 'icio' objects (e.g. several years)
#'
#' \code{\link[=decomp]{decomp()}}
#'
#' Function to obtain KWW decomposition from WWZ decomposition
#'
#' \code{\link[=wwz2kww]{wwz2kww()}}
#'
#' Example ICIO data
#'
#' \code{\link[=leather]{data("leather")}}
#'
#' @section Note:
#' \code{icio} is derived from the CRAN package \code{decompr} (Quast and Kummritz 2015), of which
#' the author was a co-author and which is no longer maintained. \code{bm()} is the R counterpart of
#' \code{decompose()} in the Julia package
#' \href{https://github.com/SebKrantz/GlobalValueChains.jl}{GlobalValueChains.jl}.
#'
#' @seealso https://sebkrantz.github.io/icio/
#' @references
#' Hummels, D., Ishii, J., & Yi, K. M. (2001). The nature and growth of vertical specialization in world trade. \emph{Journal of international Economics, 54}(1), 75-96.
#'
#' Koopman, R., Wang, Z., & Wei, S. J. (2014). Tracing value-added and double counting in gross exports. \emph{American Economic Review, 104}(2), 459-94.
#'
#' Wang, Zhi, Shang-Jin Wei, and Kunfu Zhu (2013). Quantifying international production sharing at the bilateral and sector levels (No. w19677). \emph{National Bureau of Economic Research}.
#'
#' Borin, A., & Mancini, M. (2019). Measuring What Matters in Global Value Chains and Value-Added Trade. \emph{World Bank Policy Research Working Paper 8804}.
#'
#' Belotti, F., Borin, A., & Mancini, M. (2021). icio: Economic analysis with inter-country input-output tables. \emph{The Stata Journal, 21}(3), 708-755.
#' @importFrom stats setNames
#' @importFrom matrixStats rowSums2 colSums2 x_OP_y
#' @importFrom data.table fread rbindlist setDT setattr
#' @useDynLib icio, .registration = TRUE
"_PACKAGE"

#' @name leather
#' @docType data
#' @title Leather Example ICIO Data
#' @description An example 3 x 3 ICIO table describing a GVC for leather products with industries 'Agriculture', 'Textile and Leather' and 'Transport Equipment'
#' for the countries 'Argentina', 'Turkey' and 'Germany'.
#' @usage data("leather")
#'
#' @format A list of class 'iot' with the following elements:
#' \describe{
#'  \item{\code{inter}}{9 x 9 input output matrix where each column gives the value of inputs supplied to the corresponding country-industry by each row country-industry.}
#'  \item{\code{final}}{9 x 3 final demand matrix showing the final demand in each country (column) for each country-industry's (rows) produce.}
#'  \item{\code{countries}}{character vector of country names (matching columns of \code{final}).}
#'  \item{\code{industries}}{character vector of industries, such that \code{as.vector(t(outer(countries, industries, FUN = paste, sep = ".")))} generates the row- and column-names of \code{inter} and the rownames of \code{final}.}
#'  \item{\code{out}}{A vector of gross country-industry output. In a complete productive system it should be equal to \code{rowSums(inter) + rowSums(final)}.}
#' }
#' @seealso \code{\link{icio-package}}
NULL
