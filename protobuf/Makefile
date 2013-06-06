DC = dmd

PROTOBUF_PATH=protobuf-2.5.0

ifeq ($(ARGS),"")
	ARGS = "-release"
endif

all: lib compiler

lib:
	$(DC) $(ARGS) -lib -oflibprotobuf runtime.d

compiler:
	gcc -I$(PROTOBUF_PATH)/src/ -L$(PROTOBUF_PATH)/src/.libs/ -lprotobuf -lprotoc -oprotoc-gen-d plugin.cc
	#$(DC) $(ARGS) -L-lprotobuf -J. -ofcompiler runtime.d compiler.d statical.d

clean:
	rm -rf *.o *.a compiler protoc-gen-d
	rm -rf doc/*
