# Examples using Function

## Pass through R function to be called in D

```r
functionExampleCode1 = '
@Export auto dRunif(SEXP rFunc)
{
    auto dFunc = Function(rFunc);
    return dFunc(10, -1.0, 1);
}
'
saucer::dfunctions(functionExampleCode1)
dRunif(runif)
```


## Function evaluation in specified environemnt

```r
envir = environment()
envir$n = 20 # function environment
functionExampleCode2 = '
@Export auto dRunif2(SEXP rFunc, SEXP envir)
{
    auto dFunc = Function(rFunc, envir);
    return dFunc();
}
'
saucer::dfunctions(functionExampleCode2)
dRunif2(\()runif(n), envir)

```

## Creating R function on the fly in D and evaluating there

```r
functionExampleCode3 = '
@Export auto nicePlot()
{
    string functionString = `
        function(n)
        {
            plot(
                cumsum(rnorm(n) + 0.1), bg = "brown", 
                    pch = 21, ylab = "stock", xlab = "tick",
                    t = "o")
            return(invisible())
        }
    `;
    auto dFunc = Function.init(functionString);
    dFunc(200);
    return;
}
'
saucer::dfunctions(functionExampleCode3)
nicePlot()
```


## Creating R function by passing R string

```r
functionExampleCode4 = '
@Export auto createNicePlotFunction(SEXP functionString)
{
    auto dFunc = Function.init(functionString);
    return dFunc;
}
'
saucer::dfunctions(functionExampleCode4)

functionString = "
function(n)
{
    plot(
        cumsum(rnorm(n) + 0.1), bg = \"brown\", 
            pch = 21, ylab = \"stock\", xlab = \"tick\",
            t = \"o\")
    return(invisible())
}
"
nicePlot2 = createNicePlotFunction(functionString)
nicePlot2(200)
```


