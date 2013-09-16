DC := dmd
PB := osmpbf/fileformat.d osmpbf/osmformat.d
PBLIB := ProtocolBuffer/libdprotobuf.a
OSMPBFLIB := libosmpbfd
DSFMLLIB := libdsfml
LIBS := -L-ldl -L-lcsfml-graphics -L-lcsfml-window -L-lcsfml-system
DFILES := \
	pb_encoding.d osm.d scene.d osm_tags_parsing.d compression/*.d \
	math/*.d math/rtree2d/*.d math/graph/*.d map/*.d config/*.d render/*.d main.d
INCLUDE := -I/usr/include/dmd/ -I./DSFML/
BITS := -m32

ARGS ?= -release

all: $(OSMPBFLIB) dsfml main

$(OSMPBFLIB):
	make -C ProtocolBuffer args="$(BITS)" libdprotobuf
	$(DC) -d $(ARGS) $(BITS) -lib -of$(OSMPBFLIB) $(PBLIB) $(PB)

derelict3:
	cd ./Derelict3/build/; $(DC) build.d; ./build sfml2
	
dsfml:
	$(DC) -d $(BITS) -lib -of$(DSFMLLIB) ./DSFML/dsfml/*.d

main:
	$(DC) $(INCLUDE) $(LIBS) $(ARGS) $(BITS) -ofmain \
		$(OSMPBFLIB).a $(DSFMLLIB).a $(DFILES)

clean:
	rm -rf *.o *.a main
	rm -rf doc/*
	make -C ProtocolBuffer 
