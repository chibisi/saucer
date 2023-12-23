//import std.stdio: writeln;

private struct XPtr(T)
{
    import std.traits: isCallable, isPointer;
    SEXP extptr;
    alias extptr this;
    this(SEXP extptr)
    {
        enforce(TYPEOF(extptr) == EXTPTRSXP, "Submitted non-EXTPTRSXP type to XPtr constructor");
        this.extptr = extptr;
    }
    this(SEXP extptr, SEXP tag, SEXP prot)
    {
        enforce(TYPEOF(extptr) == EXTPTRSXP, "Submitted non-EXTPTRSXP type to XPtr constructor");
        R_SetExternalPtrTag(extptr, tag);
        R_SetExternalPtrProtected(extptr, prot);
        this.extptr = extptr;
    }
    this(T object, SEXP tag = R_NilValue, SEXP prot = R_NilValue)
    {
        static if(isCallable!(T) || isPointer!(T))
        {
            this.extptr = R_MakeExternalPtr(cast(void*) object, tag, prot);
            R_RegisterCFinalizerEx(this.extptr, &R_ClearExternalPtr, TRUE);
        }else{
            static assert(0, "object submitted to XPtr is not callable or a pointer.");
        }
    }
    T opCast(U: T)()
    {
        return cast(T)(R_ExternalPtrAddr(this.extptr));
    }
}

auto xptr(T)(T object)
if(!is(T == SEXP))
{
    return XPtr!(T)(object);
}
