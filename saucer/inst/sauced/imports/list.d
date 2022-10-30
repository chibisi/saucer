/+
    Test VECTOR_PTR() for Accessor function
+/

struct List
{
    SEXP sexp;
    alias implicitCast this;

    this(I)(I n)
    if(isIntegral!(I))
    {
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
    }
    this(SEXP sexp)
    {
        assert(TYPEOF(sexp) == VECSXP, "Argument is not a list.");
        this.sexp = protect(sexp);
    }
    ~this()
    {
        unprotect_ptr(sexp);
    }
    pragma(inline, true)
    SEXP opCast(T: SEXP)()
    {
        return this.sexp;
    }
    pragma(inline, true)
    SEXP implicitCast()
    {
        return cast(SEXP)this.sexp;
    }
    SEXP opIndex(I)(I i)
    if(isIntegral!(I))
    {
        return VECTOR_ELT(this.sexp, cast(int)i);
    }
    auto opIndexAssign(I)(SEXP value, I i)
    if(isIntegral!(I))
    {
        SET_VECTOR_ELT(this.sexp, cast(int)i, value);
    }
    auto length()
    {
        return LENGTH(this.sexp);
    }
}

