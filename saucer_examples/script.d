module script;
import sauced.saucer;
import std.algorithm.sorting: sort;

/*
  To compile:
  
  dmd script.d saucer.d r2d.d -c -g -J="." -fPIC -L-fopenmp -L-lR -L-lRmath # -debug=rvector
  dmd script.o saucer.o r2d.o -of=script.so -L-fopenmp -L-lR -L-lRmath -shared

  # Then in R
  dyn.load("script.so") # loads
  x = seq(1.0, 10.0, by = 0.5); y = seq(1.0, 10.0, by = 0.5)
  .Call("vdmul", x, y)
*/

@Export() SEXP generate_numbers(SEXP n_ptr)
{
  assert(LENGTH(n_ptr) == 1, "There should just be 1 items.");
  int n = INTEGER(n_ptr)[0];
  SEXP result = protect(allocVector(REALSXP, n));
  auto result_ptr = REAL(result);
  
  for(int i = 0; i < n; ++i)
  {
    result_ptr[i] = runif(0.0, 1.0);
  }
  
  unprotect(1);
  return result;
}


@Export("dot_product") SEXP dot(SEXP x_sexp, SEXP y_sexp)
{
  size_t n = LENGTH(x_sexp);
  assert(n == LENGTH(y_sexp), "Lengths of the input arrays are not equal");
  
  auto x = RVector!(REALSXP)(x_sexp);
  auto y = RVector!(REALSXP)(y_sexp);
  auto result = RVector!(REALSXP)(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  
  return result;
}


@Export() SEXP vdmul(SEXP x_sexp, SEXP y_sexp)
{
  size_t n = LENGTH(x_sexp);
  assert(n == LENGTH(y_sexp), "Lengths of the input arrays are not equal");
  auto result_vector = RVector!(REALSXP)(n);
  auto x = RVector!(REALSXP)(x_sexp);
  auto y = RVector!(REALSXP)(y_sexp);
  for(long i = 0; i < n; ++i)
  {
    result_vector[i] = x[i]*y[i];
  }
  //implicit cast to SEXP
  return result_vector;
}

@Export() SEXP outer_prod_serial(SEXP x, SEXP y)
{
  size_t n_row = LENGTH(x);
  size_t n_col = LENGTH(y);
  auto result = RMatrix!(REALSXP)(n_row, n_col);
  auto x_vec = RVector!(REALSXP)(x);
  auto y_vec = RVector!(REALSXP)(y);

  for(long i = 0; i < n_row; ++i)
  {
    for(long j = 0; j < n_col; ++j)
    {
      result[i, j] = x_vec[i]*y_vec[j];
    }
  }
  
  return result;
}

@Export() SEXP outer_prod_parallel(SEXP x, SEXP y)
{
  import std.parallelism: taskPool, parallel;
  import std.range: iota;

  size_t n_row = LENGTH(x);
  size_t n_col = LENGTH(y);
  auto result = RMatrix!(REALSXP)(n_row, n_col);
  auto x_vec = RVector!(REALSXP)(x);
  auto y_vec = RVector!(REALSXP)(y);
  
  foreach(long j; iota(0, n_col))
  {
    for(long i = 0; i < n_row; ++i)
    {
      result[i, j] = x_vec[i]*y_vec[j];
    }
  }
  return result;
}

@Export() SEXP sexp_check()
{
  RVector!(REALSXP) myRVector;
  RMatrix!(INTSXP) myRMatrix;
  
  //import std.conv: to;
  import std.stdio: writeln;
  
  writeln("Subtype of myRVector: ", getSubType!(myRVector).stringof);
  writeln("Subtype of myRMatrix: ", getSubType!(myRMatrix).stringof);

  writeln("For isRVector!(myRVector) (true): ", isRVector!(myRVector));
  writeln("For isRMatrix!(myRMatrix) (true): ", isRMatrix!(myRMatrix));
  writeln("For isRVector!(myRMatrix) (false): ", isRVector!(myRMatrix));
  writeln("For isRMatrix!(myRVector) (false): ", isRMatrix!(myRVector));
  
  writeln("For isRType!(myRVector) (true): ", isRType!(myRVector));
  writeln("For isRType!(myRMatrix) (true): ", isRType!(myRMatrix));
  auto result = RVector!(INTSXP)(1);
  result[0] = 42;
  return cast(SEXP)(result);
}

@Export() SEXP outer_prod_types(RVector!(REALSXP) x, RVector!(REALSXP) y)
{
  size_t n_row = x.length;
  size_t n_col = y.length;
  auto result = RMatrix!(REALSXP)(n_row, n_col);

  for(long i = 0; i < n_row; ++i)
  {
    for(long j = 0; j < n_col; ++j)
    {
      result[i, j] = x[i]*y[j];
    }
  }
  
  return result;
}

@Export() double[] multiply_arr(double[] x, double[] y)
{
  auto n = x.length;
  assert(n == y.length, "Lengths of x and y not equal");
  double[] result = new double[n];
  for(long i = 0; i < n; ++i)
  {
    result[i] = x[i]*y[i];
  }
  
  return result;
}


@Export() double dot_type(double[] x, double[] y)
{
  assert(x.length == y.length, "Lengths of x and y not equal");
  double result = 0;
  foreach(long i, _; x)
  {
    result += x[i]*y[i];
  }
  
  return result;
}

/*
  Testing string types
*/
@Export() auto test_strsxp(RVector!(STRSXP) x)
{
  for(long i = 0; i < x.length; ++i)
  {
    x[i] = "Hello World";
  }
  return x;
}
@Export() auto test_string(string[] x)
{
  for(long i = 0; i < x.length; ++i)
  {
    x[i] = "Goodbye World";
  }
  return x;
}
@Export() auto create_string_vector(size_t n)
{
  auto result = RVector!(STRSXP)(n);
  for(long i = 0; i < n; ++i)
  {
    result[i] = "New String";
  }
  return result;
}

@Export() auto create_string_matrix(size_t nrow, size_t ncol)
{
  auto result = RMatrix!(STRSXP)(nrow, ncol);
  for(long i = 0; i < nrow; ++i)
  {
    for(long j = 0; j < ncol; ++j)
    {
      result[i, j] = "New String";
    }
  }
  return result;
}

@Export() auto create_integer_vector(size_t n)
{
  auto result = RVector!(INTSXP)(n);
  for(long i = 0; i < n; ++i)
  {
    result[i] = i;
  }
  return result;
}

auto isin(T)(in T value, in T[] arr)
{
  for(long i = 0; i < arr.length; ++i)
  {
    if(value == arr[i])
    {
      return true;
    }
  }
  return false;
}

auto sort_unique(T)(T[] arr)
{
  T[] result = [arr[0]];
  for(long i = 1; i < arr.length; ++i)
  {
    if(!isin(arr[i], result))
    {
      result ~= arr[i];
    }
  }
  result.sort;
  return result;
}


@Export() auto test_attr_1(SEXP item, SEXP name, SEXP value)
{
  setAttrib(item, name, value);
  return item;
}

@Export() auto test_attr_2(SEXP item, string name, string value)
{
  return attr(item, name, value);
}


/*
  Get the index of items on the left in items on the right
*/
auto which(T)(T[] x, T[] levels)
{
  int n = cast(int)x.length;
  auto result = new int[n];
  for(int i = 0; i < n; ++i)
  {
    for(int j = 0; j < levels.length; ++j)
    {
      if(x[i] == levels[j])
      {
        result[i] = j + 1;
        break;
      }
    }
  }
  return result;
}

@Export() auto create_d_factor(RVector!(INTSXP) arr)
{
  int[] _arr_ = To!(int[])(cast(SEXP)arr);
  auto _levels_ = sort_unique(_arr_);
  SEXP levels = To!(SEXP)(To!(string[])(_levels_));
  
  SEXP result = To!(SEXP)(which(_arr_, _levels_));
  attr(result, "class", "factor");
  attr(result, "levels", levels);
  return result;
}



@Export("makeRaw") auto make_raw(int n)
{
  auto result = RVector!(RAWSXP)(n);
  foreach(i; 0..n)
  {
    result[i] = cast(ubyte)i;
  }
  return result;
}






