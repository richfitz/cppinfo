##' Run gccxml to collect up type information.
##'
##' There are an absolute ton of possible otions here, none of which
##' are supported.
##' @title Run GCCXML
##' @param input Single filename to run on
##' @param output Directory to leave output file (will be called
##' \code{gcc.xml})
##' @author Rich FitzJohn
##' @export
gccxml_run <- function(input, output) {
  dir.create(output, FALSE)
  output_file <- file.path(output, "gcc.xml")
  system(sprintf("%s %s -fxml=%s", gccxml_path(), input, output_file))
  gccxml_index$new(output_file)
}

gccxml_path <- function() {
  "gccxml_cc1plus"
}
