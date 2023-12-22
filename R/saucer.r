pkgOpts = new.env()


#' @title Function sets option for logging
#' 
#' @param flag for whether functions should be verbose 
#'         and print progress information
#' @return the input flag invisibly
#'
#' 
doLogging = function(flag = FALSE)
{
  pkgOpts$logging = flag
  msg = paste("Logging is now set to", flag, "\n")
  cat(msg)
  return(invisible(flag))
}


setLogFile = function(fileName = NULL)
{
  if(is.null(fileName))
  {
    pkgOpts$fileName = "saucer.log"
  }else{
    pkgOpts$fileName = fileName
  }
  return(invisible(fileName))
}

isLogActive = function()
{
  if(is.null(pkgOpts$logging) || (pkgOpts$logging == FALSE))
  {
    return(FALSE)
  }
  return(TRUE)
}

logger = function(...)
{
  if(isLogActive())
  {
    cat(..., "\n", file = pkgOpts$fileName, append = TRUE)
  }
  return(invisible(NULL))
}

doLogging(TRUE)
setLogFile()


#' @title Function to return pointer of an exported item from 
#'         loaded DLL table
#' 
#' @param symbolName character for the name of the native 
#'          symbol to be retrieved
#' @param packageName character the name of the package
#'          can be left as NULL
#' 
#' @return An object of class externalptr
#' 
#' @seealso getNativeSymbolInfo, getLoadedDLLs, dyn.load, 
#'              getDLLRegisteredRoutines
#' 
#' @export
#' 
getExternalPtr = function(symbolName, packageName = NULL)
{
  symbolInfo = getNativeSymbolInfo(symbolName, packageName)
  ptr = symbolInfo$address
  attr(ptr, "class") = NULL
  return(ptr)
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

#' @title Function to run a system command (usually compilation) 
#' 
#' @param command the command string to run
#' @param runDirectory the directory that the command should be run
#' @param failDirectory the directory that should be switched to if the command fails
#' @param successDirectory the directory that should be switched to in the event of a success
#' 
#' @return invisibly returns NULL
#' 
#' 
runCommand = function(command, runDirectory, failDirectory, successDirectory)
{
  setwd(runDirectory)
  status = system(command, intern = FALSE)

  if(status != 0)
  {
    cat("Compilation command had a status of ", status, "\n", sep = "")
    cat("Exiting as a result of error, and resetting failDirectory ...\n")
    setwd(failDirectory)
    stop("Compilation command failed to execute! Propagating error and exiting")
  }else{
    setwd(successDirectory)
  }
  return(invisible())
}



compileTranslator = function(command, currWd, module)
{
  command = stringr::str_interp(command, list("currWd" = currWd, "module" = module))
  status = system(command, intern = FALSE)

  if(status != 0)
  {
    cat("Compilation command had a status of ", status, "\n", sep = "")
    cat("Exiting as a result of error, and resetting working directory ...\n")
    setwd(currWd)
    stop("Compilation command failed to execute! Propagating error and exiting")
  }
  return(invisible())
}


compileScript = function(moduleNames, currWd, compiler = "ldmd2", flags = c("-O", "-boundscheck=off", 
                            "-mcpu=native"))
{
  dllFile = paste0(moduleNames[1], ".so")
  sllFiles = paste0(moduleNames, ".o", collapse = " ")
  scriptFiles = paste0(moduleNames, ".d", collapse = " ")
  addedFlags = paste(flags, collapse = " ")
  command = paste0(compiler, " ", scriptFiles, 
                    " saucer.d r2d.d -c -g -J=\".\" ", addedFlags, " -fPIC -L-lR -L-lRmath && ",
                    compiler, " ", sllFiles, " saucer.o r2d.o -of=", dllFile, " ", addedFlags,
                    " -fPIC -L-lR -L-lRmath -shared")
  logger(paste0("Compiling script(s): \n", command))
  status = system(command, intern = FALSE)

  if(status != 0)
  {
    cat("Compilation command had a status of ", status, "\n", sep = "")
    cat("Exiting as a result of error, and resetting working directory ...\n")
    setwd(currWd)
    stop("Compilation command failed to execute! Propagating error and exiting")
  }
  return(invisible())
}


#' @title Workhorse function for compiling the D code and creating the R wrapper
#'
#' @description The first file given is the main file containing functions
#'        to be exported, other files given are supporting files
#' 
#' @param fileNames character vector containing the module (file) names to 
#'        be compiled and loaded into the R session. The file name must 
#'        include the ".d" extension.    
#' @param code character vector containing the code to be compiled
#' @param dropFolder logical for whether the folder containing the code
#'        and compilation artifacts should be dropped after compilation is 
#'        done. Defaults to TRUE.
#' @param folderName character for what the folder name the generated code
#'        should be. Defaults to NULL - random name generated.
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler)
#' @param flags character vector flags to be passed to the chosen D compiler
#' 
#' @return NULL
.sauce = function(fileNames, dropFolder = NULL, folderName = NULL, 
                  compiler = "ldmd2", flags = c("-O", "-boundscheck=off", "-mcpu=native"))
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
  # dir.create(folderName)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  
  # Copy files
  dir.copy(sourceDir, codeFolder)
  for(fileName in fileNames)
  {
    file.copy(file.path(currWd, fileName), codeFolder)
  }
  setwd(codeFolder)

  moduleNames = extractModuleNames(fileNames, extn = "d")
  
  command = paste0("echo 'enum moduleName = \"", moduleNames[1], "\";'")
  command = paste0(command, " | ", compiler, " translator.d ")
  concatNames = paste0(currWd, .Platform$file.sep, fileNames, collapse = " ")
  command = paste0(command, concatNames)
  command = paste0(command, " saucer.d r2d.d -J=\".\" ")
  command = paste(command, "&& ./translator")
  
  # Run the d compilation script
  logger("Translator compilation command to generate script to be compiled: \n", command)
  compileTranslator(command, currWd, module)
  logger("Translator compiled, now compiling script")
  compileScript(moduleNames, currWd, compiler, flags)
  logger("Script compiled!")
  
  # Load the translated functions in a generated R script
  source(paste0(moduleNames[1], ".r"))
  
  # Set folder back to the initial folder
  setwd(currWd)
  
  # Delete these two lines
  # Move translator file (belated, should be compiled in the new folder!)
  # system(stringr::str_interp("mv translator.d translator.o translator ${folderName}/", list("folderName" = folderName)))
  
  # Drop folder if indicated
  if(dropFolder)
  {
    unlink(codeFolder, recursive = TRUE)
    cat("Temporary code folder ", codeFolder, " deleted.\n", sep = "")
  }
  
  cat(moduleNames[1], " compiled and loaded.\n", sep = "")
  
  return(invisible())
}





#' @title Function checks file names fileNames for whether 
#'        they contain the file extension extn
#' 
#' @param fileNames character vector containing the file names
#' @param extn the extension to check for (with or without 
#'             the begining full stop)
#
#' @return logical vector for whether the files given by
#'         fileNames have the given extension
#' 
#' 
hasExtension = function(fileNames, extn = "d")
{
  if(grepl("^[.]", extn))
  {
    extn = substring(extn, 2, nchar(extn))
  }
  return(grepl(paste0("[.]", extn, "$"), fileNames))
}


#' @title Extract name of file from extension
#' 
#' @param fileNames character vector containing the file names
#' @param extn the extension to check for (with or without 
#'            the starting full stop)
#'
#' @return character vector with item extracted
#' 
#' 
extractModuleNames = function(fileNames, extn = "d")
{
  if(grepl("^[.]", extn))
  {
    extn = substring(extn, 2, nchar(extn))
  }
  if(!all(hasExtension(fileNames, extn)))
  {
    cat("Files: ", paste(fileNames, collapse = " "), "\n")
    stop("Some files contain the wrong extension!")
  }
  len = nchar(extn)
  n = length(fileNames)
  for(i in 1:n)
  {
    tmp = fileNames[i]
    fileNames[i] = substr(fileNames[i], 1, nchar(tmp) - (len + 1))
  }
  return(fileNames)
}



#' @title Function compiles and loads D modules into R session
#'
#' @description The first file given is the main file containing functions
#'        to be exported, other files given are supporting files
#' 
#' @param fileNames character vector containing the module (file) names to 
#'        be compiled and loaded into the R session. The file name must 
#'        include the ".d" extension.    
#' @param code character vector containing the code to be compiled
#' @param dropFolder logical for whether the folder containing the code
#'        and compilation artifacts should be dropped after compilation is 
#'        done. Defaults to TRUE.
#' @param folderName character for what the folder name the generated code
#'        should be. Defaults to NULL - random name generated.
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler)
#' @param flags character vector flags to be passed to the chosen D compiler
#' 
#' @return NULL
#' 
#' @export
#' 
sauce = function(fileNames, ...)
{
  currDir = getwd()
  sourceFilesPresent = all(file.exists(fileNames))
  if(!(sourceFilesPresent && all(hasExtension(fileNames, "d"))))
  {
    stop(paste0("All the sources files for the modules listed are not present.\n",
          "  Or they do not have the correct extensions, check file names and try again!"))
  }
  .sauce(fileNames, ...)
  setwd(currDir)
  return(invisible())
}


#' @title Creates a random file name
#' 
#' @param prefix the file prefix
#' @param extn the file extension with or without a leading full stop
#' @param nrand the number of random characters to generate as an 
#'        append to the file name
#' @return A random file name
#'
#' @export
#' 
createFileName = function(prefix = "saucer", extn = NULL, nrand = 12)
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


.dfunction = function(code, dropFolder = NULL, folderName = NULL, compiler = "ldmd2", 
                flags = c("-O", "-boundscheck=off", "-mcpu=native"), moduleName = NULL)
{
  if(is.null(moduleName))
  {
    moduleName = createFileName()
  }
  prefix = paste0("module ", moduleName,";\nimport sauced.saucer;\n\n")
  code = paste0(prefix, code)
  codeFile = paste0(moduleName, ".d")
  cat(code, file = codeFile)
  executionError = FALSE
  tryCatch(.sauce(codeFile, dropFolder = dropFolder, folderName = folderName, compiler = compiler, flags = flags), 
    error = function(e){
      cat("Error on .sauce:\n")
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
#'              export functions mustq be marked with `@Export()`
#' 
#' @param code character vector containing the code to be compiled
#' @param dropFolder logical for whether the folder containing the code
#'        and compilation artifacts should be dropped after compilation is 
#'        done. Defaults to TRUE.
#' @param folderName character for what the folder name the generated code
#'        should be. Defaults to NULL - random name generated.
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler)
#' @param flags character vector flags to be passed to the chosen D compiler
#' @param moduleName what the module should be called, defaults to NULL - 
#'        random generated value given
#' 
#' @return character array of code submitted into the code array
#' 
#' @examples
#'         dfunctions("
#'         import std.stdio: writeln;
#'         @Export() int squared(int x)
#'         {
#'           x = x*x;
#'           writeln(\"x squared: \", x);
#'           return x;
#'         }
#'         @Export() double cubed(double x)
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
dfunctions = function(code, dropFolder = TRUE, folderName = NULL, compiler = "ldmd2", 
                  flags = c("-O", "-boundscheck=off", "-mcpu=native"), moduleName = NULL)
{
  result = .dfunction(paste0(code, collapse = "\n"), 
              dropFolder = dropFolder, folderName = folderName, 
              compiler = compiler, flags = flags, moduleName = moduleName)
  return(invisible(result))
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
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler)
#' @param flags character vector of d compiler flags to pass
#' @param cleanup logical whether to remove the generated directories afterwards or not 
#' 
#' @export
#' 
compileRInside = function(fileName, compiler = "ldmd2", flags = c("-O", "-mcpu=native"), cleanup = TRUE)
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

  command = paste0(c(compiler, files, flags, "-fPIC", "-L-lR", 
                  "-L-lRmath", jFlag), collapse = " ")
  system(command)

  if(cleanup)
  {
    dir.remove(destDir)
  }

  return(invisible(command))
}



#' @title Runs the internal D unittests for translator.d
#' 
#' @param dropFolder whether the generated code folder should be dropped or not
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler) if installed
#' @param folderNamePrefix the prefix name for the folder defaults to "dSaucerTest"
#'
#'
#' @return NULL invisibly
#' 
runDTranslatorTests = function(dropFolder = TRUE, compiler = "ldmd2", folderNamePrefix = "dTest")
{
  currWd = getwd()
  sourceDir = system.file("sauced", package = "saucer")
  folderName = createFileName(folderNamePrefix)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  dir.copy(sourceDir, codeFolder)
  setwd(codeFolder)

  command = "
  echo -e 'enum moduleName = \"test.files.test_resource_1\";' | ${compiler} translator.d test/files/example_1.d \
          test/files/test_resource_1.d test/files/test_resource_2.d saucer.d r2d.d -unittest -main -O \
          -mcpu=native -g -J=. -L-lR -L-lRmath
  ./translator
  "
  command = stringr::str_interp(command, list("compiler" = compiler))
  runCommand(command, codeFolder, currWd, currWd)
  if(dropFolder)
  {
    unlink(codeFolder, recursive = TRUE)
  }
  return(invisible(NULL))
}


#' @title Runs the internal D tests for saucer.d script
#' 
#' @param dropFolder whether the generated code folder should be dropped or not
#' @param compiler character either "ldmd2" (default - ldc compiler) 
#'        or "dmd" (DMD compiler) if installed
#' @param folderNamePrefix the prefix name for the folder defaults to "dSaucerTest"
#' 
#' @return NULL (invisibly)
#' 
runSaucedTests = function(dropFolder = TRUE, compiler = "ldmd2", folderNamePrefix = "dSaucerTest")
{
  currWd = getwd()
  sourceDir = system.file("sauced", package = "saucer")
  folderName = createFileName(folderNamePrefix)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  dir.copy(sourceDir, codeFolder)
  setwd(codeFolder)

  command = "\n${compiler} saucer.d r2d.d -unittest -main -O -mcpu=native -g -J=. -L-lR -L-lRmath && ./saucer\n"
  command = stringr::str_interp(command, list("compiler" = compiler))
  runCommand(command, codeFolder, currWd, currWd)
  if(dropFolder)
  {
    unlink(codeFolder, recursive = TRUE)
  }
  return(invisible(NULL))
}

