## Some of this is based off clang-ctags; those parts are flagged
## below.
import clang.cindex
import collections
import os.path

from clang.cindex import CompilationDatabase, CursorKind, Diagnostic, \
    TranslationUnit, TypeKind

# Push the API a little higher
def set_library_file(filename):
    clang.cindex.Config.set_library_file(filename)

results = {}
def r_libclang_run(filename, opts):
    key = os.path.abspath(filename)
    results[key] = run_clang(filename, opts)
    return key

def r_has_class(name, key):
    return bool(find_class(name, results[key].cursor))

def r_get_class(name, key):
    cursor = find_class(name, results[key].cursor)
    return cpp_class(cursor)

# Distantly related to clang-ctags
def run_clang(filename, opts):
    index = clang.cindex.Index.create()
    tu = index.parse(filename, opts,
                     options=TranslationUnit.PARSE_SKIP_FUNCTION_BODIES)
    errors = [d for d in tu.diagnostics
              if d.severity in (Diagnostic.Error, Diagnostic.Fatal)]
    if len(errors) > 0:
        print "File '%s' failed clang's parsing and type-checking" % \
            tu.spelling

    return tu

## Assume for now that we're looking for a fully qualified name, but
## this is easy to tweak, really.  But if we don't have the full
## qualification, then we'll traverse a lot of code.
def find_class(name, cursor):
    if is_named_scope(cursor):
        cursor_fqname = qualified_spelling(cursor)
        # Can't be any of the children, so return empty list
        if not name.startswith(cursor_fqname):
            return None
        # Can't be any of the children because it is itself a match
        if is_class_like(cursor) and cursor_fqname == name:
            return cursor
    for x in cursor.get_children():
        res = find_class(name, x)
        if res:
            return res

def cpp_class(cursor):
    kids = cursor.get_children()
    constructors = [cpp_constructor(x) for x in cursor.get_children()
                    if x.kind is CursorKind.CONSTRUCTOR]
    methods = [cpp_method(x) for x in cursor.get_children()
               if x.kind is CursorKind.CXX_METHOD]
    fields = [cpp_field(x) for x in cursor.get_children()
              if x.kind is CursorKind.FIELD_DECL]
    return {'name': qualified_spelling(cursor),
            'constructors': constructors,
            'methods': methods,
            'fields': fields,
            'template_info': cpp_template_info(cursor),
            'location': cpp_location(cursor.location)}    

def cpp_location(cursor):
    return {'file': cursor.file.name,
            'line': cursor.line,
            'column': cursor.column}

def cpp_field(cursor):
    return {'name': cursor.spelling,
            'type': cpp_type(cursor.type),
            'location': cpp_location(cursor.location)}

## I really don't know if we want the fully qualified name here?
def cpp_constructor(cursor):
    return {'name': qualified_spelling(cursor),
            'return_type': None,
            'location': cpp_location(cursor.location),
            'args': cpp_args(cursor)}

def cpp_method(cursor):
    return {'name': cursor.spelling,
            'return_type': cpp_type(cursor.result_type),
            'location': cpp_location(cursor.location),
            'args': cpp_args(cursor)}

def cpp_template_info(cursor):
    # TODO: also CLASS_TEMPLATE_PARTIAL_SPECIALIZATION?
    if cursor.kind is CursorKind.CLASS_TEMPLATE:
        return [cpp_template_par(p) for p in cursor.get_children()
                if is_template_parameter(p)]
    else:
        return None;

def cpp_template_par(cursor):
    if cursor.kind == CursorKind.TEMPLATE_TYPE_PARAMETER:
        return {'name': cursor.spelling}
    else:
        raise Exception("Not yet supported")

def cpp_type(cursor):
    if cursor.kind == TypeKind.LVALUEREFERENCE:
        return cpp_type(cursor.get_pointee()) + "&"
    elif cursor.get_declaration().kind is CursorKind.NO_DECL_FOUND:
        return cursor.spelling
    else:
        text = qualified_spelling(cursor.get_declaration())
        if cursor.is_const_qualified():
            text = 'const ' + text
        # Beautify output, though this might be required for use with
        # gcc.  Would like to know how to avoid:
        text = text.replace("std::__1::string", "std::string")
        return text

def cpp_args(cursor):
    return [cpp_arg(x) for x in cursor.get_arguments()]

# Getting the default is really nasty:
# http://clang-developers.42468.n3.nabble.com/Finding-default-value-for-function-argument-with-clang-c-API-td4036919.html
# So I'm not doing it.  It's not really how I want to be setting
# default values anyway.
def cpp_arg(cursor):
    return {'name': cursor.spelling,
            'type': cpp_type(cursor.type)}


# Construct the fully qualified name
# TODO: Might be worth skipping over the __1 namespace here, or in
# semantic parents:
def qualified_spelling(cursor):
    return '::'.join(semantic_parents(cursor) + 
                     [cursor.spelling or cursor.displayname])

# From clang-ctags
def semantic_parents(cursor):
    p = collections.deque()
    c = cursor.semantic_parent
    while c and is_named_scope(c):
        p.appendleft(c.displayname)
        c = c.semantic_parent
    return list(p)

# From clang-ctags
def is_definition(cursor):
    return (
        (cursor.is_definition() and not cursor.kind in [
            CursorKind.CXX_ACCESS_SPEC_DECL,
            CursorKind.TEMPLATE_TYPE_PARAMETER,
            CursorKind.UNEXPOSED_DECL]
            ) or
        # work around bug (?) whereby using PARSE_SKIP_FUNCTION_BODIES earlier
        # causes libclang to report cursor.is_definition() as false for
        # function definitions.
        cursor.kind in [
            CursorKind.FUNCTION_DECL,
            CursorKind.CXX_METHOD,
            CursorKind.FUNCTION_TEMPLATE])

# From clang-ctags
def is_named_scope(cursor):
    return cursor.kind in [
        CursorKind.NAMESPACE,
        CursorKind.STRUCT_DECL,
        CursorKind.UNION_DECL,
        CursorKind.ENUM_DECL,
        CursorKind.CLASS_DECL,
        CursorKind.CLASS_TEMPLATE,
        CursorKind.CLASS_TEMPLATE_PARTIAL_SPECIALIZATION]


def is_template_parameter(cursor):
    return cursor.kind in [
        CursorKind.TEMPLATE_TYPE_PARAMETER,
        CursorKind.TEMPLATE_NON_TYPE_PARAMETER,
        CursorKind.TEMPLATE_TEMPLATE_PARAMETER]

def is_class_like(cursor):
    return cursor.kind in [
        CursorKind.STRUCT_DECL,
        CursorKind.UNION_DECL,
        CursorKind.CLASS_DECL,
        CursorKind.CLASS_TEMPLATE,
        CursorKind.CLASS_TEMPLATE_PARTIAL_SPECIALIZATION]
