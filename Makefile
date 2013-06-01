DC = dmd

.PHONY: all
all: lib compiler

lib:
	$(DC) -lib -ofruntime runtime.d

compiler:
	$(DC) -L-lruntime -ofcompiler compiler.d runtime.d


clean:
	rm -rf *.o *.a $(RES)
	rm -rf doc/*
