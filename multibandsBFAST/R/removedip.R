#' @title remove dips
#' @param x
#' @note adapted from Eliakim's code
#' @return time series with dips removed
#' @export
removedips <- function(x) {
    # x <- na.approx(x, rule = 2)
    
    y <- as.numeric(x)
    leng <- length(x) - 2
    for (i in 1:leng) {
        ## moving window - check distance
        b <- i + 2
        c <- b - 1
        if (any(is.na(x[b]), is.na(x[c]), is.na(x[i]))) 
            next
        mida <- x[c] - x[i]
        midc <- x[c] - x[b]
        # Find 20 percent
        threshold1 <- (-1/100) * x[i]
        threshold2 <- (-1/100) * x[b]
        # check threshold
        if (mida < 0 & midc < 0 & mida < threshold1 | midc < threshold2) {
            y[c] <- (x[b] + x[i])/2
        }
    }
    return(y)
}
