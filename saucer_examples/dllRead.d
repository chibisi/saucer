/*
    To read dll functions from a file compiled in D
*/
import std.traits: Unqual, isCallable;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.sys.posix.dlfcn;
import std.stdio: writeln;


string asString(C)(C _string_)
if(is(Unqual!(C) == char*) && !is(C == string))
{
    pragma(msg, "Unqual!(C): ", Unqual!(C));
    int i = 0;
    while(_string_[i] != '\0')
    {
        ++i;
    }
    return cast(string)_string_[0..(i + 1)];
}

const(char)* asConstChar(string _string_)
{
    auto n = _string_.length;
    const(char)[] tmp = _string_[0..n];
    tmp ~= '\0';
    return &tmp[0];
}


auto dllLoad(Signature)(string fileName, string funcName)
if(isCallable!(Signature))
{
    writeln("Debug point 1");
    void* dllFile = dlopen("yspegbmalz/script.so", RTLD_LAZY);
    assert(dllFile, "dlopen error for file " ~ fileName);
    writeln("Debug point 2");

    Signature func = cast(Signature)dlsym(dllFile, "timesTwo");
    writeln("Debug point 3");
    char* error = dlerror();
    writeln("Debug point 4");
    //assert(error, "dlsym error: " ~ asString(error));
    if (error)
    {
        fprintf(stderr, "dlsym error: %s\n", error);
        exit(1);
    }
    writeln("Debug point 5");
    //dlclose(dllFile);
    
    writeln("Debug point 6");
    writeln("Calling the function before returning: ", func(3.0));
    writeln("Debug point 7");
    
    return func;
}

auto dllDLoad()
{
    //import core.sys.posix.dlfcn;
    //import core.runtime: rt_init, rt_term, rt_loadLibrary, rt_unloadLibrary;
    import core.runtime: Runtime;
    //rt_init();
    //Runtime.initialize();
    void* lib = Runtime.loadLibrary("yspegbmalz/script.so");
    auto func = cast(fType)dlsym(lib, "timesTwo");
    writeln("timesTwo(3.2): ", func(3.2));
    Runtime.unloadLibrary(lib);
    //Runtime.terminate();
    //rt_term();
}

alias fType = extern(C) double function(double);

void main()
{
    string filePath = "yspegbmalz/script.so";
    auto func = dllLoad!(fType)(filePath, "timesTwo");
    writeln("func(3.5): ", func(3.5));
    //dllDLoad();
}
