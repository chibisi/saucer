

struct DataFrame
{
    RVector!(VECSXP) __dataframe__;
    alias __dataframe__ this;
    int nrow;
    int ncol;

    this(T...)(T items)
    if(T.length > 1)
    {
        import std.conv: to;
        this.ncol = T.length;
        alias T1 = T[0];


        //Check all items have equal lengths
        if(is(T1 == SEXP))
        {
            this.nrow = LENGTH(items[0]);
        }else if(isRType!(T1))
        {
            this.nrow = items[0].length;
        }else{
            assert(0, "Unknown type: " ~ T1.stringof ~ ", type of item must either be SEXP or RType");
        }
        
        foreach(item; items[1..$])
        {
            if(is(typeof(item) == SEXP))
            {
                assert(this.nrow == LENGTH(item), "Error lengths of columns differ");
            }else if(isRType!(typeof(item)))
            {
                assert(this.nrow == item.length, "Error lengths of columns differ");
            }else{
                assert(0, "Unknown type: " ~ typeof(item).stringof ~ ", type of item must either be SEXP or RType");
            }
        }
        this.__dataframe__ = RVector!(VECSXP)(items);
        string[] _rownames_;
        string[] _colnames_;
        foreach(i; 0..(this.nrow))
        {
            //For some reason the string is ill formed without append to ""
            //needs further investigation.
            _rownames_ ~= "" ~ to!(string)(i + 1);
        }

        foreach(i; 0..(this.ncol))
        {
            _colnames_ ~= "V" ~ to!(string)(i);
        }
        this.__dataframe__.names = _colnames_;
        
        SEXP _sexp_rownames_ = RVector!(STRSXP)(_rownames_);
        setAttrib(this.__dataframe__, R_RowNamesSymbol, _sexp_rownames_);

        SEXP classname = RVector!(STRSXP)(["data.frame"]);
        classgets(this.__dataframe__, classname);
    }
    @property auto rownames()
    {
        return RVector!(STRSXP)(getAttrib(this.__dataframe__, R_RowNamesSymbol));
    }
    @property auto rownames(T)(T _rownames_)
    if(isSEXP!(T) || isRType!(T) || is(T == string[]))
    {
        static if(is(T == string[]))
        {
            SEXP _sexp_rownames_ = RVector!(STRSXP)(_rownames_);
            setAttrib(this.__dataframe__, R_RowNamesSymbol, _sexp_rownames_);
        }else{
            setAttrib(this.__dataframe__, R_RowNamesSymbol, _rownames_);
        }
        return;
    }
}




