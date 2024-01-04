struct XPtr(T)
{
    import std.traits: isCallable, isPointer, ReturnType;
    private SEXP extptr;
    private bool needUnprotect = false;

    this(P, S = SEXP)(P ptr, S tag = R_NilValue, SEXP prot = R_NilValue)
    if(((isPointer!(P) && is(P: T*)) || isSEXP!(P)) && (isSEXP!(S) || is(S == string)))
    {
        static if(isSEXP!(P))
        {
            enforce(TYPEOF(ptr) == EXTPTRSXP, "Submitted non-EXTPTRSXP type to XPtr constructor");
            this.extptr = ptr;
        }
        else
        {
            static if(isSEXP!S)
            {
                if(isString(tag))
                {
                    this.extptr = R_MakeExternalPtr(cast(void*) ptr, installChar(asChar(tag)), prot);
                }
                else
                {
                    this.extptr = R_MakeExternalPtr(cast(void*) ptr, tag, prot);
                }
            }
            else
            {
                this.extptr = R_MakeExternalPtr(cast(void*) ptr, installChar(mkChar(tag)), prot);
            }
            R_PreserveObject(this.extptr);
            R_RegisterCFinalizerEx(this.extptr, &R_ClearExternalPtr, TRUE);
            needUnprotect = true;
        }
        return;
    }
    this(ref return scope XPtr original) @trusted
    {
        this.extptr = original.extptr;
    }
    ~this()
    {
        if(needUnprotect)
        {
            R_ReleaseObject(this.extptr);
            needUnprotect = false;
        }
    }
    
    pragma(inline, true)
    T* opCast(V: T*)()
    if(!isSEXP!(V))
    {
        return cast(T*)(R_ExternalPtrAddr(this.extptr));
    }
    pragma(inline, true)
    V opCast(V)()
    if(isSEXP!V)
    {
        return this.extptr;
    }
    auto opDispatch(string member, Args...)(auto ref Args args)
    if(!isSEXP!(T*))
    {
        auto ptr = cast(T*)this;
        enum dispatch = format("ptr.%1$s(args)", member);
        static if(__traits(compiles, mixin(dispatch)))
        {
            return mixin(dispatch);
        }
        else
        {
            static assert(0, format("Call %1$s is not valid", dispatch));
        }
    }
}


auto xptr(P: T*, T)(auto ref P object)
if(!isSEXP!(P))
{
    return XPtr!(T)(object);
}
