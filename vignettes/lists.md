# Examples using lists

## Simple list constructor

```r
exampleCode1 = '
@Export auto listCreate()
{
    auto result = List(
        namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
            "Dennis Richie"]),
        namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]),
        namedElement("Typing", ["Dynamic", "Static", "Dynamic", "Static", "Static", "Static", "Static"])
    );
    return result;
}
'
saucer::dfunctions(exampleCode1, compiler = "ldmd2")
listCreate() |> print()
```

## Slicing lists

```r
exampleCode2 = '
@Export auto slicing()
{
    auto result = List(
        namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
            "Dennis Richie"]),
        namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]),
        namedElement("Typing", ["Dynamic", "Static", "Dynamic", "Static", "Static", "Static", "Static"])
    );
    return result[1..($-1)];
}
'
saucer::dfunctions(exampleCode2, TRUE)
slicing() |> print()


exampleCode3 = '
@Export auto passThrough(SEXP orig)
{
    return List(orig)[1..($-1)];
}
'
saucer::dfunctions(exampleCode3, TRUE)
passThrough(listCreate()) |> print()
```

## Copying lists

```r
exampleCode4 = '
@Export auto copyList(List orig)
{
    auto result = List(orig);//copy constructor
    return result;
}
'
saucer::dfunctions(exampleCode4, TRUE)
copyList(listCreate()) |> print()
```

## List concatenation

```r
exampleCode5 = '
@Export auto binaryConcat1()
{
    auto lhs = List(namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
                "Dennis Richie"]));
    auto rhs = List(namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]),
                    namedElement("Typing", ["Dynamic", "Static", "Dynamic", "Static", "Static", 
                        "Static", "Static"]));
    return lhs ~ rhs;
}
'
saucer::dfunctions(exampleCode5, TRUE)
binaryConcat1() |> print()

exampleCode6 = '
@Export auto binaryConcat2()
{
    auto lhs = List(namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
                "Dennis Richie"]),
        namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]));
    auto rhs = namedElement("Typing", ["Dynamic", "Static", "Dynamic", "Static", "Static", 
                        "Static", "Static"]);
    return lhs ~ rhs;
}
'
saucer::dfunctions(exampleCode6, TRUE)
binaryConcat2() |> print()


exampleCode7 = '
@Export auto binaryConcat3()
{
    auto lhs = List(namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
                "Dennis Richie"]),
        namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]));
    auto rhs = ["Dynamic", "Static", "Dynamic", "Static", "Static", 
                        "Static", "Static"];
    return lhs ~ rhs;
}
'
saucer::dfunctions(exampleCode7, TRUE)
binaryConcat3() |> print()
```

## Length of lists

```r
exampleCode8 = '
@Export auto getLength(SEXP arr)
{
    //D\'s UFCS on R\'s length function.
    return arr.length;
}
'
saucer::dfunctions(exampleCode8, TRUE)
getLength(listCreate()) |> print()
```

## Single item lists

```r
exampleCode9 = '
@Export auto singleItemList()
{
    auto list = List(namedElement("Language", CharacterVector("R", "D", "Julia", "Nim", "Chapel", "C++", "C")));
    return list;
}
'
saucer::dfunctions(exampleCode9, TRUE)
singleItemList() |> print()
```
