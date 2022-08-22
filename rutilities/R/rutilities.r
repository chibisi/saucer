#' @title Function to quit R - to make it the same as Julia/Python
#' 
#' @param save character "yes" or "no" passed to q() defaults to "no"
#' 
#' @export
#' 
exit = function(save = "no")q(save)

#' @title Function compiles and installs/updates
#'        an R package on the system
#' 
#' @param package_name character for the name of the package - folder name
#' @param path character the path where the folder is located
#' 
#' @examples
#'        # update_package("saucer")
#' 
#' @export
#' 
update_package = function(package_name, path = ".")
{
  curr_wd = getwd()
  on.exit(setwd(curr_wd))
  setwd(path)
  cmds = paste0("Rscript -e \"roxygen2::roxygenize('", package_name,"')
  system('R CMD build ", package_name,"')
  pkg_build = list.files(pattern = '", package_name,"_[0-9.]+.tar.gz')
  paste0('R CMD INSTALL ', pkg_build, collapse = '') |> system()
  unlink(pkg_build)\"")
  system(cmds)
  return(invisible())
}



#' @title Binary function %+% for concetenating characters
#' @name %+%
#' 
#' @param x character on the lhs
#' @param y character on the rhs
#' @docType methods
#' 
#' @examples
#'          "Hello " %+% "World!"
#' 
#' 
setGeneric("%+%", valueClass = "character", function(x, y)standardGeneric("%+%"))

#' @name %+%
#' @aliases %+%,character,character-method
#' 
#' 
setMethod("%+%", signature("character", "character"), function(x, y)paste0(x, y, collapse = ""))

