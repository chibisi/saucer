# Run this to update the saucer package
# require(testthat)

# Testing plugin style
funcs1 = '
@Export() auto funcA(double x)
{
  return x*x;
}

@Export() auto funcB(double x)
{
  return x*x*x;
}
'

funcs2 = '
import std.stdio: writeln;
@Export() auto funcC(string name)
{
  writeln("Hello ", name);
  return name;
}

@Export() auto funcD(string name)
{
  writeln("Goodbye ", name);
  return name;
}
'

# Compile both sets of functions
saucer::dfunctions(c(funcs1, funcs2), TRUE)
testthat::test_that("1. Basic tests that the dfunction plugin style is working", {
  testthat::expect_true(funcA(3) == 9, info = c("Squared function"))
  testthat::expect_true(funcB(4) == 64, info = c("Cubed function"))
  testthat::expect_true(funcC("Jimmy") == "Jimmy", info = "Basic printing and returning string")
  testthat::expect_true(funcD("Jimmy") == "Jimmy", info = "Basic printing and returning string")
})


testCode = '
@Export() auto testNamedElement()
{
  auto result = isNamedElement!(NamedElement!(int), NamedElement!(double));
  return result;
}

@Export() auto sexpToString(StringVector x)
{
  auto result = To!string(x);
  import std.stdio: writeln;
  writeln("output: ", result);
  return true;
}

@Export() auto testConversion()
{
  int result1 = is(NumericVector: SEXP);
  int result2 = is(NumericVector == SEXP);
  int result3 = is(const SEXP == SEXP);
  auto result = [result1, result2, result3];
  return(result);
}

@Export() auto testIsIn()
{
  import std.algorithm: canFind;
  auto x = ["a", "b", "c", "d", "e"];
  auto y = [1, 2, 3, 4, 5];
  int result1 = x.canFind("a");
  int result2 = y.canFind(3);
  int result3 = y.canFind(7);
  int result4 = x.canFind("z");
  auto result = [result1, result2, result3, result4];
  return result;
}
'
saucer::dfunctions(testCode, TRUE)
testNamedElement()
sexpToString("Hello World!")
testConversion()
testIsIn()


listTests = '
@Export() auto initList()
{
  auto result = List(NumericVector(1., 2, 3, 4), StringVector("Mat", "Mark", "Luke", "John"));
  return result;
}

@Export() auto namedList() @safe //currently segfaults
{
  auto result = List(
    namedElement("Places", ["New York", "Paris", "London", "Tokyo"]),
    namedElement("Population", [8.5, 2.2, 9.0, 14.0])
  );
  //Attempting appending to list
  result["Favorite"] = IntegerVector([1, 4, 2, 3]);
  return result;
}
'
saucer::dfunctions(listTests, TRUE)



# The rest of the functions are located in a script
saucer::sauce("example1.d", dropFolder = TRUE)

testthat::test_that("2. Testing functions from script", {
  
  x = seq(1.0, 10.0, by = 0.5); y = seq(1.0, 10.0, by = 0.5)
  testthat::expect_true(dot_product(x, y) == sum(x*y), info = c("Dot product test"))
  
  n = 100
  randNumbers = generate_numbers(as.integer(n))
  testthat::expect_true(length(randNumbers) == n, info = c("Check number of random numbers generated"))

  vdmul(x, y)
  ans1 = outer_prod_serial(x, y)
  testthat::expect_true(sum(abs(ans1 - x %o% y)) == 0, info = c("Outer product test"))
  
  ans2 = outer_prod_parallel(x, y) # parallel version
  testthat::expect_true(sum(abs(ans1 - ans2)) == 0, info = c("Outer product parallel output test"))
  
  testthat::expect_true(sexp_check() == 42, info = c("Type checking"))
  
  ans3 = outer_prod_types(x, y)
  testthat::expect_true(sum(abs(ans1 - ans3)) == 0, info = c("Outer product test 2"))
  
  testthat::expect_true(all(multiply_arr(x, y) == x*y), info = c("Element by element multiplication"))
  
  testthat::expect_true(abs(dot_type(x, y) - sum(x * y)) == 0, info = c("Dot product test 2"))

  cat("SEXP #1 ...\n")
  testthat::expect_equal(rep("", 10) |> test_strsxp(), rep("Hello World", 10), info = "Basic character production test 1")

  cat("SEXP #2 ...\n")
  testthat::expect_equal(rep("", 10) |> test_string(), rep("Goodbye World", 10), info = "Basic character production test 2")
  
  testthat::expect_equal(create_string_vector(10L), rep("New String", 10), info = "Generating character vector")
  testthat::expect_equal(create_string_matrix(10L, 10L), matrix("New String", ncol = 10, nrow = 10), info = "Generating character matrix")

  ans4 = create_integer_vector(10L)
  test_attr_1(ans4, "cool_nine", "my stuff")
  testthat::expect_equal(attributes(ans4)$cool_nine, "my stuff", info = "Assigning attributes 1")
  
  ans5 = create_integer_vector(10L)
  test_attr_2(ans5, "cool_nine", "my stuff")
  testthat::expect_equal(attributes(ans5)$cool_nine, "my stuff", info = "Assigning attributes 2")
  
  set.seed(0)
  x2a = create_d_factor(sample(1:10, 20, replace = TRUE))
  
  set.seed(0)
  x2b = factor(sample(1:10, 20, replace = TRUE))
  testthat::expect_equal(x2a, x2b, info = "Assigning attributes 3")
  
   testthat::expect_true(all(makeRaw(as.integer(10)) == as.raw(0:9)), info = "Test raw vectors")
})



funcs6 = '
@Export() SEXP listTest(SEXP vec1, SEXP vec2, SEXP vec3)
{
  RVector!(VECSXP) x = RVector!(VECSXP)(vec1, vec2, vec3);
  return x;
}

@Export() auto listTestRAPI(SEXP arr0, SEXP arr1, SEXP arr2)
{
  protect(arr0); protect(arr1); protect(arr2);
  auto result = protect(allocVector(VECSXP, 3));
  SET_VECTOR_ELT(result, 0, arr0);
  SET_VECTOR_ELT(result, 1, arr1);
  SET_VECTOR_ELT(result, 2, arr2);
  unprotect(4);
  return result;
}

@Export() SEXP makeDataFrame(SEXP vec1, SEXP vec2, SEXP vec3)
{
  RVector!(VECSXP) x = RVector!(VECSXP)(vec1, vec2, vec3);
  x.names = ["one", "two", "three"];
  SEXP __class_name__ = RVector!(STRSXP)(["data.frame"]);
  SEXP __row_names__ = RVector!(STRSXP)(["1", "2", "3", "4", "5"]);
  setAttrib(x, R_RowNamesSymbol, __row_names__);
  classgets(x, __class_name__);
  return x;
}

@Export() SEXP makeDataFrame1(SEXP vec1, SEXP vec2, SEXP vec3)
{
  auto df = DataFrame(vec1, vec2, vec3);
  return df;
}
'

saucer::dfunctions(funcs6, dropFolder = T)

testthat::test_that("Basic check for list", {

  cat("Running tests for basic lists ...\n")
  origList = list(1:5, 6:10, 11:15)
  rvecList = listTest(1:5, 6:10, 11:15)
  rvecAPIList = listTestRAPI(1:5, 6:10, 11:15)

  testthat::expect_true(all(origList[[1]] == rvecList[[1]]))
  testthat::expect_true(all(origList[[2]] == rvecList[[2]]))
  testthat::expect_true(all(origList[[3]] == rvecList[[3]]))

  testthat::expect_true(all(origList[[1]] == rvecAPIList[[1]]))
  testthat::expect_true(all(origList[[2]] == rvecAPIList[[2]]))
  testthat::expect_true(all(origList[[3]] == rvecAPIList[[3]]))
})


testthat::test_that("Basic dataframe check",{
  .df = makeDataFrame1(1:5, 6:10, 11:15)
  testthat::expect_true(class(.df) == "data.frame")
  testthat::expect_true(all(names(.df) == c("V0", "V1", "V2")));
  testthat::expect_true(all(.df$V0 == 1:5))
  testthat::expect_true(all(.df$V1 == 6:10))
  testthat::expect_true(all(.df$V2 == 11:15))
})


saucer::sauce("example2.d", dropFolder = TRUE)

x = listTest()
getByString(x, "matrix")
getByInteger(x, 3L)



