##' Run doxygen
##' @title Run doxygen
##' @param input Vector of directories to search for inut files
##' @param output Output directory.  xml will be in
##' \code{file.path(output, "xml")}.
##' @author Rich FitzJohn
##' @export
doxygen_run <- function(input, output) {
  dir.create(output, FALSE)

  doxyfile <- file.path(output, "Doxyfile")

  ## Make this quiet:
  system(sprintf("%s -g %s", doxygen_path(), doxyfile))

  ## TODO: Need to tweak include path so that we pick up things from
  ## Makevars, and from the general R path.  It might be OK without
  ## this though.  The issue will be if the things to wrap are in a
  ## header file.
  str <- readLines(doxyfile)
  opts <- list(GENERATE_HTML="NO",
               GENERATE_LATEX="NO",
               GENERATE_XML="YES",
               EXTRACT_ALL="YES",
               OUTPUT_DIRECTORY=output,
               INPUT=paste(input, collapse=" "))
  str <- doxyfile_set_options(opts, str)
  writeLines(str, doxyfile)

  ## Also make this quiet
  system(sprintf("%s %s", doxygen_path(), doxyfile))

  doxygen_index$new(output)
}

## This eventually becomes configurable
doxygen_path <- function() {
  "doxygen"
}

doxyfile_set_options <- function(opts, str) {
  for (i in names(opts)) {
    str <- doxyfile_set_option(i, opts[[i]], str)
  }
  str
}

doxyfile_set_option <- function(key, value, str) {
  re <- sprintf("^(%s\\s*=\\s*)(.*)$", key)
  i <- grep(re, str)
  if (length(i) != 1) {
    stop(sprintf("key %s not found", key))
  }
  str[i] <- sub(re, sprintf("\\1%s", value), str[i])
  str
}
