/*
  Function to set attributes
*/
auto attr(R, N, T)(R _robj_, N _name_, T _value_)
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
auto attr(R, N)(SEXP _robj_, N _name_)
{
  SEXP name = To!(SEXP)(_name_);
  return getAttrib(_robj_, name);
}



