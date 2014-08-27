## There are an absolute ton of options here.  An interface for
## passing these along would be nice.
##
## Unlike doxygen, which naturally does a whole directory at once,
## this file is translation unit based.  So for now it's probably best
## to assume that the input is a single header file.
gccxml_run <- function(input, output) {
  dir.create(output, FALSE)
  output_file <- file.path(output, "index.xml")
  system(sprintf("%s %s -fxml=%s", gccxml_path(), input, output_file))
  gccxml_index$new(output_file)
}

gccxml_path <- function() {
  "gccxml_cc1plus"
}
