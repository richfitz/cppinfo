## Code that would get up and running with the python wrapper.
import sys
import os.path
sys.path.append(os.path.abspath("../../inst"))
import cppinfo

opts = ['-x', 'c++', '-std=c++11', '-stdlib=libc++']
tu = cppinfo.libclang_run("src/test.cc", opts)
cursor = cppinfo.find_class("mypackage::circle", tu.cursor)
cppinfo.cpp_class(cursor)
