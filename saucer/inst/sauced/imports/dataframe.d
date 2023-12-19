/*
    TODO:

    1. Account for basic type in length and init
*/


auto makeRowNames(I)(I n)
if(isIntegral!(I))
{
    //import std.range: iota;
    //import std.array: array;
    //To!SEXP(iota!(int)(1, cast(int)nRow + 1).array);
    auto nRow = cast(int)(n);
    int[] _rowNames_;
    foreach(i; 1..(nRow + 1))
    {
        _rowNames_ ~= i;
    }
    auto result = To!SEXP(_rowNames_);
    return result;
}


struct DataFrame
{
    List data;
    this(Arg)(Arg arg) @trusted
    if(is(Arg == SEXP))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect_ptr(className);
        auto rtype = cast(SEXPTYPE)TYPEOF(arg);
        if(rtype == VECSXP)
        {
            this(List(arg));
            enforce(arg.length > 0, "Empty list can not be used to create a DataFrame");
            auto rowNames = protect(makeRowNames(this[0].length));
            scope(exit) unprotect_ptr(rowNames);
            Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
            classgets(this.data.sexp, className);
        }else{
            auto name = protect(Rf_getAttrib(arg, R_NamesSymbol));
            scope(exit) unprotect_ptr(name);
            if(name.length == 1)
            {
                this.data = List(namedElement(name, arg));
                auto rowNames = protect(makeRowNames(arg.length));
                scope(exit) unprotect_ptr(rowNames);
                Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
                classgets(this.data.sexp, className);
            }else{
                this.data = List(namedElement("column_1", arg));
                auto rowNames = protect(makeRowNames(arg.length));
                scope(exit) unprotect_ptr(rowNames);
                Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
                classgets(this.data.sexp, className);
            }
        }
        return;
    }
    //For named element or rtype
    this(Arg)(Arg arg) @trusted
    if(!is(Arg == SEXP) && !is(Arg == List) && !is(Arg == DataFrame))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect_ptr(className);
        static if(isNamedElement!(Arg))
        {
            this.data = List(arg);
            auto rowNames = protect(makeRowNames(arg.data.length));
            scope(exit) unprotect_ptr(rowNames);
            Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
            classgets(this.data.sexp, className);
        }else{
            this.data = List(namedElement("column_1", arg));
            auto rowNames = protect(makeRowNames(arg.length));
            scope(exit) unprotect_ptr(rowNames);
            Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
            classgets(this.data.sexp, className);
        }
        return;
    }
    //For List
    this(Arg)(Arg arg) @trusted
    if(!is(Arg == SEXP) && is(Arg == List) && !is(Arg == DataFrame))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect_ptr(className);
        auto ncols = arg.length;
        int maxLength = 0;
        auto lengths = new int[ncols];
        int[] uniqueLengths;
        foreach(i; 0..ncols)
        {
            int columnLength = cast(int)arg[i].length;
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
        enforce(uniqueLengths.length <= 2, 
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
        }
        if(uniqueLengths.length == 2)
        {
            foreach(i; 0..ncols)
            {
                auto column = protect(arg[i]);
                if(column.length == 1)
                {
                    fillSEXPVector(column, uniqueLengths[1]);
                    arg[i] = column;
                }
                unprotect_ptr(column);
            }
            this.data = arg;
            classgets(this.data.sexp, className);
        }
        this.data = arg;
        auto rowNames = protect(makeRowNames(maxLength));
        scope(exit) unprotect_ptr(rowNames);
        Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
        classgets(this.data.sexp, className);
        return;
    }
    SEXP opCast(T)() @trusted
    if(is(T == SEXP))
    {
        return this.data.sexp;
    }
}



