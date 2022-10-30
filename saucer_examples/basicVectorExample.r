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

demoMatrixA = "
@Export(\"helloMatrix\") auto func(int nrow, int ncol)
{
    auto result = CharacterMatrix(nrow, ncol);
    foreach(j; 0..ncol)
    {
        foreach(i; 0..nrow)
        {
            result[i, j] = \"Hello World\";
        }
    }
    return result;
}
"

dfunctions(demoMatrixA)
helloMatrix(5L, 4L)

demoMatrixB = "
@Export(\"RNGMatrix\") auto func(int nrow, int ncol)
{
    auto result = NumericMatrix(nrow, ncol);
    foreach(j; 0..ncol)
    {
        foreach(i; 0..nrow)
        {
            result[i, j] = runif(0, 1);
        }
    }
    return result;
}
"

dfunctions(demoMatrixB)
helloMatrix(10L, 6L)



demoGetCol = "
@Export(\"getCol\") auto func1(NumericMatrix mat, int i)
{
    return mat[i - 1];
}

@Export(\"setCol\") auto func2(NumericMatrix mat, int i, NumericVector col)
{
    mat[i - 1] = col;
    return mat;
}
"

dfunctions(demoGetCol)
rmat = matrix(runif(60), ncol = 6)
all(rmat[,3] == getCol(rmat, 3L))

newCol = runif(10)
setCol(rmat, 4L, newCol)
all(rmat[,4] == newCol)


require(rutilities)
require(saucer)

dotDemo = "
@Export(\"dot\") auto func(NumericVector x, NumericVector y)
{
    auto n = x.length;
    assert(n == y.length);
    double result = 0;
    foreach(i; 0..n)
    {
        result += x[i]*y[i];
    }
    return result;
}
"

dfunctions(dotDemo)

x = runif(10)
y = runif(10)
approxEqual(dot(x, y), sum(x*y))
# TRUE


require(rutilities)
require(saucer)

sauce("deOptim")

deOptim01(50L, 500L, rep(-100, 5), 
        rep(100, 5), c(0.9, 0.5))

lapplyd(as.list(rep(10, 5)), rnorm)


