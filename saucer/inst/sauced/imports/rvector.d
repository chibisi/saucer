//module saucer.inst.sauced.imports.rvector;

/*
    TODO:
    1. To!() conversion: bool[] -> SEXP && SEXP -> bool[]
*/

import std.conv: to;
//import std.stdio: writeln;

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
enum bool NonStringSEXP(SEXPTYPE Type) = (Type == REALSXP) || 
    (Type == INTSXP) || (Type == LGLSXP) || (Type == RAWSXP) || 
    (Type == RAWSXP) || (Type == CPLXSXP);

enum bool SEXPDataTypes(SEXPTYPE Type) = (Type == REALSXP) || (Type == INTSXP) || 
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
    const(char*) _ptr_ = cast(const(char*))&value[0];
    auto element = Rf_mkCharLen(_ptr_, n);
    SEXP* ps = STRING_PTR(result);
	ps[0] = element;
    unprotect(1);
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
    const(char*) ptr = cast(const(char*))&value[0];
    return mkCharLen(ptr, n);
}



/+
    Function to set a string as an element in an R character SEXP
    vector
+/
pragma(inline, true)
auto setSEXP(SEXPTYPE Type, I)(SEXP sexp, I i, auto ref string value)
if((Type == STRSXP) && isIntegral!(I))
{
    int n = cast(int)value.length;
    if(n > 0)
    {
        const(char*) _ptr_ = cast(const(char*))&value[0];
        SEXP element = Rf_mkCharLen(_ptr_, n);
        SEXP* ps = cast(SEXP*)STDVEC_DATAPTR(sexp);
	    ps[i] = element;
    }
    return value;
}

/+
    Function to get an element of an R character SEXP 
    vector as a string
+/
pragma(inline, true)
auto getSEXP(SEXPTYPE Type, I)(SEXP sexp, I i)
if((Type == STRSXP) && isIntegral!(I))
{
    const(char)* element = CHAR(STRING_ELT(sexp, cast(int)i));
    auto n = strlen(element);
    return cast(string)element[0..n];
}


/+
    Function to set an element of SEXTYPE Type in a SEXP of type 
    in (REALSXP, INTSXP, LGLSXP, RAWSXP, RAWSXP, CPLXSXP)
+/
pragma(inline, true)
auto setSEXP(SEXPTYPE Type, T, I)(SEXP sexp, I i, ref T value)
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
auto getSEXP(SEXPTYPE Type, I)(SEXP sexp, I i)
if(isIntegral!(I) && NonStringSEXP!(Type))
{
    return Accessor!(Type)(sexp)[i];
}


pragma(inline, true)
auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, auto ref T[] value)
if(isIntegral!(I) && isBasicType!(T) /* && NonStringSEXP!(Type) */)
{
    //assert((i >= 0) && (n < LENGTH(sexp)), 
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
auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, I j, auto ref T value)
if(isIntegral!(I) && isBasicType!(T) /* && NonStringSEXP!(Type) */)
{
    //assert((i >= 0) && (j < LENGTH(sexp)) , 
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
auto getSlice(SEXPTYPE Type, I)(SEXP sexp, I i, I j)
if(isIntegral!(I) /* && NonStringSEXP!(Type) */)
{
    auto n = j - i;
    //assert((n <= LENGTH(sexp)) && (n >= 0), 
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
    scope(exit) unprotect_ptr(newVector);
    copyVector(newVector, originalVector);
    return newVector;
}


struct RVector(SEXPTYPE Type)
if(SEXPDataTypes!(Type))
{
    SEXP sexp;
    bool needUnprotect = false;
    //long refCount;
    alias ElType = SEXPElementType!(Type);
    //alias implicitCast this;

    private void unprotect()
    {
        if(needUnprotect)
        {
            unprotect_ptr(this.sexp);
            needUnprotect = false;
        }
    }
    @property size_t length() const @trusted
    {
        return LENGTH(cast(SEXP)this.sexp);
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
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.needUnprotect = true;
    }
    this(T)(T value) @trusted
    if(is(T == ElType) && !isIntegral!(T))
    {
        this.sexp = protect(allocVector(Type, 1));
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
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.needUnprotect = true;
        static if((Type == STRSXP))
        {
            for(long i = 0; i < n; ++i)
            {
                setSEXP!(Type)(this.sexp, i, arr[i]);
            }
        }else{
            Accessor!(Type)(this.sexp)[0..n] = arr[];
        }
    }
    /*
        Here we assume that SEXP are already protected
    */
    this(T)(T sexp) @trusted
    if(is(T == SEXP))
    {
        assert((Type == TYPEOF(sexp)) && isVector(sexp), 
            "Type of input is not the same as SEXPTYPE Type submitted");
        this.sexp = protect(sexp);
        this.needUnprotect = true;
    }
    /* For logical implicit from bool array */
    this(T)(T[] arr...) @trusted
    if(is(T == bool))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ 
                    Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = protect(allocVector(LGLSXP, cast(int)n));
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
        this.sexp = protect(allocVector(LGLSXP, cast(int)n));
        this.needUnprotect = true;
        Accessor!(LGLSXP)(this.sexp)[0..n] = (cast(int*)arr.ptr)[0..n];
    }
    /* Copy constructor */
    this(ref return scope RVector original) @trusted
    {
        int n = cast(int)original.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
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
        assert(this.length == 1, "Cannot cast to basic Type " ~ 
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
                assert(n == value.length, 
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
                assert(n == value.length, 
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
        assert(j >= i, 
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
                assert(value.length == n, 
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
                assert(value.length == n, 
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
        assert(n > 0, 
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
            assert(value.length == n, 
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
            assert(value.length == n, 
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
        assert(i <= j, 
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
            assert(value.length == n,
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
            assert(value.length == n, 
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
        assert(this.length == n, "Legnths of vector comparisons differ");
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
            assert(this.length == n, "Legnths of vector comparisons differ");
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
        assert(_names_.length == LENGTH(this.sexp), 
            "length of names not equal to length of sexp");
        Rf_setAttrib(this.sexp, R_NamesSymbol, To!SEXP(_names_));
        return;
    }
    @property auto names(SEXP _names_) @trusted
    {
        auto type = TYPEOF(_names_);
        assert(type == STRSXP, "Error no implementation of names method for type " 
            ~ type.stringof);
        assert(LENGTH(_names_) == LENGTH(this.sexp), 
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
    assert(_n_ >= 0, "Number of elements is negative");
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


auto constructNestedCall(string fName = "CDR", string arg = "arg", alias n)()
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
auto InternalCall0(Args...)(string fName, Args args)
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
auto InternalCall(Args...)(string fName, Args args) @system
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



unittest
{
    import std.stdio: writeln;
    initEmbedR();

    writeln("Start of RVector tests ...\n" ~ 
        "######################################################");
    writeln("Test 1 for instantiating basic R vectors ...");
    assert(NumericVector(1.0, 2, 3, 4).data == [1.0, 2, 3, 4],
            "Test failed for creating REALSXP vector");
    assert(IntegerVector(1, 2, 3, 4).data == [1, 2, 3, 4],
            "Test failed for creating INTSXP vector");
    assert(RawVector(cast(ubyte)1, cast(ubyte)2,
            cast(ubyte)3, cast(ubyte)4).data == [cast(ubyte)1, cast(ubyte)2,
            cast(ubyte)3, cast(ubyte)4], 
            "Test failed for creating RAWSXP");
    assert(ComplexVector(Rcomplex(1, 3), Rcomplex(2, 5), 
            Rcomplex(6, -5), Rcomplex(-7, 3)).data == 
            [Rcomplex(1, 3), Rcomplex(2, 5), Rcomplex(6, -5), 
            Rcomplex(-7, 3)]);
    assert(LogicalVector(TRUE, FALSE , FALSE, TRUE).data == 
            [TRUE, FALSE , FALSE, TRUE],
            "Test failed for creating LGLSXP");
    assert(CharacterVector("Flying", "in", "a", "blue", 
            "dream").data == ["Flying", "in", "a", "blue", "dream"],
            "Test failed for creating STRSXP");

    assert(NumericVector(4).length == 4, 
            "Test failed for REALSXP vector constructor");
    assert(IntegerVector(4).length == 4,
            "Test failed for INTSXP vector contructor");
    assert(RawVector(4).length == 4,
            "Test failed for RAWSXP vector contructor");
    assert(ComplexVector(4).length == 4,
            "Test failed for CPLXSXP vector contructor");
    assert(LogicalVector(4).length == 4,
            "Test failed for LGLSXP vector contructor");
    assert(CharacterVector(4).length == 4,
            "Test failed for STRSXP vector contructor");
    writeln("Test 1 for instantiating basic R vectors done.\n");
    
    writeln("Test 2 for opDollar and opIndex ...");
    auto x0a = CharacterVector("Flying", "in", "a", "blue", "dream");
    assert(x0a[$ - 1] == "dream", "Test opDollar or opIndexAssign failed");
    writeln("Test 2 for opDollar done.\n");

    writeln("Test 3 for opCast and opIndexAssign ...");
    auto x0b = CharacterVector(1);
    x0b[0] = "Hello World!";
    assert(cast(string)x0b == "Hello World!",
        "opCast(string) failed.");
    assert(x0b[0] == "Hello World!", "Test opIndexAssign failed");
    assert((cast(string[])x0a) == ["Flying", "in", "a", "blue", "dream"],
            "opCast(string[]) failed");
    writeln("Test 3 for opCast and opIndexAssign done.\n");

    writeln("Test 4 for opUnary and opIndexUnary ...");
    auto x0bc = IntegerVector(1, 2, 3, 4);
    assert((-x0bc).data == [-1, -2, -3, -4], "Test for opUnary failed");
    assert(++x0bc[2] == 4, "Test for opIndexUnary failed.");
    assert((++x0bc).data == [2, 3, 4, 5], "Tests for opUnary failed.");    
    writeln("Test 4 for opUnary done.\n");

    writeln("Test 5 for opIndexOpAssign ...");
    x0a[0] ~= " by";
    assert(x0a[0] == "Flying by", "opIndexOpAssign for STRSXP failed.");

    x0bc = IntegerVector(1, 2, 3, 4);
    x0bc[1] *= 3;
    assert(x0bc[1] == 6, "opIndexOpAssign for INTSXP failed.");

    auto x0c = LogicalVector(TRUE, FALSE , TRUE, TRUE);
    x0c[3] &= FALSE;
    assert(x0c[3] == FALSE, "opIndexOpAssign for LGLSXP failed.");
    writeln("Test 5 for opIndexOpAssign done.\n");


    writeln("Test 6 for opOpAssign ...");
    x0a = CharacterVector("Flying", "in", "a");
    x0a ~= ["blue", "dream"];
    assert(x0a.data == ["Flying", "in", "a", "blue", "dream"],
            "opOpAssign for CharacterVector and string[] failed");
    x0a = CharacterVector("Flying", "in", "a");
    x0a ~= CharacterVector("blue", "dream");
    assert(x0a.data == ["Flying", "in", "a", "blue", "dream"],
            "opOpAssign for CharacterVector and CharacterVector failed");
    x0c = LogicalVector(TRUE, FALSE , TRUE, FALSE);
    x0c ~= [TRUE, FALSE];
    assert(x0c.data == [TRUE, FALSE , TRUE, FALSE, TRUE, FALSE],
            "opOpAssign for LogicalVector and Rboolean[] failed");
    x0c = LogicalVector(TRUE, FALSE , TRUE, FALSE);
    x0c ~= LogicalVector(TRUE, FALSE);
    assert(x0c.data == [TRUE, FALSE , TRUE, FALSE, TRUE, FALSE],
            "opOpAssign for LogicalVector and LogicalVector failed");
    writeln("Test 6 for opOpAssign passed\n");

    writeln("Test 7 for copy constructor ...");
    assert(LogicalVector(x0c).data == x0c.data,
                "Copy constructor for logical vector failed.");
    assert(CharacterVector(x0a).data == x0a.data,
                "Copy constructor for character vector failed.");
    writeln("Test 7 for copy contructor passed.\n");

    writeln("Test 8 for opSlice ...");
    auto x1a = IntegerVector(1, 2, 3, 4, 5, 6);
    auto x1b = x1a[];
    assert(x1a.data == x1b.data, "opSlice() test 1 failed.");
    x1b = x1a[1..4];
    assert(x1b.data == [2, 3, 4], "opSlice(i, j) test 2 failed.");
    auto x1c = CharacterVector("Flying", "in", "a", "blue", "dream");
    auto x1d = x1c[];
    assert(x1c.data == x1d.data, "opSlice() test 3 failed.");
    x1d = x1c[1..4];
    assert(x1c[1..4].data == x1d.data, "opSlice(i, j) test 4 failed.");
    writeln("Test 8 for opSlice passed.\n");

    writeln("Test 9 for opBinary ...");

    assert((LogicalVector(FALSE) ~ 
            LogicalVector(TRUE, FALSE)).data == [FALSE, TRUE, FALSE],
            "opBinary test a (~) for LogicalVectors Failed.");
    auto x2a = ComplexVector(Rcomplex(1, 2), Rcomplex(-3, 1), Rcomplex(-5, 11));
    assert((ComplexVector(Rcomplex(1, 2)) ~ 
            ComplexVector(Rcomplex(-3, 1), Rcomplex(-5, 11))).data == x2a.data,
            "opBinary test b (~) for ComplexVector failed");
    x2a = ComplexVector(Rcomplex(1, 2), Rcomplex(-3, 1), Rcomplex(-5, 11),
                        Rcomplex(4, -5), Rcomplex(6, -3), Rcomplex(10, 4));
    auto x2d = ComplexVector(Rcomplex(-3, 4), Rcomplex(-5, -5), Rcomplex(-27, 1), 
                    Rcomplex(14, 3), Rcomplex(12, 9), Rcomplex(2, 24));
    assert((x2a * Rcomplex(1, 2)).data == x2d.data,
        "opBinary failed test c (*) for ComplexVectors");
    auto x2b = ["Flying", "in", "a", "blue", "dream"];
    assert((CharacterVector("Flying", "in", "a") ~ 
        CharacterVector("blue", "dream")).data == x2b,
        "opBinary test d (~) for CharacterVectors failed.");
    assert((CharacterVector("Flying", "in", "a") ~ 
        ["blue", "dream"]).data == x2b,
        "opBinary test e (~) for CharacterVector and string[] failed.");
    
    assert((NumericVector(1., 2.) ~ 
        NumericVector(3., 4.)).data == [1., 2, 3, 4], 
        "opBinary test f for NumericVectors failed.");
    assert((NumericVector(1., 2., 3.) + 
        NumericVector(3., 4., 6.)).data == [4., 6, 9],
        "opBinary test g (+) for NumericVectors failed.");
    assert((LogicalVector(TRUE, FALSE, TRUE) & 
        LogicalVector(FALSE, FALSE, TRUE)).data == [FALSE, FALSE, TRUE],
        "opBinary test h (&) for LogicalVector operators failed.");
    
    assert((LogicalVector(FALSE, TRUE, FALSE, TRUE) ~ FALSE).data == 
        [FALSE, TRUE, FALSE, TRUE, FALSE], 
        "opBinary test i (~) for LogicalVector and Rboolean item.");
    writeln("Test 9 for opBinary passed.\n");

    writeln("Test 10 for opSliceAssign ...");
    x1c = CharacterVector("Flying", "in", "a", "blue", "dream");
    x1c[3..$] = CharacterVector("crimson", "lake");
    assert(x1c.data == ["Flying", "in", "a", "crimson", "lake"],
        "opSliceAssign test a for CharacterVectors failed.");
    x1c[3..$] = ["blue", "dream"];
    assert(x1c.data == ["Flying", "in", "a", "blue", "dream"],
        "opSliceAssign test b for CharacterVector and string[] failed.");
    x1c[3..$] = "ahhh ...";
    assert(x1c.data == ["Flying", "in", "a", "ahhh ...", "ahhh ..."],
        "opSliceAssign test c for CharacterVector and string failed");
    auto x2c = NumericVector(1., 2, 3, 4, 5, 6);
    x2c[1..5] = 42.0;
    assert(x2c.data == [1., 42, 42, 42, 42, 6],
        "opSliceAssign test d for NumericVector and double failed");
    x2c[1..5] = [2., 3, 4, 5];
    assert(x2c.data == [1., 2, 3, 4, 5, 6],
        "opSliceAssign test e for NumericVector and double[] failed");
    x2c[1..5] = NumericVector(42., 42., 42., 42.);
    assert(x2c.data == [1., 42, 42, 42, 42, 6],
        "opSliceAssign test e for NumericVectors failed");
    x0c = LogicalVector(TRUE, FALSE, TRUE, FALSE);
    x0c[1..3] = FALSE;
    assert(x0c.data == [TRUE, FALSE, FALSE, FALSE],
        "opSliceAssign test f for LogicalVector and Rboolean failed");
    x0c[1..3] = [TRUE, TRUE];
    assert(x0c.data == [TRUE, TRUE, TRUE, FALSE],
        "opSliceAssign test g for LogicalVector and Rboolean[] failed");
    x0c[1..3] = LogicalVector(FALSE, FALSE);
    assert(x0c.data == [TRUE, FALSE, FALSE, FALSE],
        "opSliceAssign test h for LogicalVectors failed");
    x0c[] = TRUE;
    assert(x0c.data == [TRUE, TRUE, TRUE, TRUE],
        "opSliceAssign test i for LogicalVector and Rboolean failed");
    writeln("Test 10 for opSliceAssign passed.\n");

    writeln("Test 11 for opSliceOpAssign ...");
    x2c = NumericVector(1., 2, 3, 4, 5, 6, 7, 8, 9, 10);
    x2c[3..6] *= 3;
    assert(x2c[3..6].data == [12., 15, 18],
        "opSliceOpAssign failed test a for NumericVector");
    x2c[3..6] /= NumericVector(3., 3, 3);
    assert(x2c[3..6].data == [4., 5, 6],
        "opSliceOpAssign failed test b for NumericVector");
    x2c[3..6] *= [3., 3, 3];
    assert(x2c[3..6].data == [12., 15, 18],
        "opSliceOpAssign failed test c for NumericVector");
    
    x1c = CharacterVector("Flying", "in", "a", "blue", "dream");
    x1c[1..4] ~= " ahh...";
    assert(x1c.data == ["Flying", "in ahh...", "a ahh...", 
            "blue ahh...", "dream"], 
            "opSliceOpAssign failed test d for NumericVector");
    x1c = CharacterVector("Flying", "in", "a", "blue", "dream");
    x1c[1..4] ~= CharacterVector(" ahh...", " ahh...", " ahh...");
    assert(x1c.data == ["Flying", "in ahh...", "a ahh...", 
            "blue ahh...", "dream"], 
            "opSliceOpAssign failed test e for NumericVector");
    x1c = CharacterVector("Flying", "in", "a", "blue", "dream");
    x1c[1..4] ~= [" ahh...", " ahh...", " ahh..."];
    assert(x1c.data == ["Flying", "in ahh...", "a ahh...", 
            "blue ahh...", "dream"], 
            "opSliceOpAssign failed test f for NumericVector");
    
    x2a = ComplexVector(Rcomplex(1, 2), Rcomplex(-3, 1), Rcomplex(-5, 11),
                        Rcomplex(4, -5), Rcomplex(6, -3), Rcomplex(10, 4));
    x2a[1..($ - 1)] *= Rcomplex(1, 2);
    assert(x2a[1..($-1)].data == [Rcomplex(-5, -5), Rcomplex(-27, 1), 
            Rcomplex(14, 3), Rcomplex(12, 9)],
            "opSliceOpAssign failed test g for ComplexVector");
    writeln("Test 11 for opSliceOpAssign passed\n");


    writeln("Test 12 for names() and attributes ...");
    auto x2e = IntegerVector(1, 2, 3, 4);
    auto strNames = ["a", "b", "c", "d"];
    x2e.names = strNames;
    assert(x2e.names == strNames, "names(...) function test a failed");
    x2e = IntegerVector(1, 2, 3, 4);
    attr(x2e, "names", strNames);
    assert(x2e.names == strNames, "attr() function test b failed");
    writeln("Test 12 for names() and attributes passed\n");
    
    writeln("End of RVector tests.\n" ~ 
        "######################################################\n");
}

