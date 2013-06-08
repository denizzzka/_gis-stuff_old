DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
DERELICTLIB := -L-lDerelictSFML2 -L-lDerelictUtil -L-ldl
DFILES := math/rtree2d.d math/geometry.d math/graph.d pb_encoding.d main.d
INCLUDE := -I/usr/include/dmd/

ARGS ?= -d -release

all: $(OSMPBFLIB) main

$(OSMPBFLIB):
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

main:
	$(DC) $(INCLUDE) $(DERELICTLIB) $(ARGS) $(BITS) -ofmain $(OSMPBFLIB).a $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
