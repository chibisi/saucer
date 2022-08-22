/*
  Class to create an R vector

  Think about using this instead:
  
  (https://developer.r-project.org/Blog/public/2018/12/10/unprotecting-by-value/)
  SEXP R_NewPreciousMSet(int initialSize);
  void R_PreserveInMSet(SEXP x, SEXP mset);
  void R_ReleaseFromMSet(SEXP x, SEXP mset);
  void R_ReleaseMSet(SEXP mset, int keepSize);
*/

import std.string: toStringz, fromStringz;

debug(rvector)
{
  import std.stdio: writeln;
}

struct RVector(SEXPTYPE type)
{
  SEXP __sexp__;
  /*
    If the vector is allocated in this struct, 
    it will be unprotected here.
  */
  bool __need_unprotect__;
  SEXPElementType!(type)[] data;

  alias __sexp__ this;
  
  this(T)(T n)
  if(isIntegral!(T) && (type != STRSXP))
  {
    this.__sexp__ = protect(allocVector(type, cast(int)n));
    this.__need_unprotect__ = true;
    this.data = Accessor!(type)(__sexp__)[0..n];
  }
  this(T)(T n)
  if(isIntegral!(T) && (type == STRSXP))
  {
    this.__sexp__ = protect(allocVector(type, cast(int)n));
    this.__need_unprotect__ = true;
    
    this.data.length = n;
    for(long i = 0; i < n; ++i)
    {
      this.data[i] = CHAR(STRING_ELT(this.__sexp__, i));
    }
  }
  /*
    Copies from array because can not (yet) verify 
    that it is allocated with the R memory allocator
  */
  this(T)(T[] arr)
  if(is(T == SEXPElementType!(type)) && 
     !is(T == string) && 
     !is(T == const(char)*) && 
     (type != STRSXP))
  {
    auto n = arr.length;
    this.__sexp__ = protect(allocVector(type, cast(int)n));
    this.__need_unprotect__ = true;
    this.data = Accessor!(type)(__sexp__)[0..n];
    this.data[] = arr[];//copy contents across
  }
  this(T)(T[] arr)
  if((is(T == string) || is(T == const(char)*)) && 
     (type == STRSXP))
  {
    auto n = arr.length;
    this.data.length = n;
    this.__sexp__ = protect(allocVector(type, cast(int)n));
    this.__need_unprotect__ = true;
    
    for(long i = 0; i < n; ++i)
    {
      static if(is(T == string))
      {
        SET_STRING_ELT(this.__sexp__, i, mkChar(cast(const(char)*)arr[i]));
        this.data[i] = cast(const(char)*)toStringz(arr[i]);
      }else{
        //for T == const(char)*
        SET_STRING_ELT(this.__sexp__, i, mkChar(cast(const(char)*)arr[i]));
        this.data[i] = arr[i];
      }
    }
  }
  /* Create RVector from SEXP */
  this(SEXP __sexp__)
  {
    assert(type == TYPEOF(__sexp__), "Type of input is not the same as SEXPTYPE type submitted");
    static if(type != STRSXP)
    {
      this.__sexp__ = __sexp__;
      this.__need_unprotect__ = false;
      size_t n = LENGTH(__sexp__);
      this.data = Accessor!(type)(__sexp__)[0..n];
    }else{
      this.__sexp__ = __sexp__;
      this.__need_unprotect__ = false;
      size_t n = LENGTH(__sexp__);
      this.data.length = n;
      //this.data = Accessor!(type)(__sexp__)[0..n];
      for(long i = 0; i < n; ++i)
      {
        this.data[i] = CHAR(STRING_ELT(this.__sexp__, i));
      }
    }
  }
  /*
    Destructor just unprotects and releases for R's gc
    It auto activates when the variable goes out of scope
    and if it is returned, unprotect has to occur manually
  */
  ~this()
  {
    debug(rvector)
    {
      "Destructor called".writeln;
    }
    unprotect;
  }
  
  size_t length()
  {
    return LENGTH(__sexp__);
  }
  SEXP opCast(T : SEXP)()
  {
    return __sexp__;
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
  
  /*
    Manual unprotect. This will probably not be needed because
    RVector is never returned to R, only the SEXP within the
    RVector type is returned, so the object is destroyed on
    return to R or on exit from the function.
  */
  void unprotect()
  {
    debug(rvector)
    {
      "unprotect_ptr called".writeln;
    }
    if(__need_unprotect__)
    {
      unprotect_ptr(__sexp__);
      __need_unprotect__ = false;
      debug(rvector)
      {
        "unprotect_ptr run".writeln;
      }
    }
  }
  string toString()
  {
    return "<RVector>\n" ~ to!(string)(opCast!(SEXPElementType!(type)[])());
  }
  auto opIndex(size_t i) inout
  {
    static if(type != STRSXP)
    {
      return data[i];
    }else{
      return cast(string)fromStringz(data[i]);
    }
  }
  auto opIndexUnary(string op)(size_t i) inout 
  {
    mixin ("return " ~ op ~ "data[i];");
  }
  auto opIndexAssign(T)(T value, size_t i) 
  {
    static if(is(T == SEXPElementType!(type)) && (type != STRSXP))
    {
      return data[i] = value;
    }else static if(is(T == string) && (type == STRSXP))
    {
      return SET_STRING_ELT(this.__sexp__, i, mkChar(cast(const(char)*)toStringz(value)));
    }else static if(__traits(compiles, cast(SEXPElementType!(type))value))
    {
      return data[i] = cast(SEXPElementType!(type))value;
    }else
    {
      static assert(0, "unknown string type value assign type.");
    }
  }
  auto opIndexOpAssign(string op, T)(T value, size_t i)
  {
    static if(type != STRSXP)
    {
      mixin ("return data[i] " ~ op ~ "= value;");
    }else{
      mixin("auto tmp = To!(string)(data[i]) " ~ op ~ " To!(string)(value);");
      data[i] = cast(const(char)*)toStringz(tmp);
      SET_STRING_ELT(this.__sexp__, 0, mkChar(cast(const(char)*)toStringz(tmp)));
      return data[i] = mkChar(cast(const(char)*)toStringz(tmp));
      return data[i];
    }
  }
}

