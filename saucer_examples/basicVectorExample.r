require(rutilities)
require(saucer)



demoBasicVector = "
@Export(\"dotProduct\") func(NumericVector x, NumericVector y)
{
    auto n = x.length;
    assert(y.length == n, \"Vectors are not of equal length\");
    double result = 0;
    foreach(i; 0..n)
    {
        result += x[i]*y[i];
    }
    return result;
}
"


dfunctions(demoBasicVector, dropFolder = TRUE)

x = runif(100); y = runif(100);
dotProduct(x, y) == sum(x*y)

approxEqual(dotProduct(x, y), sum(x*y))


# dmd script_8w23i01y6vbu.d saucer.d r2d.d -O -boundscheck=off -mcpu=native -c -g -J=. -fPIC -L-fopenmp -L-lR -L-lRmath
# dmd script_8w23i01y6vbu.o saucer.o r2d.o -O -boundscheck=off -mcpu=native -of=script_8w23i01y6vbu.so -L-fopenmp -L-lR -L-lRmath -shared"


demoCreateVector = "
import std.stdio: writeln;

@Export(\"makeVector\") runif01(int n)
{
    auto result = NumericVector(n);
    foreach(int i; 0..n)
    {
        result[i] = runif(0.0, 1.0);
    }
    return result;
}


@Export(\"simulateDot\") dotProduct(int n)
{
    auto x = runif01(n);
    auto y = runif01(n);
    
    writeln(\"x: \", x.toString);
    writeln(\"y: \", y.toString);

    double result = 0;
    foreach(i; 0..n)
    {
        result += x[i]*y[i];
    }
    return result;
}
"

dfunctions(demoCreateVector, dropFolder = TRUE)
makeVector(100L)
simulateDot(10L)


demoVariadicD = "
@Export(\"variadic\") auto func()
{
    return RVector!(INTSXP)(1, 2, 3, 4, 5, 6);
}
"

dfunctions(demoVariadicD)
variadic()


