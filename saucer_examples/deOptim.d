/+
    Script to dogfood saucer library
+/

module deOptim;
import sauced.saucer;
import std.stdio: writeln;

/+
    Function to initialize the population of the DE algorithm
    it returns a matrix where each column is a vector item

    @param integer p - the dimension of the vector
    @param integer N - the population of vector population

    @return NumericMatrix of dimension p x N full of U(0, 1)
            functions.
+/
auto initialize(int p, int N, 
    NumericVector lbounds, NumericVector ubounds)
{
    assert((ubounds.length == p) && (lbounds.length == p), 
        "Number of items in bounds differs from p");
    assert(all(ubounds.cmp!(">")(lbounds)), 
        "One or more upper bounds not greater than lower bound");
    auto result = NumericMatrix(p, N);
    auto diffs = ubounds - lbounds;
    foreach(j; 0..N)
    {
        foreach(i; 0..p)
        {
            result[i, j] = lbounds[i] + diffs[i]*runif(0, 1);
        }
    }
    return result;
}


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


// This is the objective function type
alias Objective = double function (View!(REALSXP));

/+
    Function to evaluate the objective function for a 
    matrix with columns for population
+/
auto objectiveCompileTimePass(Objective /* or alias */ func)(NumericMatrix population)
{
    auto result = NumericVector(population.ncols);
    foreach(i; 0..population.ncols)
    {
        result[i] = func(population.colView(i));
    }
    return result;
}


auto objectiveRuntimePass(NumericMatrix population, Objective func)
{
    auto result = NumericVector(population.ncols);
    foreach(i; 0..population.ncols)
    {
        result[i] = func(population.colView(i));
    }
    return result;
}


/+
    Sample n integers from 0..size without replacement
+/
auto sampleInt(int n, int size)
{
    import std.range : iota;
    import std.array: array;
    import std.random: Random, unpredictableSeed, randomSample, randomShuffle;
    auto result = IntegerVector(n);
    auto rnd = Random(unpredictableSeed);
    auto _sample_ = (iota(0, size))
                        .randomSample(n, rnd)
                        .array()
                        .randomShuffle(rnd);
    result.ptr[0..n] = _sample_;
    return result;
}

/+
    Uses the scheme x_m = x_1 + F(x_2 + x_3)
    parameters is a vector of length 2
    the first element should be F the mixing coefficeint
    and the second element Cr should be the cross-over
    probability.

    @param population is the population matrix each column is an item
    @param parameters is the length two parameters containing 
            the parameters for mutation
    @param func the objective function that calculates an objective value
            from a vector
+/
NumericMatrix simpleMutation(alias func)(ref NumericMatrix population, 
                        ref NumericVector parameters)
{
    auto N = population.ncols;
    auto p = population.nrows;
    //auto result = NumericMatrix(p, N);
    auto idx = new int[3];
    auto F = parameters[0];
    auto Cr = parameters[1];
    /* Iteration over columns */
    foreach(i; 0..N)
    {
        auto idx0 = sampleInt(6, cast(int)N);
        size_t j = 0, k = 0;
        while(k < 3)
        {
            if(i != idx0[j])
            {
                idx[k] = idx0[j];
                ++k;
            }
            ++j;
        }
        auto mutant = NumericVector(p);
        auto a = population[idx[0]];
        auto b = population[idx[1]];
        auto c = population[idx[2]];

        foreach(m; 0..p)
        {
            mutant[m] = a[m] + F * (b[m] + c[m]);
        }
        auto candidate = population[i];
        //This element always crosses over
        auto coi = sampleInt(1, cast(int)p)[0];
        candidate[coi] = mutant[coi];
        foreach(m; 0..p)
        {
            if(m != coi)
            {
                //If random U(0, 1) > Cross over probability
                if(runif(0, 1) > Cr)
                {
                    candidate[m] = mutant[m];
                }
            }
        }
        auto candidateObj = func(candidate);
        auto currObj = func(population[i]);
        if(candidateObj < currObj)
        {
            population[i] = candidate;
        }else{
            population[i] = population[i];
        }
    }
    return population;
}

//Objective function 01
auto func01(NumericVector parameters)
{
    double result = 0;
    auto d = parameters.length;
    foreach(i; 0..d)
    {
        auto tmp = parameters[i];
        result += tmp*tmp;
    }
    return result;
}



@Export() auto deOptim01(int N, int niter, NumericVector lbounds, 
                NumericVector ubounds, NumericVector parameters)
{
    int p = cast(int)lbounds.length;
    auto result = initialize(p, N, lbounds, ubounds);
    foreach(i; 0..niter)
    {
        simpleMutation!(func01)(result, parameters);
    }
    return result;
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

