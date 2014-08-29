idx_d <- idx_g <- idx_c <- NULL

test_that("Can run commands", {
  idx_d <<- doxygen_run('src/test.cc', tempfile())
  # idx_g <<- gccxml_run('src/test.cc', tempfile())
  idx_c <<- libclang_run('src/test.cc')
})

test_that("Expected contents found", {
  ## Doxygen misses the struct.  That's OK because it's a fixable bug:
  expect_that(idx_d$names(),
              equals(c("mypackage::circle", "mypackage::pair1")))
  ## GCCXML misses the struct for the same reason.  Easy enough to fix.
  ## It also misses mypackage::pair1 because that's an uninstantiated
  ## template.
  ## expect_that(idx_g$names(),
  ##             equals("mypackage::circle"))
  expect_that(idx_c$names(), throws_error("Not yet implemented"))

  expect_that(idx_d$has_class("mypackage::circle"), is_true())
  expect_that(idx_d$has_class("mypackage::pair1"), is_true())
  expect_that(idx_d$has_class("mypackage::foo"), is_false())

  ## expect_that(idx_g$has_class("mypackage::circle"), is_true())
  ## expect_that(idx_g$has_class("mypackage::pair1"), is_false())
  ## expect_that(idx_g$has_class("mypackage::foo"), is_false())

  expect_that(idx_c$has_class("mypackage::circle"), is_true())
  expect_that(idx_c$has_class("mypackage::pair1"), is_true())
  expect_that(idx_c$has_class("mypackage::foo"), is_true())
})

## Now, check the contents!
test_that("Check circle", {
  for (idx in c(idx_d, idx_c)) {
    cl <- idx$get_class("mypackage::circle")

    expect_that(cl$name, equals("mypackage::circle"))
    expect_that(cl$location$file, equals(normalizePath("src/test.cc")))
    expect_that(cl$location$line, equals(8))
    ## NOTE: the column number information seems odd at best: 1, NULL, 7.

    ## Templates:
    expect_that(cl$template_info, is_null())

    ## TODO: We can't in general rely on ordering of the libclang version:
    ## both because the underlying dictionaries don't guarantee sort and
    ## because the json transfer might not.  Probably good to sort these
    ## by line number of processing.
    expect_that(length(cl$methods), equals(3))
    methods <- c("area", "circumference", "set_circumference")
    expect_that(sapply(cl$methods, function(x) x$name), equals(methods))

    methods <- sapply(cl$methods, function(x) x$name)

    m <- cl$methods[[match("area", methods)]]
    expect_that(m$name, equals("area"))
    expect_that(m$is_constructor(), is_false())
    expect_that(m$return_type, equals("double"))
    expect_that(m$args, equals(list()))
    expect_that(m$parent, is_identical_to(cl))
    ## TODO: Doxygen location information missing here)
    expect_that(m$location$line, equals(12))
    expect_that(m$location$file, is_identical_to(cl$location$file))

    m <- cl$methods[[match("circumference", methods)]]
    expect_that(m$name, equals("circumference"))
    expect_that(m$is_constructor(), is_false())
    expect_that(m$return_type, equals("double"))
    expect_that(m$args, equals(list()))
    expect_that(m$parent, is_identical_to(cl))
    ## TODO: Doxygen location information missing here)
    expect_that(m$location$line, equals(15))
    expect_that(m$location$file, is_identical_to(cl$location$file))

    m <- cl$methods[[match("set_circumference", methods)]]
    expect_that(m$name, equals("set_circumference"))
    expect_that(m$is_constructor(), is_false())
    expect_that(m$return_type, equals("void"))
    expect_that(length(m$args), equals(1))
    a <- m$args[[1]]
    expect_that(a$name, equals("c"))
    expect_that(a$type, equals("double"))
    expect_that(a$parent, is_identical_to(m))
    expect_that(m$parent, is_identical_to(cl))
    ## TODO: Doxygen location information missing here)
    expect_that(m$location$line, equals(18))
    expect_that(m$location$file, is_identical_to(cl$location$file))

    ## Fields:
    expect_that(length(cl$fields), equals(1))
    f <- cl$fields[[1]]
    expect_that(f$name, equals("radius"))
    expect_that(f$type, equals("double"))
    expect_that(f$location$line, equals(10))
    expect_that(f$location$file, equals(cl$location$file))
    expect_that(f$parent, is_identical_to(cl))

    ## Constructor:
    expect_that(length(cl$constructors), equals(1))
    ctor <- cl$constructors[[1]]
    ## This is not great.  Need to decide what to do with this, as I know
    ## I used fully qualified names for libclang
    expect_that(ctor$name, equals(cl$name))
    expect_that(ctor$is_constructor(), is_true())
    expect_that(length(ctor$args), equals(1))
    a <- ctor$args[[1]]
    expect_that(a$name, equals("r"))
    expect_that(a$type, equals("double"))
    expect_that(a$parent, is_identical_to(ctor))
    expect_that(ctor$location$file, equals(cl$location$file))
    expect_that(ctor$location$line, equals(11))
  }
})
