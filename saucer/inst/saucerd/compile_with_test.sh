dmd translator2.d files/test_resource_1.d files/test_resource_2.d saucer.d r2d.d -unittest -main -O -mcpu=native -g -J=\".\" -L-lR -L-lRmath
./translator2

# Clean up the executables and compilation artifacts
test -f "translator2" && rm translator2
test -f "translator2.o" && rm translator2.o
