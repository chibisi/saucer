module sauced.r2d;

import core.stdc.config;
import core.stdc.stddef;
import core.stdc.stdarg;

extern (C):

alias FILE = _IO_FILE;
struct _IO_FILE;

enum
{
    FP_NAN = 0,
    FP_INFINITE = 1,
    FP_ZERO = 2,
    FP_SUBNORMAL = 3,
    FP_NORMAL = 4
}

extern __gshared double R_NaN;
extern __gshared double R_PosInf;
extern __gshared double R_NegInf;
extern __gshared double R_NaReal;
extern __gshared int R_NaInt;
int R_IsNA (double);
int R_IsNaN (double);
int R_finite (double);


struct Rboolean
{
    int _data_;
    alias _data_ this;
    this(int value) @trusted
    {
        if(value == 0)
        {
            this._data_ = 0;
        }else{
            this._data_ = 1;
        }
    }
    auto opAssign(bool value) @trusted
    {
        if(!value)
        {
            _data_ = 0;
        }else{
            _data_ = 1;
        }
    }
    string toString() @trusted
    {
        if(_data_ == 0)
        {
            return "FALSE";
        }else{
            return "TRUE";
        }
    }
    bool opCast(T: bool)() const @trusted
    {
        return cast(bool)_data_;
    }
}

enum FALSE = Rboolean(0);
enum TRUE = Rboolean(1);


struct Rcomplex
{
    import std.complex: Complex;
    import std.traits: isANumber = isNumeric;
    double r;
    double i;

    this(T)(T r)
    if(isANumber!(T))
    {
        this.r = cast(double)r;
        this.i = 0;
    }
    this(T)(T r, T i)
    if(isANumber!(T))
    {
        this.r = cast(double)r;
        this.i = cast(double)i;
    }
    this(inout ref Rcomplex original) inout
    {
        this.r = original.r;
        this.i = original.i;
    }
    Rcomplex opUnary(string op)()
    {
        mixin("return Rcomplex(" ~ op ~ " this.r, " ~ op ~ " this.i);");
    }
    Rcomplex opBinary(string op, T)(T num)
    if(isANumber!(T))
    {
        static if((op == "+") || (op == "-"))
        {
            mixin("return Rcomplex(this.r " ~ op ~ " num, this.i);");
        }else static if((op == "*") || (op == "/"))
        {
            mixin("return Rcomplex(this.r " ~ op ~ " num, this.i " ~ op ~ " num);");
        }else{
            enforce(0, "No opBinary implementation for operator " ~ op);
        }
    }
    Rcomplex opBinary(string op)(Rcomplex num)
    {
        static if((op == "+") || (op == "-"))
        {
            mixin("return Rcomplex(this.r " ~ op ~ " num.r, this.i " ~ op ~ " num.i);");
        }else static if((op == "*") || (op == "/"))
        {
            mixin("return Rcomplex((this.r " ~ op ~ " num.r) - (this.i " ~ op ~ " num.i), (this.r " ~ op ~ " num.i) + (this.i " ~ op ~ " num.r));");
        }else{
            enforce(0, "No opBinary implementation for operator " ~ op);
        }
    }
    ref Rcomplex opOpAssign(string op, T)(T num) return
    if(is(T == Rcomplex) || isANumber!(T))
    {
        mixin("this = this " ~ op ~ " num;");
        return this;
    }

    auto opEquals(Rcomplex num)
    {
        return (this.r == num.r) && (this.i == num.i);
    }
    auto opEquals(double num)
    {
        return (this.r == num) && (this.i == 0);
    }
    @property Rcomplex conjugate()
    {
        return Rcomplex(this.r, -this.i);
    }
    Complex!(double) opCast(T: Complex!(double))()
    {
        return Complex!(double)(this.r, this.i);
    }
    string toString()
    {
        import std.conv: to;
        string result = to!(string)(this.r);
        if(this.i >= 0)
        {
            result ~= "+";
            result ~= to!(string)(this.i) ~ "i";
        }else{
            result ~= "-";
            result ~= to!(string)(-1*this.i) ~ "i";
        }
        return result;
    }
}


unittest
{
    import std.stdio: writeln;
    import std.complex: Complex;

    import sauced.saucer: initEmbedR;
    initEmbedR();

    writeln("Rcomplex tests ...\n######################################################\n");

    writeln("opEquals tests ...");
    auto x1 = Rcomplex(3, 4);
    assert(x1 == Rcomplex(3, 4), "Rcomplex vs Rcomplex opEquals falied!");
    assert(x1 != Rcomplex(3, 6), "Rcomplex vs Rcomplex opEquals falied!");
    assert(Rcomplex(3, 0) == 3, "Rcomplex vs real number opEquals falied!");
    assert(Rcomplex(3, 0) != 4, "Rcomplex vs real number opEquals falied!");
    writeln("4 opEquals tests passed");

    writeln("\nMultiplication tests");
    assert(Rcomplex(3, 4) * Rcomplex(1, 3) == Rcomplex(-9, 13), "Rcomplex vs Rcomplex multiplication falied!");
    assert(x1 * 3 == Rcomplex(9, 12), "Rcomplex vs scalar multiplication falied!");
    writeln("2 Multiplication tests passed");
    
    writeln("\nAddition tests ...");
    assert(Rcomplex(3, 4) + Rcomplex(1, 3) == Rcomplex(4, 7), "Rcomplex vs Rcomplex addition test falied!");
    assert(Rcomplex(3, 4) + 3 == Rcomplex(6, 4), "Rcomplex vs scalar addition falied!");
    writeln("2 Addition tests passed");

    writeln("\nUnary operations ...");
    assert(-Rcomplex(2, -5) == Rcomplex(-2, 5), "Rcomplex unary negation failed.");
    assert(++Rcomplex(2, 4) == Rcomplex(3, 5), "Rcomplex unary increment failed.");
    writeln("3 Unary operation tests passed");

    writeln("\nConjugate tests ....");
    assert(Rcomplex(2, 6).conjugate == Rcomplex(2, -6), "Rcomplex conjugate test failed.");
    assert(Rcomplex(2, -3).conjugate == Rcomplex(2, 3), "Rcomplex conjugate test failed.");
    assert(Rcomplex(-7, -3).conjugate == Rcomplex(-7, 3), "Rcomplex conjugate test failed.");
    writeln("3 complex conjugate tests passed");

    writeln("\nCast test ...");
    auto dComplex = cast(Complex!(double)) Rcomplex(6, 3);
    assert(dComplex == Complex!(double)(6, 3), "Cast to D Compplex!(double) failed.");
    writeln("1 cast test passed");

    writeln("\nopOpAssign tests ...");
    x1 = Rcomplex(2, 5);
    x1 += Rcomplex(1, 2);
    assert(x1 == Rcomplex(3, 7), "Rcomplex vs Rcomplex opOpAssign failed");
    x1 -= 7;
    assert(x1 == Rcomplex(-4, 7), "Rcomplex vs scalar opOpAssign failed");
    writeln("2 opOpAssign tests passed");

    writeln("\nEnd of Rcomplex tests\n######################################################\n");
}


void Rf_error (const(char)*, ...);
void UNIMPLEMENTED (const(char)*);
void WrongArgCount (const(char)*);
void Rf_warning (const(char)*, ...);
void R_ShowMessage (const(char)* s);
alias ptrdiff_t = c_long;

struct max_align_t
{
    long __max_align_ll;
    real __max_align_ld;
}

void* vmaxget ();
void vmaxset (const(void)*);
void R_gc ();
int R_gc_running ();
char* R_alloc (size_t, int);
real* R_allocLD (size_t nelem);
char* S_alloc (c_long, int);
char* S_realloc (char*, c_long, c_long, int);
void* R_malloc_gc (size_t);
void* R_calloc_gc (size_t, size_t);
void* R_realloc_gc (void*, size_t);
void Rprintf (const(char)*, ...);
void REprintf (const(char)*, ...);
void Rvprintf (const(char)*, va_list);
void REvprintf (const(char)*, va_list);

enum RNGtype
{
    WICHMANN_HILL = 0,
    MARSAGLIA_MULTICARRY = 1,
    SUPER_DUPER = 2,
    MERSENNE_TWISTER = 3,
    KNUTH_TAOCP = 4,
    USER_UNIF = 5,
    KNUTH_TAOCP2 = 6,
    LECUYER_CMRG = 7
}

enum N01type
{
    BUGGY_KINDERMAN_RAMAGE = 0,
    AHRENS_DIETER = 1,
    BOX_MULLER = 2,
    USER_NORM = 3,
    INVERSION = 4,
    KINDERMAN_RAMAGE = 5
}

enum Sampletype
{
    ROUNDING = 0,
    REJECTION = 1
}

Sampletype R_sample_kind ();
void GetRNGstate ();
void PutRNGstate ();
double unif_rand ();
double R_unif_index (double);
double norm_rand ();
double exp_rand ();
alias Int32 = uint;
double* user_unif_rand ();
void user_unif_init (Int32);
int* user_unif_nseed ();
int* user_unif_seedloc ();
double* user_norm_rand ();
void R_isort (int*, int);
void R_rsort (double*, int);
void R_csort (Rcomplex*, int);
void rsort_with_index (double*, int*, int);
void Rf_revsort (double*, int*, int);
void Rf_iPsort (int*, int, int);
void Rf_rPsort (double*, int, int);
void Rf_cPsort (Rcomplex*, int, int);
void R_qsort (double* v, size_t i, size_t j);
void R_qsort_I (double* v, int* II, int i, int j);
void R_qsort_int (int* iv, size_t i, size_t j);
void R_qsort_int_I (int* iv, int* II, int i, int j);
const(char)* R_ExpandFileName (const(char)*);
void Rf_setIVector (int*, int, int);
void Rf_setRVector (double*, int, double);
Rboolean Rf_StringFalse (const(char)*);
Rboolean Rf_StringTrue (const(char)*);
Rboolean Rf_isBlankString (const(char)*);
double R_atof (const(char)* str);
double R_strtod (const(char)* c, char** end);
char* R_tmpnam (const(char)* prefix, const(char)* tempdir);
char* R_tmpnam2 (const(char)* prefix, const(char)* tempdir, const(char)* fileext);
void R_free_tmpnam (char* name);
void R_CheckUserInterrupt ();
void R_CheckStack ();
void R_CheckStack2 (size_t);
int findInterval (
    double* xt,
    int n,
    double x,
    Rboolean rightmost_closed,
    Rboolean all_inside,
    int ilo,
    int* mflag);
int findInterval2 (
    double* xt,
    int n,
    double x,
    Rboolean rightmost_closed,
    Rboolean all_inside,
    Rboolean left_open,
    int ilo,
    int* mflag);
void find_interv_vec (
    double* xt,
    int* n,
    double* x,
    int* nx,
    int* rightmost_closed,
    int* all_inside,
    int* indx);

void R_max_col (double* matrix, int* nr, int* nc, int* maxes, int* ties_meth);
void* R_chk_calloc (size_t, size_t);
void* R_chk_realloc (void*, size_t);
void R_chk_free (void*);
void call_R (char*, c_long, void**, char**, c_long*, char**, c_long, char**);
alias Sfloat = double;
alias Sint = int;
void R_FlushConsole ();
void R_ProcessEvents ();
alias DL_FUNC = void* function();
alias R_NativePrimitiveArgType = uint;

struct R_CMethodDef
{
    const(char)* name;
    DL_FUNC fun;
    int numArgs;
    R_NativePrimitiveArgType* types;
}

alias R_FortranMethodDef = R_CMethodDef;

struct R_CallMethodDef
{
    const(char)* name;
    DL_FUNC fun;
    int numArgs;
}

alias R_ExternalMethodDef = R_CallMethodDef;
struct _DllInfo;
alias DllInfo = _DllInfo;
int R_registerRoutines (
    DllInfo* info,
    const R_CMethodDef* croutines,
    const R_CallMethodDef* callRoutines,
    const R_FortranMethodDef* fortranRoutines,
    const R_ExternalMethodDef* externalRoutines);
Rboolean R_useDynamicSymbols (DllInfo* info, Rboolean value);
Rboolean R_forceSymbols (DllInfo* info, Rboolean value);
DllInfo* R_getDllInfo (const(char)* name);
DllInfo* R_getEmbeddingDllInfo ();
struct Rf_RegisteredNativeSymbol;
alias R_RegisteredNativeSymbol = Rf_RegisteredNativeSymbol;

enum NativeSymbolType
{
    R_ANY_SYM = 0,
    R_C_SYM = 1,
    R_CALL_SYM = 2,
    R_FORTRAN_SYM = 3,
    R_EXTERNAL_SYM = 4
}

DL_FUNC R_FindSymbol (
    const(char)*,
    const(char)*,
    R_RegisteredNativeSymbol* symbol);
void R_RegisterCCallable (const(char)* package_, const(char)* name, DL_FUNC fptr);
DL_FUNC R_GetCCallable (const(char)* package_, const(char)* name);
alias Rbyte = ubyte;
alias R_len_t = int;
alias R_xlen_t = c_long;

enum SEXPTYPE
{
    NILSXP = 0,
    SYMSXP = 1,
    LISTSXP = 2,
    CLOSXP = 3,
    ENVSXP = 4,
    PROMSXP = 5,
    LANGSXP = 6,
    SPECIALSXP = 7,
    BUILTINSXP = 8,
    CHARSXP = 9,
    LGLSXP = 10,
    INTSXP = 13,
    REALSXP = 14,
    CPLXSXP = 15,
    STRSXP = 16,
    DOTSXP = 17,
    ANYSXP = 18,
    VECSXP = 19,
    EXPRSXP = 20,
    BCODESXP = 21,
    EXTPTRSXP = 22,
    WEAKREFSXP = 23,
    RAWSXP = 24,
    S4SXP = 25,
    NEWSXP = 30,
    FREESXP = 31,
    FUNSXP = 99
}

struct SEXPREC;
alias SEXP = SEXPREC*;
const(char)* R_CHAR (SEXP x);
Rboolean Rf_isNull (SEXP s);
Rboolean Rf_isSymbol (SEXP s);
Rboolean Rf_isLogical (SEXP s);
Rboolean Rf_isReal (SEXP s);
Rboolean Rf_isComplex (SEXP s);
Rboolean Rf_isExpression (SEXP s);
Rboolean Rf_isEnvironment (SEXP s);
Rboolean Rf_isString (SEXP s);
Rboolean Rf_isObject (SEXP s);

enum
{
    SORTED_DECR_NA_1ST = -2,
    SORTED_DECR = -1,
    UNKNOWN_SORTEDNESS = -0x7fffffff - 1,
    SORTED_INCR = 1,
    SORTED_INCR_NA_1ST = 2,
    KNOWN_UNSORTED = 0
}

SEXP ATTRIB (SEXP x);
int OBJECT (SEXP x);
int MARK (SEXP x);
int TYPEOF (SEXP x);
int NAMED (SEXP x);
int REFCNT (SEXP x);
int TRACKREFS (SEXP x);
void SET_OBJECT (SEXP x, int v);
void SET_TYPEOF (SEXP x, int v);
void SET_NAMED (SEXP x, int v);
void SET_ATTRIB (SEXP x, SEXP v);
void DUPLICATE_ATTRIB (SEXP to, SEXP from);
void SHALLOW_DUPLICATE_ATTRIB (SEXP to, SEXP from);
void ENSURE_NAMEDMAX (SEXP x);
void ENSURE_NAMED (SEXP x);
void SETTER_CLEAR_NAMED (SEXP x);
void RAISE_NAMED (SEXP x, int n);
void DECREMENT_REFCNT (SEXP x);
void INCREMENT_REFCNT (SEXP x);
void DISABLE_REFCNT (SEXP x);
void ENABLE_REFCNT (SEXP x);
void MARK_NOT_MUTABLE (SEXP x);
int ASSIGNMENT_PENDING (SEXP x);
void SET_ASSIGNMENT_PENDING (SEXP x, int v);
int IS_ASSIGNMENT_CALL (SEXP x);
void MARK_ASSIGNMENT_CALL (SEXP x);
int IS_S4_OBJECT (SEXP x);
void SET_S4_OBJECT (SEXP x);
void UNSET_S4_OBJECT (SEXP x);
int NOJIT (SEXP x);
int MAYBEJIT (SEXP x);
void SET_NOJIT (SEXP x);
void SET_MAYBEJIT (SEXP x);
void UNSET_MAYBEJIT (SEXP x);
int IS_GROWABLE (SEXP x);
void SET_GROWABLE_BIT (SEXP x);
int LENGTH (SEXP x);
R_xlen_t XLENGTH (SEXP x);
R_xlen_t TRUELENGTH (SEXP x);
void SETLENGTH (SEXP x, R_xlen_t v);
void SET_TRUELENGTH (SEXP x, R_xlen_t v);
int IS_LONG_VEC (SEXP x);
int LEVELS (SEXP x);
int SETLEVELS (SEXP x, int v);
int* LOGICAL (SEXP x);
int* INTEGER (SEXP x);
Rbyte* RAW (SEXP x);
double* REAL (SEXP x);
Rcomplex* COMPLEX (SEXP x);
const(int)* LOGICAL_RO (SEXP x);
const(int)* INTEGER_RO (SEXP x);
const(Rbyte)* RAW_RO (SEXP x);
const(double)* REAL_RO (SEXP x);
const(Rcomplex)* COMPLEX_RO (SEXP x);
SEXP VECTOR_ELT (SEXP x, R_xlen_t i);
void SET_STRING_ELT (SEXP x, R_xlen_t i, SEXP v);
SEXP SET_VECTOR_ELT (SEXP x, R_xlen_t i, SEXP v);
SEXP* STRING_PTR (SEXP x);
const(SEXP)* STRING_PTR_RO (SEXP x);
SEXP* VECTOR_PTR (SEXP x);
void* STDVEC_DATAPTR (SEXP x);
int IS_SCALAR (SEXP x, int type);
int ALTREP (SEXP x);
SEXP ALTREP_DUPLICATE_EX (SEXP x, Rboolean deep);
SEXP ALTREP_COERCE (SEXP x, int type);
Rboolean ALTREP_INSPECT (SEXP, int, int, int, void function (SEXP, int, int, int));
SEXP ALTREP_SERIALIZED_CLASS (SEXP);
SEXP ALTREP_SERIALIZED_STATE (SEXP);
SEXP ALTREP_UNSERIALIZE_EX (SEXP, SEXP, SEXP, int, int);
R_xlen_t ALTREP_LENGTH (SEXP x);
R_xlen_t ALTREP_TRUELENGTH (SEXP x);
void* ALTVEC_DATAPTR (SEXP x);
const(void)* ALTVEC_DATAPTR_RO (SEXP x);
const(void)* ALTVEC_DATAPTR_OR_NULL (SEXP x);
SEXP ALTVEC_EXTRACT_SUBSET (SEXP x, SEXP indx, SEXP call);
int ALTINTEGER_ELT (SEXP x, R_xlen_t i);
void ALTINTEGER_SET_ELT (SEXP x, R_xlen_t i, int v);
int ALTLOGICAL_ELT (SEXP x, R_xlen_t i);
void ALTLOGICAL_SET_ELT (SEXP x, R_xlen_t i, int v);
double ALTREAL_ELT (SEXP x, R_xlen_t i);
void ALTREAL_SET_ELT (SEXP x, R_xlen_t i, double v);
SEXP ALTSTRING_ELT (SEXP, R_xlen_t);
void ALTSTRING_SET_ELT (SEXP, R_xlen_t, SEXP);
Rcomplex ALTCOMPLEX_ELT (SEXP x, R_xlen_t i);
void ALTCOMPLEX_SET_ELT (SEXP x, R_xlen_t i, Rcomplex v);
Rbyte ALTRAW_ELT (SEXP x, R_xlen_t i);
void ALTRAW_SET_ELT (SEXP x, R_xlen_t i, Rbyte v);
R_xlen_t INTEGER_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, int* buf);
R_xlen_t REAL_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, double* buf);
R_xlen_t LOGICAL_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, int* buf);
R_xlen_t COMPLEX_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, Rcomplex* buf);
R_xlen_t RAW_GET_REGION (SEXP sx, R_xlen_t i, R_xlen_t n, Rbyte* buf);
int INTEGER_IS_SORTED (SEXP x);
int INTEGER_NO_NA (SEXP x);
int REAL_IS_SORTED (SEXP x);
int REAL_NO_NA (SEXP x);
int LOGICAL_IS_SORTED (SEXP x);
int LOGICAL_NO_NA (SEXP x);
int STRING_IS_SORTED (SEXP x);
int STRING_NO_NA (SEXP x);
SEXP ALTINTEGER_SUM (SEXP x, Rboolean narm);
SEXP ALTINTEGER_MIN (SEXP x, Rboolean narm);
SEXP ALTINTEGER_MAX (SEXP x, Rboolean narm);
SEXP INTEGER_MATCH (SEXP, SEXP, int, SEXP, SEXP, Rboolean);
SEXP INTEGER_IS_NA (SEXP x);
SEXP ALTREAL_SUM (SEXP x, Rboolean narm);
SEXP ALTREAL_MIN (SEXP x, Rboolean narm);
SEXP ALTREAL_MAX (SEXP x, Rboolean narm);
SEXP REAL_MATCH (SEXP, SEXP, int, SEXP, SEXP, Rboolean);
SEXP REAL_IS_NA (SEXP x);
SEXP ALTLOGICAL_SUM (SEXP x, Rboolean narm);
SEXP R_compact_intrange (R_xlen_t n1, R_xlen_t n2);
SEXP R_deferred_coerceToString (SEXP v, SEXP info);
SEXP R_virtrep_vec (SEXP, SEXP);
SEXP R_tryWrap (SEXP);
SEXP R_tryUnwrap (SEXP);
R_len_t R_BadLongVector (SEXP, const(char)*, int);
int BNDCELL_TAG (SEXP e);
void SET_BNDCELL_TAG (SEXP e, int v);
double BNDCELL_DVAL (SEXP cell);
int BNDCELL_IVAL (SEXP cell);
int BNDCELL_LVAL (SEXP cell);
void SET_BNDCELL_DVAL (SEXP cell, double v);
void SET_BNDCELL_IVAL (SEXP cell, int v);
void SET_BNDCELL_LVAL (SEXP cell, int v);
void INIT_BNDCELL (SEXP cell, int type);
void SET_BNDCELL (SEXP cell, SEXP val);
SEXP TAG (SEXP e);
SEXP CAR0 (SEXP e);
SEXP CDR (SEXP e);
SEXP CAAR (SEXP e);
SEXP CDAR (SEXP e);
SEXP CADR (SEXP e);
SEXP CDDR (SEXP e);
SEXP CDDDR (SEXP e);
SEXP CADDR (SEXP e);
SEXP CADDDR (SEXP e);
SEXP CAD4R (SEXP e);
int MISSING (SEXP x);
void SET_MISSING (SEXP x, int v);
void SET_TAG (SEXP x, SEXP y);
SEXP SETCAR (SEXP x, SEXP y);
SEXP SETCDR (SEXP x, SEXP y);
SEXP SETCADR (SEXP x, SEXP y);
SEXP SETCADDR (SEXP x, SEXP y);
SEXP SETCADDDR (SEXP x, SEXP y);
SEXP SETCAD4R (SEXP e, SEXP y);
void* EXTPTR_PTR (SEXP);
SEXP CONS_NR (SEXP a, SEXP b);
SEXP FORMALS (SEXP x);
SEXP BODY (SEXP x);
SEXP CLOENV (SEXP x);
int RDEBUG (SEXP x);
int RSTEP (SEXP x);
int RTRACE (SEXP x);
void SET_RDEBUG (SEXP x, int v);
void SET_RSTEP (SEXP x, int v);
void SET_RTRACE (SEXP x, int v);
void SET_FORMALS (SEXP x, SEXP v);
void SET_BODY (SEXP x, SEXP v);
void SET_CLOENV (SEXP x, SEXP v);
SEXP PRINTNAME (SEXP x);
SEXP SYMVALUE (SEXP x);
SEXP INTERNAL (SEXP x);
int DDVAL (SEXP x);
void SET_DDVAL (SEXP x, int v);
void SET_PRINTNAME (SEXP x, SEXP v);
void SET_SYMVALUE (SEXP x, SEXP v);
void SET_INTERNAL (SEXP x, SEXP v);
SEXP FRAME (SEXP x);
SEXP ENCLOS (SEXP x);
SEXP HASHTAB (SEXP x);
int ENVFLAGS (SEXP x);
void SET_ENVFLAGS (SEXP x, int v);
void SET_FRAME (SEXP x, SEXP v);
void SET_ENCLOS (SEXP x, SEXP v);
void SET_HASHTAB (SEXP x, SEXP v);
SEXP PRCODE (SEXP x);
SEXP PRENV (SEXP x);
SEXP PRVALUE (SEXP x);
int PRSEEN (SEXP x);
void SET_PRSEEN (SEXP x, int v);
void SET_PRENV (SEXP x, SEXP v);
void SET_PRVALUE (SEXP x, SEXP v);
void SET_PRCODE (SEXP x, SEXP v);
void SET_PRSEEN (SEXP x, int v);
int HASHASH (SEXP x);
int HASHVALUE (SEXP x);
void SET_HASHASH (SEXP x, int v);
void SET_HASHVALUE (SEXP x, int v);
alias PROTECT_INDEX = int;
extern __gshared SEXP R_GlobalEnv;
extern __gshared SEXP R_EmptyEnv;
extern __gshared SEXP R_BaseEnv;
extern __gshared SEXP R_BaseNamespace;
extern __gshared SEXP R_NamespaceRegistry;
extern __gshared SEXP R_Srcref;
extern __gshared SEXP R_NilValue;
extern __gshared SEXP R_UnboundValue;
extern __gshared SEXP R_MissingArg;
extern __gshared SEXP R_InBCInterpreter;
extern __gshared SEXP R_CurrentExpression;
extern __gshared SEXP R_RestartToken;
extern __gshared SEXP R_AsCharacterSymbol;
extern __gshared SEXP R_baseSymbol;
extern __gshared SEXP R_BaseSymbol;
extern __gshared SEXP R_BraceSymbol;
extern __gshared SEXP R_Bracket2Symbol;
extern __gshared SEXP R_BracketSymbol;
extern __gshared SEXP R_ClassSymbol;
extern __gshared SEXP R_DeviceSymbol;
extern __gshared SEXP R_DimNamesSymbol;
extern __gshared SEXP R_DimSymbol;
extern __gshared SEXP R_DollarSymbol;
extern __gshared SEXP R_DotsSymbol;
extern __gshared SEXP R_DoubleColonSymbol;
extern __gshared SEXP R_DropSymbol;
extern __gshared SEXP R_EvalSymbol;
extern __gshared SEXP R_FunctionSymbol;
extern __gshared SEXP R_LastvalueSymbol;
extern __gshared SEXP R_LevelsSymbol;
extern __gshared SEXP R_ModeSymbol;
extern __gshared SEXP R_NaRmSymbol;
extern __gshared SEXP R_NameSymbol;
extern __gshared SEXP R_NamesSymbol;
extern __gshared SEXP R_NamespaceEnvSymbol;
extern __gshared SEXP R_PackageSymbol;
extern __gshared SEXP R_PreviousSymbol;
extern __gshared SEXP R_QuoteSymbol;
extern __gshared SEXP R_RowNamesSymbol;
extern __gshared SEXP R_SeedsSymbol;
extern __gshared SEXP R_SortListSymbol;
extern __gshared SEXP R_SourceSymbol;
extern __gshared SEXP R_SpecSymbol;
extern __gshared SEXP R_TripleColonSymbol;
extern __gshared SEXP R_TspSymbol;
extern __gshared SEXP R_dot_defined;
extern __gshared SEXP R_dot_Method;
extern __gshared SEXP R_dot_packageName;
extern __gshared SEXP R_dot_target;
extern __gshared SEXP R_dot_Generic;
extern __gshared SEXP R_NaString;
extern __gshared SEXP R_BlankString;
extern __gshared SEXP R_BlankScalarString;
SEXP R_GetCurrentSrcref (int);
SEXP R_GetSrcFilename (SEXP);
SEXP Rf_asChar (SEXP);
SEXP Rf_coerceVector (SEXP, SEXPTYPE);
SEXP Rf_PairToVectorList (SEXP x);
SEXP Rf_VectorToPairList (SEXP x);
SEXP Rf_asCharacterFactor (SEXP x);
int Rf_asLogical (SEXP x);
int Rf_asLogical2 (SEXP x, int checking, SEXP call, SEXP rho);
int Rf_asInteger (SEXP x);
double Rf_asReal (SEXP x);
Rcomplex Rf_asComplex (SEXP x);
struct R_allocator;
alias R_allocator_t = R_allocator;

enum warn_type
{
    iSILENT = 0,
    iWARN = 1,
    iERROR = 2
}

char* Rf_acopy_string (const(char)*);
void Rf_addMissingVarsToNewEnv (SEXP, SEXP);
SEXP Rf_alloc3DArray (SEXPTYPE, int, int, int);
SEXP Rf_allocArray (SEXPTYPE, SEXP);
SEXP Rf_allocFormalsList2 (SEXP sym1, SEXP sym2);
SEXP Rf_allocFormalsList3 (SEXP sym1, SEXP sym2, SEXP sym3);
SEXP Rf_allocFormalsList4 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4);
SEXP Rf_allocFormalsList5 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5);
SEXP Rf_allocFormalsList6 (SEXP sym1, SEXP sym2, SEXP sym3, SEXP sym4, SEXP sym5, SEXP sym6);
SEXP Rf_allocMatrix (SEXPTYPE, int, int);
SEXP Rf_allocList (int);
SEXP Rf_allocS4Object ();
SEXP Rf_allocSExp (SEXPTYPE);
SEXP Rf_allocVector3 (SEXPTYPE, R_xlen_t, R_allocator_t*);
R_xlen_t Rf_any_duplicated (SEXP x, Rboolean from_last);
R_xlen_t Rf_any_duplicated3 (SEXP x, SEXP incomp, Rboolean from_last);
SEXP Rf_applyClosure (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_arraySubscript (
    int,
    SEXP,
    SEXP,
    SEXP function (SEXP, SEXP),
    SEXP function (SEXP, int),
    SEXP);
SEXP Rf_classgets (SEXP, SEXP);
SEXP Rf_cons (SEXP, SEXP);
SEXP Rf_fixSubset3Args (SEXP, SEXP, SEXP, SEXP*);
void Rf_copyMatrix (SEXP, SEXP, Rboolean);
void Rf_copyListMatrix (SEXP, SEXP, Rboolean);
void Rf_copyMostAttrib (SEXP, SEXP);
void Rf_copyVector (SEXP, SEXP);
int Rf_countContexts (int, int);
SEXP Rf_CreateTag (SEXP);
void Rf_defineVar (SEXP, SEXP, SEXP);
SEXP Rf_dimgets (SEXP, SEXP);
SEXP Rf_dimnamesgets (SEXP, SEXP);
SEXP Rf_DropDims (SEXP);
SEXP Rf_duplicate (SEXP);
SEXP Rf_shallow_duplicate (SEXP);
SEXP R_duplicate_attr (SEXP);
SEXP R_shallow_duplicate_attr (SEXP);
SEXP Rf_lazy_duplicate (SEXP);
SEXP Rf_duplicated (SEXP, Rboolean);
Rboolean R_envHasNoSpecialSymbols (SEXP);
SEXP Rf_eval (SEXP, SEXP);
SEXP Rf_ExtractSubset (SEXP, SEXP, SEXP);
SEXP Rf_findFun (SEXP, SEXP);
SEXP Rf_findFun3 (SEXP, SEXP, SEXP);
void Rf_findFunctionForBody (SEXP);
SEXP Rf_findVar (SEXP, SEXP);
SEXP Rf_findVarInFrame (SEXP, SEXP);
SEXP Rf_findVarInFrame3 (SEXP, SEXP, Rboolean);
void R_removeVarFromFrame (SEXP, SEXP);
SEXP Rf_getAttrib (SEXP, SEXP);
SEXP Rf_GetArrayDimnames (SEXP);
SEXP Rf_GetColNames (SEXP);
void Rf_GetMatrixDimnames (SEXP, SEXP*, SEXP*, const(char*)*, const(char*)*);
SEXP Rf_GetOption (SEXP, SEXP);
SEXP Rf_GetOption1 (SEXP);
int Rf_FixupDigits (SEXP, warn_type);
int Rf_FixupWidth (SEXP, warn_type);
int Rf_GetOptionDigits ();
int Rf_GetOptionWidth ();
SEXP Rf_GetRowNames (SEXP);
void Rf_gsetVar (SEXP, SEXP, SEXP);
SEXP Rf_install (const(char)*);
SEXP Rf_installChar (SEXP);
SEXP Rf_installNoTrChar (SEXP);
SEXP Rf_installTrChar (SEXP);
SEXP Rf_installDDVAL (int i);
SEXP Rf_installS3Signature (const(char)*, const(char)*);
Rboolean Rf_isFree (SEXP);
Rboolean Rf_isOrdered (SEXP);
Rboolean Rf_isUnmodifiedSpecSym (SEXP sym, SEXP env);
Rboolean Rf_isUnordered (SEXP);
Rboolean Rf_isUnsorted (SEXP, Rboolean);
SEXP Rf_lengthgets (SEXP, R_len_t);
SEXP Rf_xlengthgets (SEXP, R_xlen_t);
SEXP R_lsInternal (SEXP, Rboolean);
SEXP R_lsInternal3 (SEXP, Rboolean, Rboolean);
SEXP Rf_match (SEXP, SEXP, int);
SEXP Rf_matchE (SEXP, SEXP, int, SEXP);
SEXP Rf_namesgets (SEXP, SEXP);
SEXP Rf_mkChar (const(char)*);
SEXP Rf_mkCharLen (const(char)*, int);
Rboolean Rf_NonNullStringMatch (SEXP, SEXP);
int Rf_ncols (SEXP);
int Rf_nrows (SEXP);
SEXP Rf_nthcdr (SEXP, int);

enum nchar_type
{
    Bytes = 0,
    Chars = 1,
    Width = 2
}

int R_nchar (
    SEXP string,
    nchar_type type_,
    Rboolean allowNA,
    Rboolean keepNA,
    const(char)* msg_name);
Rboolean Rf_pmatch (SEXP, SEXP, Rboolean);
Rboolean Rf_psmatch (const(char)*, const(char)*, Rboolean);
SEXP R_ParseEvalString (const(char)*, SEXP);
void Rf_PrintValue (SEXP);
void Rf_printwhere ();
void Rf_readS3VarsFromFrame (SEXP, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*, SEXP*);
SEXP Rf_setAttrib (SEXP, SEXP, SEXP);
void Rf_setSVector (SEXP*, int, SEXP);
void Rf_setVar (SEXP, SEXP, SEXP);
SEXP Rf_stringSuffix (SEXP, int);
SEXPTYPE Rf_str2type (const(char)*);
Rboolean Rf_StringBlank (SEXP);
SEXP Rf_substitute (SEXP, SEXP);
SEXP Rf_topenv (SEXP, SEXP);
const(char)* Rf_translateChar (SEXP);
const(char)* Rf_translateChar0 (SEXP);
const(char)* Rf_translateCharUTF8 (SEXP);
const(char)* Rf_type2char (SEXPTYPE);
SEXP Rf_type2rstr (SEXPTYPE);
SEXP Rf_type2str (SEXPTYPE);
SEXP Rf_type2str_nowarn (SEXPTYPE);
void Rf_unprotect_ptr (SEXP);
void R_signal_protect_error ();
void R_signal_unprotect_error ();
void R_signal_reprotect_error (PROTECT_INDEX i);
SEXP R_tryEval (SEXP, SEXP, int*);
SEXP R_tryEvalSilent (SEXP, SEXP, int*);
SEXP R_GetCurrentEnv ();
const(char)* R_curErrorBuf ();
Rboolean Rf_isS4 (SEXP);
SEXP Rf_asS4 (SEXP, Rboolean, int);
SEXP Rf_S3Class (SEXP);
int Rf_isBasicClass (const(char)*);
Rboolean R_cycle_detected (SEXP s, SEXP child);

enum cetype_t
{
    CE_NATIVE = 0,
    CE_UTF8 = 1,
    CE_LATIN1 = 2,
    CE_BYTES = 3,
    CE_SYMBOL = 5,
    CE_ANY = 99
}

cetype_t Rf_getCharCE (SEXP);
SEXP Rf_mkCharCE (const(char)*, cetype_t);
SEXP Rf_mkCharLenCE (const(char)*, int, cetype_t);
const(char)* Rf_reEnc (const(char)* x, cetype_t ce_in, cetype_t ce_out, int subst);
SEXP R_forceAndCall (SEXP e, int n, SEXP rho);
SEXP R_MakeExternalPtr (void* p, SEXP tag, SEXP prot);
void* R_ExternalPtrAddr (SEXP s);
SEXP R_ExternalPtrTag (SEXP s);
SEXP R_ExternalPtrProtected (SEXP s);
void R_ClearExternalPtr (SEXP s);
void R_SetExternalPtrAddr (SEXP s, void* p);
void R_SetExternalPtrTag (SEXP s, SEXP tag);
void R_SetExternalPtrProtected (SEXP s, SEXP p);
SEXP R_MakeExternalPtrFn (DL_FUNC p, SEXP tag, SEXP prot);
DL_FUNC R_ExternalPtrAddrFn (SEXP s);
alias R_CFinalizer_t = void function (SEXP);
void R_RegisterFinalizer (SEXP s, SEXP fun);
void R_RegisterCFinalizer (SEXP s, R_CFinalizer_t fun);
void R_RegisterFinalizerEx (SEXP s, SEXP fun, Rboolean onexit);
void R_RegisterCFinalizerEx (SEXP s, R_CFinalizer_t fun, Rboolean onexit);
void R_RunPendingFinalizers ();
SEXP R_MakeWeakRef (SEXP key, SEXP val, SEXP fin, Rboolean onexit);
SEXP R_MakeWeakRefC (SEXP key, SEXP val, R_CFinalizer_t fin, Rboolean onexit);
SEXP R_WeakRefKey (SEXP w);
SEXP R_WeakRefValue (SEXP w);
void R_RunWeakRefFinalizer (SEXP w);
SEXP R_PromiseExpr (SEXP);
SEXP R_ClosureExpr (SEXP);
SEXP R_BytecodeExpr (SEXP e);
void R_initialize_bcode ();
SEXP R_bcEncode (SEXP);
SEXP R_bcDecode (SEXP);
void R_registerBC (SEXP, SEXP);
Rboolean R_checkConstants (Rboolean);
Rboolean R_BCVersionOK (SEXP);
void R_init_altrep ();
void R_reinit_altrep_classes (DllInfo*);
Rboolean R_ToplevelExec (void function (void*) fun, void* data);
SEXP R_ExecWithCleanup (
    SEXP function (void*) fun,
    void* data,
    void function (void*) cleanfun,
    void* cleandata);
SEXP R_tryCatch (
    SEXP function (void*),
    void*,
    SEXP,
    SEXP function (SEXP, void*),
    void*,
    void function (void*),
    void*);
SEXP R_tryCatchError (
    SEXP function (void*),
    void*,
    SEXP function (SEXP, void*),
    void*);
SEXP R_withCallingErrorHandler (
    SEXP function (void*),
    void*,
    SEXP function (SEXP, void*),
    void*);
SEXP R_MakeUnwindCont ();
void R_ContinueUnwind (SEXP cont);
SEXP R_UnwindProtect (
    SEXP function (void* data) fun,
    void* data,
    void function (void* data, Rboolean jump) cleanfun,
    void* cleandata,
    SEXP cont);
SEXP R_NewEnv (SEXP, int, int);
void R_RestoreHashCount (SEXP rho);
Rboolean R_IsPackageEnv (SEXP rho);
SEXP R_PackageEnvName (SEXP rho);
SEXP R_FindPackageEnv (SEXP info);
Rboolean R_IsNamespaceEnv (SEXP rho);
SEXP R_NamespaceEnvSpec (SEXP rho);
SEXP R_FindNamespace (SEXP info);
void R_LockEnvironment (SEXP env, Rboolean bindings);
Rboolean R_EnvironmentIsLocked (SEXP env);
void R_LockBinding (SEXP sym, SEXP env);
void R_unLockBinding (SEXP sym, SEXP env);
void R_MakeActiveBinding (SEXP sym, SEXP fun, SEXP env);
Rboolean R_BindingIsLocked (SEXP sym, SEXP env);
Rboolean R_BindingIsActive (SEXP sym, SEXP env);
SEXP R_ActiveBindingFunction (SEXP sym, SEXP env);
Rboolean R_HasFancyBindings (SEXP rho);
void Rf_errorcall (SEXP, const(char)*, ...);
void Rf_warningcall (SEXP, const(char)*, ...);
void Rf_warningcall_immediate (SEXP, const(char)*, ...);
void R_XDREncodeDouble (double d, void* buf);
double R_XDRDecodeDouble (void* buf);
void R_XDREncodeInteger (int i, void* buf);
int R_XDRDecodeInteger (void* buf);
alias R_pstream_data_t = void*;

enum R_pstream_format_t
{
    R_pstream_any_format = 0,
    R_pstream_ascii_format = 1,
    R_pstream_binary_format = 2,
    R_pstream_xdr_format = 3,
    R_pstream_asciihex_format = 4
}

alias R_outpstream_t = R_outpstream_st*;

struct R_outpstream_st
{
    R_pstream_data_t data;
    R_pstream_format_t type;
    int version_;
    void function (R_outpstream_t, int) OutChar;
    void function (R_outpstream_t, void*, int) OutBytes;
    SEXP function (SEXP, SEXP) OutPersistHookFunc;
    SEXP OutPersistHookData;
}

alias R_inpstream_t = R_inpstream_st*;

struct R_inpstream_st
{
    R_pstream_data_t data;
    R_pstream_format_t type;
    int function (R_inpstream_t) InChar;
    void function (R_inpstream_t, void*, int) InBytes;
    SEXP function (SEXP, SEXP) InPersistHookFunc;
    SEXP InPersistHookData;
    char[64] native_encoding;
    void* nat2nat_obj;
    void* nat2utf8_obj;
}

void R_InitInPStream (
    R_inpstream_t stream,
    R_pstream_data_t data,
    R_pstream_format_t type,
    int function (R_inpstream_t) inchar,
    void function (R_inpstream_t, void*, int) inbytes,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitOutPStream (
    R_outpstream_t stream,
    R_pstream_data_t data,
    R_pstream_format_t type,
    int version_,
    void function (R_outpstream_t, int) outchar,
    void function (R_outpstream_t, void*, int) outbytes,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitFileInPStream (
    R_inpstream_t stream,
    FILE* fp,
    R_pstream_format_t type,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_InitFileOutPStream (
    R_outpstream_t stream,
    FILE* fp,
    R_pstream_format_t type,
    int version_,
    SEXP function (SEXP, SEXP) phook,
    SEXP pdata);
void R_Serialize (SEXP s, R_outpstream_t ops);
SEXP R_Unserialize (R_inpstream_t ips);
SEXP R_SerializeInfo (R_inpstream_t ips);
SEXP R_do_slot (SEXP obj, SEXP name);
SEXP R_do_slot_assign (SEXP obj, SEXP name, SEXP value);
int R_has_slot (SEXP obj, SEXP name);
SEXP R_S4_extends (SEXP klass, SEXP useTable);
SEXP R_do_MAKE_CLASS (const(char)* what);
SEXP R_getClassDef (const(char)* what);
SEXP R_getClassDef_R (SEXP what);
Rboolean R_has_methods_attached ();
Rboolean R_isVirtualClass (SEXP class_def, SEXP env);
Rboolean R_extends (SEXP class1, SEXP class2, SEXP env);
SEXP R_do_new_object (SEXP class_def);
int R_check_class_and_super (SEXP x, const(char*)* valid, SEXP rho);
int R_check_class_etc (SEXP x, const(char*)* valid);
void R_PreserveObject (SEXP);
void R_ReleaseObject (SEXP);
SEXP R_NewPreciousMSet (int);
void R_PreserveInMSet (SEXP x, SEXP mset);
void R_ReleaseFromMSet (SEXP x, SEXP mset);
void R_ReleaseMSet (SEXP mset, int keepSize);
void R_dot_Last ();
void R_RunExitFinalizers ();
int R_system (const(char)*);
Rboolean R_compute_identical (SEXP, SEXP, int);
SEXP R_body_no_src (SEXP x);
void R_orderVector (int* indx, int n, SEXP arglist, Rboolean nalast, Rboolean decreasing);
void R_orderVector1 (int* indx, int n, SEXP x, Rboolean nalast, Rboolean decreasing);
SEXP Rf_allocVector (SEXPTYPE, R_xlen_t);
Rboolean Rf_conformable (SEXP, SEXP);
SEXP Rf_elt (SEXP, int);
Rboolean Rf_inherits (SEXP, const(char)*);
Rboolean Rf_isArray (SEXP);
Rboolean Rf_isFactor (SEXP);
Rboolean Rf_isFrame (SEXP);
Rboolean Rf_isFunction (SEXP);
Rboolean Rf_isInteger (SEXP);
Rboolean Rf_isLanguage (SEXP);
Rboolean Rf_isList (SEXP);
Rboolean Rf_isMatrix (SEXP);
Rboolean Rf_isNewList (SEXP);
Rboolean Rf_isNumber (SEXP);
Rboolean Rf_isNumeric (SEXP);
Rboolean Rf_isPairList (SEXP);
Rboolean Rf_isPrimitive (SEXP);
Rboolean Rf_isTs (SEXP);
Rboolean Rf_isUserBinop (SEXP);
Rboolean Rf_isValidString (SEXP);
Rboolean Rf_isValidStringF (SEXP);
Rboolean Rf_isVector (SEXP);
Rboolean Rf_isVectorAtomic (SEXP);
Rboolean Rf_isVectorList (SEXP);
Rboolean Rf_isVectorizable (SEXP);
SEXP Rf_lang1 (SEXP);
SEXP Rf_lang2 (SEXP, SEXP);
SEXP Rf_lang3 (SEXP, SEXP, SEXP);
SEXP Rf_lang4 (SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lang5 (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lang6 (SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_lastElt (SEXP);
SEXP Rf_lcons (SEXP, SEXP);
R_len_t Rf_length (SEXP);
SEXP Rf_list1 (SEXP);
SEXP Rf_list2 (SEXP, SEXP);
SEXP Rf_list3 (SEXP, SEXP, SEXP);
SEXP Rf_list4 (SEXP, SEXP, SEXP, SEXP);
SEXP Rf_list5 (SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_list6 (SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP Rf_listAppend (SEXP, SEXP);
SEXP Rf_mkNamed (SEXPTYPE, const(char*)*);
SEXP Rf_mkString (const(char)*);
int Rf_nlevels (SEXP);
int Rf_stringPositionTr (SEXP, const(char)*);
SEXP Rf_ScalarComplex (Rcomplex);
SEXP Rf_ScalarInteger (int);
SEXP Rf_ScalarLogical (int);
SEXP Rf_ScalarRaw (Rbyte);
SEXP Rf_ScalarReal (double);
SEXP Rf_ScalarString (SEXP);
R_xlen_t Rf_xlength (SEXP);
R_xlen_t XLENGTH (SEXP x);
R_xlen_t XTRUELENGTH (SEXP x);
int LENGTH_EX (SEXP x, const(char)* file, int line);
R_xlen_t XLENGTH_EX (SEXP x);
SEXP Rf_protect (SEXP);
void Rf_unprotect (int);
void R_ProtectWithIndex (SEXP, PROTECT_INDEX*);
void R_Reprotect (SEXP, PROTECT_INDEX);
SEXP R_FixupRHS (SEXP x, SEXP y);
SEXP CAR (SEXP e);
void* DATAPTR (SEXP x);
const(void)* DATAPTR_RO (SEXP x);
const(void)* DATAPTR_OR_NULL (SEXP x);
const(int)* LOGICAL_OR_NULL (SEXP x);
const(int)* INTEGER_OR_NULL (SEXP x);
const(double)* REAL_OR_NULL (SEXP x);
const(Rcomplex)* COMPLEX_OR_NULL (SEXP x);
const(Rbyte)* RAW_OR_NULL (SEXP x);
void* STDVEC_DATAPTR (SEXP x);
int INTEGER_ELT (SEXP x, R_xlen_t i);
double REAL_ELT (SEXP x, R_xlen_t i);
int LOGICAL_ELT (SEXP x, R_xlen_t i);
Rcomplex COMPLEX_ELT (SEXP x, R_xlen_t i);
Rbyte RAW_ELT (SEXP x, R_xlen_t i);
SEXP STRING_ELT (SEXP x, R_xlen_t i);
double SCALAR_DVAL (SEXP x);
int SCALAR_LVAL (SEXP x);
int SCALAR_IVAL (SEXP x);
void SET_SCALAR_DVAL (SEXP x, double v);
void SET_SCALAR_LVAL (SEXP x, int v);
void SET_SCALAR_IVAL (SEXP x, int v);
void SET_SCALAR_CVAL (SEXP x, Rcomplex v);
void SET_SCALAR_BVAL (SEXP x, Rbyte v);
SEXP R_altrep_data1 (SEXP x);
SEXP R_altrep_data2 (SEXP x);
void R_set_altrep_data1 (SEXP x, SEXP v);
void R_set_altrep_data2 (SEXP x, SEXP v);
SEXP ALTREP_CLASS (SEXP x);
int* LOGICAL0 (SEXP x);
int* INTEGER0 (SEXP x);
double* REAL0 (SEXP x);
Rcomplex* COMPLEX0 (SEXP x);
Rbyte* RAW0 (SEXP x);
void SET_LOGICAL_ELT (SEXP x, R_xlen_t i, int v);
void SET_INTEGER_ELT (SEXP x, R_xlen_t i, int v);
void SET_REAL_ELT (SEXP x, R_xlen_t i, double v);
void SET_COMPLEX_ELT (SEXP x, R_xlen_t i, Rcomplex v);
void SET_RAW_ELT (SEXP x, R_xlen_t i, Rbyte v);
void R_BadValueInRCode (
    SEXP value,
    SEXP call,
    SEXP rho,
    const(char)* rawmsg,
    const(char)* errmsg,
    const(char)* warnmsg,
    const(char)* varname,
    Rboolean warnByDefault);
double R_pow (double x, double y);
double R_pow_di (double, int);
double norm_rand ();
double unif_rand ();
double R_unif_index (double);
double exp_rand ();
void set_seed (uint, uint);
void get_seed (uint*, uint*);
double dnorm4 (double, double, double, int);
double pnorm5 (double, double, double, int, int);
double qnorm5 (double, double, double, int, int);
double rnorm (double, double);
void pnorm_both (double, double*, double*, int, int);
double dunif (double, double, double, int);
double punif (double, double, double, int, int);
double qunif (double, double, double, int, int);
double runif (double, double);
double dgamma (double, double, double, int);
double pgamma (double, double, double, int, int);
double qgamma (double, double, double, int, int);
double rgamma (double, double);
double log1pmx (double);
double log1pexp (double);
double log1mexp (double);
double lgamma1p (double);
double logspace_add (double, double);
double logspace_sub (double, double);
double logspace_sum (const(double)*, int);
double dbeta (double, double, double, int);
double pbeta (double, double, double, int, int);
double qbeta (double, double, double, int, int);
double rbeta (double, double);
double dlnorm (double, double, double, int);
double plnorm (double, double, double, int, int);
double qlnorm (double, double, double, int, int);
double rlnorm (double, double);
double dchisq (double, double, int);
double pchisq (double, double, int, int);
double qchisq (double, double, int, int);
double rchisq (double);
double dnchisq (double, double, double, int);
double pnchisq (double, double, double, int, int);
double qnchisq (double, double, double, int, int);
double rnchisq (double, double);
double df (double, double, double, int);
double pf (double, double, double, int, int);
double qf (double, double, double, int, int);
double rf (double, double);
double dt (double, double, int);
double pt (double, double, int, int);
double qt (double, double, int, int);
double rt (double);
double dbinom_raw (double x, double n, double p, double q, int give_log);
double dbinom (double, double, double, int);
double pbinom (double, double, double, int, int);
double qbinom (double, double, double, int, int);
double rbinom (double, double);
void rmultinom (int, double*, int, int*);
double dcauchy (double, double, double, int);
double pcauchy (double, double, double, int, int);
double qcauchy (double, double, double, int, int);
double rcauchy (double, double);
double dexp (double, double, int);
double pexp (double, double, int, int);
double qexp (double, double, int, int);
double rexp (double);
double dgeom (double, double, int);
double pgeom (double, double, int, int);
double qgeom (double, double, int, int);
double rgeom (double);
double dhyper (double, double, double, double, int);
double phyper (double, double, double, double, int, int);
double qhyper (double, double, double, double, int, int);
double rhyper (double, double, double);
double dnbinom (double, double, double, int);
double pnbinom (double, double, double, int, int);
double qnbinom (double, double, double, int, int);
double rnbinom (double, double);
double dnbinom_mu (double, double, double, int);
double pnbinom_mu (double, double, double, int, int);
double qnbinom_mu (double, double, double, int, int);
double rnbinom_mu (double, double);
double dpois_raw (double, double, int);
double dpois (double, double, int);
double ppois (double, double, int, int);
double qpois (double, double, int, int);
double rpois (double);
double dweibull (double, double, double, int);
double pweibull (double, double, double, int, int);
double qweibull (double, double, double, int, int);
double rweibull (double, double);
double dlogis (double, double, double, int);
double plogis (double, double, double, int, int);
double qlogis (double, double, double, int, int);
double rlogis (double, double);
double dnbeta (double, double, double, double, int);
double pnbeta (double, double, double, double, int, int);
double qnbeta (double, double, double, double, int, int);
double rnbeta (double, double, double);
double dnf (double, double, double, double, int);
double pnf (double, double, double, double, int, int);
double qnf (double, double, double, double, int, int);
double dnt (double, double, double, int);
double pnt (double, double, double, int, int);
double qnt (double, double, double, int, int);
double ptukey (double, double, double, double, int, int);
double qtukey (double, double, double, double, int, int);
double dwilcox (double, double, double, int);
double pwilcox (double, double, double, int, int);
double qwilcox (double, double, double, int, int);
double rwilcox (double, double);
double dsignrank (double, double, int);
double psignrank (double, double, int, int);
double qsignrank (double, double, int, int);
double rsignrank (double);
double gammafn (double);
double lgammafn (double);
double lgammafn_sign (double, int*);
void dpsifn (double, int, int, int, double*, int*, int*);
double psigamma (double, double);
double digamma (double);
double trigamma (double);
double tetragamma (double);
double pentagamma (double);
double beta (double, double);
double lbeta (double, double);
double choose (double, double);
double lchoose (double, double);
double bessel_i (double, double, double);
double bessel_j (double, double);
double bessel_k (double, double, double);
double bessel_y (double, double);
double bessel_i_ex (double, double, double, double*);
double bessel_j_ex (double, double, double*);
double bessel_k_ex (double, double, double, double*);
double bessel_y_ex (double, double, double*);
int imax2 (int, int);
int imin2 (int, int);
double fmax2 (double, double);
double fmin2 (double, double);
double sign (double);
double fprec (double, double);
double fround (double, double);
double fsign (double, double);
double ftrunc (double);
double log1pmx (double);
double lgamma1p (double);
double logspace_add (double logx, double logy);
double logspace_sub (double logx, double logy);
int R_finite (double);
extern __gshared int N01_kind;
