/+
    Test VECTOR_PTR() for Accessor function
+/

struct List
{
    SEXP sexp;
    int[string] _names_;
    alias implicitCast this;
    bool needUnprotect = false;
    this(I)(I n)
    if(isIntegral!(I))
    {
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        needUnprotect = true;
    }
    this(SEXP sexp)
    {
        assert(TYPEOF(sexp) == VECSXP, "Argument is not a list.");
        this.sexp = sexp;
        SEXP lNames = Rf_getAttrib(this.sexp, R_NamesSymbol);
        if(LENGTH(lNames) > 0)
        {
            string[] keys = getSlice!(STRSXP)(lNames, 0, this.length);
            foreach(i; 0..length)
            {
                this._names_[keys[i]] = i;
            }
        }
    }
    ~this()
    {
        if(needUnprotect)
        {
            unprotect_ptr(sexp);
            needUnprotect = false;
        }
    }
    static auto init(Args...)(Args args)
    {
        enum n = Args.length;
        auto result = List(n);
        SEXP arg;
        static foreach(i; 0..n)
        {
            static if(!(is(Args[i] == SEXP) || isRType!(Args[i])))
            {
                arg = To!(SEXP)(args[i]);
                result[i] = arg;
            }else{
                result[i] = args[i];
            }
        }
        return result;
    }

    pragma(inline, true)
    SEXP opCast(T: SEXP)()
    {
        return this.sexp;
    }
    pragma(inline, true)
    SEXP implicitCast()
    {
        return cast(SEXP)this.sexp;
    }
    SEXP opIndex(I)(I i)
    if(isIntegral!(I))
    {
        assert((i < this.length) && (i >= 0), 
            "Indexing bounds error");
        return VECTOR_ELT(this.sexp, cast(int)i);
    }
    auto opIndexAssign(T, I)(T value, I i)
    if(isIntegral!(I))
    {
        static if(is(T == SEXP) || isRType!T)
        {
            SET_VECTOR_ELT(this.sexp, cast(int)i, value);
        }else static if(__traits(compiles, cast(SEXP)value))
        {
            SEXP _value_ = cast(SEXP)value;
            SET_VECTOR_ELT(this.sexp, cast(int)i, _value_);
        }else{
            assert(0, "No assign overload available for type " ~ T.stringof);
        }
    }
    auto length()
    {
        return LENGTH(this.sexp);
    }
    /*
        Gets the names
    */
    @property string[] names()
    {
        return _names_.keys;
    }
    /*
        Set names
    */
    @property auto names(A)(A lNames)
    if(is(A == SEXP) || is(A == string[]))
    {
        static if(is(A == SEXP))
        {
            assert((LENGTH(lNames) == this.length) &&
                    (Rf_isString(lNames)),
                "Length of names submitted is not equal to list length");
            //this._names_.length = this.length;

            string[] keys = getSlice!(STRSXP)(this.sexp, 0, this.length);
            foreach(i; 0..length)
            {
                this._names_[keys[i]] = i;
            }
            Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
        }else static if(is(A == string[]))
        {
            //this._names_.length = this.length;
            assert(lNames.length == this.length,
                "Length of names submitted is not equal to list length");
            foreach(i; 0..length)
            {
                this._names_[lNames[i]] = i;
            }
            SEXP _lNames_ = To!(SEXP)(lNames);
            Rf_setAttrib(this.sexp, R_NamesSymbol, _lNames_);
        }
    }
    SEXP opIndex(string _name_)
    {
        if(!isin(_name_, this._names_.keys))
        {
            return R_NilValue;
        }
        auto i = this._names_[_name_];
        SEXP result = VECTOR_ELT(this.sexp, cast(int)i);
        return result;
    }
    auto opIndexAssign(T)(T value, string _name_)
    {
        auto i = this._names_[_name_];
        static if(is(T == SEXP) || isRType!T)
        {
            SET_VECTOR_ELT(this.sexp, cast(int)i, value);
        }else static if(__traits(compiles, To!(SEXP)(value)))
        {
            SEXP _value_ = To!(SEXP)(value);
            SET_VECTOR_ELT(this.sexp, cast(int)i, _value_);
        }else{
            assert(0, "No assign overload available for type " ~ T.stringof);
        }
    }
}


