

struct DataFrame
{
    List data;
    SEXP className;
    //Constructors
    this(Arg)(Arg arg) @trusted
    if(is(Arg == SEXP))
    {
        protect(To!(SEXP)("data.frame"));
        auto rtype = cast(SEXP)TYPEOF(arg);
        if(rtype == VECSXP)
        {
            //Not yet implemented
            this(List(arg));
            classgets(this.data.sexp, className);
        }else{
            auto name = protect(Rf_getAttrib(arg, R_NamesSymbol));
            scope(exit) unprotect_ptr(name);
            if(name.length == 1)
            {
                this.data = List(namedElement(name, arg));
                classgets(this.data.sexp, className);
            }else{
                this.data = List(namedElement("column_1", arg));
                classgets(this.data.sexp, className);
            }
        }
    }
    this(Arg)(Arg arg) @trusted
    if(!is(Arg == SEXP) && !is(Arg == List))
    {
        protect(To!(SEXP)("data.frame"));
        static if(isNamedElement!(Arg))
        {
            this.data = List(arg);
            classgets(this.data.sexp, className);
        }else{
            this.data = List(namedElement("column_1", arg));
            classgets(this.data.sexp, className);
        }
    }
    this(Arg)(Arg arg) @trusted
    if(!is(Arg == SEXP) && is(Arg == List))
    {
        protect(To!(SEXP)("data.frame"));
        auto ncols = arg.length;
        long maxLength = 0;
        auto lengths = new int[ncols];
        int[] uniqueLengths;
        foreach(i; 0..ncols)
        {
            auto columnLength = arg[i].length;
            maxLength = maxLength >= columnLength ? maxLength : columnLength;
            lengths[i] = columnLength;
            if(i == 0)
            {
                uniqueLengths ~= columnLength;
            }else{
                if(!columnLength.isin(uniqueLengths))
                {
                    uniqueLengths ~= columnLength;
                }
            }
        }
        enforce(uniqueLengths.length < 3, 
            "Submitted list has items items with to many lengths: " ~ 
                to!(string)(uniqueLengths));
        if(uniqueLengths.length == 2)
        {
            uniqueLengths = uniqueLengths[0] < uniqueLengths[1] ?
                uniqueLengths : [uniqueLengths[1], uniqueLengths[0]];
            enforce(uniqueLengths[0] == 1, "Lists with invalid lengths submitted: " ~ 
                to!(string)(uniqueLengths));
        }
        auto sNames = protect(Rf_getAttrib(arg.sexp, R_NamesSymbol));
        scope(exit) unprotect_ptr(sNames);
        if(sNames.length != ncols)
        {
            auto colNames = new string[ncols];
            foreach(i, ref name; colNames)
            {
                name = "column_" ~ to!(string)(i);
            }
            auto newSNames = protect(To!(SEXP)(colNames));
            scope(exit) unprotect_ptr(newSNames);
            Rf_setAttrib(arg.sexp, R_NamesSymbol, newSNames);
            arg.nameIndex = NamedIndex(colNames);
        }
        if(arg.nameIndex.length != ncols)
        {
            auto newSNames = protect(Rf_getAttrib(arg.sexp, R_NamesSymbol));
            scope(exit) unprotect_ptr(newSNames);
            arg.nameIndex = NamedIndex(newSNames);
        }
        if(uniqueLengths.length <= 1)
        {
            this.data = arg;
            classgets(this.data.sexp, className);
            return;
        }
        if(uniqueLengths.length == 2)
        {
            foreach(i; 0..ncols)
            {
                auto column = protect(arg[i]);
                scope(exit) unprotect_ptr(column);
                if(column.length == 1)
                {
                    fillSEXPVector(column, uniqueLengths[1]);
                    arg[i] = column;
                }
            }
            this.data = arg;
            classgets(this.data.sexp, className);
            return;
        }
    }
    ~this()
    {
        unprotect_ptr(className);
    }
    SEXP opCast(T)() @trusted
    if(is(T == SEXP))
    {
        return this.data.sexp;
    }
}



