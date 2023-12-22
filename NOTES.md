# Notes


1. When calling `writeln`, use the `toString()` function on RVector, RMatrix and other D-interfacing object. This is because `writeln` currently calls copy constructors multiple times which is obviously resource wasteful. For convenience I don't really want to disable it.

2. Users need Rmath library installed: https://openwetware.org/wiki/Installing_libRmath
```
sudo apt install r-mathlib
```

## Implementation Approach

The general implementation approach for this library is to focus on the static aspect of interfacing R and D. Meaning that dispatch of objects should be explicitly known at compile time. So for example vector types are specified explicitly in the functions that are dispatched to R: `@Export() auto dot(NumericVector x, NumericVector y) @safe {...}`. In this case the type of the vector is known at compile time as a `NumericVector` (double not int).



## Safety

The D programming language has an attribute `@safe` tools to dissallow operations that may cause memory corruption. It is thus recommended that functions you write should be marked with this attribute - unless you have a deep knowledge of D - in which case ignore this note. The data interfaces for working with R and D in this package necessarily interface with unsafe C code and some care is take to make sure that they can be used safely in conjuction with the `@safe` attribute. The raw C functions however are left as the default `@system` attribute, this means that they can not be directly called in `@safe` functions, which is a necessary concession.

The approach of this package is in line with the philosophy of D, which is not to stop you from doing things, but to make available tools that allow you to do what you want.


### Example of a segfault case (why @safe should be used)
**No longer relevant because there is no more implicit casting with alias this**

Attempting to call the function below will create a segfault:

```d
@Export("dot_product") SEXP dot(NumericVector x, NumericVector y)
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return result;
}
```

This is because `RVector` objects are structs and avoid the garbage collector, when the function returns there is a subsequent implicit cast to `SEXP`, but the `RVector result` object is destroyed, meaning there is no reference to the internal `SEXP` object resulting in a segfault and the hard-crash of R. Marking the function with the `@safe` attribute:

```
@Export("dot_product") SEXP dot(NumericVector x, NumericVector y) @safe
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return result;
}
```

will avoid this by create an error message on compilation:

```
Error: `@safe` function `example1.dot` cannot call `@system` function `sauced.saucer.RVector!SEXPTYPE.REALSXP.RVector.implicitCast`
```

In general the direct use of `SEXP` or any of the C API should be avoided, this issue can be resolved in a number of ways. Firstly if the `SEXP` return in the D function is required, the returned object should be explicitly cast to `SEXP`:


```
@Export("dot_product") SEXP dot(NumericVector x, NumericVector y) @safe
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return cast(SEXP)result;
}
```

Use of `auto` or the actual return type would also work ...

```
@Export("dot_product") auto dot(NumericVector x, NumericVector y) @safe
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return result;
}
```

or

```
@Export("dot_product") NumericVector dot(NumericVector x, NumericVector y) @safe
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return result;
}
```


## RVector constructors

There are a number of RVectors to cover the different types in R. These can be created/initialised in different ways. For example they can be created by providing their length **check these**:

```d
  auto x = NumericVector(10); 
```


They can be created from D arrays:

```d
  auto x = double(5);
  auto y = NumericVector(x);
```

They can be created from SEXP (discouraged):
```d
  SEXP x = someOtherFunction(...);
  auto y = NumericVector(x);
```





