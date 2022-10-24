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
  //Try with String elemenets as 
  //SEXP and see what happens
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
    size_t n = LENGTH(sexp);
    this.needUnprotect = true;
    this.sexp = sexp;
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
  size_t get_index(size_t i, size_t j) const
  {
    return i + nrows*j;
  }
  auto opIndex(I)(I i, I j) inout
  if(isIntegral!(I))
  {
    static if(Type != STRSXP)
    {
      return ptr[get_index(i, j)];
    }else{
      return getSEXP(this.sexp, get_index(i, j));
    }
  }
  auto opIndexUnary(string op, I)(I i, I j) inout
  if(isIntegral!(I))
  {
    static if(Type != STRSXP)
    {
      mixin ("return " ~ op ~ "this.ptr[get_index(i, j)];");
    }else{
      auto element = getSEXP(this.sexp, get_index(i, j));
      mixin ("return " ~ op ~ "element;");
    }
  }
  auto opIndexAssign(T, I)(auto ref T value, I i, I j) 
  if(isIntegral!(I))
  {
    auto idx = get_index(i, j);
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
    auto idx = get_index(i, j);
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
}

