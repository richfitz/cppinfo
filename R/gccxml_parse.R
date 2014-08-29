gccxml_index <-
  R6::R6Class("gccxml_index",
              public=list(
                xml=NULL,
                filename=NULL,
                cache=NULL,
                initialize=function(filename) {
                  self$filename <- filename
                  self$xml <- xmlRoot(xmlInternalTreeParse(self$filename))
                },
                names=function(full=TRUE) {
                  xpath <- "/GCC_XML/Class"
                  res <- getNodeSet(self$xml, xpath)
                  ## This returns the *full* name of the class,
                  ## i.e. including the namespace.
                  attr <- if (full) "demangled" else "name"
                  if (length(res) == 0) character(0) else
                  sapply(res, xmlGetAttr, attr)
                },
                has_class=function(name, full=TRUE) {
                  attr <- if (full) "demangled" else "name"
                  fmt <- "/GCC_XML/Class[@%s='%s']"
                  xpath <- sprintf(fmt, attr, name)
                  length(getNodeSet(self$xml, xpath)) == 1
                },
                get_class_internal=function(name, full=TRUE) {
                  attr <- if (full) "demangled" else "name"
                  fmt <- "/GCC_XML/Class[@%s='%s']"
                  xpath <- sprintf(fmt, attr, name)
                  nd <- getNode(self$xml, xpath)
                  gccxml_process_class(nd, self$xml)
                },
            get_class=function(name) {
              if (name %in% names(self$cache)) {
                cl <- self$cache[[name]]
              } else if (self$has_class(name)) {
                self$cache[[name]] <- cl <-
                  self$get_class_internal(name)
              } else {
                stop(sprintf("Class %s not found"))
              }
              cl
            }))

gccxml_process_class <- function(nd, xml) {
  ret <- cpp_class$new()

  ret$name <- xmlGetAttr(nd, "demangled")
  ## Can't do anything about templates with gccxml unless they're
  ## instantiated, which is unlikely in a header file...
  ret$template_info <- NULL


  members <- strsplit(xmlGetAttr(nd, "members"), " ", fixed=TRUE)[[1]]
  members_xml <- sapply(members, function(id)
                        getNode(xml, sprintf("/GCC_XML/*[@id='%s']", id)))
  members_type <- sapply(members_xml, xmlName)

  known_types <- c("Constructor", "Method", "Field", # handled
                   "Destructor", "OperatorMethod")   # ignored
  if (!all(members_type %in% known_types)) {
    stop("Unknown member types in class")
  }

  ret$constructors <- lapply(unname(members_xml[members_type == "Constructor"]),
                             gccxml_process_constructor, xml, ret)

  ## Operator methods need special treatment here.  That might also be
  ## the case in Doxygen too, actually.  Can set that up in the test
  ## cases.  Be careful not to exclude the assignment operator
  ## though.
  ret$methods <- lapply(unname(members_xml[members_type == "Method"]),
                        gccxml_process_method, xml, ret)

  ret$fields <- lapply(unname(members_xml[members_type == "Field"]),
                        gccxml_process_field, xml, ret)

  ret$location <- gccxml_process_location(nd, xml)
  ret
}

gccxml_process_constructor <- function(nd, xml, parent) {
  ret <- cpp_method$new()
  ret$name <- parent$name
  ret$return_type <- NULL
  ret$parent <- parent
  ret$location <- gccxml_process_location(nd, xml)
  ret$args <- lapply(xmlChildren(nd), gccxml_process_arg, xml, ret)
  ret
}

gccxml_process_method <- function(nd, xml, parent) {
  ret <- cpp_method$new()
  ret$name <- xmlGetAttr(nd, "name")
  ret$return_type <- gccxml_process_type(xmlGetAttr(nd, "returns"), xml)
  ret$location <- gccxml_process_location(nd, xml)
  ret$parent <- parent
  ret$args <- lapply(xmlChildren(nd), gccxml_process_arg, xml, ret)
  ## NOTE: Can add if this is public (Doxygen always public by default)
  ret
}

gccxml_process_field <- function(nd, xml, parent) {
  ret <- cpp_field$new()
  ret$name     <- xmlGetAttr(nd, "name")
  ret$type     <- gccxml_process_type(xmlGetAttr(nd, "type"), xml)
  ret$location <- gccxml_process_location(nd, xml)
  ret$parent   <- parent
  ret
}

gccxml_process_arg <- function(nd, xml, parent) {
  if (xmlName(nd) != "Argument") {
    stop("Unexpected input")
  }
  ret <- cpp_arg$new()
  ret$parent  <- parent
  ret$name    <- xmlGetAttr(nd, "name")
  ret$type    <- gccxml_process_type(xmlGetAttr(nd, "type"), xml)
  ret$default <- xmlGetAttr(nd, "default")
  ret
}

gccxml_process_location <- function(nd, xml) {
  ret <- cpp_location$new()
  file <- xmlGetAttr(nd, "file")
  xpath <- sprintf("/GCC_XML/File[@id='%s']", file)
  ret$file <- normalizePath(xmlGetAttr(getNode(xml, xpath), "name"))
  ret$line <- as.integer(xmlGetAttr(nd, "line"))
  ret
}

gccxml_process_type <- function(id, xml) {
  t <- getNode(xml, sprintf("/GCC_XML/*[@id='%s']", id))
  n <- xmlName(t)
  if (n == "FundamentalType") {
    xmlGetAttr(t, "name")
  } else if (n == "ReferenceType") {
    paste0(gccxml_process_type(xmlGetAttr(t, "type"), xml), "&")
  } else if (n == "CvQualifiedType") {
    paste(gccxml_process_type(xmlGetAttr(t, "type"), xml), "const")
  } else if (n == "Class") {
    xmlGetAttr(t, "demangled")
  } else {
    stop("fixme")
  }
}
