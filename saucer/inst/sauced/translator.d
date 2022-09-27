module sauced.translator;

import sauced.saucer;
import std.conv: to;
import std.traits: getUDAs, staticMap;
import std.algorithm.iteration: map;
import std.array: array;
import std.stdio: writeln;
import std.path: dirSeparator;


/+
    # Purpose
    D functions are called from R by wrapping the original function
    signatures as SEXP, so that these can be used by R's R_CallMethodDef 
    C API.

    # Data Members
    string origName - this is the original name of the D function
    string newName - this is the name of the wrapped SEXP style function
    string rName - this is the name that the function will be called in R
                    when it is exported
    long nArgs - this is the number of arguments in the function
    string signature - this is the full function signature for the wrapped
                        SEXP style function.
+/
struct Signature
{
    string origName;
    string newName;
    string rName;
    long nArgs;
    string signature;
}



/+
    The purpose of this function is perform a single pass of the
    module handed to it and extract the name of all the exported
    functions in the module.

    It consists of a single parameter moduleName the name of the
    module to be imported and extracted
+/
string[] getExportedFunctions(string moduleName)()
{
    string[] result;
    mixin("import " ~ moduleName ~ ";");
    //Iterating over all the items in the module
    static foreach(string item; __traits(allMembers, mixin(moduleName)))
    {
        //Select if there are attributes in the item
        static if(__traits(getAttributes, mixin(item)).length > 0)
        {
            //Iterating over the attributes
            static foreach(attr; __traits(getAttributes, mixin(item)))
            {{
                //Filters for the export attribute
                static if(is(typeof(attr) == Export))
                {
                    result ~= item;
                }
            }}
        }
    }
    assert(result.length > 0, "Number of exported items is zero please check that you are exporting functions");
    return result;
}


/*
    Tests for get_exported function
*/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] exFunctions = getExportedFunctions!(moduleName);
    static assert(exFunctions == ["dot_double", "dot", "create_integer_vector"],
            "Failed to retrieve the correct function names.");
}




/+
    Compile time function creates the Signature object when 
    supplied with the module name and the function as a string
+/
auto getSignature(string moduleName, string item)()
{
    import std.traits: ParameterIdentifierTuple;

    //Import the function name
    mixin("import " ~ moduleName ~ ": " ~ item ~ ";");
    //Filters if the attribute is Export
    mixin("enum attr = getUDAs!(" ~ item ~ ", Export)[0];");
    
    
    static if(attr.function_name == "")
    {
        enum string rName = item;
    }else{
        enum string rName = attr.function_name;
    }
    
    string newName = "__R_" ~ item ~ "__";
    long nArgs = mixin("ParameterIdentifierTuple!" ~ item).length;
    string funcSignature = "SEXP " ~ newName ~ "(";
    
    static foreach(i, param; mixin("ParameterIdentifierTuple!" ~ item))
    {
        if(i < (nArgs - 1))
        {
            funcSignature ~= "SEXP " ~ param ~ ", ";
        }else{
            funcSignature ~= "SEXP " ~ param;
        }
    }
    funcSignature ~= ")";
    return Signature(item, newName, rName, nArgs, funcSignature);
}


unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum signature = Signature("dot", "__R_dot__", "dot_product", 2, "SEXP __R_dot__(SEXP x_sexp, SEXP y_sexp)");
    static assert(signature == getSignature!(moduleName, "dot")(),
        "Signature test failure, wrong signature returned");
}



/**************************************************************************/

/+
    The purpose of the translator is to wrap the D functions so that they can
    easily be exported to R. The FunctionCall object holds all the information
    about the function that is exported. It basically contains all the things
    that are required to wrap the exported D functions to R

    Arguments:

    string origName the original name of the function before it is wrapped
    string resultName the name of the returned item within the function body.
    bool isVoid whether the original function returns void or not. 
                    A void return has to be wrapped to an SEXP null.
    string call the function call that maps the wrapped SEXP call back to the
                original D function by using the appropriate conversion
                functions or templates.
+/
struct FunctionCall
{
    string origName;
    string resultName;
    bool isVoid;
    string call;
}


/+
    Returns item of type Function call which contains all the information
    from an exported D function required to construct the wrapper function.

    # Arguments
    string moduleName: the name of the module where the function is located
    string item: the name of the function to be exported

    Returns
    FunctionCall containing the information required to construct the 
    wrapper function to interface with R. Form more information, see the
    documentation for the FunctonCall object.
+/
auto getFunctionCall(string moduleName, string item)()
{
    import std.traits: ReturnType, Parameters, ParameterIdentifierTuple;
    
    FunctionCall functionCall;
    mixin("import " ~ moduleName ~ ": " ~ item ~ ";");
    long nArgs = mixin("ParameterIdentifierTuple!" ~ item).length;
    string func_call = item ~ "(";
    alias types = mixin("Parameters!" ~ item);
    bool void_return = mixin("is(ReturnType!" ~ item ~ " == void)");
    static foreach(i, param; mixin("ParameterIdentifierTuple!" ~ item))
    {
      if(i < (nArgs - 1))
      {
        func_call ~= modifyArg!(types[i])(param) ~ ", ";
      }else{
        func_call ~= modifyArg!(types[i])(param);
      }
    }
    func_call ~= ")";
    string resultName = "__d_" ~ item ~ "__";
    if(!void_return)
    {
      func_call = "auto " ~ resultName ~ " = " ~ func_call;
    }
    functionCall = FunctionCall(item, resultName, void_return, func_call);
    return functionCall;
}


/+
    Unit test for getFunctionCall() function
+/
unittest
{
    enum moduleName = "test.files.test_resource_1";
    enum string[] functionNames = ["dot_double", "dot", "create_integer_vector"];
    
    //Testing the function calls:
    
    static assert(FunctionCall("dot_double", "__d_dot_double__", false, 
                        "auto __d_dot_double__ = dot_double(To!(double[])(x), To!(double[])(y))") ==
                        getFunctionCall!(moduleName, functionNames[0]),
                 "Incorrect function call returned for " ~ functionNames[0]);
    
    static assert(FunctionCall("dot", "__d_dot__", false, 
                        "auto __d_dot__ = dot(x_sexp, y_sexp)") ==
                        getFunctionCall!(moduleName, functionNames[1]),
                 "Incorrect function call returned for " ~ functionNames[1]);
    
    static assert(FunctionCall("create_integer_vector", "__d_create_integer_vector__", 
                    false, "auto __d_create_integer_vector__ = create_integer_vector(To!(ulong)(n))") ==
                    getFunctionCall!(moduleName, functionNames[2]),
                 "Incorrect function call returned for " ~ functionNames[2]);
}


/+
    Demos for getFunctionCall demos
+/
mixin template FunctionCallDemo()
{
    auto functionCallDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        pragma(msg, "All the function from the test module: ", items);
        pragma(msg, "Function Call: ", getFunctionCall!(moduleName, items[0]));
        pragma(msg, "Function Call: ", getFunctionCall!(moduleName, items[1]));
        pragma(msg, "Function Call: ", getFunctionCall!(moduleName, items[2]));
    }
}



/+
    Function is basically the vectorization of getSignature() and
    getFunctionCall() functions and returns either Signature[]
    or FunctionCall[] arrays.

    Arguments
    alias func: the template function that takes string moduleName and
                string item.
    string moduleName: name of the module where the items are located
    string[] items: the exported functions from which the objects
                    should be extracted.
    
    Returns
    Entity entity: either Signature, FunctionCall type or some
                    other appropriate type.
+/
auto getEntities(alias func, string moduleName, string[] items)()
{
    import std.traits: ReturnType;
    
    static assert(items.length > 0,
            "Number of items sought is not greater than zero");

    alias func0 = func!(moduleName, items[0]);
    alias Entity = ReturnType!(func0);
    Entity[] entities;
    static foreach(enum string item; items)
    {
        entities ~= func!(moduleName, item);
    }
    return entities;
}



/*
    Unit tests for getEntities function
*/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName)();

    //Test for getting Signature array
    enum signatures = [Signature("dot_double", "__R_dot_double__", 
                                "dot_double", 2L, "SEXP __R_dot_double__(SEXP x, SEXP y)"), 
                        Signature("dot", "__R_dot__", "dot_product", 2L, 
                                "SEXP __R_dot__(SEXP x_sexp, SEXP y_sexp)"), 
                        Signature("create_integer_vector", "__R_create_integer_vector__", 
                                "ivector", 1L, "SEXP __R_create_integer_vector__(SEXP n)")];
    static assert(signatures == getEntities!(getSignature, moduleName, items),
        "The signatures returned from the getEntities (Signatures) function do not match expected calls.");
    
    //Tests for getting function call array
    enum functionCalls = [FunctionCall("dot_double", "__d_dot_double__", false, 
                            "auto __d_dot_double__ = dot_double(To!(double[])(x), To!(double[])(y))"), 
                          FunctionCall("dot", "__d_dot__", false, "auto __d_dot__ = dot(x_sexp, y_sexp)"), 
                          FunctionCall("create_integer_vector", "__d_create_integer_vector__", false, 
                          "auto __d_create_integer_vector__ = create_integer_vector(To!(ulong)(n))")];
    static assert(functionCalls == getEntities!(getFunctionCall, moduleName, items),
        "The function calls returned from the getEntities (FunctionCall) function do not match expected calls.");
}


/+
    Demonstration function for getEntities() function
+/
mixin template GetEntitiesDemo()
{
    void getEntitiesDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        pragma(msg, "Demo for getEntities (Signature): ", getEntities!(getSignature, moduleName, items));
        pragma(msg, "Demo for getEntities (FunctionCall): ", getEntities!(getFunctionCall, moduleName, items));
    }
}


/+
    Function for creating R_CallMethodDef signatures
+/
string createMethodCall(Signature signature)()
{
  //pragma(msg, "nArgs: ", to!(string)(signature.nArgs));
  return "R_CallMethodDef(\".C__" ~ signature.origName ~ "__\", cast(DL_FUNC) &" ~ signature.newName ~ ", " ~ to!(string)(signature.nArgs) ~ ")";
}


/*
    Unit tests for creating the method call strings
*/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName);
    enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    enum string[] rMethodCalls = ["R_CallMethodDef(\".C__dot_double__\", cast(DL_FUNC) &__R_dot_double__, 2)",
                                  "R_CallMethodDef(\".C__dot__\", cast(DL_FUNC) &__R_dot__, 2)",
                                  "R_CallMethodDef(\".C__create_integer_vector__\", cast(DL_FUNC) &__R_create_integer_vector__, 1)"];
    static assert(rMethodCalls[0] == createMethodCall!(signatures[0]), "Failed to create correct method call: " ~ rMethodCalls[0]);
    static assert(rMethodCalls[1] == createMethodCall!(signatures[1]), "Failed to create correct method call: " ~ rMethodCalls[1]);
    static assert(rMethodCalls[2] == createMethodCall!(signatures[2]), "Failed to create correct method call: " ~ rMethodCalls[2]);
}


/*
    Demo for the function createMethodCall
*/
mixin template CreateMethodCallDemo()
{
    void createMethodCallDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
        static foreach(enum signature; signatures)
        {
            pragma(msg, "Signature: ", signature);
            pragma(msg, "Method Call: ", createMethodCall!(signature));
        }
    }
}



/+
    Function to wrap all the method calls for the exported functions
+/
string wrapMethodCalls(Signature[] signatures)()
{
    string result = "  __gshared static const R_CallMethodDef[] callMethods = [\n";
    static foreach(i, signature; signatures)
    {
      result ~= "    " ~ createMethodCall!(signature)() ~ ", \n";
    }
    result ~= "    R_CallMethodDef(null, null, 0)\n";
    result ~= "  ];";
    return result;
}


/+
    Unit test for wrapMethodCalls() function
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName);
    enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    //Do not move the spacing for the string since string comparison occurs here
    enum wrappedMethodCalls = "  __gshared static const R_CallMethodDef[] callMethods = [
    R_CallMethodDef(\".C__dot_double__\", cast(DL_FUNC) &__R_dot_double__, 2), 
    R_CallMethodDef(\".C__dot__\", cast(DL_FUNC) &__R_dot__, 2), 
    R_CallMethodDef(\".C__create_integer_vector__\", cast(DL_FUNC) &__R_create_integer_vector__, 1), 
    R_CallMethodDef(null, null, 0)
  ];";
    static assert(wrappedMethodCalls == wrapMethodCalls!(signatures), "Wrong wrapped method calls returned.");
}


/+
    Demo for wrapMethodCalls() function
+/
mixin template WrapMethodCallsDemo()
{
    void wrapMethodCallsDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    }
}

/*
    wrapFunction() constructs the string for the SEXP wrapped function using
    the respective Signature and FunctionCall objects for the particular
    wrapped function.

    Function runs in compile time.

    Arguments
    Signature signature - the Signature object for the exported function
    FunctionCall functionCall - the FunctionCall object for the exported function

    Returns
    string containing the body of the function ready to be written 
*/
string wrapFunction(Signature signature, FunctionCall functionCall)()
{
    string func = "  \n  {\n";
    func ~= "    " ~ functionCall.call ~ ";\n";
    if(functionCall.isVoid)
    {
      func ~= "    return R_NilValue;\n";
      func ~= "  }\n";
    }else{
      string tmp = "    static if(!isSEXP!(" ~ functionCall.resultName ~ "))\n";
      tmp ~= "    {\n";
      tmp ~= "      return To!(SEXP)(" ~ functionCall.resultName ~ ");\n";
      tmp ~= "    }else{\n";
      tmp ~= "      return " ~ functionCall.resultName ~ ";\n";
      tmp ~= "    }\n";
      func ~= tmp ~ "  }\n";
    }
    func = "  " ~ signature.signature ~ func;
    return func;
}

enum string[] wrappedTestFunctions = [
  "  SEXP __R_dot_double__(SEXP x, SEXP y)  
  {
    auto __d_dot_double__ = dot_double(To!(double[])(x), To!(double[])(y));
    static if(!isSEXP!(__d_dot_double__))
    {
      return To!(SEXP)(__d_dot_double__);
    }else{
      return __d_dot_double__;
    }
  }\n", 
  "  SEXP __R_dot__(SEXP x_sexp, SEXP y_sexp)  
  {
    auto __d_dot__ = dot(x_sexp, y_sexp);
    static if(!isSEXP!(__d_dot__))
    {
      return To!(SEXP)(__d_dot__);
    }else{
      return __d_dot__;
    }
  }\n",
  "  SEXP __R_create_integer_vector__(SEXP n)  
  {
    auto __d_create_integer_vector__ = create_integer_vector(To!(ulong)(n));
    static if(!isSEXP!(__d_create_integer_vector__))
    {
      return To!(SEXP)(__d_create_integer_vector__);
    }else{
      return __d_create_integer_vector__;
    }
  }\n"];



/+
    Unit tests for wrapped functions
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName);
    enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    enum FunctionCall[] functionCalls = getEntities!(getFunctionCall, moduleName, items);

    static foreach(enum i; 0..signatures.length)
    {{
        enum signatureString = wrapFunction!(signatures[i], functionCalls[i]);
        enum staticString = wrappedTestFunctions[i];
        static assert(wrappedTestFunctions[i] == signatureString,
                "Wrong wrapped function body for item " ~ to!(string)(i));
    }}
}



/+
    Demo for wrapFunction() function
+/
mixin template WrapFunctionDemo()
{
    void wrapFunctionDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
        enum FunctionCall[] functionCalls = getEntities!(getFunctionCall, moduleName, items);

        static foreach(enum i; 0..signatures.length)
        {{
            enum signatureString = wrapFunction!(signatures[i], functionCalls[i]);
            enum staticString = wrappedTestFunctions[i];
            pragma(msg, signatureString);
            static assert(wrappedTestFunctions[i] == signatureString,
                    "Wrong wrapped function body for item " ~ to!(string)(i));
        }}
    }
}




/+
    Vectorization of the wrapFunction() function

    Arguments
    Signature[] signatures - array of signatures
    FunctionCall[] functionCalls - array of function calls

    Return
    string array containing the wrapped functions
+/
string[] wrapFunctions(Signature[] signatures, FunctionCall[] functionCalls)()
{
    static assert(signatures.length == functionCalls.length, 
                "Length of signatures and function calls differ");
    string[] funcs;
    static foreach(enum i; 0..signatures.length)
    {
        funcs ~= wrapFunction!(signatures[i], functionCalls[i]);
    }
    return funcs;
}



/+
    Unit tests for wrapFunctions()
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName);
    enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    enum FunctionCall[] functionCalls = getEntities!(getFunctionCall, moduleName, items);
    enum string[] wrappedFunctions = wrapFunctions!(signatures, functionCalls);
    
    static assert(signatures.length == functionCalls.length, "Length of function calls differs for length of signatures");
    static assert(wrappedFunctions == wrappedTestFunctions, "Wrapped functions differ from expected functions.");
}


/+
    Demo for wrapFunctions()
+/
mixin template WrapFunctionsDemo()
{
    void wrapFunctionDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
        enum FunctionCall[] functionCalls = getEntities!(getFunctionCall, moduleName, items);
        enum string[] wrappedFunctions = wrapFunctions!(signatures, functionCalls);
        
        static foreach(wrappedFunction; wrappedFunctions)
        {
            pragma(msg, "Wrapped function output:\n", wrappedFunction);
        }
    }
}



/+
    Function for tailAppend() which writes the relevant load/unload code at the end
    of the script

    Arguments
    string moduleName the name of the module

    Result
    string result the string to be written at the end of the code
+/
string tailAppend(string moduleName)()
{
  string result = "\n\n\n  import core.runtime: Runtime;\n";
  result ~= "  import std.stdio: writeln;\n\n";
  result ~= "  void R_init_" ~ extractShortModuleName!(moduleName) ~ "(DllInfo* info)\n";
  result ~= "  {\n";
  result ~= "    writeln(\"Your saucer module " ~ moduleName ~ " is now loaded!\");\n";
  result ~= "    R_registerRoutines(info, null, callMethods.ptr, null, null);\n";
  result ~= "    Runtime.initialize;\n";
  result ~= "    writeln(\"Runtime has been initialized!\");\n";
  result ~= "  }\n";
  result ~= "  \n";
  result ~= "  \n";
  result ~= "  void R_unload_" ~ extractShortModuleName!(moduleName) ~ "(DllInfo* info)\n";
  result ~= "  {\n";
  result ~= "    writeln(\"Attempting to terminate " ~ moduleName ~ " closing DRuntime!\");\n";
  result ~= "    Runtime.terminate;\n";
  result ~= "    writeln(\"Runtime has been terminated. Goodbye!\");\n";
  result ~= "  }\n";
  return result;
}


/+
    Unit tests for tailAppend() function
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string tailAppendString = "\n\n\n  import core.runtime: Runtime;
  import std.stdio: writeln;

  void R_init_test_resource_1(DllInfo* info)
  {
    writeln(\"Your saucer module " ~ moduleName ~ " is now loaded!\");
    R_registerRoutines(info, null, callMethods.ptr, null, null);
    Runtime.initialize;
    writeln(\"Runtime has been initialized!\");
  }
  
  
  void R_unload_test_resource_1(DllInfo* info)
  {
    writeln(\"Attempting to terminate " ~ moduleName ~ " closing DRuntime!\");
    Runtime.terminate;
    writeln(\"Runtime has been terminated. Goodbye!\");
  }\n";
    static assert(tailAppendString == tailAppend!(moduleName),
            "Output from tailAppend() function wrong");
}



/+
    Demo for tailAppend() function
+/
mixin template TailAppendDemo()
{
    void tailAppendDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string tailAppendString = "\n\n\n  import core.runtime: Runtime;
      import std.stdio: writeln;

      void R_init_test_resource_1(DllInfo* info)
      {
        writeln(\"Your saucer module " ~ moduleName ~ " is now loaded!\");
        R_registerRoutines(info, null, callMethods.ptr, null, null);
        Runtime.initialize;
        writeln(\"Runtime has been initialized!\");
      }
    
    
      void R_unload_test_resource_1(DllInfo* info)
      {
        writeln(\"Attempting to terminate " ~ moduleName ~ " closing DRuntime!\");
        Runtime.terminate;
        writeln(\"Runtime has been terminated. Goodbye!\");
      }\n";
      pragma(msg, "Output from tailAppend() function: ", tailAppend!(moduleName));
    }
}



/+
    Extract the last module name item from the full module name
+/
string extractShortModuleName(string fullModuleName)()
{
    string result;
    foreach_reverse(el; fullModuleName)
    {
        if(el == '.')
        {
            break;
        }else{
            result = el ~ result;
        }
    }
    return result;
}


unittest
{
    enum moduleName = "lib0.lib1.lib2.module0";
    enum string fileName = extractShortModuleName!(moduleName);
    static assert(fileName == "module0", "Wrong module name returned.");
}


/+
    Converts the full module names into file path
+/
string extractFilePath(string fullModuleName)()
{
    string result;
    foreach(char el; fullModuleName)
    {
        if(el == '.')
        {
            result ~= dirSeparator;
        }else{
            result ~= el;
        }
    }
    return result ~ ".d";
}


/* Requires OS specific improvement */


/+
  Function to extract the module name from the file name

  # Arguments
  string moduleName - the name of the module

  # Returns
  string fileName the name of the file from the module name
+/
string extractFileName(string moduleName)()
{
    return extractShortModuleName!(moduleName) ~ ".d";
}



unittest
{
    enum moduleName = "lib0.lib1.lib2.module0";
    enum string fileName = extractFileName!(moduleName);
    static assert(fileName == "module0.d", "Wrong file name returned.");
}

 
/+
    wrapModule() takes the module name and path of a D script and returns
    another D script with the exported D function SEXP wrapped so that they can
    be called from R's C backend.

    Arguments
    string moduleName - the name of the module to be wrapped
    string path - the path to the module to be wrapped

    Returns
    string result containing the new script;
+/
string wrapModule(string moduleName, string path = "")()
{
    enum string[] items = getExportedFunctions!(moduleName);
    enum Signature[] signatures = getEntities!(getSignature, moduleName, items);
    enum FunctionCall[] functionCalls = getEntities!(getFunctionCall, moduleName, items);

    enum string[] funcs = wrapFunctions!(signatures, functionCalls);
    string result = "extern (C)\n{\n";
    static foreach(func; funcs)
    {{
      result ~= func ~ "\n";
    }}
    result ~= wrapMethodCalls!(signatures);
    result ~= tailAppend!(extractShortModuleName!(moduleName)) ~ "}";

    return import(path ~ extractFilePath!(moduleName)) ~ result;
}


//For testing purposes
enum testResource2String = "module test.files.test_resource_2;
import sauced.saucer;


/+
    Multiplies two numbers by each other
+/
@Export() double mult(double x, double y)
{  
    return x*y;
}

extern (C)
{
  SEXP __R_mult__(SEXP x, SEXP y)  
  {
    auto __d_mult__ = mult(To!(double)(x), To!(double)(y));
    static if(!isSEXP!(__d_mult__))
    {
      return To!(SEXP)(__d_mult__);
    }else{
      return __d_mult__;
    }
  }

  __gshared static const R_CallMethodDef[] callMethods = [
    R_CallMethodDef(\".C__mult__\", cast(DL_FUNC) &__R_mult__, 2), 
    R_CallMethodDef(null, null, 0)
  ];


  import core.runtime: Runtime;
  import std.stdio: writeln;

  void R_init_test_resource_2(DllInfo* info)
  {
    writeln(\"Your saucer module test_resource_2 is now loaded!\");
    R_registerRoutines(info, null, callMethods.ptr, null, null);
    Runtime.initialize;
    writeln(\"Runtime has been initialized!\");
  }
  
  
  void R_unload_test_resource_2(DllInfo* info)
  {
    writeln(\"Attempting to terminate test_resource_2 closing DRuntime!\");
    Runtime.terminate;
    writeln(\"Runtime has been terminated. Goodbye!\");
  }
}";


/+
    Unit test for wrapModule() function
+/
unittest
{
    enum string moduleName = "test.files.test_resource_2";
    enum string wrappedModuleString = wrapModule!(moduleName);
    static assert(testResource2String == wrappedModuleString,
            "wrappedModule string does not match expected ouput");
}



/+
    Demo for wrapModule demo
+/
mixin template WrapModuleDemo()
{
    void wrapModuleDemo()
    {
        enum string moduleName = "test.files.test_resource_2";
        enum string wrappedModuleString = wrapModule!(moduleName);
        pragma(msg, "Complete wrap for module name:\n\n", wrappedModuleString);
    }
}




/+
    Contains the details of the exported D function written to R

    Arguments
    string origName - the original name of the D function
    string cName - the .C__ name that will be called in R
    long nArgs - the number of arguments in the function
    string repr - string representation of the function
+/
struct RFunction
{
    string origName;
    string cName;
    long nArgs;
    string repr;
}


/+
    Create RFunction object when given the module name and the function name

    Arguments
    string moduleName - string for the module
    string item - string for the function name

    Result
    RFunction
+/
auto createRFunction(string moduleName, string item)()
{
    import std.traits: Parameters, ParameterIdentifierTuple;

    mixin("import " ~ moduleName ~ ": " ~ item ~ ";");
    enum Signature signature = getSignature!(moduleName, item);

    string fBody = signature.rName ~ " = function(";
    string call = "\n  .Call(\"" ~ signature.newName ~ "\"";
    static foreach(i, param; mixin("ParameterIdentifierTuple!" ~ item))
    {
      if(i < (signature.nArgs - 1))
      {
        fBody ~= param ~ ", ";
        call ~= ", " ~ param;
      }else{
        fBody ~= param;
        call ~= ", " ~ param;
      }
    }
    fBody ~= ")";
    call ~= ")";
    fBody ~= "\n{" ~ call ~ "\n" ~ "}\n";
    return RFunction(item, signature.newName, signature.nArgs, fBody);
}


/+
    The unit tests for createRFunction()
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum string[] items = getExportedFunctions!(moduleName);
    enum RFunction[] rFuncs = [RFunction("dot_double", "__R_dot_double__", 2L, 
                                    "dot_double = function(x, y)\n{\n  .Call(\"__R_dot_double__\", x, y)\n}\n"), 
                                RFunction("dot", "__R_dot__", 2L, 
                                    "dot_product = function(x_sexp, y_sexp)\n{\n  .Call(\"__R_dot__\", x_sexp, y_sexp)\n}\n"), 
                                RFunction("create_integer_vector", "__R_create_integer_vector__", 1L, 
                                    "ivector = function(n)\n{\n  .Call(\"__R_create_integer_vector__\", n)\n}\n")];
    static assert(rFuncs[0] == createRFunction!(moduleName, items[0]), "Incorrect R function returned from createRFunction() for item 0");
    static assert(rFuncs[1] == createRFunction!(moduleName, items[1]), "Incorrect R function returned from createRFunction() for item 1");
    static assert(rFuncs[2] == createRFunction!(moduleName, items[2]), "Incorrect R function returned from createRFunction() for item 2");
}


/+
    Demo function for createRFunction()
+/
mixin template CreateRFunctionDemo()
{
    void createRFunctionDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum string[] items = getExportedFunctions!(moduleName);
        static foreach(item; items)
        {
            pragma(msg, "R function for item: ", item, "\n", createRFunction!(moduleName, item));
        }
    }
}


/+
    Vectorization of createRFunction()

    Arguments
    string moduleName the name of the module

    Returns
    RFunctions[] rFuncs - array of RFunctions
+/
auto createRFunctions(string moduleName)()
{
    import std.traits: Parameters, ParameterIdentifierTuple;
    
    enum string[] items = getExportedFunctions!(moduleName);
    RFunction[] rFuncs;

    static foreach(enum item; items)
    {
        rFuncs ~= createRFunction!(moduleName, item);
    }
    return rFuncs;
}


/+
    The unit test for createRFunctions()
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    enum RFunction[] rFuncs = [RFunction("dot_double", "__R_dot_double__", 2L, 
                                    "dot_double = function(x, y)\n{\n  .Call(\"__R_dot_double__\", x, y)\n}\n"), 
                                RFunction("dot", "__R_dot__", 2L, 
                                    "dot_product = function(x_sexp, y_sexp)\n{\n  .Call(\"__R_dot__\", x_sexp, y_sexp)\n}\n"), 
                                RFunction("create_integer_vector", "__R_create_integer_vector__", 1L, 
                                    "ivector = function(n)\n{\n  .Call(\"__R_create_integer_vector__\", n)\n}\n")];
    static assert(rFuncs == createRFunctions!(moduleName), "Incorrect R function returned from the createRFunctions() function");
}



/+
    Demo for createRFunctions()
+/
mixin template CreateRFunctionsDemo()
{
    void createRFunctionsDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        enum RFunction[] rFuncs = createRFunctions!(moduleName);
        pragma(msg, "RFunction[] returned: ", rFuncs);
    }
}



/+
    Creates R script that is the interface with the module

    Arguments
    string moduleName - the name of the module

    Returns
    string code - ready to be written to file
+/
auto createRScript(string moduleName)()
{
    enum RFunction[] rFuncs = createRFunctions!(moduleName);
    string code = "dyn.load(\"" ~ extractShortModuleName!(moduleName) ~ ".so\")\n\n";
    static foreach(rFunc; rFuncs)
    {
        code ~= rFunc.repr ~ "\n";
    }
    return code;
}


//Variable for the unit test below
enum string testRScript = "dyn.load(\"test_resource_1.so\")

dot_double = function(x, y)
{
  .Call(\"__R_dot_double__\", x, y)
}

dot_product = function(x_sexp, y_sexp)
{
  .Call(\"__R_dot__\", x_sexp, y_sexp)
}

ivector = function(n)
{
  .Call(\"__R_create_integer_vector__\", n)
}\n\n";


/+
    unit tests for createRScript!(moduleName)
+/
unittest
{
    enum string moduleName = "test.files.test_resource_1";
    static assert(testRScript == createRScript!(moduleName));
}


/+
    demo for function createRScript!(moduleName)
+/
mixin template CreateRScriptDemo()
{
    void createRScriptDemo()
    {
        enum string moduleName = "test.files.test_resource_1";
        pragma(msg, "Create R scripts:\n", createRScript!(moduleName));
    }
}




/+
    This creates the main function that writes and compiles the module
+/
mixin template Saucerize(string moduleName)
{
    void translate()
    {
        import std.stdio: File, writeln;
        import std.file: copy, mkdir, exists, isDir;
        import std.process: execute, executeShell;

        enum fileName = extractShortModuleName!(moduleName);
        //Write the wrapped module
        File(fileName ~ ".d", "w").writeln(wrapModule!(moduleName)());
        //Write the R script wrapper
        File(fileName ~ ".r", "w").writeln(createRScript!(moduleName));
        
        return;
    }
    void saucerize()
    {
        import std.stdio: File, writeln;
        import std.file: copy, mkdir, exists, isDir;
        import std.process: execute, executeShell;

        enum fileName = extractShortModuleName!(moduleName);
        File(fileName ~ ".d", "w").writeln(wrapModule!(moduleName)());
        enum dllFile = fileName ~ ".so";
        enum commands = "dmd " ~ fileName ~ ".d saucer.d r2d.d -O -boundscheck=off -mcpu=native -c -g -J=\".\" -fPIC -L-fopenmp -L-lR -L-lRmath && " ~
                        "dmd " ~ fileName ~ ".o saucer.o r2d.o -O -boundscheck=off -mcpu=native -of=" ~ dllFile ~ " -L-fopenmp -L-lR -L-lRmath -shared";
        auto ls = executeShell(commands);
        if(ls.status != 0)
        {
            writeln("Command:\n" ~ commands ~ "\nNot run.");
        }else
        {
            writeln(ls.output);
        }

        File(fileName ~ ".r", "w").writeln(createRScript!(moduleName));
        return;
    }
    
    void main()
    {
        try
        {
            translate();
        }
        catch(Exception e)
        {
            writeln("Exception output: ", e);
        }
    }
}



/*
    Pass module name at command line like this:
    echo 'enum moduleName = "test_resource_1";' | dmd files to compile.d

    # Source:
    # https://forum.dlang.org/post/mailman.575.1636047390.11670.digitalmars-d-learn@puremagic.com
*/
version(unittest)
{
    //Don't want main to be written for unit tests
}else{
    import __stdin: moduleName;
    mixin Saucerize!(moduleName);
}
