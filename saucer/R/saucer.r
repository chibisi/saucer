# Internal workshorse function for compiling and loading a D module
.saucerize = function(module, dropFolder = NULL, folderName = NULL)
{
  currWd = getwd()
  sourceDir = system.file("sauced", package = "saucer")
  
  # drop if folder is random generated
  if(is.null(folderName))
  {
    folderName = paste0(sample(letters, 10), collapse = "")
    if(is.null(dropFolder))
    {
      dropFolder = TRUE
    }
  }else{
    if(is.null(dropFolder))
    {
      dropFolder = FALSE
    }
  }
  
  # Set Code Folder
  dir.create(folderName)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  setwd(codeFolder)
  
  # Copy files
  importsFolder = file.path(codeFolder, "imports")
  dir.create(importsFolder)
  file.copy(file.path(sourceDir, "r2d.d"), codeFolder)
  file.copy(file.path(sourceDir, "saucer.d"), codeFolder)
  file.copy(file.path(sourceDir, "imports", "isin.d"), file.path(importsFolder, "isin.d"))
  file.copy(file.path(sourceDir, "imports", "rvector.d"), file.path(importsFolder, "rvector.d"))
  file.copy(file.path(sourceDir, "imports", "rmatrix.d"), file.path(importsFolder, "rmatrix.d"))
  file.copy(file.path(sourceDir, "imports", "dataframe.d"), file.path(importsFolder, "dataframe.d"))
  file.copy(file.path(sourceDir, "imports", "commonfunctions.d"), file.path(importsFolder, "commonfunctions.d"))
  file.copy(file.path(sourceDir, "imports", "r_aliases.d"), file.path(importsFolder, "r_aliases.d"))
  file.copy(file.path(sourceDir, "translator.d"), codeFolder)
  file.copy(file.path(currWd, paste0(module, ".d")), codeFolder)
  
  # Run the d compilation script
  command = "echo 'enum moduleName = \"${module}\";' | dmd translator.d ${currWd}/${module}.d saucer.d r2d.d -O -boundscheck=off -mcpu=native -g -J=\".\" -L-lR -L-lRmath && ./translator" #-L-lR -L-lRmath
  command = stringr::str_interp(command, list("currWd" = currWd, "module" = module))
  
  commandFailed = FALSE
  command_output = system(command, intern = TRUE)
  
  status = attr(command_output, "status")
  if(length(status) == 0)
  {
    status = 0
  }
  if(status != 0)
  {
    cat("Compilation command had a status of ", status, "\n", sep = "")
    cat("Exiting as a result of error, and resetting working directory ...\n")
    setwd(currWd)
    return(stop("Compilation command failed to execute! Propagating error and exiting"))
  }
  
  # cat("Command output: \n", command_output, sep = "")
  
  # Load the translated functions in a generated R script
  source(paste0(module, ".r"))
  
  # Set folder back to the initial folder
  setwd(currWd)
  
  # Delete these two lines
  # Move translator file (belated, should be compiled in the new folder!)
  # system(stringr::str_interp("mv translator.d translator.o translator ${folderName}/", list("folderName" = folderName)))
  
  # Drop folder if indicated
  if(dropFolder)
  {
    unlink(codeFolder, recursive = T)
    cat("Temporary code folder ", codeFolder, " deleted.\n", sep = "")
  }
  
  cat(module, " compiled and loaded.\n", sep = "")
  
  return(invisible())
}





#' @title Function compiles and loads D modules into R session
#'
#' @param modules character vector containing the module names to 
#'        be compiled and loaded into the R session. Excludes the
#'        ".d" extension (for now)
#'        TODO: this functionality requires more work        
#' @param folderName  a character containing the name of the
#'        folder where the code will be created. If missing
#'         a random name is generated
#' @param dropFolder whether to delete the folder containing
#'        the compilation artifacts once the compilation is done.
#' 
#' @return NULL
#' 
#' @export
#' 
#' @examples
#' 
#' # require(saucer)
#' # saucerize("script", dropFolder = TRUE)
#' # 
#' # x = seq(1.0, 10.0, by = 0.5); y = seq(1.0, 10.0, by = 0.5)
#' # generate_numbers(as.integer(100))
#' # dot(x, y)
#' # vdmul(x, y)
#' # ans1 = outer_prod_serial(x, y)
#' # ans2 = outer_prod_parallel(x, y) # parallel version
#' # sum(abs(ans1 - ans2)) == 0
#' # sexp_check()
#' 
#' @export
#' 
saucerize = function(modules, ...)
{
  for(i in 1:length(modules))
  {
    tryCatch(
      .saucerize(modules[i], ...), 
      error = function(e)
      {
        cat("Failed to compile and load module:", modules[i], "\n")
        print(e)
      }
    )
  }
  return(invisible())
}


#' @title Creates a random file name
#' 
#' @param prefix the file prefix
#' @param extn the file extension with or without a leading full stop
#' @param nrand the number of random characters to generate as an 
#'        append to the file name
#' @return A random file name
createFileName = function(prefix = "script", extn = NULL, nrand = 12)
{
  postfix = paste0(sample(c(0:9, letters), nrand), collapse = "")
  .file = paste0(c(prefix, postfix), collapse = "_")
  if(!is.null(extn))
  {
    len = length(extn)
    if(substr(extn, 1, 1) == ".")
    {
      .file = paste0(.file, extn)
    }else{
      .file = paste0(.file, ".", extn)
    }
  }
  return(.file)
}


.dfunction = function(code, dropFolder)
{
  moduleName = createFileName()
  prefix = paste0("module ", moduleName,";\nimport sauced.saucer;\n\n")
  code = paste0(prefix, code)
  codeFile = paste0(moduleName, ".d")
  cat(code, file = codeFile)
  executionError = FALSE
  tryCatch(.saucerize(moduleName, dropFolder = dropFolder), error = function(e){
    cat("Error on .saucerize:\n")
    paste(e)
    executionError <<- TRUE
  })
  if(executionError)
  {
    # cat("Printing the requested compilation:\n###################################\n", code, 
    #         "###################################\n")
    if(file.exists(codeFile))
    {
      cat("Deleting the temp script ", codeFile, "\n", sep = "")
      file.remove(codeFile)
      cat("Temp script ", codeFile, " removed, folder will still remain\n", sep = "")
    }
    return(invisible(code))
  }
  # Clean up
  cat("Deleting temp file: ", codeFile, "\n")
  unlink(codeFile)
  return(invisible(code))
}


#' @title Compile D code from string
#' @description Compiles and loads D code from string array, note that the desired 
#'              export functions must still be marked with `@exportd()`
#' 
#' @param code character containing the code to be compiled
#' 
#' @return character array of code submitted into the code array
#' 
#' @examples
#'         dfunctions("
#'         import std.stdio: writeln;
#'         @exportd() int squared(int x)
#'         {
#'           x = x*x;
#'           writeln(\"x squared: \", x);
#'           return x;
#'         }
#'         @exportd() double cubed(double x)
#'         {
#'           x = x*x*x;
#'           writeln(\"x cubed: \", x);
#'           return x;
#'         }
#'         ")
#' 
#'         squared(as.integer(5))
#'         cubed(5)
#' 
#' @export
#' 
dfunctions = function(codeArr, dropFolder = TRUE)
{
  result = .dfunction(paste0(codeArr, collapse = "\n"), dropFolder)
  return(invisible(result))
}



#' @title unix-style function to copy a directory from
#' 
#' @param from the path to the directory to be copied
#' @param to the path that the direectory should be copied to
#' @param flags character vector of the flags passed to the 
#'        cp linux function. Defaults to "-r".
#' 
#' @return invisibly returns the command that was run
#'
#' @export
#' 
dir.copy = function(from, to, flags = "-r")
{
  stopifnot((length(from) == length(to)) & (length(to) == 1))
  stopifnot(dir.exists(from))
  stopifnot()

  flags = paste0(flags, collapse = " ")
  command = paste0(c("cp", from, flags, to), collapse = " ")
  system(command)
  stopifnot(file.exists(to))
  
  return(invisible(command))
}



#' @title Delete a directory
#' 
#' @param directory character single directory to be removed
#' @param flags character vector of flags to be passed to the "rm"
#'        unix function.
#' 
#' 
#' @export
#'
dir.remove = function(directory, flags = "-rf")
{
  stopifnot(dir.exists(directory))
  stopifnot(length(directory) == 1)

  flags = paste0(flags, collapse = " ")
  command = paste0(c("rm", flags, directory), collapse = " ")
  system(command)
  return(invisible(command))
}



#' @title Compile RInside D code
#' 
#' @description Simple function to compile a D script that calls the R API
#' 
#' @param fileNames single string item for path to file to be
#' @param extraFiles single character string containing the extra files 
#'                   to be included in the compilation
#' 
#' @export
#' 
compileRInside = function(fileName, flags = c("-O", "-fPIC", "-L-lR", "-L-lRmath", 
                                              "-mcpu=native"), cleanup = TRUE)
{
  sourceDir = system.file("sauced", package = "saucer")
  destDir = createFileName(prefix = "tmpFolder", NULL, 6)

  # Copy sauced to temp directory
  dir.copy(sourceDir, destDir)
  
  flags = paste0(flags, collapse = " ")
  files = paste0(paste0(destDir, .Platform$file.sep), 
              c("saucer.d", "r2d.d", "rinside/rembedded.d", 
                "rinside/rinterface.d", "rinside/rstartup.d"))
  files = c(fileName, files)
  jFlag = paste0("-J=", "\"", destDir, "\"")

  command = paste0(c("dmd", files, flags, jFlag), collapse = " ")
  system(command)

  if(cleanup)
  {
    dir.remove(destDir)
  }

  return(invisible(command))
}

