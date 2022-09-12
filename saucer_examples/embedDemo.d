import sauced.saucer;

import sauced.r2d;
import sauced.rinside.rembedded: Rf_initEmbeddedR, setup_Rmainloop, R_ReplDLLinit, Rf_endEmbeddedR;
import sauced.rinside.rinterface: Rf_mainloop, ptr_R_WriteConsole;

import std.stdio: stdout, stdin, readln, readf, write, writeln;


auto toCString(string _string_)
{
    char[] charArr = cast(char[])_string_;
    charArr ~= '\0';
    return charArr.ptr;
}

auto fromCString(char* _cstring_)
{
    string result;
    char tmp;
    int i = 0;
    while(tmp != '\0')
    {
        tmp = _cstring_[i];
        result ~= tmp;
        ++i;
    }
    return result;
}

//The R flags in the process
enum rFlags = ["R", "--interactive", "--no-save", "--no-restore", "--no-site-file",
			"--no-init-file", "--no-environ"];


auto WriteConsole(string _commands_)
{
    auto cstring = toCString(_commands_ ~ "\n");
    ptr_R_WriteConsole(cstring, cast(int)_commands_.length);
    return;
}

/*
  Try an eval parse
*/
auto parseEvalString(string command, bool writeCommand = false)
{
    if(writeCommand)
    {
        WriteConsole("> " ~ command);
    }
    
    SEXP result = R_ParseEvalString(toCString(command), R_GlobalEnv);
    Rf_PrintValue(result);
    return;
}

/*
  Function to demo rembedded functionality. For more information see test examples:
  https://github.com/wch/r-source/tree/trunk/tests/Embedding
*/
auto testEmbed()
{
    char*[] args;
    foreach(arg; rFlags)
    {
        args ~= toCString(arg);
    }
    
    int init = Rf_initEmbeddedR(cast(int)rFlags.length, args.ptr);

    int n = 5;
    auto result = RVector!(REALSXP)(n);
    foreach(i; 0..n)
    {
        result[i] = 2.0*(i*i);
    }
    result.unprotect;

    parseEvalString("runif(100)");
    

    //Mini R repl demo taking in two lines ...
    string command;
    foreach(i; 0..2)
    {
        stdout.write("> ");
        command = stdin.readln();
        parseEvalString(command);
    }
    
    result.Rf_PrintValue;
    Rf_endEmbeddedR(0);

    return result;
}


/*
    dmd script.d "sauced/saucer.d" "sauced/r2d.d" "sauced/rinside/rembedded.d" -O -fPIC -L-lR -L-lRmath -boundscheck=on -mcpu=native -J="sauced" && ./script
*/

void main()
{
    auto result = testEmbed();
    writeln("Result output: ", result);
}


