#' Recode a messy survey column into clean 0/1
#'
#' Converts alternative survey response values into clean standard numeric 0 or 1 scores.
#'
#' @param x A vector coding a single condition.
#' @param yes The raw value(s) that should become 1.
#' @param no The raw value(s) that should become 0.
#'
#' @return A numeric vector of 0, 1, or NA.
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
