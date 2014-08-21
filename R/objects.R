## Objects to hold different types of information.  These are all
## "dumb" objects containing only fields.
##' @importFrom R6 R6Class
cpp_location <-
  R6Class("cpp_location",
          public=list(
            file=NULL,
            bodyfile=NULL,
            line=NULL,
            column=NULL,
            bodystart=NULL,
            bodyend=NULL))

cpp_arg <-
  R6Class("cpp_arg",
          public=list(
            name=NULL,
            type=NULL,
            default=NULL,
            parent=NULL))

cpp_method <-
  R6Class("cpp_method",
          public=list(
            name=NULL,
            return_type=NULL,
            args=NULL,
            location=NULL,
            parent=NULL))

cpp_field <-
  R6Class("cpp_field",
          public=list(
            name=NULL,
            type=NULL,
            location=NULL,
            parent=NULL))

cpp_class <-
  R6Class("cpp_class",
          public=list(
            name=NULL,
            constructors=NULL,
            methods=NULL,
            fields=NULL,
            template_info=NULL,
            location=NULL))

cpp_template_par <-
  R6Class("cpp_template_info",
          public=list(
            name=NULL,
            parent=NULL))
