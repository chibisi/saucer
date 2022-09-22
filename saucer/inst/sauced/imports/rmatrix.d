/*
  Class creates an RMatrix
*/

struct RMatrix(SEXPTYPE type)
{
  SEXP __sexp__;
  bool __need_unprotect__;
  SEXPElementType!(type)[] data;

  alias implicitCast this;
  //alias __sexp__ this;
  
  this(T)(T n_row, T n_col)
  if(isIntegral!(T) && (type != STRSXP))
  {
    this.__sexp__ = protect(allocMatrix(type, cast(int)n_row, cast(int)n_col));
    this.__need_unprotect__ = true;
    this.data = Accessor!(type)(__sexp__)[0..(n_row * n_col)];
  }
  this(T)(T n_row, T n_col)
  if(isIntegral!(T) && (type == STRSXP))
  {
    this.__sexp__ = protect(allocMatrix(type, cast(int)n_row, cast(int)n_col));
    this.__need_unprotect__ = true;
    auto n = cast(long)n_row * n_col;
    this.data.length = cast(int)n;
    for(long i = 0; i < n; ++i)
    {
      this.data[i] = CHAR(STRING_ELT(this.__sexp__, i));
    }
  }

  this(T)(T[] arr, I n_row, I n_col)
  if(is(T == SEXPElementType!(type)) && 
     !is(T == string) && !is(T == const(char)*) && 
     (type != STRSXP) && isIntegral!(I))
  {
    auto n = arr.length;
    assert(n == n_row*n_col, "Length of array is not equal to multiple of nrow x ncol");
    this.__sexp__ = protect(allocMatrix(type, cast(int)n_row, cast(int)n_col));
    this.__need_unprotect__ = true;
    this.data = Accessor!(type)(__sexp__)[0..n];
    this.data[] = arr[];//copy contents across
  }

  this(T, I)(T[] arr, I n_row, I n_col)
  if((is(T == string) || is(T == const(char)*)) && 
     (type == STRSXP) && isIntegral!(I))
  {
    auto n = arr.length;
    assert(n == n_row*n_col, "Length of array is not equal to multiple of nrow x ncol");
    this.data.length = n;
    this.__sexp__ = protect(allocMatrix(type, cast(int)n_row, cast(int)n_col));
    this.__need_unprotect__ = true;
    
    for(long i = 0; i < n; ++i)
    {
      static if(is(T == string))
      {
        SET_STRING_ELT(this.__sexp__, i, mkChar(cast(const(char)*)arr[i]));
        this.data[i] = cast(const(char)*)toStringz(arr[i]);
      }else{
        SET_STRING_ELT(this.__sexp__, i, mkChar(cast(const(char)*)arr[i]));
        this.data[i] = arr[i];
      }
    }
  }
  
  this(SEXP __sexp__)
  {
    assert(type == TYPEOF(__sexp__), 
      "Type of input is not the same of SEXPTYPE type submitted");
    static if(type != STRSXP)
    {
      this.__sexp__ = protect(__sexp__);
      size_t n = LENGTH(__sexp__);
      this.__need_unprotect__ = true;
      this.data = Accessor!(type)(__sexp__)[0..n];
    }else{
      this.__sexp__ = protect(__sexp__);
      size_t n = LENGTH(__sexp__);
      this.__need_unprotect__ = true;
      this.data.length = n;
      for(long i = 0; i < n; ++i)
      {
        this.data[i] = CHAR(STRING_ELT(this.__sexp__, i));
      }
    }
  }
    
  ~this()
  {
    unprotect;
  }
  
  void unprotect()
  {
    if(__need_unprotect__)
    {
      unprotect_ptr(__sexp__);
      __need_unprotect__ = false;
    }
  }
  
  pragma(inline, true)
  size_t nrows() const
  {
    /* Cast away the const assume that nrow is okay to run */
    return Rf_nrows(cast(SEXP)__sexp__);
  }

  pragma(inline, true)
  size_t ncols() const
  {
    /* Cast away the const assume that nrow is okay to run */
    return Rf_ncols(cast(SEXP)__sexp__);
  }

  pragma(inline, true)
  size_t length()
  {
    return LENGTH(__sexp__);
  }
  /*
    Unprotect on casting back to SEXP
  */
  SEXP opCast(T: SEXP)()
  {
    unprotect();
    return __sexp__;
  }
  /*
    Wrapper for alias this
  */
  pragma(inline, true)
  SEXP implicitCast()
  {
    return opCast!(SEXP)();
  }
  T opCast(T: SEXPElementType!(type)[])()
  {
    return data;
  }
  T opCast(T: SEXPElementType!(type))()
  {
    assert(length == 1, "Cannot cast to basic type " ~ 
        SEXPElementType!(type).stringof ~ 
        "length is not equal to 1");
    return data[0];
  }
  T opCast(T: string[])()
  if(type == STRSXP)
  {
    long n = length;
    auto result = new string[n];
    for(long i = 0; i < n; ++i)
    {
      result[i] = cast(string)fromStringz(CHAR(STRING_ELT(this.__sexp__, i)));
    }
    return result;
  }
  T opCast(T: string)()
  if(type == STRSXP)
  {
    assert(length == 1, "Cannot cast to basic type " ~ 
        SEXPElementType!(type).stringof ~ 
        "length is not equal to 1");
    return cast(string)fromStringz(R_CHAR(STRING_ELT(this.__sexp__, 0)));
  }
  pragma(inline, true)
  size_t get_index(size_t i, size_t j) const
  {
    return i + nrows*j;
  }
  auto opIndex(I)(I i, I j) inout
  if(isIntegral!(I))
  {
    static if(type != STRSXP)
    {
      return data[get_index(i, j)];
    }else{
      return cast(string)fromStringz(data[get_index(i, j)]);
    }
  }
  auto opIndexUnary(string op)(size_t i, size_t j) inout 
  {
    mixin ("return " ~ op ~ "data[get_index(i, j)];");
  }
  auto opIndexAssign(T, I)(T value, I i, I j) 
  if(isIntegral!(I))
  {
    static if(is(T == SEXPElementType!(type)) && (type != STRSXP))
    {
      return data[get_index(i, j)] = value;
    }else static if(is(T == string) && (type == STRSXP))
    {
      return SET_STRING_ELT(this.__sexp__, get_index(i, j), mkChar(cast(const(char)*)toStringz(value)));
    }else static if(__traits(compiles, cast(SEXPElementType!(type))value))
    {
      return data[get_index(i, j)] = cast(SEXPElementType!(type))value;
    }else
    {
      static assert(0, "unknown string type value assign type.");
    }
  }
  auto opIndexOpAssign(string op, T, I)(T value, I i, I j)
  if(isIntegral!(I))
  {
    static if(type != STRSXP)
    {
      mixin ("return data[get_index(i, j)] " ~ op ~ "= value;");
    }else{
      mixin("auto tmp = To!(string)(data[get_index(i, j)]) " ~ op ~ " To!(string)(value);");
      data[get_index(i, j)] = cast(const(char)*)toStringz(tmp);
      SET_STRING_ELT(this.__sexp__, 0, mkChar(cast(const(char)*)toStringz(tmp)));
      return data[get_index(i, j)] = mkChar(cast(const(char)*)toStringz(tmp));
      return data[get_index(i, j)];
    }
  }
}

