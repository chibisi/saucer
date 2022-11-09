require(data.table)
require(ggplot2)
require(scales)
require(dlstats)

# Competition analysis, C++ and Rust DL numbers on CRAN


dlData = data.table(cran_stats(c("Rcpp", "rextendr", "cpp11")))
maxEnd = dlData[, max(end)]
dlData = dlData[end < maxEnd, ]

p = ggplot(dlData, aes(end, downloads, group = package, color = package)) +
    geom_line() + 
    geom_point() +
    scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
              labels = trans_format("log10", math_format(10^.x))) +
    theme(legend.position="top", legend.title = element_blank()) +
    labs(x = "Date", y = "#Downloads") + 
    scale_x_date(date_breaks = "3 months", date_labels = "%b %y")


svg(filename = "oppoDLNumbers.svg", width = 14, height = 8)
plot(p)
dev.off()



