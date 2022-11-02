/+
    Script to dogfood saucer library
+/

module example2;
import std.traits: isIntegral;
import sauced.saucer;
import std.math: abs;
import std.stdio: writeln;



// Sorting example
/* @Export() */ auto test()
{
    import std.range: iota, zip;
    import std.algorithm.sorting: sort;
    import std.array: array;
    auto x = ["d", "b", "a", "c"];
    auto y = iota(0, 4).array;
    foreach(tup; zip(y, x))
    {
        writeln("Tuple: index 1: ", tup[0], ", index 2: ", tup[1]);
    }
    sort!("a[0] < b[0]")(zip(x, y));
    writeln("x: ", x, "\ny: ", y);
    return;
}


@Export() testCall(int n, int size, Rboolean replace)
{
    return InternalCall("sample", n, size, replace, R_NilValue);
}


/+
    D version of lapply
    usage:
    lapplyd(as.list(rep(10, 5)), rnorm)
+/
@Export("lapplyd") auto lapply(List list, Function func)
{
    auto n = list.length;
    auto result = List(n);
    foreach(i; 0..n)
    {
        result[i] = func(list[i]);
    }
    return result;
}



/+
    Example of parallelism
    usage:
    parRNorm(100L)
+/
@Export("parRNorm") auto randGaussian(int n)
{
    import std.range: iota;
    import std.parallelism: parallel;
    double[] result = new double[n];
    foreach(i; parallel(iota(n)))
    {
        result[i] = rnorm(0, 1);
    }
    return result;
}


/+
    Usage:
    x = runif(10);
    y = runif(10);
    approxEqual(dot(x, y), sum(x*y)) # TRUE
+/
@Export("dot") auto dotProduct(double[] x, double[] y)
{
    auto n = x.length;
    assert(n == y.length, 
        "Lengths of input arrays do not match");
    double result = 0;
    foreach(i; 0..n)
    {
        result += x[i] * y[i];
    }
    return result;
}


/+
    Usage
    makeList("a", "b", runif(10), 1:10, rnorm(10))
+/
@Export() auto makeList(SEXP x0, SEXP x1, SEXP x2, SEXP x3, SEXP x4)
{
    return List.init(x0, x1, x2, x3, x4);
}

