# Internal workshorse function for compiling and loading a D module
.saucerize = function(module, drop_folder = NULL, folder_name = NULL)
{
  curr_wd = getwd()
  source_dir = system.file("saucerd", package = "saucer")
  
  # drop if folder is random generated
  if(is.null(folder_name))
  {
    folder_name = paste0(sample(letters, 10), collapse = "")
    if(is.null(drop_folder))
    {
      drop_folder = TRUE
    }
  }else{
    if(is.null(drop_folder))
    {
      drop_folder = FALSE
    }
  }
  
  # Set Code Folder
  dir.create(folder_name)
  code_folder = paste0(curr_wd, "/", folder_name)
  setwd(code_folder)
  
  # Copy files
  file.copy(file.path(source_dir, "r2d.d"), code_folder)
  file.copy(file.path(source_dir, "saucer.d"), code_folder)
  file.copy(file.path(source_dir, "rvector.d"), code_folder)
  file.copy(file.path(source_dir, "rmatrix.d"), code_folder)
  file.copy(file.path(source_dir, "commonfunctions.d"), code_folder)
  file.copy(file.path(source_dir, "r_aliases.d"), code_folder)
  file.copy(file.path(source_dir, "translator.d"), code_folder)
  file.copy(file.path(curr_wd, paste0(module, ".d")), code_folder)
  
  # Run the d compilation script
  command = "echo 'enum moduleName = \"${module}\";' | dmd translator.d ${curr_wd}/${module}.d saucer.d r2d.d -O -boundscheck=off -mcpu=native -g -J=\".\" -L-lR -L-lRmath && ./translator" #-L-lR -L-lRmath
  command = stringr::str_interp(command, list("curr_wd" = curr_wd, "module" = module))

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
    setwd(curr_wd)
    return(stop("Compilation command failed to execute! Propagating error and exiting"))
  }
  
  # cat("Command output: \n", command_output, sep = "")
  
  # Load the translated functions in a generated R script
  source(paste0(module, ".r"))
  
  # Set folder back to the initial folder
  setwd(curr_wd)
  
  # Delete these two lines
  # Move translator file (belated, should be compiled in the new folder!)
  # system(stringr::str_interp("mv translator.d translator.o translator ${folder_name}/", list("folder_name" = folder_name)))
  
  # Drop folder if indicated
  if(drop_folder)
  {
    unlink(code_folder, recursive = T)
    cat("Temporary code folder ", code_folder, " deleted.\n", sep = "")
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
#' @param folder_name  a character containing the name of the
#'        folder where the code will be created. If missing
#'         a random name is generated
#' @param drop_folder whether to delete the folder containing
#'        the compilation artifacts once the compilation is done.
#' 
#' @return NULL
#' 
#' @export
#' 
#' @examples
#' 
#' # require(saucer)
#' # saucerize("script", drop_folder = TRUE)
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
create_file_name = function(prefix = "script", extn = NULL, nrand = 12)
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


.dfunction = function(code, drop_folder)
{
  module_name = create_file_name()
  prefix = paste0("module ", module_name,";\nimport saucer;\n\n")
  code = paste0(prefix, code)
  code_file = paste0(module_name, ".d")
  cat(code, file = code_file)
  executionError = FALSE
  tryCatch(.saucerize(module_name, drop_folder = drop_folder), error = function(e){
    cat("Error on .saucerize:\n")
    paste(e)
    executionError <<- TRUE
  })
  if(executionError)
  {
    # cat("Printing the requested compilation:\n###################################\n", code, 
    #         "###################################\n")
    if(file.exists(code_file))
    {
      cat("Deleting the temp script ", code_file, "\n", sep = "")
      file.remove(code_file)
      cat("Temp script ", code_file, " removed, folder will still remain\n", sep = "")
    }
    return(invisible(code))
  }
  # Clean up
  cat("Deleting temp file: ", code_file, "\n")
  unlink(code_file)
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
dfunctions = function(code_arr, drop_folder = TRUE)
{
  result = .dfunction(paste0(code_arr, collapse = "\n"), drop_folder)
  return(invisible(result))
}
