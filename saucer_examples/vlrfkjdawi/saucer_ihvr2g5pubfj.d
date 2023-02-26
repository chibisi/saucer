module saucer_ihvr2g5pubfj;
import sauced.saucer;


@Export() auto funcA(double x)
{
  return x*x;
}

@Export() auto funcB(double x)
{
  return x*x*x;
}


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

extern (C)
{
  SEXP __R_funcA__(SEXP x)  
  {
    auto __d_funcA__ = funcA(To!(double)(x));
    static if(!isSEXP!(__d_funcA__))
    {
      return To!(SEXP)(__d_funcA__);
    }else{
      return __d_funcA__;
    }
  }

  SEXP __R_funcB__(SEXP x)  
  {
    auto __d_funcB__ = funcB(To!(double)(x));
    static if(!isSEXP!(__d_funcB__))
    {
      return To!(SEXP)(__d_funcB__);
    }else{
      return __d_funcB__;
    }
  }

  SEXP __R_funcC__(SEXP name)  
  {
    auto __d_funcC__ = funcC(To!(string)(name));
    static if(!isSEXP!(__d_funcC__))
    {
      return To!(SEXP)(__d_funcC__);
    }else{
      return __d_funcC__;
    }
  }

  SEXP __R_funcD__(SEXP name)  
  {
    auto __d_funcD__ = funcD(To!(string)(name));
    static if(!isSEXP!(__d_funcD__))
    {
      return To!(SEXP)(__d_funcD__);
    }else{
      return __d_funcD__;
    }
  }

  __gshared static const R_CallMethodDef[] callMethods = [
    R_CallMethodDef(".C__funcA__", cast(DL_FUNC) &__R_funcA__, 1), 
    R_CallMethodDef(".C__funcB__", cast(DL_FUNC) &__R_funcB__, 1), 
    R_CallMethodDef(".C__funcC__", cast(DL_FUNC) &__R_funcC__, 1), 
    R_CallMethodDef(".C__funcD__", cast(DL_FUNC) &__R_funcD__, 1), 
    R_CallMethodDef(null, null, 0)
  ];


  import core.runtime: Runtime;
  import std.stdio: writeln;

  void R_init_saucer_ihvr2g5pubfj(DllInfo* info)
  {
    writeln("Your saucer module saucer_ihvr2g5pubfj is now loaded!");
    R_registerRoutines(info, null, callMethods.ptr, null, null);
    Runtime.initialize;
    writeln("Runtime has been initialized!");
  }
  
  
  void R_unload_saucer_ihvr2g5pubfj(DllInfo* info)
  {
    writeln("Attempting to terminate saucer_ihvr2g5pubfj closing DRuntime!");
    Runtime.terminate;
    writeln("Runtime has been terminated. Goodbye!");
  }
}
