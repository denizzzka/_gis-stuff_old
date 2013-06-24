DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
LIBS := -L-ldl
DFILES := math/rtree2d.d math/geometry.d math/graph.d math/earth.d \
	pb_encoding.d osm.d sfml.d main.d
INCLUDE := -I/usr/include/dmd/ -I./Derelict3/import/ -I./SFML2_wrapper/

ARGS ?= -d -release

all: $(OSMPBFLIB) derelict3 main

$(OSMPBFLIB):
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

derelict3:
	cd ./Derelict3/build/; $(DC) build.d; ./build sfml2

main:
	$(DC) $(INCLUDE) $(LIBS) $(ARGS) $(BITS) -ofmain \
		$(OSMPBFLIB).a ./Derelict3/lib/*.a ./SFML2_wrapper/sf/*.d $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
