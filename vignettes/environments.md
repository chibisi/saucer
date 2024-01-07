# Examples using Environments

## Creating environments

```r
environmentExampleCode1 = '
@Export auto createEnvironment()
{
    auto result = Environment.create();
    result.assign("x", IntegerVector(1, 2, 3, 4, 5, 6));
    result["test"] = true;
    result.assign("city", "Los Angeles");
    result["temperature"] = 27;
    result.assign("scale", "centigrade");
    result.assign("numbers", [1.4, 5.2, 6.8, 4.0, 2.6]);
    return result;
}
'
saucer::dfunctions(environmentExampleCode1)
result1 = createEnvironment()
as.list(result1) |> print()
```

## Getting items from environments


```r
myEnv = new.env()
myEnv$x = c(1, 2, 3, 4, 5, 6)
myEnv$test = TRUE
myEnv$city = "Los Angeles"
myEnv$temperature = 27
myEnv$scale = "centigrade"
myEnv$numbers = c(1.4, 5.2, 6.8, 4.0, 2.6)

environmentExampleCode2 = '
@Export auto getItemFromEnvironment(Environment envir, SEXP name)
{
    return envir.get(name);
}
'
saucer::dfunctions(environmentExampleCode2)
getItemFromEnvironment(myEnv, "x")


environmentExampleCode3 = '
@Export auto getItemFromEnvironmentString(Environment envir, string name)
{
    return envir[name];
}
'
saucer::dfunctions(environmentExampleCode3)
getItemFromEnvironmentString(myEnv, "numbers")
```

## Assigning variables in environments

```r
environmentExampleCode4 = '
@Export auto assignVariableSEXP(Environment envir, SEXP name, SEXP value)
{
    envir[name] = value;
    return;
}
'
saucer::dfunctions(environmentExampleCode4)
assignVariableSEXP(myEnv, "instrument", "guitar")
as.list(myEnv) |> print()
```

## Getting R's environments

```r
environmentExampleCode5 = '
@Export auto getBaseEnv()
{
    auto env = Environment.create;
    return env.baseEnv;
}
'
saucer::dfunctions(environmentExampleCode5)
getBaseEnv() |> print()


environmentExampleCode6 = '
@Export auto getGlobalEnv()
{
    auto env = Environment.create;
    return env.globalEnv;
}
'
saucer::dfunctions(environmentExampleCode6)
getGlobalEnv() |> print()


environmentExampleCode7 = '
@Export auto getEmptyEnv()
{
    auto env = Environment.create;
    return env.emptyEnv;
}
'
saucer::dfunctions(environmentExampleCode7)
getEmptyEnv() |> print()


environmentExampleCode8 = '
@Export auto getCurrentEnv()
{
    auto env = Environment.create;
    return env.getCurrentEnvironment;
}
'
saucer::dfunctions(environmentExampleCode8)
getCurrentEnv() |> print()
```

## Locking environments and un/locking bindings

```r
lockedEnv1 = new.env()
lockedEnv1$x = rnorm(100)
lockedEnv2 = new.env()
lockedEnv2$x = rnorm(100)

environmentExampleCode9 = '
@Export auto doLockEnvironment(Environment envir, bool bindings)
{
    envir.lockEnvironment(bindings);
    return;
}
'
saucer::dfunctions(environmentExampleCode9)

doLockEnvironment(lockedEnv1, FALSE)

lockedEnv1$x = 42
lockedEnv1$x |> print()
testthat::expect_error({lockedEnv1$y = "Something New"})

doLockEnvironment(lockedEnv2, TRUE)
testthat::expect_error({lockedEnv2$x = 42})


environmentExampleCode10 = '
@Export auto doLockBinding(Environment envir, SEXP name)
{
    envir.lockBinding(name);
    return;
}

@Export auto doUnLockBinding(Environment envir, SEXP name)
{
    envir.unlockBinding(name);
    return;
}
'
saucer::dfunctions(environmentExampleCode10)


doLockBinding(myEnv, "x")
testthat::expect_error({myEnv$x = "Something New"})

doUnLockBinding(myEnv, "x")
myEnv$x = "Something New"
as.list(myEnv) |> print()
```

