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
#'        # updatePackage("saucer")
#' 
#' @export
#' 
updatePackage = function(package_name, path = ".")
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


#' Function to remove a package and recompile and reinstall it
#' 
#' @export
#' 
removeAndUpdate = function(packageName, path = ".")
{
    curr_wd = getwd()
    on.exit(setwd(curr_wd))
    setwd(path)
    
    remove.packages(packageName)
    updatePackage(packageName)
    
    return(invisible())
}


#' @title checks whether two numbers are qpproximately the same to some absolute error
#' 
#' @param x a number
#' @param y a number
#' @param absError the absolute error defaults to 1E-8
#' 
#' @return whether the two numbers are approximately equal
#' 
#' @export
#' 
approxEqual = function(x, y, absError = 1E-8)
{
  return(abs(x - y) < absError)
}


#' @title assert assertion function to enforce conditions
#' 
#' @param expr the expression to be evaluated
#' @param message character to be displaced in the event of an error
#'
#' return NULL (invisibly)
#'
#' @export
#'
assert = function(expr, message = "There was an error!", envir = NULL)
{
  expr = substitute(expr)
  if(is.null(envir))
  {
    envir = parent.frame()
  }
  evaled = eval(expr, envir = envir)
  boolValue = (class(evaled) != "logical") | 
                  (class(evaled) != "integer") | 
                    (class(evaled) != "numeric")
  if(!boolValue)
  {
    stop("Expression expr does not evaluate to logical");
  }
  if(!evaled)
  {
    stop(message)
  }
  return(invisible(NULL))
}


