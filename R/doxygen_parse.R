doxygen_index <-
  R6::R6Class("doxygen_index",
              public=list(
                xml=NULL,
                path=NULL,
                cache=NULL,
                initialize=function(path) {
                  self$path <- file.path(path, "xml")
                  self$xml <-
                    xmlRoot(xmlInternalTreeParse(file.path(self$path,
                                                           "index.xml")))
                },
                names=function() {
                  xpath <- "/doxygenindex/compound[@kind = 'class']/name"
                  set <- getNodeSet(self$xml, xpath)
                  if (length(set) == 0) character(0) else sapply(set, xmlValue)
                },
                has_class=function(name) {
                  fmt <- "/doxygenindex/compound[name='%s' and @kind='class']"
                  xpath <- sprintf(fmt, name)
                  length(getNodeSet(self$xml, xpath)) == 1
                },
                get_class_xml=function(name) {
                  xpath <- sprintf("/doxygenindex/compound[name='%s']", name)
                  nd <- getNode(self$xml, xpath)
                  nd_file <- paste0(xmlGetAttr(nd, "refid"), ".xml")
                  xmlRoot(xmlInternalTreeParse(file.path(self$path, nd_file)))
                },
                get_class=function(name) {
                  if (name %in% names(self$cache)) {
                    cl <- self$cache[[name]]
                  } else if (self$has_class(name)) {
                    self$cache[[name]] <- cl <-
                      doxygen_process_class(self$get_class_xml(name))
                  } else {
                    stop(sprintf("Class %s not found"))
                  }
                  cl
                }))

doxygen_process_class <- function(xml) {
  if (length(xml) != 1 && length(xml$compoundef) != 1) {
    stop("Unexpected format in class definition") # check xsd perhaps?
  }

  ret <- cpp_class$new()

  ret$name <- getNodeValue(xml, "/doxygen/compounddef/compoundname")

  ret$template_info <- doxygen_template_info(xml, ret)
  
  functions <- xpathApply(xml, "//memberdef[@kind='function']",
                          doxygen_process_method, ret)

  is_constructor <- sapply(functions, function(x) x$is_constructor())
  ret$constructors <- functions[ is_constructor]
  ret$methods      <- functions[!is_constructor]

  ret$fields <- xpathApply(xml, "//memberdef[@kind='variable']",
                           doxygen_process_field, ret)

  loc_xml <- getNode(xml, "./compounddef/location")
  ret$location <- doxygen_process_location(loc_xml)
  ret
}

doxygen_template_info <- function(xml, parent) {
  info <- getNode(xml, "/doxygen/compounddef/templateparamlist",
                  missing_ok=TRUE)
  if (!is.null(info)) {
    info <- xpathApply(info, "./param", doxygen_template_par, parent)
  }
  info
}

doxygen_template_par <- function(xml, parent) {
  ret <- cpp_template_par$new()
  if (!identical(unname(names(xml)), "type")) {
    stop("Still have to process this")
    ## According to the xsd, all sorts of interesting things could be
    ## in here! 'name' looks like most interesting
  }
  ret$name <- sub("(typename|class) ", "", getNodeValue(xml, "./type"))
  ret$parent <- parent
  ret
}

doxygen_process_method <- function(xml, parent) {
  ret <- cpp_method$new()
  ret$name        <- getNodeValue(xml, "./name")
  ret$return_type <- getNodeValue(xml, "./type")
  if (length(ret$return_type) == 0 || ret$return_type == "") {
    ret$return_type <- NULL
  }
  ret$location    <- doxygen_process_location(xml)
  ret$parent      <- parent
  ret$args <- xpathApply(xml, "./param", doxygen_process_arg, ret)
  ret
}

doxygen_process_field <- function(xml, parent) {
  ret <- cpp_field$new()
  ret$name     <- getNodeValue(xml, "./name")
  ret$type     <- getNodeValue(xml, "./type")
  ret$location <- doxygen_process_location(xml)
  ret$parent   <- parent
  ret
}

doxygen_process_arg <- function(xml, parent) {
  ret <- cpp_arg$new()
  ret$parent  <- parent
  ret$name    <- getNodeValue(xml, "./declname")
  ret$type    <- getNodeValue(xml, "./type")
  ret$default <- getNodeValue(xml, "./defval", missing_ok=TRUE)
  ret
}

doxygen_process_location <- function(xml) {
  ret <- cpp_location$new()
  tmp <- as.list(xmlAttrs(xml))
  ret$file      <- tmp$file
  ret$bodyfile  <- tmp$bodyfile
  ret$line      <- as.integer(tmp$line)
  ret$column    <- as.integer(tmp$column)
  ret$bodystart <- as.integer(tmp$bodystart)
  ret$bodyend   <- as.integer(tmp$bodyend)
  ret
}
