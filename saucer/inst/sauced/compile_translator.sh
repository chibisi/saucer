echo 'enum moduleName = "test.files.test_resource_1";' | dmd translator.d test/files/example_1.d test/files/test_resource_1.d test/files/test_resource_2.d saucer.d r2d.d -O -mcpu=native -g -J=\".\" -L-lR -L-lRmath
./translator

# Clean up the executables and compilation artifacts
test -f "translator" && rm translator
test -f "translator.o" && rm translator.o

test -f "r2d.o" && rm r2d.o
test -f "saucer.o" && rm saucer.o
test -f "test_resource_1.o" && rm test_resource_1.o
test -f "test_resource_1.so" && rm test_resource_1.so
test -f "test_resource_1.r" && rm test_resource_1.r
test -f "test_resource_1.d" && rm test_resource_1.d
