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

//import std.stdio: writeln;
struct RVector(SEXPTYPE type)
{
  SEXP __sexp__;
  /*
    If the vector is allocated in this struct, 
    it will be unprotected here.
  */
  bool __need_unprotect__;
  
  static if(type != VECSXP)
  {
    SEXPElementType!(type)[] data;
  }

  alias __sexp__ this;
  //alias implicitCast this;
  
  this(T)(T n)
  if((type == VECSXP) && isIntegral!(T))
  {
    static if(type == VECSXP)
    {
      this.__sexp__ = protect(allocVector(VECSXP, cast(int)n));
    }
  }
  this(T)(T n)
  if((type != VECSXP) && isIntegral!(T) && (type != STRSXP))
  {
    this.__sexp__ = protect(allocVector(type, cast(int)n));
    this.__need_unprotect__ = true;
    static if(type != VECSXP)
    {
      this.data = Accessor!(type)(__sexp__)[0..n];
    }
  }
  this(T)(T n)
  if((type != VECSXP) && isIntegral!(T) && (type == STRSXP))
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
  if((type != VECSXP) && is(T == SEXPElementType!(type)) && 
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
  if((type != VECSXP) && (is(T == string) || is(T == const(char)*)) && 
     (type == STRSXP))
  {
    //writeln("String constructor 1");
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
  this(T)(T[] arr)
  if((type == VECSXP) && !is(T == SEXP))
  {
    SEXP __item__ = To!(SEXP)(arr);
    this.__sexp__ = protect(allocVector(VECSXP, 1));
    SET_VECTOR_ELT(this.__sexp__, 0, __item__);
  }
  /* Create RVector from SEXP */
  this(T)(T __sexp__)
  if(is(T == SEXP) && (type != VECSXP))
  {
    assert(type == TYPEOF(__sexp__), "Type of input is not the same as SEXPTYPE type submitted");
    
    static if(type != STRSXP)
    {
      this.__sexp__ = protect(__sexp__);
      this.__need_unprotect__ = true;
      size_t n = LENGTH(__sexp__);
      this.data = Accessor!(type)(__sexp__)[0..n];
    }else{
      //writeln("String constructor 2");
      this.__sexp__ = protect(__sexp__);
      this.__need_unprotect__ = true;
      size_t n = LENGTH(__sexp__);
      this.data.length = n;
      //this.data = Accessor!(type)(__sexp__)[0..n];
      for(long i = 0; i < n; ++i)
      {
        this.data[i] = CHAR(STRING_ELT(this.__sexp__, i));
      }
    }
  }
  this(T...)(T items)
  if((type == VECSXP) || ((T.length == 1) && !isIntegral!(T)))
  {
    enum n = T.length;
    this.__sexp__ = protect(allocVector(VECSXP, cast(int)n));
    static foreach(enum i; 0..n)
    {{
      static if(is(T[i] == SEXP))
      {
        SEXP item = items[i];
        SET_VECTOR_ELT(this.__sexp__, cast(int)i, protect(item));
      }else static if(isRType!(T[i]))
      {
        SEXP item = items[i];
        SET_VECTOR_ELT(this.__sexp__, cast(int)i, protect(item));
      }else
      {
        static assert(0, "SEXP and RVector only allowed for lists");
      }
    }}
  }
  
  static if(false)
  {
    auto append(T)(T item)
    if((is(T == SEXP) || isRType!T) && (type == VECSXP))
    {
      static if(is(T == SEXP))
      {
        item = protect(item);
        this.__sexp__ = listAppend(this.__sexp__, item);
      }else static if(isRType!T)
      {
        SEXP __item__ = item;
        __item__ = protect(__item__);
        this.__sexp__ = listAppend(this.__sexp__, __item__);
      }
      return;
    }
  }
  
  /*
    Destructor just unprotects and releases for R's gc
    It auto activates when the variable goes out of scope
    and if it is returned, unprotect has to occur manually
  */
  ~this()
  {
    //writeln("Destructor ...");
    debug(rvector)
    {
      "Destructor called".writeln;
    }
    static if(type == VECSXP)
    {
      sauced.saucer.unprotect(cast(int)(length + 1));
    }else static if((type != VECSXP) && (type != STRSXP))
    {
      this.unprotect;
    }
  }
  
  size_t length()
  {
    return LENGTH(__sexp__);
  }
  /*
    Unprotect when casting back to SEXP
  */
  SEXP opCast(T : SEXP)()
  {
    //writeln("opCast SEXP ...");
    this.unprotect();
    return this.__sexp__;
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
  if(type != VECSXP)
  {
    return data;
  }
  T opCast(T: SEXPElementType!(type))()
  if(type != VECSXP)
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
    //writeln("Running unprotect_ptr for " ~ type.stringof);
    debug(rvector)
    {
      "unprotect_ptr called".writeln;
    }
    if(__need_unprotect__)
    {
      unprotect_ptr(this.__sexp__);
      __need_unprotect__ = false;
      debug(rvector)
      {
        "unprotect_ptr run".writeln;
      }
    }
  }
  string toString()
  {
    static if(type == VECSXP)
    {
      return "<RVector!(VECSXP)> String representation not yet implemented,\nuse print(SEXP) function instead for printing.";
    }else{
      return "<RVector>\n" ~ to!(string)(opCast!(SEXPElementType!(type)[])());
    }
  }
  /*
    Functions to get and set names
  */
  @property auto names()
  {
    SEXP __names__ = getAttrib(__sexp__, R_NameSymbol);
    return RVector!(STRSXP)(__names__);
  }
  @property auto names(T)(T arr)
  if((is(T == string[]) || isRType!(T) || is(T == SEXP)) && (type == VECSXP))
  {
    static if(isRType!(T))
    {
      SEXP __arr__ = arr;
      __arr__ = protect(__arr__);
      setAttrib(__sexp__, R_NamesSymbol, __arr__);
      sauced.saucer.unprotect(1);
      return;
    }else static if(is(T == string[]))
    {
      SEXP __arr__ = To!(SEXP)(arr);
      __arr__ = protect(__arr__);
      setAttrib(__sexp__, R_NamesSymbol, __arr__);
      sauced.saucer.unprotect(1);
      return;
    }else static if(is(T == SEXP))
    {
      arr = protect(arr);
      setAttrib(__sexp__, R_NamesSymbol, arr);
      sauced.saucer.unprotect(1);
      return;
    }else {
      static assert("Unknown type " ~ T.stringof ~ " can not be attached to list name");
    }
  }
  auto opIndex(size_t i) inout
  {
    static if(type == VECSXP)
    {
      return VECTOR_ELT(cast(SEXP)__sexp__, cast(long)i);
    }else static if(type != STRSXP)
    {
      return data[i];
    }else{
      return cast(string)fromStringz(data[i]);
    }
  }
  auto opIndexUnary(string op)(size_t i) inout 
  if(type != VECSXP)
  {
    mixin ("return " ~ op ~ "data[i];");
  }
  auto opIndexAssign(T)(T value, size_t i) 
  {
    static if(type == VECSXP)
    {
      static if(is(T == SEXP) || isRType!(T))
      {
        SET_VECTOR_ELT(this.__sexp__, cast(int)i, value);
        return;
      }else{
        SEXP __sexp_value__ = To!(SEXP)(value);
        SET_VECTOR_ELT(this.__sexp__, cast(int)i, __sexp_value__);
        return;
      }
    }else static if(is(T == SEXPElementType!(type)) && (type != STRSXP))
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
  if(type != VECSXP)
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

