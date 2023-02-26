dyn.load("saucer_ihvr2g5pubfj.so")

funcA = function(x)
{
  .Call("__R_funcA__", PACKAGE = "saucer_ihvr2g5pubfj", x)
}

funcB = function(x)
{
  .Call("__R_funcB__", PACKAGE = "saucer_ihvr2g5pubfj", x)
}

funcC = function(name)
{
  .Call("__R_funcC__", PACKAGE = "saucer_ihvr2g5pubfj", name)
}

funcD = function(name)
{
  .Call("__R_funcD__", PACKAGE = "saucer_ihvr2g5pubfj", name)
}


