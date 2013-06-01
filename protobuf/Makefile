DC = dmd

.PHONY: all
all: lib compiler

lib:
	$(DC) -lib -oflibprotobuf runtime.d

compiler:
	$(DC) -L-lprotobuf -ofcompiler runtime.d compiler.d

clean:
	rm -rf *.o *.a compiler
	rm -rf doc/*
