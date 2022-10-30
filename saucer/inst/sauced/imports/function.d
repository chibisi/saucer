struct Function
{
    SEXP func;
    SEXP envir;
    alias implicitCast this;
    
    pragma(inline, true)
    SEXP opCast(T: SEXP)()
    {
        return this.func;
    }
    
    this(SEXP func)
    {
        assert(Rf_isFunction(func), 
                "input given is not a function");
        this.func = func;
        this.envir = R_GlobalEnv; //R_GetCurrentEnv();
    }
    this(SEXP func, SEXP envir)
    {
        assert(Rf_isFunction(func), 
                "input given is not a function");
        assert(Rf_isEnvironment(envir), 
                "second item given is not an environment");
        this.func = func;
        this.envir = envir;
    }
    this(Function fn)
    {
        this.func = fn.func;
        this.envir = fn.envir;
    }
    
    auto opCall(Args...)(Args args)
    {
        enum nargs = Args.length;
        SEXP call, arg;
        protect(call = allocVector(LANGSXP, cast(int)(nargs + 1)));
        SETCAR(call, this.func);
        SEXP tmp = call;
        int nProtect = 1;
        static foreach(i; 0..nargs)
        {
            static if(!(is(Args[i] == SEXP) || isRType!(Args[i])))
            {
                arg = protect(To!(SEXP)(args[i]));
                ++nProtect;
            }else{
                arg = args[i];
            }
            tmp = CDR(tmp);
            SETCAR(tmp, arg);
        }
        auto result = eval(call, this.envir);
        unprotect(nProtect);
        return result;
    }
    pragma(inline, true)
    SEXP implicitCast()
    {
      return opCast!(SEXP)();
    }
}

