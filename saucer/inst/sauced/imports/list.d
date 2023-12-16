import std.traits: Unqual;
import std.exception: enforce;

pragma(inline, true) auto boundsCheck(I, L)(I i, L len)
if(isIntegral!I && isIntegral!L)
{
    assert(i < len, "The index i " ~ to!(string)(i) ~ 
        " is not less than the given length " ~
        to!(string)(len));
    return;
}



//List element
struct NamedElement(N, T)
if(isConvertibleTo!(N, string, To) && isConvertibleToSEXP!(T))
{
    string name; //maybe a type that is convertible to a string
    T data;
    this(N name, T data) @trusted
    {
        this.name = To!string(name);
        this.data = data;
    }
}


auto namedElement(N, T)(N name, T data)
{
    return NamedElement!(N, T)(name, data);
}


enum isNamedElement() = false;
template isNamedElement(T)
{
    alias R = Unqual!(T);
    static if(is(R == NamedElement!(N, M), N, M))
    {
        enum isNamedElement = true;
    }else{
        enum isNamedElement = false;
    }
}

mixin(CreateMultipleCase!("isNamedElement"));
enum isNamedElement(alias Arg) = isNamedElement!(typeof(Arg));


struct NamedIndex
{
    string[] data;
    this(string[] data...)
    {
        enforce(isUnique(data), "string array submitted into NamedIndex must be unique");
        this.data = data;
    }
    this(SEXP sexp)
    {
        sexp = protect(sexp);
        scope(exit)unprotect_ptr(sexp);
        auto rtype = TYPEOF(sexp);
        enforce(rtype == STRSXP, "Wrong sexp data " ~ to!(string)(rtype) ~ "type for names.");
        auto data = To!(string[])(sexp);
        enforce(isUnique(data), "string array submitted into NamedIndex must be unique");
        this.data = data;
    }
    auto length()
    {
        return data.length;
    }
    bool isin(string index)
    {
        foreach(i; 0..this.length)
        {
            if(data[i] == index)
            {
                return true;
            }
        }
        return false;
    }
    auto names()
    {
        return this.data;
    }
    auto asSEXP()
    {
        return To!(SEXP)(this.data);
    }
    auto opIndex(T)(T index)
    if(isIntegral!(T) || is(T == string))
    {
        static if(isIntegral!(T))
        {
            return this.data[index];
        }else{
            foreach(i; 0..this.length)
            {
                if(this.data[i] == index)
                {
                    return i;
                }
            }
        }
        assert(0, "Item " ~ to!string(index) ~ " not found!");
    }
    auto opDollar()
    {
        return this.length;
    }
    auto opIndexAssign(T)(auto ref string value, T index)
    if(isIntegral!(T))
    {
        enforce(!this.isin(value), "Can not assign string already in index");
        this.data[index] = value;
        return;
    }
    auto opBinary(string op, R)(auto ref R rhs)
    if((op == "~") && (is(R == string) || is(R == string[]) || is(R == typeof(this))))
    {
        static if(is(R == string))
        {
            enforce(!this.isin(rhs), "Attempting to append item (" ~ rhs ~ ") already in the index.");
            return NamedIndex(this.data ~ rhs);
        }else static if(is(R == string[])){
            auto newIndex = this(this.data.dup);
            nNewElements = newIndex.length;
            foreach(i; 0..nNewElements)
            {
                element = newIndex.data[i];
                enforce(!newIndex.isin(element), "Can not assign string (" ~ element ~ ") already in index");
                newIndex.data ~= element;
            }
            return newIndex;
        }else static if(is(R == typeof(this)))
        {
            return opBinary!"~"(rhs.data);
        }
    }
    auto opOpAssign(string op, R)(R rhs)
    if((op == "~") && (is(R == string) || is(R == string[]) || is(R == typeof(this))))
    {
        this = this ~ rhs;
        return;
    }
    auto opSlice(I)(I start, I end)
    if(isIntegral!(I))
    {
        return NamedIndex(this.data[start..end]);
    }
}




struct List
{
    SEXP sexp;
    NamedIndex nameIndex;
    bool needUnprotect = false;
    this(I)(I n) @trusted
    if(isIntegral!(I))
    {
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        this.needUnprotect = true;
    }
    this(T)(T value) @trusted
    if(!isIntegral!(T) && isConvertibleTo!(T, SEXP, To) && !is(T == List))
    {
        static if(isSEXP!(T))
        {
            if(TYPEOF(value) == VECSXP)
            {
                this.sexp = protect(value);
                this.needUnprotect = true;
                auto lNames = protect(Rf_getAttrib(this.sexp, R_NamesSymbol));
                scope(exit) unprotect_ptr(lNames);
                if((lNames.length > 0) && (lNames.length == this.sexp.length))
                {
                    this.nameIndex = NamedIndex(lNames);
                }
                return;
            }else{
                this.sexp = protect(allocVector(VECSXP, 1));
                this.needUnprotect = true;
                this[0] = value;
                return;
            }
        }else{
            auto element = To!(SEXP)(value);
            this.sexp = protect(allocVector(VECSXP, 1));
            this.needUnprotect = true;
            this[0] = element;
            return;
        }
    }
    /* Copy constructor */
    this(T)(auto ref T original) @trusted
    if(is(T == List))
    {
        this.sexp = protect(copyVector(original.sexp));
        this.needUnprotect = true;
        auto lNames = protect(Rf_getAttrib(original.sexp, R_NamesSymbol));
        scope(exit) unprotect_ptr(lNames);
        if(LENGTH(lNames) > 0)
        {
            Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
            this.nameIndex = NamedIndex(lNames);
        }
    }
    this(Args...)(Args args) @trusted
    if((Args.length > 1) && isConvertibleToSEXP!(Args))
    {
        SEXP element;
        enum n = Args.length;
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        this.needUnprotect = true;
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
        auto n = Args.length;
        this.sexp = protect(allocVector(VECSXP, cast(int)n));
        this.needUnprotect = true;
        SEXP element;
        string name;
        static foreach(i, arg; args)
        {
            name = arg.name;
            this.nameIndex ~= name;
            element = protect(To!(SEXP)(arg.data));
            this[i] = element;
            unprotect_ptr(element);
        }
        auto lNames = protect(this.nameIndex.asSEXP);
        scope(exit) unprotect_ptr(lNames);
        Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
    }
    ~this() @trusted
    {
        if(this.needUnprotect)
        {
            unprotect_ptr(sexp);
            this.needUnprotect = false;
        }
    }
    pragma(inline, true)
    SEXP opCast(T)() @trusted
    if(is(T == SEXP))
    {
        return this.sexp;
    }
    auto length() @trusted
    {
        return LENGTH(this.sexp);
    }
    auto length(I)(I newLength) @trusted
    if(isIntegral!I)
    {
        auto currLength = this.length;
        if(newLength <= currLength)
        {
            SETLENGTH(this.sexp, cast(int)newLength);
            this.nameIndex = this.nameIndex[0..newLength];
            return newLength;
        }else{
            /*
                SETLENGTH can not be used to increase 
                list (VECSXP) length because it segfaults.
                Instead, a new list is created and the items from the old list are trasfered across
            */
            auto newList = protect(allocVector(VECSXP, cast(int)newLength));
            // ... move items from old list to new list
            foreach(int i; 0..currLength)
            {
                auto element = VECTOR_ELT(this.sexp, cast(int)i);
                SET_VECTOR_ELT(newList, i, element);
            }
            // ... move the names from old list to new list
            auto lNames = protect(Rf_getAttrib(this.sexp, R_NamesSymbol));
            scope(exit) unprotect_ptr(lNames);
            if(LENGTH(lNames) > 0)
            {
                Rf_setAttrib(newList, R_NamesSymbol, lNames);
            }
            // reassign list
            auto oldList = this.sexp;
            this.sexp = newList;
            //unprotects from constructor
            unprotect_ptr(oldList);
        }
        return newLength;
    }
    auto opDollar()
    {
        return this.length;
    }
    SEXP opIndex(I)(I i) @trusted
    if(isIntegral!(I))
    {
        
        boundsCheck(i, this.length);
        return VECTOR_ELT(this.sexp, cast(int)i);
    }
    auto opIndex(string name) @trusted
    {
        auto i = this.nameIndex[name];
        boundsCheck(i, this.length);
        auto result = VECTOR_ELT(this.sexp, cast(int)i);
        return result;
    }
    /*
        Gets the names
    */
    @property string[] names() @trusted
    {
        return this.nameIndex.names;
    }
    /*
        Set names
    */
    @property auto names(A)(A lNames) @trusted
    if(is(A == SEXP) || is(A == string[]))
    {
        static if(is(A == SEXP))
        {
            auto nNames = LENGTH(lNames);
            enforce(nNames == this.length, "Length of submitted names " ~ 
                to!string(nNames) ~ " is not equal to length of the list");
            this.nameIndex = NamedIndex(lNames);
            Rf_setAttrib(this.sexp, R_NamesSymbol, lNames);
        }else static if(is(A == string[]))
        {
            enforce(lNames.length == this.length,
                "Length of names submitted " ~ to!string(lNames.length) ~ 
                "is not equal to list length");
            
            this.nameIndex = NamedIndex(lNames);
            Rf_setAttrib(this.sexp, R_NamesSymbol, this.nameIndex.asSEXP);
        }
        return;
    }
    auto opIndexAssign(T, I)(auto ref T value, I i) @trusted
    if(isIntegral!(I) && isConvertibleTo!(T, SEXP, To))
    {
        boundsCheck(i, this.length);
        SET_VECTOR_ELT(this.sexp, cast(int)i, To!(SEXP)(value));
        return;
    }
    auto append(T)(auto ref T value) @trusted
    if(isConvertibleTo!(T, SEXP, To))
    {
        this.length(this.length + 1);
        opIndexAssign(value, cast(int)this.length - 1);
        return;
    }
    auto append(T)(auto ref T value, string name) @trusted
    if(isConvertibleTo!(T, SEXP, To))
    {
        this.nameIndex ~= name;
        this.length(this.length + 1);
        opIndexAssign(value, cast(int)this.length - 1);
        Rf_setAttrib(this.sexp, R_NamesSymbol, To!(SEXP)(this.nameIndex.data));
        return;
    }
    auto append(E)(E element)
    if(isNamedElement!E)
    {
        this.append(element.data, element.name);
        return;
    }
    auto opIndexAssign(T)(auto ref T value, string name) @trusted
    {
        if(isin(name, this.nameIndex.data))
        {
            auto i = this.nameIndex[name];
            opIndexAssign(value, i);
            return;
        }

        if(this.length == this.nameIndex.length)
        {
            this.append(value, name);
            return;
        }else{
            string msg = "List was not initialized with names or " ~ 
                    "length of names is not equal to number of items";
            enforce(0, msg);
        }
    }
    auto opOpAssign(string op, T)(auto ref T value) @trusted
    if((op == "~") && isConvertibleTo!(T, SEXP, To))
    {
        this.append(value);
        return;
    }
    auto opOpAssign(string op, T)(auto ref T value, string name) @trusted
    if((op == "~") && isConvertibleTo!(T, SEXP, To))
    {
        this.append(value, name);
        return;
    }
    auto opOpAssign(string op, E)(E element) @trusted
    if((op == "~") && isNamedElement!(E))
    {
        this.append(element);
        return;
    }
    auto opSlice(I)(I start, I end)
    if(isIntegral!(I))
    {
        assert(end > start, 
            "Starting index is not less than the finishing index.");
        auto newLength = end - start;
        auto result = List(newLength);
        foreach(i; 0..newLength)
        {
            result[i] = copyVector(this[i + start]);
        }
        string[] lNames;
        if(this.nameIndex.length == this.length)
        {
            foreach(i; 0..newLength)
            {
                lNames ~= this.nameIndex[i + start];
            }
        }
        Rf_setAttrib(result.sexp, R_NamesSymbol, To!(SEXP)(lNames));
        return result;
    }
    auto opBinary(string op, R)(auto ref R rhs)
    if((op == "~") && is(R == List))
    {
        auto result = List(this.length + rhs.length);
        foreach(i; 0..this.length)
        {
            result[i] = copyVector(this[i]);
        }
        foreach(i; 0..rhs.length)
        {
            result[i + this.length] = copyVector(rhs[i]);
        }
        auto thisNames = protect(Rf_getAttrib(this.sexp, R_NamesSymbol));
        scope(exit)unprotect_ptr(thisNames);
        auto rhsNames = protect(Rf_getAttrib(rhs.sexp, R_NamesSymbol));
        scope(exit)unprotect_ptr(rhsNames);
        if((LENGTH(thisNames) > 0) && (LENGTH(rhsNames) > 0))
        {
            auto newNames = To!(string[])(thisNames) ~ To!(string[])(rhsNames);
            Rf_setAttrib(result.sexp, R_NamesSymbol, To!(SEXP)(newNames));
        }
        return result;
    }
    auto opBinary(string op, R)(auto ref R _rhs_)
    if((op == "~") && ((!is(R == List) && isConvertibleTo!(R, SEXP, To)) || isNamedElement!(R)))
    {
        auto rhs = List(_rhs_);
        return this ~ rhs;
    }
}


