DC := dmd
PB := osmproto/fileformat.d osmproto/osmformat.d
PBLIB := ./ProtocolBuffer/libdprotobuf.a
DFILES := math/rtree2d.d math/geometry.d math/graph.d pb_encoding.d main.d


ARGS ?= -d -release


all: main

main:
	make -C ProtocolBuffer libdprotobuf
	$(DC) $(ARGS) -ofmain $(PB) $(PBLIB) $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
