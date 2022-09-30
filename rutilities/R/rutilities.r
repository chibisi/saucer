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
    
    pkgUpdateFunc = updatePackage
    remove.packages(packageName)
    pkgUpdateFunc(packageName)
    
    return(invisible())
}


#' @title Function to remove and update a locally available package
#'
#' @description Function to remove and update a locally available package 
#'              using the updatePackage() function
#' 
#' @param package the package name to be passed to remove.packages() 
#'               and updatePackage()
#'
#' @return NULL invisibly
#'
#' @export
#'
removeAndUpdatePackage = function(package = "saucer")
{
    command = paste0("R -e \"require('rutilities'); remove.packages('", package,"'); exit()\"")
    status = system(command, intern = FALSE)
    status = attr(status, "status")
    if(length(status) > 0)
    {
        if(status == 1)
        {
            messageString = paste0("Execution error remove ", package, " package failed")
            stop(messageString)
        }
    }
    command = paste0("R -e \"require('rutilities'); updatePackage('", package, "'); exit()\"")
    status = system(command, intern = TRUE)
    status = attr(status, "status")
    if(length(status) > 0)
    {
        if(status == 1)
        {
            messageString = paste0("Execution error remove ", package, " package failed")
            stop(messageString)
        }
    }
    return(invisible())
}



