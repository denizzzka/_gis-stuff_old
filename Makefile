DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
DSFMLFLIB := libdsfml
#DERELICTLIB := -L-ldl -L-lDerelictSFML2 -L-lDerelictUtil
DFILES := math/rtree2d.d math/geometry.d math/graph.d math/earth.d \
	pb_encoding.d osm.d sfml.d main.d
INCLUDE := -I/usr/include/dmd/ -I./DSFML/

ARGS ?= -d -release

all: $(OSMPBFLIB) $(DSFMLFLIB) main

$(OSMPBFLIB):
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

$(DSFMLFLIB):
	$(DC) $(INCLUDE) $(BITS) -lib -of$(DSFMLFLIB) ./DSFML/dsfml/*.d

main:
	$(DC) $(INCLUDE) $(DERELICTLIB) $(ARGS) $(BITS) -ofmain \
		$(OSMPBFLIB).a $(DSFMLFLIB).a $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
