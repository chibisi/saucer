/+
    Script to dogfood saucer library
+/

module deOptim;
import sauced.saucer;

/+
    Function to initialize the parameters of the DE algorithm
    it returns a matrix where each column is a vector item

    @param integer p - the dimension of the vector
    @param integer N - the population of vector parameters

    @return NumericMatrix of dimension p x N full of U(0, 1)
            functions.
+/
@Export() auto initialize(int p, int N, 
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
@Export() auto test()
{
    import std.range: iota, zip;
    import std.stdio: writeln;
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


@Export() auto testOrder(CharacterVector arr)
{
    return order(arr);
}



// This is the objective function type
alias Objective = double function (View!(REALSXP));

/+
    Function to evaluate the objective function for a 
    matrix with columns for parameters
+/
auto objectiveCompileTimePass(Objective /* or alias */ func)(NumericMatrix parameters)
{
    auto result = NumericVector(parameters.ncols);
    foreach(i; 0..parameters.ncols)
    {
        result[i] = func(parameters.colView(i));
    }
    return result;
}


auto objectiveRuntimePass(NumericMatrix parameters, Objective func)
{
    auto result = NumericVector(parameters.ncols);
    foreach(i; 0..parameters.ncols)
    {
        result[i] = func(parameters.colView(i));
    }
    return result;
}


@Export() auto testRuntimeObjective()
{
    import std.stdio: writeln;

    Objective func = function double(View!(REALSXP) vect){
        double result = 0;
        foreach(i; 0..vect.length)
        {
            result += vect[i];
        }
        return result;
    };

    return objectiveRuntimePass(initialize(5, 20, 
                rep!(REALSXP)(0.0, 5), rep!(REALSXP)(1.0, 5)), 
            func);
}


