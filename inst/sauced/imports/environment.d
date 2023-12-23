import std.stdio: writeln;

alias NamespaceEnvSpec = R_NamespaceEnvSpec;
alias FindPackageEnv = R_FindPackageEnv;

alias GetCurrentEnv = R_GetCurrentEnv;
alias NewEnv = R_NewEnv;
alias IsPackageEnv = R_IsPackageEnv;
alias PackageEnvName = R_PackageEnvName;
alias IsNamespaceEnv = R_IsNamespaceEnv;
alias LockEnvironment = R_LockEnvironment;
alias EnvironmentIsLocked = R_EnvironmentIsLocked;
alias LockBinding = R_LockBinding;
alias unLockBinding = R_unLockBinding;
alias MakeActiveBinding = R_MakeActiveBinding;
alias BindingIsLocked = R_BindingIsLocked;
alias BindingIsActive = R_BindingIsActive;
alias ActiveBindingFunction = R_ActiveBindingFunction;

alias GlobalEnv = R_GlobalEnv;
alias EmptyEnv = R_EmptyEnv;
alias BaseEnv = R_BaseEnv;




auto assertSymbol(string symbol)()
{
    return "enforce(isSymbol(" ~ symbol ~ "), " ~ 
                "\"Type of symbol is not a SYMSXP\");";
}
auto assertSymbolOrString(string symbol)()
{
    return "enforce(isSymbol(" ~ symbol ~ ") || Rf_isString(" ~ symbol ~ "), " ~ 
                "\"Type of symbol is not a SYMSXP\");";
}

auto assertFunction(string symbol)()
{
    return "enforce(isFunction(" ~ symbol ~ "), " ~ 
                "\"Type of symbol is not a SEXP function\");";
}

/*
    Copying environments doesn't make sense
    so definitely use reference counting here.
*/
private struct Environment
{
    SEXP envir;
    alias envir this;
    bool needUnprotect = false;
    @disable this();
    this(SEXP envir)
    {
        this.envir = envir;
    }
    this(I)(I size)
    if(isIntegral!I)
    {
        enforce(size > 0, "Given size must be greater than zero");
        this.envir = protect(R_NewEnv(R_GlobalEnv, TRUE, cast(int)size));
        needUnprotect = true;
    }
    ~this()
    {
        if(needUnprotect)
        {
            unprotect_ptr(this.envir);
            needUnprotect = false;
        }
    }
    pragma(inline, true)
    SEXP opCast(T: SEXP)()
    {
        return this.envir;
    }
    static Environment baseEnv()
    {
        return Environment(R_BaseEnv);
    }
    static Environment globalEnv()
    {
        return Environment(R_GlobalEnv);
    }
    static Environment emptyEnv()
    {
        return Environment(R_EmptyEnv);
    }
    static Environment getCurrentEnvironment()
    {
        auto result = Environment(R_GetCurrentEnv());
        return result;
    }
    void lockEnvironment(Rboolean bindings = FALSE)
    {
        R_LockEnvironment(this.envir, bindings);
    }
    Rboolean isLocked()
    {
        return R_EnvironmentIsLocked(this.envir);
    }
    /*
        Locks the binding of the environment
        symbol is a string or a an EXP that is a string
    */
    void lockBinding(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            R_LockBinding(symbol, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            R_LockBinding(_symbol_, this.envir);
        }
    }
    void unlockBinding(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            R_unLockBinding(symbol, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            R_unLockBinding(_symbol_, this.envir);
        }
    }
    void makeActiveBinding(S, F)(S symbol, F func)
    if((is(S == SEXP) || is(S == string)) && 
            (is(F == SEXP) || is(F == Function)))
    {
        static if(is(F == SEXP))
        {
            mixin(assertFunction!(func.stringof));
        }
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            R_MakeActiveBinding(symbol, func, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            R_MakeActiveBinding(_symbol_, func, this.envir);
        }
    }
    Rboolean isBindingLocked(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            return R_BindingIsLocked(symbol, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            return R_BindingIsLocked(_symbol_, this.envir);
        }
    }
    Rboolean isBindingActive(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            return R_BindingIsActive(symbol, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            return R_BindingIsActive(_symbol_, this.envir);
        }
    }
    SEXP getActiveBindingFunction(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            return R_ActiveBindingFunction(symbol, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            auto func = R_ActiveBindingFunction(_symbol_, this.envir);
            return Function(func, CLOENV(func));
        }
    }
    Rboolean isNamespaceEnv()
    {
        return R_IsNamespaceEnv(this.envir);
    }
    pragma(inline, true)
    string packageEnvName()
    {
        return getSEXP!(STRSXP)(R_PackageEnvName(this.envir), 0);
    }
    Rboolean isPackageEnv()
    {
        return R_IsPackageEnv(this.envir);
    }
    void assign(S, O)(S symbol, O obj)
    if((is(S == SEXP) || is(S == string)) && (is(O == SEXP) || (isRType!O)))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            Rf_defineVar(symbol, obj, this.envir);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            Rf_defineVar(_symbol_, obj, this.envir);
        }
    }
    SEXP get(S)(S symbol)
    if(is(S == SEXP) || is(S == string))
    {
        static if(is(S == SEXP))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            return Rf_findVarInFrame(this.envir, symbol);
        }else
        {
            SEXP _symbol_ = installChar(mkChar(symbol));
            return Rf_findVarInFrame(this.envir, _symbol_);
        }
    }
}




