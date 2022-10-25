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
#' @export 
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


compileScript = function(fileName, currWd)
{
  dllFile = paste0(fileName, ".so");
  command = paste0("dmd ", fileName, 
                    ".d saucer.d r2d.d -O -boundscheck=off -mcpu=native -c -g -J=\".\" -fPIC -L-fopenmp -L-lR -L-lRmath && ",
                    "dmd ", fileName, ".o saucer.o r2d.o -O -boundscheck=off -mcpu=native -of=", dllFile,
                    " -L-fopenmp -L-lR -L-lRmath -shared")
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



# Internal workshorse function for compiling and loading a D module
.sauce = function(module, dropFolder = NULL, folderName = NULL)
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
  file.copy(file.path(currWd, paste0(module, ".d")), codeFolder)

  setwd(codeFolder)
  
  # Run the d compilation script
  command = "echo 'enum moduleName = \"${module}\";' | dmd translator.d ${currWd}/${module}.d saucer.d r2d.d -O -boundscheck=off -mcpu=native -g -J=\".\" -L-lR -L-lRmath && ./translator" #-L-lR -L-lRmath
  compileTranslator(command, currWd, module)
  compileScript(module, currWd)
  
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
    unlink(codeFolder, recursive = TRUE)
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
#' # sauce("script", dropFolder = TRUE)
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
sauce = function(modules, ...)
{
  currDir = getwd()
  for(i in 1:length(modules))
  {
    tryCatch(
      .sauce(modules[i], ...), 
      error = function(e)
      {
        cat("Failed to compile and load module:", modules[i], "\n")
        print(e)
      }
    )
  }
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
  tryCatch(.sauce(moduleName, dropFolder = dropFolder), error = function(e){
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



#' @title Runs the internal D unittests for translator.d
#' 
#' @param dropFolder whether the generated code folder should be dropped or not
#' @param folderNamePrefix the prefix name for the folder defaults to "dSaucerTest"
#'
#'
#' @return NULL invisibly
#' 
#' @export 
#' 
runDTranslatorTests = function(dropFolder = TRUE, folderNamePrefix = "dTest")
{
  currWd = getwd()
  sourceDir = system.file("sauced", package = "saucer")
  folderName = createFileName(folderNamePrefix)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  dir.copy(sourceDir, codeFolder)
  setwd(codeFolder)

  command = "
  echo 'enum moduleName = \"test.files.test_resource_1\";' | dmd translator.d test/files/example_1.d test/files/test_resource_1.d test/files/test_resource_2.d saucer.d r2d.d -unittest -main -O -mcpu=native -g -J=. -L-lR -L-lRmath
  ./translator
  "
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
#' @param folderNamePrefix the prefix name for the folder defaults to "dSaucerTest"
#' 
#' 
#' @return NULL invisibly
#' 
#' @export 
#' 
runSaucedTests = function(dropFolder = TRUE, folderNamePrefix = "dSaucerTest")
{
  currWd = getwd()
  sourceDir = system.file("sauced", package = "saucer")
  folderName = createFileName(folderNamePrefix)
  codeFolder = paste0(currWd, .Platform$file.sep, folderName)
  dir.copy(sourceDir, codeFolder)
  setwd(codeFolder)

  command = "
  dmd saucer.d r2d.d -unittest -main -O -mcpu=native -g -J=. -L-lR -L-lRmath && ./saucer
  "
  runCommand(command, codeFolder, currWd, currWd)
  if(dropFolder)
  {
    unlink(codeFolder, recursive = TRUE)
  }
  return(invisible(NULL))
}
