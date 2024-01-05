import std.conv: to;

/* Vector aliases */
alias NumericVector = RVector!(REALSXP);
alias IntegerVector = RVector!(INTSXP);
alias LogicalVector = RVector!(LGLSXP);
alias RawVector = RVector!(RAWSXP);
alias ComplexVector = RVector!(CPLXSXP);
alias CharacterVector = RVector!(STRSXP);
alias StringVector = CharacterVector;

/*
    Template for non-string datatypes
*/
private enum bool NonStringSEXP(SEXPTYPE Type) = (Type == REALSXP) || 
    (Type == INTSXP) || (Type == LGLSXP) || (Type == RAWSXP) || 
    (Type == RAWSXP) || (Type == CPLXSXP);

private enum bool SEXPDataTypes(SEXPTYPE Type) = (Type == REALSXP) || (Type == INTSXP) || 
    (Type == LGLSXP) || (Type == RAWSXP) || (Type == CPLXSXP) || 
    (Type == STRSXP);


/+
    Casts a string to a c string const(char) *
+/
const(char)* castChar(string symbol)
{
    auto n = symbol.length;
    const(char)* result = cast(const(char)*)(symbol[0..$] ~ '\0');
    return result;
}


enum useLib = true;
static if(useLib)
{
    /+
        Converts a string to an SEXP
        Perhaps you should be using STRING_PTR(SEXP)
        instead of STDVEC_DATAPTR(SEXP)?
    +/
    pragma(inline, true)
    SEXP mkString(string value)
    {
        int n = cast(int)value.length;
        auto result = protect(allocVector(STRSXP, 1));
        scope(exit) unprotect(1);
        auto _ptr_ = toUTFz!(const(char)*)(value);
        auto element = mkCharLen(_ptr_, n);
        SEXP* ps = STRING_PTR(result);
    	ps[0] = element;
        return result;
    }
    
    /+
      Overloads R's mkChar function to return a CHARSXP
      from a string
    +/
    pragma(inline, true)
    SEXP mkChar(string value)
    {
        auto ptr = toUTFz!(const(char)*)(value);
        return mkCharLen(ptr, cast(int)value.length);
    }
}else{
    /+
        Converts a string to an SEXP
        Perhaps you should be using STRING_PTR(SEXP)
        instead of STDVEC_DATAPTR(SEXP)?
    +/
    pragma(inline, true)
    SEXP mkString(string value)
    {
        int n = cast(int)value.length;
        auto result = protect(allocVector(STRSXP, 1));
        scope(exit) unprotect(1);
        const(char*) _ptr_ = cast(const(char)*)&value[0];
        auto element = Rf_mkCharLen(_ptr_, n);
        SEXP* ps = STRING_PTR(result);
    	ps[0] = element;
        return result;
    }
    
    /+
      Overloads R's mkChar function to return a CHARSXP
      from a string
    +/
    pragma(inline, true)
    SEXP mkChar(string value)
    {
        int n = cast(int)value.length;
        const(char*) ptr = cast(const(char)*)&value[0];
        return mkCharLen(ptr, n);
    }

}


/+
    Function to set a string as an element in an R character SEXP
    vector
+/
pragma(inline, true)
private auto setSEXP(SEXPTYPE Type, I)(SEXP sexp, I i, string value)
if((Type == STRSXP) && isIntegral!(I))
{
    auto stringLength = cast(int)value.length;
    if(stringLength > 0)
    {
        auto _ptr_ = cast(const(char*))&value[0];
        SEXP element = protect(Rf_mkCharLen(_ptr_, stringLength));
        scope(exit) unprotect(1);
        
        SET_STRING_ELT(sexp, cast(int)i, element);
    }else{
        enforce(0, "Can not set items in array of zero length");
    }
    return value;
}

/+
    Function to get an element of an R character SEXP 
    vector as a string
+/
pragma(inline, true)
private auto getSEXP(SEXPTYPE Type, I)(SEXP sexp, I i)
if((Type == STRSXP) && isIntegral!(I))
{
    import core.stdc.string: strlen;
    const(char)* element = CHAR(STRING_ELT(sexp, cast(int)i));
    auto n = strlen(element);
    return cast(string)element[0..n];
}


/+
    Function to set an element of SEXTYPE Type in a SEXP of type 
    in (REALSXP, INTSXP, LGLSXP, RAWSXP, RAWSXP, CPLXSXP)
+/
pragma(inline, true)
private auto setSEXP(SEXPTYPE Type, T, I)(SEXP sexp, I i, ref T value)
if(isIntegral!(I) && isBasicType!(T) && NonStringSEXP!(Type))
{
    Accessor!(Type)(sexp)[i] = value;
    return value;
}


/+
    Function to get an element of SEXTYPE Type from an SEXP of type 
    in (REALSXP, INTSXP, LGLSXP, RAWSXP, RAWSXP, CPLXSXP)
+/
pragma(inline, true)
private auto getSEXP(SEXPTYPE Type, I)(SEXP sexp, I i)
if(isIntegral!(I) && NonStringSEXP!(Type))
{
    return Accessor!(Type)(sexp)[i];
}


pragma(inline, true)
private auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, auto ref T[] value)
if(isIntegral!(I) && isBasicType!(T) /* && NonStringSEXP!(Type) */)
{
    //enforce((i >= 0) && (n < LENGTH(sexp)), 
    //        "Requested range not less than or " ~ 
    //            "equal to length of array.");
    static if(Type != STRSXP)
    {
        auto n = value.length + i;
        Accessor!(Type)(sexp)[i..n] = value[];
        return Accessor!(Type)(sexp)[i..n];
    }else{
        auto n = value.length;
        foreach(j; 0..n)
        {
            setSEXP!(Type)(sexp, i + j, value[j]);
        }
        return value;
    }
}

pragma(inline, true)
private auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, I j, auto ref T value)
if(isIntegral!(I) && isBasicType!(T) /* && NonStringSEXP!(Type) */)
{
    //enforce((i >= 0) && (j < LENGTH(sexp)) , 
    //    "Issue with range of object requested");
    
    static if(Type != STRSXP)
    {
        Accessor!(Type)(sexp)[i..j] = value;
        return Accessor!(Type)(sexp)[i..j];
    }else{
        auto n = j - i;
        T[] result = new T[n];
        foreach(k; i..j)
        {
            setSEXP!(Type)(sexp, k, value);
            result[k - i] = value;
        }
        return result;
    }
}


pragma(inline, true)
private auto getSlice(SEXPTYPE Type, I)(SEXP sexp, I i, I j)
if(isIntegral!(I) /* && NonStringSEXP!(Type) */)
{
    auto n = j - i;
    //enforce((n <= LENGTH(sexp)) && (n >= 0), 
    //        "Requested range not less than or " ~ 
    //            "equal to length of array.");
    static if(Type != STRSXP)
    {
        return Accessor!(Type)(sexp)[i..j];
    }else{
        string[] result = new string[n];
        foreach(k; 0..n)
        {
            result[k] = getSEXP!(Type)(sexp, i + k);
        }
        return result;
    }
}

/*
    Overloads the original R function to copy an SEXP vector
    by only requiring the original rather than the original
    vector and the destination vector
*/
auto copyVector(SEXP originalVector)
{
    auto type = cast(SEXPTYPE)TYPEOF(originalVector);
    auto newVector = protect(allocVector(type, 
                        LENGTH(originalVector)));
    scope(exit) unprotect(1);
    copyVector(newVector, originalVector);
    return newVector;
}


/*
    Fills SEXP R Vector with a submitted value. works with R vectors only
    but not lists.
*/
private auto fillSEXPVector(I)(SEXP sexp, I finalLength)
if(isIntegral!(I))
{
    auto rtype = cast(SEXPTYPE)TYPEOF(sexp);
    enforce(!(!isVector(sexp) || (rtype == VECSXP)), 
        "Submitted SEXP is either not a vector or is a list");
    auto _finalLength_ = cast(int)finalLength;
    SEXP result;
    switch (rtype)
    {
        default:
            throw new Exception("SEXP (" ~ to!(string)(rtype) ~ ") is not applicable.");
        case REALSXP:
            result = protect(allocVector(REALSXP, _finalLength_));
            auto value = getSEXP!(REALSXP)(sexp, 0);
            setSlice!(REALSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
        case INTSXP:
            result = protect(allocVector(INTSXP, _finalLength_));
            auto value = getSEXP!(INTSXP)(sexp, 0);
            setSlice!(INTSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
        case STRSXP:
            result = protect(allocVector(STRSXP, _finalLength_));
            auto value = getSEXP!(STRSXP)(sexp, 0);
            setSlice!(STRSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
        case LGLSXP:
            result = protect(allocVector(LGLSXP, _finalLength_));
            auto value = getSEXP!(LGLSXP)(sexp, 0);
            setSlice!(LGLSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
        case RAWSXP:
            result = protect(allocVector(RAWSXP, _finalLength_));
            auto value = getSEXP!(RAWSXP)(sexp, 0);
            setSlice!(RAWSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
        case CPLXSXP:
            result = protect(allocVector(CPLXSXP, _finalLength_));
            auto value = getSEXP!(CPLXSXP)(sexp, 0);
            setSlice!(CPLXSXP)(result, 0, finalLength, value);
            unprotect(1);
            return result;
    }
    enforce(0, "SEXP (" ~ to!(string)(rtype) ~ ") is not applicable.");
}


/*
    Joins two SEXP R vectors
*/
private auto join(SEXP lhs, SEXP rhs)
{
    auto rtype = rTypeOf(lhs);
    enforce(rtype == rTypeOf(rhs), "Vector types do not match.");
    auto lhsLength = lhs.length;
    auto rhsLength = rhs.length;
    auto finalLength = cast(int)(lhs.length + rhs.length);
    auto result = protect(allocVector(rtype, finalLength));
    scope(exit) unprotect(1);
    switch(rtype)
    {
        default:
            throw new Exception("SEXP (" ~ to!(string)(rtype) ~ 
                ") is not applicable or has not been implemented.");
        static foreach(TYPE; [REALSXP, INTSXP, LGLSXP, RAWSXP, CPLXSXP, STRSXP])
        {
            case TYPE:
                alias FUNC = Accessor!(TYPE);
                auto ptr = FUNC(result);
                ptr[0..lhsLength] = FUNC(lhs)[0..lhsLength];
                ptr[lhsLength..finalLength] = FUNC(rhs)[0..rhsLength];
                return result;
        }
    }
    enforce(0, "SEXP (" ~ to!(string)(rtype) ~ ") is not applicable.");
}


/*
    Function to subset SEXP vectors of type in
        [REALSXP, INTSXP, LGLSXP, RAWSXP, CPLXSXP, STRSXP]
*/
private auto slice(bool copy = true, I)(SEXP sexp, I i, I j)
if(isIntegral!(I))
{
    auto rtype = rTypeOf(sexp);
    enforce((j > i) && (j <= cast(I)sexp.length), 
        format("Please check the selection slice indexes " ~ 
            "(i: %1$s, j: %2$s) and the length (%3$s) of the SEXP", 
            i, j, sexp.length));
    auto finalLength = cast(int)(j - i);
    static if(copy)
    {
        //returns copied slice
        auto result = protect(allocVector(rtype, finalLength));
        scope(exit) unprotect(1);
        
        switch(rtype)
        {
            default:
                throw new Exception("SEXP (" ~ to!(string)(rtype) ~ 
                    ") is not applicable or has not been implemented.");
            static foreach(TYPE; [REALSXP, INTSXP, LGLSXP, RAWSXP, CPLXSXP, STRSXP])
            {
                case TYPE:
                    alias FUNC = Accessor!(TYPE);
                    auto ptr = FUNC(result);
                    ptr[0..finalLength] = FUNC(sexp)[i..j];
                    return result;
            }
        }
    }else{
        //returns truncated input
        auto result = sexp;
        switch(rtype)
        {
            default:
                throw new Exception("SEXP (" ~ to!(string)(rtype) ~ 
                    ") is not applicable or has not been implemented.");
            static foreach(TYPE; [REALSXP, INTSXP, LGLSXP, RAWSXP, CPLXSXP, STRSXP])
            {
                case TYPE:
                    alias FUNC = Accessor!(TYPE);
                    auto ptr = FUNC(result);
                    if(i != 0)
                    {
                        foreach(k; 0..finalLength)
                        {
                            ptr[k] = ptr[k + i];
                        }
                    }
                    SETLENGTH(result, finalLength);//truncate
                    return result;
            }
        }
    }
    enforce(0, "SEXP (" ~ to!(string)(rtype) ~ ") is not applicable.");
}





struct RVector(alias Type)
if(SEXPDataTypes!(Type))
{
    SEXP sexp;
    bool needUnprotect = false;
    alias ElType = SEXPElementType!(Type);

    private void unprotect()
    {
        if(needUnprotect)
        {
            R_ReleaseObject(this.sexp);
            needUnprotect = false;
        }
    }
    @property size_t length() @trusted
    {
        return LENGTH(this.sexp);
    }
    @property auto length(T)(T n) @trusted
    if(isIntegral!(T))
    {
        static if(Type != STRSXP)
        {
            SETLENGTH(this.sexp, cast(int)n);
            return this.length;
        }else{
            static assert(0, "No implementation of length change for STRSXP yet");
        }
    }
    @property auto data()
    {
        auto n = this.length;
        static if(NonStringSEXP!(Type))
        {
            return Accessor!(Type)(sexp)[0..n];
        }else{
            string[] result;
            foreach(i; 0..n)
            {
                result ~= getSEXP!(Type)(this.sexp, i);
            }
            return result;
        }
    }
    static if(Type != STRSXP)
    {
        pragma(inline, true)
        @property auto ptr()
        {
            return Accessor!(Type)(this.sexp);
        }
    }
    /*
        Contructors
    */
    this(T)(T n) @trusted
    if(isIntegral!(T))
    {
        this.sexp = allocVector(Type, cast(int)n);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
    }
    this(T)(T value) @trusted
    if(is(T == ElType) && !isIntegral!(T))
    {
        this.sexp = allocVector(Type, 1);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        static if((Type == STRSXP))
        {
            setSEXP!(Type)(this.sexp, 0, value);
        }else{
            Accessor!(Type)(this.sexp)[0] = value;
        }
    }
    this(T)(T[] arr...) @trusted
    if(is(T == ElType))
    {
        auto n = arr.length;
        this.sexp = allocVector(Type, cast(int)n);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        static if(Type == STRSXP)
        {
            for(long i = 0; i < n; ++i)
            {
                setSEXP!(Type)(this.sexp, i, arr[i]);
            }
        }else{
            Accessor!(Type)(this.sexp)[0..n] = arr[];
        }
    }
    this(T)(T sexp) @trusted
    if(is(T == SEXP))
    {
        enforce((Type == TYPEOF(sexp)) && isVector(sexp), 
            "Type of input is not the same as SEXPTYPE Type submitted");
        this.sexp = sexp;
        this.needUnprotect = false;
    }
    /* For logical implicit from bool array */
    this(T)(T[] arr...) @trusted
    if(is(T == bool))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ 
                    Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = allocVector(LGLSXP, cast(int)n);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        int* _data_ = Accessor!(LGLSXP)(this.sexp)[0..n];
        foreach(i; 0..n)
        {
            _data_[i] = arr[i];
        }
    }
    /* Using R's boolean */
    this(T)(T[] arr...) @trusted
    if(is(T == Rboolean))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ 
                    Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = allocVector(LGLSXP, cast(int)n);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        Accessor!(LGLSXP)(this.sexp)[0..n] = (cast(int*)arr.ptr)[0..n];
    }
    /* Copy constructor */
    this(ref return scope RVector original) @trusted
    {
        int n = cast(int)original.length;
        this.sexp = allocVector(Type, cast(int)n);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        copyVector(this.sexp, original.sexp);
    }
    
    //disable const copy for now
    //@disable this(ref const(typeof(this)));

    ~this() @trusted
    {
        this.unprotect;
    }
    string toString() @trusted
    {
        string result = "RVector!(" ~ Type.stringof ~ ")(";
        auto n = this.length;
        for(int i = 0; i < n; ++i)
        {
            static if(Type != LGLSXP)
            {
                ElType tmp = getSEXP!(Type)(this.sexp, i);
            }else{
                Rboolean tmp = cast(Rboolean)getSEXP!(Type)(this.sexp, i);
            }
            result ~= to!(string)(tmp) ~ ", ";
        }
        if(n > 0)
        {
            result = result[0..($ - 2)];
        }
        result ~= ")";
        return result;
    }
    pragma(inline, true)
    T opCast(T: SEXP)() @trusted
    {
        return this.sexp;
    }
    @property SEXP implicitCast() @system
    {
        return cast(SEXP)this;
    }
    T opCast(T: ElType)() @trusted
    {
        enforce(this.length == 1, "Cannot cast to basic Type " ~ 
            ElType.stringof ~ 
            "length is not equal to 1");
        return this[0];
    }
    T opCast(T: ElType[])() @trusted
    {
        auto n = this.length;
        return getSlice!(Type)(this.sexp, 0, n);
    }
    auto opDollar() @trusted
    {
        return this.length();
    }
    pragma(inline, true)
    ElType opIndex(size_t i) @trusted
    {
        return getSEXP!(Type)(this.sexp, i);
    }
    /* Generates a copy for now */
    RVector opUnary(string op)() @trusted
    {
        auto n = this.length;
        auto arr = getSlice!(Type)(this.sexp, 0, n);
        auto result = arr.dup;

        mixin("result[] = " ~ op ~ "arr[];");
        return RVector!(Type)(result);
    }
    auto opIndexUnary(string op)(size_t i) @trusted
    {
        auto result = this[i];
        mixin ("result = " ~ op ~ "result;");
        return result;
    }
    ElType opIndexAssign(T)(auto ref T value, size_t i) @trusted
    {
        static if(is(T == ElType))
        {
            return setSEXP!(Type)(this.sexp, i, value);
        }else static if(__traits(compiles, cast(ElType)value))
        {
            ElType _value_ = cast(ElType)value;
            return setSEXP!(Type)(this.sexp, i, _value_);
        }else{
            static assert(0, "Type " ~ T.stringof ~ 
                " not implemented for opIndexAssign in " ~ 
                " RVector!(" ~ Type.stringof ~ ").");
        }
    }
    auto opIndexOpAssign(string op, T)(auto ref T value, size_t i) @trusted
    {
        static if((Type != STRSXP) && is(T == ElType))
        {
            auto _ptr_ = Accessor!(Type)(this.sexp);
            mixin("this.ptr[i] " ~ op ~ "= value;");
            return this.ptr[i];
        }else static if((Type == STRSXP) && is(T == ElType))
        {
            auto element = getSEXP!(Type)(this.sexp, i);
            mixin("element " ~ op ~ "= value;");
            setSEXP!(Type)(this.sexp, i, element);
            return element;
        }else static if(__traits(compiles, cast(ElType)value))
        {
            ElType _value_ = cast(ElType)value;
            auto element = getSEXP!(Type)(this.sexp, i);
            mixin("element " ~ op ~ "= _value_;");
            setSEXP!(Type)(this.sexp, i, element);
            return element;
        }else{
            static assert(0, "Type " ~ T.stringof ~ 
                " not implemented for opIndexOpAssign in " ~ 
                " RVector!(" ~ Type.stringof ~ ").");
        }
    }
    auto ref RVector opOpAssign(string op, T)(T value) @trusted return
    {
        static if(is(T == ElType))
        {
            /* For appends ~ */
            static if(op == "~")
            {
                auto last = this.length;
                this.length = this.length + 1;
                static if(Type == STRSXP)
                {
                    setSEXP!(Type)(this.sexp, last, value);
                }else
                {
                    this.ptr[last] = value;
                }
            }else
            { /* For other operations */
                auto n = this.length;
                static if(Type == CPLXSXP)
                {
                    foreach(i; 0..n)
                    {
                        auto element = this.ptr[i];
                        mixin("element " ~ op ~ "= value;");
                        this.ptr[i] = element;
                    }
                }else static if(Type != STRSXP)
                {
                    mixin("this.ptr[0..n] " ~ op ~ "= value;");
                }else{
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(this.sexp, i);
                        mixin("element " ~ op ~ "= value;");
                        setSEXP!(Type)(this.sexp, i, element);
                    }
                }
            }
        }else static if(is(T == ElType[]) || is(T == Rboolean[]))
        {
            /* For appends */
            static if(op == "~")
            {
                auto p = this.length;
                this.length = value.length + p;
                static if(Type != STRSXP)
                {
                    auto n = this.length;
                    static if(is(T == Rboolean[]))
                    {
                        int[] _value_ = (cast(int*)(value.ptr))[0..value.length];
                        this.ptr[p..n] = _value_[];
                    }else{
                        this.ptr[p..n] = value[];
                    }
                }else{
                    auto n = value.length;
                    foreach(i; 0..n)
                    {
                        setSEXP!(Type)(this.sexp, p + i, value[i]);
                    }
                }
            }else{
                auto n = this.length;
                enforce(n == value.length, 
                    "length of candidate array differs in opOpAssign.");
                static if(Type != STRSXP)
                {
                    static if(is(T == Rboolean[]))
                    {
                        int[] _value_ = (cast(int*)(value.ptr))[0..value.length];
                        mixin("this.ptr[0..n] " ~ op ~ "= _value_[];");
                    }else{
                        mixin("this.ptr[0..n] " ~ op ~ "= value[];");
                    }
                }else{
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(this.sexp, i);
                        mixin("element " ~ op ~ "= value[i];");
                        setSEXP!(Type)(this.sexp, i, element);
                    }
                }
            }
        }else static if(is(T == RVector))
        {
            /* For appends */
            static if(op == "~")
            {
                auto p = this.length;
                this.length = value.length + p;
                static if(Type != STRSXP)
                {
                    auto n = this.length;
                    this.ptr[p..n] = value.ptr[0..value.length];
                }else{
                    auto n = value.length;
                    foreach(i; 0..n)
                    {
                        setSEXP!(Type)(this.sexp, p + i, value[i]);
                    }
                }
            }else{
                auto n = this.length;
                enforce(n == value.length, 
                    "length of candidate array differs in opOpAssign.");
                static if(Type != STRSXP)
                {
                    mixin("this.ptr[0..n] " ~ op ~ "= value[];");
                }else{
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(this.sexp, i);
                        mixin("element " ~ op ~ "= value[i];");
                        setSEXP!(Type)(this.sexp, i, element);
                    }
                }
            }
        }else static if(__traits(compiles, cast(ElType)value) && !is(Eltype == string))
        {
            auto _value_ = cast(ElType)value;
            auto n = this.length;
            static if(op == "~") /* For appends */
            {
                this.length = n + 1;
                this.ptr[n] = _value_;
            }else{
                mixin("this.ptr[0..n] " ~ op ~ "= _value_;");
            }
        }else{
            static assert(0, "Unknown type " ~ T.stringof ~ " for opOpAssign.");
        }
        return this;
    }

    RVector opSlice() @trusted
    {
        return RVector!(Type)(this);
    }
    RVector opSlice(size_t i, size_t j) @trusted
    {
        enforce(j >= i, 
            "opSlice error, the second index is not" ~ 
            " greater than or equal to the first");
        static if(Type != STRSXP)
        {
            return RVector!(Type)(this.ptr[i..j]);
        }else{
            auto n = j - i;
            auto result = RVector!(Type)(n);
            foreach(k; 0..n)
            {
                result[k] = this[i + k];
            }
            return result;
        }
    }
    RVector opBinary(string op, T)(T value) @trusted
    {
        auto result = RVector!(Type)(this);
        auto n = result.length;
        static if(is(T == ElType))
        {
            static if(op == "~")
            {
                result.length = result.length + 1;
                result[$ - 1] = value;
            }else{
                static if(Type == CPLXSXP)
                {
                    foreach(i; 0..n)
                    {
                        auto element = this.ptr[i];
                        mixin("element " ~ op ~ "= value;");
                        result.ptr[i] = element;
                    }
                }else static if(Type != STRSXP)
                {
                    mixin("result.ptr[0..n] " ~ op ~ "= value;");
                }else
                {
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(result.sexp, i);
                        mixin("element " ~ op ~ "= value;");
                        setSEXP!(Type)(result.sexp, i, element);
                    }
                }
            }
        }else static if(is(T == ElType[]) || is(T == Rboolean[]))
        {
            static if(op == "~")
            {
                auto p = result.length;
                result.length = result.length + value.length;
                n = result.length;
                static if(is(T == Rboolean[]))
                {
                    int[] _value_ = (cast(int*)(value.ptr))[0..n];
                    result.ptr[p..n] = _value_;
                }else static if(Type == STRSXP)
                {
                    setSlice!(Type)(result.sexp, p, value);
                }else{
                    result.ptr[p..n] = value[];
                }
            }else
            {
                enforce(value.length == n, 
                    "Length of array not equal to length of RVector");
                static if(is(T == Rboolean[]))
                {
                    int[] _value_ = (cast(int*)(value.ptr))[0..n];
                    mixin("result.ptr[0..n] " ~ op ~ "= _value_[];");
                }else static if(Type != STRSXP)
                {
                    mixin("result.ptr[0..n] " ~ op ~ "= value[];");
                }else static if(Type == STRSXP)
                {
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(result.sexp, i);
                        mixin("element " ~ op ~ "= value[i];");
                        setSEXP!(Type)(result.sexp, i, element);
                    }
                }
            }
        }else static if(is(T == RVector))
        {
            static if(op == "~")
            {
                auto p = result.length;
                auto m = value.length;
                static if(Type == LGLSXP)
                {
                    result.length = result.length + m;
                    n = result.length;
                    int[] _value_ = (cast(int*)(value.ptr))[0..m];
                    result.ptr[p..n] = _value_;
                }else static if(Type == STRSXP)
                {
                    result = RVector!(Type)(this.data ~ value.data);
                }else{
                    result.length = result.length + m;
                    n = result.length;
                    result.ptr[p..n] = value.ptr[0..m];
                }
            }else
            {
                enforce(value.length == n, 
                    "Length of RVector not equal to length of RVector");
                static if(Type != STRSXP)
                {
                    mixin("result.ptr[0..n] " ~ op ~ "= value.ptr[0..n];");
                }else static if(Type == STRSXP)
                {
                    foreach(i; 0..n)
                    {
                        auto element = getSEXP!(Type)(result.sexp, i);
                        mixin("element " ~ op ~ "= value[i];");
                        setSEXP!(Type)(result.sexp, i, element);
                    }
                }
            }
        }else static if(__traits(compiles, cast(ElType)value) && (Type != STRSXP))
        {
            auto _value_ = cast(ElType)value;
            static if(op == "~")
            {
                result.length = result.length + 1;
                result[$ - 1] = _value_;
            }else
            {
                mixin ("result.ptr[0..n] " ~ op ~ "= _value_;");
            }
        }else
        {
            static assert(0, "opBinary unknown type " ~ T.stringof ~ " used.");
        }
        return result;
    }
    auto opBinaryRight(string op, T)(T value) @trusted
    {
        return opBinary!(op, T)(value);
    }
    auto opSliceAssign(T)(T value, size_t i, size_t j) @trusted
    {
        if(i == j)
        {
            return RVector!(Type)(0);
        }
        auto n = j - i;
        enforce(n > 0, 
            "Number of elements to be replace is not greater than zero.");
        static if(is(T == ElType))
        {
            static if(Type != STRSXP)
            {
                this.ptr[i..j] = value;
            }else
            {
                setSlice!(Type)(this.sexp, i, j, value);
            }
        }else static if(is(T == ElType[]) || is(T == Rboolean[]))
        {
            enforce(value.length == n, 
                "Length of replacement vector not equal " ~ 
                "to replacement zone length");
            static if(is(T == Rboolean[]))
            {
                int[] _value_ = (cast(int*)(value.ptr))[0..n];
                this.ptr[i..j] = _value_;
            }else static if(Type == STRSXP)
            {
                setSlice!(Type)(this.sexp, i, value);
            }else{
                this.ptr[i..j] = value;
            }
        }else static if(is(T == RVector))
        {
            enforce(value.length == n, 
                "Length of replacement vector not equal " ~ 
                "to replacement zone length");
            static if(is(Type == LGLSXP))
            {
                int[] _value_ = (cast(int*)(value.ptr))[0..n];
                this.ptr[i..j] = _value_;
            }else static if(Type == STRSXP)
            {
                setSlice!(Type)(this.sexp, i, value.data);
            }else{
                this.ptr[i..j] = value.ptr[0..n];
            }
        }else static if(__traits(compiles, cast(ElType)value) && (Type != STRSXP))
        {
            auto _value_ = cast(ElType)value;
            this.ptr[i..j] = _value_;
        }else
        {
            static assert(0, "opSliceAssign unknown type " ~ T.stringof ~ " used.");
        }
        static if(Type == STRSXP)
        {
            return RVector!(Type)(this.data[i..j]);
        }else
        {
            return RVector!(Type)(this.ptr[i..j]);
        }
    }
    auto opSliceAssign(T)(T value) @trusted
    {
        return opSliceAssign!(T)(value, 0, this.length);
    }
    RVector opSliceOpAssign(string op, T)(T value, size_t i, size_t j) @trusted
    {
        if(i == j)
        {
            return RVector!(Type)(0);
        }
        enforce(i <= j, 
            "Index requested is not valid j is not greater than i");
        auto n = j - i;
        static if(is(T == ElType))
        {
            static if(Type == STRSXP)
            {
                foreach(k; i..j)
                {
                    auto element = this[k];
                    mixin("element " ~ op ~ "= value;");
                    setSEXP!(Type)(this.sexp, k, element);
                }
            }else static if(Type == CPLXSXP)
            {
                foreach(k; i..j)
                {
                    auto element = this.ptr[k];
                    mixin("element " ~ op ~ "= value;");
                    this.ptr[k] = element;
                }
            }else
            {
                mixin("this.ptr[i..j] " ~ op ~ "= value;");
            }
        }else static if(is(T == ElType[]) || is(T == Rboolean[]))
        {
            enforce(value.length == n,
                "Length of array not equal to replacement length.");
            static if(is(T == Rboolean[]))
            {
                int[] _value_ = (cast(int*)(value.ptr))[0..n];
                mixin("this.ptr[i..j] " ~ op ~ "= _value_[];");
            }else static if(Type != STRSXP)
            {
                mixin("this.ptr[i..j] " ~ op ~ "= value[];");
            }else static if(Type == STRSXP)
            {
                foreach(k; 0..n)
                {
                    auto element = this[i + k];
                    mixin("element " ~ op ~ "= value[k];");
                    setSEXP!(Type)(this.sexp, i + k, element);
                }
            }
        }else static if(is(T == RVector))
        {
            enforce(value.length == n, 
                "Length of candidate vector not equal to replacement length");
            static if(Type == STRSXP)
            {
                foreach(k; 0..n)
                {
                    auto element = this[i + k];
                    mixin("element " ~ op ~ "= value[k];");
                    setSEXP!(Type)(this.sexp, i + k, element);
                }
            }else static if(Type != LGLSXP)
            {
                foreach(k; 0..n)
                {
                    auto element = this[i + k];
                    mixin("element " ~ op ~ "= value[k];");
                    this.ptr[i + k] = element;
                }
            }else static if(Type != STRSXP)
            {
                mixin("this.ptr[i..j] " ~ op ~ "= value.ptr[0..n];");
            }
        }else static if(__traits(compiles, cast(ElType)value) && (Type != STRSXP))
        {
            auto _value_ = cast(ElType)value;
            mixin ("this.ptr[i..j] " ~ op ~ "= _value_;");
        }else
        {
            static assert(0, "opSliceOpAssign unknown type " ~ T.stringof ~ " used.");
        }
        return this[i..j];
    }
    auto opSliceOpAssign(string op, T)(T value) @trusted
    {
        return opSliceOpAssign!(op, T)(value, 0, this.length);
    }
    auto setAttrib(SEXP symbol, SEXP attrib)
    {
        Rf_setAttrib(this.sexp, symbol, attrib);
        return;
    }
    auto setAttrib(string symbol, SEXP attrib)
    {
        Rf_setAttrib(this.sexp, To!SEXP(symbol), attrib);
        return;
    }
    auto getAttrib(SEXP symbol)
    {
        return Rf_getAttrib(this.sexp, symbol);
    }
    auto getAttrib(string symbol)
    {
        return Rf_getAttrib(this.sexp, To!SEXP(symbol));
    }
    bool opEquals(RVector arr) @trusted
    {
        return this.data == arr.data;
    }
    auto eq(RVector arr) @trusted
    {
        auto n = arr.length;
        enforce(this.length == n, "Legnths of vector comparisons differ");
        auto result = RVector!(LGLSXP)(n);
        foreach(i; 0..n)
        {
            result[i] = arr[i] == this[i];
        }
        return result;
    }
    auto cmp(string op)(RVector arr) @trusted
    {
        static if(isCmp!op)
        {
            auto n = arr.length;
            enforce(this.length == n, "Legnths of vector comparisons differ");
            auto result = RVector!(LGLSXP)(n);
            foreach(i; 0..n)
            {
                mixin("result[i] = this[i] " ~ op ~ " arr[i];");
            }
            return result;
        }else{
            static assert(0, "Operator " ~ op ~ " is not a comparison operator");
        }
    }
    @property string[] names() @trusted
    {
        SEXP _names_ = Rf_getAttrib(this.sexp, R_NamesSymbol);
        return getSlice!(STRSXP)(_names_, 0, LENGTH(this.sexp));
    }
    @property auto names(string[] _names_) @trusted
    {
        enforce(_names_.length == LENGTH(this.sexp), 
            "length of names not equal to length of sexp");
        Rf_setAttrib(this.sexp, R_NamesSymbol, To!SEXP(_names_));
        return;
    }
    @property auto names(SEXP _names_) @trusted
    {
        auto type = TYPEOF(_names_);
        enforce(type == STRSXP, "Error no implementation of names method for type " 
            ~ type.stringof);
        enforce(LENGTH(_names_) == LENGTH(this.sexp), 
            "length of names not equal to length of sexp");
        Rf_setAttrib(this.sexp, R_NamesSymbol, _names_);
        return;
    }
}

enum bool isCmp(string op) = (op == "==") || (op == ">") || (op == "<") || 
                (op == ">=") || (op == "<=");

/*
    Gets the SEXPTYPR for the RType RVector, RMatrix, etc.
*/
template GetSEXPType(U: R!T, alias R, SEXPTYPE T)
if(isRType!U)
{
    enum GetSEXPType = T;
}


bool all(T)(auto ref T vec) @trusted
if(is(T == LogicalVector))
{
    int total = 0;
    auto n = vec.length;
    foreach(i; 0..n)
    {
        total += cast(int)vec[i];
    }
    return n == total ? true : false;
}


auto ref rep(SEXPTYPE Type, T, I)(auto ref T element, auto ref I times) @trusted
if(is(T == SEXPElementType!(Type)) && isIntegral!(I))
{
    auto result = RVector!(Type)(times);
    /* 
        Rethink returning copies of things and use views 
        instead when new objects don't need to be created 
    */
    static if(Type != STRSXP)
    {
        result.ptr[0..times] = element;
    }else{
        result[] = element;
    }
    return result;
}


auto seq(SEXPTYPE Type, T)(T from, T to, T by = 1) @trusted
if(is(T == SEXPElementType!(Type)))
{
    import std.range: iota;
    auto _n_ = (to - from)/by;
    enforce(_n_ >= 0, "Number of elements is negative");
    auto n = cast(size_t)(_n_);
    auto result = RVector!(Type)(n);
    size_t i = 0;
    foreach(ref element; iota(from, to, by))
    {
        result[i] = element;
        ++i;
    }
    return result;
}

/+
    Order function returns the order of the items in the vector and leaves the order 
    of the original vector unchanged.
+/
auto order(SEXPTYPE Type)(RVector!(Type) arr, 
            Rboolean decreasing = FALSE) @trusted
{
    auto n = cast(int)arr.length;
    auto result = seq!(INTSXP)(0, n);
    R_orderVector1(result.ptr, n, arr.sexp, 
        TRUE, decreasing);
    return result + 1;
}


private auto constructNestedCall(string fName = "CDR", string arg = "arg", alias n)()
if(isIntegral!(typeof(n)))
{
    string tmp0 = fName, tmp1 = ")";
    static foreach(i; 0..n)
    {
        tmp0 ~= "(" ~ fName;
        tmp1 ~= ")";
    }
    tmp0 = tmp0 ~ "(";
    return tmp0 ~ arg ~ tmp1;
}


/+
    This is the nested call version ...
+/
private auto InternalCall0(Args...)(string fName, Args args)
{
    enum nargs = Args.length;
    SEXP call, arg;
    protect(call = allocVector(LANGSXP, cast(int)(nargs + 1)));
    SETCAR(call, Rf_installChar(mkChar(fName)));
    static foreach(i; 0..nargs)
    {
        arg = To!(SEXP)(args[i]);
        SETCAR(mixin(constructNestedCall!("CDR", "call", i)()), arg);
    }
    auto result = eval(call, R_GlobalEnv);
    unprotect(1);
    return result;
}


/+
    Generalized R call for any function with string fName
    and arguments args with type sequence Args...
    which are coerable to SEXP with the To!(SEXP)(...) template 
    function
+/
private auto InternalCall(Args...)(string fName, Args args) @system
{
    enum nargs = Args.length;
    SEXP call, arg;
    protect(call = allocVector(LANGSXP, cast(int)(nargs + 1)));
    SETCAR(call, installChar(mkChar(fName)));
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
    auto result = eval(call, R_GlobalEnv);
    unprotect(nProtect);
    return result;
}

