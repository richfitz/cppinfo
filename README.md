Extract type information from C++ code

There are three backends that I'm developing at the same time:

* [Doxygen](http://doxygen.org)
* [GCCXML](http://gccxml.github.io)
* [libclang](http://clang.llvm.org/doxygen/group__CINDEX.html)

Each of these have strengths and weaknesses, and it's not clear to me which will be best for use.

# What is output so far?

At the moment just class information.  For each class, we return lists of constructors, methods and fields (public only for doxygen, all for gccxml/libclang).  Template information.  For each argument, name and type information is included.  Everything has location information (file/line/column).

# What is on the radar?

Functions.  This is actually really easy, I just haven't got around to it.

# The different backends

One unresolved difference is that Doxygen processes whole directories at once, while GCCXML and libclang operate one file at a time (being focussed on translation units).

## Doxygen

This is the easiest to install.  It presumably does a good job in parsing C++ given it is in very widespread use.  We parse its XML output, which contains pretty much everything we need.  What is *not* included is any system headers.  So if you want information about, say, `std::pair` or a boost library, you'll have to get doxygen to document that directory too.

## GCCXML

This is fairly easy to install, though it depends on Cmake, which is not always installed already.  It also doesn't do well with system libraries (I think).  But the biggest problem is that it can't/won't include information on uninstantiated templates.  That's a problem if you want to point this at headers to get type information as the templates aren't instantiated there.

## libclang

This is a pain to install, but apart from that is capable of doing pretty much everything.

Installing this requires at least [rPython](http://cran.r-project.org/web/packages/rPython) (not available on windows) and the Python libclang bindings.  The version from `pip install clang` **will not work**: you must clone the repo [here](https://github.com/trolldbois/python-clang) and install with `sudo setup.py install`.  The reason for this is that we require `clang_getTypeSpelling()`, which is not exposed in the version on pip.  Libclang must be installed.  On OSX, this is locatable by running `mdfind -name libclang.dylib`.  It is possibly in `/Library/Developer/CommandLineTools/usr/lib/libclang.dylib`.  You'll need to either add this to `$DYLD_LIBRARY_PATH` or pass it through to `cppinfo::libclang_set_library_file()` so that the Python libclang module can find it.  If you download the binaries from [llvm](http://llvm.org) some extra work is needed to set search paths.  If you get that working please let me know or file an issue/PR with directions.
