module test.files.test_resource_2;
import sauced.saucer;


/+
    Multiplies two numbers by each other
+/
@Export() double mult(double x, double y)
{  
    return x*y;
}

