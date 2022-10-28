/*
  Class creates an RMatrix
*/

/* Matrix aliases */
alias NumericMatrix = RMatrix!(REALSXP);
alias IntegerMatrix = RMatrix!(INTSXP);
alias ComplexMatrix = RMatrix!(CPLXSXP);
alias CharacterMatrix = RMatrix!(STRSXP);
alias LogicalMatrix = RMatrix!(LGLSXP);
alias RawMatrix = RMatrix!(RAWSXP);



struct RMatrix(SEXPTYPE Type)
if(SEXPDataTypes!(Type))
{
  SEXP sexp;
  bool needUnprotect;
  static if(Type != STRSXP)
  {
    alias ElType = SEXPElementType!(Type);
  }else{
    alias ElType = SEXP;
  }

  alias implicitCast this;
  
  this(T)(T n_row, T n_col)
  if(isIntegral!(T))
  {
    this.sexp = protect(allocMatrix(Type, cast(int)n_row, cast(int)n_col));
    this.needUnprotect = true;
  }

  this(T)(T[] arr, I n_row, I n_col)
  if(is(T == SEXPElementType!(Type)))
  {
    auto n = arr.length;
    assert(n == n_row*n_col, "Length of array is not equal to multiple of nrow x ncol");
    this.sexp = protect(allocMatrix(Type, cast(int)n_row, cast(int)n_col));
    this.needUnprotect = true;
    static if(Type != STRSXP)
    {
      this.ptr[0..n] = arr[0..n];
    }else{
      foreach(i; 0..n)
      {
        this.ptr[i] = mkChar(arr[i]);
      }
    }
  }
  
  /*
    Here we assume that sexp is already protected
  */
  this(SEXP sexp)
  {
    assert(Type == TYPEOF(sexp), 
      "Type of input is not the same of SEXPTYPE type submitted");
    this.sexp = protect(sexp);
    this.needUnprotect = true;
    this.sexp = sexp;
  }
  this(ref return scope RMatrix original)
  {
    int n = cast(int)original.length;
    this.sexp = protect(allocMatrix(Type, cast(int)original.nrows, cast(int)original.ncols));
    this.needUnprotect = true;
    copyMatrix(this.sexp, original.sexp, FALSE);
  }
    
  ~this()
  {
    unprotect;
  }
  
  void unprotect()
  {
    if(needUnprotect)
    {
      unprotect_ptr(sexp);
      needUnprotect = false;
    }
  }

  @property auto ptr()
  {
    return Accessor!(Type)(this.sexp);
  }
  
  pragma(inline, true)
  size_t nrows() const
  {
    /* Cast away the const assume that nrow is okay to run */
    return Rf_nrows(cast(SEXP)sexp);
  }

  pragma(inline, true)
  size_t ncols() const
  {
    /* Cast away the const assume that nrow is okay to run */
    return Rf_ncols(cast(SEXP)sexp);
  }

  pragma(inline, true)
  @property size_t length() const
  {
      return LENGTH(cast(SEXP)this.sexp);
  }
  pragma(inline, true)
  @property auto length(T)(T n)
  if(isIntegral!(T))
  {
      SETLENGTH(this.sexp, cast(int)n);
      return this.length;
  }
  /*
    Unprotect on casting back to SEXP
  */
  SEXP opCast(T: SEXP)()
  {
    unprotect();
    return sexp;
  }
  /*
    Wrapper for alias this
  */
  pragma(inline, true)
  SEXP implicitCast()
  {
    return opCast!(SEXP)();
  }
  T opCast(T: SEXPElementType!(Type)[])()
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
  T opCast(T: SEXPElementType!(Type))()
  {
    assert(this.length == 1, "Cannot cast to basic type " ~ 
        SEXPElementType!(Type).stringof ~ 
        "length is not equal to 1");
    static if(Type != STRSXP)
    {
      return ptr[0];
    }else{
      return getSEXP!(Type)(this.sexp, 0);
    }
  }
  pragma(inline, true)
  size_t getIndex(size_t i, size_t j) const
  {
    return i + nrows*j;
  }
  auto opIndex(I)(I i, I j)
  if(isIntegral!(I))
  {
    static if(Type != STRSXP)
    {
      return ptr[getIndex(i, j)];
    }else{
      return getSEXP(this.sexp, getIndex(i, j));
    }
  }
  auto opIndexUnary(string op, I)(I i, I j)
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
  auto opIndexAssign(T, I)(auto ref T value, I i, I j) 
  if(isIntegral!(I))
  {
    auto idx = getIndex(i, j);
    static if((Type != STRSXP) && is(T == ElType))
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
  auto opIndexOpAssign(string op, T, I)(auto ref T value, I i, I j)
  if(isIntegral!(I))
  {
    auto idx = getIndex(i, j);
    static if((Type != STRSXP) && is(T == ElType))
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
  auto colIndices(I)(I i)
  if(isIntegral!(I))
  {
    auto from = getIndex(0, i);
    auto to = getIndex(this.nrows - 1, i) + 1;
    return [from, to];
  }
  RVector!(Type) opIndex(I)(I j)
  if(isIntegral!(I))
  {
    auto range = colIndices!(I)(j);
    auto n = this.nrows;
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
  auto opIndexAssign(J)(RVector!(Type) vec, J j)
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
  //auto opIndexAssign(I)(RVector!(Type) col, I j)
  //if(isIntegral!(I))
  //{
  //  auto range = colIndices!(I)(j);
  //  this.ptr[range[0]..range[1]] = col.ptr[0..col.length];
  //}
  auto colView(J)(J j)
  if(isIntegral!(J))
  {
    auto idx = getIndex(0, j);
    return View!(Type)(&this.ptr[idx], this.nrows);
  }
}



struct View(SEXPTYPE Type)
if(SEXPDataTypes!(Type))
{
  alias ElType = SEXPElementType!(Type);
  private ElType* ptr;
  immutable size_t length;
  this(ElType* ptr, size_t length)
  {
    this.ptr = ptr;
    this.length = length;
  }
  ~this()
  {
    this.ptr = null;
  }
  ElType opIndex(size_t i)
  {
    assert((i >= 0) && (i < this.length), 
      "Invalid index subscript " ~ to!(string)(i) ~ 
      " for data range.");
    return ptr[i];
  }
}

