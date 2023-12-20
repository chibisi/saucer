vectorExampleCode1 = '
@Export() auto logicalToBooleanArray(LogicalVector arr)
{
    import std.stdio: writeln;
    bool[] result = To!(bool[])(arr);
    writeln("Converted logical vector: ", result);
    return;
}
'

saucer::dfunctions(vectorExampleCode1)
logicalToBooleanArray(c(TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE))


vectorExampleCode2 = '
@Export() auto booleanArrayToLogical()
{
    auto arr = [true, false, true, true, false, true, false, false];
    return arr;
}
'
saucer::dfunctions(vectorExampleCode2)
booleanArrayToLogical()


vectorExampleCode3 = '
@Export() auto createStringVector()
{
    auto result = CharacterVector("Monday", "Tuesday", "Wednesday", 
                    "Thursday", "Friday", "Saturday", "Sunday");
    return result;
}
'
saucer::dfunctions(vectorExampleCode3);
createStringVector()


vectorExampleCode4 = '
@Export() auto convertStringArrayToSEXP()
{
    auto arr = ["Monday", "Tuesday", "Wednesday", 
                    "Thursday", "Friday", "Saturday", "Sunday"];
    return arr;
}
'
saucer::dfunctions(vectorExampleCode4);
convertStringArrayToSEXP()


