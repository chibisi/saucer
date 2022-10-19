import std.conv: to;
import std.stdio: writeln;

/* Vector aliases */
alias NumericVector = RVector!(REALSXP);
alias IntegerVector = RVector!(INTSXP);
alias LogicalVector = RVector!(LGLSXP);
alias RawVector = RVector!(RAWSXP);
alias ComplexVector = RVector!(CPLXSXP);
alias CharacterVector = RVector!(STRSXP);

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
auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, ref T[] value)
if(isIntegral!(I) /* && isBasicType!(T) && NonStringSEXP!(Type) */)
{
    assert((i >= 0) && (n < LENGTH(sexp)), 
            "Requested range not less than or " ~ 
                "equal to length of array.");
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
auto setSlice(SEXPTYPE Type, T, I)(SEXP sexp, I i, I j, ref T value)
if(isIntegral!(I) /* && isBasicType!(T) && NonStringSEXP!(Type) */)
{
    assert((i >= 0) && (j < LENGTH(sexp)), 
        "Issue with range of object requested");
    
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
    assert((n <= LENGTH(sexp)) && (n >= 0), 
            "Requested range not less than or " ~ 
                "equal to length of array.");
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



struct RVector(SEXPTYPE Type)
if(SEXPDataTypes!(Type))
{
    SEXP sexp;
    bool need_unprotect;
    alias ElType = SEXPElementType!(Type);
    alias implicitCast this;

    private void unprotect()
    {
        if(need_unprotect)
        {
            unprotect_ptr(this.sexp);
            need_unprotect = false;
        }
    }
    @property size_t length() const
    {
        return LENGTH(cast(SEXP)this.sexp);
    }
    @property auto length(T)(T n)
    if(isIntegral!(T))
    {
        SETLENGTH(this.sexp, cast(int)n);
        return this.length;
    }
    @property ElType[] data()
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
    this(T)(T n)
    if(isIntegral!(T))
    {
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
    }
    this(T)(T[] arr...)
    if(is(T == ElType))
    {
        auto n = arr.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
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
    this(T)(T sexp)
    if(is(T == SEXP))
    {
        assert(Type == TYPEOF(sexp), 
            "Type of input is not the same as SEXPTYPE Type submitted");
        
        this.sexp = protect(sexp);
        this.need_unprotect = true;
    }
    /* For logical implicit from bool array */
    this(T)(T[] arr...)
    if(is(T == bool))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ 
                    Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = protect(allocVector(LGLSXP, cast(int)n));
        this.need_unprotect = true;
        int* _data_ = Accessor!(LGLSXP)(this.sexp)[0..n];
        foreach(i; 0..n)
        {
            _data_[i] = arr[i];
        }
    }
    /* Using R's boolean */
    this(T)(T[] arr...)
    if(is(T == Rboolean))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ 
                    Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = protect(allocVector(LGLSXP, cast(int)n));
        this.need_unprotect = true;
        //int* _data_ = Accessor!(LGLSXP)(this.sexp)[0..n];
        Accessor!(LGLSXP)(this.sexp)[0..n] = (cast(int*)arr.ptr)[0..n];
        /*foreach(i; 0..n)
        {
            _data_ = arr[i];
        }*/
    }
    /* Copy constructor */
    this(ref return scope RVector original)
    {
        int n = cast(int)original.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        static if((Type == STRSXP))
        {
            foreach(i; 0..n)
            {
                ElType element = getSEXP!(Type)(original.sexp, i);
                setSEXP!(Type)(this.sexp, i, element);
            }
        }else static if(Type == LGLSXP)
        {
            Accessor!(Type)(this.sexp)[0..n] = (cast(int*)original.ptr)[0..n];
        }else{
            Accessor!(Type)(this.sexp)[0..n] = 
                        Accessor!(Type)(original.sexp)[0..n];
        }
    }
    //disable const copy for now
    @disable this(ref const(typeof(this)));

    ~this()
    {
        this.unprotect;
    }
    string toString()
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
    T opCast(T: SEXP)()
    {
        return this.sexp;
    }
    @property SEXP implicitCast()
    {
        return cast(SEXP)this;
    }
    T opCast(T: ElType)()
    {
        assert(this.length == 1, "Cannot cast to basic Type " ~ 
            ElType.stringof ~ 
            "length is not equal to 1");
        return this[0];
    }
    T opCast(T: ElType[])()
    {
        auto n = this.length;
        return getSlice!(Type)(this.sexp, 0, n);
    }
    auto opDollar()
    {
        return this.length();
    }
    ElType opIndex(size_t i)
    {
        return getSEXP!(Type)(this.sexp, i);
    }
    /* Generates a copy for now */
    RVector opUnary(string op)()
    {
        auto n = this.length;
        auto arr = getSlice!(Type)(this.sexp, 0, n);
        auto result = arr.dup;

        mixin("result[] = " ~ op ~ "arr[];");
        return RVector!(Type)(result);
    }
    auto opIndexUnary(string op)(size_t i) 
    {
        auto result = this[i];
        mixin ("result = " ~ op ~ "result;");
        return result;
    }
    ElType opIndexAssign(T)(auto ref T value, size_t i)
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
    auto opIndexOpAssign(string op, T)(auto ref T value, size_t i)
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
    auto ref RVector opOpAssign(string op, T)(T value) return
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
                }else{
                    this.ptr[last] = value;
                }
            }else{ /* For other operations */
                auto n = this.length;
                static if(Type != STRSXP)
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
            return this;
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
            return this;
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
            return this;
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
            return this;
        }else{
            static assert(0, "Unknown type " ~ T.stringof ~ " for opOpAssign.");
        }
    }

    RVector opSlice()
    {
        auto n = this.length;
        static if(Type != STRSXP)
        {
            return RVector!(Type)(this.ptr[0..n]);
        }else{
            auto result = getSlice!(Type)(this.sexp, 0, n);
            return RVector!(Type)(result);
        }
    }
}


unittest
{
    import std.stdio: writeln;
    initEmbedR();

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
    
    endEmbedR();
}

