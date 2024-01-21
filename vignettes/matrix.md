# Examples using matrices

## Simple instantiation with value

```r
matrixExampleCode1 = '
@Export auto simpleMatrix(double value)
{
    auto matA = NumericMatrix(value, 3, 4);
    return matA;
}
'
saucer::dfunctions(matrixExampleCode1)
(mat = simpleMatrix(3.0)) |> print()
```

## Matrix Expression example

In the example below the expression `matA + matB - matB*matC + matB*matD` is
a `MatrixExpression` and is lazily evaluated into the `NumericMatrix result`
variable. 


```r
matrixExampleCode2 = '
@Export auto matrixExpression()
{
    auto matA = NumericMatrix(1, 3, 4);
    auto matB = NumericMatrix(2, 3, 4);
    auto matC = NumericMatrix(3, 3, 4);
    auto matD = NumericMatrix(4, 3, 4);
    NumericMatrix result = matA + matB - matB*matC + matB*matD;
    return result;
}
'
saucer::dfunctions(matrixExampleCode2)
(mat = matrixExpression()) |> print()
```

It can also be returned to R as a regular R matrix

```r
matrixExampleCode3 = '
@Export auto matrixExpressionReturn()
{
    auto matA = NumericMatrix(1, 3, 4);
    auto matB = NumericMatrix(2, 3, 4);
    auto matC = NumericMatrix(3, 3, 4);
    auto matD = NumericMatrix(4, 3, 4);
    return matA + matB - matB*matC + matB*matD;
}
'
saucer::dfunctions(matrixExampleCode3)
(mat = matrixExpressionReturn()) |> print()
```

## Copy on slice example

```r
matrixExampleCode4 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto sliceCopy()
{
    auto data = iota(1.0, 41.0, 1.0).array;
    auto mat = NumericMatrix(data, 8, 5);
    return mat[2..7, 1..4];
}
'
saucer::dfunctions(matrixExampleCode4)
(mat = sliceCopy()) |> print()
```

## Index assigning

```r
matrixExampleCode5 = '
@Export auto elementAssign()
{
    auto mat = NumericMatrix(3, 4);
    
    for(long j = 0; j < mat.ncol; ++j)
    {
        for(long i = 0; i < mat.nrow; ++i)
        {
            mat[i, j] = 1 + i + j*mat.nrow;
        }
    }
    return mat;
}
'
saucer::dfunctions(matrixExampleCode5)
(mat = elementAssign()) |> print()
```

## Slice assigning from value

```r
matrixExampleCode6 = '
@Export auto sliceAssign()
{
    auto mat = NumericMatrix(0, 8, 5);
    mat[2..7, 1..4] = 42.0;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode6)
(mat = sliceAssign()) |> print()
```

### Slice assigning from matrix

```r
matrixExampleCode7 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto sliceAssignMatrix()
{
    auto data = iota(1.0, 16.0, 1.0).array;
    auto mat0 = NumericMatrix(data, 5, 3);
    auto mat = NumericMatrix(-2, 8, 5);
    mat[2..7, 1..4] = mat0;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode7)
(mat = sliceAssignMatrix()) |> print()
```

## Slice assign from `MatrixExpression`


```r
matrixExampleCode8 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto sliceAssignExpr()
{
    auto data = iota(1.0, 16.0, 1.0).array;
    auto matA = NumericMatrix(data, 5, 3);
    auto matB = NumericMatrix(2.0, 5, 3);
    auto matC = NumericMatrix(3.0, 5, 3);
    auto mat = NumericMatrix(-2, 8, 5);
    mat[2..7, 1..4] = matC * matB - matA;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode8)
(mat = sliceAssignExpr()) |> print()
```

## Slice assign from `MatrixExpression` involving constants

```r
matrixExampleCode9 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto matrixExpressionConstants()
{
    auto data = iota(1.0, 16.0, 1.0).array;
    auto matA = NumericMatrix(data, 5, 3);
    auto matB = NumericMatrix(2.0, 5, 3);
    auto matC = NumericMatrix(3.0, 5, 3);
    auto mat = NumericMatrix(-2, 8, 5);
    mat[2..7, 1..4] = 3.0*matA - matB*matC;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode9)
(mat = matrixExpressionConstants()) |> print()
```

## Slice assigning with opEquals

```r
matrixExampleCode10 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto matrixExpressionOpAssign()
{
    auto data = iota(1.0, 16.0, 1.0).array;
    auto matA = NumericMatrix(data, 5, 3);
    auto matB = NumericMatrix(2.0, 5, 3);
    auto matC = NumericMatrix(3.0, 5, 3);
    auto mat = NumericMatrix(-2, 8, 5);
    mat[2..7, 1..4] += 3.0*matA - matB*matC;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode10)
(mat = matrixExpressionOpAssign()) |> print()
```

## Matrix assign with opEquals


```r
matrixExampleCode11 = '
import std.range: iota;
import std.array: array;
import std.stdio: writeln;

@Export auto matrixExpressionOpAssign2()
{
    auto data = iota(1.0, 16.0, 1.0).array;
    auto matA = NumericMatrix(data, 5, 3);
    auto matB = NumericMatrix(2.0, 5, 3);
    auto matC = NumericMatrix(3.0, 5, 3);
    auto mat = NumericMatrix(-2, 5, 3);
    mat += 3.0*matA - matB*matC;
    return mat;
}
'
saucer::dfunctions(matrixExampleCode11)
(mat = matrixExpressionOpAssign2()) |> print()
```

## Immutable Reference matrices coming soon

