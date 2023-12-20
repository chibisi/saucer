langList = list(
    Language = c("R", "D", "Julia", "Nim", "Chapel", "C++", "C"),
    Creator = c("Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
        "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
        "Dennis Richie"),
    Year = c(1993, 2001, 2012, 2008, 2009, 1985, 1970),
    Typing = c("Dynamic", "Static", "Dynamic", "Static", "Static", "Static", "Static")
)



dfExampleCode1 = '
@Export() auto simpleDataFrame()
{
    auto list = List(
        namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"]),
        namedElement("Creator", ["Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
            "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
            "Dennis Richie"]),
        namedElement("Year", [1993, 2001, 2012, 2008, 2009, 1985, 1970]),
        namedElement("Typing", ["Dynamic", "Static", "Dynamic", "Static", "Static", "Static", "Static"])
    );
    return DataFrame(list);
}
'

saucer::dfunctions(dfExampleCode1)
simpleDataFrame()



dfExampleCode2 = '
@Export() auto oneColumnDataFrame()
{
    auto df = DataFrame(
        namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"])
    );
    return df;
}
'

saucer::dfunctions(dfExampleCode2)
oneColumnDataFrame()


dfExampleCode3 = '
@Export() auto oneRowDataFrame()
{
    auto df = DataFrame(
        1
    );
    return df;
}
'

saucer::dfunctions(dfExampleCode3)
oneRowDataFrame()


dfExampleCode4 = '
@Export() auto makeDFFromSEXP(SEXP vec)
{
    auto result = DataFrame(vec);
    return result;
}
'
saucer::dfunctions(dfExampleCode4)


makeDFFromSEXP(runif(10))
makeDFFromSEXP(letters[1:5])
makeDFFromSEXP(langList)


dfExampleCode5 = '
@Export() auto makeDFFromRType()
{
    return DataFrame(NumericVector(1.0, 3, 4, 6));
}
'
saucer::dfunctions(dfExampleCode5)

makeDFFromRType()



dfExampleCode6 = '
@Export() auto makeDFFromSEXPs(SEXP col1, SEXP col2, SEXP col3)
{
    return DataFrame(col1, col2, col3);
}
'
saucer::dfunctions(dfExampleCode6)

makeDFFromSEXPs(langList$Language, langList$Creator, langList$Year)



dfExampleCode7 = '
@Export() auto makeDFFromOneItem()
{
    return DataFrame("something");
}
'
saucer::dfunctions(dfExampleCode7)

makeDFFromOneItem()


dfExampleCode8 = '
@Export() auto makeDFFromMultiplyTypes(SEXP category)
{
    auto vec = CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve");
    return DataFrame(
        category,
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"), //causes an issue
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        vec,
        NumericVector(13., 14., 15, 16, 17, 18),
        CharacterVector("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen"),
    );
}
'
saucer::dfunctions(dfExampleCode8)

category = c("A")
names(category) = "Category"

makeDFFromMultiplyTypes(category)















#----------------------------------------------------------------------------------------#
segfaultCode = '
@Export() auto makeDFFromMultiplyTypes(SEXP category)
{
    auto vec = CharacterVector("One", "Two", "Three", "Four", "Five", "Six");
    return DataFrame(
        category,
        "Stuff", 
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        1, 2, 3, 4, 5, 6,
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42))
    );
}
'