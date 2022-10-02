import std.conv: to;

/* Vector aliases */
alias NumericVector = RVector!(REALSXP);
alias IntegerVector = RVector!(INTSXP);
alias LogicalVector = RVector!(LGLSXP);


struct RVector(SEXPTYPE Type)
if((Type == REALSXP) || (Type == INTSXP) || (Type == LGLSXP) || (Type == RAWSXP))
{
    SEXP sexp;
    bool need_unprotect;
    SEXPElementType!(Type)[] data;
    alias implicitCast this;
    
    private void unprotect()
    {
        if(need_unprotect)
        {
            unprotect_ptr(this.sexp);
            need_unprotect = false;
        }
    }
    size_t length()
    {
        return LENGTH(sexp);
    }
    this(T)(T n) @nogc
    if(isIntegral!(T))
    {
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(Type)(sexp)[0..n];
    }
    this(T)(T[] arr...)  @nogc
    if(is(T == SEXPElementType!(Type)))
    {
        auto n = arr.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        
        //If this doesn't work, replace with the commented lines below
        Accessor!(Type)(sexp)[0..n] = arr[];
        this.data = Accessor!(Type)(sexp)[0..n];
        
        //this.data = Accessor!(Type)(sexp)[0..n];
        //this.data[] = arr[];
    }
    this(T)(T sexp) @nogc
    if(is(T == SEXP))
    {
        assert(Type == TYPEOF(sexp), "Type of input is not the same as SEXPTYPE Type submitted");
        
        this.sexp = protect(sexp);
        this.need_unprotect = true;
        size_t n = LENGTH(sexp);
        this.data = Accessor!(Type)(sexp)[0..n];
    }
    /* Copy constructor */
    this(ref return scope RVector original)
    {
        int n = cast(int)original.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(Type)(original.sexp)[0..n];
    }
    //disable const copy
    @disable this(ref const(typeof(this)));

    ~this() @nogc
    {
        this.unprotect;
    }
    string toString() const
    {
        return to!(string)(data) ~ "\n";
    }
    /*
        Waiting till RVector!(STRSXP) is implemented
    */
    static if(false)
    {
        @property auto names()
        {
            SEXP __names__ = getAttrib(this.sexp, R_NameSymbol);
            return RVector!(STRSXP)(__names__);
        }
        @property auto names(T)(T __names__)
        if(is(T == SEXP))
        {
            assert(LENGTH(__names__) == length, "Length of names differ from length of SEXP object");
            __names__ = protect(__names__);
            setAttrib(this.__sexp__, R_NamesSymbol, __names__);
            unprotect_ptr(__names__);
            return;
        }
        @property auto names(T)(T __names__)
        if(is(T == RVector!(STRSXP)))
        {
            assert(__names__.length == length, "Length of names differ from length of SEXP object");
            SEXP __sexp__ = __names__.sexp;
            __sexp__.unprotect;
            setAttrib(this.__sexp__, R_NamesSymbol, __sexp__);
            return;
        }
        @property auto names(T)(T[] __names__)
        if(is(T == string))
        {
            assert(length(__names__) == length, "Length of names differ from length of SEXP object");
            SEXP __arr__ = To!(SEXP)(__names__);
            __arr__ = protect(__arr__);
            setAttrib(this.sexp, R_NamesSymbol, __arr__);
            unprotect_ptr(__arr__);
            return;
        }
    }
    SEXP implicitCast()
    {
        return cast(SEXP)this;
    }
    T opCast(T: SEXP)()
    {
      return this.sexp;
    }
    T opCast(T: SEXPElementType!(Type)[])()
    {
      return data;
    }
    T opCast(T: SEXPElementType!(Type))()
    {
      assert(length == 1, "Cannot cast to basic Type " ~ 
          SEXPElementType!(Type).stringof ~ 
          "length is not equal to 1");
      return data[0];
    }
    auto opIndex(size_t i) inout
    {
        return data[i];
    }
    auto opIndexUnary(string op)(size_t i) inout 
    {
        mixin ("return " ~ op ~ "data[i];");
    }
    auto opIndexAssign(T)(T value, size_t i) 
    {
        static if(is(T == SEXPElementType!(Type)))
        {
            return data[i] = value;
        }else static if(__traits(compiles, cast(SEXPElementType!(Type))value))
        {
            return data[i] = cast(SEXPElementType!(Type))value;
        }else
        {
            static assert(0, "unknown string Type value assign Type.");
        }
    }
    auto opIndexOpAssign(string op, T)(T value, size_t i)
    if(is(T == SEXPElementType!(Type)))
    {
        mixin ("return data[i] " ~ op ~ "= value;");
    }
}


unittest
{
    import std.stdio: writeln;
    import rinside.rembedded: Rf_initEmbeddedR, Rf_endEmbeddedR;
    
    enum rFlags = ["R", "--quiet", "--vanilla"];
    char*[] args;
    foreach(arg; rFlags)
    {
        args ~= toCString(arg);
    }
    
    int init = Rf_initEmbeddedR(cast(int)rFlags.length, args.ptr);
    assert(init, "R standalone failed to initialize");
    
    auto x0a = IntegerVector(3);
    x0a[0] = 0; x0a[1] = 1; x0a[2] = 2;
    assert(x0a.length == 3, "IntegerVector does not have the correct length");
    
    int[] x0b = [0, 1, 2];
    assert(x0a.data == x0b, "Unexpected content in vector");

    Rf_endEmbeddedR(0);
}


