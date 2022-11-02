/+
    Script to dogfood saucer library
+/

module simpleDE;
import std.traits: isIntegral;
import sauced.saucer;
import std.math: abs;
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


auto simpleMutation(I)(ref NumericMatrix population, ref NumericVector parameters, ref I i)
if(isIntegral!(I))
{
    auto p = population.nrows;
    auto N = population.ncols;
    auto idx = new int[3];
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
        mutant[m] = a[m] + parameters[0] * (b[m] + c[m]);
    }
    return mutant;
}

struct Best
{
    size_t index;
    double value;
    alias value this;
    this(size_t index, double value)
    {
        this.index = index;
        this.value = value;
    }
    string toString()
    {
        return "index: " ~ to!string(index) ~ 
                ", value: " ~ to!string(value); 
    }
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
    @param objective the objective function that calculates an objective value
            from a vector
+/
auto iterate(alias objective)(ref NumericMatrix population, 
                        ref NumericVector parameters)
{
    auto N = population.ncols;
    auto p = population.nrows;
    auto F = parameters[0];
    auto Cr = parameters[1];
    
    double delta = 0;
    Best result = Best(0, double.max);
    Best value = Best(0, double.max);
    /* Iteration over columns */
    foreach(i; 0..N)
    {
        auto candidate = population[i];
        //This element always crosses over
        auto coi = sampleInt(1, cast(int)p)[0];
        auto mutant = simpleMutation(population, parameters, i);
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
        auto candidateObj = objective(candidate);
        auto currObj = objective(population[i]);
        if(candidateObj < currObj)
        {
            population[i] = candidate;
            value = Best(i, candidateObj);
        }else{
            value = Best(i, currObj);
        }
        delta = result - value;
        if(delta > 0)
        {
            result = value;
        }
    }
    //writeln("Iteration result, index ", 
    //    result.toString);
    return result;
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


@Export() auto deOptimize(int N, int niter, NumericVector lbounds, 
                NumericVector ubounds, NumericVector parameters)
{
    enum double eps = 1E-8;
    int p = cast(int)lbounds.length;
    auto population = initialize(p, N, lbounds, ubounds);
    Best value = Best(0, double.max);
    Best best = Best(0, double.max);
    foreach(i; 0..niter)
    {
        value = iterate!(func01)(population, parameters);
        auto delta = best - value;
        if(delta > 0)
        {
            best = value;
        }
    }
    auto result = List.init(cast(int)best.index, best.value, 
                population[best.index], population);
    result.names = ["bestIndex", "bestValue", "bestIndividual", 
            "population"];
    return result;
}



