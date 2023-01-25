
struct DataFrame
{
    import std.stdio: writeln;
    SEXP sexp
    int[string] _names_;
    bool needUnprotect = false;
    this(Args...)(Args args)
    {
        enum n = Args.length;
        auto _obj_ = List(n);
        static foreach(i; 0..n)
        {
            static if(!(is(Args[i] == SEXP) || isRType!(Args[i])))
            {
                arg = To!(SEXP)(args[i]);
                _obj_[i] = arg;
            }else{
                _obj_[i] = args[i];
            }
        }
        this.sexp = cast(SEXP)_obj_;
        this.needUnprotect = true;
    }
}


