## Utilities for dealing with XML data

## Might as well load the entire damn package: we use a ton of
## functions from it:
##' @import XML
getNode <- function(doc, path, ..., missing_ok=FALSE) {
  res <- getNodeSet(doc, path)
  if (length(res) > 1) {
    stop("More than one node found")    
  } else if (length(res) == 0) {
    if (missing_ok) {
      NULL
    } else {
      stop("Node not found")
    }
  } else {
    res[[1]]
  }
}

getNodeValue <- function(...) {
  nd <- getNode(...)
  if (is.null(nd)) NULL else xmlValue(nd, recursive=FALSE)
}
