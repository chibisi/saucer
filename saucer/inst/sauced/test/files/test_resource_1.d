module test.files.test_resource_1;
import sauced.saucer;

/*
    The purpose of this script is to serve as a means of 
    testing functions. It serves as a resource that can be
    used in various testing functions.
*/


/+
    Dot Product function for two double[] arrays

    Arguments
    double[] x vector of items
    double[] y vector of items

    Return
    double the dot product
+/
@Export() double dot_double(double[] x, double[] y)
{
  assert(x.length == y.length, "Lengths of x and y not equal");
  double result = 0;
  foreach(long i, _; x)
  {
    result += x[i]*y[i];
  }
  
  return result;
}


/+
    Dot Product function for two SEXP numeric arrays

    Function is exported in R as dot_product

    Argument
    SEXP x_sexp numeric vector
    SEXP y_sexp numeric vector

    Return
    SEXP numeric the dot product
+/
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


/+
    Function to create an integer vector

    Argument
    size_t n the length of the vector to be returned

    Return
    RVector!(INTSXP) vector
+/
@Export("ivector") auto create_integer_vector(size_t n)
{
    auto result = RVector!(INTSXP)(n);
    for(long i = 0; i < n; ++i)
    {
      result[i] = i;
    }
    return result;
}

