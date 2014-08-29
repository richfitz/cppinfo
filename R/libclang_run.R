## Interface to my interface to the python interface to libclang code:
##   R -> Python -> C++ -> Python -> R -> YAML -> R
## Ideally there is some other way of doing this on Windows where
## rPython is not available.  But I don't immediately see how, as the
## serialisation approach that is being used at present seems fairly
## flexible.  We could do it via calls and return serialise objects,
## but that would require running libclang for every use, which seems
## not-ideal.
libclang_init <- function(libclang_filename=NULL) {
  ## http://r.789695.n4.nabble.com/Recommended-way-to-call-import-functions-from-a-Suggested-package-td4659415.html
  loadNamespace("rPython")
  rPython::python.exec("import sys")
  if (!rPython::python.call("sys.modules.has_key", "cppinfo")) {
    path <- system.file(package="cppinfo", mustWork=TRUE)
    rPython::python.exec(sprintf("sys.path.append('%s')", normalizePath(path)))
    rPython::python.exec("import cppinfo")
  }
  if (!is.null(libclang_filename)) {
    libclang_set_library_file(libclang_filename)
  }
}

##' Set location of the libclang file.  On OS X this is findable by
##' running \code{mdfind -name libclang.dylib} and may be
##' `/Library/Developer/CommandLineTools/usr/lib/libclang.dylib`.  If
##' the libclang library is found within your dynamic library search
##' path (\code{DYLD_LIBRARY_PATH} on OS X, \code{LD_LIBRARY_PATH} on
##' Linux) then this is not necessary.
##' @title Set path to libclang
##' @param filename Filename of libclang.dylib or libclang.so (full
##' pathm including the file itself)
##' @author Rich FitzJohn
##' @export
libclang_set_library_file <- function(filename) {
  libclang_init()
  rPython::python.call("cppinfo.set_library_file", filename)
}

##' Run libclang to collect up type information.
##'
##' At the moment, opts is ignored.  This is all entirely discoverable
##' from the R build environment so hopefully I'll get that added at
##' some point.  At the moment I'm running with
##' \code{-x c++ -std=c++11 -stdlib=libc++}
##' which seems fairly sesible except for forcing c++11.
##' @title Run libclang
##' @param input Single file to run
##' @param opts Character vector of options to pass through to libclang.
##' @return 
##' @author Rich FitzJohn
##' @export
libclang_run <- function(input, opts) {
  libclang_init()
  opts <- c('-x', 'c++', '-std=c++11', '-stdlib=libc++')
  if (!is.character(input) || length(input) != 1) {
    stop("input must be a scalar character")
  }
  if (!is.character(opts)) {
    stop("opts must be a character vector")
  }
  libclang_index$new(rPython::python.call('cppinfo.r_libclang_run', input, opts))
}
