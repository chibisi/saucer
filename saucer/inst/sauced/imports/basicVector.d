import std.conv: to;

/* Vector aliases */
alias NumericVector = RVector!(REALSXP);
alias IntegerVector = RVector!(INTSXP);
alias LogicalVector = RVector!(LGLSXP);
alias RawVector = RVector!(RAWSXP);


import std.stdio: writeln;

struct RVector(SEXPTYPE Type)
if((Type == REALSXP) || (Type == INTSXP) || (Type == LGLSXP) || (Type == RAWSXP))
{
    SEXP sexp;
    bool need_unprotect;
    alias ElType = SEXPElementType!(Type);
    ElType[] data;
    alias implicitCast this;
    
    private void unprotect()
    {
        if(need_unprotect)
        {
            unprotect_ptr(this.sexp);
            need_unprotect = false;
        }
    }
    @property size_t length()
    {
        return LENGTH(sexp);
    }
    @property auto length(T)(T n)
    if(isIntegral!(T))
    {
        SETLENGTH(this.sexp, cast(int)n);
        data.length = n;
        return this.length;
    }

    this(T)(T n)// @nogc
    if(isIntegral!(T))
    {
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(Type)(sexp)[0..n];
    }
    this(T)(T[] arr...)//  @nogc
    if(is(T == ElType))
    {
        auto n = arr.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(Type)(sexp)[0..n];
        Accessor!(Type)(sexp)[0..n] = arr[];
    }
    this(T)(T sexp)// @nogc
    if(is(T == SEXP))
    {
        assert(Type == TYPEOF(sexp), "Type of input is not the same as SEXPTYPE Type submitted");
        
        this.sexp = protect(sexp);
        this.need_unprotect = true;
        size_t n = LENGTH(sexp);
        this.data = Accessor!(Type)(sexp)[0..n];
    }
    /* For logical implicit from bool array */
    this(T)(T[] arr)
    if(is(T == bool))
    {
        static assert(Type == LGLSXP, "Wrong SEXP given :" ~ Type ~ ", LGLSXP expected.");
        auto n = arr.length;
        this.sexp = protect(allocVector(LGLSXP, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(LGLSXP)(sexp)[0..n];
        foreach(i; 0..arr.length)
        {
            this.data[i] = arr[i];
        }
    }
    /* Copy constructor */
    this(ref return scope RVector original)
    {
        int n = cast(int)original.length;
        this.sexp = protect(allocVector(Type, cast(int)n));
        this.need_unprotect = true;
        this.data = Accessor!(Type)(sexp)[0..n];
        foreach(i; 0..n)
        {
            this.data[i] = original[i];
        }
    }
    //disable const copy
    @disable this(ref const(typeof(this)));

    ~this()// @nogc
    {
        this.unprotect;
    }
    string toString() const
    {
        return "RVector!(" ~ Type.stringof ~ ")(" ~ to!(string)(this.data) ~ ")\n";
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
    LogicalVector opEquals(T)(T arr)
    if(is(T == ElType[]) || is(T == RVector))
    {
        auto n = this.length;
        assert(arr.length == n, "Length of arrays not equal");
        auto result = LogicalVector(n);
        foreach(i; 0..n)
        {
            result[i] = arr[i] == data[i];
        }
        return result;
    }
    LogicalVector gt(T)(T rvec)
    if(is(T == ElType[]) || is(T == RVector))
    {
        auto n = this.length;
        assert(rvec.length == n);
        auto result = LogicalVector(n);
        foreach(i; 0..n)
        {
            result[i] = this.data[i] > rvec[i];
        }
        return result;
    }
    LogicalVector gteq(T)(T rvec)
    if(is(T == ElType[]) || is(T == RVector))
    {
        auto n = this.length;
        assert(rvec.length == n);
        auto result = LogicalVector(n);
        foreach(i; 0..n)
        {
            result[i] = this.data[i] >= rvec[i];
        }
        return result;
    }
    LogicalVector lt(T)(T rvec)
    if(is(T == ElType[]) || is(T == RVector))
    {
        auto n = this.length;
        assert(rvec.length == n);
        auto result = LogicalVector(n);
        foreach(i; 0..n)
        {
            result[i] = this.data[i] < rvec[i];
        }
        return result;
    }
    LogicalVector lteq(T)(T rvec)
    if(is(T == ElType[]) || is(T == RVector))
    {
        auto n = this.length;
        assert(rvec.length == n);
        auto result = LogicalVector(n);
        foreach(i; 0..n)
        {
            result[i] = this.data[i] <= rvec[i];
        }
        return result;
    }
    T opCast(T: SEXP)()
    {
      return this.sexp;
    }
    T opCast(T: ElType[])()
    {
      return data;
    }
    T opCast(T: ElType)()
    {
      assert(length == 1, "Cannot cast to basic Type " ~ 
          ElType.stringof ~ 
          "length is not equal to 1");
      return data[0];
    }
    SEXP implicitCast()
    {
        return cast(SEXP)this;
    }
    ElType opIndex(size_t i) inout
    {
        return data[i];
    }
    /* Generates a copy for now */
    RVector opUnary(string op)()
    {
        auto result = RVector!(Type)(this);
        mixin("result.data[] = " ~ op ~ "result.data[];");
        return result;
    }
    auto opIndexUnary(string op)(size_t i) 
    {
        mixin ("return " ~ op ~ "data[i];");
    }
    auto opIndexAssign(T)(T value, size_t i) 
    {
        static if(is(T == ElType))
        {
            return data[i] = value;
        }else static if(__traits(compiles, cast(ElType)value))
        {
            return data[i] = cast(ElType)value;
        }else
        {
            static assert(0, "unknown string Type value assign Type.");
        }
    }
    auto opIndexOpAssign(string op)(ElType value, size_t i)
    {
        static if(op == "~")
        {
            static assert("Insertion (~) not valid for indexing operation.");
        }else{
            mixin("data[i] " ~ op ~ "= value;");
        }
    }
    ref RVector opOpAssign(string op)(ElType value) return
    {
        static if(op == "~") /* For appends */
        {
            this.length = this.length + 1;
            data[$ - 1] = value;
        }else{
            mixin("data[] " ~ op ~ "= value;");
        }
        return this;
    }
    ref RVector opOpAssign(string op)(ElType[] arr) return
    {
        static if(op == "~") /* For appends */
        {
            auto origLength = this.length;
            this.length = this.length + arr.length;
            data[origLength..$] = arr[];
        }else{
            mixin("data[] " ~ op ~ "= arr[];");
        }
        return this;
    }
    ref RVector opOpAssign(string op)(RVector rvec) return
    {
        static if(op == "~") /* For appends */
        {
            auto origLength = this.length;
            this.length = this.length + rvec.length;
            data[origLength..$] = rvec.data[];
        }else{
            mixin("data[] " ~ op ~ "= rvec.data[];");
        }
        return this;
    }
    auto opDollar()
    {
        return length;
    }
    ElType[] opSlice()
    {
        return data[];
    }
    ElType[] opSlice(size_t i, size_t j)
    {
        return data[i..j];
    }
    auto opSliceAssign(ElType value)
    {
        data[] = value;
    }
    auto opSliceAssign(ElType[] arr)
    {
        assert(arr.length == length, "Lengths of array replacement differs from target range");
        data[] = arr[];
    }
    auto opSliceAssign(ElType value, size_t i, size_t j)
    {
        data[i..j] = value;
    }
    auto opSliceAssign(ElType[] arr, size_t i, size_t j)
    {
        assert(arr.length == j - i, "Lengths of array replacement differs from target range");
        data[i..j] = arr[];
    }
    auto opSliceOpAssign(string op)(ElType value)
    {
        static if(op == "~") /* For appends */
        {
            this.length = this.length + 1;
            data[$ - 1] = value;
            return;
        }else{
            mixin ("data[] " ~ op ~ "= value;");
            return;
        }
    }
    auto opSliceOpAssign(string op)(ElType[] arr)
    {
        static if(op == "~") /* For appends */
        {
            auto origLength = this.length;
            auto n = this.length + arr.length;
            this.length = n;
            data[origLength..$] = arr[];
            return;
        }else{
            assert(arr.length == length, "Lengths of array replacement differs from target range");
            mixin("data[] " ~ op ~ "= arr[];");
            return;
        }
    }
    auto opSliceOpAssign(string op)(ElType value, size_t i, size_t j)
    {
        static if(op == "~")
        {
            static assert("Operator ~ not yet implemented.");
        }else{
            mixin("data[i..j] " ~ op ~ "= value;");
        }
    }
    auto opSliceOpAssign(string op)(ElType[] arr, size_t i, size_t j)
    {
        static if(op == "~")
        {
            static assert("Operator ~ not yet implemented.");
        }else{
            assert(arr.length == j - i, "Lengths of array replacement differs from target range");
            mixin ("data[i..j] " ~ op ~ "= arr[];");
        }
    }
    RVector opBinary(string op)(ElType value)
    {
        auto result = RVector!(Type)(this);
        mixin("result[] " ~ op ~ "=value;");
        return result;
    }
    RVector opBinary(string op)(ElType[] arr)
    {
        assert(this.length == arr.length, "Array is of different from the RVector");
        auto result = RVector!(Type)(this);
        mixin("result[] " ~ op ~ "= arr[];");
        return result;
    }
    RVector opBinary(string op)(RVector rvec)
    {
        assert(this.length == rvec.length, "Array is of different from the RVector");
        auto result = RVector!(Type)(this);
        mixin("result[] " ~ op ~ "= rvec[];");
        return result;
    }
}


unittest
{
    import std.stdio: writeln;

    initEmbedR();
    
    auto x0a = IntegerVector(3);
    x0a[0] = 0; x0a[1] = 1; x0a[2] = 2;
    assert(x0a.length == 3, "IntegerVector does not have the correct length");
    
    int[] x0b = [0, 1, 2];
    assert(x0a.data == x0b, "Unexpected content in vector, opIndexAssign function failed");
    assert(x0a[1] == 1, "opIndex failed");

    double[] basicData = [1.0, 2, 3, 4, 5];
    auto x1a = NumericVector(basicData);
    auto x1b = NumericVector(basicData.dup);
    foreach(i; 0..basicData.length)
    {
        x1a[i] *= x1b[i];
    }
    assert(x1a.data == [1.0, 4, 9, 16, 25], "opIndexOpAssign function failed");

    ++x1a[1];
    assert(x1a[1] == 5.0, "opIndexUnary test failed");

    assert(x1a[$ - 1] == 25, "opDollar failed");
    assert(x1a[] == [1.0, 5, 9, 16, 25], "No parameter opSlice() function failed");
    assert(x1a[1..4] == [5.0, 9, 16], "Two parameter opSlice() function failed");
    
    x1a[] = 10.0;
    assert(x1a.data == [10.0, 10.0, 10.0, 10.0, 10.0], "One parameter opSliceAssign() function failed");
    
    x1a[1..4] = 12.0;
    assert(x1a.data == [10.0, 12.0, 12.0, 12.0, 10.0], "Three parameter opSliceAssign() function failed");

    x1a[] = [15.0, 15.0, 15.0, 15.0, 15.0];
    assert(x1a.data == [15.0, 15.0, 15.0, 15.0, 15.0], "One array parameter opSliceAssign() function failed");

    x1a[1..4] = [18.0, 18.0, 18.0];
    assert(x1a.data == [15.0, 18.0, 18.0, 18.0, 15.0], "Three parameter opSliceAssign() function failed");

    x1a[] -= 2;
    assert(x1a.data == [13.0, 16.0, 16.0, 16.0, 13.0], "One parameter opSliceOpAssign() function failed");

    x1a[] += [2.0, -1, -1, -1, 2];
    assert(x1a.data == [15.0, 15.0, 15.0, 15.0, 15.0], "One array parameter opSliceOpAssign() function failed");

    x1a[1..4] -= 2.0;
    assert(x1a.data == [15.0, 13.0, 13.0, 13.0, 15.0], "Three parameter opSliceOpAssign() function failed");

    x1a[1..4] += [2.0, 2, 2];
    assert(x1a.data == [15.0, 15.0, 15.0, 15.0, 15.0], "Three array parameter opSliceOpAssign() function failed");
    
    assert(LogicalVector([true, false, true]).data == [1, 0, 1], "Error in LogicalVector constructor from bool[]");

    assert((NumericVector(1.0, 2, 4, 5) == NumericVector(1.0, 2, 4, 5)).data == [1, 1, 1, 1], "RVector opEquals failed");
    assert((NumericVector(1.0, 2, 4, 5) == [1.0, 2, 4, 5]).data == [1, 1, 1, 1], "RVector array opEquals failed");

    assert(NumericVector(1.0, 2, 4, 5).gt(NumericVector(0.0, 1, 7, 8)).data == [1, 1, 0, 0], "RVector gt failed");
    assert(NumericVector(1.0, 2, 4, 5).gt([0.0, 1, 7, 8]).data == [1, 1, 0, 0], "RVector gt failed");

    assert(NumericVector(1.0, 2, 4, 5).gteq(NumericVector(0.0, 5, 4, 7)).data == [1, 0, 1, 0], "RVector gteq failed");
    assert(NumericVector(1.0, 2, 4, 5).gteq([0.0, 5, 4, 7]).data == [1, 0, 1, 0], "RVector and array gteq failed");

    assert(NumericVector(1.0, 2, 4, 5).lt(NumericVector(0.0, 1, 7, 8)).data == [0, 0, 1, 1], "RVector lt failed");
    assert(NumericVector(1.0, 2, 4, 5).lt([0.0, 1, 7, 8]).data == [0, 0, 1, 1], "RVector lt failed");

    assert(NumericVector(1.0, 2, 4, 5).lteq(NumericVector(0.0, 5, 4, 3)).data == [0, 1, 1, 0], "RVector lteq failed");
    assert(NumericVector(1.0, 2, 4, 5).lteq([0.0, 5, 4, 3]).data == [0, 1, 1, 0], "RVector and array lteq failed");

    x1a.length = 20;
    assert(x1a.length == 20, "Failed setting the length of the numeric vector");

    x1a = NumericVector(1.0, 2, 3, 4); x1a = -x1a;
    assert(x1a.data == [-1.0, -2, -3, -4], "RVector opUnary failed.");

    x1a ~= 5.0;
    assert(x1a.data == [-1.0, -2, -3, -4, 5], "RVector opOpAssign for scalar element failed.");

    x1a = NumericVector(1., 2, 3, 4);
    x1b = NumericVector(5., 6, 7, 8);
    x1a ~= x1b;
    assert(x1a.data == [1., 2, 3, 4, 5, 6, 7, 8], "RVector test for opOpAssign append operation failed");

    x1a = NumericVector(1., 2, 3, 4);
    x1b = NumericVector(5., 6, 7, 8);
    x1a += x1b;
    assert(x1a.data == [6., 8, 10, 12], "RVector test for opOpAssign (+=) operation failed");
    
    x1a = NumericVector(1., 2, 3, 4);
    x1a += [5., 6, 7, 8];
    assert(x1a.data == [6., 8, 10, 12], "RVector and array test for opOpAssign (+=) operation failed");

    x1a = NumericVector(1., 2, 3, 4);
    x1b = NumericVector(5., 6, 7, 8);
    assert((x1a - x1b).data == [-4, -4, -4, -4], "RVector vs RVector opBinary operation failed.");
    assert((x1a - [5., 6, 7, 8]).data == [-4, -4, -4, -4], "RVector vs array opBinary operation failed.");
    assert((x1b - 4).data == [1, 2, 3, 4], "RVector vs element opBinary operation failed.");

    endEmbedR();
}


