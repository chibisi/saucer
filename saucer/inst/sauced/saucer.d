module sauced.saucer;

import std.conv: to;
import std.traits: isIntegral;
public import sauced.r2d;
mixin(import("imports/r_aliases.d"));
import std.string: toStringz, fromStringz;

/*
  TODO:
  
  * Swap RVector and RMatrix over to T[] from T*
  * Make some methods private since some methods should not
  be accessible, e.g. unprotect, sexp, and so on.
*/


/*
  This is uda that marks a function to be exported 
  to R

  TODO:
  1. Rename to Export
  2. Add functionality so that the uda name can be exported to R
  
  3. Further work needs to be done on this to ensure 
  that it available at compile time
*/
struct Export
{
  immutable(string) function_name;
  this(immutable(string) function_name)
  {
    this.function_name = function_name;
  }
}


mixin(import("imports/cstring.d"));
mixin(import("imports/isin.d"));

alias print = Rf_PrintValue;


//SEXPTYPE definitions
alias NILSXP = SEXPTYPE.NILSXP;
alias SYMSXP = SEXPTYPE.SYMSXP;
alias LISTSXP = SEXPTYPE.LISTSXP;
alias CLOSXP = SEXPTYPE.CLOSXP;
alias ENVSXP = SEXPTYPE.ENVSXP;
alias PROMSXP = SEXPTYPE.PROMSXP;
alias LANGSXP = SEXPTYPE.LANGSXP;
alias SPECIALSXP = SEXPTYPE.SPECIALSXP;
alias BUILTINSXP = SEXPTYPE.BUILTINSXP;
alias CHARSXP = SEXPTYPE.CHARSXP;
alias LGLSXP = SEXPTYPE.LGLSXP;
alias INTSXP = SEXPTYPE.INTSXP;
alias REALSXP = SEXPTYPE.REALSXP;
alias CPLXSXP = SEXPTYPE.CPLXSXP;
alias STRSXP = SEXPTYPE.STRSXP;
alias DOTSXP = SEXPTYPE.DOTSXP;
alias ANYSXP = SEXPTYPE.ANYSXP;
alias VECSXP = SEXPTYPE.VECSXP;
alias EXPRSXP = SEXPTYPE.EXPRSXP;
alias BCODESXP = SEXPTYPE.BCODESXP;
alias EXTPTRSXP = SEXPTYPE.EXTPTRSXP;
alias WEAKREFSXP = SEXPTYPE.WEAKREFSXP;
alias RAWSXP = SEXPTYPE.RAWSXP;
alias S4SXP = SEXPTYPE.S4SXP;
alias NEWSXP = SEXPTYPE.NEWSXP;
alias FREESXP = SEXPTYPE.FREESXP;
alias FUNSXP = SEXPTYPE.FUNSXP;

/*
  Common element types converting to basic D types
*/
template SEXPElementType(SEXPTYPE type)
if(type == REALSXP)
{
  alias SEXPElementType = double;
}
template SEXPElementType(SEXPTYPE type)
if(type == INTSXP)
{
  alias SEXPElementType = int;
}
template SEXPElementType(SEXPTYPE type)
if(type == LGLSXP)
{
  alias SEXPElementType = int;
}
template SEXPElementType(SEXPTYPE type)
if(type == RAWSXP)
{
  alias SEXPElementType = ubyte;
}
template SEXPElementType(SEXPTYPE type)
if(type == STRSXP)
{
  //alias SEXPElementType = string;
  alias SEXPElementType = const(char)*;
}
template SEXPElementType(SEXPTYPE type)
if(type == VECSXP)
{
  alias SEXPElementType = SEXP;
}


/*
  Templates return accessor functions
*/
template Accessor(SEXPTYPE type)
if(type == REALSXP)
{
  alias Accessor = REAL;
}
template Accessor(SEXPTYPE type)
if(type == INTSXP)
{
  alias Accessor = INTEGER;
}
template Accessor(SEXPTYPE type)
if(type == LGLSXP)
{
  alias Accessor = LOGICAL;
}
template Accessor(SEXPTYPE type)
if(type == RAWSXP)
{
  alias Accessor = RAW;
}
template Accessor(SEXPTYPE type)
if(type == STRSXP)
{
  import std.string: fromStringz, toStringz;
  alias Accessor = (SEXP x, R_xlen_t i) =>
      //R_CHAR(STRING_ELT(x, i)); 
      cast(string)fromStringz(R_CHAR(STRING_ELT(x, i)));
}

//Pasting in RVector and RMatrix types
mixin(import("imports/basicVector.d"));
//mixin(import("imports/rvector.d"));
mixin(import("imports/rmatrix.d"));
//mixin(import("imports/dataframe.d"));
mixin(import("imports/commonfunctions.d"));

/*
  Template trait for whether an item is an 
  RVector!(SEXPTYPE) or not
*/
enum isRVector(V) = false;
/*
  Indicates that V is an RVector and that the
  template parameter is an SEXPTYPE value i.e.
  T is NOT SEXPTYPE but one of it's enumerations
  or else it would be T: SEXPTYPE.
*/
enum isRVector(V: RVector!T, SEXPTYPE T) = true;
//For the value
enum isRVector(alias V) = isRVector!(typeof(V));

/*
  Template trait for whether an item is an 
  RMatrix!(SEXPTYPE) or not
*/
enum isRMatrix(M) = false;
enum isRMatrix(M: RMatrix!T, SEXPTYPE T) = true;
enum isRMatrix(alias M) = isRMatrix!(typeof(M));


/*
  Template trait for whether an item is a saucer R 
  type or not.
*/
enum isRType(P) = isRVector!(P) || isRMatrix!(P);
enum isRType(alias P) = isRType!(typeof(P));


enum isSEXP(T) = is(T == SEXP);
//enum isSEXP(SEXP T) = true;
enum isSEXP(alias T) = isSEXP!(typeof(T));
//enum isSEXP(string arg) = isSEXP!(mixin(arg));

//template isSEXP(string arg)
//{
//  enum _string_ = "alias T = " ~ arg ~ ";";
//  pragma(msg, _string_);
//  mixin(_string_);
//  enum isSEXP = isSEXP!(T);
//}

alias getSubType(V) = V;
alias getSubType(V: RVector!T, SEXPTYPE T) = T;
alias getSubType(V: RMatrix!T, SEXPTYPE T) = T;
alias getSubType(alias V) = getSubType!(typeof(V));

enum isBasicType(T) = is(T == bool) || is(T == byte) || 
        is(T == ubyte) || is(T == short) || is(T == ushort) || 
        is(T == int) || is(T == uint) || is(T == long) || 
        is(T == ulong) || is(T == char) || is(T == float) || 
        is(T == double) || is(T == real) || 
        is(T == const(char)*) || 
        is(T == char*) || is(T == string);


enum isStringType(T) = is(T == char*) || is(T == const(char)*) || 
                       is(T == string);


//enum isBasicArray(T) = false;
template isBasicArray(T)
if(!is(T: U[], U))
{
  enum isBasicArray = false;
}

template isBasicArray(T: U[], U)
{
  static if(isBasicType!(U))
  {
    enum isBasicArray = true;
  }else
  {
    enum isBasicArray = false;
  }
}


/*
  Mapping from basic type to SEXPTYPE
*/
template MapToSEXP(T)
{
  static if(is(T == double))
  {
    enum SEXPTYPE MapToSEXP = REALSXP;
  }else static if(is(T == ubyte))
  {
    enum SEXPTYPE MapToSEXP = RAWSXP;
  }else static if(is(T == int))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == long))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == ulong))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == uint))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == short))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == ushort))
  {
    enum SEXPTYPE MapToSEXP = INTSXP;
  }else static if(is(T == bool))
  {
    enum SEXPTYPE MapToSEXP = LGLSXP;
  }else /*static if(is(T == const(char)*))
  {
    enum SEXPTYPE MapToSEXP = STRSXP;
  }else */static if(is(T == string))
  {
    enum SEXPTYPE MapToSEXP = STRSXP;
  }else{
    static assert(0, "Basic Type \"" ~ T.stringof ~ 
      "\" can not be converted or not yet implemented");
  }
}

template GetElementType(T: U[], U)
{
  alias GetElementType = U;
}



/*
  r_type has to be ref (borrowing) or the function 
  will attempt to call the destructor on it on exit from scope
  since r_type is not actually returned. Difficult to overload 
  the to!() template because RTypes are "alias this SEXP" so
  to!(SEXP)(r_type) will probably just try to shortcut type
  convert to SEXP thus running the destructor rather than running
  the function below and on exit of the parent function, the
  destructor will attempt to run again when the object goes out of
  scope and cause an error. So I renamed the template function to To!()
  which shall be used until we start using the new preserve list
  mechanism for unprotecting.
*/

/*
  Type conversion from any RType to an SEXP
*/
pragma(inline, true)
T To(T, F)(auto ref F r_type)
if(isSEXP!(T) && isRType!(F))
{
  return r_type.sexp;
}

pragma(inline, true)
SEXP To(T: SEXP, F)(auto ref F sexp)
if(isSEXP!(T) && isSEXP!(F))
{
  return sexp;
}

/*
  Type conversion from any Basic Array to an SEXP
*/
pragma(inline, true)
T To(T, F)(auto ref F arr)
if(isSEXP!(T) && isBasicArray!(F))
{
  alias E = GetElementType!(F);
  enum SEXPTYPE STYPE = MapToSEXP!(E);
  auto result = allocVector(STYPE, arr.length);
  static if(STYPE != STRSXP)
  {
    auto ptr = Accessor!(STYPE)(result);
    ptr[0..arr.length] = arr[];
  }else{
    for(long i = 0; i < arr.length; ++i)
    {
      SET_STRING_ELT(result, i, mkChar(cast(const(char)*)toStringz(arr[i])));
    }
  }
  return result;
}

/*
  Type conversion from any Basic type to an SEXP
*/
pragma(inline, true)
T To(T, F)(auto ref F b_type)
if(isSEXP!(T) && isBasicType!(F))
{
  enum SEXPTYPE STYPE = MapToSEXP!(F);
  auto result = allocVector(STYPE, 1);
  static if(STYPE != STRSXP)
  {
    auto ptr = Accessor!(STYPE)(result);
    ptr[0] = b_type;
  }else{
    SET_STRING_ELT(result, 0, mkChar(cast(const(char)*)toStringz(b_type)));
  }
  
  return result;
}



/*
  From SEXP to basic array
*/
pragma(inline, true)
T To(T, F)(auto ref F sexp)
if(isBasicArray!(T) && isSEXP!(F))
{
  alias E = GetElementType!(T);
  long n = LENGTH(sexp);
  static if(!isStringType!E)
  {
    alias func = Accessor!(MapToSEXP!(E));
    auto _result_ = func(sexp)[0..n];
    static if(is(typeof(_result_[0]) == E))
    {
      return _result_;
    }else{
      auto result = new E[n];
      foreach(long i, ref el; _result_)
      {
        result[i] = cast(E)el;
      }
      return result;
    }
  }else{
    alias func = Accessor!(STRSXP);
    auto result = new string[n];
    for(long i = 0; i < n; ++i)
    {
      result[i] = func(sexp, i);
    }
    return result;
  }
}

pragma(inline, true)
T To(T, F)(auto ref F arr)
if(isBasicArray!(T) && isBasicArray!(F))
{
  alias ET = GetElementType!(T);
  alias EF = GetElementType!(F);
  static if(is(ET == EF))
  {
    return arr;
  }else{
    long n = arr.length;
    auto result = new ET[n];
    for(long i = 0; i < n; ++i)
    {
      result[i] = to!(ET)(arr[i]);
    }
    return result;
  }
}

pragma(inline, true)
T To(T, F)(auto ref F arr)
if(isSEXP!(T) && isSEXP!(F))
{
  return arr;
}


/*
  From SEXP to basic type
*/
pragma(inline, true)
E To(E, F)(auto ref F sexp)
if(isBasicType!(E) && isSEXP!(F))
{
  long n = LENGTH(sexp);
  assert(n == 1, "Length of SEXP is not equal to 1");
  static if(!isStringType!E)
  {
    alias func = Accessor!(MapToSEXP!(E));
    return cast(E)func(sexp)[0];
  }else{
    alias func = Accessor!(STRSXP);
    return cast(E)func(sexp, 0);
  }
}


/*
  From SEXP to RType
*/
pragma(inline, true)
T To(T, F)(auto ref F sexp)
if(isRType!(T) && isSEXP!(F))
{
  return T(sexp);
}


/*
  Safer string of for types
*/
string StringOf(T)()
{
  static if(is(T == mixin("RVector!(LGLSXP)")))
  {
    return "RVector!(LGLSXP)";
  }
  static if(is(T == mixin("RVector!(INTSXP)")))
  {
    return "RVector!(INTSXP)";
  }
  static if(is(T == mixin("RVector!(REALSXP)")))
  {
    return "RVector!(REALSXP)";
  }
  static if(is(T == mixin("RVector!(RAWSXP)")))
  {
    return "RVector!(RAWSXP)";
  }
  /* static if(is(T == RVector!(STRSXP)))
  {
    return "RVector!(STRSXP)";
  } */
  static if(is(T == mixin("RMatrix!(LGLSXP)")))
  {
    return "RMatrix!(LGLSXP)";
  }
  static if(is(T == mixin("RMatrix!(INTSXP)")))
  {
    return "RMatrix!(INTSXP)";
  }
  static if(is(T == mixin("RMatrix!(REALSXP)")))
  {
    return "RMatrix!(REALSXP)";
  }
  static if(is(T == mixin("RMatrix!(RAWSXP)")))
  {
    return "RMatrix!(RAWSXP)";
  }
  static if(is(T == RMatrix!(STRSXP)))
  {
    return "RMatrix!(STRSXP)";
  }
  return T.stringof;
}

template ModifyArg(T, string arg)
if(!isSEXP!(T) && !isRType!(T))
{
  static assert(0, "argument type unknown.");
}

template ModifyArg(T, string arg)
if(isSEXP!(T) || isRType!(T))
{
  static if(isSEXP!(T))
  {
    enum ModifyArg = arg;
  }
  static if(isRType!(T))
  {
    //enum ModifyArg = "cast(SEXP)" ~ arg;
    enum ModifyArg = "To!(" ~ StringOf!(T)() ~ ")(" ~ arg ~ ")";
  }
}

auto modifyArg(T)(string arg)
if(!isSEXP!(T) && !isRType!(T) && 
   !isBasicArray!(T) && !isBasicType!(T))
{
  static assert(0, "argument type unknown.");
}

auto modifyArg(T)(string arg)
if(isSEXP!(T) || isRType!(T) || 
   isBasicArray!(T) || isBasicType!(T))
{
  static if(isSEXP!(T))
  {
    return arg;
  }else
  {
    return "To!(" ~ StringOf!(T)() ~ ")(" ~ arg ~ ")";
  }
}
