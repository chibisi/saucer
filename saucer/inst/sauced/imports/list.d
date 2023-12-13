/*
    TODO:
    1. Fix segfault in opIndexAssign for appending to the list
    2. Discard associative array _names_ and use struct ... {string name, index long}
       and rewrite with this. Or re-sort after changing with this:
            sort!"a[0]<b[0]"(zip(basedOnThis, alsoSortThis));
*/

/+
    Test VECTOR_PTR() for Accessor function
+/

import std.traits: Unqual;

pragma(inline, true) auto boundsCheck(I, L)(I i, L len)
if(isIntegral!I && isIntegral!L)
{
    assert(i < len, "The index i " ~ to!(string)(i) ~ 
        " is not less than the given length " ~
        to!(string)(len));
}



//List element
struct NamedElement(T)
if(isConvertibleToSEXP!(T))
{
    string name; //maybe a type that is convertible to a string
    T data;
    this(N)(N name, T data) @trusted
    if(isConvertibleTo!(N, string, To))
    {
        this.name = To!string(name);
        this.data = data;
    }
}


auto namedElement(N, T)(N n, T data)
{
    return NamedElement!(T)(n, data);
}


enum isNamedElement() = false;
template isNamedElement(T)
{
    alias R = Unqual!(T);
    static if(is(R == NamedElement!(E), E))
    {
        enum isNamedElement = true;
    }else{
        enum isNamedElement = false;
    }
}

mixin(CreateMultipleCase!("isNamedElement"));
enum isNamedElement(alias Arg) = isNamedElement!(typeof(Arg));


struct List
{
    import std.stdio: writeln;
    import std.algorithm: sort;
    SEXP sexp;
    int[string] _names_;
    alias implicitCast this;
    bool needUnprotect = false;
    this(I...)(I n) @trusted
    if((I.length == 1) && isIntegral!(I))
    {
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        needUnprotect = true;
    }
    this(T...)(T value) @trusted
    if((T.length == 1) && isSEXPOrRType!(T) && !is(T == List) /*No copy*/)
    {
        static if(isSEXP!(T))
        {
            if(TYPEOF(value) == VECSXP)
            {
                this.sexp = protect(value);
                needUnprotect = true;
                SEXP lNames = Rf_getAttrib(this.sexp, R_NamesSymbol);
                if(LENGTH(lNames) > 0)
                {
                    string[] keys = getSlice!(STRSXP)(lNames, 0, this.length);
                    foreach(i; 0..length)
                    {
                        this._names_[keys[i]] = i;
                    }
                }
                return;
            }else{
                this.sexp = protect(allocVector(VECSXP, cast(int)1));
                needUnprotect = true;
                this[0] = value;
                return;
            }
        }else{
            SEXP element = To!(SEXP)(value);
            this.sexp = protect(allocVector(VECSXP, cast(int)1));
            needUnprotect = true;
            this[0] = element;
            return;
        }
    }
    //disable copy constructor
    @disable this(this);
    this(Args...)(Args args) @trusted
    if((Args.length > 1) && isConvertibleToSEXP!(Args))
    {
        SEXP element;
        enum n = Args.length;
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        needUnprotect = true;
        static foreach(i; 0..n)
        {
            element = To!(SEXP)(args[i]);
            this[i] = element;
        }
    }
    this(Args...)(Args args) @trusted
    if(isNamedElement!(Args))
    {
        import std.algorithm: canFind;
        import std.exception: enforce;
        int n = Args.length;
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        needUnprotect = true;
        SEXP element;
        string name;
        static foreach(i, arg; args)
        {
            name = To!string(arg.name);
            enforce(!names.canFind(name), "name " ~ 
                name ~ " is not unique in list names.");
            this._names_[name] = i;
            element = protect(To!(SEXP)(arg.data));
            this[i] = element;
            unprotect(1);
        }
        SEXP lNames = protect(To!(SEXP)(this._names_.keys));
        Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
        unprotect(1);
    }
    ~this() @trusted
    {
        if(needUnprotect)
        {
            unprotect_ptr(sexp);
            needUnprotect = false;
        }
    }

    pragma(inline, true)
    SEXP opCast(T)() @trusted
    if(is(T == SEXP))
    {
        return this.sexp;
    }
    pragma(inline, true)
    SEXP implicitCast() @system
    {
        return this.sexp;
    }
    SEXP opIndex(I)(I i) @trusted
    if(isIntegral!(I))
    {
        
        {
            try
            {
                boundsCheck(i, this.length);
            }catch (Exception e)
            {
                writeln(e);
                return R_NilValue;
            }
        }

        return VECTOR_ELT(this.sexp, cast(int)i);
    }
    auto length() @trusted
    {
        return LENGTH(this.sexp);
    }
    /*
        Gets the names
    */
    @property string[] names() @trusted
    {
        return _names_.keys;
    }
    /*
        Set names
    */
    @property auto names(A)(A lNames) @trusted
    if(is(A == SEXP) || is(A == string[]))
    {
        static if(is(A == SEXP))
        {
            try
            {
                auto stringArray = To!string(lNames);
                enforce((LENGTH(lNames) == this.length) &&
                    (Rf_isString(lNames)) && isUnique(stringArray),
                    "Length of names submitted is not equal to list length");
            }catch (Exception e)
            {
                writeln(e);
                return;
            }

            string[] keys = getSlice!(STRSXP)(this.sexp, 0, this.length);
            foreach(i; 0..length)
            {
                this._names_[keys[i]] = i;
            }
            Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
        }else static if(is(A == string[]))
        {
            try
            {
                enforce(isUnique(lNames) && (lNames.length == this.length),
                    "Length of names submitted is not equal to list length");
            }catch (Exception e)
            {
                writeln(e);
                return;
            }
            
            foreach(i; 0..length)
            {
                this._names_[lNames[i]] = i;
            }
            SEXP _lNames_ = To!(SEXP)(lNames);
            Rf_setAttrib(this.sexp, R_NamesSymbol, _lNames_);
        }
    }
    SEXP opIndex(string _name_) @trusted
    {
        try
        {
            enforce(isin(_name_, this._names_.keys),
                "Index name is not in the list names");
        }catch (Exception e)
        {
            writeln(e);
            return R_NilValue;
        }
        
        auto i = this._names_[_name_];
        SEXP result = VECTOR_ELT(this.sexp, cast(int)i);
        return result;
    }
    auto opIndexAssign(T, I)(auto ref T value, I i) @trusted
    if(isIntegral!(I) && isConvertibleTo!(T, SEXP, To))
    {
        try
        {
            boundsCheck(i, this.length);
        }catch(Exception e)
        {
            writeln(e);
            return;
        }
        SEXP _value_ = To!(SEXP)(value);
        SET_VECTOR_ELT(this.sexp, cast(int)i, _value_);
    }
    auto opIndexAssign(T)(auto ref T value, string _name_) @trusted
    {
        if(isin(_name_, this._names_.keys))
        {
            auto i = this._names_[_name_];
            opIndexAssign(value, i);
            return;
        }

        if(this.length == this._names_.length)
        {
            auto newLength = cast(int)(this.length) + 1;
            writeln("New length: ", newLength);
            SETLENGTH(this.sexp, newLength); //segfaults
            //SET_TRUELENGTH(this.sexp, newLength);
            int i = cast(int)(this.length) - 1;
            writeln("Assignment point (i): ", i);
            //this._names_[_name_] = i;
            //auto lNames = To!SEXP(this._names_.keys);
            //Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
            //opIndexAssign(value, i);
            return;
        }else{
            string msg = "List was not initialized with names or " ~ 
                    "length of names is not equal to number of items";
            enforce(0, msg);
        }
    }
}


