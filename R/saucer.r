.options = new.env()

#' 
#' @seealso To use this package see the \code{\link{dfunctions}}
#'              or the \code{\link{dfunctions}} function
#' 
#' @keywords internal
#' 
"_PACKAGE"


logLevels = list("FATAL", "ERROR", "WARN", "INFO", "DEBUG", "TRACE")
names(logLevels) = logLevels


initOptions = function()
{
    .options$compiler = "ldmd2"
    .options$DFlagsScript = c("-c", "-g", "-J=\".\"")
    .options$DTranslatorFlags = c("-J=\".\"")
    .options$DOptionalFlags = c("-O", "-boundscheck=off", "-mcpu=native")
    .options$RFlags = c("-fPIC", "-L-lR", "-L-lRmath")
    .options$SaucedTests = c("-unittest", "-main", "-O", "-mcpu=native", 
                                "-g", "-J=.", "-L-lR", "-L-lRmath")
    .options$logging = TRUE
    .options$loggingLevel = "TRACE"
    return()
}


#' @title Sets the saucer compiler options
#' 
#' @param ... named parameters used to set
#'        the options. See details.
#' @details
#'         Options are as follows:
#' 
#'         compiler character the compiler to use, choose
#'                  "ldmd2", "dmd", other options will mean that
#'                  the flags will need to be reset
#'         DFlagsScript character array containing the flags
#'                  to be set for compiling the scripts
#'                  defaults to c("-c", "-g", "-J=\".\"")
#'         DTranslatorFlags character array containing the flags
#'                  to be set to generate the function wrappers
#'                  defaults to c("-J=\".\"")
#'         DOptionalFlags character array containing the flags to
#'                  be set for optional D flags e.g. optimisation etc.
#'                  defaults to c("-O", "-boundscheck=off", "-mcpu=native")
#'         RFlags character array for R flags for compiling e.g. -L-lR etc.
#'                  defaults to c("-fPIC", "-L-lR")
#'         SaucedTests compiler flags for the sauce tests
#' 
#' @export
#' 
setSaucerOptions = function(...)
{
    opts = list(...)
    setNames = names(opts)
    namesCheck = setNames %in% names(.options)
    if(sum(namesCheck) != length(setNames))
    {
        stop(paste0("Unable to set names for:", 
            paste0(setNames[!namesCheck], collapse = ", ")))
    }
    for(name in setNames)
    {
        .options[[name]] = opts[[name]]
    }
    return(opts)
}


#' @title Gets the specified compiler options
#' 
#' @param names character vector for the names in .options
#'              whose values are to be returned
#' 
#' @return list containing values indexed with names
#' 
#' @export
#' 
getSaucerOptions = function(names)
{
    result = vector(length = length(names), mode = "list")
    for(name in names)
    {
        result[[name]] = .options[[name]]
    }
    return(result)
}



setLoggingLevel = function(loggingLevel)
{
    loggingLevel = toupper(loggingLevel)
    .options$loggingLevel = logLevels[[loggingLevel]]
}


#' @title Function sets option for logging
#' 
#' @param flag for whether functions should be verbose 
#'         and print progress information
#' @return the input flag invisibly
#' 
#' @export
#' 
doLogging = function(flag)
{
    .options$logging = flag
    msg = paste("Logging is now set to", flag, "\n")
    cat(msg)
    return(invisible(flag))
}


#' @title Sets the file name where the log file will be written
#' 
#' @param fileName character for the file name where the log 
#'        file will be written.
#' 
#' @export
#' 
setLogFile = function(fileName = NULL)
{
    if(is.null(fileName))
    {
        .options$fileName = "saucer_" %+% 
                gsub("[-|:|\\.| ]", "_", as.character(Sys.time())) %+% ".log"
    }else{
        .options$fileName = fileName
    }
    return(invisible(fileName))
}


#' @title checkes whether logging is active during compilation
#' 
#' @export
#'
isLogActive = function()
{
    if(is.null(.options$logging) || (!.options$logging))
    {
        return(FALSE)
    }
    return(TRUE)
}

logger = function(...)
{
    if(isLogActive())
    {
        msg = paste0(c(.options$loggingLevel, 
                    as.character(Sys.time()), ..., "\n"))
        cat(msg, file = .options$fileName, append = TRUE)
        cat(msg) # to console
    }
    return(invisible(NULL))
}


`%+%` = function(e1, e2)
{
    return(paste0(c(e1, e2), collapse = ""))
}


initOptions()
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
    logger("Running command: " %+% command)
    status = system(command, intern = FALSE)
    
    if(status != 0)
    {
        setLoggingLevel("ERROR")
        msg = "Compilation command had a status of " %+% status
        logger(msg)
        msg = "Exiting as a result of error, and resetting failDirectory ..."
        logger(msg)
        setwd(failDirectory)
        msg = "Compilation command failed to execute! Propagating error and exiting"
        cat(msg)
        setLoggingLevel("TRACE")
        stop(msg)
    }else{
        setwd(successDirectory)
        logger("Success: set working directory to: " %+% successDirectory)
    }
    return(invisible())
}



compileTranslator = function(command, currWd, module)
{
    logger(paste0("Running command: ", command))
    status = system(command, intern = FALSE)
    
    if(status != 0)
    {
        logger("Compilation command had a status of " %+% status)
        logger("Exiting as a result of error, and resetting working directory ...")
        setwd(currWd)
        msg = "Compilation command failed to execute! Propagating error and exiting\n"
        cat(msg)
        stop(msg)
    }
    return(invisible())
}


compileScript = function(moduleNames, currWd)
{
    dllFile = paste0(moduleNames[1], ".so")
    sllFiles = paste0(moduleNames, ".o", collapse = " ")
    scriptFiles = paste0(moduleNames, ".d", collapse = " ")
    flags1 = paste(c(.options$DFlagsScript, .options$DOptionalFlags, 
                    .options$RFlags), collapse = " ")
    flags2 = paste(c(.options$DOptionalFlags, .options$RFlags), collapse = " ")
    compiler = .options$compiler
    command = paste0(c(compiler, " ", scriptFiles, " saucer.d r2d.d ", 
                     flags1, " && ", compiler, " ", sllFiles, 
                     " saucer.o r2d.o -of=", dllFile, " ", flags2, " -shared"), collapse = "")
    logger("Compiling script(s), command: " %+% command)
    status = system(command, intern = FALSE)
    
    if(status != 0)
    {
        setLoggingLevel("ERROR")
        logger("Compilation command had a status of " %+% status)
        logger("Exiting as a result of error, and resetting working directory ...")
        setwd(currWd)
        msg = "Compilation command failed to execute! Propagating error and exiting\n"
        cat(msg)
        setLoggingLevel("TRACE")
        stop(msg)
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
#' @param dropFolder logical for whether the folder containing the code
#'        and compilation artifacts should be dropped after compilation is 
#'        done. Defaults to TRUE.
#' @param folderName character for what the folder name the generated code
#'        should be. Defaults to NULL - random name generated.
#' 
#' @return NULL
#' 
.sauce = function(fileNames, dropFolder = NULL, folderName = NULL)
{
    currWd = getwd()
    sourceDir = system.file("sauced", package = "saucer")
    compiler = .options$compiler
    
    # drop if folder is random generated
    if(is.null(folderName))
    {
        # folderName = paste0(sample(letters, 10), collapse = "")
        folderName = gsub("-", "_", uuid::UUIDgenerate())
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
    command = paste0(c(command, "saucer.d r2d.d", .options$DTranslatorFlags, 
                    .options$RFlags), collapse = " ")
    command = paste0(command, " && ./translator")
    
    # Run the d compilation script
    logger("Translator compilation command to generate script to be compiled: " %+% command)
    compileTranslator(command, currWd, module)
    logger("Translator compiled, now compiling script")
    compileScript(moduleNames, currWd)
    logger("Script compiled!")
    
    # Load the translated functions in a generated R script
    source(paste0(moduleNames[1], ".r"))
    
    # Set folder back to the initial folder
    setwd(currWd)
    
    # Drop folder if indicated
    if(dropFolder)
    {
        unlink(codeFolder, recursive = TRUE)
        msg = "Temporary code folder " %+% codeFolder %+% " deleted.\n"
        cat(msg)
    }
    
    msg = paste0(moduleNames[1], " compiled and loaded.\n")
    cat(msg)
    
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
#'        include the ".d" extension. Only functions in the first
#'        file can be exported. Subsequent files are for dependencies
#'        in the first file only.
#' @param code character vector containing the code to be compiled
#' @param dropFolder logical for whether the folder containing the code
#'        and compilation artifacts should be dropped after compilation is 
#'        done. Defaults to TRUE.
#' @param folderName character for what the folder name the generated code
#'        should be. Defaults to NULL - random name generated.
#' 
#' @return NULL
#' 
#' @export
#' 
sauce = function(fileNames, ...)
{
    sourceFilesPresent = all(file.exists(fileNames))
    if(!(sourceFilesPresent && all(hasExtension(fileNames, "d"))))
    {
        stop(paste0("All the sources files for the modules listed are not present.\n",
              "  Or they do not have the correct extensions, check file names and try again!"))
    }
    .sauce(fileNames, ...)
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
createFileName = function(prefix = "saucer", extn = NULL, postfix = NULL)
{
    if(is.null(postfix))
    {
        postfix = gsub("-", "_", uuid::UUIDgenerate())
    }
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


.dfunctions = function(code, dropFolder = NULL, folderName = NULL, moduleName = NULL)
{
    postfix = NULL
    if(is.null(moduleName))
    {
        postfix = gsub("-", "_", uuid::UUIDgenerate())
        moduleName = createFileName(postfix = postfix)
    }
    if(is.null(folderName))
    {
        if(!is.null(postfix))
        {
            folderName = postfix
        }else{
            folderName = gsub("-", "_", uuid::UUIDgenerate())
        }
    }
    prefix = paste0("module ", moduleName,";\nimport sauced.saucer;\n\n")
    code = paste0(prefix, code)
    codeFile = paste0(moduleName, ".d")
    cat("Writing code to file: " %+% codeFile, "\n")
    cat(code, file = codeFile)
    executionError = FALSE
    tryCatch(.sauce(codeFile, dropFolder = dropFolder, folderName = folderName),
        error = function(e){
            setLoggingLevel("ERROR")
            cat("Error on .sauce: " %+% paste0(e, collapse = " "), "\n")
            executionError <<- TRUE
            setLoggingLevel("TRACE")
    })
    if(executionError)
    {
        if(file.exists(codeFile))
        {
          cat("Deleting the temp script " %+% codeFile, "\n")
          file.remove(codeFile)
          cat("Temp script " %+% codeFile %+% " removed, folder will still remain\n")
        }
        return(invisible(code))
    }
    # Clean up
    cat("Deleting temp file: " %+% codeFile, "\n")
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
dfunctions = function(code, dropFolder = TRUE, folderName = NULL, moduleName = NULL)
{
    result = .dfunctions(paste0(code, collapse = "\n"), 
                dropFolder = dropFolder, folderName = folderName, 
                moduleName = moduleName)
    return(invisible(result))
}


#' @title Delete a directory
#' 
#' @param directory character single directory to be removed
#' @param flags character vector of flags to be passed to the "rm"
#'        unix function.
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
#' @param cleanup logical whether to remove the generated directories afterwards or not 
#' 
#' @export
#' 
compileRInside = function(fileName, cleanup = TRUE)
{
    sourceDir = system.file("sauced", package = "saucer")
    destDir = createFileName(prefix = "tmpFolder")
    compiler = .options$compiler
    currWd = getwd()
    
    # Copy sauced to temp directory
    dir.copy(sourceDir, destDir)
    
    flags = paste0(.options$DOptionalFlags, collapse = " ")
    files = paste0(paste0(destDir, .Platform$file.sep), 
                c("saucer.d", "r2d.d", "rinside/rembedded.d", 
                  "rinside/rinterface.d", "rinside/rstartup.d"))
    files = c(fileName, files)
    jFlag = .options$DTranslatorFlags
    
    command = paste0(c(compiler, files, flags, .options$RFlags, 
                    jFlag), collapse = " ")
    logger("Compiling R inside, command: " %+% command)
    runCommand(command, destDir, currWd, currWd)
    
    if(cleanup)
    {
        dir.remove(destDir)
    }
    
    return(invisible(command))
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
runSaucedTests = function(dropFolder = TRUE, folderNamePrefix = "dSaucerTest")
{
    currWd = getwd()
    compiler = .options$compiler
    sourceDir = system.file("sauced", package = "saucer")
    folderName = createFileName(folderNamePrefix)
    codeFolder = paste0(currWd, .Platform$file.sep, folderName)
    dir.copy(sourceDir, codeFolder)
    
    command = "\n" %+% compiler %+% " saucer.d r2d.d " %+% 
                    paste0(.options$SaucedTests, collapse = " ") %+% " && ./saucer"
    logger("Compiling saucer tests, command: " %+% command)
    runCommand(command, codeFolder, currWd, currWd)
    if(dropFolder)
    {
        unlink(codeFolder, recursive = TRUE)
    }
    return(invisible(NULL))
}

