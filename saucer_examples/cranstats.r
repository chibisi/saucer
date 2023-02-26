require(data.table)
require(ggplot2)
require(scales)
require(dlstats)

# Competition analysis, C++ and Rust DL numbers on CRAN


getData = function(packages)
{
    dlData = data.table(cran_stats(packages))
    return(dlData)
}


plotStats = function(plotData, minDate = "2018-12-31", doLog = TRUE)
{
    maxEnd = plotData[, max(end)]
    plotData = plotData[(end > as.Date(minDate)) & (end < maxEnd), ]
    
    logScale = scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
                  labels = trans_format("log10", math_format(10^.x)))

    p = ggplot(plotData, aes(end, downloads, group = package, color = package)) +
        geom_line(size = 1.5) + 
        geom_point(size = rel(4)) +
        labs(x = "\nDate", y = "#Downloads\n") + 
        scale_x_date(date_breaks = "3 months", date_labels = "%m-%y") +
        theme(legend.position="top", legend.title = element_blank(),
            axis.text = element_text(size = rel(1.2)), 
            legend.text = element_text(size = rel(1.3)),
            axis.title = element_text(size = rel(1.3))) +
            scale_color_brewer(palette="Paired")
    
    if(doLog)
    {
        p = p + logScale
    }
    return(p)
}

writeChart = function(p, fileName = "chart.png", func = png, 
                        width = 12, height = 8, ...)
{
    func(filename = fileName, width = width, height = height, ...)
    plot(p)
    dev.off()
    return()
}



#===========================================================================#

topPkgs = c("e1071", "kernlab", "xgboost", "gbm",  "rpart", 
            "party", "nnet", "tensorflow", "h2o", "neuralnet")
topData = getData(topPkgs)
topPlot = plot(plotStats(topData, minDate = "2018-01-01", doLog = TRUE))
writeChart(topPlot, fileName = "topCRANMLLibs.png", 
            func = png, width = 14, height = 7, res = 300, units = "in")

#===========================================================================#

svmPkgs = c("gensvm", "gkmSVM", "mildsvm", "penalizedSVM", "ramsvm", 
            "sparseSVM", "SSOSVM", "survivalsvm", "SVMMaj", "svmpath", 
            "SwarmSVM", "WeightSVM")
svmData = getData(svmPkgs)
svmPlot = plot(plotStats(svmData, minDate = "2018-01-01", doLog = TRUE))

# writeChart(svmPlot, fileName = "svmLibsPlot.png", 
#             func = png, width = 14, height = 7, res = 300, units = "in")

#===========================================================================#

knnPkgs = c("bbknnR", "biokNN", "FastKNN", "KernelKnn", "kknn", "knnp",
        "kNNvs", "knnwtsim", "mstknnclust", "OkNNE", "SKNN", "tsfknn")
knnData = getData(knnPkgs)
knnPlot = plot(plotStats(knnData, minDate = "2018-01-01", doLog = TRUE))

#===========================================================================#

nbPkgs = c("fastNaiveBayes", "naivebayes")
nbData = getData(nbPkgs)
nbPlot = plot(plotStats(nbData, minDate = "2018-01-01", doLog = TRUE))

#===========================================================================#
clusterPkgs = c("fastcluster", "fastkmedoids", "fclust", "fdacluster",
                "fdaMocca", "FisherEM", "flexclust", "flexCWM", "genie",
                "GIC", "glmmML", "Gmedian", "gmfd", "hkclustering",
                "ihclust")

clusterPkgs = c("kernlab", "cluster", "fastcluster", "flexclust", "bayesm")
clusterData = getData(clusterPkgs)
clusterPlot = plot(plotStats(clusterData, minDate = "2018-01-01", doLog = TRUE))

#===========================================================================#

# Decomposed packages
ePkgs = c("e1071", "naivebayes", "kknn", "kernlab", "cluster", 
            "glmnet", "arules", "gbm", "nnet", "rpart")
eData = getData(ePkgs)
ePlot = plot(plotStats(eData, minDate = "2018-01-01", doLog = TRUE))

writeChart(ePlot, fileName = "e1071Analysis.png", 
            func = png, width = 14, height = 7, res = 300, units = "in")

#===========================================================================#

nnPkgs = c("nnet", "neuralnet", "tensorflow", "torch", 
            "deepnet", "RcppDL", "RSNNS", "h2o")
treePkgs = c("tree", "rpart", "RWeka", "Cubist", 
        "C50", "pre", "party", "partykit", "glmtree", "semtree",
        "maptree", "RPMM", "randomForest", "ipred")
boostPkgs = c("gbm", "lightgbm", "xgboost", "bst", 
        "mboost", "GMMBoost", "gamboostLSS")


boostData = getData(boostPkgs)
plot(plotStats(boostData, minDate = "2018-12-31"))


treeData = getData(c("gbm", "xgboost", "randomForest", "rpart", 
                "party", "partykit"))
plot(plotStats(treeData, minDate = "2018-01-01", doLog = TRUE))

otherPkgs = c("e1071", "kernlab", "klaR")
otherData = getData(otherPkgs)
plot(plotStats(otherData, minDate = "2018-01-01", doLog = TRUE))



nnData = getData(nnPkgs)
plot(plotStats(nnData, minDate = "2018-01-01", doLog = TRUE))

#===========================================================================#

langPkgs = c("Rcpp", "rextendr", "cpp11", "JuliaCall", "JuliaConnectoR")
langData = getData(langPkgs)
langPlot = plotStats(langData, minDate = "2018-01-01", doLog = TRUE)
writeChart(langPlot, fileName = "langPackage.png", func = png, 
        width = 16, height = 8, units = "in", res = 400)

