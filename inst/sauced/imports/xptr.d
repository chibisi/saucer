import std.traits: isBasicDType = isBasicType, isCallable, isPointer, ReturnType;
import core.lifetime: emplace, moveEmplace;

private extern(C) static void finalizerFunction(SEXP ptr)
{
    enforce(TYPEOF(ptr) == EXTPTRSXP, 
        "Submitted non-EXTPTRSXP type to XPtr constructor");
    auto vPtr = R_ExternalPtrAddr(ptr);
    if(vPtr != null)
    {
        R_chk_free(vPtr);
    }
    return;
}


T* makePointer(T)(auto ref T value) @trusted
if(!isPointer!(T) && !is(T: A[], A))
{
    auto ptr = cast(T*)R_chk_calloc(1, T.sizeof);
    moveEmplace(value, *ptr);
    return ptr;
}



T* makePointer(T, Args...)(auto ref Args args) @trusted
if(!isPointer!(T) && !is(T: A[], A))
{
    auto ptr = cast(T*)R_chk_calloc(1, T.sizeof);
    ptr = emplace(ptr, args);
    return ptr;
}



struct XPtr(T)
{
    private SEXP extptr;
    private bool needUnprotect = false;

    this(P, S = SEXP)(auto ref P ptr, S tag = R_NilValue, SEXP prot = R_NilValue) @trusted
    if((isSEXP!(S) || is(S == string)))
    {
        SEXP _tag_;
        static if(isSEXP!S)
        {
            if(isString(tag))
            {
                _tag_ = installChar(asChar(tag));
            }
            else
            {
                _tag_ = tag;
            }
        }
        else
        {
            _tag_ = installChar(mkChar(tag));
        }

        static if(isSEXP!(P))
        {
            enforce(TYPEOF(ptr) == EXTPTRSXP, "Submitted non-EXTPTRSXP type to XPtr constructor");
            this.extptr = ptr;
        }
        else static if(is(P: T*))
        {
            this.extptr = R_MakeExternalPtr(cast(void*) ptr, _tag_, prot);
            R_PreserveObject(this.extptr);
            needUnprotect = true;
        }
        else static if(is(P: T[]))
        {
            enforce(ptr.length > 0, "Can not take the pointer for a zero length array");
            this.extptr = R_MakeExternalPtr(cast(void*) &ptr[0], _tag_, prot);
            R_PreserveObject(this.extptr);
            needUnprotect = true;
        }else{
            auto pPtr = cast(P*)R_chk_calloc(1, P.sizeof);//allocates
            pPtr[0] = ptr;
            this.extptr = R_MakeExternalPtr(cast(void*) pPtr, _tag_, prot);
            R_PreserveObject(this.extptr);
            needUnprotect = true;
        }
        //R_RegisterCFinalizerEx(this.extptr, &finalizerFunction, TRUE);
        R_RegisterCFinalizerEx(this.extptr, &R_ClearExternalPtr, TRUE);
        
        return;
    }
    this(ref return scope XPtr original) @trusted
    {
        this.extptr = original.extptr;
    }
    ~this() @trusted
    {
        if(needUnprotect)
        {
            R_ReleaseObject(this.extptr);
            needUnprotect = false;
        }
    }
    
    pragma(inline, true)
    T* opCast(V: T*)() @trusted
    if(!isSEXP!(V))
    {
        return cast(T*)(R_ExternalPtrAddr(this.extptr));
    }
    pragma(inline, true)
    V opCast(V)() @trusted
    if(isSEXP!V)
    {
        return this.extptr;
    }
    auto opDispatch(string member, Args...)(auto ref Args args) @trusted
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


auto xptr(P)(auto ref P object)
if(!isSEXP!(P))
{
    static if(is(P: T*, T))
    {
        return XPtr!(T)(object);
    }else static if(is(P: T[], T))
    {
        return XPtr!(T)(object);
    }else
    {
        return XPtr!(P)(object);
    }
}
