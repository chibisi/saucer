struct Function
{
    private SEXP func;
    private SEXP envir;
    private bool needUnprotect = false;
    
    this(SEXP func) @trusted
    {
        enforce(Rf_isFunction(func), 
                "input given is not a function");
        this.func = func;
        this.envir = CLOENV(func);
    }
    this(Function fn) @trusted
    {
        this.func = fn.func;
        this.envir = fn.envir;
    }
    this(E)(SEXP func, E envir) @trusted
    if(isSEXP!(E) || is(E == Environment))
    {
        enforce(Rf_isFunction(func), 
                "input given is not a function");
        static if(isSEXP!(E))
        {
            enforce(Rf_isEnvironment(envir), 
                "second item given is not an environment");
            this.envir = envir;
        }else{
            this.envir = envir.envir;
        }
        this.func = func;
    }
    @property auto env(E)(E envir) @trusted
    if(isSEXP!(E) || is(E == Environment))
    {
        static if(isSEXP!(E))
        {
            enforce(Rf_isEnvironment(envir), 
                "second item given is not an environment");
            this.envir = envir;
        }else{
            this.envir = envir.envir;
        }
        return;
    }
    ~this() @trusted
    {
        if(this.needUnprotect)
        {
            R_ReleaseObject(func);
            this.needUnprotect = false;
        }
    }
    pragma(inline, true)
    SEXP opCast(T: SEXP)() @trusted
    {
        return this.func;
    }
    auto opCall(Args...)(Args args) @trusted
    if((Args.length >= 1) && ForTypes!(isConvertibleToOrIsSEXP, "all", Args))
    {
        enum nargs = Args.length;
        SEXP call, arg;
        call = protect(allocVector(LANGSXP, cast(int)(nargs + 1)));
        scope(exit) unprotect(1);
        SETCAR(call, this.func);
        SEXP tmp = call;
        static foreach(i; 0..nargs)
        {{
            static if(isConvertibleTo!(Args[i], SEXP, To))
            {
                arg = protect(To!(SEXP)(args[i]));
                scope(exit) unprotect(1);
            }else{
                arg = args[i];
            }
            tmp = CDR(tmp);
            SETCAR(tmp, arg);
        }}
        return eval(call, this.envir);
    }
    auto opCall(Args...)(Args args) @trusted
    if((Args.length == 0))
    {
        enum nargs = Args.length;
        SEXP call, arg;
        call = protect(allocVector(LANGSXP, cast(int)(nargs + 1)));
        scope(exit) unprotect(1);
        SETCAR(call, this.func);
        return eval(call, this.envir);
    }
    static auto init(S)(S functionString) @trusted
    if(is(S == string) || isSEXP!(S))
    {
        Function result;
        static if(isSEXP!(S))
        {
            enforce(isString(functionString), "SEXP entered is not a string");
            auto strPtr = CHAR(Accessor!(STRSXP)(functionString)[0]);
            result.func = R_ParseEvalString(strPtr, R_GlobalEnv);
            R_PreserveObject(result.func);
            result.envir = R_GlobalEnv;
            result.needUnprotect = true;
        }else{
            auto strPtr = toUTFz!(const(char)*)(functionString);
            result.func = R_ParseEvalString(strPtr, R_GlobalEnv);
            R_PreserveObject(result.func);
            result.envir = R_GlobalEnv;
            result.needUnprotect = true;
        }
        return result;
    }
}

