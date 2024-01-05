# Examples using XPtr (Externalptr)

Currently XPtr, can be used with EXTPTRSXP (but no other SEXP - at least for now), RTypes such as NumericVector, NumericMatrix etc., user defined structs and basic types.

## Example XPtr with user defined structs

```r
externalPtrExampleCode1 = '
import std.stdio: writeln;
struct Gaussian
{
    private double mean;
    private double sd;
    
    this(double mean, double sd)
    {
        this.mean = mean;
        this.sd = sd;
        return;
    }

    this(ref return scope Gaussian original)
    {
        this.mean = original.mean;
        this.sd = original.sd;
    }
    @disable this();
    ~this()
    {
        writeln("Destructor called in Gaussian");
    }
    
    auto density(double[] x, int log = 0)
    {
        auto result = NumericVector(x.length);
        foreach(i, element; x)
        {
            result[i] = dnorm4(element, mean, sd, log);
        }
        return result;
    }
    auto probability(double[] q, int lowerTail = 1, int logp = 0)
    {
        auto result = NumericVector(q.length);
        foreach(i, element; q)
        {
            result[i] = pnorm5(element, mean, sd, lowerTail, logp);
        }
        return result;
    }
    auto quantile(double[] p, int lowerTail = 1, int logp = 0)
    {
        auto result = NumericVector(p.length);
        foreach(i, element; p)
        {
            result[i] = qnorm5(element, mean, sd, lowerTail, logp);
        }
        return result;
    }
    auto random(int n)
    {
        auto result = NumericVector(n);
        foreach(i; 0..result.length)
        {
            result[i] = rnorm(mean, sd);
        }
        return result;
    }
}

@Export auto createGaussian(double mean, double sd)
{
    auto distPtr = makePointer!(Gaussian)(mean, sd);
    return xptr(distPtr);
}

@Export auto createGaussian2(double mean, double sd)
{
    auto dist = Gaussian(mean, sd);
    auto distPtr = makePointer(dist);
    return xptr(distPtr);
}

@Export auto callRandom(XPtr!(Gaussian) distPtr, int n)
{
    return distPtr.random(n);
}
@Export auto callDensity(XPtr!(Gaussian) distPtr, double[] x)
{
    return distPtr.density(x);
}
@Export auto callProbability(XPtr!(Gaussian) distPtr, double[] x)
{
    return distPtr.probability(x);
}
@Export auto callQuantile(XPtr!(Gaussian) distPtr, double[] p)
{
    return distPtr.quantile(p);
}
'
saucer::dfunctions(externalPtrExampleCode1)

# Destructor not called, because struct 
#     is never created on the stack
ptr1 = createGaussian(5, 2)
par(mfrow = c(2,2))
hist({x = callRandom(ptr1, 1000L)})
plot({d = callDensity(ptr1, x)} ~ x)
plot({p = callProbability(ptr1, x)} ~ x)
hist({q = callQuantile(ptr1, p)})

# struct is created on the stack so 
#   destructor is called (function scoped)
ptr2 = createGaussian2(8, 2)
par(mfrow = c(2,2))
hist({x = callRandom(ptr2, 1000L)})
plot({d = callDensity(ptr2, x)} ~ x)
plot({p = callProbability(ptr2, x)} ~ x)
hist({q = callQuantile(ptr2, p)})
```

## Example with NumericVector

```r
externalPtrExampleCode2 = '
@Export auto makeVectorPtr(NumericVector x)
{
    auto ptr = makePointer(x);
    return xptr(ptr);
}

@Export auto returnVector(XPtr!(NumericVector) x)
{
    NumericVector result = (cast(NumericVector*)x)[0];
    return result;
}
'
saucer::dfunctions(externalPtrExampleCode2)

x = rnorm(10)
ptr3 = makeVectorPtr(x)
y = returnVector(ptr3)
all(x == y) |> print()
```

## Example with NumericMatrix


```r
externalPtrExampleCode3 = '
@Export auto makeMatrixPtr(NumericMatrix x)
{
    auto ptr = makePointer(x);
    return xptr(ptr);
}

@Export auto returnMatrix(XPtr!(NumericMatrix) x)
{
    NumericMatrix result = (cast(NumericMatrix*)x)[0];
    return result;
}
'
saucer::dfunctions(externalPtrExampleCode3)
x = matrix(rnorm(100), nr = 10)
ptr4 = makeMatrixPtr(x)
y = returnMatrix(ptr4)
all(x == y) |> print()
```


