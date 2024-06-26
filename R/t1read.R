#' Read and augment data with extended metadata attributes
#'
#' @param data Either a file name (\code{character}) or a \code{data.frame}. If
#' a file name it will be read using the function \code{read.fun}.
#' @param metadata Either a file name (\code{character}) or a \code{list}. If a
#' file name it will be read using the function \code{\link[yaml]{read_yaml}}
#' (so it should be a file the contains valid YAML text), and a \code{list} results.
#' See Details regarding the \code{list} contents.
#' @param read.fun A function to read files. It should accept a file name as
#' its first argument and return a \code{data.frame}.
#' @param ... Further optional arguments, passed to \code{read.fun}.
#' @param escape.html Logical. Should strings (labels, units) be converted to
#' valid HTML by escaping special symbols?
#' @details The \code{metadata} list may contain the following 3 named elements
#' (other elements are ignored):
#' \itemize{
#'   \item \code{labels}: a named list, with names corresponding to columns in \code{data}
#'   and values the associated label attribute.
#'   \item \code{units}: a named list, with names corresponding to columns in \code{data}
#'   and values the associated units attribute.
#'   \item \code{categoricals}: a named list, with names corresponding to columns in
#'   \code{data} and values are themselves lists, used to convert the column to
#'   a \code{factor}: the list names are the levels, and the values are the
#'   associated labels. The names can also be omitted if the goal is just to
#'   specify the order of the factor levels.
#' }
#' @return A \code{data.frame} (as returned by \code{read.fun}).
#' @examples
#'
#' # Simulate some data
#' set.seed(123)
#' data <- expand.grid(sex=0:1, cohort=1:3)[rep(1:6, times=c(7, 9, 21, 22, 11, 14)),]
#' data$age <- runif(nrow(data), 18, 80)
#' data$agecat <- 1*(data$age >= 65)
#' data$wgt <- rnorm(nrow(data), 75, 15)
#'
#' metadata <- list(
#'   labels=list(
#'     cohort = "Cohort",
#'     sex = "Sex",
#'     age = "Age",
#'     agecat  = "Age category",
#'     wgt = "Weight"),
#'   units=list(
#'     age = "years",
#'     wgt = "kg"),
#'   categoricals=list(
#'     cohort = list(
#'       `1` = "Cohort A",
#'       `2` = "Cohort B",
#'       `3` = "Cohort C"),
#'     sex = list(
#'       `0` = "Female",
#'       `1` = "Male"),
#'     agecat = list(
#'       `0` = "< 65",
#'       `1` = "\U{2265} 65")))
#'
#'  data <- t1read(data, metadata)
#'  table1butbetter(~ sex + age + agecat + wgt | cohort, data=data)
#'
#' @keywords utilities
#' @export
#' @importFrom utils read.csv
t1read <- function(data, metadata=NULL, read.fun=read.csv, ..., escape.html=TRUE) {
    if (is.character(data)) {
        args <- c(list(data), list(...))
        data <- do.call(read.fun, args)
    }
    if (!inherits(data, "data.frame")) {
        stop("Unexpected data; should be a type of data.frame")
    }
    if (escape.html) {
        esc <- htmltools::htmlEscape
    } else {
        esc <- function(x) x
    }
    if (!is.null(metadata)) {
        if (is.character(metadata)) {
            metadata <- yaml::read_yaml(metadata)
        }
        i <- names(data) %in% names(metadata$categoricals)
        for (v in names(data)[i]) {
            lab <- unlist(metadata$categoricals[[v]])
            lev <- names(lab)
            if (is.null(lev)) {
                lev <- lab
            }
            lev[lev == ""] <- lab[lev == ""]
            data[[v]] <- factor(data[[v]], levels=lev, labels=esc(lab))
        }
        # Apply labels
        i <- names(data) %in% names(metadata$labels)
        for (v in names(data)[i]) {
            attr(data[[v]], "label") <- esc(metadata$labels[[v]])
        }
        # Apply units
        i <- names(data) %in% names(metadata$units)
        for (v in names(data)[i]) {
            attr(data[[v]], "units") <- esc(metadata$units[[v]])
        }
    }
    return(data)
}
