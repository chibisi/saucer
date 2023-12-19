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

saucer::dfunctions(dfExampleCode1, TRUE)
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

saucer::dfunctions(dfExampleCode2, TRUE)
oneColumnDataFrame()


