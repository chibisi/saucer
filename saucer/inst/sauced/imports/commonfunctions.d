/*
  Function to set attributes
*/
auto attr(R, N, T)(ref R _robj_, N _name_, T _value_)
{
  SEXP robj, name, value;
  robj = To!(SEXP)(_robj_);
  name = To!(SEXP)(_name_);
  value = To!(SEXP)(_value_);
  setAttrib(robj, name, value);
  return robj;
}

/*
  Function to get attributes 
	(should test to see if it can also get them too)
*/
auto attr(R, N)(ref R _robj_, N _name_)
{
  SEXP robj = To!(SEXP)(robj);
  SEXP name = To!(SEXP)(_name_);
  return getAttrib(robj, name);
}

alias attributes = attr;

auto isin(A: E[], E)(E element, A arr)
{
  foreach(item; arr)
  {
    if(item == element)
    {
      return true;
    }
  }
  return false;
}

/+
  Function to get the unique elements from an array;
+/
auto unique(A: E[], E)(A arr)
{
    import std.array: array;
    import std.algorithm.iteration: uniq;
    return arr.uniq.array;
}

bool isUnique(A: E[], E)(A arr)
{
  return arr.length == (arr.unique).length;
}

