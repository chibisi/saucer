# Saucer Project

The purpose of the saucer project is to create bidirectional interop between the R programming language and D, and to provide a D API to the standalone Rmath library. The aim is that in time, it will have a similar functional set to libraries like Rcpp in terms of its features and capability, but with the added advantage that the D programming language is more accessible than C++, and has powerful set of programming paradigms influenced by C, C++, Java, and languages in the functional sphere. For more information see the [D programming language website](https://dlang.org/).

## Implementation approach

For now the implementation of the library is in it's early phase. The library provides data objects that wrap the R SEXP objects, but are statically typed with respect to the SEXPTYPE:

* Vectors (RVector)
    - `alias NumericVector = RVector!(REALSXP);`
    - `alias IntegerVector = RVector!(INTSXP);`
    - `alias LogicalVector = RVector!(LGLSXP);`
    - `alias RawVector = RVector!(RAWSXP);`
    - `alias ComplexVector = RVector!(CPLXSXP);`
    - `alias CharacterVector = RVector!(STRSXP);`
    - `alias StringVector = CharacterVector;`
* Matrices (RMatrix)
    - `alias NumericMatrix = RMatrix!(REALSXP);`
    - `alias IntegerMatrix = RMatrix!(INTSXP);`
    - `alias ComplexMatrix = RMatrix!(CPLXSXP);`
    - `alias CharacterMatrix = RMatrix!(STRSXP);`
    - `alias StringMatrix = CharacterMatrix;`
    - `alias LogicalMatrix = RMatrix!(LGLSXP);`
    - `alias RawMatrix = RMatrix!(RAWSXP);`
* List (list)
* Dataframe (data.frame)
* Functions (R functions, lambdas, and closures)

These objects are written in D structs as supposed to classes, and so do not directly associate with the D garbage collector. Method dispatch relies heavily on D's compile time traits system. And D's strings mixins are heavily used to generate the functions that wrap those that are given by the user, which are then compiled to DLLs and called by R through an auto generated R function.

Other objects such as Functions, Environments, and External Pointers are already in development and will follow shortly. In addition tools that allow R code to be run from D are already available, in the `rinside` module. This functionality is still fairly raw but will be expandedd upon in due course. Methods in the types provided are marked with `@trusted` to allow them to be called with `@safe` attribute.


### Other efforts

There is a project called [embedr](https://github.com/bachmeil/embedrv2/tree/main) which is an early effort for R and D interop. However as of writing this (2023-12-20) it requires precompiled code that ships with the library - which has security implications, it is syntactically quite different from popular interfaces like Rcpp, and not as feature rich as saucer.


## Compiling D code

The package provides two main functions to compile D code and immediately include it in an R session:

1. `dfunctions(...)` function to compile D code strings containing exported functions to be called in R
2. `sauce(...)` function to compile D files containing exported function to be called in R

### D compilers

There are [three D compilers](https://dlang.org/download.html), two of which are supported in this package, namely the LDC (LLVM) compiler (the `ldmd2` interface is supported), and the DMD (Digital Mars D compiler `dmd`), either of which can be selected in the supplied R functions mentioned above. You may notice that the LDC LLVM compiler takes much longer to compile code than the DMD reference compiler.


## Prerequisites & Installation

1. D's LDC compiler installed
2. R-mathlib installed
3. R's development tools installed - or the development version of R

For now, this library is Linux only. For installation details, see the [wiki](https://github.com/chibisi/saucer/wiki).


## Examples

Exported function must be marked with `@Export(...)` (or `@Export`) where `...` is an option export name. For example:

```r
codeExample1 = '
import std.stdio: writeln;
//This function returns void
@Export auto helloWorld()
{
    writeln("Hello World!");
    return;
}
'
saucer::dfunctions(codeExample1)
helloWorld() # returns NULL
```


```r
codeExample2 = '
@Export("DotArray") auto dot_array(double[] x, double[] y)
{
    auto n = x.length;
    enforce(n == y.length, "Arrays x, and y lengths are not equal");
    double result = 0;
    foreach(i; 0..n)
    {
        result += x[i] * y[i];
    }
    return result;
}'
saucer::dfunctions(codeExample2)
round(DotArray({x = runif(100)}, {y = runif(100)}), 4) == round(sum(x*y), 4)
# Could also use # DotArray(runif(10), runif(10))
```

In the above example, you can see that the native D array notation and `auto` infer return type can be used directly. To all intents and purposes, the `dot_array(...)` function is regular D code. The `@Export("DotArray")` user defined attribute (UDA) is used to export the function to R as the function `DotArray`, any function being exported to R *must* at least be marked with `@Export()` (with or without the brackets), and at the moment the compilation will fail if no functions are exported.


Simple example with scalar inputs and outputs

```r
codeExample3 = '
@Export int signD(int x)
{
    if(x > 0)
    {
        return 1;
    }else if(x == 0)
    {
        return 0;
    }else{
        return -1;
    }
}
'
saucer::dfunctions(codeExample3)
# Note integers must be submitted to a function requiring integer parameters
signD(-10L) == sign(-10L)
signD(0L) == sign(0L)
signD(100L) == sign(100L)
```

Vector input scalar output:

```r
codeExample4 = '
@Export double sumD(NumericVector x)
{
    auto n = x.length;
    double result = 0;
    for(typeof(n) i = 0; i < n; ++i)
    {
        result += x[i];
    }
    return result;
}
'
saucer::dfunctions(codeExample4)
sumD(seq(0, 10, by = 0.5))
```

Vector input with a vector output

```r
codeExample5 = '
import std.math: sqrt, pow;
@Export auto pdistD(double x, NumericVector y)
{
    auto n = y.length;
    auto result = NumericVector(n);
    foreach(i; 0..n)
    {
        result[i] = sqrt(pow(y[i] - x, 2));
    }
    return result;
}
'
saucer::dfunctions(codeExample5)
pdistD(5, rnorm(10, mean = 5))
```


Simple matrix example

```r
codeExample6 = '
@Export auto rowSumsD(IntegerMatrix x)
{
    auto nrow = x.nrow, ncol = x.ncol;
    auto result = NumericVector(nrow);
    foreach(i; 0..nrow)
    {
        double total = 0;
        foreach(j; 0..ncol)
        {
            total += x[i, j];
        }
        result[i] = total;
    }
    return result;
}
'
saucer::dfunctions(codeExample6)
set.seed(1014)
x = matrix(sample(100), 10)
all(rowSumsD(x) == rowSums(x))
```

We can compile more than one code snippet:
```r
saucer::dfunctions(c(codeExample5, codeExample6))
```
Note that the snippets are joined and compiled together in one script.

Below is the D code for `meancalc.d` a file that calculates the mean of a numeric vector:

```d
module meancalc;
import sauced.saucer;

@Export auto meanD(NumericVector x)
{
    auto n = x.length;
    double total = 0;
    foreach(i; 0..n)
    {
        total += x[i];
    }
    return total/n;
}
```

It can be compiled and then run with:

```r
saucer::sauce("meancalc.d")
meanD({x = runif(1000)})
mean(x)
```

consider `rowsums.d` below

```d
module rowsums;
import sauced.saucer;

@Export auto rowSumsD(IntegerMatrix x)
{
    auto nrow = x.nrow, ncol = x.ncol;
    auto result = NumericVector(nrow);
    foreach(i; 0..nrow)
    {
        double total = 0;
        foreach(j; 0..ncol)
        {
            total += x[i, j];
        }
        result[i] = total;
    }
    return result;
}
```

We can compile a file with exports with files with dependencies. Consider the following script `averagerandom.d`:

```d
module averagerandom;
import randomnumbers;
import sauced.saucer;

@Export auto calcRandomAverage(int n)
{
    auto x = generateNumbers(n);
    double total = 0;
    foreach(i; 0..n)
    {
        total += x[i];
    }
    return total/n;
}
```

It imports code from `randomnumbers.d`:

```d
module randomnumbers;
import std.random: uniform01;
import std.traits: isIntegral;


auto generateNumbers(I)(I n)
if(isIntegral!I)
{
    auto result = new double[n];
    foreach(i; 0..n)
    {
        result[i] = uniform01();
    }
    return result;
}
```

We can compile them both together (only marked functions in `averagerandom.d` will be exported):

```r
saucer::sauce(c("averagerandom.d", "randomnumbers.d"))
calcRandomAverage(100L)
```

### Function examples
[Examples for R function interop with D](./vignettes/functions.md)


### List examples
[Examples for R list interop with D](./vignettes/lists.md)


### DataFrame examples
[Examples for R data.frame interop with D](./vignettes/dataframe.md)


### Environment examples

[Examples for R environment interop with D](./vignettes/environments.md)


More examples will follow ...

## Limitations

- Limited type coverage - as discussed this will change rapidly to include more R types.
- Documentation - this will also be expanded on in due time.
- Type qualification support for interfacing types, e.g. immutable, const and so forth.
- No (direct) tooling to creating R packages containing D code in an easy a way as in Rcpp.


## References

1. [D Programming Language](https://dlang.org/).
2. [Rcpp package, Dirk Eddelbuettel et al](https://cran.r-project.org/web/packages/Rcpp/).
3. [A tool for translating C and Objective-C headers to D modules](https://code.dlang.org/packages/dstep)
4. [Writing R Extenstions, Chapter 5, R Core Team](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#System-and-foreign-language-interfaces).
5. [R Internals, Chapter 1, R Core Team](https://cran.r-project.org/doc/manuals/r-release/R-ints.html#R-Internal-Structures).
6. [Documentation for R's internal C API, Hadley Wickham](https://github.com/hadley/r-internals/tree/master).
7. [Unprotecting by Value, R Blog, Tomas Kalibera](https://blog.r-project.org/2018/12/10/unprotecting-by-value/).
8. [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html).


