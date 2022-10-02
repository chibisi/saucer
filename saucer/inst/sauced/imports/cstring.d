/+
    Converts string to null terminated c string char* type
+/
auto toCString(string _string_)
{
    char[] charArr = cast(char[])_string_;
    charArr ~= '\0';
    return charArr.ptr;
}

/+
    Converts null terminated cstring char* to string
+/
auto fromCString(char* _cstring_)
{
    string result;
    char tmp;
    int i = 0;
    while(tmp != '\0')
    {
        tmp = _cstring_[i];
        result ~= tmp;
        ++i;
    }
    return result;
}
