# Examples using data.frames

## Simple data.frame creation

```r
dfExampleCode1 = '
@Export auto simpleDataFrame()
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
simpleDataFrame() |> print()
```


## Single column data.frame

```r
dfExampleCode2 = '
@Export auto oneColumnDataFrame()
{
    auto df = DataFrame(
        namedElement("Language", ["R", "D", "Julia", "Nim", "Chapel", "C++", "C"])
    );
    return df;
}
'
saucer::dfunctions(dfExampleCode2)
oneColumnDataFrame() |> print()
```

## Single element data.frame

```r
dfExampleCode3 = '
@Export auto oneRowDataFrame()
{
    auto df = DataFrame(
        1
    );
    return df;
}
'
saucer::dfunctions(dfExampleCode3)
oneRowDataFrame() |> print()
```

## From list

### Some data

```r
langList = list(
    Language = c("R", "D", "Julia", "Nim", "Chapel", "C++", "C"),
    Creator = c("Robert Ihaka & Ross Gentleman", "Walter Bright & Andrei Alexandrescu",
        "Jeff Bezanson et al", "Andreas Rumpf", "David Callahan et al", "Bjarne Stroustrup",
        "Dennis Richie"),
    Year = c(1993, 2001, 2012, 2008, 2009, 1985, 1970),
    Typing = c("Dynamic", "Static", "Dynamic", "Static", "Static", "Static", "Static")
)

```

### Usage

```r
dfExampleCode4 = '
@Export auto makeDFFromSEXP(SEXP vec)
{
    auto result = DataFrame(vec);
    return result;
}
'
saucer::dfunctions(dfExampleCode4)

makeDFFromSEXP(runif(10)) |> print()
makeDFFromSEXP(letters[1:5]) |> print()
makeDFFromSEXP(langList) |> print()
```


## From individual R vector

```r
dfExampleCode5 = '
@Export auto makeDFFromRType()
{
    return DataFrame(NumericVector(1.0, 3, 4, 6));
}
'
saucer::dfunctions(dfExampleCode5)
makeDFFromRType() |> print()

```


## From submitted columns

```r
dfExampleCode6 = '
@Export auto makeDFFromSEXPs(SEXP col1, SEXP col2, SEXP col3)
{
    return DataFrame(col1, col2, col3);
}
'
saucer::dfunctions(dfExampleCode6)
makeDFFromSEXPs(langList$Language, langList$Creator, langList$Year) |> print()
```

## From one item

```r
dfExampleCode7 = '
@Export auto makeDFFromOneItem()
{
    return DataFrame("something");
}
'
saucer::dfunctions(dfExampleCode7)
makeDFFromOneItem() |> print()
```

## Mix'in match

```r
dfExampleCode8 = '
@Export auto makeDFFromMultiplyTypes(SEXP category)
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
makeDFFromMultiplyTypes(category) |> print()
```


```r
dfExampleCode9 = '
@Export auto makeDFMoreSingleItems(SEXP category)
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

saucer::dfunctions(dfExampleCode9)

category = c("A")
names(category) = "Category"
makeDFMoreSingleItems(category) |> print()
```


## Subsetting a column

```r
dfExampleCode10 = '
@Export auto subsetColumns(DataFrame data, int col)
{
    return data[col - 1];
}
'

saucer::dfunctions(dfExampleCode10)


randomData = data.frame(
    Category = "A",
    Column_2 = "Stuff",
    Column_3 = c("One", "Two", "Three", "Four", "Five", "Six"),
    SomeIntegers = c(1, 2, 3, 4, 5, 6),
    SomeNumbers = c(7., 8., 9, 10, 11, 42),
    Column_6 = c("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
    Column_7 = c(13., 14., 15, 16, 17, 18),
    Column_8 = c("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen")
)

subsetColumns(randomData, 1L) |> print()
```

## Subsetting columns with integers/strings

```r
dfExampleCode11 = '
@Export auto subsetColumnIntegerSlice(DataFrame data)
{
    return data[1..6];
}
'
saucer::dfunctions(dfExampleCode11)

subsetColumnIntegerSlice(randomData) |> print()

dfExampleCode12 = '
@Export auto subsetColumnStringSlice(DataFrame data)
{
    return data["Column_2".."Column_6"];//ffor strings inclusve of last item
}
'
saucer::dfunctions(dfExampleCode12)

subsetColumnStringSlice(randomData) |> print()
```


## Subsetting rows (with integers) and columns (with integers/strings)

```r
dfExampleCode11b = '
@Export auto subsetRowColumnIntegerSlice(DataFrame data)
{
    return data[1..5, 1..6];
}
'
saucer::dfunctions(dfExampleCode11b)
subsetRowColumnIntegerSlice(randomData) |> print()

dfExampleCode12b = '
@Export auto subsetRowColumnStringSlice(DataFrame data)
{
    return data[1..5, "Column_2".."Column_6"];//ffor strings inclusve of last item
}
'
saucer::dfunctions(dfExampleCode12b)
subsetRowColumnStringSlice(randomData) |> print()
```

## Colnames

```r
dfExampleCode13 = '
@Export auto getColumnNames(DataFrame data)
{
    return data.colnames;
}
'
saucer::dfunctions(dfExampleCode13)
getColumnNames(randomData) |> print()
```

## Dimensions of the data.frame

```r
dfExampleCode14 = '
@Export auto dDim(DataFrame data)
{
    return data.dim;
}
'
saucer::dfunctions(dfExampleCode14)
dDim(randomData) |> print()
```

## Row bind with list and data.frames

```r
dfExampleCode16 = '
@Export auto rbindDFSEXP(SEXP list)
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18),
        CharacterVector("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen"),
    );
    df.rbind(list);
    return df;
}
'
saucer::dfunctions(dfExampleCode16)

testDF = data.frame(
    Category = "B",
    column_2 = "MoreStuff",
    column_3 = c("One", "Two", "Three", "Four", "Five", "Six"),
    SomeIntegers = as.integer(c(1, 2, 3, 4, 5, 6)),
    SomeNumbers = c(7., 8., 9, 10, 11, 42),
    column_6 = c("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
    column_7 = c(13., 14., 15, 16, 17, 18),
    column_8 = c("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen")
)
testList = list(
    Category = "C",
    column_2 = "EvenMoreStuff",
    column_3 = c("One", "Two", "Three", "Four", "Five", "Six"),
    SomeIntegers = as.integer(c(1, 2, 3, 4, 5, 6)),
    SomeNumbers = c(7., 8., 9, 10, 11, 42),
    column_6 = c("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
    column_7 = c(13., 14., 15, 16, 17, 18),
    column_8 = c("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen")
)

rbindDFSEXP(testList) |> print()
rbindDFSEXP(testDF) |> print()
```

## Column bind with lists and data.frames

```r
dfExampleCode17 = '
@Export auto cbindDF(DataFrame df0)
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18),
        CharacterVector("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen"),
    );
    df.cbind(df0);
    return df;
}
'
saucer::dfunctions(dfExampleCode17)

oneCol = data.frame(column_9 = rnorm(6))
multipleCols = data.frame(column_9 = rnorm(6), 
                    column_10 = runif(6), CategoryB = "D")


cbindDF(oneCol) |> print()
cbindDF(multipleCols) |> print()


dfExampleCode18 = '
@Export auto cbindList(List list)
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18),
        CharacterVector("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen")
    );
    df.cbind(list);
    return df;
}
'
saucer::dfunctions(dfExampleCode18)


oneColList = list(column_9 = rnorm(6))
multipleColsList = list(column_9 = rnorm(6), 
                    column_10 = runif(6), CategoryB = "D")

cbindList(oneColList) |> print()
cbindList(multipleColsList) |> print()
```


## Column bind with vectors

```r
dfExampleCode19 = '
@Export auto cbindRVec1()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18)
    );
    auto vec = CharacterVector("Thirteen", "Fourteen", "Fifteen", 
                    "Sixteen", "Seventeen", "Eighteen");
    df.cbind(vec);
    return df;
}
'
saucer::dfunctions(dfExampleCode19)
cbindRVec1() |> print()


dfExampleCode20 = '
@Export auto cbindRVec2()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18)
    );
    auto vec = namedElement("MoreNumbers", CharacterVector("Thirteen", "Fourteen", "Fifteen", 
                    "Sixteen", "Seventeen", "Eighteen"));
    df.cbind(vec);
    return df;
}
'
saucer::dfunctions(dfExampleCode20)
cbindRVec2() |> print()


dfExampleCode21 = '
@Export auto cbindRVec3()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18)
    );
    auto vec = [19, 20, 21, 22, 23, 24];
    df.cbind(vec);
    return df;
}
'
saucer::dfunctions(dfExampleCode21)
cbindRVec3() |> print()



dfExampleCode22 = '
@Export auto cbindRVec4()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18)
    );
    df.cbind(34);
    return df;
}
'
saucer::dfunctions(dfExampleCode22)
cbindRVec4() |> print()


dfExampleCode23 = '
@Export auto cbindRVec5()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18)
    );
    df.cbind("Nothing");
    return df;
}
'
saucer::dfunctions(dfExampleCode23)
cbindRVec5() |> print()
```

## Row selection

```r
dfExampleCode24 = '
@Export auto rowSelect()
{
    auto df = DataFrame(
        namedElement("Category", "A"),
        "Stuff",
        CharacterVector("One", "Two", "Three", "Four", "Five", "Six"),
        namedElement("SomeIntegers", [1, 2, 3, 4, 5, 6]),
        namedElement("SomeNumbers", NumericVector(7., 8., 9, 10, 11, 42)),
        CharacterVector("Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"),
        NumericVector(13., 14., 15, 16, 17, 18),
        CharacterVector("Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen"),
    );
    
    return df.rows[1..5];
}
'
saucer::dfunctions(dfExampleCode24)
rowSelect() |> print()
```

