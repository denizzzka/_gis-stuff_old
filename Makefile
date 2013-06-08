DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
DFILES := math/rtree2d.d math/geometry.d math/graph.d pb_encoding.d main.d

ARGS ?= -d -release

all: $(OSMPBFLIB) main

libosmpbfd:
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

main:
	$(DC) $(ARGS) $(BITS) -ofmain $(OSMPBFLIB).a $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
