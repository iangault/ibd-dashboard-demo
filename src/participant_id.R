#' Standardize participant IDs to PREFIX_NN (two-digit numeric suffix, underscore).
#'
#' Examples: SYN-7, SYN_7, SYN7, and syn_07 become SYN_07. Values that do not
#' match PREFIX + optional -/_ + digits (e.g. CONTROL) are returned uppercased
#' and trimmed unchanged.
#'
#' @param x Character vector (or coercible to character).
#' @return Character vector of the same length as `x`.
normalize_participant_id <- function(x) {
  if (length(x) == 0L) {
    return(x)
  }
  x_chr <- toupper(trimws(as.character(x)))
  vapply(
    seq_along(x_chr),
    function(i) {
      xi <- x_chr[i]
      if (is.na(x[i]) || is.na(xi)) {
        return(NA_character_)
      }
      if (!nzchar(xi)) {
        return(xi)
      }
      if (!grepl("^[A-Z]+[-_]?[0-9]+$", xi)) {
        return(xi)
      }
      parts <- regmatches(xi, regexec("^([A-Z]+)[_-]?([0-9]+)$", xi))[[1]]
      if (length(parts) < 3L) {
        return(xi)
      }
      num <- parts[3]
      if (nchar(num) == 1L) {
        num <- sprintf("%02d", as.integer(num))
      }
      paste0(parts[2], "_", num)
    },
    FUN.VALUE = character(1L),
    USE.NAMES = FALSE
  )
}
