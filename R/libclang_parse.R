libclang_index <-
  R6::R6Class("libclang_index",
              public=list(
                cache=NULL,
                key=NULL,
                initialize=function(key) {
                  self$key <- key
                },
                names=function() {
                  ## This needs work
                  stop("Not yet implemented")
                },
                has_class=function(name) {
                  rPython::python.call("cppinfo.r_has_class", name, self$key)
                },
                get_class_internal=function(name) {
                  obj <- rPython::python.call("cppinfo.r_get_class", name, self$key)
                  libclang_process_class(obj)
                },
                ## Will move into the parent class:
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

## Compared to gccxml and doxygen this is really easy because I
## already tweaked things to be in the right format.
libclang_process_class <- function(obj) {
  ret <- cpp_class$new()
  ret$name <- obj$name
  ret$location <- libclang_process_location(obj$location)
  ret$constructors <- lapply(obj$constructors,
                             libclang_process_constructor, ret)
  ret$methods <- lapply(obj$methods, libclang_process_method, ret)
  ret$fields  <- lapply(obj$fields,  libclang_process_field,  ret)
  ret$template_info <-
    libclang_process_template_info(obj$template_info, ret)
  ret
}

libclang_process_location <- function(obj) {
  ret <- cpp_location$new()
  ret$file   <- obj$file
  ret$line   <- obj$line
  ret$column <- obj$column
  ret
}

libclang_process_constructor <- function(obj, parent) {
  ret <- cpp_method$new()
  ret$name        <- obj$name
  ret$return_type <- NULL
  ret$parent      <- parent
  ret$location    <- libclang_process_location(obj$location)
  ret$args        <- lapply(obj$args, libclang_process_arg, ret)
  ret
}

libclang_process_method <- function(obj, parent) {
  ret <- cpp_method$new()
  ret$name        <- obj$name
  ret$return_type <- obj$return_type
  ret$location    <- libclang_process_location(obj$location)
  ret$parent      <- parent
  ret$args        <- lapply(obj$args, libclang_process_arg, ret)
  ## TODO: Add if this is public (Doxygen always public by default,
  ## but see gccxml
  ret
}

libclang_process_field <- function(obj, parent) {
  ret <- cpp_field$new()
  ret$name     <- obj$name
  ret$type     <- obj$type
  ret$location <- libclang_process_location(obj$location)
  ret$parent   <- parent
  ret
}

libclang_process_arg <- function(obj, parent) {
  ret <- cpp_arg$new()
  ret$parent  <- parent
  ret$name    <- obj[["name"]]
  ret$type    <- obj[["type"]]
  ret
}

libclang_process_template_info <- function(obj, parent) {
  if (is.null(obj)) {
    obj
  } else {
    lapply(obj, libclang_process_template_par, parent)
  }
}

libclang_process_template_par <- function(obj, parent) {
  ret <- cpp_template_par$new()
  ret$name <- obj[["name"]]
  ret$parent <- parent
  ret
}
