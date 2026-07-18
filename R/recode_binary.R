#' Recode survey responses into 0/1/NA
#'
#' Converts raw response values into a standardized binary format for downstream
#' analysis.
#'
#' @param x A vector for one survey item or condition.
#' @param yes Value(s) in `x` that should be coded as `1`.
#' @param no Optional value(s) in `x` that should be coded as `0`. If `NULL`,
#'   all non-missing values not listed in `yes` remain `NA`.
#'
#' @return A numeric vector containing only `0`, `1`, and `NA`.
#' @export
recode_binary <- function(x, yes, no = NULL) {
  out <- rep(NA_real_, length(x))
  out[x %in% yes] <- 1

  if (is.null(no)) {
    remaining <- !(x %in% yes) & !is.na(x)
    if (any(remaining)) {
      warning("Some values matched neither `yes` nor `no`; leaving them as NA.", call. = FALSE)
    }
  } else {
    out[x %in% no] <- 0
    remaining <- !(x %in% yes) & !(x %in% no) & !is.na(x)
    if (any(remaining)) {
      warning("Some values matched neither `yes` nor `no`; leaving them as NA.", call. = FALSE)
    }
  }
  return(out)
}
