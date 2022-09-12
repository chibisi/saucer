//simple file for overall export check
module test_resource_2;
import saucer;


/+
    Multiplies two numbers by each other
+/
@Export() double mult(double x, double y)
{  
    return x*y;
}

