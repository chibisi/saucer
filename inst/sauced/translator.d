module sauced.translator;

import sauced.saucer;
import std.conv: to;
import std.traits: getUDAs, ReturnType;
import std.algorithm.iteration: map;
import std.stdio: writeln;
import std.path: dirSeparator;
import std.format: format;
import std.algorithm: map;

/*
    TODO
    
    1. Use format(...) rather than messy string ~= string concats - much easier!
    2. Probably don't need resultName in FunctionCall object
*/



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
        /*
            Possibility exists to restrict to functions
        */
        static if(false)
        {
            import std.traits: isSomeFunction;
            pragma(msg, item, ", is a function? ", mixin("isSomeFunction!(" ~ item ~ ")"));
        }
        
        //Select if there are attributes in the item
        static if(__traits(compiles, __traits(getAttributes, mixin(item)).length > 0))
        {
            static if(__traits(getAttributes, mixin(item)).length > 0)
            {
                //Iterating over the attributes
                static foreach(attr; __traits(getAttributes, mixin(item)))
                {{
                    //Filters for the export attribute
                    static if(is(typeof(attr) == Export) || is(attr == Export))
                    {
                        result ~= item;
                    }
                }}
            }
        }
    }
    assert(result.length > 0, "Number of exported items is zero please check that you are exporting functions");
    return result;
}



/+
    Compile time function creates the Signature object when 
    supplied with the module name and the function as a string
+/
auto getSignature(string moduleName, string item)()
{
    import std.traits: ParameterIdentifierTuple;

    //Import the function name
    mixin(format(`import %1$s: %2$s;`, moduleName, item));
    //Filters if the attribute is Export
    mixin(format(`alias attr = getUDAs!(%1$s, Export)[0];`, item));
    
    static if(is(attr == Export))
    {
        enum rName = item;
    }
    else static if(attr.function_name == "")
    {
        enum rName = item;
    }
    else
    {
        enum rName = attr.function_name;
    }
    
    enum newName = format("__R_%1$s__", item);
    alias parameterTuple = mixin(format("ParameterIdentifierTuple!%1$s", item));
    long nArgs = parameterTuple.length;
    auto parameters(string name, string[] arr...) => 
            format("SEXP %s", name) ~ format("(%-(SEXP %s, %))", arr);
    enum funcSignature = parameters(newName, parameterTuple);
    
    return Signature(item, newName, rName, nArgs, funcSignature);
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
    mixin(format(`import %1$s: %2$s;`, moduleName, item));
    alias parameterTuple = mixin(format("ParameterIdentifierTuple!%1$s", item));
    long nArgs = parameterTuple.length;
    alias types = mixin(format("Parameters!%1$s", item));
    enum void_return = mixin(format("is(ReturnType!%1$s == void)", item));
    string[] toArray(string[] args...) => args.dup;
    enum resultName = format("__d_%1$s__", item);
    static if(void_return)
    {
      enum funcCall = format("%1$s(%2$s)", item, ModifyArg!(toArray(parameterTuple), types));
    }else{
        enum tmp = format("%1$s(%2$s)", item, ModifyArg!(toArray(parameterTuple), types));
        enum funcCall = format("auto %1$s = %2$s", resultName, tmp);
    }
    functionCall = FunctionCall(item, resultName, void_return, funcCall);
    return functionCall;
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
auto createMethodCall(Signature signature)
{
    auto origName = signature.origName;
    auto newName = signature.newName;
    auto nArgs = to!(string)(signature.nArgs);
    return format("R_CallMethodDef(\".C__%1$s__\", cast(DL_FUNC) &%2$s, %3$s)", origName, newName, nArgs);
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
            pragma(msg, "Method Call: ", createMethodCall(signature));
        }
    }
}


template MapReduce(alias arr, alias MapFun, alias ReduceFun)
{
    alias A = typeof(arr);
    static if(is(A: E[], E))
    {
        static if(arr.length == 1)
        {
            enum MapReduce = MapFun(arr[0]);
        }else{
            enum MapReduce = ReduceFun(MapFun(arr[0]), MapReduce!(arr[1..$], MapFun, ReduceFun));
        }
    }
    else
    {
        static assert(0, format("Can not apply map to type: %s", typeof(arr).stringof));
    }
}




/+
    Function to wrap all the method calls for the exported functions
+/
auto wrapMethodCalls(Signature[] signatures)()
{
    auto MapFun(Signature signature)
    {
        return format("%1$s, \n", createMethodCall(signature));
    }
    alias ReduceFun = (x, y) => format("%1$s %2$s", x, y);
    enum tmp = MapReduce!(signatures,
                    MapFun,
                        ReduceFun);
    enum result = format("__gshared static const R_CallMethodDef[] callMethods = 
    [
        %1$s
        R_CallMethodDef(null, null, 0)
    ];", tmp);
   return result;
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

    Note:
    
    1. There is a case for using writeln rather then Rf_error() here.
        writeln does not require a cast.
*/
string wrapFunction(Signature signature, FunctionCall functionCall)()
{
    enum functionSignature = signature.signature;
    enum funcCall = functionCall.call;
    static if(functionCall.isVoid)
    {
        return format(`
    %1$s
    {
        try
        {
            %2$s;
        }catch(Exception exception)
        {
            const(char*) msg = toUTFz!(const(char)*)(exception.msg);
            Rf_error(msg);
        }
        return R_NilValue;
    }
        `,functionSignature, funcCall);
    }else{
        enum resultName = functionCall.resultName;
        return format(`
    %1$s
    {
        try
        {
            %2$s;
            static if(!isSEXP!(%3$s))
            {
                return To!(SEXP)(%3$s);
            }else{
                return %3$s;
            }
        }catch(Exception exception)
        {
            const(char*) msg = toUTFz!(const(char)*)(exception.msg);
            Rf_error(msg);
            return R_NilValue;
        }
    }
      `,functionSignature, funcCall, resultName);
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
    enum tmp = extractShortModuleName!(moduleName);
    return format(`
    import core.runtime: Runtime;
    void R_init_%1$s (DllInfo* info)
    {
        import std.stdio: writeln;
        writeln("Your saucer module %2$s is now loaded!");
        R_registerRoutines(info, null, callMethods.ptr, null, null);
        Runtime.initialize;
        writeln("Runtime has been initialized!");
    }

    void R_unload_%1$s(DllInfo* info)
    {
        import std.stdio: writeln;
        writeln("Attempting to terminate %2$s closing DRuntime!");
        Runtime.terminate;
        writeln("Runtime has been terminated. Goodbye!");
    }
    `, tmp, moduleName);
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
    return format("%1$s.d", extractShortModuleName!(moduleName));
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
    auto mapFun(string element)
    {
        return format("%1$s\n", element);
    }
    enum signatureString = MapReduce!(funcs, mapFun, (x, y) => format("%1$s %2$s", x, y));
    enum methodCallString = wrapMethodCalls!(signatures);
    enum tailString = tailAppend!(extractShortModuleName!(moduleName));
    enum codeBody = format(
`
extern (C)
{
    import std.utf: toUTFz;
    %1$s
    %2$s
    %3$s
}
`, signatureString, methodCallString, tailString);
    
    return import(path ~ extractFilePath!(moduleName)) ~ codeBody;
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

    mixin(format("import %1$s: %2$s;", moduleName, item));
    enum Signature signature = getSignature!(moduleName, item);
    alias parameterTuple = mixin(format("ParameterIdentifierTuple!%1$s", item));
    
    auto parameters(string name, string[] arr...) => 
            format("%1$s", name) ~ format(" = function(%-(%s, %))", arr);
    enum funcSignature = parameters(signature.rName, parameterTuple);
    static if(signature.nArgs >= 1)
    {
        auto call(string newName, string shortName, string[] arr...) => 
            format(`.Call("%1$s", PACKAGE = "%2$s", `, newName, shortName) ~ format("%-(%s, %))", arr);
    }
    else
    {
        auto call(string newName, string shortName, string[] arr...) => 
            format(`.Call("%1$s", PACKAGE = "%2$s")`, newName, shortName);
    }
    enum callSignature = call(signature.newName, extractShortModuleName!(moduleName), parameterTuple);
    
    enum fBody = format(
    `
%1$s
{
    %2$s
}
    `, funcSignature, callSignature);
    
    return RFunction(item, signature.newName, signature.nArgs, fBody);
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
    alias MapFun = (RFunction functionRepresentation) => format("%1$s\n", functionRepresentation.repr);
    alias ReduceFun = (x, y) => format("%1$s %2$s", x, y);
    enum code = format("%1$s\n\n%2$s",
                    format("dyn.load(\"%1$s.so\")", extractShortModuleName!(moduleName)),
                        MapReduce!(rFuncs, MapFun, ReduceFun));
    
    return code;
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
