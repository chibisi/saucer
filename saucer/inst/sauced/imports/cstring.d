import std.string: _toCString_ = toStringz, _fromCString_ = fromStringz;

auto toCString(string _string_)
{
    auto output = _toCString_(cast(char[])_string_);
    return cast(char*)output;
}

auto fromCString(char* _string_)
{
    return cast(string)_fromCString_(_string_);
}

