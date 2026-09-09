#' Recode a messy survey column into clean 0/1
#'
#' Converts alternative survey response values into clean standard numeric
#' 0 or 1 scores.  When \code{no} is not specified, every value that is
#' neither in \code{yes} nor \code{NA} is treated as 0.  When \code{no}
#' \emph{is} specified, values matching neither \code{yes} nor \code{no}
#' are left as \code{NA} and a warning is issued.
#'
#' @param x A vector coding a single condition.
#' @param yes The raw value(s) that should become 1.
#' @param no  Optional raw value(s) that should become 0.  If \code{NULL}
#'   (the default), every non-\code{yes}, non-\code{NA} value becomes 0.
#'
#' @return A numeric vector of 0, 1, or \code{NA}.
#'
#' @examples
#' # STEPS-style coding: 1 = yes, 2 = no
#' recode_binary(c(1, 2, 1, NA), yes = 1, no = 2)
#'
#' # When `no` is omitted, everything that isn't `yes` becomes 0
#' recode_binary(c(1, 2, 9, NA), yes = 1)
#'
#' # With `no` specified, unrecognised codes (9) become NA with a warning
#' recode_binary(c(1, 2, 9, NA), yes = 1, no = 2)
#'
#' @export
recode_binary <- function(x, yes, no = NULL) {
  out <- rep(NA_real_, length(x))
  out[x %in% yes] <- 1

  if (is.null(no)) {
    # When `no` is not specified, treat everything that isn't `yes` as 0
    out[!(x %in% yes) & !is.na(x)] <- 0
  } else {
    out[x %in% no] <- 0
    remaining <- !(x %in% yes) & !(x %in% no) & !is.na(x)
    if (any(remaining)) {
      warning("Some values matched neither `yes` nor `no`; leaving them as NA.", call. = FALSE)
    }
  }
  return(out)
}
