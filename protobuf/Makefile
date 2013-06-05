DC = dmd

ifeq ($(ARGS),"")
	ARGS = "-release"
endif

all: lib compiler

lib:
	$(DC) $(ARGS) -lib -oflibprotobuf runtime.d

compiler:
	$(DC) $(ARGS) -L-lprotobuf -J. -ofcompiler runtime.d compiler.d

clean:
	rm -rf *.o *.a compiler
	rm -rf doc/*
