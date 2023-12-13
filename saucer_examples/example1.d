module example1;
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

/*
  While R's C API is available, working with it directly is discouraged
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

@Export() auto dot_sexp(SEXP x_sexp, SEXP y_sexp) @safe
{
  auto x = NumericVector(x_sexp);
  auto y = NumericVector(y_sexp);

  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = NumericVector(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  return result;
}


@Export("dot_product") auto dot(NumericVector x, NumericVector y) @safe
{
  auto n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  
  auto result = NumericVector(1);
  
  for(long i = 0; i < n; ++i)
  {
    result[0] += x[i]*y[i];
  }
  return result;
}



@Export() auto vdmul(NumericVector x, NumericVector y) @safe
{
  size_t n = x.length;
  assert(n == y.length, "Lengths of the input arrays are not equal");
  auto result = NumericVector(n);
  for(long i = 0; i < n; ++i)
  {
    result[i] = x[i]*y[i];
  }
  return result;
}

@Export() auto outer_prod_serial(NumericVector x, NumericVector y) @safe
{
  size_t n_row = x.length;
  size_t n_col = y.length;
  auto result = NumericMatrix(n_row, n_col);

  for(long i = 0; i < n_row; ++i)
  {
    for(long j = 0; j < n_col; ++j)
    {
      result[i, j] = x[i] * y[j];
    }
  }
  
  return result;
}

@Export() auto outer_prod_parallel(NumericVector x, NumericVector y)
{
  import std.parallelism: taskPool, parallel;
  import std.range: iota;

  long n_row = x.length;
  long n_col = y.length;
  auto result = NumericMatrix(n_row, n_col);
  
  auto idxs = iota(0, n_col);
  //Naked use of parallel is not safe
  foreach(long j; taskPool.parallel(idxs, 5))
  {
    for(long i = 0; i < n_row; ++i)
    {
      result[i, j] = x[i]*y[j];
    }
  }
  return result;
}

@Export() auto sexp_check() @safe
{
  NumericVector myRVector;
  IntegerVector myRMatrix;
  
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
  return;
}

@Export() auto outer_prod_types(NumericVector x, NumericVector y) @safe
{
  size_t n_row = x.length;
  size_t n_col = y.length;
  auto result = NumericMatrix(n_row, n_col);

  for(long i = 0; i < n_row; ++i)
  {
    for(long j = 0; j < n_col; ++j)
    {
      result[i, j] = x[i]*y[j];
    }
  }
  
  return result;
}

@Export() auto out_of_bounds(NumericVector x) @safe
{
  return x[x.length];
}



@Export() double[] multiply_arr(double[] x, double[] y) @safe
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


@Export() double dot_type(double[] x, double[] y) @safe
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
@Export() auto test_strsxp(StringVector x) @safe
{
  for(long i = 0; i < x.length; ++i)
  {
    x[i] = "Hello World";
  }
  return x;
}
@Export() auto test_string(string[] x) @safe
{
  for(long i = 0; i < x.length; ++i)
  {
    x[i] = "Goodbye World";
  }
  return x;
}
@Export() auto create_string_vector(size_t n) @safe
{
  auto result = StringVector(n);
  for(long i = 0; i < n; ++i)
  {
    result[i] = "New String";
  }
  return result;
}

@Export() auto create_string_matrix(size_t nrow, size_t ncol) @safe
{
  auto result = StringMatrix(nrow, ncol);
  for(long i = 0; i < nrow; ++i)
  {
    for(long j = 0; j < ncol; ++j)
    {
      result[i, j] = "New String";
    }
  }
  return result;
}

@Export() auto create_integer_vector(size_t n) @safe
{
  auto result = IntegerVector(n);
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

@Export() auto create_d_factor(IntegerVector arr)
{
  int[] _arr_ = To!(int[])(cast(SEXP)arr);
  auto _levels_ = sort_unique(_arr_);
  SEXP levels = To!(SEXP)(To!(string[])(_levels_));
  
  SEXP result = To!(SEXP)(which(_arr_, _levels_));
  attr(result, "class", "factor");
  attr(result, "levels", levels);
  return result;
}



@Export("makeRaw") auto make_raw(int n) @safe
{
  auto result = RawVector(n);
  foreach(i; 0..n)
  {
    result[i] = cast(ubyte)i;
  }
  return result;
}






