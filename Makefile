DC = dmd
PB = osmproto/fileformat.d osmproto/osmformat.d
PBLIB = ./ProtocolBuffer/libdprotobuf.a
DFILES = math/rtree2d.d math/geometry.d math/graph.d pb_encoding.d main.d


ifeq ($(ARGS),"")
	ARGS = "-release"
endif

all: main

main:
	
	make -C ProtocolBuffer libdprotobuf
	$(DC) $(ARGS) -ofmain $(PB) $(PBLIB) $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
