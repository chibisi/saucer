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


private auto assertSymbolOrString(string symbol)()
{
    return format("enforce(isSymbol(%1$s) || Rf_isString(%1$s), " ~ 
                "\"Type of symbol is not a SYMSXP or a string\");", symbol);
}

private auto assertFunction(string symbol)()
{
    return format(`enforce(isFunction(%1$s), ` ~ 
                `"Type of symbol is not a SEXP function");`, symbol);
}

/*
    Copying environments doesn't make senseprivate 
    so definitely use reference counting here.
*/
struct Environment
{
    private SEXP envir;
    private bool needUnprotect = false;
    this(SEXP envir) @trusted
    {
        enforce(cast(bool)isEnvironment(envir),
            "Submitted SEXP is not an environment");
        this.envir = envir;
    }
    this(I)(I size) @trusted
    if(isIntegral!I)
    {
        enforce(size > 0, "Given size must be greater than zero");
        this.envir = R_NewEnv(R_GlobalEnv, TRUE, cast(int)size);
        R_PreserveObject(this.envir);
        needUnprotect = true;
    }
    static auto init(int n = 29) @trusted
    {
        return Environment(n);
    }
    ~this()
    {
        if(needUnprotect)
        {
            R_ReleaseObject(this.envir);
            needUnprotect = false;
        }
    }
    pragma(inline, true)
    SEXP opCast(T: SEXP)() @trusted
    {
        return this.envir;
    }
    static Environment baseEnv() @trusted
    {
        return Environment(R_BaseEnv);
    }
    static Environment globalEnv() @trusted
    {
        return Environment(R_GlobalEnv);
    }
    static Environment emptyEnv() @trusted
    {
        return Environment(R_EmptyEnv);
    }
    static Environment getCurrentEnvironment() @trusted
    {
        auto result = Environment(R_GetCurrentEnv());
        return result;
    }
    void lockEnvironment(R)(R bindings = cast(R)FALSE) @trusted
    if(is(R == Rboolean) || is(R == int) || is(R == bool))
    {
        static if(is(R == Rboolean))
        {
            R_LockEnvironment(this.envir, bindings);
        }else{
            R_LockEnvironment(this.envir, Rboolean(bindings));
        }
        return;
    }
    auto isLocked() @trusted
    {
        return cast(bool)R_EnvironmentIsLocked(this.envir);
    }
    /*
        Locks the binding of the environment
        symbol is a string or a an EXP that is a string
    */
    void lockBinding(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                R_LockBinding(installChar(asChar(symbol)), this.envir);
            }else{
                R_LockBinding(symbol, this.envir);
            }
        }else
        {
            R_LockBinding(installChar(mkChar(symbol)), this.envir);
        }
        return;
    }
    void unlockBinding(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                R_unLockBinding(installChar(asChar(symbol)), this.envir);
            }else{
                R_unLockBinding(symbol, this.envir);
            }
        }else
        {
            R_unLockBinding(installChar(mkChar(symbol)), this.envir);
        }
        return;
    }
    void makeActiveBinding(S, F)(S symbol, F func) @trusted
    if((isSEXP!(S) || is(S == string)) && 
            (isSEXP!(F) || is(F == Function)))
    {
        SEXP _symbol_, _func_;
        int nProtect = 0;
        static if(isSEXP!(F))
        {
            mixin(assertFunction!(func.stringof));
            _func_ = func;
        }else{
            _func_ = func.func;
        }
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                _symbol_ = protect(installChar(asChar(symbol)));
                ++nProtect;
            }
            else
            {
                _symbol_ = symbol;
            }
        }else{
            _symbol_ = protect(installChar(mkChar(symbol)));
            ++nProtect;
        }
        R_MakeActiveBinding(_symbol_, _func_, this.envir);
        if(nProtect > 0)
        {
            unprotect(nProtect);
        }
        return;
    }
    bool isBindingLocked(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                return cast(bool)R_BindingIsLocked(installChar(asChar(symbol)), this.envir);
            }else{
                return cast(bool)R_BindingIsLocked(symbol, this.envir);
            }
        }else
        {
            return cast(bool)R_BindingIsLocked(installChar(mkChar(symbol)), this.envir);
        }
    }
    auto isBindingActive(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                return cast(bool)R_BindingIsActive(installChar(asChar(symbol)), this.envir);
            }else{
                return cast(bool)R_BindingIsActive(symbol, this.envir);
            }
        }else
        {
            return cast(bool)R_BindingIsActive(installChar(mkChar(symbol)), this.envir);
        }
    }
    auto getActiveBindingFunction(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                return R_ActiveBindingFunction(installChar(asChar(symbol)), this.envir);
            }else{
                return R_ActiveBindingFunction(symbol, this.envir);
            }
        }else
        {
            return R_ActiveBindingFunction(installChar(mkChar(symbol)), this.envir);
        }
    }
    auto isNamespaceEnv() @trusted
    {
        return cast(bool)R_IsNamespaceEnv(this.envir);
    }
    pragma(inline, true)
    string packageEnvName() @trusted
    {
        return getSEXP!(STRSXP)(R_PackageEnvName(this.envir), 0);
    }
    auto isPackageEnv() @trusted
    {
        return cast(bool)R_IsPackageEnv(this.envir);
    }
    void assign(S, O)(S symbol, auto ref O value) @trusted
    if((isSEXP!(S) || is(S == string)) && (isSEXP!(O) || isConvertibleToSEXP!(O)))
    {
        int nProtect = 0;
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            SEXP _symbol_;
            if(isString(symbol))
            {
                _symbol_ = protect(installChar(asChar(symbol)));
                ++nProtect;
            }else{
                _symbol_ = symbol;
            }
            static if(isSEXP!(O))
            {
                Rf_defineVar(_symbol_, value, this.envir);
            }else{
                Rf_defineVar(_symbol_, To!(SEXP)(value), this.envir);
            }
        }else
        {
            static if(isSEXP!(O))
            {
                Rf_defineVar(installChar(mkChar(symbol)), value, this.envir);
            }else{
                Rf_defineVar(installChar(mkChar(symbol)), To!(SEXP)(value), this.envir);
            }
        }
        if(nProtect > 0)
        {
            unprotect(nProtect);
        }
        return;
    }
    SEXP get(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        static if(isSEXP!(S))
        {
            mixin(assertSymbolOrString!(symbol.stringof));
            if(isString(symbol))
            {
                return Rf_findVarInFrame(this.envir, installChar(asChar(symbol)));
            }else{
                return Rf_findVarInFrame(this.envir, symbol);
            }
        }else
        {
            return Rf_findVarInFrame(this.envir, installChar(mkChar(symbol)));
        }
    }
    auto opIndex(S)(S symbol) @trusted
    if(isSEXP!(S) || is(S == string))
    {
        return this.get(symbol);
    }
    auto opIndexAssign(O, S)(auto ref O value, S symbol) @trusted
    if((isSEXP!(S) || is(S == string)) && (isSEXP!(O) || isConvertibleToSEXP!(O)))
    {
        this.assign(symbol, value);
        return;
    }
}




