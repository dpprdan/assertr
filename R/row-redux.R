
##
##  provides different row reduction functions
##

#' Computes mahalanobis distance for each row of data frame
#'
#' This function will return a vector, with the same length as the number
#' of rows of the provided data frame, corresponding to the average
#' mahalanobis distances of each row from the whole data set.
#'
#' This is useful for finding anomalous observations, row-wise.
#'
#' It will convert any categorical variables in the data frame into numerics
#' as long as they are factors. For example, in order for a character
#' column to be used as a component in the distance calculations, it must
#' either be a factor, or converted to a factor by using the
#' \code{stringsAsFactors} parameter.
#'
#' @param data A data frame
#' @param keep.NA Ensure that every row with missing data remains NA in
#'                 the output? TRUE by default.
#' @param robust Attempt to compute mahalanobis distance based on
#'         robust covariance matrix? FALSE by default
#' @param stringsAsFactors Convert non-factor string columns into factors?
#'                         FALSE by default
#'
#' @return A vector of observation-wise mahalanobis distances.
#' @seealso \code{\link{insist_rows}}
#' @examples
#'
#' maha_dist(mtcars)
#'
#' maha_dist(iris, robust=TRUE)
#'
#'
#' library(magrittr)            # for piping operator
#' library(dplyr)               # for "everything()" function
#'
#' # using every column from mtcars, compute mahalanobis distance
#' # for each observation, and ensure that each distance is within 10
#' # median absolute deviations from the median
#' mtcars %>%
#'   insist_rows(maha_dist, within_n_mads(10), everything())
#'   ## anything here will run
#'
#' @export
maha_dist <- function(data, keep.NA=TRUE, robust=FALSE, stringsAsFactors=FALSE){
  # this implementation is heavily inspired by the implementation
  # in the "psych" package written by William Revelle
  if(!(any(class(data) %in% c("matrix", "data.frame"))))
    stop("\"data\" must be a data.frame (or matrix)", call.=FALSE)
  ## check
  if(stringsAsFactors){
    char_cols <- vapply(data, is.character, logical(1))
    data[char_cols] <- lapply(data[char_cols], as.factor)
  }
  a.matrix <- data.matrix(data)
  if(ncol(a.matrix)<2)
    stop("\"data\" needs to have at least two columns", call.=FALSE)
  row.names(a.matrix) <- NULL
  a.matrix <- scale(a.matrix, scale=FALSE)
  if(robust){
    if(anyNA(a.matrix))
      stop("cannot use robust maha_dist with missing values", call.=FALSE)
    dcov <- MASS::cov.mcd(a.matrix)$cov
  } else{
    dcov <- stats::cov(a.matrix, use="pairwise")
  }
  inv <- MASS::ginv(dcov)
  dists <- t(apply(a.matrix, 1,
                   function(a.row) colSums(a.row * inv, na.rm=TRUE)))
  dists <- rowSums(dists * a.matrix, na.rm=TRUE)
  if(keep.NA)
    dists[ apply(data, 1, function(x) any(is.na(x))) ] <- NA
  return(dists)
}
attr(maha_dist, "call") <- "maha_dist"


#' Counts number of NAs in each row
#'
#' This function will return a vector, with the same length as the number
#' of rows of the provided data frame, corresponding to the number of missing
#' values in each row
#'
#' @param data A data frame
#' @param allow.NaN Treat NaN like NA (by counting it). FALSE by default
#' @return A vector of number of missing values in each row
#' @seealso \code{\link{is.na}} \code{\link{is.nan}} \code{\link{not_na}}
#' @examples
#'
#' num_row_NAs(mtcars)
#'
#'
#' library(magrittr)            # for piping operator
#' library(dplyr)               # for "everything()" function
#'
#' # using every column from mtcars, make sure there are at most
#' # 2 NAs in each row. If there are any more than two, error out
#' mtcars %>%
#'   assert_rows(num_row_NAs, within_bounds(0,2), everything())
#'   ## anything here will run
#'
#' @export
num_row_NAs <- function(data, allow.NaN=FALSE){
  if(!(any(class(data) %in% c("matrix", "data.frame"))))
    stop("\"data\" must be a data.frame (or matrix)", call.=FALSE)
  pred <- if(allow.NaN){
            function(x){ sum((is.na(x) | is.nan(x))) }
          } else {
            function(x){ sum((is.na(x)&(!(is.nan(x))))) }
          }
  ret.vec <- apply(data, 1, pred)
  return(ret.vec)
}
attr(num_row_NAs, "call") <- "num_row_NAs"



#' Concatenate all columns of each row in data frame into a string
#'
#' This function will return a vector, with the same length as the number
#' of rows of the provided data frame. Each element of the vector will be
#' it's corresponding row with all of its values (one for each column)
#' "pasted" together in a string.
#'
#' @param data A data frame
#' @param sep A string to separate the columns with (default: "")
#' @return A vector of rows concatenated into strings
#' @seealso \code{\link{paste}}
#' @examples
#'
#' col_concat(mtcars)
#'
#' library(magrittr)            # for piping operator
#'
#' # you can use "assert_rows", "is_uniq", and this function to
#' # check if joint duplicates (across different columns) appear
#' # in a data frame
#' \dontrun{
#' mtcars %>%
#'   assert_rows(col_concat, is_uniq, mpg, hp)
#'   # fails because the first two rows are jointly duplicates
#'   # on these two columns
#' }
#'
#' mtcars %>%
#'   assert_rows(col_concat, is_uniq, mpg, hp, wt) # ok
#'
#' @export
col_concat <- function(data, sep=""){
  if(!(any(class(data) %in% c("matrix", "data.frame"))))
    stop("\"data\" must be a data.frame (or matrix)", call.=FALSE)

  apply(data, 1, paste0, collapse=sep)
}
attr(col_concat, "call") <- "col_concat"
