# Run this to update the saucer package
require("saucer")
require("rutilities")

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
dfunctions(c(funcs1, funcs2), TRUE)
funcA(3)
funcB(4)
funcC("Jimmy")
funcD("Jimmy")

funcs3 = '
@Export() auto funcE()
{
  import std.stdio: writeln;
  writeln("Hello World");
  return;
}
'
dfunctions(c(funcs3))
funcE()


funcs4 = '
@Export() auto funcG(string message)
{
  import std.stdio: writeln;
  writeln(message);
  return message;
}
'
dfunctions(c(funcs4))
funcG("My very cool message!")


funcs5 = '
@Export() auto funcH()
{
  return "Hello World!";
}
'
dfunctions(c(funcs5))
funcH()


# The rest of the functions are located in a script
saucerize("script")

x = seq(1.0, 10.0, by = 0.5); y = seq(1.0, 10.0, by = 0.5)

generate_numbers(as.integer(100))
dot(x, y) == sum(x*y)
vdmul(x, y)
ans1 = outer_prod_serial(x, y)
sum(abs(ans1 - x %o% y)) == 0
ans2 = outer_prod_parallel(x, y) # parallel version
sum(abs(ans1 - ans2)) == 0
sexp_check()

ans3 = outer_prod_types(x, y)
sum(abs(ans1 - ans3)) == 0

multiply_arr(x, y)
abs(dot_type(x, y) - sum(x * y)) == 0

# For strings
# Using SXP
rep("", 10) |> test_strsxp()
# Using string[]
rep("", 10) |> test_string()


# Create character vector within 
# the function
create_string_vector(10L)
# Create Character matrix using ...
create_string_matrix(10L, 10L)
# Just a test on integers
ans4 = create_integer_vector(10L)

# segfaults - maybe try to catch these errors
# but To! functions are evaluated at compile time
# maybe create all the alternative forms of the 
# function required? Seems like overkill
# create_string_vector(integer(10))

test_attr_1(ans4, "cool_nine", "my stuff")
print(ans4)


ans5 = create_integer_vector(10L)
test_attr_2(ans5, "cool_nine", "my stuff")
print(ans5)

set.seed(0)
x2 = sample(1:10, 20, replace = TRUE)
x2 = create_d_factor(x2)
print(x2)

