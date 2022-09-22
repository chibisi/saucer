import std.meta: AliasSeq;


struct _Tuple_(T...)
{
  enum length = T.length;
  alias get(ulong i) = T[i];
}


enum bool _isTuple_(T) = false;
enum bool _isTuple_(T: Tuple!(U), U) = true;

bool __in__(S, T)()
if(_isTuple_!(S))
{
    static assert(S.length > 0, "No S variables submitted");
    bool result = false;
    static foreach(enum i; 0..(S.length))
    {
        static if(is(S.get!(i) == T))
        {
            result = true;
        }
    }
    return result;
}

/+
  Compile time check for whether items in AliasSeq!(T) are in _Tuple!(S)
+/
template isin(S, T...)
if(_isTuple_!(S))
{
    static assert(T.length > 0, "No T variables submitted");
    static assert(S.length > 0, "No S variables submitted");
    static if(T.length == 1)
    {
        enum bool isin = __in__!(S, T);
    }else{
        alias TL = AliasSeq!(T);
        enum bool isin = isin!(S, T[0]) || isin!(S, T[1..$]);
    }
}


unittest
{
    static assert(isin!(_Tuple_!(int, double), string, ulong) == false);
    static assert(isin!(_Tuple_!(int, double), int, double, double, int) == true);
    static assert(isin!(_Tuple_!(int, double), int, ulong) == true);
}

