# Examples using XPtr (Externalptr)


```r
externalPtrExampleCode1 = '
import std.stdio: writeln;
import std.format: format;
struct Gaussian
{
    private double mean;
    private double sd;
    
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
    auto x = cast(Gaussian*)R_malloc_gc(Gaussian.sizeof);
    x[0] = Gaussian(mean, sd);
    return xptr(x);
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
ptr = createGaussian(5, 2)
par(mfrow = c(2,2))
hist({x = callRandom(ptr, 1000L)})
plot({d = callDensity(ptr, x)} ~ x)
plot({p = callProbability(ptr, x)} ~ x)
hist({q = callQuantile(ptr, p)})
```