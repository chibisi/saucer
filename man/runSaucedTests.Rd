% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/saucer.r
\name{runSaucedTests}
\alias{runSaucedTests}
\title{Runs the internal D tests for saucer.d script}
\usage{
runSaucedTests(dropFolder = TRUE, folderNamePrefix = "dSaucerTest")
}
\arguments{
\item{dropFolder}{whether the generated code folder should be dropped or not}

\item{folderNamePrefix}{the prefix name for the folder defaults to "dSaucerTest"}

\item{compiler}{character either "ldmd2" (default - ldc compiler) 
or "dmd" (DMD compiler) if installed}
}
\value{
NULL (invisibly)
}
\description{
Runs the internal D tests for saucer.d script
}
