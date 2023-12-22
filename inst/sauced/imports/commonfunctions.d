/*
  Function to set attributes
*/
auto attr(R, N, T)(ref R robj, N name, T value)
{

  setAttrib(To!(SEXP)(robj), To!(SEXP)(name), To!(SEXP)(value));
  return;
}

/*
  Function to get attributes 
	(should test to see if it can also get them too)
*/
auto attr(R, N)(ref R robj, N name)
{
  return getAttrib(To!(SEXP)(robj), To!(SEXP)(name));
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

bool isUnique(A: E[], E)(auto ref A arr)
{
  return arr.length == (arr.unique).length;
}

