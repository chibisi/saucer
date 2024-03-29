/*
  Class creates an RMatrix
*/

/* Matrix aliases */
alias NumericMatrix = RMatrix!(REALSXP);
alias IntegerMatrix = RMatrix!(INTSXP);
alias ComplexMatrix = RMatrix!(CPLXSXP);
alias CharacterMatrix = RMatrix!(STRSXP);
alias StringMatrix = CharacterMatrix;
alias LogicalMatrix = RMatrix!(LGLSXP);
alias RawMatrix = RMatrix!(RAWSXP);



/*
    Expression Template
*/
private struct MatrixExpression(string op, E1, E2)
if(
    (isRMatrixOrExpression!E1 || isBasicType!E1) && (isRMatrixOrExpression!E2 || isBasicType!E2)
)
{
    E1 lhs;
    E2 rhs;

    this(E1, E2)(E1 lhs, E2 rhs)
    if(isRMatrixOrExpression!E1 && isRMatrixOrExpression!E2)
    {
        auto lhsNRow = lhs.nrow;
        auto lhsNCol = lhs.ncol;

        auto rhsNRow = rhs.nrow;
        auto rhsNCol = rhs.ncol;

        enforce(lhsNRow == rhsNRow,
            "Number of rows on both sides of the operator are not equal");
        enforce(lhsNCol == rhsNCol,
            "Number of columns on both sides of the operator are not equal");
        
        this.lhs = lhs;
        this.rhs = rhs;
    }
    
    this(E1, E2)(E1 lhs, E2 rhs)
    if(isRMatrixOrExpression!E1 && isBasicType!E2)
    {
        this.lhs = lhs;
        this.rhs = rhs;
    }
    this(E1, E2)(E1 lhs, E2 rhs)
    if(isBasicType!E1 && isRMatrixOrExpression!E2)
    {
        this.lhs = lhs;
        this.rhs = rhs;
    }
    
    this(ref return scope MatrixExpression original)
    {
        this.lhs = original.lhs;
        this.rhs = original.rhs;
    }
    
    auto nrow()
    {
        static if(__traits(compiles, lhs.nrow))
        {
            return lhs.nrow;
        }
        else static if(__traits(compiles, rhs.nrow))
        {
            return rhs.nrow;
        }
        else
        {
            static assert(0, "Neither argument has an nrow method.");
        }
    }
    
    auto ncol()
    {
        static if(__traits(compiles, lhs.ncol))
        {
            return lhs.ncol;
        }
        else static if(__traits(compiles, rhs.ncol))
        {
            return rhs.ncol;
        }
        else
        {
            static assert(0, "Neither argument has an ncol method.");
        }
    }
    
    pragma(inline, true) auto opCast(T: SEXP)() @trusted
    {
        import std.traits: ReturnType;
        alias ElType = ReturnType!(opIndex!int);
        alias Type = MapToSEXP!(ElType);
        RMatrix!(Type) result = this;
        return result.sexp;
    }
    
    auto opIndex(I)(I i, I j) @trusted
    if(isIntegral!I)
    {
        static if(isRMatrixOrExpression!E1 && isRMatrixOrExpression!E2)
        {
            mixin(`return lhs[i, j] ` ~ op ~ ` rhs[i, j];`);
        }
        else static if(isRMatrixOrExpression!E1 && isBasicType!E2)
        {
            mixin(`return lhs[i, j] ` ~ op ~ ` rhs;`);
        }else static if(isBasicType!E1 && isRMatrixOrExpression!E2)
        {
            mixin(`return lhs ` ~ op ~ ` rhs[i, j];`);
        }else
        {
            static assert(0, "Neighter argument has matrix[i, j] indexing");
        }
    }
    
    pragma(inline, true) auto opBinary(string op, T)(auto ref T rhs)
    {
        return operator!(op)(this, rhs);
    }
    pragma(inline, true) auto opBinaryRight(string op, T)(auto ref T lhs)
    {
        return operator!(op)(lhs, this);
    }
}


enum isRMatrixExpression(T) = is(T: MatrixExpression!(op, E1, E2), alias op, E1, E2) || 
                                    is(T: View!(U), alias U);
enum isRMatrixOrExpression(T) = isRMatrix!(T) || isRMatrixExpression!(T);
enum isRMatrixExpressionOrBasicType(T) = isBasicType!T || isRMatrixOrExpression!T;


/*
    All the binary overload operators
*/
auto operator(string op, E1, E2)(auto ref E1 lhs, auto ref E2 rhs)
if ((isRMatrixOrExpression!E1 && isBasicType!E2) ||
        (isBasicType!E1 && isRMatrixOrExpression!E2) ||
        (isRMatrixOrExpression!E1 && isRMatrixOrExpression!E2))
{
    return MatrixExpression!(op, E1, E2)(lhs, rhs);
}


private struct View(alias Type)
if(SEXPDataTypes!(Type))
{
    private SEXP sexp;
    private size_t i = 0;
    private size_t j = 0;
    private size_t k = 0;
    private size_t l = 0;
    this(SEXP sexp)
    {
        enforce(cast(bool)Rf_isMatrix(sexp),
            "Item to view is not a matrix");
        this.sexp = sexp;
        this.j = this._nrows_;
        this.l = this._ncols_;
    }
    pragma(inline, true) private auto _nrows_()
    {
        return Rf_nrows(this.sexp);
    }
    pragma(inline, true) private auto _ncols_()
    {
        return Rf_ncols(this.sexp);
    }
    pragma(inline, true) private auto nrow()
    {
        return cast(size_t)(this.j - this.i);
    }
    pragma(inline, true) private auto ncol()
    {
        return cast(size_t)(this.l - this.k);
    }
    auto opIndex(I)(I[2] r0, I[2] r1) @trusted
    if(isIntegral!I)
    {
        enforce(r0[1] <= this._nrows_,
            "Row limit can not be greater than number of rows");
        enforce(r1[1] <= this._ncols_,
            "Col limit can not be greater than number of rows");
        this.i = cast(size_t)r0[0];
        this.j = cast(size_t)r0[1];
        this.k = cast(size_t)r1[0];
        this.l = cast(size_t)r1[1];
        return this;
    }
    auto opIndex(I)(I m, I n)
    if(isIntegral!I)
    {
        enforce((m >= 0) && (m < this.nrow),
            "First index is not in range [0, nrow]");
        enforce((n >= 0) && (n < this.ncol),
            "First index is not in range [0, ncol]");
    auto ptr = Accessor!(Type)(this.sexp);
        return ptr[(m + this.i) + this._nrows_*(n + this.k)];
    }
    pragma(inline, true) @property auto opDollar(size_t dim: 0)() @trusted
    {
        return this.nrow;
    }
    pragma(inline, true) @property auto opDollar(size_t dim: 1)() @trusted
    {
        return this.ncol;
    }
    I[2] opSlice(size_t dim, I)(I start, I end) @trusted
    if(isIntegral!I && ((dim >= 0) && (dim < 2)))
    {
        enforce(start >= 0 && end <= this.opDollar!dim, 
        "Start and end indexes are not withing dimension limits");
        return [start, end];
    }
}



struct RMatrix(alias Type)
if(SEXPDataTypes!(Type))
{
    private SEXP sexp;
    private bool needUnprotect = false;
    View!(Type) view;
    static if(Type != STRSXP)
    {
        alias ElType = SEXPElementType!(Type);
    }else{
        alias ElType = SEXP;
    }
    
    this(T)(T n_row, T n_col) @trusted
    if(isIntegral!(T))
    {
        this.sexp = allocMatrix(Type, cast(int)n_row, cast(int)n_col);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        this.view = View!(Type)(this.sexp);
    }
    
    this(T, I)(T[] arr, I n_row, I n_col) @trusted
    if(is(T: SEXPElementType!(Type)) && isIntegral!(I))
    {
        auto n = arr.length;
        enforce(n == n_row*n_col, "Length of array is not equal to multiple of nrow x ncol");
        this.sexp = allocMatrix(Type, cast(int)n_row, cast(int)n_col);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        static if(Type != STRSXP)
        {
            this.ptr[0..n] = arr[0..n];
        }else{
            auto ptr = this.ptr;
            foreach(i; 0..n)
            {
              ptr[i] = mkChar(arr[i]);
            }
        }
        this.view = View!(Type)(this.sexp);
    }
    this(T, I)(T value, I nrow, I ncol) @trusted
    if(is(T: SEXPElementType!(Type)) && isIntegral!(I))
    {
        auto n = nrow * ncol;
        this.sexp = allocMatrix(Type, cast(int)nrow, cast(int)ncol);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        static if(Type != STRSXP)
        {
            this.ptr[0..n] = value;
        }else
        {
            this.ptr[0..n] = mkChar(value);
        }
        this.view = View!(Type)(this.sexp);
    }
    
    this(SEXP sexp) @trusted
    {
        enforce((Type == rTypeOf(sexp)) && isMatrix(sexp), 
          "Type of input is not the same of SEXPTYPE type submitted");
        this.sexp = sexp;
    }
    
    this(E)(E expr) @trusted
    if(isRMatrixExpression!E)
    {
        auto nrow = expr.nrow;
        auto ncol = expr.ncol;
        auto n = nrow * ncol;
        this.sexp = allocMatrix(Type, cast(int)nrow, cast(int)ncol);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        static if(Type != STRSXP)
        {
            this.ptr[0..n] = 0;
        }else
        {
            string tmp = "";
            this.ptr[0..n] = mkChar(tmp);
        }
        for(long j = 0; j < this.ncol; ++j)
        {
            for(long i = 0; i < this.nrow; ++i)
            {
                this[i, j] = expr[i, j];
            }
        }
        this.view = View!(Type)(this.sexp);
    }
    
    this(ref return scope RMatrix original) @trusted
    {
        int n = cast(int)original.length;
        this.sexp = allocMatrix(Type, cast(int)original.nrow, cast(int)original.ncol);
        R_PreserveObject(this.sexp);
        this.needUnprotect = true;
        copyMatrix(this.sexp, original.sexp, FALSE);
        this.view = View!(Type)(this.sexp);
    }
    
    ~this() @trusted
    {
        this.unprotect;
    }
    
    void unprotect()
    {
        if(needUnprotect)
        {
            R_ReleaseObject(this.sexp);
            needUnprotect = false;
        }
    }
    
    @property auto ptr()
    {
        return Accessor!(Type)(this.sexp);
    }
    
    auto opIndex(I)(I[2] r0, I[2] r1) @trusted 
    if(isIntegral!I)
    {
        auto nrow = r0[1] - r0[0];
        auto ncol = r1[1] - r1[0];
        auto sexp = allocMatrix(Type, cast(int)nrow, cast(int)ncol);
        R_PreserveObject(sexp);
        auto mPtr = Accessor!(Type)(sexp);
        auto oPtr = ptr;

        for(long i = 0; i < ncol; ++i)
        {
            mPtr[(i*nrow)..((i + 1)*nrow)] = 
                oPtr[(r0[0] + (i + r1[0])*this.nrow)..(r0[1] + (i + r1[0])*this.nrow)];
        }
        auto result = RMatrix!(Type)(sexp);
        result.needUnprotect = true;
        return result;
    }

    pragma(inline, true)
    size_t nrow() @trusted
    {
        return this.opDollar!0;
    }
    
    pragma(inline, true)
    size_t ncol() @trusted
    {
        return this.opDollar!1;
    }
    
    pragma(inline, true)
    @property size_t length() @trusted
    {
        return LENGTH(this.sexp);
    }
    pragma(inline, true)
    @property auto length(I)(I n) @trusted
    if(isIntegral!I)
    {
        SETLENGTH(this.sexp, cast(int)n);
        return this.length;
    }
    pragma(inline, true) @property auto opDollar(size_t dim: 0)() @trusted
    {
        return Rf_nrows(this.sexp);
    }
    pragma(inline, true) @property auto opDollar(size_t dim: 1)() @trusted
    {
        return Rf_ncols(this.sexp);
    }
    I[2] opSlice(size_t dim, I)(I start, I end) @trusted
    if(isIntegral!I && ((dim >= 0) && (dim < 2)))
    {
        enforce(start >= 0 && end <= this.opDollar!dim, 
        "Start and end indexes are not withing dimension limits");
        return [start, end];
    }
    auto opIndexAssign(T, I)(auto ref T value, I[2] r0, I[2] r1) @trusted
    if(is(T: SEXPElementType!(Type)) && isIntegral!I)
    {
        for(long j = r1[0]; j < r1[1]; ++j)
        {
            for(long i = r0[0]; i < r0[1]; ++i)
            {
                this[i, j] = value;
            }
        }
        return;
    }
    auto opIndexAssign(M, I)(auto ref M expr, I[2] r0, I[2] r1) @trusted
    if(isRMatrixOrExpression!M && isIntegral!I)
    {
        auto nrows = r0[1] - r0[0];
        auto ncols = r1[1] - r1[0];

        enforce(nrows == expr.nrow, 
            "number of rows for expr not equal to implied sliced rows");
        enforce(ncols == expr.ncol, 
            "number of columns for expr not equal to implied sliced columns");
        
        for(long j = 0; j < ncols; ++j)
        {
            for(long i = 0; i < nrows; ++i)
            {
                this[i + r0[0], j + r1[0]] = expr[i, j];
            }
        }
        return;
    }
    auto opIndexOpAssign(string op, T, I)(auto ref T value, I[2] r0, I[2] r1) @trusted
    if(is(T: SEXPElementType!(Type)) && isIntegral!I)
    {
        for(long j = r1[0]; j < r1[1]; ++j)
        {
            for(long i = r0[0]; i < r0[1]; ++i)
            {
                mixin(`this[i, j] ` ~ op ~ `= value;`);
            }
        }
        return;
    }
    auto opIndexOpAssign(string op, M, I)(auto ref M expr, I[2] r0, I[2] r1) @trusted
    if(isRMatrixOrExpression!M && isIntegral!I)
    {
        auto nrows = r0[1] - r0[0];
        auto ncols = r1[1] - r1[0];

        enforce(nrows == expr.nrow, 
            "number of rows for expr not equal to implied sliced rows");
        enforce(ncols == expr.ncol, 
            "number of columns for expr not equal to implied sliced columns");
        
        for(long j = 0; j < ncols; ++j)
        {
            for(long i = 0; i < nrows; ++i)
            {
                mixin(`this[i + r0[0], j + r1[0]] ` ~ op ~ `= expr[i, j];`);
            }
        }
        return;
    }
    auto opOpAssign(string op, T)(auto ref T value) @trusted
    if(is(T: SEXPElementType!(Type)))
    {
        for(long j = 0; j < this.ncol; ++j)
        {
            for(long i = 0; i < this.nrow; ++i)
            {
                mixin(`this[i, j] ` ~ op ~ `= value;`);
            }
        }
        return;
    }
    auto opOpAssign(string op, M)(auto ref M expr) @trusted
    if(isRMatrixOrExpression!M)
    {
        enforce(this.nrow == expr.nrow, 
            "number of rows for expr not equal to nrow for matrix");
        enforce(this.ncol == expr.ncol, 
            "number of columns for expr not equal to ncol for matrix");
        
        for(long j = 0; j < this.ncol; ++j)
        {
            for(long i = 0; i < this.nrow; ++i)
            {
                mixin(`this[i, j] ` ~ op ~ `= expr[i, j];`);
            }
        }
        return;
    }
    /*
      Unprotect on casting back to SEXP
    */
    pragma(inline, true)
    SEXP opCast(T: SEXP)() @trusted
    {
        return this.sexp;
    }
    T opCast(T: SEXPElementType!(Type)[])() @trusted
    {
        auto n = this.length;
        static if(Type != STRSXP)
        {
            return ptr[0..n];
        }else{
            T result;
            foreach(i; 0..n)
            {
              result ~= getSEXP!(Type)(this.sexp, i);
            }
            return result;
        }
    }
    T opCast(T: SEXPElementType!(Type))() @trusted
    {
        enforce(this.length == 1, "Cannot cast to basic type " ~ 
            SEXPElementType!(Type).stringof ~ 
            "length is not equal to 1");
        static if(Type != STRSXP)
        {
            return ptr[0];
        }else{
            return getSEXP!(Type)(this.sexp, 0);
        }
    }
    auto asVector() @trusted
    {
        return RVector!(Type)(this.sexp);
    }
    pragma(inline, true)
    size_t getIndex(size_t i, size_t j) @trusted
    {
        return i + nrow*j;
    }
    auto opIndex(I)(I i, I j) @trusted
    if(isIntegral!(I))
    {
        static if(Type != STRSXP)
        {
            return ptr[getIndex(i, j)];
        }else{
            return getSEXP(this.sexp, getIndex(i, j));
        }
    }
    auto opIndexUnary(string op, I)(I i, I j) @trusted
    if(isIntegral!(I))
    {
        static if(Type != STRSXP)
        {
            mixin ("return " ~ op ~ "this.ptr[getIndex(i, j)];");
        }else{
            auto element = getSEXP(this.sexp, getIndex(i, j));
            mixin ("return " ~ op ~ "element;");
        }
    }
    auto opAssign(T)(auto ref T value) @trusted
    if(isRMatrixExpression!(T))
    {
        for(long j = 0; j < this.ncol; ++j)
        {
            for(long i = 0; i < this.nrow; ++i)
            {
                this[i, j] = value[i, j];
            }
        }
        return;
    }
    pragma(inline, true) auto opBinary(string op, T)(auto ref T rhs) @trusted
    {
        return operator!(op)(this, rhs);
    }
    pragma(inline, true) auto opBinaryRight(string op, T)(auto ref T lhs) @trusted
    {
        return operator!(op)(lhs, this);
    }
    auto opIndexAssign(T, I)(auto ref T value, I i, I j) @trusted
    if(isIntegral!(I))
    {
        auto idx = getIndex(i, j);
        static if((Type != STRSXP) && is(T: ElType))
        {
            this.ptr[idx] = value;
        }else static if(Type == STRSXP)
        {
            SET_STRING_ELT(this.sexp, idx, mkChar(value));
        }else static if(__traits(compiles, cast(ElType)value))
        {
            this.ptr[idx] = cast(ElType)value;
        }else
        {
            static assert(0, "unknown string type value assign type.");
        }
        return value;
    }
    auto opIndexOpAssign(string op, T, I)(auto ref T value, I i, I j) @trusted
    if(isIntegral!(I))
    {
        auto idx = getIndex(i, j);
        static if((Type != STRSXP) && is(T: ElType))
        {
            mixin ("this.ptr[idx] " ~ op ~ "= value;");
            return this.ptr[idx];
        }else static if(Type == STRSXP)
        {
            auto element = getSEXP(this.sexp, idx);
            mixin("element " ~ op ~ "= value;");
            return SET_STRING_ELT(this.sexp, idx, mkChar(element));
        }else static if(__traits(compiles, cast(ElType)value))
        {
            mixin("this.ptr[idx] op= cast(ElType)value;");
            return this.ptr[idx];
        }
    }
    auto colIndices(I)(I i) @system
    if(isIntegral!(I))
    {
        auto from = getIndex(0, i);
        auto to = getIndex(this.nrow - 1, i) + 1;
        return [from, to];
    }
    RVector!(Type) opIndex(I)(I j) @trusted
    if(isIntegral!(I))
    {
        auto range = colIndices!(I)(j);
        auto n = this.nrow;
        static if(Type != STRSXP)
        {
            auto result = RVector!(Type)(this.ptr[range[0]..range[1]]);
        }else{
            auto result = RVector!(Type)(n);
            foreach(i; 0..n)
            {
                result[i] = this[i, j];
            }
        }
        return result;
    }
    auto opIndexAssign(J)(RVector!(Type) vec, J j) @trusted
    if(isIntegral!(J))
    {
        auto range = colIndices!(J)(j);
        auto n = vec.length;
        static if(Type != STRSXP)
        {
            this.ptr[range[0]..range[1]] = vec.ptr[0..n];
        }else{
            foreach(i;0..n)
            {
                this.ptr[range[0] + i] = mkChar(vec[i]);
            }
        }
        return;
    }
}



