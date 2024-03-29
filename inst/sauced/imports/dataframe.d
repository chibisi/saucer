/*
    TODO:

    1. Account for basic type in length and init
*/


auto makeRowNames(I)(I n)
if(isIntegral!(I))
{
    auto nRow = cast(int)(n);
    int[] _rowNames_;
    foreach(i; 1..(nRow + 1))
    {
        _rowNames_ ~= i;
    }
    auto result = To!SEXP(_rowNames_);
    return result;
}


private struct RowIndexer
{
    List* list;
    this(List* list)
    {
        this.list = list;
    }
    auto opSlice(I)(I i, I j)
    if(isIntegral!(I))
    {
        auto ncols = list.length;
        auto nrows = j - i;
        auto resultList = List(ncols);
        foreach(m; 0..ncols)
        {
            resultList[m] = slice((*list)[m], i, j);
        }
        Rf_setAttrib(resultList.sexp, R_RowNamesSymbol, makeRowNames(nrows));
        Rf_setAttrib(resultList.sexp, R_NamesSymbol, Rf_getAttrib(list.sexp, R_NamesSymbol));
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
        classgets(resultList.sexp, className);
        auto result = DataFrame(1);
        result.data = resultList;
        return result;
    }
}


struct DataFrame
{
    import std.stdio: writeln;
    private List data;
    RowIndexer rows;
    this(Arg)(Arg arg) @trusted
    if(is(Arg == SEXP))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
        auto rtype = cast(SEXPTYPE)TYPEOF(arg);
        if(rtype == VECSXP)
        {
            auto list = List(arg);
            this(list);
        }else{
            auto name = protect(Rf_getAttrib(arg, R_NamesSymbol));
            scope(exit) unprotect(1);
            if(name.length == 1)
            {
                auto list = List(namedElement(name, arg));
                this(list);
            }else{
                auto list = List(namedElement("column_1", arg));
                this(list);
            }
        }
        return;
    }
    //For named element or rtype or basic type or array
    this(Arg)(Arg arg) @trusted
    if(!is(Arg == SEXP) && !is(Arg == List) && !is(Arg == DataFrame))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
        static if(isNamedElement!(Arg))
        {
            this.data = List(arg);
            auto rowNames = protect(makeRowNames(arg.data.length));
            scope(exit) unprotect(1);
            Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
            classgets(this.data.sexp, className);
        }else{
            static if(isBasicType!Arg)
            {
                this.data = List(namedElement("column_1", [arg]));
                auto rowNames = protect(makeRowNames(1));
                scope(exit) unprotect(1);
                Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
                classgets(this.data.sexp, className);
            }else{
                this.data = List(namedElement("column_1", arg));
                auto rowNames = protect(makeRowNames(arg.length));
                scope(exit) unprotect(1);
                Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
                classgets(this.data.sexp, className);
            }
        }
        this.rows = RowIndexer(&this.data);
        return;
    }
    //For List
    this(Arg)(Arg arg) @trusted
    if(is(Arg == List))
    {
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
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
        scope(exit) unprotect(1);
        if(sNames.length != ncols)
        {
            auto colNames = new string[ncols];
            foreach(i, ref name; colNames)
            {
                name = "column_" ~ to!(string)(i + 1);
            }
            auto newSNames = protect(To!(SEXP)(colNames));
            scope(exit) unprotect(1);
            Rf_setAttrib(arg.sexp, R_NamesSymbol, newSNames);
            arg.nameIndex = NamedIndex(colNames);
        }
        if(arg.nameIndex.length != ncols)
        {
            auto newSNames = protect(Rf_getAttrib(arg.sexp, R_NamesSymbol));
            scope(exit) unprotect(1);
            arg.nameIndex = NamedIndex(newSNames);
        }
        if(uniqueLengths.length == 2)
        {
            foreach(i; 0..ncols)
            {
                if(arg[i].length == 1)
                {
                    arg[i] = fillSEXPVector(arg[i], uniqueLengths[1]);
                }
            }
        }
        this.data = arg;
        auto rowNames = protect(makeRowNames(maxLength));
        scope(exit) unprotect(1);
        Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
        classgets(this.data.sexp, className);
        this.rows = RowIndexer(&this.data);
        return;
    }
    this(Args...)(Args args) @trusted
    if((Args.length > 1) && isSEXP!(Args))
    {
        string[] colNames;
        auto ncols = Args.length;
        auto slist = protect(allocVector(VECSXP, cast(int)ncols));
        scope(exit) unprotect(1);
        foreach(i, sexp; args)
        {
            enforce(rTypeOf(sexp) != VECSXP, "Lists are not allowed in multiple argument for DataFrame constructor");
            auto sName = protect(Rf_getAttrib(sexp, R_NamesSymbol));
            scope(exit) unprotect(1);
            string colName = sName.length == 1 ? 
                                To!(string)(sName) : "column_" ~ to!string(i + 1);
            auto j = 1;
            while(colName.isin(colNames))
            {
                colName ~= "_" ~ to!string(j);
                ++j;
            }
            colNames ~= colName;
            SET_VECTOR_ELT(slist, cast(int)i, sexp);
        }
        Rf_setAttrib(slist, R_NamesSymbol, To!SEXP(colNames));
        this(List(slist));
        return;
    }
    this(Args...)(Args args) @trusted
    if((Args.length > 1) && (isConvertibleToSEXP!(Args) || isAnyNamedElement!(Args)) && !isSEXP!(Args))
    {
        auto ncols = Args.length;
        auto slist = protect(allocVector(VECSXP, cast(int)ncols));
        scope(exit) unprotect(1);
        string[] colNames;
        static foreach(i, Arg; Args)
        {{
            SEXP sexp;
            string colName;
            static if(is(Arg == SEXP))
            {
                sexp = protect(args[i]);
                scope(exit) unprotect(1);
                enforce(rTypeOf(sexp) != VECSXP, "Lists are not allowed in " ~ 
                    "multiple argument for DataFrame constructor");
                auto sName = protect(Rf_getAttrib(sexp, R_NamesSymbol));
                scope(exit) unprotect(1);
                colName = sName.length == 1 ? 
                                To!(string)(sName) : "column_" ~ to!string(i + 1);
            }else static if(isNamedElement!(Arg))
            {
                auto tmp = args[i].data;
                static if(is(typeof(tmp) == SEXP))
                {
                    sexp = protect(tmp);
                    scope(exit) unprotect(1);
                }else{
                    sexp = protect(To!SEXP(tmp));
                    scope(exit) unprotect(1);
                }
                colName = args[i].name;
            }else
            {
                sexp = protect(To!SEXP(args[i]));
                scope(exit) unprotect(1);
                colName = "column_" ~ to!string(i + 1);
            }
            auto j = 1;
            while(colName.isin(colNames))
            {
                colName ~= "_" ~ to!string(j);
                ++j;
            }
            colNames ~= colName;
            SET_VECTOR_ELT(slist, cast(int)i, sexp);
        }}
        Rf_setAttrib(slist, R_NamesSymbol, To!SEXP(colNames));
        this(List(slist));
        return;
    }
    SEXP opCast(T)() @trusted
    if(is(T == SEXP))
    {
        return this.data.sexp;
    }
    auto length()
    {
        return this.data.length;
    }
    auto ncol()
    {
        return cast(size_t)this.length;
    }
    auto nrow() @trusted
    {
        if(this.ncol == 0)
        {
            return cast(size_t)0;
        }else
        {
            return cast(size_t)this.data[0].length;
        }
    }
    auto dim() @trusted
    {
        return [this.nrow, this.ncol];
    }
    auto names() @trusted
    {
        return this.data.names;
    }
    pragma(inline, true)
    auto colnames() @trusted
    {
        return this.names();
    }
    auto names(A)(A lNames) @trusted
    if(is(A == SEXP) || is(A == string[]) || is(A == CharacterVector))
    {
        this.data.names(lNames);
        return;
    }
    pragma(inline, true)
    auto colnames(A)(A lNames) @trusted
    if(is(A == SEXP) || is(A == string[]) || is(A == CharacterVector))
    {
        return this.names(lNames);
    }
    auto opIndex(I)(I i) @trusted
    if(isIntegral!I || is(I == string))
    {
        return DataFrame(namedElement(this.data.nameIndex[i], this.data[i]));
    }
    auto opIndex(I)(I[] idx)
    if(isIntegral!(I) /* || is(I == string) */)
    {
        return DataFrame(this.data[idx[0]..idx[1]]);
    }
    auto opIndex(I, J)(I[] idx0, J[] idx1)
    if(isIntegral!(I) && isIntegral!(J))
    {
        //column select - generates new DF
        auto result = this[idx1[0]..idx1[1]];
        I start = idx0[0];
        I end = idx0[1];
        //inplace row subsetting
        foreach(i; 0..result.ncol)
        {
            result.data[i] = slice!(false)(result.data[i], start, end);
        }
        Rf_setAttrib(result.data.sexp, R_RowNamesSymbol, makeRowNames(end - start));
        return result;
    }
    auto opSlice(size_t dim, I)(I start, I end)
    if((dim >= 0 && dim < 2) && (isIntegral!I || is(I == string)))
    {
        static if(isIntegral!I)
        {
            enforce(start >= 0 && end <= this.opDollar!dim, 
                "Index given is out of bounds");
            return [start, end];
        }else static if(is(I == string))
        {
            auto _start_ = this.data.nameIndex[start];
            auto _end_ = this.data.nameIndex[end] + 1;
            enforce(_start_ >= 0 && _end_ <= this.opDollar!dim, 
                "Index given is out of bounds");
            return [_start_, _end_];
        }
    }
    @property auto opDollar(size_t dim : 0)()
    {
        return this.nrow;
    }
    @property auto opDollar(size_t dim : 1)()
    {
        return this.ncol; 
    }
    auto rbind(DataFrame df) @trusted
    {
        enforce(this.names == df.names, "Column names of the DataFrame to be appended " ~ 
            "differs from the DataFrame being appended to. Current names: \n" ~ to!string(this.names) ~
            "\nCandidate names: \n" ~ to!string(df.names));
        auto sameColNames = true;
        auto ncols = this.ncol;
        //Check column types
        foreach(i; 0..ncols)
        {
            sameColNames = sameColNames && (TYPEOF(this.data[i]) == TYPEOF(df.data[i]));
        }
        enforce(sameColNames, "Columns in candidate entry does not have the same types as the DataFrame");
        //Join columns
        size_t nrows;
        foreach(i; 0..ncols)
        {
            auto column = protect(join(this.data[i], df.data[i]));
            scope(exit) unprotect(1);
            if(i == 0)
            {
                nrows = column.length;
            }
            this.data[i] = column;
        }
        auto rowNames = protect(makeRowNames(nrows));
        scope(exit) unprotect(1);
        Rf_setAttrib(this.data.sexp, R_RowNamesSymbol, rowNames);
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
        classgets(this.data.sexp, className);
        return;
    }
    auto rbind(List list) @trusted
    {
        this.rbind(DataFrame(list));
        return;
    }
    auto rbind(SEXP list) @trusted
    {
        auto rtype = rTypeOf(list);
        enforce(rtype == VECSXP, "Types such as this " ~ to!string(rtype) ~ 
            "that are not lists (VECSXP) or DataFrame can not be row-bound to dataframes");
        this.rbind(DataFrame(list));
        return;
    }
    auto cbind(D)(D rhs)
    if(is(D == DataFrame))
    {
        enforce(this.nrow == rhs.nrow, "Number of rows in the dataframe do not match");
        auto lhsLength = this.length;
        auto rhsLength = rhs.length;
        auto ncols = lhsLength + rhsLength;
        auto colNames = protect(join(Rf_getAttrib(this.data.sexp, R_NamesSymbol),
                                Rf_getAttrib(rhs.data.sexp, R_NamesSymbol)));
        scope(exit) unprotect(1);
        auto newList = List(ncols);
        foreach(i; 0..ncols)
        {
            if(i < lhsLength)
            {
                newList[i] = this.data[i];
            }else{
                newList[i] = rhs.data[i - lhsLength];
            }
        }
        Rf_setAttrib(newList.sexp, R_NamesSymbol, colNames);
        auto rowNames = protect(Rf_getAttrib(this.data.sexp, R_RowNamesSymbol));
        scope(exit) unprotect(1);
        Rf_setAttrib(newList.sexp, R_RowNamesSymbol, rowNames);
        auto className = protect(To!(SEXP)("data.frame"));
        scope(exit) unprotect(1);
        classgets(newList.sexp, className);
        this.data = newList;
        return;
    }
    auto cbind(D)(D rhs)
    if(is(D == List))
    {
        this.cbind(DataFrame(rhs));
        return;
    }
    auto cbind(D)(D rhs)
    if(isConvertibleToSEXP!(D) && !is(D == DataFrame) && !is(D == List))
    {
        auto n = cast(int)this.nrow;
        static if(isBasicType!(D))
        {
            enum TYPE = MapToSEXP!(D);
            alias R = SEXPElementType!TYPE;
            auto rvec = RVector!TYPE(n);
            rvec[] = cast(R)rhs;
            this.cbind(rvec);
        }else static if(isRVector!(D) || isBasicArray!(D))
        {
            auto result = List(To!SEXP(rhs));
            auto colNames = this.names;
            auto colName = "column_" ~ to!string(n);
            auto j = n + 1;
            while(colName.isin(colNames))
            {
                colName = "column_" ~ to!string(j);
                j++;
            }
            result.names([colName]);
            this.cbind(DataFrame(result));
        }else static if(isSEXP!(D))
        {
            if(rTypeOf(rhs) == VECSXP)
            {
                this.cbind(DataFrame(rhs));
            }else{
                auto result = List(rhs);
                auto colNames = this.names;
                auto colName = "column_" ~ to!string(n);
                auto j = n + 1;
                while(colName.isin(colNames))
                {
                    colName = "column_" ~ to!string(j);
                    j++;
                }
                result.names([colName]);
                this.cbind(DataFrame(result));
            }
        }
        return;
    }
    auto cbind(D)(D rhs)
    if(isNamedElement!(D))
    {
        this.cbind(DataFrame(rhs));
        return;
    }
}



