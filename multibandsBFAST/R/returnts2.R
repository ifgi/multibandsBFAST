#' @title return time series ndmi,ndvi, PCts1, PCts2, PCts3, PCtsauto, PChists1, PChists2, PChists3,PChistsauto, TB, TG, TW. Return also the PCgreeness and selected PC orders, In addition, the removed index is book-keeped
#' @param inputarr 3d matrix, [spectral bands, spatial points, time series]
#' @param timearr the time of the array
#' @param tctl1 from which id the Landsat7 is used.
#' @param monitoryear the year to start monitoring. By default 2005
#' @param loca the spatial id for the time series to be returned
#' @return time stamp to be removed, vegetation index ndmi, ndvi
#' @return PC scores from two PCA methods: Historical PC 1-3, auto PC score, PC score 1-3, auto PCscore, time series unscaled.   
#' @return TB, TG, TW
#' @import bfast
#' @import plyr
#' @import reshape2
#' @export 

returnts2 <- function(inputarr, timearr, tctl1, monitoryear = 2005, loca, 
    preprocess = T) {
    if (preprocess) {
        a7bandsrm <- aaply(inputarr, c(1, 2), rmsat)  #remove extreme value outside valid  range (1-10000)
        a7bandsrm2 <- aaply(a7bandsrm, c(1, 2), removedips)  # remove low value
    } else {
        a7bandsrm2 = inputarr
    }
    arr <- na.omit(t(a7bandsrm2[, loca, ]))
    arrbandsrm <- t(a7bandsrm2[, loca, ])
    ndmi <- (arr[, 4] - arr[, 5])/(arr[, 4] + arr[, 5])
    ndvi <- (arr[, 4] - arr[, 3])/(arr[, 4] + arr[, 3])  # try ndvi 
    # historical pca
    PCAhis <- arrbandsrm[(round(decimal_date(timearr), digits = 6) < monitoryear), 
        ]  # using historical period to compute pc loading
    fit <- prcomp(na.omit(PCAhis), scale. = T)
    PChweight1 <- fit$rotation[, 1]
    
    # PChweight2 <- fit$rotation[,2]
    PChweight3 <- fit$rotation[, 3]
    PChists1 <- drop(arr %*% PChweight1)
    # PChists2 <- drop ( arr %*% PChweight2 )
    PChists3 <- drop(arr %*% PChweight3)
    pcacompauto <- which.max(abs(apply(fit$rotation[1:3, ] - fit$rotation[4:6, 
        ], 2, sum)))
    pcacompauto2 <- which.max(abs(fit$rotation[4, 2:3] - fit$rotation[6, 
        2:3])) + 1
    # to further avoid mistakenly selected pc, but not described in the
    # paper.
    if (pcacompauto == pcacompauto2) 
        pcacompauto = ifelse(pcacompauto2 == 3, 2, 3)
    
    PChweightauto <- fit$rotation[, pcacompauto]
    PC2hweightauto <- fit$rotation[, pcacompauto2]
    
    PChistsauto <- drop(arr %*% PChweightauto)
    PChists2 <- drop(arr %*% PC2hweightauto)
    # pca score
    fit2 <- prcomp(arr, scale. = T)
    
    PCweight1 <- fit2$rotation[, 1]
    PCweight2 <- fit2$rotation[, 2]
    PCweight3 <- fit2$rotation[, 3]
    
    PCts1 <- drop(arr %*% PCweight1)
    PCts2 <- drop(arr %*% PCweight2)
    PCts3 <- drop(arr %*% PCweight3)
    # pcscore with realtime score
    arr1 <- arr
    bt <- pca_bfm(arr = arr1, hisweight = F, pcacomp, myear = 2005, history = c("all"), 
        my_dates = timearr, scoreselect = T, lastordetect = "last", minumum_observations = 15, 
        sca = F, type = "OLS-MOSUM", moy = 1)
    if (!is.na(bt)) 
        PCAscorearr <- arrbandsrm[(round(decimal_date(timearr), digits = 6) < 
            bt), ]  # using historical period to compute pc loading
 else PCAscorearr = arrbandsrm
    
    fit3 <- prcomp(na.omit(PCAscorearr), scale. = T)
    re2 <- arrbandsrm[(round(decimal_date(timearr), digits = 6) >= bt), 
        ]
    PCweightauto <- fit3$rotation[, pcacompauto]
    
    PCtsauto <- drop(na.omit(PCAscorearr) %*% PCweightauto)
    re <- attributes(arr)$na.action
    str(t(arrbandsrm))
    tct1 <- tctts(t(arrbandsrm), tctl1)
    TB <- na.omit(tct1[[1]])
    TG <- na.omit(tct1[[2]])
    TW <- na.omit(tct1[[3]])
    res <- list(removedindexhis = re, NDMI = ndmi, NDVI = ndvi, 
        PC1 = PCts1, PC2 = PCts2, PC3 = PCts3, PCauto = PCtsauto, hisPC1 = PChists1, 
        hisPCgreeness = PChists2, hisPC3 = PChists3, hisPCauto = PChistsauto, 
        TB = TB, TG = TG, TW = TW, PCautoorder = pcacompauto, PCgreennessorder = pcacompauto2, 
        bfasttime = bt, removedindexpcscore = re2)
    return(res)
}
