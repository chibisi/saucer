require(data.table)
require(ggplot2)
require(scales)
require(dlstats)

# Competition analysis, C++ and Rust DL numbers on CRAN

dlData = data.table(cran_stats(c("Rcpp", "rextendr", 
            "cpp11", "JuliaCall", "JuliaConnectoR")))
maxEnd = dlData[, max(end)]
dlData = dlData[(end > as.Date("2018-12-31")) & (end < maxEnd), ]

p = ggplot(dlData, aes(end, downloads, group = package, color = package)) +
    geom_line() + 
    geom_point(size = rel(2)) +
    scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
              labels = trans_format("log10", math_format(10^.x))) +
    labs(x = "\nDate", y = "#Downloads\n") + 
    scale_x_date(date_breaks = "3 months", date_labels = "%m-%y") +
    theme(legend.position="top", legend.title = element_blank(),
        axis.text = element_text(size = rel(1.2)), 
        legend.text = element_text(size = rel(1.3)),
        axis.title = element_text(size = rel(1.3)))

plot(p)

svg(filename = "oppoDLNumbers.svg", width = 12, height = 8)
plot(p)
dev.off()

png(filename = "oppoDLNumbers.png", width = 12, height = 8, 
        units = "in", res = 300)
plot(p)
dev.off()

