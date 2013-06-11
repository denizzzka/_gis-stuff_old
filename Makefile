DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
LIBS := -L-ldl -L-lDerelictSFML2 -L-lDerelictUtil
#LIBS := -L-ldl -L-lcsfml-graphics -L-lcsfml-window -L-lcsfml-system
DFILES := math/rtree2d.d math/geometry.d math/graph.d math/earth.d \
	pb_encoding.d osm.d sfml.d main.d
INCLUDE := -I/usr/include/dmd/ -I./SFML-D/

ARGS ?= -d -release

all: $(OSMPBFLIB) main

$(OSMPBFLIB):
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

main:
	$(DC) $(INCLUDE) $(LIBS) $(ARGS) $(BITS) -ofmain \
		$(OSMPBFLIB).a ./SFML-D/sf/*.d $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
