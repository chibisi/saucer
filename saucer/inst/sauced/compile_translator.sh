dmd translator.d files/test_resource_1.d files/test_resource_2.d saucer.d r2d.d -O -mcpu=native -g -J=\".\" -L-lR -L-lRmath
./translator

# Clean up the executables and compilation artifacts
test -f "translator" && rm translator
test -f "translator.o" && rm translator.o
